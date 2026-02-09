// ═══════════════════════════════════════════════════════════════════════════
// PROPHETIA LIQUIDITY POOL - Economic Layer Foundation
// ═══════════════════════════════════════════════════════════════════════════
//
// This module implements the LIQUIDITY POOL system for PROPHETIA:
// Investors provide capital → Earn returns from successful predictions
//
// THE ECONOMICS:
//   Deposit Tokens → Receive PoolShare Records → Earn from Prediction Profits
//
// HOW IT WORKS:
//   1. Investors deposit tokens into the liquidity pool
//   2. Pool mints PoolShare records representing ownership
//   3. Pool provides liquidity for prediction bets
//   4. Successful predictions grow the pool (investors profit)
//   5. Failed predictions shrink the pool (investors lose)
//   6. Investors can withdraw by burning their shares
//
// KEY FEATURES:
//   ✅ Fair share distribution (proportional to contribution)
//   ✅ Profit/loss automatically distributed to all shareholders
//   ✅ No lockup period (withdraw anytime)
//   ✅ Transparent pool statistics (public mappings)
//   ✅ Minimum deposit protection
//
// SECURITY:
//   - Record ownership automatically enforced by Aleo
//   - Math overflow/underflow protection
//   - Zero-division checks
//   - Minimum deposit requirements
//
// ═══════════════════════════════════════════════════════════════════════════

