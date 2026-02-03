# PROPHETIA Liquidity Pool System

## 📚 Table of Contents

1. [Overview](#overview)
2. [Economic Model](#economic-model)
3. [Technical Implementation](#technical-implementation)
4. [Usage Guide](#usage-guide)
5. [Security Considerations](#security-considerations)
6. [Economics Deep Dive](#economics-deep-dive)
7. [Integration](#integration)
8. [FAQ](#faq)

---

## Overview

The PROPHETIA Liquidity Pool is the **economic engine** that powers the prediction marketplace. It allows investors to provide capital for prediction bets and earn returns based on pool performance.

### 🎯 Core Concept

```
Investors Deposit Capital → Pool Provides Liquidity for Bets → 
Successful Predictions Generate Profit → Investors Share Profits Automatically
```

### Key Features

✅ **Fair Distribution** - All investors earn proportional returns  
✅ **Automatic Profit/Loss Sharing** - No manual calculations needed  
✅ **No Lock-Up Period** - Withdraw anytime  
✅ **Transparent Statistics** - Public pool metrics  
✅ **Zero-Knowledge Privacy** - Share ownership is private  
✅ **Security by Design** - Aleo record ownership enforced

---

## Economic Model

### Share-Based Ownership

The liquidity pool uses a **share-based** model similar to traditional mutual funds or DeFi liquidity pools (Uniswap, Curve).

#### First Deposit (1:1 Ratio)

```
Alice deposits 100 tokens
→ Receives 100 shares
→ Share value: 1.0 token/share
```

#### Subsequent Deposits (Proportional)

```
Pool State: 100 tokens, 100 shares
Bob deposits 50 tokens
→ Shares minted = (50 × 100) / 100 = 50 shares
→ New pool: 150 tokens, 150 shares
→ Share value maintained: 1.0 token/share
```

### Profit Distribution

When the pool makes a profit, **liquidity increases** but **shares remain constant**, causing share value to rise.

```
Pool: 150 tokens, 150 shares (share value = 1.0)
Pool earns 30 tokens profit
→ New pool: 180 tokens, 150 shares (share value = 1.2)

Alice's 100 shares: 100 × 1.2 = 120 tokens (+20% gain!)
Bob's 50 shares: 50 × 1.2 = 60 tokens (+20% gain!)
```

### Loss Distribution

When the pool loses, **liquidity decreases**, causing share value to fall.

```
Pool: 150 tokens, 150 shares (share value = 1.0)
Pool loses 30 tokens
→ New pool: 120 tokens, 150 shares (share value = 0.8)

Alice's 100 shares: 100 × 0.8 = 80 tokens (-20% loss)
Bob's 50 shares: 50 × 0.8 = 40 tokens (-20% loss)
```

### Why This Model is Fair

1. **Proportional Returns** - All investors get same % regardless of size
2. **Time-Independent** - Early and late investors treated equally (at current share value)
3. **Automatic Rebalancing** - No need to manually track individual investments
4. **Capital Efficient** - Single pool serves all investors

---

## Technical Implementation

### Record Definition: PoolShare

```leo
record PoolShare {
    owner: address,      // Who owns this share
    amount: u64,         // Number of shares (scaled 10^6)
    pool_id: u8,         // Pool identifier (multi-pool support)
    _nonce: group,       // Privacy guarantee
}
```

**Key Properties:**
- **Private** - Only owner knows share amount
- **Transferable** - Can be sent to another address
- **Burnable** - Consumed on withdrawal
- **Unique** - Each record has unique nonce

### Mapping: pool_state

Public state mapping storing pool statistics:

```leo
mapping pool_state: u8 => u64;

Key 0: total_liquidity   // Total tokens in pool
Key 1: total_shares      // Total shares minted
Key 2: total_bets        // Number of predictions
Key 3: total_profit      // Cumulative profit
Key 4: total_loss        // Cumulative losses
```

### Core Transitions

#### 1. deposit_liquidity

**Purpose:** Invest tokens into the pool

**Parameters:**
- `amount: u64` - Token amount to deposit (min 1.0 token = 1,000,000 scaled)

**Returns:**
- `PoolShare` record representing ownership

**Logic:**
```leo
if total_liquidity == 0:
    shares = amount  // 1:1 for first deposit
else:
    shares = (amount × total_shares) / total_liquidity
    
total_liquidity += amount
total_shares += shares
```

**Gas Cost:** ~15,000 credits

#### 2. withdraw_liquidity

**Purpose:** Exit the pool by burning shares

**Parameters:**
- `shares: PoolShare` - Share record to burn

**Returns:**
- `u64` - Token amount withdrawn

**Logic:**
```leo
withdrawal = (user_shares × total_liquidity) / total_shares

total_liquidity -= withdrawal
total_shares -= user_shares
// PoolShare record automatically consumed
```

**Gas Cost:** ~12,000 credits

#### 3. get_pool_stats

**Purpose:** Query pool performance (read-only)

**Returns:**
```leo
(
    total_liquidity: u64,
    total_shares: u64,
    total_bets: u64,
    total_profit: u64,
    total_loss: u64
)
```

**Gas Cost:** ~5,000 credits

#### 4. calculate_share_value

**Purpose:** Check value of shares without burning

**Parameters:**
- `shares: PoolShare` - Share record to value

**Returns:**
- `u64` - Current token value

**Logic:**
```leo
value = (user_shares × total_liquidity) / total_shares
```

**Gas Cost:** ~3,000 credits

#### 5. record_bet (Management Function)

**Purpose:** Track bet placement for statistics

**Parameters:**
- `bet_amount: u64` - Size of bet

**Called by:** Prediction betting contract

#### 6. record_profit (Management Function)

**Purpose:** Distribute profit to shareholders

**Parameters:**
- `profit_amount: u64` - Profit earned

**Effect:**
- Increases `total_liquidity` (share value rises)
- Increases `total_profit` counter

#### 7. record_loss (Management Function)

**Purpose:** Distribute loss to shareholders

**Parameters:**
- `loss_amount: u64` - Loss incurred

**Effect:**
- Decreases `total_liquidity` (share value falls)
- Increases `total_loss` counter

---

## Usage Guide

### For Investors

#### Step 1: Deposit Funds

```bash
# Deposit 100 tokens
leo execute deposit_liquidity 100000000u64 --network testnet
```

**Output:** PoolShare record
```
{
    owner: aleo1abc...,
    amount: 100000000u64,  // 100 shares
    pool_id: 0u8,
    _nonce: ...
}
```

#### Step 2: Monitor Performance

```bash
# Check pool stats
leo execute get_pool_stats --network testnet
```

**Output:** (total_liq, total_shares, total_bets, total_profit, total_loss)

**Calculate ROI:**
```
Net Profit = total_profit - total_loss
Initial Capital = total_liquidity - net_profit
ROI = (net_profit / initial_capital) × 100%
```

#### Step 3: Check Your Share Value

```bash
# Non-destructive value check
leo execute calculate_share_value [your_poolshare_record] --network testnet
```

**Example:**
```
Input: PoolShare with 100,000,000 shares
Pool: 180 tokens, 150 shares
Output: 120000000u64 (120 tokens)
Profit: 20 tokens (20% gain)
```

#### Step 4: Withdraw

```bash
# Burn shares and receive tokens
leo execute withdraw_liquidity [your_poolshare_record] --network testnet
```

**Output:** Withdrawal amount in tokens

### For Pool Managers

Pool managers (prediction betting contracts) call management functions:

```leo
// Record a bet being placed
prophetia_pool.aleo/record_bet(bet_amount);

// Record profit from successful prediction
prophetia_pool.aleo/record_profit(profit_amount);

// Record loss from failed prediction
prophetia_pool.aleo/record_loss(loss_amount);
```

---

## Security Considerations

### ✅ Built-In Protections

1. **Record Ownership**
   - Aleo enforces only record owner can spend it
   - No way to steal someone else's shares

2. **Minimum Deposit**
   - 1.0 token minimum (1,000,000 scaled)
   - Prevents dust attacks and gas griefing

3. **Math Safety**
   - u128 used for intermediate calculations
   - Prevents overflow in multiplication
   - Zero-division checks

4. **State Consistency**
   - Mapping updates atomic
   - Records consumed on withdrawal (no double-spend)

5. **Privacy**
   - Share amounts private (record fields)
   - Only pool totals are public

### ⚠️ Risks to Consider

1. **Pool Performance Risk**
   - If predictions fail, investors lose money
   - No guaranteed returns
   - Past performance ≠ future results

2. **Liquidity Risk**
   - If pool depleted, withdrawals may be delayed
   - Mitigation: Conservative bet sizing, insurance fund (future)

3. **Smart Contract Risk**
   - Bugs could lock funds or miscalculate
   - Mitigation: Audits, formal verification (Week 10)

4. **Economic Attacks**
   - Large depositor could manipulate share price timing
   - Mitigation: Minimum delays, MEV protection (future)

### Best Practices for Investors

✅ **Diversify** - Don't put all capital in one pool  
✅ **Monitor** - Check pool stats regularly  
✅ **Understand Risk** - Pool can lose money  
✅ **Start Small** - Test with minimum deposit first  
✅ **Check Value** - Use `calculate_share_value` before withdrawing

---

## Economics Deep Dive

### Capital Efficiency

Traditional oracle: Each bet needs dedicated capital  
PROPHETIA pool: Shared capital serves many bets simultaneously

**Example:**
```
Traditional: 10 bets × 100 tokens each = 1,000 tokens needed
Pool: 10 bets with shared 300 token pool = 300 tokens needed
Efficiency: 70% capital savings!
```

### Share Value Dynamics

Share value equation:
```
share_value = total_liquidity / total_shares
```

**Profit Example:**
```
Initial: 100 tokens, 100 shares → 1.0 token/share
+20 profit: 120 tokens, 100 shares → 1.2 tokens/share
+20% return for all investors
```

**Loss Example:**
```
Initial: 100 tokens, 100 shares → 1.0 token/share
-20 loss: 80 tokens, 100 shares → 0.8 tokens/share
-20% loss for all investors
```

### Multi-Investor Fairness

**Scenario:** Three investors, different sizes

```
Alice deposits 100 tokens → 100 shares (57.14%)
Bob deposits 50 tokens → 50 shares (28.57%)
Charlie deposits 25 tokens → 25 shares (14.29%)
Total: 175 tokens, 175 shares

Pool earns 40 tokens profit → 215 tokens, 175 shares

Alice withdraws: (100 × 215) / 175 = 122.86 tokens (+22.86%)
Bob withdraws: (50 × 215) / 175 = 61.43 tokens (+22.86%)
Charlie withdraws: (25 × 215) / 175 = 30.71 tokens (+22.86%)

All earn SAME % regardless of size! ✅
```

### Comparison to Traditional Finance

| Feature | PROPHETIA Pool | Mutual Fund | DeFi LP |
|---------|---------------|-------------|---------|
| Shares | ✅ Yes | ✅ Yes | ✅ Yes |
| Proportional Returns | ✅ Yes | ✅ Yes | ✅ Yes |
| Automatic Distribution | ✅ Yes | ✅ Yes | ✅ Yes |
| Lock-Up Period | ❌ No | ⚠️ Sometimes | ❌ No |
| Privacy | ✅ Yes (ZK) | ❌ No | ❌ No |
| Gas Cost | Low | N/A | Medium |

---

## Integration

### Connecting Prediction System

The liquidity pool integrates with the prediction betting system (Week 7):

```leo
// In betting contract:
transition place_bet(prediction_id: u64, amount: u64) {
    // 1. Check pool has liquidity
    let pool_stats = prophetia_pool.aleo/get_pool_stats();
    assert(pool_stats.0 >= amount);
    
    // 2. Record the bet
    prophetia_pool.aleo/record_bet(amount);
    
    // 3. Execute prediction...
    
    // 4. If win: record profit
    if prediction_correct {
        let profit = calculate_profit(amount);
        prophetia_pool.aleo/record_profit(profit);
    } else {
        // 5. If loss: record loss
        prophetia_pool.aleo/record_loss(amount);
    }
}
```

### Frontend Integration (Week 6)

Dashboard should display:
- Current pool size
- Total shares outstanding
- Share value (APY calculation)
- Total bets made
- Win/loss ratio
- Net ROI

**API Endpoints:**
```typescript
// Fetch pool statistics
GET /api/pool/stats
Response: {
    totalLiquidity: number,
    totalShares: number,
    shareValue: number,
    totalBets: number,
    totalProfit: number,
    totalLoss: number,
    roi: number
}

// Fetch user position
GET /api/pool/position/:address
Response: {
    shareAmount: number,
    currentValue: number,
    initialDeposit: number,
    profit: number,
    roi: number
}
```

---

## FAQ

### General Questions

**Q: How is this different from a traditional investment fund?**  
A: Similar concept (shares represent ownership), but on-chain with ZK privacy, no middleman, and transparent rules.

**Q: Can I lose money?**  
A: Yes! If the pool's predictions fail, share value decreases. This is not a guaranteed-return investment.

**Q: How often can I withdraw?**  
A: Anytime! There's no lock-up period. Withdraw whenever you want.

**Q: Are my holdings private?**  
A: Yes! Your PoolShare record is private. Only you know how many shares you have. Pool totals are public.

**Q: What happens if the pool runs out of money?**  
A: Withdrawals would fail. Mitigation: Conservative bet sizing, insurance fund (future feature).

### Technical Questions

**Q: Why use shares instead of direct token tracking?**  
A: Shares allow automatic profit/loss distribution without tracking each investor individually. More capital efficient and gas-efficient.

**Q: What if I lose my PoolShare record?**  
A: Records are like cash - if you lose them, they're gone. Backup your wallet! (Future: recovery mechanisms)

**Q: Can I transfer my shares to someone else?**  
A: Yes! PoolShare records are transferable. Send them like any other Aleo record.

**Q: What's the minimum deposit?**  
A: 1.0 token (1,000,000 scaled). Prevents dust attacks.

**Q: How are profits calculated?**  
A: Withdrawal = (your_shares × total_liquidity) / total_shares. This automatically includes all profits/losses.

### Economic Questions

**Q: Do early investors get better deals?**  
A: No! Share value at time of deposit determines your price. If pool grew before you joined, you pay higher share price but get proportional value.

**Q: What's a good ROI to expect?**  
A: Depends on prediction accuracy. Historical data will be available after launch. No guarantees!

**Q: How much should I invest?**  
A: Only invest what you can afford to lose. Start with minimum deposit to test.

**Q: Can large investors manipulate the pool?**  
A: Deposit/withdraw don't change others' share values (only total pool size). Future: MEV protections, delays.

### Future Features

**Q: Will there be multiple pools?**  
A: Yes! `pool_id` field supports multiple pools (conservative vs aggressive, different strategies).

**Q: Will there be fees?**  
A: Likely in Week 8: Small performance fee to pool managers, protocol fee for development.

**Q: Can pools have different strategies?**  
A: Yes! Week 8 will add pool strategy types (algorithm preference, risk level, asset focus).

**Q: Insurance fund for losses?**  
A: Planned for Week 8: Reserve fund to cover extreme losses, funded by performance fees.

---

## Mathematical Formulas

### Share Minting (Deposit)

**First Deposit:**
$$
\text{shares} = \text{amount}
$$

**Subsequent Deposits:**
$$
\text{shares} = \frac{\text{amount} \times \text{total\_shares}}{\text{total\_liquidity}}
$$

### Withdrawal Calculation

$$
\text{withdrawal} = \frac{\text{user\_shares} \times \text{total\_liquidity}}{\text{total\_shares}}
$$

### Share Value

$$
\text{share\_value} = \frac{\text{total\_liquidity}}{\text{total\_shares}}
$$

### ROI Calculation

$$
\text{Net Profit} = \text{total\_profit} - \text{total\_loss}
$$

$$
\text{Initial Capital} = \text{total\_liquidity} - \text{Net Profit}
$$

$$
\text{ROI} = \frac{\text{Net Profit}}{\text{Initial Capital}} \times 100\%
$$

### Per-Share ROI

$$
\text{Current Value} = \frac{\text{user\_shares} \times \text{total\_liquidity}}{\text{total\_shares}}
$$

$$
\text{Profit} = \text{Current Value} - \text{Initial Deposit}
$$

$$
\text{ROI} = \frac{\text{Profit}}{\text{Initial Deposit}} \times 100\%
$$

---

## Testing

Comprehensive test suite: `tests/test_liquidity_pool.py`

**9 Tests (All Passing):**
1. ✅ First Deposit (1:1 ratio)
2. ✅ Subsequent Deposit (proportional)
3. ✅ Full Withdrawal
4. ✅ Partial Withdrawal
5. ✅ Profit Distribution
6. ✅ Loss Distribution
7. ✅ Multiple Depositors (fairness)
8. ✅ Minimum Deposit Validation
9. ✅ Share Value Calculation

**Run Tests:**
```bash
python3 tests/test_liquidity_pool.py
```

---

## References

- **Uniswap V2 LP Tokens:** Similar share-based model for AMM pools
- **Mutual Fund Shares:** Traditional finance equivalent
- **Aleo Records:** Privacy-preserving ownership model
- **Fixed-Point Arithmetic:** Week 2 math utilities

---

## Changelog

**Week 5 (Current):**
- ✅ Initial liquidity pool implementation
- ✅ PoolShare record definition
- ✅ Deposit/withdraw mechanics
- ✅ Profit/loss distribution
- ✅ Pool statistics tracking
- ✅ Comprehensive test suite (9/9 passing)

**Week 6 (Planned):**
- Frontend dashboard for pool visualization
- Real-time share value updates
- Historical performance charts

**Week 7 (Planned):**
- Integration with prediction betting system
- Automated profit/loss recording

**Week 8 (Planned):**
- Multiple pool support (different strategies)
- Performance fees
- Insurance fund
- Pool manager reputation system

---

## Contact & Support

**Documentation:** [docs/](../docs/)  
**Examples:** [examples/pool_usage.leo](../examples/pool_usage.leo)  
**Tests:** [tests/test_liquidity_pool.py](../tests/test_liquidity_pool.py)  
**Contract:** [contracts/src/liquidity_pool.leo](../contracts/src/liquidity_pool.leo)

**Issues:** Report bugs in GitHub Issues  
**Discussions:** Join our Discord for help

---

**DISCLAIMER:** The liquidity pool involves financial risk. Investors can lose money if predictions fail. This is not financial advice. Invest responsibly.

---

*Last Updated: Week 5 - Liquidity Pool Foundation*  
*Version: 1.0*  
*Status: Production-Ready (Testnet)*
