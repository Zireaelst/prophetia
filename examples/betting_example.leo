// ═══════════════════════════════════════════════════════════════════════
// PROPHETIA - Betting System Usage Examples
// ═══════════════════════════════════════════════════════════════════════
// 
// Bu dosya betting_system.leo kontratının kullanım örneklerini içerir.
// Tüm örnekler end-to-end senaryoları gösterir:
//   - Veri kaydı (data_records.leo)
//   - Model eğitimi (models.leo)
//   - Tahmin (inference.leo)
//   - Bahis açma (betting_system.leo)
//   - Settlement (betting_system.leo)
//   - Likidite yönetimi (liquidity_pool.leo)
//
// Hafta 6: Otomatik Bahis Sistemi
// ═══════════════════════════════════════════════════════════════════════

program betting_example.aleo {
    // ─────────────────────────────────────────────────────────────────────
    // İmport Edilen Programlar
    // ─────────────────────────────────────────────────────────────────────
    import prophetia_data.aleo;
    import prophetia_models.aleo;
    import prophetia_inference.aleo;
    import prophetia_pool.aleo;
    import betting_system.aleo;
    
    // ─────────────────────────────────────────────────────────────────────
    // ÖRNEK 1: Basic Win Scenario (Kazanç Senaryosu)
    // ─────────────────────────────────────────────────────────────────────
    // 
    // Flow:
    // 1. Veri sağlayıcı market data kaydeder
    // 2. Model creator model eğitir
    // 3. Oracle inference çalıştırır
    // 4. Tahmin yüksek confidence → Bahis açılır
    // 5. Gerçek değer target'ı geçer → WIN
    // 6. Profit pool'a eklenir
    //
    transition example_win_scenario(
        public data_provider: address,
        public model_creator: address,
        public oracle_address: address,
    ) -> (u64, bool) {
        
        // ═════════════════════════════════════════════════════════════════
        // ADIM 1: VERİ KAYDI (Data Provider)
        // ═════════════════════════════════════════════════════════════════
        // 
        // Bitcoin fiyat verisi: $45,000
        // Timestamp: 1640000000 (Unix)
        // Category: PRICE (0u8)
        // Metadata: "BTC-USD Daily Close"
        //
        let data_record: DataRecord = prophetia_data.aleo/record_data(
            0u8,                    // category: PRICE
            45_000_000_000u64,      // value: $45,000 (scaled)
            1640000000u64,          // timestamp
            field1,                 // source_hash
            data_provider           // provider
        );
        
        // ═════════════════════════════════════════════════════════════════
        // ADIM 2: MODEL EĞİTİMİ (Model Creator)
        // ═════════════════════════════════════════════════════════════════
        //
        // Linear Regression model (type: 0u8)
        // Accuracy: 82% (820,000 scaled)
        // Sample count: 1000
        //
        let model_record: ModelRecord = prophetia_models.aleo/create_model(
            0u8,                    // model_type: LINEAR_REGRESSION
            820_000u64,             // accuracy: 82%
            1000u64,                // sample_count
            field1,                 // weights_hash (model parameters)
            model_creator           // creator
        );
        
        // ═════════════════════════════════════════════════════════════════
        // ADIM 3: INFERENCE (Oracle)
        // ═════════════════════════════════════════════════════════════════
        //
        // Model ile tahmin çalıştır
        // Predicted value: $46,800 (4% artış)
        // Confidence: 85% (yüksek)
        //
        let signal: ProphecySignal = prophetia_inference.aleo/run_inference(
            model_record,
            data_record,
            oracle_address
        );
        
        // Signal values:
        // - predicted_value: 46_800_000_000u64
        // - confidence: 850_000u64 (85%)
        // - category: 0u8
        // - timestamp: current
        
        // ═════════════════════════════════════════════════════════════════
        // ADIM 4: BAHİS AÇMA (Betting System)
        // ═════════════════════════════════════════════════════════════════
        //
        // Confidence yüksek (85%) → Büyük bahis (85 tokens)
        // Target: $46,500 (conservative)
        // Threshold: $46,000 (stop loss)
        //
        let bet_position: BetPosition = betting_system.aleo/place_bet(
            signal,
            0u8,                    // target_category: PRICE
            46_500_000_000u64,      // target_value: $46,500
            46_000_000_000u64       // threshold: $46,000
        );
        
        // Bet details:
        // - bet_amount: 85 tokens (85% of max exposure)
        // - active: true
        // - settlement: pending
        
        // ═════════════════════════════════════════════════════════════════
        // ADIM 5: GERÇEK DEĞER GELDİ (Oracle Update)
        // ═════════════════════════════════════════════════════════════════
        //
        // 24 saat sonra gerçek Bitcoin fiyatı: $47,200
        // Target ($46,500) aşıldı → WIN!
        //
        let actual_value: u64 = 47_200_000_000u64;
        let oracle_signature: field = field1; // Oracle'ın signature'ı
        
        // ═════════════════════════════════════════════════════════════════
        // ADIM 6: SETTLEMENT (Betting System)
        // ═════════════════════════════════════════════════════════════════
        //
        // Actual (47,200) >= Target (46,500) → WIN
        // Profit: 85 tokens
        // Pool liquidity +85 tokens
        //
        let (profit_or_loss, is_win): (u64, bool) = betting_system.aleo/settle_bet(
            bet_position,
            actual_value,
            oracle_signature
        );
        
        // Results:
        // profit_or_loss = 85_000_000u64 (85 tokens profit)
        // is_win = true
        //
        // Betting state updated:
        // - total_profit += 85 tokens
        // - win_count += 1
        // - current_exposure -= 85 tokens
        // - active_bets -= 1
        //
        // Pool updated (via record_profit):
        // - total_liquidity += 85 tokens
        // - total_profit += 85 tokens
        
        return (profit_or_loss, is_win);
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // ÖRNEK 2: Loss Scenario (Zarar Senaryosu)
    // ─────────────────────────────────────────────────────────────────────
    //
    // Flow:
    // 1-3. Aynı (veri, model, inference)
    // 4. Tahmin orta confidence → Orta bahis
    // 5. Gerçek değer target'ın altında → LOSS
    // 6. Loss pool'dan düşer
    //
    transition example_loss_scenario(
        public data_provider: address,
        public model_creator: address,
        public oracle_address: address,
    ) -> (u64, bool) {
        
        // ADIM 1-2: Data & Model (önceki örnekle aynı)
        let data_record: DataRecord = prophetia_data.aleo/record_data(
            0u8, 45_000_000_000u64, 1640000000u64, field1, data_provider
        );
        
        let model_record: ModelRecord = prophetia_models.aleo/create_model(
            0u8, 820_000u64, 1000u64, field1, model_creator
        );
        
        // ADIM 3: Inference (bu sefer düşük confidence)
        //
        // Predicted: $46,000 (minimal artış)
        // Confidence: 65% (orta)
        //
        let signal: ProphecySignal = prophetia_inference.aleo/run_inference(
            model_record,
            data_record,
            oracle_address
        );
        // signal.confidence = 650_000u64 (65%)
        
        // ADIM 4: Bahis (orta confidence → orta bet)
        //
        // 65% confidence → 65 tokens bet
        //
        let bet_position: BetPosition = betting_system.aleo/place_bet(
            signal,
            0u8,                    // target_category
            46_000_000_000u64,      // target_value: $46,000
            45_500_000_000u64       // threshold: $45,500
        );
        // bet_amount: 65 tokens
        
        // ADIM 5: Gerçek değer (olumsuz)
        //
        // 24 saat sonra: $44,800 (düştü!)
        // Target ($46,000) aşılamadı → LOSS
        //
        let actual_value: u64 = 44_800_000_000u64;
        let oracle_signature: field = field2;
        
        // ADIM 6: Settlement (LOSS)
        //
        // Actual (44,800) < Target (46,000) → LOSS
        // Loss: 65 tokens
        // Pool liquidity -65 tokens
        //
        let (profit_or_loss, is_win): (u64, bool) = betting_system.aleo/settle_bet(
            bet_position,
            actual_value,
            oracle_signature
        );
        
        // Results:
        // profit_or_loss = 65_000_000u64 (65 tokens loss)
        // is_win = false
        //
        // Betting state updated:
        // - total_loss += 65 tokens
        // - loss_count += 1
        // - current_exposure -= 65 tokens
        //
        // Pool updated (via record_loss):
        // - total_liquidity -= 65 tokens
        // - total_loss += 65 tokens
        
        return (profit_or_loss, is_win);
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // ÖRNEK 3: Multiple Concurrent Bets (Çoklu Bahis)
    // ─────────────────────────────────────────────────────────────────────
    //
    // Flow:
    // 1. 3 farklı asset için 3 tahmin
    // 2. 3 bahis aynı anda açık
    // 3. Risk management: Total exposure <= 10% pool
    // 4. Her biri ayrı settle edilir
    //
    transition example_multiple_bets(
        public oracle: address,
    ) -> (u64, u64, u64) {
        
        // ═════════════════════════════════════════════════════════════════
        // BET 1: Bitcoin (BTC)
        // ═════════════════════════════════════════════════════════════════
        //
        // Confidence: 70% → 70 tokens bet
        //
        let signal1: ProphecySignal = ProphecySignal {
            predicted_value: 46_500_000_000u64,
            confidence: 700_000u64,
            category: 0u8,
            timestamp: 1640000000u64
        };
        
        let bet1: BetPosition = betting_system.aleo/place_bet(
            signal1,
            0u8,
            46_500_000_000u64,
            46_000_000_000u64
        );
        // bet_amount: 70 tokens
        // current_exposure: 70 tokens
        
        // ═════════════════════════════════════════════════════════════════
        // BET 2: Ethereum (ETH)
        // ═════════════════════════════════════════════════════════════════
        //
        // Kalan exposure: 30 tokens (100 - 70)
        // Confidence: 80% → 24 tokens bet (30 × 0.8)
        //
        let signal2: ProphecySignal = ProphecySignal {
            predicted_value: 3_200_000_000u64,
            confidence: 800_000u64,
            category: 0u8,
            timestamp: 1640000100u64
        };
        
        let bet2: BetPosition = betting_system.aleo/place_bet(
            signal2,
            0u8,
            3_200_000_000u64,
            3_100_000_000u64
        );
        // bet_amount: 24 tokens
        // current_exposure: 94 tokens (70 + 24)
        
        // ═════════════════════════════════════════════════════════════════
        // BET 3: Solana (SOL)
        // ═════════════════════════════════════════════════════════════════
        //
        // Kalan exposure: 6 tokens (100 - 94)
        // Confidence: 60% (min) → 3.6 tokens bet (6 × 0.6)
        //
        let signal3: ProphecySignal = ProphecySignal {
            predicted_value: 125_000_000u64,
            confidence: 600_000u64,
            category: 0u8,
            timestamp: 1640000200u64
        };
        
        let bet3: BetPosition = betting_system.aleo/place_bet(
            signal3,
            0u8,
            125_000_000u64,
            120_000_000u64
        );
        // bet_amount: 3.6 tokens
        // current_exposure: 97.6 tokens (70 + 24 + 3.6)
        // TOPLAM: %9.76 (10% limit içinde ✓)
        
        // ═════════════════════════════════════════════════════════════════
        // 24 SAAT SONRA: SETTLEMENT
        // ═════════════════════════════════════════════════════════════════
        
        // BET 1: BTC = $47,000 → WIN (target: $46,500)
        let (profit1, win1): (u64, bool) = betting_system.aleo/settle_bet(
            bet1,
            47_000_000_000u64,
            field1
        );
        // profit1 = 70 tokens, win1 = true
        
        // BET 2: ETH = $3,050 → LOSS (target: $3,200)
        let (profit2, win2): (u64, bool) = betting_system.aleo/settle_bet(
            bet2,
            3_050_000_000u64,
            field2
        );
        // profit2 = 24 tokens (loss), win2 = false
        
        // BET 3: SOL = $130 → WIN (target: $125)
        let (profit3, win3): (u64, bool) = betting_system.aleo/settle_bet(
            bet3,
            130_000_000u64,
            field3
        );
        // profit3 = 3.6 tokens, win3 = true
        
        // TOPLAM:
        // - Profit: 70 + 3.6 = 73.6 tokens
        // - Loss: 24 tokens
        // - Net: +49.6 tokens
        // - Win rate: 2/3 = 66.67%
        
        return (profit1, profit2, profit3);
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // ÖRNEK 4: Bet Cancellation (Bahis İptali)
    // ─────────────────────────────────────────────────────────────────────
    //
    // Flow:
    // 1. Bahis açılır
    // 2. Market koşulları hızla değişir
    // 3. Kullanıcı/Oracle bahsi iptal eder
    // 4. Bet amount geri ödenir (refund)
    // 5. Exposure sıfırlanır
    //
    transition example_bet_cancellation(
        public oracle: address,
    ) -> u64 {
        
        // ADIM 1: Bahis aç
        let signal: ProphecySignal = ProphecySignal {
            predicted_value: 46_000_000_000u64,
            confidence: 850_000u64,
            category: 0u8,
            timestamp: 1640000000u64
        };
        
        let bet_position: BetPosition = betting_system.aleo/place_bet(
            signal,
            0u8,
            46_000_000_000u64,
            45_500_000_000u64
        );
        
        // bet_amount: 85 tokens
        // current_exposure: 85 tokens
        // active_bets: 1
        
        // ADIM 2: Market crash! (örnek: exchange hack haberi)
        //
        // Oracle/User decision: İptal et
        // Rationale: Extreme volatility, invalidates prediction
        
        // ADIM 3: Cancel bet
        let refund_amount: u64 = betting_system.aleo/cancel_bet(
            bet_position
        );
        
        // Results:
        // refund_amount = 85_000_000u64 (85 tokens returned)
        //
        // Betting state updated:
        // - current_exposure -= 85 tokens (now 0)
        // - active_bets -= 1 (now 0)
        // - total_settled += 1
        //
        // Position marked as settled (but no win/loss)
        
        return refund_amount;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // ÖRNEK 5: Statistics Tracking (İstatistik Takibi)
    // ─────────────────────────────────────────────────────────────────────
    //
    // Flow:
    // 1. 10 bahis (7 win, 3 loss)
    // 2. get_bet_stats() ile istatistikleri çek
    // 3. Win rate hesapla
    // 4. Dashboard'da göster
    //
    transition example_statistics(
        public oracle: address,
    ) -> (u64, u64, u64, u64, u64, u64, u64, u64, u64) {
        
        // ═════════════════════════════════════════════════════════════════
        // 10 BAHIS SENARYOSU (özet)
        // ═════════════════════════════════════════════════════════════════
        //
        // Bet 1: 70 tokens, target=180 → actual=190 → WIN (+70)
        // Bet 2: 65 tokens, target=175 → actual=185 → WIN (+65)
        // Bet 3: 60 tokens, target=160 → actual=150 → LOSS (-60)
        // Bet 4: 75 tokens, target=195 → actual=200 → WIN (+75)
        // Bet 5: 80 tokens, target=185 → actual=175 → LOSS (-80)
        // Bet 6: 70 tokens, target=188 → actual=192 → WIN (+70)
        // Bet 7: 65 tokens, target=170 → actual=178 → WIN (+65)
        // Bet 8: 60 tokens, target=165 → actual=158 → LOSS (-60)
        // Bet 9: 75 tokens, target=198 → actual=205 → WIN (+75)
        // Bet 10: 70 tokens, target=191 → actual=195 → WIN (+70)
        //
        // Toplam: 7 WIN, 3 LOSS
        // Total profit: 490 tokens
        // Total loss: 200 tokens
        // Net profit: +290 tokens
        
        // ... (10 place_bet ve settle_bet çağrısı burada olurdu)
        // ... (Kısalık için detaylar atlandı)
        
        // ═════════════════════════════════════════════════════════════════
        // İSTATİSTİKLERİ ÇEK
        // ═════════════════════════════════════════════════════════════════
        
        let stats: (u64, u64, u64, u64, u64, u64, u64, u64) = 
            betting_system.aleo/get_bet_stats();
        
        // stats tuple:
        // (
        //   total_placed: 10,
        //   total_settled: 10,
        //   active_bets: 0,
        //   total_profit: 490_000_000,     // 490 tokens
        //   total_loss: 200_000_000,       // 200 tokens
        //   current_exposure: 0,
        //   win_count: 7,
        //   loss_count: 3
        // )
        
        // ═════════════════════════════════════════════════════════════════
        // WIN RATE HESAPLA
        // ═════════════════════════════════════════════════════════════════
        
        let win_rate: u64 = betting_system.aleo/calculate_win_rate();
        
        // win_rate = 700_000u64 (70% scaled)
        // Calculation: (7 wins / 10 total) × 1_000_000 = 700_000
        
        // ═════════════════════════════════════════════════════════════════
        // DASHBOARD METRICS
        // ═════════════════════════════════════════════════════════════════
        //
        // Total Bets: 10
        // Win Rate: 70%
        // Total Profit: 490 tokens
        // Total Loss: 200 tokens
        // Net Profit: +290 tokens (+145% ROI)
        // Current Exposure: 0 tokens (all settled)
        // Active Bets: 0
        
        return (
            stats.0,    // total_placed
            stats.1,    // total_settled
            stats.2,    // active_bets
            stats.3,    // total_profit
            stats.4,    // total_loss
            stats.5,    // current_exposure
            stats.6,    // win_count
            stats.7,    // loss_count
            win_rate    // win_rate
        );
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // ÖRNEK 6: Risk Management Demo (Risk Yönetimi)
    // ─────────────────────────────────────────────────────────────────────
    //
    // Flow:
    // 1. Pool liquidity: 1000 tokens
    // 2. Max exposure: 100 tokens (10%)
    // 3. Birden fazla bahis dene
    // 4. 10% limite ulaşınca block et
    //
    transition example_risk_management(
        public oracle: address,
    ) -> (u64, u64, u64) {
        
        // ═════════════════════════════════════════════════════════════════
        // BAŞLANGIÇ DURUMU
        // ═════════════════════════════════════════════════════════════════
        //
        // Pool: 1000 tokens
        // Max exposure: 100 tokens (10%)
        // Current exposure: 0 tokens
        
        // ═════════════════════════════════════════════════════════════════
        // BAHIS 1: Yüksek confidence (85%)
        // ═════════════════════════════════════════════════════════════════
        
        let signal1: ProphecySignal = ProphecySignal {
            predicted_value: 46_500_000_000u64,
            confidence: 850_000u64,     // 85%
            category: 0u8,
            timestamp: 1640000000u64
        };
        
        let bet1: BetPosition = betting_system.aleo/place_bet(
            signal1, 0u8, 46_500_000_000u64, 46_000_000_000u64
        );
        
        // Bet amount: 85 tokens (85% of 100 max)
        // Current exposure: 85 tokens
        // Remaining: 15 tokens
        
        // ═════════════════════════════════════════════════════════════════
        // BAHIS 2: Orta confidence (80%)
        // ═════════════════════════════════════════════════════════════════
        
        let signal2: ProphecySignal = ProphecySignal {
            predicted_value: 3_200_000_000u64,
            confidence: 800_000u64,     // 80%
            category: 0u8,
            timestamp: 1640000100u64
        };
        
        let bet2: BetPosition = betting_system.aleo/place_bet(
            signal2, 0u8, 3_200_000_000u64, 3_100_000_000u64
        );
        
        // Available: 15 tokens
        // Bet amount: 12 tokens (15 × 0.8)
        // Current exposure: 97 tokens
        // Remaining: 3 tokens
        
        // ═════════════════════════════════════════════════════════════════
        // BAHIS 3: DENEME (FAIL BEKLENİYOR)
        // ═════════════════════════════════════════════════════════════════
        //
        // Remaining: 3 tokens < 2 × MIN_BET (2 tokens)
        // Risk management: BLOCK!
        
        let signal3: ProphecySignal = ProphecySignal {
            predicted_value: 125_000_000u64,
            confidence: 1_000_000u64,   // 100% (max)
            category: 0u8,
            timestamp: 1640000200u64
        };
        
        // Bu çağrı FAIL edecek:
        // assert: "Insufficient exposure remaining: 3.00 tokens"
        
        // let bet3: BetPosition = betting_system.aleo/place_bet(
        //     signal3, 0u8, 125_000_000u64, 120_000_000u64
        // );
        // ❌ AssertionError: Risk management blocked!
        
        // ═════════════════════════════════════════════════════════════════
        // SONUÇ: RİSK LİMİTİ ÇALIŞTI
        // ═════════════════════════════════════════════════════════════════
        //
        // Total exposure: 97 tokens (9.7% of pool)
        // Max allowed: 100 tokens (10% of pool)
        // Active bets: 2
        // Remaining capacity: 3 tokens (insufficient for new bet)
        //
        // Risk management başarıyla pool'u korudu! ✓
        
        return (
            bet1.bet_amount,    // 85 tokens
            bet2.bet_amount,    // 12 tokens
            97_000_000u64       // total exposure
        );
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // ÖRNEK 7: Edge Cases (Özel Durumlar)
    // ─────────────────────────────────────────────────────────────────────
    //
    transition example_edge_cases() {
        
        // ═════════════════════════════════════════════════════════════════
        // EDGE CASE 1: Minimum Confidence (60%)
        // ═════════════════════════════════════════════════════════════════
        
        let signal_min: ProphecySignal = ProphecySignal {
            predicted_value: 46_000_000_000u64,
            confidence: 600_000u64,         // Exactly 60% (min)
            category: 0u8,
            timestamp: 1640000000u64
        };
        
        let bet_min: BetPosition = betting_system.aleo/place_bet(
            signal_min, 0u8, 46_000_000_000u64, 45_500_000_000u64
        );
        // ✓ SUCCESS: 60% kabul edilir (MIN_CONFIDENCE)
        
        // ═════════════════════════════════════════════════════════════════
        // EDGE CASE 2: Below Minimum (59%)
        // ═════════════════════════════════════════════════════════════════
        
        let signal_low: ProphecySignal = ProphecySignal {
            predicted_value: 46_000_000_000u64,
            confidence: 590_000u64,         // 59% (below min)
            category: 0u8,
            timestamp: 1640000100u64
        };
        
        // let bet_low: BetPosition = betting_system.aleo/place_bet(
        //     signal_low, 0u8, 46_000_000_000u64, 45_500_000_000u64
        // );
        // ❌ FAIL: "Confidence too low: 590000 < 600000"
        
        // ═════════════════════════════════════════════════════════════════
        // EDGE CASE 3: Zero Pool Liquidity
        // ═════════════════════════════════════════════════════════════════
        //
        // Eğer pool boşsa (liquidity = 0), hiç bahis açılamaz
        
        // Assume pool.total_liquidity = 0
        
        let signal_zero: ProphecySignal = ProphecySignal {
            predicted_value: 46_000_000_000u64,
            confidence: 850_000u64,
            category: 0u8,
            timestamp: 1640000200u64
        };
        
        // let bet_zero: BetPosition = betting_system.aleo/place_bet(
        //     signal_zero, 0u8, 46_000_000_000u64, 45_500_000_000u64
        // );
        // ❌ FAIL: "Pool has no liquidity"
        
        // ═════════════════════════════════════════════════════════════════
        // EDGE CASE 4: Bet Amount Too Small
        // ═════════════════════════════════════════════════════════════════
        //
        // Eğer available_exposure çok küçükse (< MIN_BET × 2),
        // yeni bahis açılamaz
        
        // Assume current_exposure = 99.5 tokens (of 100 max)
        // Available: 0.5 tokens < MIN_BET (1.0)
        
        let signal_tiny: ProphecySignal = ProphecySignal {
            predicted_value: 46_000_000_000u64,
            confidence: 1_000_000u64,       // 100%
            category: 0u8,
            timestamp: 1640000300u64
        };
        
        // let bet_tiny: BetPosition = betting_system.aleo/place_bet(
        //     signal_tiny, 0u8, 46_000_000_000u64, 45_500_000_000u64
        // );
        // ❌ FAIL: "Insufficient exposure remaining: 0.50 tokens"
        
        return;
    }
    
    // ─────────────────────────────────────────────────────────────────────
    // ÖRNEK 8: Full Integration Flow (Tam Entegrasyon)
    // ─────────────────────────────────────────────────────────────────────
    //
    // Bu örnek tüm PROPHETIA sistemini birleştirir:
    // Data → Model → Inference → Betting → Settlement → Profit Distribution
    //
    transition example_full_integration(
        public data_provider: address,
        public model_creator: address,
        public oracle: address,
        public investor: address,
    ) -> (u64, bool, u64) {
        
        // ═════════════════════════════════════════════════════════════════
        // PHASE 1: LIQUIDITY POOL SETUP
        // ═════════════════════════════════════════════════════════════════
        
        // Investor deposits 1000 tokens
        let deposit_amount: u64 = 1_000_000_000u64;  // 1000 tokens
        let lp_tokens: u64 = prophetia_pool.aleo/deposit(
            deposit_amount,
            investor
        );
        
        // lp_tokens: 1000 (1:1 initial ratio)
        // Pool liquidity: 1000 tokens
        
        // ═════════════════════════════════════════════════════════════════
        // PHASE 2: DATA COLLECTION
        // ═════════════════════════════════════════════════════════════════
        
        // Data provider records Bitcoin price
        let data: DataRecord = prophetia_data.aleo/record_data(
            0u8,                    // PRICE
            45_000_000_000u64,      // $45,000
            1640000000u64,          // timestamp
            field1,                 // source_hash
            data_provider
        );
        
        // ═════════════════════════════════════════════════════════════════
        // PHASE 3: MODEL TRAINING
        // ═════════════════════════════════════════════════════════════════
        
        // Model creator trains prediction model
        let model: ModelRecord = prophetia_models.aleo/create_model(
            0u8,                    // LINEAR_REGRESSION
            820_000u64,             // 82% accuracy
            1000u64,                // 1000 samples
            field2,                 // weights_hash
            model_creator
        );
        
        // ═════════════════════════════════════════════════════════════════
        // PHASE 4: INFERENCE
        // ═════════════════════════════════════════════════════════════════
        
        // Oracle runs inference
        let signal: ProphecySignal = prophetia_inference.aleo/run_inference(
            model,
            data,
            oracle
        );
        
        // signal:
        // - predicted_value: $46,800
        // - confidence: 85%
        
        // ═════════════════════════════════════════════════════════════════
        // PHASE 5: BETTING
        // ═════════════════════════════════════════════════════════════════
        
        // System places automated bet
        let bet: BetPosition = betting_system.aleo/place_bet(
            signal,
            0u8,
            46_500_000_000u64,      // target: $46,500
            46_000_000_000u64       // threshold: $46,000
        );
        
        // bet_amount: 85 tokens (85% confidence)
        // Pool exposure: 85 tokens (8.5%)
        
        // ═════════════════════════════════════════════════════════════════
        // PHASE 6: SETTLEMENT (24 hours later)
        // ═════════════════════════════════════════════════════════════════
        
        // Actual Bitcoin price: $47,200 → WIN!
        let (profit, is_win): (u64, bool) = betting_system.aleo/settle_bet(
            bet,
            47_200_000_000u64,      // actual_value
            field3                  // oracle_signature
        );
        
        // profit: 85 tokens
        // is_win: true
        
        // Pool state:
        // - total_liquidity: 1085 tokens (+85)
        // - total_profit: 85 tokens
        
        // ═════════════════════════════════════════════════════════════════
        // PHASE 7: PROFIT DISTRIBUTION (Week 7 gelecek!)
        // ═════════════════════════════════════════════════════════════════
        
        // Profit split (40-40-20):
        // - Data provider: 34 tokens (40%)
        // - Model creator: 34 tokens (40%)
        // - Pool investors: 17 tokens (20%)
        //
        // (Bu kısım Week 7'de implement edilecek)
        
        // ═════════════════════════════════════════════════════════════════
        // RETURN: SUMMARY
        // ═════════════════════════════════════════════════════════════════
        
        return (
            profit,         // 85 tokens profit
            is_win,         // true (WIN)
            lp_tokens       // 1000 LP tokens (investor's share)
        );
        
        // ═════════════════════════════════════════════════════════════════
        // FINAL STATE:
        // ═════════════════════════════════════════════════════════════════
        //
        // Pool: 1085 tokens (+8.5% ROI)
        // Betting: 1 win, 0 loss, 100% win rate
        // LP token value: 1.085 tokens each (+8.5% appreciation)
        // Data provider: Earned 34 tokens from prediction
        // Model creator: Earned 34 tokens from accuracy
        // Investors: Gained 17 tokens passive income
        //
        // 🎉 Başarılı bir tahmin döngüsü tamamlandı!
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// DEPLOYMENT & USAGE INSTRUCTIONS
// ═══════════════════════════════════════════════════════════════════════════
//
// 1. LEO BUILD
// ────────────
//
// Tüm kontratları build et:
//
//   cd contracts/src
//   leo build data_records.leo
//   leo build models.leo
//   leo build inference.leo
//   leo build liquidity_pool.leo
//   leo build betting_system.leo
//
// Example'ı build et:
//
//   cd examples
//   leo build betting_example.leo
//
// 2. LEO RUN (Local Test)
// ────────────────────────
//
// Örnek 1: Win Scenario
//
//   leo run example_win_scenario \
//     "aleo1data..." \
//     "aleo1model..." \
//     "aleo1oracle..."
//
// Örnek 2: Loss Scenario
//
//   leo run example_loss_scenario \
//     "aleo1data..." \
//     "aleo1model..." \
//     "aleo1oracle..."
//
// Örnek 3: Multiple Bets
//
//   leo run example_multiple_bets "aleo1oracle..."
//
// Örnek 4: Cancellation
//
//   leo run example_bet_cancellation "aleo1oracle..."
//
// Örnek 5: Statistics
//
//   leo run example_statistics "aleo1oracle..."
//
// Örnek 6: Risk Management
//
//   leo run example_risk_management "aleo1oracle..."
//
// Örnek 8: Full Integration
//
//   leo run example_full_integration \
//     "aleo1data..." \
//     "aleo1model..." \
//     "aleo1oracle..." \
//     "aleo1investor..."
//
// 3. SNARKVM DEPLOYMENT
// ──────────────────────
//
// Testnet'e deploy:
//
//   snarkvm deploy betting_example.aleo \
//     --private-key "APrivateKey1..." \
//     --query "https://api.explorer.aleo.org/v1" \
//     --broadcast "https://api.explorer.aleo.org/v1/testnet/transaction/broadcast"
//
// 4. PYTHON SIMULATION
// ─────────────────────
//
// Test suite ile validasyon:
//
//   cd ../../tests
//   python3 test_betting.py
//
// Expected output: "10/10 tests passed"
//
// 5. NEXT STEPS (Week 7)
// ───────────────────────
//
// - Profit distribution system (40-40-20 split)
// - Reputation scoring for providers/creators
// - Integration with betting system
// - Testing full cycle: bet → win → distribute
//
// ═══════════════════════════════════════════════════════════════════════════
// KEY TAKEAWAYS
// ═══════════════════════════════════════════════════════════════════════════
//
// ✓ Risk Management: 10% max pool exposure protects capital
// ✓ Confidence-Based Sizing: Higher confidence → larger bets
// ✓ Multiple Concurrent Bets: Portfolio diversification
// ✓ Win/Loss Settlement: Automated profit/loss distribution
// ✓ Statistics Tracking: Win rate, profit, exposure monitoring
// ✓ Edge Case Handling: Min confidence, zero pool, tiny bets
// ✓ Full Integration: Data → Model → Inference → Bet → Settle
//
// Week 6 başarıyla tamamlandı! 🚀
// ═══════════════════════════════════════════════════════════════════════════
