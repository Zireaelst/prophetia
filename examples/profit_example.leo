/*
═══════════════════════════════════════════════════════════════════════════════
PROPHETIA - Profit Distribution System Examples
═══════════════════════════════════════════════════════════════════════════════

Week 7: Kar Dağıtım Sistemi Usage Examples

Bu dosya profit_distribution.leo contract'ının nasıl kullanılacağını gösteren
kapsamlı örnekler içerir.

KAPSAM:
- Tek başarılı tahmin (profit distribution)
- Başarısız tahmin (reputation loss + stake slash)
- Çoklu tahminler (reputation evolution)
- Reputation impact karşılaştırması
- Stake lifecycle (deposit → slash → recover → withdraw)
- Full end-to-end integration

═══════════════════════════════════════════════════════════════════════════════
*/

program profit_example.aleo {
    /*
    ═══════════════════════════════════════════════════════════════════════════
    SCENARIO 1: Single Successful Prediction - Basic Profit Distribution
    ═══════════════════════════════════════════════════════════════════════════
    
    CONTEXT:
    - ZK-ML tahmin başarılı → Betting system kar etti → Profit distribution
    - Data provider: Alice (reputation 50%)
    - Model creator: Bob (reputation 50%)
    - Profit: 100 tokens
    
    EXPECTED OUTCOME:
    - Alice: 44 tokens (40 base + 4 bonus)
    - Bob: 44 tokens (40 base + 4 bonus)
    - Pool: 12 tokens (20 - 8 bonus)
    - Both reputations increase to 55%
    ═══════════════════════════════════════════════════════════════════════════
    */
    
    transition scenario_1_basic_distribution(
        profit_amount: u64,
        data_provider: address,
        model_creator: address,
        prediction_id: u64
    ) -> (ProfitShare, ProfitShare) {
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 1: DISTRIBUTE PROFIT
        // ═══════════════════════════════════════════════════════════════════
        
        // profit_amount = 100_000_000u64 (100 tokens × 1M scale)
        // prediction_id = 1u64
        
        let (data_share, model_share) = profit_distribution.aleo/distribute_profit(
            profit_amount,
            data_provider,
            model_creator,
            prediction_id
        );
        
        // ═══════════════════════════════════════════════════════════════════
        // SONUÇ:
        // ═══════════════════════════════════════════════════════════════════
        
        // data_share.amount = 44_000_000u64 (44 tokens)
        // data_share.reputation_bonus = 4_000_000u64 (4 tokens)
        // data_share.role = 0u8 (DATA_PROVIDER)
        
        // model_share.amount = 44_000_000u64 (44 tokens)
        // model_share.reputation_bonus = 4_000_000u64 (4 tokens)
        // model_share.role = 1u8 (MODEL_CREATOR)
        
        // Pool gets: 12_000_000u64 (12 tokens) via pool.aleo/record_profit()
        
        // ═══════════════════════════════════════════════════════════════════
        // REPUTATION UPDATE:
        // ═══════════════════════════════════════════════════════════════════
        
        // Alice: 500_000u64 → 550_000u64 (50% → 55%, +5%)
        // Bob: 500_000u64 → 550_000u64 (50% → 55%, +5%)
        
        return (data_share, model_share);
    }
    
    /*
    ═══════════════════════════════════════════════════════════════════════════
    SCENARIO 2: Failed Prediction - Penalty Mechanism
    ═══════════════════════════════════════════════════════════════════════════
    
    CONTEXT:
    - Tahmin yanlış çıktı → Loss → Penalty
    - Data provider: Alice (reputation 55%, stake 50 tokens)
    - Model creator: Bob (reputation 55%, stake 30 tokens)
    - Loss: 100 tokens
    
    EXPECTED OUTCOME:
    - Alice reputation: 55% → 45% (-10%)
    - Alice stake: 50 → 45 tokens (-10% slash)
    - Bob reputation: 55% → 45% (-10%)
    - Bob stake: 30 → 27 tokens (-10% slash)
    ═══════════════════════════════════════════════════════════════════════════
    */
    
    transition scenario_2_failed_prediction(
        data_provider: address,
        model_creator: address,
        loss_amount: u64
    ) {
        
        // ═══════════════════════════════════════════════════════════════════
        // CONTEXT: İLK DURUMLAR
        // ═══════════════════════════════════════════════════════════════════
        
        // Alice reputation: 550_000u64 (55%)
        // Alice stake: 50_000_000u64 (50 tokens)
        
        // Bob reputation: 550_000u64 (55%)
        // Bob stake: 30_000_000u64 (30 tokens)
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 1: PENALIZE FAILURE
        // ═══════════════════════════════════════════════════════════════════
        
        profit_distribution.aleo/penalize_failure(
            data_provider,
            model_creator,
            loss_amount  // 100_000_000u64 (100 tokens)
        );
        
        // ═══════════════════════════════════════════════════════════════════
        // SONUÇ:
        // ═══════════════════════════════════════════════════════════════════
        
        // Alice:
        // - Reputation: 550_000 - 100_000 = 450_000u64 (45%, -10%)
        // - Stake: 50_000_000 - 5_000_000 = 45_000_000u64 (45 tokens, -10%)
        // - Slash count: 0 → 1
        // - Contributions: +1 (failures da contribution)
        
        // Bob:
        // - Reputation: 550_000 - 100_000 = 450_000u64 (45%, -10%)
        // - Stake: 30_000_000 - 3_000_000 = 27_000_000u64 (27 tokens, -10%)
        // - Slash count: 0 → 1
        // - Contributions: +1
        
        return;
    }
    
    /*
    ═══════════════════════════════════════════════════════════════════════════
    SCENARIO 3: Multiple Rounds - Reputation Evolution
    ═══════════════════════════════════════════════════════════════════════════
    
    CONTEXT:
    - 5 tahmin: 3 win, 2 loss
    - Alice & Bob start at 50% reputation
    - Track reputation changes over time
    
    EXPECTED FLOW:
    1. Win → 50% → 55%
    2. Win → 55% → 60%
    3. Loss → 60% → 50%
    4. Win → 50% → 55%
    5. Loss → 55% → 45%
    
    FINAL: 45% reputation (3W/2L = 60% success rate)
    ═══════════════════════════════════════════════════════════════════════════
    */
    
    transition scenario_3_multiple_rounds(
        data_provider: address,
        model_creator: address
    ) -> u64 {
        
        // ═══════════════════════════════════════════════════════════════════
        // ROUND 1: WIN (100 tokens profit)
        // ═══════════════════════════════════════════════════════════════════
        
        let profit1: u64 = 100_000_000u64;
        let (data1, model1) = profit_distribution.aleo/distribute_profit(
            profit1,
            data_provider,
            model_creator,
            1u64
        );
        
        // Reputation: 50% → 55%
        // Alice earned: 44 tokens (40 + 4 bonus)
        
        // ═══════════════════════════════════════════════════════════════════
        // ROUND 2: WIN (150 tokens profit)
        // ═══════════════════════════════════════════════════════════════════
        
        let profit2: u64 = 150_000_000u64;
        let (data2, model2) = profit_distribution.aleo/distribute_profit(
            profit2,
            data_provider,
            model_creator,
            2u64
        );
        
        // Reputation: 55% → 60%
        // Alice earned: 66.6 tokens (60 + 6.6 bonus)
        
        // ═══════════════════════════════════════════════════════════════════
        // ROUND 3: LOSS (100 tokens loss)
        // ═══════════════════════════════════════════════════════════════════
        
        let loss1: u64 = 100_000_000u64;
        profit_distribution.aleo/penalize_failure(
            data_provider,
            model_creator,
            loss1
        );
        
        // Reputation: 60% → 50% (-10%)
        // Stake slashed: -10%
        
        // ═══════════════════════════════════════════════════════════════════
        // ROUND 4: WIN (120 tokens profit)
        // ═══════════════════════════════════════════════════════════════════
        
        let profit3: u64 = 120_000_000u64;
        let (data3, model3) = profit_distribution.aleo/distribute_profit(
            profit3,
            data_provider,
            model_creator,
            4u64
        );
        
        // Reputation: 50% → 55%
        // Alice earned: 52.8 tokens (48 + 4.8 bonus)
        
        // ═══════════════════════════════════════════════════════════════════
        // ROUND 5: LOSS (80 tokens loss)
        // ═══════════════════════════════════════════════════════════════════
        
        let loss2: u64 = 80_000_000u64;
        profit_distribution.aleo/penalize_failure(
            data_provider,
            model_creator,
            loss2
        );
        
        // Reputation: 55% → 45% (-10%)
        // Stake slashed again: -10%
        
        // ═══════════════════════════════════════════════════════════════════
        // FINAL STATISTICS
        // ═══════════════════════════════════════════════════════════════════
        
        let success_rate: u64 = profit_distribution.aleo/calculate_success_rate(
            data_provider
        );
        
        // Contributions: 5
        // Successes: 3
        // Success rate: (3 × 1_000_000) / 5 = 600_000 (60%)
        // Final reputation: 450_000 (45%)
        
        return success_rate;  // Returns 600_000u64 (60%)
    }
    
    /*
    ═══════════════════════════════════════════════════════════════════════════
    SCENARIO 4: Reputation Impact Comparison
    ═══════════════════════════════════════════════════════════════════════════
    
    CONTEXT:
    - Same profit (100 tokens) to 3 participants with different reputations:
      * Charlie: 30% reputation (low)
      * Diana: 50% reputation (neutral)
      * Eve: 90% reputation (high)
    
    EXPECTED EARNINGS:
    - Charlie: 42.4 tokens (40 + 2.4 bonus)
    - Diana: 44.0 tokens (40 + 4.0 bonus)
    - Eve: 47.2 tokens (40 + 7.2 bonus)
    
    INSIGHT: 90% rep earns 11% more than 30% rep (47.2 vs 42.4)
    ═══════════════════════════════════════════════════════════════════════════
    */
    
    transition scenario_4_reputation_comparison(
        charlie: address,  // 30% rep
        diana: address,    // 50% rep
        eve: address       // 90% rep
    ) -> (u64, u64, u64) {
        
        // ═══════════════════════════════════════════════════════════════════
        // SETUP: Set different reputations
        // ═══════════════════════════════════════════════════════════════════
        
        // Charlie reputation: 300_000u64 (30%)
        // Diana reputation: 500_000u64 (50%) - initial default
        // Eve reputation: 900_000u64 (90%)
        
        let profit: u64 = 100_000_000u64;  // 100 tokens
        
        // ═══════════════════════════════════════════════════════════════════
        // CHARLIE (30% reputation)
        // ═══════════════════════════════════════════════════════════════════
        
        let (charlie_data, charlie_model) = profit_distribution.aleo/distribute_profit(
            profit,
            charlie,
            diana,  // model creator doesn't matter for this comparison
            1u64
        );
        
        // Charlie:
        // Base: 40 tokens
        // Bonus multiplier: 0.3 × 0.2 = 0.06 (6%)
        // Bonus: 40 × 0.06 = 2.4 tokens
        // Total: 42.4 tokens
        
        let charlie_amount: u64 = charlie_data.amount;  // 42_400_000u64
        
        // ═══════════════════════════════════════════════════════════════════
        // DIANA (50% reputation)
        // ═══════════════════════════════════════════════════════════════════
        
        let (diana_data, diana_model) = profit_distribution.aleo/distribute_profit(
            profit,
            diana,
            charlie,
            2u64
        );
        
        // Diana:
        // Base: 40 tokens
        // Bonus multiplier: 0.5 × 0.2 = 0.10 (10%)
        // Bonus: 40 × 0.10 = 4.0 tokens
        // Total: 44.0 tokens
        
        let diana_amount: u64 = diana_data.amount;  // 44_000_000u64
        
        // ═══════════════════════════════════════════════════════════════════
        // EVE (90% reputation)
        // ═══════════════════════════════════════════════════════════════════
        
        let (eve_data, eve_model) = profit_distribution.aleo/distribute_profit(
            profit,
            eve,
            diana,
            3u64
        );
        
        // Eve:
        // Base: 40 tokens
        // Bonus multiplier: 0.9 × 0.2 = 0.18 (18%)
        // Bonus: 40 × 0.18 = 7.2 tokens
        // Total: 47.2 tokens
        
        let eve_amount: u64 = eve_data.amount;  // 47_200_000u64
        
        // ═══════════════════════════════════════════════════════════════════
        // COMPARISON
        // ═══════════════════════════════════════════════════════════════════
        
        // Eve vs Charlie: 47.2 / 42.4 = 1.113 (11.3% more)
        // Eve vs Diana: 47.2 / 44.0 = 1.073 (7.3% more)
        // Diana vs Charlie: 44.0 / 42.4 = 1.038 (3.8% more)
        
        return (charlie_amount, diana_amount, eve_amount);
    }
    
    /*
    ═══════════════════════════════════════════════════════════════════════════
    SCENARIO 5: Stake Lifecycle
    ═══════════════════════════════════════════════════════════════════════════
    
    CONTEXT:
    - Frank deposits 50 tokens stake
    - Experiences 3 failures (3 slashes)
    - Recovers with 5 wins
    - Withdraws remaining stake
    
    FLOW:
    1. Deposit 50 tokens → locked 24h
    2. 3 failures → 50 × 0.9³ = 36.45 tokens
    3. 5 wins → reputation recovery (no stake recovery)
    4. Withdraw 36.45 tokens (after lock expires)
    ═══════════════════════════════════════════════════════════════════════════
    */
    
    transition scenario_5_stake_lifecycle(
        frank: address,
        grace: address  // model creator partner
    ) -> u64 {
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 1: DEPOSIT STAKE
        // ═══════════════════════════════════════════════════════════════════
        
        let stake_amount: u64 = 50_000_000u64;  // 50 tokens
        let stake: Stake = profit_distribution.aleo/deposit_stake(
            stake_amount,
            0u8,  // role: DATA_PROVIDER
            frank
        );
        
        // Stake locked until: current_block + 86_400 blocks (24 hours)
        // Slash count reset to 0
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 2: 3 FAILURES (3 SLASHES)
        // ═══════════════════════════════════════════════════════════════════
        
        // Failure 1
        profit_distribution.aleo/penalize_failure(frank, grace, 100_000_000u64);
        // Stake: 50 → 45 tokens (-10%)
        // Slash count: 0 → 1
        
        // Failure 2
        profit_distribution.aleo/penalize_failure(frank, grace, 80_000_000u64);
        // Stake: 45 → 40.5 tokens (-10%)
        // Slash count: 1 → 2
        
        // Failure 3
        profit_distribution.aleo/penalize_failure(frank, grace, 120_000_000u64);
        // Stake: 40.5 → 36.45 tokens (-10%)
        // Slash count: 2 → 3
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 3: 5 WINS (REPUTATION RECOVERY)
        // ═══════════════════════════════════════════════════════════════════
        
        // Note: Wins increase reputation but DON'T restore slashed stake
        
        let profit: u64 = 100_000_000u64;
        
        // Win 1
        let (data1, model1) = profit_distribution.aleo/distribute_profit(
            profit, frank, grace, 1u64
        );
        // Reputation +5%
        
        // Win 2
        let (data2, model2) = profit_distribution.aleo/distribute_profit(
            profit, frank, grace, 2u64
        );
        // Reputation +5%
        
        // Win 3
        let (data3, model3) = profit_distribution.aleo/distribute_profit(
            profit, frank, grace, 3u64
        );
        // Reputation +5%
        
        // Win 4
        let (data4, model4) = profit_distribution.aleo/distribute_profit(
            profit, frank, grace, 4u64
        );
        // Reputation +5%
        
        // Win 5
        let (data5, model5) = profit_distribution.aleo/distribute_profit(
            profit, frank, grace, 5u64
        );
        // Reputation +5%
        
        // Final stats:
        // - Contributions: 3 + 5 = 8
        // - Successes: 5
        // - Success rate: (5 × 1_000_000) / 8 = 625_000 (62.5%)
        // - Reputation: 50% - 30% (3 losses) + 25% (5 wins) = 45%
        // - Stake: 36.45 tokens (slashes PERMANENT)
        
        // ═══════════════════════════════════════════════════════════════════
        // ADIM 4: WITHDRAW STAKE (after lock period)
        // ═══════════════════════════════════════════════════════════════════
        
        // Assuming 24h passed (86_400 blocks)
        // current_block >= stake.locked_until
        
        let withdrawn: u64 = profit_distribution.aleo/withdraw_stake(
            stake,
            frank
        );
        
        // withdrawn = 36_450_000u64 (36.45 tokens)
        // stake_amounts[frank] = 0u64 (cleared)
        // slash_counts[frank] = 0u64 (reset)
        
        return withdrawn;  // Returns 36_450_000u64
    }
    
    /*
    ═══════════════════════════════════════════════════════════════════════════
    SCENARIO 6: Full End-to-End Integration
    ═══════════════════════════════════════════════════════════════════════════
    
    CONTEXT:
    - Complete flow from data → model → inference → bet → win → distribute
    - Helen (data provider) & Ian (model creator)
    - Stake deposited, successful prediction, profit distribution
    
    FLOW:
    1. Helen deposits data NFT
    2. Ian deploys ZK-ML model
    3. Inference executed → Signal generated
    4. Betting system places bet based on signal
    5. Bet wins → Profit: 100 tokens
    6. Profit distributed: Helen + Ian + Pool
    ═══════════════════════════════════════════════════════════════════════════
    */
    
    transition scenario_6_full_integration(
        helen: address,  // Data provider
        ian: address     // Model creator
    ) -> (ProfitShare, ProfitShare) {
        
        // ═══════════════════════════════════════════════════════════════════
        // STEP 1: DATA UPLOAD (Assume already done via data_nft.aleo)
        // ═══════════════════════════════════════════════════════════════════
        
        // data_nft.aleo/mint_data_nft(...)
        // Result: DataNFT with market_data, historical_prices, etc.
        
        // ═══════════════════════════════════════════════════════════════════
        // STEP 2: MODEL DEPLOYMENT (Assume already done via zkml_verifier.aleo)
        // ═══════════════════════════════════════════════════════════════════
        
        // zkml_verifier.aleo/register_model(...)
        // Result: Model hash registered, ready for inference
        
        // ═══════════════════════════════════════════════════════════════════
        // STEP 3: INFERENCE EXECUTION (prediction_registry.aleo)
        // ═══════════════════════════════════════════════════════════════════
        
        // let signal: Signal = prediction_registry.aleo/create_prediction(...)
        // Signal contains:
        // - category: 0u8 (BULLISH)
        // - confidence: 850_000u64 (85%)
        // - target_value: 50_000u64 ($50k BTC price)
        // - proof: ZK proof
        
        // ═══════════════════════════════════════════════════════════════════
        // STEP 4: BET PLACEMENT (betting_system.aleo)
        // ═══════════════════════════════════════════════════════════════════
        
        // let position: BetPosition = betting_system.aleo/place_bet(...)
        // Position:
        // - bet_amount: 85 tokens (based on 85% confidence)
        // - target_value: 50_000u64
        // - expected payout: 170 tokens (2x)
        
        // ═══════════════════════════════════════════════════════════════════
        // STEP 5: BET SETTLEMENT - WIN
        // ═══════════════════════════════════════════════════════════════════
        
        // BTC actually goes to $51k (above target)
        // actual_value: 51_000u64
        
        // let (payout, is_win) = betting_system.aleo/settle_bet(...)
        // is_win = true
        // payout = 170 tokens
        // profit = payout - bet_amount = 170 - 85 = 85 tokens
        
        // ═══════════════════════════════════════════════════════════════════
        // STEP 6: PROFIT DISTRIBUTION (THIS CONTRACT)
        // ═══════════════════════════════════════════════════════════════════
        
        let profit: u64 = 85_000_000u64;  // 85 tokens profit
        let prediction_id: u64 = 12345u64;
        
        let (helen_share, ian_share) = profit_distribution.aleo/distribute_profit(
            profit,
            helen,  // data provider
            ian,    // model creator
            prediction_id
        );
        
        // ═══════════════════════════════════════════════════════════════════
        // RESULT (assuming both at 50% reputation):
        // ═══════════════════════════════════════════════════════════════════
        
        // Helen (data provider):
        // - Base: 85 × 0.4 = 34 tokens
        // - Bonus: 34 × 0.5 × 0.2 = 3.4 tokens
        // - Total: 37.4 tokens
        // - New reputation: 55%
        
        // helen_share.amount = 37_400_000u64
        // helen_share.reputation_bonus = 3_400_000u64
        // helen_share.role = 0u8 (DATA_PROVIDER)
        
        // Ian (model creator):
        // - Base: 85 × 0.4 = 34 tokens
        // - Bonus: 34 × 0.5 × 0.2 = 3.4 tokens
        // - Total: 37.4 tokens
        // - New reputation: 55%
        
        // ian_share.amount = 37_400_000u64
        // ian_share.reputation_bonus = 3_400_000u64
        // ian_share.role = 1u8 (MODEL_CREATOR)
        
        // Pool:
        // - Base: 85 × 0.2 = 17 tokens
        // - Adjusted: 17 - 6.8 (bonuses) = 10.2 tokens
        // - Sent via pool.aleo/record_profit()
        
        // ═══════════════════════════════════════════════════════════════════
        // VERIFICATION: Total conservation
        // ═══════════════════════════════════════════════════════════════════
        
        // Helen: 37.4
        // Ian: 37.4
        // Pool: 10.2
        // Total: 85.0 tokens ✓
        
        return (helen_share, ian_share);
    }
    
    /*
    ═══════════════════════════════════════════════════════════════════════════
    SCENARIO 7: Extreme Case - 10 Consecutive Failures (Complete Stake Loss)
    ═══════════════════════════════════════════════════════════════════════════
    
    CONTEXT:
    - Jack deposits 100 tokens stake
    - Experiences 10 consecutive failures
    - Stake gets completely wiped out
    - Reputation drops to near-zero
    
    OUTCOME:
    - After 10 failures: Stake = 0 tokens (MAX_SLASH_COUNT reached)
    - Reputation: 50% - 10×10% = 0% (MIN_REPUTATION)
    - System automatically exits Jack from active participation
    ═══════════════════════════════════════════════════════════════════════════
    */
    
    transition scenario_7_max_slashes(
        jack: address,
        kate: address  // model creator partner
    ) -> u64 {
        
        // ═══════════════════════════════════════════════════════════════════
        // INITIAL STATE
        // ═══════════════════════════════════════════════════════════════════
        
        // Deposit 100 tokens stake
        let stake_amount: u64 = 100_000_000u64;
        let stake: Stake = profit_distribution.aleo/deposit_stake(
            stake_amount,
            0u8,
            jack
        );
        
        // Initial:
        // - Stake: 100 tokens
        // - Reputation: 50%
        // - Slash count: 0
        
        // ═══════════════════════════════════════════════════════════════════
        // 10 CONSECUTIVE FAILURES
        // ═══════════════════════════════════════════════════════════════════
        
        let loss: u64 = 100_000_000u64;
        
        // Failure 1: 100 → 90 tokens, rep 50% → 40%
        profit_distribution.aleo/penalize_failure(jack, kate, loss);
        
        // Failure 2: 90 → 81 tokens, rep 40% → 30%
        profit_distribution.aleo/penalize_failure(jack, kate, loss);
        
        // Failure 3: 81 → 72.9 tokens, rep 30% → 20%
        profit_distribution.aleo/penalize_failure(jack, kate, loss);
        
        // Failure 4: 72.9 → 65.61 tokens, rep 20% → 10%
        profit_distribution.aleo/penalize_failure(jack, kate, loss);
        
        // Failure 5: 65.61 → 59.05 tokens, rep 10% → 0%
        profit_distribution.aleo/penalize_failure(jack, kate, loss);
        
        // Failure 6: 59.05 → 53.14 tokens, rep 0% (MIN)
        profit_distribution.aleo/penalize_failure(jack, kate, loss);
        
        // Failure 7: 53.14 → 47.83 tokens, rep 0% (MIN)
        profit_distribution.aleo/penalize_failure(jack, kate, loss);
        
        // Failure 8: 47.83 → 43.05 tokens, rep 0% (MIN)
        profit_distribution.aleo/penalize_failure(jack, kate, loss);
        
        // Failure 9: 43.05 → 38.74 tokens, rep 0% (MIN)
        profit_distribution.aleo/penalize_failure(jack, kate, loss);
        
        // Failure 10: 38.74 → 0 tokens (MAX_SLASH_COUNT reached)
        profit_distribution.aleo/penalize_failure(jack, kate, loss);
        
        // ═══════════════════════════════════════════════════════════════════
        // FINAL STATE
        // ═══════════════════════════════════════════════════════════════════
        
        let final_stake: u64 = profit_distribution.aleo/get_stake_amount(jack);
        
        // final_stake = 0u64 (completely lost)
        // slash_count = 10 (MAX reached)
        // reputation = 0u64 (MIN_REPUTATION)
        // contributions = 10
        // successes = 0
        // success_rate = 0%
        
        // Jack is now effectively ejected from the system:
        // - No stake to secure participation
        // - Zero reputation → no bonus earnings
        // - 0% success rate → no credibility
        
        return final_stake;  // Returns 0u64
    }
}

