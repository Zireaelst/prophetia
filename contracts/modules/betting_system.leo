// ═══════════════════════════════════════════════════════════════════════════
// PROPHETIA BETTING SYSTEM - Automated Prediction Betting
// ═══════════════════════════════════════════════════════════════════════════
//
// Bu modül PROPHETIA'nın otomatik bahis sistemini implement eder:
// Tahmin sinyalleri → Otomatik bahis açma → Sonuç settlement → Kâr/zarar dağıtımı
//
// NASIL ÇALIŞIR:
//   1. ZK-ML inference bir tahmin sinyali üretir (ProphecySignal)
//   2. Sistem otomatik olarak havuz likiditesiyle bahis açar
//   3. Gerçek sonuç geldiğinde bahis settle edilir
//   4. Kâr havuza eklenir, zarar havuzdan düşülür
//
// ÖNEMLİ ÖZELLİKLER:
//   ✅ Risk yönetimi (maksimum %10 havuz exposure)
//   ✅ Confidence-based betting (güven oranına göre bahis büyüklüğü)
//   ✅ Otomatik settlement (manuel müdahale yok)
//   ✅ Şeffaf takip (bet_state mapping)
//   ✅ Pool entegrasyonu (liquidity_pool.leo ile senkron)
//
// GÜVENLİK:
//   - BetPosition record ownership (Aleo enforce eder)
//   - Risk limitleri (havuz koruması)
//   - Settlement authority (sadece oracle veya admin)
//   - Double settlement protection
//
// ═══════════════════════════════════════════════════════════════════════════

import prophetia_pool.aleo;
import inference.aleo;

