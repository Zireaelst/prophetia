// ═══════════════════════════════════════════════════════════════════════════
// PROPHETIA LIQUIDITY POOL - Usage Examples
// ═══════════════════════════════════════════════════════════════════════════
//
// This example demonstrates how to use the liquidity pool system:
//   1. Multiple investors depositing
//   2. Pool earning profits from predictions
//   3. Pool incurring losses
//   4. Investors withdrawing with gains/losses
//
// SCENARIO: Three Investors & Market Performance
//   - Alice invests 100 tokens (early bird, large stake)
//   - Bob invests 50 tokens (moderate investment)
//   - Charlie invests 25 tokens (small player)
//   - Pool makes 3 predictions: 2 wins, 1 loss
//   - All investors withdraw and compare returns
//
// ═══════════════════════════════════════════════════════════════════════════

import prophetia_pool.aleo;

program pool_usage_example.aleo {
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 1: First Investor (Alice)
    // ───────────────────────────────────────────────────────────────────────
    
    /// Alice deposits 100 tokens as the first investor
    ///
    /// Initial Pool State:
    ///   total_liquidity: 0
    ///   total_shares: 0
    ///
    /// After Alice's deposit:
    ///   total_liquidity: 100 tokens
    ///   total_shares: 100 shares
    ///   Alice's share value: 1.0 token/share (1:1 ratio)
    ///
    transition alice_deposits() -> prophetia_pool.PoolShare {
        let alice_deposit: u64 = 100000000u64;  // 100.0 tokens
        
        // Alice calls deposit_liquidity on the pool
        let alice_shares: prophetia_pool.PoolShare = prophetia_pool.aleo/deposit_liquidity(alice_deposit);
        
        // Alice receives PoolShare record:
        // {
        //   owner: alice_address,
        //   amount: 100,000,000 (100 shares),
        //   pool_id: 0,
        //   _nonce: ...
        // }
        
        return alice_shares;
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 2: Second Investor (Bob)
    // ───────────────────────────────────────────────────────────────────────
    
    /// Bob deposits 50 tokens after Alice
    ///
    /// Pool State Before Bob:
    ///   total_liquidity: 100 tokens
    ///   total_shares: 100 shares
    ///
    /// Bob's Share Calculation:
    ///   shares = (50 × 100) / 100 = 50 shares
    ///
    /// After Bob's deposit:
    ///   total_liquidity: 150 tokens
    ///   total_shares: 150 shares
    ///   Bob's share value: 1.0 token/share (fair!)
    ///
    transition bob_deposits() -> prophetia_pool.PoolShare {
        let bob_deposit: u64 = 50000000u64;  // 50.0 tokens
        
        let bob_shares: prophetia_pool.PoolShare = prophetia_pool.aleo/deposit_liquidity(bob_deposit);
        
        // Bob receives:
        // {
        //   owner: bob_address,
        //   amount: 50,000,000 (50 shares),
        //   pool_id: 0,
        //   _nonce: ...
        // }
        
        return bob_shares;
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 3: Third Investor (Charlie)
    // ───────────────────────────────────────────────────────────────────────
    
    /// Charlie deposits 25 tokens (smallest investor)
    ///
    /// Pool State Before Charlie:
    ///   total_liquidity: 150 tokens
    ///   total_shares: 150 shares
    ///
    /// Charlie's Share Calculation:
    ///   shares = (25 × 150) / 150 = 25 shares
    ///
    /// After Charlie's deposit:
    ///   total_liquidity: 175 tokens
    ///   total_shares: 175 shares
    ///   Charlie's share value: 1.0 token/share
    ///
    /// Ownership Breakdown:
    ///   Alice: 100/175 = 57.14%
    ///   Bob: 50/175 = 28.57%
    ///   Charlie: 25/175 = 14.29%
    ///
    transition charlie_deposits() -> prophetia_pool.PoolShare {
        let charlie_deposit: u64 = 25000000u64;  // 25.0 tokens
        
        let charlie_shares: prophetia_pool.PoolShare = prophetia_pool.aleo/deposit_liquidity(charlie_deposit);
        
        // Charlie receives:
        // {
        //   owner: charlie_address,
        //   amount: 25,000,000 (25 shares),
        //   pool_id: 0,
        //   _nonce: ...
        // }
        
        return charlie_shares;
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 4: First Prediction (WIN - Pool Earns 35 Tokens)
    // ───────────────────────────────────────────────────────────────────────
    
    /// Pool makes a successful prediction and earns 35 tokens profit
    ///
    /// Pool State Before Profit:
    ///   total_liquidity: 175 tokens
    ///   total_shares: 175 shares
    ///   share_value: 1.0 token/share
    ///
    /// After 35 Token Profit:
    ///   total_liquidity: 210 tokens (+35)
    ///   total_shares: 175 shares (unchanged)
    ///   share_value: 1.2 tokens/share (+20% gain!)
    ///
    /// Investor Value Breakdown:
    ///   Alice: 100 shares × 1.2 = 120 tokens (was 100, +20 profit)
    ///   Bob: 50 shares × 1.2 = 60 tokens (was 50, +10 profit)
    ///   Charlie: 25 shares × 1.2 = 30 tokens (was 25, +5 profit)
    ///
    transition prediction_win_1() {
        let profit: u64 = 35000000u64;  // 35.0 tokens profit
        
        // Pool contract calls record_profit
        prophetia_pool.aleo/record_profit(profit);
        
        // Share value automatically increased for ALL investors!
        // No manual distribution needed - economic magic! ✨
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 5: Second Prediction (WIN - Pool Earns 20 Tokens)
    // ───────────────────────────────────────────────────────────────────────
    
    /// Another successful prediction, pool earns 20 more tokens
    ///
    /// Pool State Before:
    ///   total_liquidity: 210 tokens
    ///   total_shares: 175 shares
    ///   share_value: 1.2 tokens/share
    ///
    /// After 20 Token Profit:
    ///   total_liquidity: 230 tokens (+20)
    ///   total_shares: 175 shares
    ///   share_value: 1.314 tokens/share (+31.4% total gain!)
    ///
    /// Investor Values:
    ///   Alice: 100 shares × 1.314 = 131.4 tokens (+31.4 profit)
    ///   Bob: 50 shares × 1.314 = 65.7 tokens (+15.7 profit)
    ///   Charlie: 25 shares × 1.314 = 32.85 tokens (+7.85 profit)
    ///
    transition prediction_win_2() {
        let profit: u64 = 20000000u64;  // 20.0 tokens profit
        
        prophetia_pool.aleo/record_profit(profit);
        
        // Pool is performing well! Investors happy! 😊
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 6: Third Prediction (LOSS - Pool Loses 15 Tokens)
    // ───────────────────────────────────────────────────────────────────────
    
    /// Pool makes a bad prediction and loses 15 tokens
    ///
    /// Pool State Before:
    ///   total_liquidity: 230 tokens
    ///   total_shares: 175 shares
    ///   share_value: 1.314 tokens/share
    ///
    /// After 15 Token Loss:
    ///   total_liquidity: 215 tokens (-15)
    ///   total_shares: 175 shares
    ///   share_value: 1.229 tokens/share (+22.9% total)
    ///
    /// Investor Values:
    ///   Alice: 100 shares × 1.229 = 122.9 tokens (+22.9 profit still!)
    ///   Bob: 50 shares × 1.229 = 61.45 tokens (+11.45 profit)
    ///   Charlie: 25 shares × 1.229 = 30.72 tokens (+5.72 profit)
    ///
    /// Despite one loss, pool still up 22.9% overall!
    ///
    transition prediction_loss_1() {
        let loss: u64 = 15000000u64;  // 15.0 tokens loss
        
        prophetia_pool.aleo/record_loss(loss);
        
        // Losses distributed fairly across all shareholders
        // But still profitable overall! 📈
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 7: Check Pool Statistics
    // ───────────────────────────────────────────────────────────────────────
    
    /// Query pool performance metrics
    ///
    /// Returns:
    ///   total_liquidity: 215 tokens
    ///   total_shares: 175 shares
    ///   total_bets: 3 (number of predictions)
    ///   total_profit: 55 tokens (35 + 20)
    ///   total_loss: 15 tokens
    ///   Net profit: 40 tokens (22.9% ROI)
    ///
    transition check_pool_performance() -> (u64, u64, u64, u64, u64) {
        let stats: (u64, u64, u64, u64, u64) = prophetia_pool.aleo/get_pool_stats();
        
        // Unpack the stats
        let total_liq: u64 = stats.0;     // 215,000,000 (215 tokens)
        let total_shares: u64 = stats.1;  // 175,000,000 (175 shares)
        let total_bets: u64 = stats.2;    // 3 bets
        let total_profit: u64 = stats.3;  // 55,000,000 (55 tokens)
        let total_loss: u64 = stats.4;    // 15,000,000 (15 tokens)
        
        // Net profit = 55 - 15 = 40 tokens
        // ROI = 40 / 175 = 22.9%
        
        return stats;
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 8: Alice Withdraws (Full Exit)
    // ───────────────────────────────────────────────────────────────────────
    
    /// Alice decides to cash out all her shares
    ///
    /// Alice's Position:
    ///   shares: 100
    ///   current_value: (100 × 215) / 175 = 122.86 tokens
    ///   initial_deposit: 100 tokens
    ///   profit: 22.86 tokens (22.86% return!)
    ///
    /// After Alice's withdrawal:
    ///   total_liquidity: 92.14 tokens
    ///   total_shares: 75 shares
    ///   Bob and Charlie's share value: UNCHANGED at 1.229
    ///
    transition alice_withdraws(alice_shares: prophetia_pool.PoolShare) -> u64 {
        // Alice burns her shares and receives tokens
        let withdrawal: u64 = prophetia_pool.aleo/withdraw_liquidity(alice_shares);
        
        // Alice receives approximately 122,860,000 (122.86 tokens)
        // Profit: 22.86 tokens (22.86% ROI)
        // Alice is happy! 💰
        
        return withdrawal;
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 9: Check Alice's Share Value Before Withdrawal
    // ───────────────────────────────────────────────────────────────────────
    
    /// Alice can check her share value without withdrawing
    ///
    transition alice_checks_value(alice_shares: prophetia_pool.PoolShare) -> u64 {
        let current_value: u64 = prophetia_pool.aleo/calculate_share_value(alice_shares);
        
        // Returns: 122,860,000 (122.86 tokens)
        // This is a read-only operation - shares not consumed
        
        return current_value;
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 10: Bob Withdraws Partially (Keeps Some Exposure)
    // ───────────────────────────────────────────────────────────────────────
    
    /// Bob withdraws but wants to keep some shares in the pool
    ///
    /// Note: In this simplified example, we withdraw all of Bob's shares.
    /// For partial withdrawal, Bob would need to split his PoolShare record first
    /// (feature for future implementation).
    ///
    /// Bob's Position:
    ///   shares: 50
    ///   current_value: (50 × 92.14) / 75 = 61.43 tokens
    ///   initial_deposit: 50 tokens
    ///   profit: 11.43 tokens (22.86% return - same ROI as Alice!)
    ///
    transition bob_withdraws(bob_shares: prophetia_pool.PoolShare) -> u64 {
        let withdrawal: u64 = prophetia_pool.aleo/withdraw_liquidity(bob_shares);
        
        // Bob receives approximately 61,430,000 (61.43 tokens)
        // Profit: 11.43 tokens (22.86% ROI)
        // Fair distribution confirmed! ✅
        
        return withdrawal;
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 11: Charlie Withdraws (Smallest Investor)
    // ───────────────────────────────────────────────────────────────────────
    
    /// Charlie (smallest investor) also withdraws
    ///
    /// Charlie's Position:
    ///   shares: 25
    ///   current_value: (25 × 30.71) / 25 = 30.71 tokens
    ///   initial_deposit: 25 tokens
    ///   profit: 5.71 tokens (22.86% return - SAME as Alice and Bob!)
    ///
    /// This proves the fairness of the liquidity pool:
    ///   All investors get the same % return regardless of size!
    ///
    transition charlie_withdraws(charlie_shares: prophetia_pool.PoolShare) -> u64 {
        let withdrawal: u64 = prophetia_pool.aleo/withdraw_liquidity(charlie_shares);
        
        // Charlie receives approximately 30,710,000 (30.71 tokens)
        // Profit: 5.71 tokens (22.86% ROI)
        // Small investors protected! 🛡️
        
        return withdrawal;
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // EXAMPLE 12: Multi-Step Investment Journey
    // ───────────────────────────────────────────────────────────────────────
    
    /// Comprehensive example showing entire lifecycle
    ///
    /// This transition demonstrates:
    ///   1. Deposit funds
    ///   2. Wait for pool performance
    ///   3. Check value anytime
    ///   4. Withdraw when desired
    ///
    transition full_investment_lifecycle() -> (prophetia_pool.PoolShare, u64, u64) {
        // Step 1: Investor deposits 75 tokens
        let deposit_amount: u64 = 75000000u64;
        let shares: prophetia_pool.PoolShare = prophetia_pool.aleo/deposit_liquidity(deposit_amount);
        
        // Step 2: Time passes, pool makes profits/losses...
        // (simulated by other investors' actions in above examples)
        
        // Step 3: Check current value (non-destructive)
        let current_value: u64 = prophetia_pool.aleo/calculate_share_value(shares);
        
        // Step 4: Decide to withdraw
        let withdrawal: u64 = prophetia_pool.aleo/withdraw_liquidity(shares);
        
        // Returns:
        //   - Original PoolShare record (consumed)
        //   - Current value checked
        //   - Withdrawal amount received
        
        return (shares, current_value, withdrawal);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// DEPLOYMENT & TESTING GUIDE
// ═══════════════════════════════════════════════════════════════════════════

/*

STEP-BY-STEP USAGE
──────────────────

1. DEPLOY THE POOL CONTRACT
   
   cd contracts
   leo deploy prophetia_pool.aleo --network testnet


2. ALICE DEPOSITS (First Investor)
   
   leo execute alice_deposits --network testnet
   
   Output: PoolShare record with 100,000,000 shares


3. BOB DEPOSITS (Second Investor)
   
   leo execute bob_deposits --network testnet
   
   Output: PoolShare record with 50,000,000 shares


4. CHARLIE DEPOSITS (Third Investor)
   
   leo execute charlie_deposits --network testnet
   
   Output: PoolShare record with 25,000,000 shares


5. FIRST WIN (Pool Profits)
   
   leo execute prediction_win_1 --network testnet
   
   Effect: All share values increase by 20%


6. SECOND WIN (More Profits)
   
   leo execute prediction_win_2 --network testnet
   
   Effect: Share values now up 31.4% total


7. ONE LOSS (Setback)
   
   leo execute prediction_loss_1 --network testnet
   
   Effect: Share values decrease slightly, still +22.9% overall


8. CHECK PERFORMANCE
   
   leo execute check_pool_performance --network testnet
   
   Output: (215000000, 175000000, 3, 55000000, 15000000)
   Interpretation:
     - 215 tokens in pool
     - 175 shares outstanding
     - 3 bets made
     - 55 tokens total profit
     - 15 tokens total loss
     - Net: +40 tokens (22.9% ROI)


9. ALICE CHECKS VALUE (Before Withdrawing)
   
   leo execute alice_checks_value [alice_poolshare_record] --network testnet
   
   Output: 122860000 (122.86 tokens)


10. ALICE WITHDRAWS
    
    leo execute alice_withdraws [alice_poolshare_record] --network testnet
    
    Output: 122860000 (122.86 tokens)
    Profit: 22.86 tokens (22.86% return)


11. BOB WITHDRAWS
    
    leo execute bob_withdraws [bob_poolshare_record] --network testnet
    
    Output: 61430000 (61.43 tokens)
    Profit: 11.43 tokens (22.86% return - SAME %)


12. CHARLIE WITHDRAWS
    
    leo execute charlie_withdraws [charlie_poolshare_record] --network testnet
    
    Output: 30710000 (30.71 tokens)
    Profit: 5.71 tokens (22.86% return - FAIR!)


KEY INSIGHTS
────────────

✅ Fair Distribution
   All investors (Alice, Bob, Charlie) earned the same 22.86% ROI
   regardless of their investment size.

✅ Automatic Profit/Loss Sharing
   No manual calculations needed - share value updates automatically
   when pool earns profits or incurs losses.

✅ Transparent Performance
   Anyone can query pool statistics at any time using get_pool_stats.

✅ No Lock-Up Period
   Investors can withdraw anytime - full liquidity!

✅ Proportional Ownership
   Shares represent fair percentage of pool regardless of entry time.

✅ Secure
   Records ensure only owners can withdraw their shares.


ECONOMICS SUMMARY
─────────────────

Initial Investments:
  Alice: 100 tokens (57.14%)
  Bob: 50 tokens (28.57%)
  Charlie: 25 tokens (14.29%)
  Total: 175 tokens

Pool Performance:
  Prediction 1: +35 tokens (WIN)
  Prediction 2: +20 tokens (WIN)
  Prediction 3: -15 tokens (LOSS)
  Net: +40 tokens (+22.86%)

Final Withdrawals:
  Alice: 122.86 tokens (+22.86 profit)
  Bob: 61.43 tokens (+11.43 profit)
  Charlie: 30.71 tokens (+5.71 profit)
  Total: 215 tokens

Verification:
  175 (initial) + 40 (net profit) = 215 ✅
  All investors share same 22.86% ROI ✅


RISK CONSIDERATIONS
───────────────────

⚠️ Pool Can Lose Money
   If predictions fail, share value decreases.
   Investors share losses proportionally.

⚠️ No Guaranteed Returns
   Past performance doesn't guarantee future results.
   Pool success depends on prediction accuracy.

⚠️ Liquidity Risk
   If pool runs out of capital, withdrawals may be limited.
   (Future: implement withdrawal queue or insurance fund)

✅ Mitigations
   - Diversified prediction portfolio
   - Conservative bet sizing
   - Multiple ML algorithms (from Week 4!)
   - Transparent pool statistics


NEXT STEPS
──────────

Week 6: Frontend dashboard to visualize pool performance
Week 7: Integration with prediction betting system
Week 8: Advanced economics (fees, insurance fund)
Week 9: Reputation system for pool managers
Week 10: Security audit and optimization

*/