/*
═══════════════════════════════════════════════════════════════════════════════
DEPLOYMENT INSTRUCTIONS
═══════════════════════════════════════════════════════════════════════════════

1. BUILD CONTRACT:
   cd prophetia
   leo build profit_example.aleo

2. DEPLOY TO TESTNET:
   snarkos developer deploy \
     --private-key <YOUR_PRIVATE_KEY> \
     --query "https://api.explorer.aleo.org/v1" \
     --path ./build/ \
     --broadcast "https://api.explorer.aleo.org/v1/testnet/transaction/broadcast" \
     --fee 1000000 \
     --record <YOUR_RECORD>

3. EXECUTE SCENARIOS:
   
   # Scenario 1: Basic distribution
   snarkos developer execute \
     --private-key <KEY> \
     --query "https://api.explorer.aleo.org/v1" \
     --broadcast "https://api.explorer.aleo.org/v1/testnet/transaction/broadcast" \
     profit_example.aleo scenario_1_basic_distribution \
     100000000u64 \
     <alice_address> \
     <bob_address> \
     1u64

   # Scenario 3: Multiple rounds
   snarkos developer execute \
     --private-key <KEY> \
     --query "https://api.explorer.aleo.org/v1" \
     --broadcast "https://api.explorer.aleo.org/v1/testnet/transaction/broadcast" \
     profit_example.aleo scenario_3_multiple_rounds \
     <alice_address> \
     <bob_address>

   # Scenario 6: Full integration
   snarkos developer execute \
     --private-key <KEY> \
     --query "https://api.explorer.aleo.org/v1" \
     --broadcast "https://api.explorer.aleo.org/v1/testnet/transaction/broadcast" \
     profit_example.aleo scenario_6_full_integration \
     <helen_address> \
     <ian_address>

4. QUERY STATISTICS:
   
   # Get participant info
   snarkos developer execute \
     profit_distribution.aleo get_participant_info <address>
   
   # Get success rate
   snarkos developer execute \
     profit_distribution.aleo calculate_success_rate <address>
   
   # Get system stats
   snarkos developer execute \
     profit_distribution.aleo get_distribution_stats

═══════════════════════════════════════════════════════════════════════════════
KEY INSIGHTS FROM EXAMPLES
═══════════════════════════════════════════════════════════════════════════════

1. REPUTATION MATTERS:
   - 90% rep earns 11% more than 30% rep (47.2 vs 42.4 tokens)
   - Incentivizes quality over quantity
   - Reputation compounds over time

2. STAKE IS AT RISK:
   - Each failure: -10% stake permanently
   - 10 failures → Complete loss
   - Creates accountability

3. REPUTATION CAN RECOVER:
   - Wins increase reputation (+5%)
   - But stake slashes are PERMANENT
   - Balance between forgiveness and consequences

4. POOL GETS STABLE INCOME:
   - Always 20% base (adjusted down by bonuses)
   - Passive investors protected
   - Active participants earn more via reputation

5. SUCCESS RATE TRACKED:
   - Visible metric: successes / contributions
   - Different from reputation (which is adjusted ±5%/±10%)
   - Both affect earnings and credibility

6. ECONOMIC FLYWHEEL:
   - Good performance → High reputation → More earnings → More participation
   - Bad performance → Low reputation + Stake loss → Natural exit
   - System self-balances quality

═══════════════════════════════════════════════════════════════════════════════
*/
