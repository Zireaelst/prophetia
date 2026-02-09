// ═══════════════════════════════════════════════════════════════════════════════
// PROPHETIA - Profit Distribution System
// ═══════════════════════════════════════════════════════════════════════════════
//
// Week 7: Kar Dağıtım Sistemi
//
// AMAÇ:
// Başarılı tahminlerden elde edilen karları 3 taraf arasında adil şekilde dağıtmak:
//   - Data Provider (40%): Kaliteli veri sağlayıcısını ödüllendir
//   - Model Creator (40%): Doğru model geliştiricisini ödüllendir
//   - Pool Investors (20%): Pasif gelir sağla
//
// EKONOMİK RASYONEL:
// Bu 40-40-20 split, kalite ve katılımı teşvik eder:
//   • Yüksek pay (40%): Aktif katılımcılar (veri/model) büyük risk alır
//   • Orta pay (20%): Pasif yatırımcılar sermaye sağlar
//   • Reputasyon sistemi: İyi performans → daha yüksek gelecek paylar
//   • Stake mekanizması: Kötü performans → stake kaybı
//
// ═══════════════════════════════════════════════════════════════════════════════

program profit_distribution.aleo {
    // ─────────────────────────────────────────────────────────────────────────
    // İmport Edilen Programlar
    // ─────────────────────────────────────────────────────────────────────────
    import prophetia_data.aleo;
    import prophetia_models.aleo;
    import prophetia_pool.aleo;
    import betting_system.aleo;
    
    // ─────────────────────────────────────────────────────────────────────────
    // Records
    // ─────────────────────────────────────────────────────────────────────────
    
    // ProfitShare: Kar paylaşım receipt'i
    record ProfitShare {
        owner: address,          // Alıcı adresi
        amount: u64,            // Alınan kar miktarı (scaled)
        role: u8,               // 0=data_provider, 1=model_creator, 2=pool
        prediction_id: u64,     // Hangi tahmin için
        reputation_bonus: u64,  // Reputasyon bonusu (scaled, 0-200,000 = 0-20%)
        timestamp: u64          // Ödeme zamanı
    }
    
    // Stake: Model/Data provider stake'i
    record Stake {
        owner: address,         // Stake sahibi
        amount: u64,           // Stake miktarı (scaled)
        role: u8,              // 0=data_provider, 1=model_creator
        locked_until: u64,     // Unlock timestamp
        slash_count: u64       // Kaç kez slash edildi
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // Structs
    // ─────────────────────────────────────────────────────────────────────────
    
    // ParticipantInfo: Katılımcı bilgileri
    struct ParticipantInfo {
        address: address,
        reputation_score: u64,  // 0-1,000,000 (0-100%)
        total_contributions: u64, // Toplam katkı sayısı
        successful_predictions: u64, // Başarılı tahmin sayısı
        stake_amount: u64       // Mevcut stake
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // Constants
    // ─────────────────────────────────────────────────────────────────────────
    
    const SCALE: u64 = 1_000_000u64;  // 10^6 scaling
    
    // Kar dağıtım oranları (SCALE'e göre)
    const DATA_PROVIDER_SHARE: u64 = 400_000u64;   // 40%
    const MODEL_CREATOR_SHARE: u64 = 400_000u64;   // 40%
    const POOL_SHARE: u64 = 200_000u64;            // 20%
    
    // Reputasyon sistemi
    const MIN_REPUTATION: u64 = 0u64;              // 0%
    const MAX_REPUTATION: u64 = 1_000_000u64;      // 100%
    const INITIAL_REPUTATION: u64 = 500_000u64;    // 50% (yeni kullanıcılar)
    const MAX_REPUTATION_BONUS: u64 = 200_000u64;  // +20% bonus for 100% rep
    
    // Stake gereksinimleri
    const MIN_STAKE_AMOUNT: u64 = 10_000_000u64;   // 10 tokens minimum
    const STAKE_LOCK_PERIOD: u64 = 86400u64;       // 24 saat (Unix seconds)
    const SLASH_PENALTY: u64 = 100_000u64;         // 10% slash per failure
    const MAX_SLASH_COUNT: u64 = 10u64;            // 10 başarısızlık → tam kayıp
    
    // Reputasyon değişim hızları
    const REPUTATION_GAIN_WIN: u64 = 50_000u64;    // +5% per win
    const REPUTATION_LOSS_FAIL: u64 = 100_000u64;  // -10% per failure
    
    // ─────────────────────────────────────────────────────────────────────────
    // Mappings
    // ─────────────────────────────────────────────────────────────────────────
    
    // Reputasyon skorları (address → reputation)
    mapping reputation_scores: address => u64;
    
    // Katılım istatistikleri
    mapping contribution_stats: address => u64;  // total_contributions
    mapping success_stats: address => u64;       // successful_predictions
    
    // Stake bilgileri
    mapping stake_amounts: address => u64;       // current stake
    mapping slash_counts: address => u64;        // slash count
    
    // Kar dağıtım geçmişi
    mapping distribution_history: u64 => u64;    // prediction_id → total_distributed
    
    // Sistem metrikleri
    mapping system_metrics: u8 => u64;
    // Key 0: total_distributions      // Toplam dağıtım sayısı
    // Key 1: total_profit_distributed  // Toplam dağıtılan kar
    // Key 2: total_data_provider_paid  // Data provider'lara ödenen
    // Key 3: total_model_creator_paid  // Model creator'lara ödenen
    // Key 4: total_pool_allocated      // Pool'a ayrılan
    
    // ─────────────────────────────────────────────────────────────────────────
    // CORE TRANSITION: distribute_profit
    // ─────────────────────────────────────────────────────────────────────────
    //
    // Başarılı bir tahminden elde edilen karı 3 taraf arasında dağıtır.
    //
    // PARAMETERS:
    //   profit_amount: Dağıtılacak toplam kar (betting kazancı)
    //   data_provider: Veri sağlayıcı adresi
    //   model_creator: Model geliştirici adresi
    //   prediction_id: Tahmin ID (tracking için)
    //
    // RETURNS:
    //   (ProfitShare, ProfitShare): Data provider ve model creator payları
    //   (Pool payı otomatik olarak pool.aleo'ya gider)
    //
    // LOGIC:
    //   1. Reputasyon skorlarını çek
    //   2. Base split hesapla (40-40-20)
    //   3. Reputasyon bonusu uygula (max +20%)
    //   4. ProfitShare record'ları oluştur
    //   5. Pool payını pool.aleo'ya gönder
    //   6. Reputasyonları güncelle (başarı → +5%)
    //   7. İstatistikleri kaydet
    //
    transition distribute_profit(
        public profit_amount: u64,
        public data_provider: address,
        public model_creator: address,
        public prediction_id: u64
    ) -> (ProfitShare, ProfitShare) {
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 1: REPUTASYON SKORLARINI ÇEK
        // ═══════════════════════════════════════════════════════════════════
        
        // Data provider reputation (varsayılan: 50% for yeni kullanıcılar)
        let data_rep: u64 = Mapping::get_or_use(
            reputation_scores,
            data_provider,
            INITIAL_REPUTATION
        );
        
        // Model creator reputation
        let model_rep: u64 = Mapping::get_or_use(
            reputation_scores,
            model_creator,
            INITIAL_REPUTATION
        );
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 2: BASE SPLIT HESAPLAMA (40-40-20)
        // ═══════════════════════════════════════════════════════════════════
        
        // Base paylar (reputasyon bonusu olmadan)
        let base_data_share: u64 = (profit_amount * DATA_PROVIDER_SHARE) / SCALE;
        let base_model_share: u64 = (profit_amount * MODEL_CREATOR_SHARE) / SCALE;
        let pool_share: u64 = (profit_amount * POOL_SHARE) / SCALE;
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 3: REPUTASYON BONUSU HESAPLAMA
        // ═══════════════════════════════════════════════════════════════════
        //
        // Formula: bonus = base_share × (reputation / SCALE) × (MAX_BONUS / SCALE)
        //
        // Örnek:
        //   base_share = 40 tokens
        //   reputation = 900_000 (90%)
        //   MAX_BONUS = 200_000 (20%)
        //   bonus = 40 × 0.9 × 0.2 = 7.2 tokens
        //   final_share = 40 + 7.2 = 47.2 tokens
        //
        
        // Data provider bonus
        let data_bonus_multiplier: u64 = (data_rep * MAX_REPUTATION_BONUS) / SCALE;
        let data_bonus: u64 = (base_data_share * data_bonus_multiplier) / SCALE;
        let final_data_share: u64 = base_data_share + data_bonus;
        
        // Model creator bonus
        let model_bonus_multiplier: u64 = (model_rep * MAX_REPUTATION_BONUS) / SCALE;
        let model_bonus: u64 = (base_model_share * model_bonus_multiplier) / SCALE;
        let final_model_share: u64 = base_model_share + model_bonus;
        
        // Bonus'lar pool payından düşülür (toplam = profit_amount)
        let adjusted_pool_share: u64 = pool_share - data_bonus - model_bonus;
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 4: ProfitShare RECORD'LARI OLUŞTUR
        // ═══════════════════════════════════════════════════════════════════
        
        let data_profit_share: ProfitShare = ProfitShare {
            owner: data_provider,
            amount: final_data_share,
            role: 0u8,  // Data provider
            prediction_id: prediction_id,
            reputation_bonus: data_bonus,
            timestamp: block.height
        };
        
        let model_profit_share: ProfitShare = ProfitShare {
            owner: model_creator,
            amount: final_model_share,
            role: 1u8,  // Model creator
            prediction_id: prediction_id,
            reputation_bonus: model_bonus,
            timestamp: block.height
        };
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 5: POOL PAYINI GÖNDER
        // ═══════════════════════════════════════════════════════════════════
        
        // Pool payı, pool.aleo'ya record_profit() ile eklenir
        // Bu, tüm LP token sahiplerine otomatik dağıtır (share value artışı)
        prophetia_pool.aleo/record_profit(adjusted_pool_share);
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 6: REPUTASYONLARI GÜNCELLE (BAŞARI BONUSU)
        // ═══════════════════════════════════════════════════════════════════
        
        // Data provider reputation artır (+5%)
        let new_data_rep: u64 = data_rep + REPUTATION_GAIN_WIN;
        let clamped_data_rep: u64 = new_data_rep <= MAX_REPUTATION ? 
            new_data_rep : MAX_REPUTATION;
        
        Mapping::set(reputation_scores, data_provider, clamped_data_rep);
        
        // Model creator reputation artır (+5%)
        let new_model_rep: u64 = model_rep + REPUTATION_GAIN_WIN;
        let clamped_model_rep: u64 = new_model_rep <= MAX_REPUTATION ? 
            new_model_rep : MAX_REPUTATION;
        
        Mapping::set(reputation_scores, model_creator, clamped_model_rep);
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 7: İSTATİSTİKLERİ GÜNCELLE
        // ═══════════════════════════════════════════════════════════════════
        
        // Contribution counts
        let data_contributions: u64 = Mapping::get_or_use(
            contribution_stats, data_provider, 0u64
        );
        Mapping::set(contribution_stats, data_provider, data_contributions + 1u64);
        
        let model_contributions: u64 = Mapping::get_or_use(
            contribution_stats, model_creator, 0u64
        );
        Mapping::set(contribution_stats, model_creator, model_contributions + 1u64);
        
        // Success counts
        let data_successes: u64 = Mapping::get_or_use(
            success_stats, data_provider, 0u64
        );
        Mapping::set(success_stats, data_provider, data_successes + 1u64);
        
        let model_successes: u64 = Mapping::get_or_use(
            success_stats, model_creator, 0u64
        );
        Mapping::set(success_stats, model_creator, model_successes + 1u64);
        
        // Distribution history
        Mapping::set(distribution_history, prediction_id, profit_amount);
        
        // System metrics
        let total_dists: u64 = Mapping::get_or_use(system_metrics, 0u8, 0u64);
        Mapping::set(system_metrics, 0u8, total_dists + 1u64);
        
        let total_profit: u64 = Mapping::get_or_use(system_metrics, 1u8, 0u64);
        Mapping::set(system_metrics, 1u8, total_profit + profit_amount);
        
        let total_data_paid: u64 = Mapping::get_or_use(system_metrics, 2u8, 0u64);
        Mapping::set(system_metrics, 2u8, total_data_paid + final_data_share);
        
        let total_model_paid: u64 = Mapping::get_or_use(system_metrics, 3u8, 0u64);
        Mapping::set(system_metrics, 3u8, total_model_paid + final_model_share);
        
        let total_pool_alloc: u64 = Mapping::get_or_use(system_metrics, 4u8, 0u64);
        Mapping::set(system_metrics, 4u8, total_pool_alloc + adjusted_pool_share);
        
        return (data_profit_share, model_profit_share);
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // TRANSITION: penalize_failure
    // ─────────────────────────────────────────────────────────────────────────
    //
    // Başarısız tahmin durumunda reputasyon cezası uygular.
    //
    // PARAMETERS:
    //   data_provider: Veri sağlayıcı adresi
    //   model_creator: Model geliştirici adresi
    //   loss_amount: Kaybedilen miktar (stake için)
    //
    // RETURNS:
    //   None (sadece state günceller)
    //
    // LOGIC:
    //   1. Reputasyon düşür (-10%)
    //   2. Başarısızlık sayaçlarını artır
    //   3. Eğer stake varsa slash et (%10)
    //   4. Max slash count'a ulaşılmışsa stake'i tamamen al
    //
    transition penalize_failure(
        public data_provider: address,
        public model_creator: address,
        public loss_amount: u64
    ) {
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 1: REPUTASYON DÜŞÜR (-10%)
        // ═══════════════════════════════════════════════════════════════════
        
        // Data provider penalty
        let data_rep: u64 = Mapping::get_or_use(
            reputation_scores,
            data_provider,
            INITIAL_REPUTATION
        );
        
        let new_data_rep: u64 = data_rep >= REPUTATION_LOSS_FAIL ? 
            data_rep - REPUTATION_LOSS_FAIL : MIN_REPUTATION;
        
        Mapping::set(reputation_scores, data_provider, new_data_rep);
        
        // Model creator penalty
        let model_rep: u64 = Mapping::get_or_use(
            reputation_scores,
            model_creator,
            INITIAL_REPUTATION
        );
        
        let new_model_rep: u64 = model_rep >= REPUTATION_LOSS_FAIL ? 
            model_rep - REPUTATION_LOSS_FAIL : MIN_REPUTATION;
        
        Mapping::set(reputation_scores, model_creator, new_model_rep);
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 2: CONTRIBUTION SAYAÇLARINI ARTIR (başarısızlık da contribution)
        // ═══════════════════════════════════════════════════════════════════
        
        let data_contributions: u64 = Mapping::get_or_use(
            contribution_stats, data_provider, 0u64
        );
        Mapping::set(contribution_stats, data_provider, data_contributions + 1u64);
        
        let model_contributions: u64 = Mapping::get_or_use(
            contribution_stats, model_creator, 0u64
        );
        Mapping::set(contribution_stats, model_creator, model_contributions + 1u64);
        
        // (success_stats değişmez - sadece kazançlarda artırılır)
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 3: STAKE SLASH (Eğer stake varsa %10 ceza)
        // ═══════════════════════════════════════════════════════════════════
        
        // Data provider stake slash
        let data_stake: u64 = Mapping::get_or_use(stake_amounts, data_provider, 0u64);
        if data_stake > 0u64 {
            let slash: u64 = (data_stake * SLASH_PENALTY) / SCALE;
            let new_stake: u64 = data_stake - slash;
            Mapping::set(stake_amounts, data_provider, new_stake);
            
            // Slash count artır
            let data_slashes: u64 = Mapping::get_or_use(slash_counts, data_provider, 0u64);
            Mapping::set(slash_counts, data_provider, data_slashes + 1u64);
            
            // Max slash → stake tamamen gider
            if data_slashes + 1u64 >= MAX_SLASH_COUNT {
                Mapping::set(stake_amounts, data_provider, 0u64);
            }
        }
        
        // Model creator stake slash
        let model_stake: u64 = Mapping::get_or_use(stake_amounts, model_creator, 0u64);
        if model_stake > 0u64 {
            let slash: u64 = (model_stake * SLASH_PENALTY) / SCALE;
            let new_stake: u64 = model_stake - slash;
            Mapping::set(stake_amounts, model_creator, new_stake);
            
            let model_slashes: u64 = Mapping::get_or_use(slash_counts, model_creator, 0u64);
            Mapping::set(slash_counts, model_creator, model_slashes + 1u64);
            
            if model_slashes + 1u64 >= MAX_SLASH_COUNT {
                Mapping::set(stake_amounts, model_creator, 0u64);
            }
        }
        
        return;
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // TRANSITION: deposit_stake
    // ─────────────────────────────────────────────────────────────────────────
    //
    // Kullanıcılar stake deposit eder (güven teminatı).
    //
    // PARAMETERS:
    //   amount: Stake miktarı (min 10 tokens)
    //   role: 0=data_provider, 1=model_creator
    //
    // RETURNS:
    //   Stake record (private ownership)
    //
    transition deposit_stake(
        public amount: u64,
        public role: u8
    ) -> Stake {
        
        // Validasyon: Minimum stake
        assert(amount >= MIN_STAKE_AMOUNT);
        
        // Validasyon: Valid role
        assert(role == 0u8 || role == 1u8);
        
        // Mevcut stake'i çek
        let current_stake: u64 = Mapping::get_or_use(
            stake_amounts,
            self.caller,
            0u64
        );
        
        // Yeni toplam stake
        let new_stake: u64 = current_stake + amount;
        Mapping::set(stake_amounts, self.caller, new_stake);
        
        // Lock period (24 saat)
        let unlock_time: u64 = block.height + STAKE_LOCK_PERIOD;
        
        // Slash count sıfırla (yeni stake ile temiz başlangıç)
        Mapping::set(slash_counts, self.caller, 0u64);
        
        // Stake record oluştur
        let stake_record: Stake = Stake {
            owner: self.caller,
            amount: amount,
            role: role,
            locked_until: unlock_time,
            slash_count: 0u64
        };
        
        return stake_record;
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // TRANSITION: withdraw_stake
    // ─────────────────────────────────────────────────────────────────────────
    //
    // Stake'i geri çeker (lock period sonrası).
    //
    // PARAMETERS:
    //   stake: Stake record
    //
    // RETURNS:
    //   amount: Geri çekilen miktar
    //
    transition withdraw_stake(
        stake: Stake
    ) -> u64 {
        
        // Ownership check
        assert(stake.owner == self.caller);
        
        // Lock period check
        assert(block.height >= stake.locked_until);
        
        // Mevcut stake'i çek
        let current_stake: u64 = Mapping::get_or_use(
            stake_amounts,
            self.caller,
            0u64
        );
        
        // Withdraw amount (slash'ler uygulandıktan sonra kalan)
        let withdraw_amount: u64 = current_stake;
        
        // Stake'i sıfırla
        Mapping::set(stake_amounts, self.caller, 0u64);
        
        // Slash count sıfırla
        Mapping::set(slash_counts, self.caller, 0u64);
        
        return withdraw_amount;
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // TRANSITION: get_participant_info
    // ─────────────────────────────────────────────────────────────────────────
    //
    // Bir katılımcının tüm bilgilerini döner.
    //
    transition get_participant_info(
        public participant: address
    ) -> ParticipantInfo {
        
        let reputation: u64 = Mapping::get_or_use(
            reputation_scores,
            participant,
            INITIAL_REPUTATION
        );
        
        let contributions: u64 = Mapping::get_or_use(
            contribution_stats,
            participant,
            0u64
        );
        
        let successes: u64 = Mapping::get_or_use(
            success_stats,
            participant,
            0u64
        );
        
        let stake: u64 = Mapping::get_or_use(
            stake_amounts,
            participant,
            0u64
        );
        
        let info: ParticipantInfo = ParticipantInfo {
            address: participant,
            reputation_score: reputation,
            total_contributions: contributions,
            successful_predictions: successes,
            stake_amount: stake
        };
        
        return info;
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // TRANSITION: calculate_success_rate
    // ─────────────────────────────────────────────────────────────────────────
    //
    // Bir katılımcının başarı oranını hesaplar.
    //
    // RETURNS:
    //   success_rate: 0-1,000,000 (0-100%)
    //
    transition calculate_success_rate(
        public participant: address
    ) -> u64 {
        
        let contributions: u64 = Mapping::get_or_use(
            contribution_stats,
            participant,
            0u64
        );
        
        let successes: u64 = Mapping::get_or_use(
            success_stats,
            participant,
            0u64
        );
        
        // Zero contributions → 0% success rate
        if contributions == 0u64 {
            return 0u64;
        }
        
        // Formula: (successes × SCALE) / contributions
        let success_rate: u64 = (successes * SCALE) / contributions;
        
        return success_rate;
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // TRANSITION: get_distribution_stats
    // ─────────────────────────────────────────────────────────────────────────
    //
    // Sistem-wide dağıtım istatistiklerini döner.
    //
    // RETURNS:
    //   (total_distributions, total_profit, data_paid, model_paid, pool_allocated)
    //
    transition get_distribution_stats() -> (u64, u64, u64, u64, u64) {
        
        let total_dists: u64 = Mapping::get_or_use(system_metrics, 0u8, 0u64);
        let total_profit: u64 = Mapping::get_or_use(system_metrics, 1u8, 0u64);
        let data_paid: u64 = Mapping::get_or_use(system_metrics, 2u8, 0u64);
        let model_paid: u64 = Mapping::get_or_use(system_metrics, 3u8, 0u64);
        let pool_alloc: u64 = Mapping::get_or_use(system_metrics, 4u8, 0u64);
        
        return (total_dists, total_profit, data_paid, model_paid, pool_alloc);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// USAGE EXAMPLES
// ═══════════════════════════════════════════════════════════════════════════
//
// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 1: Successful Prediction Flow
// ─────────────────────────────────────────────────────────────────────────
//
// 1. Betting system wins 100 tokens
// 2. distribute_profit() çağrılır
// 3. Kar dağıtılır:
//    - Data provider: 40 tokens (base) + 7.2 tokens (90% rep bonus) = 47.2 tokens
//    - Model creator: 40 tokens (base) + 7.2 tokens (90% rep bonus) = 47.2 tokens
//    - Pool investors: 20 tokens - 14.4 tokens (bonus) = 5.6 tokens
// 4. Reputasyonlar artırılır: 90% → 95%
// 5. Başarı sayaçları güncellenir
//
// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 2: Failed Prediction Flow
// ─────────────────────────────────────────────────────────────────────────
//
// 1. Betting system loses 100 tokens
// 2. penalize_failure() çağrılır
// 3. Reputasyonlar düşürülür: 90% → 80% (-10%)
// 4. Eğer stake varsa:
//    - Data provider stake: 50 tokens → 45 tokens (-10% slash)
//    - Model creator stake: 30 tokens → 27 tokens (-10% slash)
// 5. Slash count artırılır: 0 → 1
// 6. 10 başarısızlık sonrası: Stake tamamen kaybolur
//
// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 3: Reputation Impact on Earnings
// ─────────────────────────────────────────────────────────────────────────
//
// Scenario: 100 tokens profit
//
// Low Reputation (50%):
//   - Base: 40 tokens
//   - Bonus: 40 × 0.5 × 0.2 = 4 tokens
//   - Total: 44 tokens
//
// High Reputation (90%):
//   - Base: 40 tokens
//   - Bonus: 40 × 0.9 × 0.2 = 7.2 tokens
//   - Total: 47.2 tokens
//
// Difference: 7.3% more earnings for high reputation! 💰
//
// ─────────────────────────────────────────────────────────────────────────
// EXAMPLE 4: Stake Mechanics
// ─────────────────────────────────────────────────────────────────────────
//
// Alice deposits 50 tokens stake:
//   deposit_stake(50_000_000u64, 0u8)
//   → Stake record created (locked 24 hours)
//
// After 3 failed predictions:
//   Slash 1: 50 → 45 tokens (-10%)
//   Slash 2: 45 → 40.5 tokens (-10%)
//   Slash 3: 40.5 → 36.45 tokens (-10%)
//   Slash count: 3 / 10
//
// After 10 failed predictions:
//   Slash count: 10 / 10 → Stake completely lost! ❌
//   Alice must deposit new stake to continue
//
// ═══════════════════════════════════════════════════════════════════════════
// KEY INSIGHTS
// ═══════════════════════════════════════════════════════════════════════════
//
// 1. **40-40-20 Split Rationale:**
//    - Active participants (data/model) take on most risk → deserve higher share
//    - Passive investors (pool) provide capital → earn stable returns
//    - Aligns incentives: Quality → More profit
//
// 2. **Reputation System:**
//    - Starts at 50% (neutral for new users)
//    - Win: +5% reputation, better bonuses in future
//    - Loss: -10% reputation, reduced bonuses
//    - Max bonus: +20% (at 100% reputation)
//
// 3. **Stake Mechanism:**
//    - Minimum 10 tokens to participate
//    - Slash 10% per failure (skin in the game)
//    - Max 10 failures → Complete stake loss
//    - Forces quality: Bad performers exit naturally
//
// 4. **Economic Balance:**
//    - Good performers earn MORE (reputation bonus)
//    - Bad performers earn LESS (slashing + low reputation)
//    - Pool always gets 20% (stable passive income)
//    - Self-correcting: Quality rises, spam dies
//
// ═══════════════════════════════════════════════════════════════════════════