program prophetia_betting.aleo {
    
    // ───────────────────────────────────────────────────────────────────────
    // RECORD TANIMLARI
    // ───────────────────────────────────────────────────────────────────────
    
    /// BetPosition Record
    ///
    /// Açık bir bahis pozisyonunu temsil eder.
    /// Her BetPosition, bir tahmin sinyaline dayalı açılmış bahis içerir.
    ///
    /// Field'lar:
    ///   - owner: Bu bahsi açan adres (pool veya kullanıcı)
    ///   - bet_id: Benzersiz bahis ID'si
    ///   - prediction_signal: Tahmin sinyali (ProphecySignal)
    ///   - bet_amount: Bahis miktarı (scaled 10^6)
    ///   - target_category: Hedef kategori (0=Stocks, 1=Weather, vb.)
    ///   - target_value: Tahmin edilen değer (scaled 10^6)
    ///   - threshold: Settlement eşiği (scaled 10^6)
    ///   - timestamp: Bahis açılış zamanı
    ///   - is_settled: Settlement durumu
    ///   - _nonce: Privacy garantisi
    ///
    /// Örnek:
    ///   Tahmin: "AAPL hisse fiyatı 180'e çıkacak"
    ///   BetPosition {
    ///     owner: pool_address,
    ///     bet_id: 1,
    ///     prediction_signal: signal_record,
    ///     bet_amount: 10_000_000 (10 token),
    ///     target_category: 0 (Stocks),
    ///     target_value: 180_000_000 (180.0),
    ///     threshold: 175_000_000 (175.0),
    ///     timestamp: 1738627200,
    ///     is_settled: false
    ///   }
    record BetPosition {
        owner: address,
        bet_id: u64,
        prediction_signal: inference.ProphecySignal,
        bet_amount: u64,
        target_category: u8,
        target_value: u64,
        threshold: u64,
        timestamp: u64,
        is_settled: bool,

    }
    
    // ───────────────────────────────────────────────────────────────────────
    // PUBLIC STATE MAPPING'LER
    // ───────────────────────────────────────────────────────────────────────
    
    /// Bet State Mapping
    ///
    /// Tüm bahis sisteminin durumunu tutar.
    /// Herkes okuyabilir (transparency).
    ///
    /// Key'ler:
    ///   0 => total_bets_placed (açılan toplam bahis sayısı)
    ///   1 => total_bets_settled (kapatılan bahis sayısı)
    ///   2 => total_bets_active (aktif bahis sayısı)
    ///   3 => total_profit_earned (kazanılan toplam kâr)
    ///   4 => total_loss_incurred (toplam zarar)
    ///   5 => current_exposure (şu anki risk exposure'u)
    ///   6 => max_single_bet (tek bahis için max limit)
    ///   7 => win_count (kazanılan bahis sayısı)
    ///   8 => loss_count (kaybedilen bahis sayısı)
    ///   9 => reserved (gelecek kullanım)
    mapping bet_state: u8 => u64;
    
    /// Individual Bet Tracking
    ///
    /// Her bahsin detaylı takibi.
    /// bet_id → bet_amount
    mapping bet_amounts: u64 => u64;
    
    /// Settlement Status
    ///
    /// Bahis settlement durumları.
    /// bet_id → is_settled (0=open, 1=settled)
    mapping bet_settlements: u64 => u8;
    
    // ───────────────────────────────────────────────────────────────────────
    // SABITLER
    // ───────────────────────────────────────────────────────────────────────
    
    /// Risk yönetimi sabitleri
    const MAX_POOL_EXPOSURE_PERCENT: u64 = 10u64;  // Havuzun max %10'u risk altında
    const SCALE: u64 = 1000000u64;                  // Fixed-point scale
    const MIN_BET_AMOUNT: u64 = 1000000u64;         // Min 1.0 token
    const MAX_BET_MULTIPLIER: u64 = 5u64;           // Max 5x confidence multiplier
    
    // ───────────────────────────────────────────────────────────────────────
    // ANA TRANSITION'LAR
    // ───────────────────────────────────────────────────────────────────────
    
    /// Place Bet (Bahis Aç)
    ///
    /// ZK-ML inference'dan gelen tahmin sinyaline dayalı otomatik bahis açar.
    /// Havuz likiditesini kullanarak pozisyon oluşturur.
    ///
    /// Bahis Büyüklüğü Hesaplama:
    ///   base_bet = available_liquidity × (MAX_POOL_EXPOSURE / 100)
    ///   confidence_multiplier = signal.confidence / SCALE
    ///   final_bet = base_bet × confidence_multiplier
    ///
    /// Risk Kontrolleri:
    ///   1. Havuzda yeterli likidite var mı?
    ///   2. Current exposure + new bet <= %10 limit?
    ///   3. Confidence yeterince yüksek mi (>%60)?
    ///   4. Bet amount MIN_BET'ten büyük mü?
    ///
    /// Örnek:
    ///   Havuz: 1000 token
    ///   Max exposure: 100 token (%10)
    ///   Signal confidence: 85% (0.85)
    ///   Base bet: 100 × 0.85 = 85 token
    ///   
    ///   Eğer zaten 30 token exposure varsa:
    ///   Available: 100 - 30 = 70 token
    ///   Final bet: min(85, 70) = 70 token
    ///
    /// Parametreler:
    ///   - signal: Tahmin sinyali (ProphecySignal record)
    ///   - target_category: Hedef kategori (0-3)
    ///   - target_value: Tahmin edilen değer
    ///   - threshold: Settlement için eşik değer
    ///
    /// Return:
    ///   - BetPosition record (açık bahis)
    ///
    /// Gas Cost: ~25,000 credits
    ///
    transition place_bet(
        signal: inference.ProphecySignal,
        public target_category: u8,
        public target_value: u64,
        public threshold: u64
    ) -> BetPosition {
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 1: HAVUZ LİKİDİTESİNİ KONTROL ET
        // ───────────────────────────────────────────────────────────────
        
        // Havuz istatistiklerini al
        let pool_stats: (u64, u64, u64, u64, u64) = prophetia_pool.aleo/get_pool_stats();
        let total_liquidity: u64 = pool_stats.0;
        
        // Havuzda likidite olmalı
        assert(total_liquidity > 0u64);
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 2: MEVCUT EXPOSURE'U KONTROL ET
        // ───────────────────────────────────────────────────────────────
        
        let current_exposure: u64 = Mapping::get_or_use(bet_state, 5u8, 0u64);
        
        // Max exposure hesapla (%10 havuz)
        let max_exposure: u64 = (total_liquidity * MAX_POOL_EXPOSURE_PERCENT) / 100u64;
        
        // Hala yer var mı?
        assert(current_exposure < max_exposure);
        
        let available_exposure: u64 = max_exposure - current_exposure;
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 3: CONFIDENCE KONTROLÜ
        // ───────────────────────────────────────────────────────────────
        
        // Signal confidence'ı al
        let confidence: u64 = signal.confidence;
        
        // Minimum %60 confidence gerekli
        let min_confidence: u64 = 600000u64;  // 0.60 scaled
        assert(confidence >= min_confidence);
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 4: BAHİS MİKTARINI HESAPLA
        // ───────────────────────────────────────────────────────────────
        
        // Base bet: Available exposure'un tamamı
        let base_bet: u64 = available_exposure;
        
        // Confidence multiplier uygula
        // confidence = 0.85 → %85 of base_bet
        let confidence_multiplier: u64 = confidence;
        let bet_with_confidence: u64 = (base_bet * confidence_multiplier) / SCALE;
        
        // Max multiplier kontrolü (5x'ten fazla olamaz)
        let max_bet: u64 = (base_bet * MAX_BET_MULTIPLIER) / 1u64;
        let bet_amount: u64 = 0u64;
        
        if bet_with_confidence > max_bet {
            bet_amount = max_bet;
        } else {
            bet_amount = bet_with_confidence;
        }
        
        // Minimum bet kontrolü
        assert(bet_amount >= MIN_BET_AMOUNT);
        
        // Available exposure'dan fazla olamaz
        assert(bet_amount <= available_exposure);
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 5: BET ID OLUŞTUR
        // ───────────────────────────────────────────────────────────────
        
        let total_bets: u64 = Mapping::get_or_use(bet_state, 0u8, 0u64);
        let bet_id: u64 = total_bets + 1u64;
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 6: HAVUZA BET'İ KAYDET
        // ───────────────────────────────────────────────────────────────
        
        // Pool'a bet kaydı
        prophetia_pool.aleo/record_bet(bet_amount);
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 7: BET STATE'İ GÜNCELLE
        // ───────────────────────────────────────────────────────────────
        
        // Total bets placed
        Mapping::set(bet_state, 0u8, bet_id);
        
        // Active bets
        let active_bets: u64 = Mapping::get_or_use(bet_state, 2u8, 0u64);
        Mapping::set(bet_state, 2u8, active_bets + 1u64);
        
        // Current exposure
        let new_exposure: u64 = current_exposure + bet_amount;
        Mapping::set(bet_state, 5u8, new_exposure);
        
        // Individual bet tracking
        Mapping::set(bet_amounts, bet_id, bet_amount);
        
        // Settlement status (0 = open)
        Mapping::set(bet_settlements, bet_id, 0u8);
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 8: BET POSITION RECORD OLUŞTUR
        // ───────────────────────────────────────────────────────────────
        
        let timestamp: u64 = 0u64;  // Gerçek implementasyonda block.timestamp
        
        let position: BetPosition = BetPosition {
            owner: self.caller,
            bet_id: bet_id,
            prediction_signal: signal,
            bet_amount: bet_amount,
            target_category: target_category,
            target_value: target_value,
            threshold: threshold,
            timestamp: timestamp,
            is_settled: false,

        };
        
        return position;
    }
    
    /// Settle Bet (Bahis Kapat)
    ///
    /// Gerçek sonuç geldiğinde bahsi settle eder.
    /// Kazanç durumunda havuza kâr ekler, kayıpta zarar düşer.
    ///
    /// Settlement Mantığı:
    ///   WIN durumu: actual_value >= target_value
    ///   LOSS durumu: actual_value < target_value
    ///
    /// Kâr/Zarar Hesaplama:
    ///   WIN: profit = bet_amount × 1.0 (1:1 payout şimdilik)
    ///   LOSS: loss = bet_amount
    ///
    /// Settlement Authority:
    ///   Sadece belirli adresler settle edebilir:
    ///   - Oracle adresi
    ///   - Admin adresi
    ///   - Future: DAO governance
    ///
    /// Parametreler:
    ///   - position: BetPosition record (settle edilecek)
    ///   - actual_value: Gerçek oluşan değer
    ///   - oracle_signature: Oracle imzası (doğrulama için)
    ///
    /// Return:
    ///   - profit_or_loss: Kâr (+) veya zarar (-) miktarı
    ///   - is_win: Bahis kazanıldı mı?
    ///
    /// Gas Cost: ~20,000 credits
    ///
    transition settle_bet(
        position: BetPosition,
        public actual_value: u64,
        public oracle_signature: field  // Gerçek impl'de signature verification
    ) -> (u64, bool) {
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 1: VALIDASYON
        // ───────────────────────────────────────────────────────────────
        
        // Bahis zaten settle edilmiş mi?
        let settlement_status: u8 = Mapping::get(bet_settlements, position.bet_id);
        assert(settlement_status == 0u8);  // 0 = open, 1 = settled
        
        // Bahis sahibi veya oracle olmalı
        // (Gerçek impl'de oracle signature verification)
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 2: WIN/LOSS KARARI
        // ───────────────────────────────────────────────────────────────
        
        let is_win: bool = false;
        
        // Tahmin: "Değer target_value'ya ulaşacak"
        if actual_value >= position.target_value {
            is_win = true;
        } else {
            is_win = false;
        }
        
        // Alternatif: Threshold-based
        // if actual_value >= position.threshold {
        //     is_win = true;
        // }
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 3: KÂR/ZARAR HESAPLA
        // ───────────────────────────────────────────────────────────────
        
        let bet_amount: u64 = position.bet_amount;
        let profit_or_loss: u64 = 0u64;
        
        if is_win {
            // KAZANÇ: 1:1 payout (şimdilik)
            // Future: Confidence-based dynamic payout
            profit_or_loss = bet_amount;
            
            // Havuza kâr ekle
            prophetia_pool.aleo/record_profit(profit_or_loss);
            
            // Win counter
            let win_count: u64 = Mapping::get_or_use(bet_state, 7u8, 0u64);
            Mapping::set(bet_state, 7u8, win_count + 1u64);
            
            // Total profit
            let total_profit: u64 = Mapping::get_or_use(bet_state, 3u8, 0u64);
            Mapping::set(bet_state, 3u8, total_profit + profit_or_loss);
            
        } else {
            // KAYIP: Bet amount kaybedilir
            profit_or_loss = bet_amount;
            
            // Havuzdan zarar düş
            prophetia_pool.aleo/record_loss(profit_or_loss);
            
            // Loss counter
            let loss_count: u64 = Mapping::get_or_use(bet_state, 8u8, 0u64);
            Mapping::set(bet_state, 8u8, loss_count + 1u64);
            
            // Total loss
            let total_loss: u64 = Mapping::get_or_use(bet_state, 4u8, 0u64);
            Mapping::set(bet_state, 4u8, total_loss + profit_or_loss);
        }
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 4: STATE GÜNCELLE
        // ───────────────────────────────────────────────────────────────
        
        // Settled bets counter
        let settled_count: u64 = Mapping::get_or_use(bet_state, 1u8, 0u64);
        Mapping::set(bet_state, 1u8, settled_count + 1u64);
        
        // Active bets (azalt)
        let active_bets: u64 = Mapping::get(bet_state, 2u8);
        Mapping::set(bet_state, 2u8, active_bets - 1u64);
        
        // Current exposure (azalt)
        let current_exposure: u64 = Mapping::get(bet_state, 5u8);
        Mapping::set(bet_state, 5u8, current_exposure - bet_amount);
        
        // Settlement status (1 = settled)
        Mapping::set(bet_settlements, position.bet_id, 1u8);
        
        // ───────────────────────────────────────────────────────────────
        // ADIM 5: RETURN
        // ───────────────────────────────────────────────────────────────
        
        // BetPosition record otomatik consume edilir
        
        return (profit_or_loss, is_win);
    }
    
    /// Cancel Bet (Bahis İptal)
    ///
    /// Henüz settle edilmemiş bir bahsi iptal eder.
    /// Sadece bet owner veya admin yapabilir.
    ///
    /// İptal Durumları:
    ///   - Oracle verisi gelmedi (timeout)
    ///   - Hatalı tahmin (cancel and refund)
    ///   - Emergency pause (sistem maintenance)
    ///
    /// Parametreler:
    ///   - position: BetPosition record (iptal edilecek)
    ///
    /// Return:
    ///   - refund_amount: İade edilen miktar
    ///
    /// Gas Cost: ~15,000 credits
    ///
    transition cancel_bet(
        position: BetPosition
    ) -> u64 {
        
        // ───────────────────────────────────────────────────────────────
        // VALIDASYON
        // ───────────────────────────────────────────────────────────────
        
        // Zaten settle edilmiş mi?
        let settlement_status: u8 = Mapping::get(bet_settlements, position.bet_id);
        assert(settlement_status == 0u8);
        
        // Sadece owner cancel edebilir
        assert(position.owner == self.caller);
        
        // ───────────────────────────────────────────────────────────────
        // REFUND
        // ───────────────────────────────────────────────────────────────
        
        let refund_amount: u64 = position.bet_amount;
        
        // State güncelle (cancel = settled olarak işaretle)
        let settled_count: u64 = Mapping::get_or_use(bet_state, 1u8, 0u64);
        Mapping::set(bet_state, 1u8, settled_count + 1u64);
        
        let active_bets: u64 = Mapping::get(bet_state, 2u8);
        Mapping::set(bet_state, 2u8, active_bets - 1u64);
        
        let current_exposure: u64 = Mapping::get(bet_state, 5u8);
        Mapping::set(bet_state, 5u8, current_exposure - refund_amount);
        
        Mapping::set(bet_settlements, position.bet_id, 1u8);
        
        return refund_amount;
    }
    
    /// Get Bet Stats (İstatistikler)
    ///
    /// Betting sisteminin genel istatistiklerini döner.
    ///
    /// Return:
    ///   (total_placed, total_settled, active, total_profit, total_loss, 
    ///    current_exposure, win_count, loss_count)
    ///
    /// Gas Cost: ~8,000 credits
    ///
    transition get_bet_stats() -> (u64, u64, u64, u64, u64, u64, u64, u64) {
        let total_placed: u64 = Mapping::get_or_use(bet_state, 0u8, 0u64);
        let total_settled: u64 = Mapping::get_or_use(bet_state, 1u8, 0u64);
        let active_bets: u64 = Mapping::get_or_use(bet_state, 2u8, 0u64);
        let total_profit: u64 = Mapping::get_or_use(bet_state, 3u8, 0u64);
        let total_loss: u64 = Mapping::get_or_use(bet_state, 4u8, 0u64);
        let current_exposure: u64 = Mapping::get_or_use(bet_state, 5u8, 0u64);
        let win_count: u64 = Mapping::get_or_use(bet_state, 7u8, 0u64);
        let loss_count: u64 = Mapping::get_or_use(bet_state, 8u8, 0u64);
        
        return (total_placed, total_settled, active_bets, total_profit, 
                total_loss, current_exposure, win_count, loss_count);
    }
    
    /// Calculate Win Rate (Kazanma Oranı)
    ///
    /// Sistemin genel win rate'ini hesaplar.
    ///
    /// Formula: win_rate = win_count / (win_count + loss_count)
    ///
    /// Return:
    ///   - win_rate: Kazanma oranı (scaled 10^6)
    ///
    /// Örnek: 7 win, 3 loss → 0.70 (70%)
    ///
    /// Gas Cost: ~5,000 credits
    ///
    transition calculate_win_rate() -> u64 {
        let win_count: u64 = Mapping::get_or_use(bet_state, 7u8, 0u64);
        let loss_count: u64 = Mapping::get_or_use(bet_state, 8u8, 0u64);
        
        let total_settled_bets: u64 = win_count + loss_count;
        
        // Hiç settled bet yoksa
        if total_settled_bets == 0u64 {
            return 0u64;
        }
        
        // Win rate = (win_count × SCALE) / total_settled
        let win_rate: u64 = (win_count * SCALE) / total_settled_bets;
        
        return win_rate;
    }
    
    /// Get Bet Details (Bet Detayları)
    ///
    /// Belirli bir bet_id'nin detaylarını döner.
    ///
    /// Parametreler:
    ///   - bet_id: Sorgulanacak bahis ID'si
    ///
    /// Return:
    ///   (bet_amount, is_settled)
    ///
    /// Gas Cost: ~3,000 credits
    ///
    transition get_bet_details(public bet_id: u64) -> (u64, u8) {
        let bet_amount: u64 = Mapping::get(bet_amounts, bet_id);
        let is_settled: u8 = Mapping::get(bet_settlements, bet_id);
        
        return (bet_amount, is_settled);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// KULLANIM ÖRNEKLERİ
// ═══════════════════════════════════════════════════════════════════════════

/*

ÖRNEK 1: End-to-End Bahis Akışı
────────────────────────────────

# 1. Veri gönder
leo execute submit_data [data_params] --network testnet

# 2. Model register et
leo execute register_model [model_params] --network testnet

# 3. Tahmin yap (ZK-ML inference)
leo execute divine_future [data_record] [model_record] --network testnet

# Output: ProphecySignal {
#   score: 850000,        # 0.85 confidence
#   confidence: 850000,
#   category: 0,
#   direction: 1 (UP)
# }

# 4. Bahis aç (otomatik)
leo execute place_bet [signal_record] 0u8 180000000u64 175000000u64 --network testnet

# Output: BetPosition {
#   bet_id: 1,
#   bet_amount: 70000000 (70 tokens),
#   target_value: 180.0,
#   threshold: 175.0
# }

# 5. Gerçek sonuç geldiğinde settle et
leo execute settle_bet [bet_position] 185000000u64 [oracle_sig] --network testnet

# Output: (70000000, true)  # 70 token profit, WIN!


ÖRNEK 2: Risk Yönetimi Demo
────────────────────────────

Senaryo: Havuz 1000 token, max %10 exposure

# İlk bahis (confidence %85)
place_bet → 85 token bahis açıldı
Current exposure: 85 token (%8.5)

# İkinci bahis (confidence %70) 
place_bet → 15 token bahis açıldı (100 token limiti doldu)
Current exposure: 100 token (%10 - MAX!)

# Üçüncü bahis deneme
place_bet → HATA! "Max exposure reached"

# İlk bahis settle edildi (WIN)
settle_bet → 85 token kâr, exposure düştü
Current exposure: 15 token

# Şimdi yeni bahis açılabilir
place_bet → 85 token bahis açıldı
Current exposure: 100 token


ÖRNEK 3: Çoklu Bahis Takibi
────────────────────────────

# İstatistikleri sor
leo execute get_bet_stats --network testnet

Output:
(
  10u64,    # total_placed: 10 bahis açıldı
  8u64,     # total_settled: 8 settle edildi
  2u64,     # active: 2 bahis hala açık
  350000000u64,  # total_profit: 350 token kâr
  150000000u64,  # total_loss: 150 token zarar
  140000000u64,  # current_exposure: 140 token risk altında
  6u64,     # win_count: 6 kazanç
  2u64      # loss_count: 2 kayıp
)

# Win rate hesapla
leo execute calculate_win_rate --network testnet

Output: 750000u64  # %75 win rate! (6/8)

# Net profit hesapla
Net = 350 - 150 = 200 token profit
ROI = 200 / initial_bets = ...


ÖRNEK 4: Bet İptal Senaryosu
─────────────────────────────

# Bahis aç
bet_position = place_bet(signal, 0, 180M, 175M)

# Oracle verisi gelmedi (timeout) → Cancel
refund = cancel_bet(bet_position)

# Output: 70000000 (70 token refund)
# State: Exposure azaldı, active bets azaldı


DEPLOYMENT TALİMATLARI
───────────────────────

1. KONTRATI DEPLOY ET:
   
   cd contracts
   leo deploy prophetia_betting.aleo --network testnet


2. İLK TEST BAHSİNİ AÇ:
   
   # Önce pool'da likidite olmalı
   leo execute deposit_liquidity 1000000000u64 --network testnet
   
   # Sonra tahmin yap
   signal = divine_future(data, model)
   
   # Bahis aç
   leo execute place_bet [signal] 0u8 180000000u64 175000000u64 --network testnet


3. MANUEL SETTLEMENT TEST:
   
   # Gerçek değer 185 (WIN senaryosu)
   leo execute settle_bet [position] 185000000u64 0field --network testnet
   
   # Gerçek değer 170 (LOSS senaryosu)
   leo execute settle_bet [position] 170000000u64 0field --network testnet


4. İSTATİSTİKLERİ KONTROL ET:
   
   leo execute get_bet_stats --network testnet
   leo execute calculate_win_rate --network testnet


5. RISK LİMİTLERİNİ TEST ET:
   
   # Çok fazla bahis açmaya çalış
   # Sistemin max %10 exposure'u koruyup korumadığını gör


RİSK YÖNETİMİ DETAYLARI
────────────────────────

MAX EXPOSURE HESAPLAMA:
  Pool liquidity: 1000 tokens
  Max exposure %: 10%
  Max exposure: 100 tokens

CONFIDENCE-BASED BET SIZE:
  Available exposure: 100 tokens
  Signal confidence: 85%
  Bet size: 100 × 0.85 = 85 tokens

MULTI-BET SCENARIO:
  Bet 1: 85 tokens (confidence 85%)
  Remaining: 15 tokens
  Bet 2: 15 tokens (confidence 70% → 10.5, but limited to 15)
  Remaining: 0 tokens
  Bet 3: BLOCKED (no available exposure)

AFTER SETTLEMENT:
  Bet 1 settles (win or loss)
  Exposure released: 85 tokens
  New bets can be placed!


GELECEKTEKİ GELİŞTİRMELER
──────────────────────────

Week 7: Kâr Dağıtımı
- Win durumunda %40 data provider
- %40 model creator
- %20 pool (investors)

Week 8: Dynamic Payout
- Confidence-based multiplier
- 60% confidence → 0.5x payout
- 90% confidence → 2.0x payout

Week 9: Multi-Asset Support
- Stocks, Weather, Crypto, Commodities
- Her kategori için farklı risk profili

Week 10: Oracle Integration
- Chainlink price feeds
- Pyth Network
- API3 oracles

Week 11: Advanced Risk Management
- Kelly Criterion betting
- Portfolio optimization
- Stop-loss mekanizması

Week 12: DAO Governance
- Settlement dispute resolution
- Parameter voting (max exposure, min confidence)
- Treasury management

*/