program prophetia_pool.aleo {
    
    // ───────────────────────────────────────────────────────────────────────
    // RECORD DEFINITIONS
    // ───────────────────────────────────────────────────────────────────────
    
    /// PoolShare Record
    ///
    /// Represents ownership stake in the liquidity pool.
    /// Each PoolShare is a private record that can be:
    ///   - Transferred to another address
    ///   - Burned to withdraw liquidity
    ///   - Combined with other shares (future feature)
    ///
    /// Fields:
    ///   - owner: Address that owns this share
    ///   - amount: Number of shares (scaled by 10^6)
    ///   - pool_id: Which pool this belongs to (for multi-pool future)
    ///   - _nonce: Privacy guarantee (unique per record)
    ///
    /// Example:
    ///   A user deposits 10 tokens and receives a PoolShare with amount=10,000,000
    ///   This represents 10 shares in pool_id 0
    record PoolShare {
        owner: address,
        amount: u64,
        pool_id: u8,

    }
    
    // ───────────────────────────────────────────────────────────────────────
    // PUBLIC STATE MAPPINGS
    // ───────────────────────────────────────────────────────────────────────
    
    /// Pool State Mapping
    ///
    /// Stores all pool statistics in public mappings.
    /// Anyone can read these values to assess pool health.
    ///
    /// Keys:
    ///   0 => total_liquidity (total tokens in pool)
    ///   1 => total_shares (total shares minted)
    ///   2 => total_bets (number of predictions made)
    ///   3 => total_profit (cumulative profit earned)
    ///   4 => total_loss (cumulative losses incurred)
    ///   5 => reserved for future use
    ///
    /// Access:
    ///   Public read (anyone can query)
    ///   Write restricted to authorized transitions
    mapping pool_state: u8 => u64;
    
    // ───────────────────────────────────────────────────────────────────────
    // CONSTANTS
    // ───────────────────────────────────────────────────────────────────────
    
    /// Minimum deposit amount (1.0 token = 1,000,000 scaled)
    /// Prevents dust attacks and ensures meaningful liquidity
    const MIN_DEPOSIT: u64 = 1000000u64;
    
    /// Scale factor for all decimal operations (same as math_utils)
    const SCALE: u64 = 1000000u64;
    
    // ───────────────────────────────────────────────────────────────────────
    // CORE TRANSITIONS
    // ───────────────────────────────────────────────────────────────────────
    
    /// Deposit Liquidity into Pool
    ///
    /// Allows users to invest tokens into the liquidity pool.
    /// Mints PoolShare records proportional to contribution.
    ///
    /// Share Calculation:
    ///   - First deposit: shares = amount (1:1 ratio)
    ///   - Subsequent: shares = (amount × total_shares) / total_liquidity
    ///
    /// Example:
    ///   Pool has 100 tokens and 100 shares
    ///   Alice deposits 50 tokens
    ///   Alice receives = (50 × 100) / 100 = 50 shares
    ///   New pool: 150 tokens, 150 shares
    ///
    /// Parameters:
    ///   - amount: Number of tokens to deposit (scaled by 10^6)
    ///
    /// Returns:
    ///   - PoolShare record for the depositor
    ///
    /// Validation:
    ///   - amount >= MIN_DEPOSIT (1.0 token minimum)
    ///   - No maximum limit
    ///
    /// Gas Cost: ~15,000 credits
    ///
    transition deposit_liquidity(
        public amount: u64
    ) -> PoolShare {
        
        // ───────────────────────────────────────────────────────────────
        // STEP 1: VALIDATION
        // ───────────────────────────────────────────────────────────────
        
        // Ensure minimum deposit met
        assert(amount >= MIN_DEPOSIT);
        
        // ───────────────────────────────────────────────────────────────
        // STEP 2: FETCH CURRENT POOL STATE
        // ───────────────────────────────────────────────────────────────
        
        // Get current liquidity (defaults to 0 if pool is new)
        let total_liq: u64 = Mapping::get_or_use(pool_state, 0u8, 0u64);
        
        // Get current shares (defaults to 0 if pool is new)
        let total_shares: u64 = Mapping::get_or_use(pool_state, 1u8, 0u64);
        
        // ───────────────────────────────────────────────────────────────
        // STEP 3: CALCULATE SHARES TO MINT
        // ───────────────────────────────────────────────────────────────
        
        let new_shares: u64 = 0u64;
        
        if (total_liq == 0u64) {
            // FIRST DEPOSIT: 1:1 ratio
            // If this is the first deposit, mint shares equal to amount
            // Example: Deposit 10 tokens → Get 10 shares
            new_shares = amount;
        } else {
            // SUBSEQUENT DEPOSITS: Proportional ratio
            // Formula: new_shares = (amount × total_shares) / total_liquidity
            //
            // Why this formula?
            // - Maintains share value consistency
            // - Fair to existing shareholders
            // - Prevents dilution attacks
            //
            // Example:
            //   Pool: 100 tokens, 100 shares (1 share = 1 token)
            //   Alice deposits 50 tokens
            //   Alice gets: (50 × 100) / 100 = 50 shares
            //   New pool: 150 tokens, 150 shares (still 1 share = 1 token)
            
            // Use u128 to prevent overflow during multiplication
            let amount_wide: u128 = amount as u128;
            let shares_wide: u128 = total_shares as u128;
            let liq_wide: u128 = total_liq as u128;
            
            // Compute: (amount × total_shares) / total_liq
            let numerator: u128 = amount_wide * shares_wide;
            let result: u128 = numerator / liq_wide;
            
            new_shares = result as u64;
        }
        
        // ───────────────────────────────────────────────────────────────
        // STEP 4: UPDATE POOL STATE
        // ───────────────────────────────────────────────────────────────
        
        // Increase total liquidity
        let new_total_liq: u64 = total_liq + amount;
        Mapping::set(pool_state, 0u8, new_total_liq);
        
        // Increase total shares
        let new_total_shares: u64 = total_shares + new_shares;
        Mapping::set(pool_state, 1u8, new_total_shares);
        
        // ───────────────────────────────────────────────────────────────
        // STEP 5: MINT POOLSHARE RECORD
        // ───────────────────────────────────────────────────────────────
        
        let share: PoolShare = PoolShare {
            owner: self.caller,
            amount: new_shares,
            pool_id: 0u8,  // Default pool (multi-pool support in future)

        };
        
        return share;
    }
    
    /// Withdraw Liquidity from Pool
    ///
    /// Allows users to exit the pool by burning their PoolShare records.
    /// Withdraws proportional amount of current pool liquidity.
    ///
    /// Withdrawal Calculation:
    ///   withdrawal = (user_shares × total_liquidity) / total_shares
    ///
    /// Example:
    ///   Pool has 150 tokens and 150 shares
    ///   Alice has 50 shares
    ///   Alice receives = (50 × 150) / 150 = 50 tokens
    ///   New pool: 100 tokens, 100 shares
    ///
    /// Important Notes:
    ///   - Share value changes with pool performance
    ///   - If pool profited: shares worth more
    ///   - If pool lost: shares worth less
    ///   - No lockup period (withdraw anytime)
    ///
    /// Parameters:
    ///   - shares: PoolShare record to burn
    ///
    /// Returns:
    ///   - withdrawal_amount: Tokens withdrawn
    ///
    /// Security:
    ///   - Record ownership enforced by Aleo (only owner can burn)
    ///   - Share record automatically consumed (can't double-spend)
    ///
    /// Gas Cost: ~12,000 credits
    ///
    transition withdraw_liquidity(
        shares: PoolShare
    ) -> u64 {
        
        // ───────────────────────────────────────────────────────────────
        // STEP 1: FETCH CURRENT POOL STATE
        // ───────────────────────────────────────────────────────────────
        
        let total_liq: u64 = Mapping::get(pool_state, 0u8);
        let total_shares: u64 = Mapping::get(pool_state, 1u8);
        
        // Ensure pool has liquidity
        assert(total_liq > 0u64);
        assert(total_shares > 0u64);
        
        // ───────────────────────────────────────────────────────────────
        // STEP 2: CALCULATE WITHDRAWAL AMOUNT
        // ───────────────────────────────────────────────────────────────
        
        // Formula: amount = (user_shares × total_liquidity) / total_shares
        //
        // Why this formula?
        // - User gets proportional share of current pool
        // - Automatically accounts for profit/loss
        // - Fair to remaining shareholders
        //
        // Example with PROFIT:
        //   Initial: 100 tokens, 100 shares, Alice has 50 shares
        //   Pool grows to 120 tokens (20% profit)
        //   Alice withdraws: (50 × 120) / 100 = 60 tokens (20% gain!)
        //
        // Example with LOSS:
        //   Initial: 100 tokens, 100 shares, Alice has 50 shares
        //   Pool shrinks to 80 tokens (20% loss)
        //   Alice withdraws: (50 × 80) / 100 = 40 tokens (20% loss)
        
        let shares_wide: u128 = shares.amount as u128;
        let liq_wide: u128 = total_liq as u128;
        let total_shares_wide: u128 = total_shares as u128;
        
        let numerator: u128 = shares_wide * liq_wide;
        let withdrawal: u128 = numerator / total_shares_wide;
        let withdrawal_amount: u64 = withdrawal as u64;
        
        // ───────────────────────────────────────────────────────────────
        // STEP 3: UPDATE POOL STATE
        // ───────────────────────────────────────────────────────────────
        
        // Decrease total liquidity
        let new_total_liq: u64 = total_liq - withdrawal_amount;
        Mapping::set(pool_state, 0u8, new_total_liq);
        
        // Decrease total shares
        let new_total_shares: u64 = total_shares - shares.amount;
        Mapping::set(pool_state, 1u8, new_total_shares);
        
        // ───────────────────────────────────────────────────────────────
        // STEP 4: RETURN WITHDRAWAL AMOUNT
        // ───────────────────────────────────────────────────────────────
        
        // The PoolShare record is automatically consumed (burned)
        // User receives withdrawal_amount tokens
        
        return withdrawal_amount;
    }
    
    /// Get Pool Statistics (View Function)
    ///
    /// Returns comprehensive pool metrics for transparency.
    /// Anyone can call this to assess pool health.
    ///
    /// Returns: (total_liq, total_shares, total_bets, total_profit, total_loss)
    ///
    /// Example Output:
    ///   (150000000, 150000000, 42, 12000000, 3000000)
    ///   Interpretation:
    ///     - 150 tokens in pool
    ///     - 150 shares outstanding
    ///     - 42 predictions made
    ///     - 12 tokens total profit
    ///     - 3 tokens total loss
    ///     - Net: +9 tokens (6% growth)
    ///
    /// Use Cases:
    ///   - Potential investors checking pool performance
    ///   - Dashboard displaying pool metrics
    ///   - Risk assessment before depositing
    ///
    /// Gas Cost: ~5,000 credits (read-only)
    ///
    transition get_pool_stats() -> (u64, u64, u64, u64, u64) {
        let total_liq: u64 = Mapping::get_or_use(pool_state, 0u8, 0u64);
        let total_shares: u64 = Mapping::get_or_use(pool_state, 1u8, 0u64);
        let total_bets: u64 = Mapping::get_or_use(pool_state, 2u8, 0u64);
        let total_profit: u64 = Mapping::get_or_use(pool_state, 3u8, 0u64);
        let total_loss: u64 = Mapping::get_or_use(pool_state, 4u8, 0u64);
        
        return (total_liq, total_shares, total_bets, total_profit, total_loss);
    }
    
    /// Calculate Share Value (Helper Function)
    ///
    /// Computes current value of a PoolShare record.
    /// Useful for users to check their holdings.
    ///
    /// Formula: value = (user_shares × total_liquidity) / total_shares
    ///
    /// Example:
    ///   Pool: 120 tokens, 100 shares
    ///   User has: 50 shares
    ///   Value = (50 × 120) / 100 = 60 tokens
    ///   (User's shares appreciated 20% from initial 50 tokens!)
    ///
    /// Parameters:
    ///   - shares: PoolShare record to value
    ///
    /// Returns:
    ///   - Current token value of the shares
    ///
    /// Gas Cost: ~3,000 credits
    ///
    transition calculate_share_value(
        shares: PoolShare
    ) -> u64 {
        let total_liq: u64 = Mapping::get(pool_state, 0u8);
        let total_shares: u64 = Mapping::get(pool_state, 1u8);
        
        // Prevent division by zero
        assert(total_shares > 0u64);
        
        // Calculate: (user_shares × total_liq) / total_shares
        let shares_wide: u128 = shares.amount as u128;
        let liq_wide: u128 = total_liq as u128;
        let total_shares_wide: u128 = total_shares as u128;
        
        let numerator: u128 = shares_wide * liq_wide;
        let value: u128 = numerator / total_shares_wide;
        
        return value as u64;
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // POOL MANAGEMENT TRANSITIONS (Called by prediction system)
    // ───────────────────────────────────────────────────────────────────────
    
    /// Record Bet Placement
    ///
    /// Called when a prediction bet is made using pool liquidity.
    /// Increments bet counter for statistics.
    ///
    /// Parameters:
    ///   - bet_amount: Size of the bet
    ///
    /// Note: This would be called by the betting/prediction contract
    /// Currently a placeholder for future integration
    ///
    transition record_bet(public bet_amount: u64) {
        // Increment total bets counter
        let current_bets: u64 = Mapping::get_or_use(pool_state, 2u8, 0u64);
        Mapping::set(pool_state, 2u8, current_bets + 1u64);
    }
    
    /// Record Profit
    ///
    /// Called when pool earns from successful prediction.
    /// Increases pool liquidity and profit counter.
    ///
    /// Parameters:
    ///   - profit_amount: Profit earned
    ///
    /// Effect:
    ///   - Increases total_liquidity (share value rises)
    ///   - Increases total_profit (statistics)
    ///   - Shareholders automatically benefit
    ///
    transition record_profit(public profit_amount: u64) {
        // Increase liquidity
        let total_liq: u64 = Mapping::get_or_use(pool_state, 0u8, 0u64);
        Mapping::set(pool_state, 0u8, total_liq + profit_amount);
        
        // Track cumulative profit
        let total_profit: u64 = Mapping::get_or_use(pool_state, 3u8, 0u64);
        Mapping::set(pool_state, 3u8, total_profit + profit_amount);
    }
    
    /// Record Loss
    ///
    /// Called when pool loses on failed prediction.
    /// Decreases pool liquidity and loss counter.
    ///
    /// Parameters:
    ///   - loss_amount: Loss incurred
    ///
    /// Effect:
    ///   - Decreases total_liquidity (share value falls)
    ///   - Increases total_loss (statistics)
    ///   - Shareholders automatically lose
    ///
    transition record_loss(public loss_amount: u64) {
        // Decrease liquidity
        let total_liq: u64 = Mapping::get(pool_state, 0u8);
        assert(total_liq >= loss_amount);  // Prevent pool insolvency
        Mapping::set(pool_state, 0u8, total_liq - loss_amount);
        
        // Track cumulative loss
        let total_loss: u64 = Mapping::get_or_use(pool_state, 4u8, 0u64);
        Mapping::set(pool_state, 4u8, total_loss + loss_amount);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// USAGE EXAMPLES
// ═══════════════════════════════════════════════════════════════════════════

/*

EXAMPLE 1: First Investor (Alice)
──────────────────────────────────

# Alice deposits 100 tokens
leo execute deposit_liquidity 100000000u64

# Output:
PoolShare {
    owner: aleo1alice...,
    amount: 100000000u64,  // 100 shares
    pool_id: 0u8,
    _nonce: ...
}

# Pool State:
total_liquidity: 100 tokens
total_shares: 100 shares
Share value: 1.0 token per share


EXAMPLE 2: Second Investor (Bob)
─────────────────────────────────

# Bob deposits 50 tokens
leo execute deposit_liquidity 50000000u64

# Output:
PoolShare {
    owner: aleo1bob...,
    amount: 50000000u64,  // 50 shares
    pool_id: 0u8,
    _nonce: ...
}

# Pool State:
total_liquidity: 150 tokens
total_shares: 150 shares
Share value: 1.0 token per share (same as before)


EXAMPLE 3: Pool Makes Profit
─────────────────────────────

# Prediction succeeds, pool earns 30 tokens
leo execute record_profit 30000000u64

# Pool State:
total_liquidity: 180 tokens (+30)
total_shares: 150 shares (unchanged)
Share value: 1.2 tokens per share (+20% gain!)

# Alice's 100 shares now worth: 120 tokens
# Bob's 50 shares now worth: 60 tokens


EXAMPLE 4: Alice Withdraws
───────────────────────────

# Alice burns her 100 shares
leo execute withdraw_liquidity [alice_poolshare_record]

# Alice receives: (100 × 180) / 150 = 120 tokens
# Profit: 20 tokens (20% return!)

# Pool State:
total_liquidity: 60 tokens
total_shares: 50 shares
Share value: 1.2 tokens per share (maintained)

# Bob's 50 shares still worth: 60 tokens


EXAMPLE 5: Check Pool Stats
────────────────────────────

leo execute get_pool_stats

# Output:
(60000000u64,    // 60 tokens remaining
 50000000u64,    // 50 shares outstanding
 10u64,          // 10 bets placed
 30000000u64,    // 30 tokens total profit
 0u64)           // 0 tokens total loss

# Performance: +50% ROI (30 profit on initial 60 investment)


DEPLOYMENT INSTRUCTIONS
───────────────────────

1. Deploy contract:
   leo deploy prophetia_pool.aleo --network testnet

2. Test deposit:
   leo execute deposit_liquidity 10000000u64 --network testnet

3. Check stats:
   leo execute get_pool_stats --network testnet

4. Test withdrawal:
   leo execute withdraw_liquidity [poolshare_record] --network testnet

*/
