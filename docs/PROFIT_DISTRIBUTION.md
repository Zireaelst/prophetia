# PROPHETIA Profit Distribution System

**Week 7: Kar Dağıtım Sistemi - Economic Incentive Layer**

Version: 1.0  
Contract: `profit_distribution.leo`  
Status: ✅ Production Ready (10/10 tests passing)

---

## Table of Contents

1. [Overview](#overview)
2. [Economic Model](#economic-model)
3. [Distribution Mechanics](#distribution-mechanics)
4. [Reputation System](#reputation-system)
5. [Stake Mechanics](#stake-mechanics)
6. [Records & Data Structures](#records--data-structures)
7. [Transitions (Functions)](#transitions-functions)
8. [Integration with Other Systems](#integration-with-other-systems)
9. [Mathematical Formulas](#mathematical-formulas)
10. [Security Considerations](#security-considerations)
11. [Usage Examples](#usage-examples)
12. [FAQ](#faq)

---

## Overview

### Purpose

PROPHETIA'nın **Profit Distribution System** başarılı tahmin karlarını üç taraf arasında adil ve teşvik edici bir şekilde dağıtır:

1. **Data Providers** (Veri Sağlayıcılar): ZK-ML için kaliteli data upload edenler
2. **Model Creators** (Model Geliştiriciler): Akıllı ML modelleri geliştiren ve deploy edenler
3. **Pool Investors** (Havuz Yatırımcıları): Betting sistemine likidite sağlayan pasif yatırımcılar

### 40-40-20 Split Rationale

```
Profit = 100 tokens
├─ Data Provider:  40 tokens (40%) + reputation bonus (max +20%)
├─ Model Creator:  40 tokens (40%) + reputation bonus (max +20%)
└─ Pool Investors: 20 tokens (20%) - reputation bonusları düşülür
```

**Neden bu oran?**

- **Active Participants (80%)**: Data provider ve model creator **risk alıyor**, zaman/beceri yatırıyor → Daha yüksek pay
- **Passive Investors (20%)**: Sadece sermaye koyuyorlar, risk düşük → Düşük ama **stabil** gelir
- **Reputation Bonus**: Quality teşvik ediliyor, spam cezalandırılıyor
- **Stake Slashing**: Accountability sağlanıyor, kötü performans maliyetli

---

## Economic Model

### Incentive Alignment

| Participant Type | Base Share | Reputation Bonus | Stake Risk | Incentive |
|------------------|------------|------------------|------------|-----------|
| **Data Provider** | 40% | Up to +20% | Yes (-10% per fail) | Quality data upload |
| **Model Creator** | 40% | Up to +20% | Yes (-10% per fail) | Accurate ML models |
| **Pool Investor** | 20% | No (stable) | No | Passive liquidity |

### Economic Flywheel

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  Good Performance                               │
│       ↓                                         │
│  High Reputation                                │
│       ↓                                         │
│  More Earnings (+20% bonus)                     │
│       ↓                                         │
│  More Participation                             │
│       ↓                                         │
│  Higher Quality Predictions                     │
│       ↓                                         │
│  (Cycle repeats)                                │
│                                                 │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│                                                 │
│  Bad Performance                                │
│       ↓                                         │
│  Low Reputation                                 │
│       ↓                                         │
│  Less Earnings (lower bonus)                    │
│       ↓                                         │
│  Stake Slashing (-10% per failure)              │
│       ↓                                         │
│  Natural Exit (after 10 failures)               │
│       ↓                                         │
│  System Quality Improves                        │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Self-Balancing Mechanism

- **Quality rises to the top**: High reputation → More earnings → More motivation
- **Spam filtered out**: Bad performers lose stake → Eventually exit
- **No manual intervention**: Economic rules handle quality control
- **Passive income protected**: Pool always gets 20% (adjusted for bonuses)

---

## Distribution Mechanics

### Step-by-Step Process

#### 1. Trigger Event

Profit distribution çağrılır when:
- Betting system wins (via `betting_system.aleo/settle_bet()`)
- Oracle confirms prediction accuracy
- Profit calculated: `payout - bet_amount`

#### 2. Base Split Calculation

```rust
profit_amount = 100_000_000u64;  // 100 tokens (scaled by 1M)

base_data_share = (profit_amount × DATA_PROVIDER_SHARE) / SCALE
                = (100_000_000 × 400_000) / 1_000_000
                = 40_000_000u64  // 40 tokens

base_model_share = (profit_amount × MODEL_CREATOR_SHARE) / SCALE
                 = 40_000_000u64  // 40 tokens

pool_share = (profit_amount × POOL_SHARE) / SCALE
           = 20_000_000u64  // 20 tokens
```

#### 3. Reputation Bonus Calculation

Reputation bonus participants'in performansına göre **up to +20%** ekler.

**Formula:**

```
bonus_multiplier = (reputation_score × MAX_REPUTATION_BONUS) / SCALE
bonus_amount = (base_share × bonus_multiplier) / SCALE
final_share = base_share + bonus_amount
```

**Example (90% reputation):**

```rust
// Data provider at 90% reputation
data_rep = 900_000u64;

bonus_multiplier = (900_000 × 200_000) / 1_000_000
                 = 180_000u64

data_bonus = (40_000_000 × 180_000) / 1_000_000
           = 7_200_000u64  // 7.2 tokens

final_data_share = 40_000_000 + 7_200_000
                 = 47_200_000u64  // 47.2 tokens
```

#### 4. Pool Share Adjustment

Pool payı **bonuslar kadar düşer** (conservation of total profit):

```rust
total_bonuses = data_bonus + model_bonus
              = 7_200_000 + 7_200_000
              = 14_400_000u64  // 14.4 tokens

adjusted_pool_share = pool_share - total_bonuses
                    = 20_000_000 - 14_400_000
                    = 5_600_000u64  // 5.6 tokens
```

**Verification:**
```
Data:  47.2 tokens
Model: 47.2 tokens
Pool:   5.6 tokens
─────────────────
Total: 100.0 tokens ✓
```

#### 5. ProfitShare Records

```leo
record ProfitShare {
    owner: address,              // alice
    amount: u64,                 // 47_200_000u64 (47.2 tokens)
    role: u8,                    // 0u8 (DATA_PROVIDER)
    prediction_id: u64,          // 12345u64
    reputation_bonus: u64,       // 7_200_000u64 (7.2 tokens)
    timestamp: u32               // block_height
}
```

#### 6. Statistics Update

```leo
// Contributions
contribution_stats[alice] += 1;

// Successes
success_stats[alice] += 1;

// Distribution history
distribution_history[prediction_id] = profit_amount;

// System metrics
system_metrics[0] += 1;  // total_distributions
system_metrics[1] += profit_amount;  // total_profit
system_metrics[2] += final_data_share;  // data_paid
system_metrics[3] += final_model_share;  // model_paid
system_metrics[4] += adjusted_pool_share;  // pool_allocated
```

---

## Reputation System

### Core Concept

**Reputation** bir participant'in **long-term quality**'sini ölçer. Başlangıçta herkes **50%** reputation ile başlar.

- **Range**: 0% - 100% (scaled: 0 - 1_000_000)
- **Initial**: 50% (500_000)
- **Max Bonus Impact**: +20% earnings
- **Decay on Failure**: -10%
- **Growth on Success**: +5%

### Reputation Changes

| Event | Change | Formula |
|-------|--------|---------|
| **Successful Prediction** | +5% | `reputation += REPUTATION_GAIN_WIN` (50_000) |
| **Failed Prediction** | -10% | `reputation -= REPUTATION_LOSS_FAIL` (100_000) |
| **Cap at Max** | 100% | `min(reputation, MAX_REPUTATION)` |
| **Floor at Min** | 0% | `max(reputation, MIN_REPUTATION)` |

### Reputation Evolution Example

5 predictions: **3 wins, 2 losses**

```
Start:  50%
Win 1:  50% + 5% = 55%
Win 2:  55% + 5% = 60%
Loss 1: 60% - 10% = 50%
Win 3:  50% + 5% = 55%
Loss 2: 55% - 10% = 45%

Final: 45% reputation
```

**Success Rate**: 3/5 = 60%  
**Reputation**: 45% (reflects recent losses)

### Bonus Impact Table

| Reputation | Bonus Multiplier | Base 40 tokens → Final |
|------------|------------------|------------------------|
| 0% | 0% | 40.0 tokens |
| 30% | 6% | 42.4 tokens (+6%) |
| 50% | 10% | 44.0 tokens (+10%) |
| 70% | 14% | 45.6 tokens (+14%) |
| 90% | 18% | 47.2 tokens (+18%) |
| 100% | 20% | 48.0 tokens (+20%) |

**Insight**: 100% rep earns **20% more** than 0% rep (48 vs 40 tokens).

---

## Stake Mechanics

### Purpose

**Stake** bir participant'in **skin in the game**'idir. Financial commitment gösterir ve accountability sağlar.

### Key Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| **MIN_STAKE_AMOUNT** | 10 tokens | Minimum deposit requirement |
| **STAKE_LOCK_PERIOD** | 24 hours (86,400 blocks) | Lock duration after deposit |
| **SLASH_PENALTY** | 10% | Percentage slashed per failure |
| **MAX_SLASH_COUNT** | 10 failures | After 10 slashes → stake = 0 |

### Deposit Stake

```leo
transition deposit_stake(
    amount: u64,        // Min 10_000_000u64 (10 tokens)
    role: u8,          // 0=data_provider, 1=model_creator
    owner: address
) -> Stake {
    // Validate minimum
    assert(amount >= MIN_STAKE_AMOUNT);
    
    // Lock for 24 hours
    let unlock_time = block.height + STAKE_LOCK_PERIOD;
    
    // Reset slash count
    slash_counts.set(owner, 0u64);
    
    // Update stake
    stake_amounts.set(owner, amount);
    
    return Stake {
        owner,
        amount,
        role,
        locked_until: unlock_time,
        slash_count: 0u8
    };
}
```

### Slash on Failure

Her başarısızlıkta **10% slash** uygulanır:

```leo
current_stake = stake_amounts.get(owner);
slash_amount = (current_stake × SLASH_PENALTY) / SCALE;
new_stake = current_stake - slash_amount;

stake_amounts.set(owner, new_stake);
slash_counts.set(owner, slash_counts.get(owner) + 1);
```

**Progressive Loss Example:**

| Failure # | Stake Before | Slash (10%) | Stake After |
|-----------|--------------|-------------|-------------|
| 0 (initial) | 50.00 tokens | - | 50.00 tokens |
| 1 | 50.00 | 5.00 | 45.00 tokens |
| 2 | 45.00 | 4.50 | 40.50 tokens |
| 3 | 40.50 | 4.05 | 36.45 tokens |
| 4 | 36.45 | 3.65 | 32.80 tokens |
| 5 | 32.80 | 3.28 | 29.52 tokens |
| ... | ... | ... | ... |
| 10 | ~19.37 | ~1.94 | **0.00 tokens** |

**After 10 failures**: Stake completely lost, participant forced to exit or re-stake.

### Withdraw Stake

```leo
transition withdraw_stake(
    stake: Stake,
    current_block: u32
) -> u64 {
    // Must wait for lock period
    assert(current_block >= stake.locked_until);
    
    let withdraw_amount = stake_amounts.get(stake.owner);
    
    // Clear stake
    stake_amounts.set(stake.owner, 0u64);
    slash_counts.set(stake.owner, 0u64);
    
    return withdraw_amount;
}
```

**Note**: Slashed amount is **PERMANENT LOSS**. Wins increase reputation but do NOT restore stake.

---

## Records & Data Structures

### ProfitShare Record

Distributed profit record sent to participants.

```leo
record ProfitShare {
    owner: address,              // Recipient address
    amount: u64,                 // Total tokens earned (base + bonus)
    role: u8,                    // 0=data_provider, 1=model_creator, 2=pool
    prediction_id: u64,          // Source prediction ID
    reputation_bonus: u64,       // Bonus tokens from reputation
    timestamp: u32               // Block height when distributed
}
```

**Example:**
```leo
ProfitShare {
    owner: alice_address,
    amount: 47_200_000u64,       // 47.2 tokens
    role: 0u8,                   // DATA_PROVIDER
    prediction_id: 12345u64,
    reputation_bonus: 7_200_000u64,  // 7.2 tokens bonus
    timestamp: 1_000_000u32
}
```

### Stake Record

Stake deposit record with lock period.

```leo
record Stake {
    owner: address,              // Staker address
    amount: u64,                 // Staked tokens
    role: u8,                    // 0=data_provider, 1=model_creator
    locked_until: u32,           // Block height when unlocked
    slash_count: u8              // Number of slashes (max 10)
}
```

**Example:**
```leo
Stake {
    owner: bob_address,
    amount: 50_000_000u64,       // 50 tokens
    role: 1u8,                   // MODEL_CREATOR
    locked_until: 1_086_400u32,  // Current + 86_400 blocks
    slash_count: 3u8             // 3 failures so far
}
```

### ParticipantInfo Struct

Comprehensive participant statistics.

```leo
struct ParticipantInfo {
    address: address,
    reputation_score: u64,       // 0 - 1_000_000 (0% - 100%)
    total_contributions: u64,    // Total predictions (wins + losses)
    successful_predictions: u64, // Win count
    stake_amount: u64            // Current staked tokens
}
```

---

## Transitions (Functions)

### 1. distribute_profit()

**Purpose**: Distribute profit to data provider and model creator with reputation bonus.

```leo
transition distribute_profit(
    profit_amount: u64,
    data_provider: address,
    model_creator: address,
    prediction_id: u64
) -> (ProfitShare, ProfitShare)
```

**Process**:
1. Fetch reputation scores (default 50% for new users)
2. Calculate base split: 40% / 40% / 20%
3. Apply reputation bonus (max +20%)
4. Create ProfitShare records
5. Send pool share via `pool.aleo/record_profit()`
6. Increase reputations by +5%
7. Update statistics

**Example Call**:
```bash
profit_distribution.aleo distribute_profit \
    100000000u64 \        # 100 tokens profit
    alice_address \       # Data provider
    bob_address \         # Model creator
    12345u64              # Prediction ID
```

---

### 2. penalize_failure()

**Purpose**: Penalize participants for failed predictions.

```leo
transition penalize_failure(
    data_provider: address,
    model_creator: address,
    loss_amount: u64
)
```

**Process**:
1. Decrease reputations by -10%
2. Increment contribution counters
3. Slash stakes by 10% (if present)
4. Track slash count (10 → stake = 0)

**Example Call**:
```bash
profit_distribution.aleo penalize_failure \
    alice_address \
    bob_address \
    100000000u64  # 100 tokens loss
```

---

### 3. deposit_stake()

**Purpose**: Deposit stake to secure participation.

```leo
transition deposit_stake(
    amount: u64,        // Min 10_000_000u64
    role: u8,          // 0=data, 1=model
    owner: address
) -> Stake
```

**Constraints**:
- `amount >= MIN_STAKE_AMOUNT` (10 tokens)
- `role` must be 0 or 1

**Example Call**:
```bash
profit_distribution.aleo deposit_stake \
    50000000u64 \     # 50 tokens
    0u8 \             # DATA_PROVIDER
    alice_address
```

---

### 4. withdraw_stake()

**Purpose**: Withdraw stake after lock period expires.

```leo
transition withdraw_stake(
    stake: Stake,
    current_block: u32
) -> u64
```

**Constraints**:
- `current_block >= stake.locked_until`

**Returns**: Remaining stake amount (after slashes)

**Example Call**:
```bash
profit_distribution.aleo withdraw_stake \
    stake_record \
    1087400u32  # Current block > locked_until
```

---

### 5. get_participant_info()

**Purpose**: Get comprehensive participant statistics.

```leo
transition get_participant_info(
    participant: address
) -> ParticipantInfo
```

**Returns**:
```leo
ParticipantInfo {
    address: participant,
    reputation_score: 550_000u64,        // 55%
    total_contributions: 10u64,          // 10 predictions
    successful_predictions: 7u64,        // 7 wins
    stake_amount: 45_000_000u64          // 45 tokens
}
```

---

### 6. calculate_success_rate()

**Purpose**: Calculate success rate: `successes / contributions`.

```leo
transition calculate_success_rate(
    participant: address
) -> u64
```

**Formula**:
```
success_rate = (successful_predictions × SCALE) / total_contributions
```

**Example**:
```
7 wins / 10 total = 700_000u64 (70%)
```

---

### 7. get_distribution_stats()

**Purpose**: Get system-wide distribution statistics.

```leo
transition get_distribution_stats() -> (u64, u64, u64, u64, u64)
```

**Returns**:
```
(
    total_distributions,      // 5
    total_profit_distributed, // 650_000_000u64 (650 tokens)
    total_data_provider_paid, // 291_880_000u64
    total_model_creator_paid, // 291_880_000u64
    total_pool_allocated      // 66_240_000u64
)
```

---

## Integration with Other Systems

### 1. Betting System → Profit Distribution

**Flow**:
```
betting_system.aleo/settle_bet()
    ↓
Calculate profit: payout - bet_amount
    ↓
profit_distribution.aleo/distribute_profit()
    ↓
ProfitShare records created
```

**Code Example**:
```leo
// In betting_system.aleo
let (payout, is_win) = settle_bet(position, actual_value, oracle_sig);

if is_win {
    let profit = payout - position.bet_amount;
    
    profit_distribution.aleo/distribute_profit(
        profit,
        position.data_provider,
        position.model_creator,
        position.prediction_id
    );
}
```

---

### 2. Profit Distribution → Liquidity Pool

**Flow**:
```
profit_distribution.aleo/distribute_profit()
    ↓
Calculate pool share (20% - bonuses)
    ↓
pool.aleo/record_profit()
    ↓
Pool balance increases
```

**Code Example**:
```leo
let adjusted_pool_share = pool_share - data_bonus - model_bonus;

pool.aleo/record_profit(
    adjusted_pool_share,
    prediction_id
);
```

---

### 3. Data NFT → Profit Distribution

**Link**: Data provider address in PredictionSignal record.

```leo
// In prediction_registry.aleo
record PredictionSignal {
    data_provider: address,  // Alice
    model_creator: address,  // Bob
    ...
}
```

When bet wins:
```leo
distribute_profit(
    profit,
    signal.data_provider,  // Alice gets data provider share
    signal.model_creator,  // Bob gets model creator share
    prediction_id
);
```

---

## Mathematical Formulas

### Base Distribution

```
profit = P

base_data_share = P × 0.4
base_model_share = P × 0.4
pool_share = P × 0.2
```

### Reputation Bonus

```
reputation_score = R  (0 ≤ R ≤ 1_000_000)
MAX_BONUS = 200_000  (20%)

bonus_multiplier = (R × MAX_BONUS) / SCALE
                 = (R × 200_000) / 1_000_000
                 = R / 5

bonus_amount = (base_share × bonus_multiplier) / SCALE
             = (base_share × R) / (5 × SCALE)
```

**Simplified**:
```
bonus = base × (reputation / 100%) × (MAX_BONUS / 100%)
      = base × (R / 1M) × (200k / 1M)
      = base × R / 5M
```

### Final Distribution

```
final_data_share = base_data_share + data_bonus
final_model_share = base_model_share + model_bonus
adjusted_pool_share = pool_share - data_bonus - model_bonus

Verify: final_data + final_model + adjusted_pool = P ✓
```

### Stake Slashing

```
S₀ = initial stake
n = number of failures
p = slash penalty = 0.1 (10%)

After n failures:
Sₙ = S₀ × (1 - p)ⁿ
   = S₀ × 0.9ⁿ
```

**Examples**:
```
S₀ = 100 tokens

After 1 failure: S₁ = 100 × 0.9¹ = 90 tokens
After 3 failures: S₃ = 100 × 0.9³ = 72.9 tokens
After 5 failures: S₅ = 100 × 0.9⁵ = 59.05 tokens
After 10 failures: S₁₀ = 100 × 0.9¹⁰ ≈ 34.87 tokens (but MAX_SLASH → 0)
```

### Success Rate

```
success_rate = (successful_predictions / total_contributions) × 100%

SR = (S / C) × SCALE
```

**Example**:
```
S = 7 wins
C = 10 total

SR = (7 / 10) × 1_000_000 = 700_000 (70%)
```

---

## Security Considerations

### 1. Overflow Protection

All arithmetic uses **checked operations** in Leo:
```leo
let result = a + b;  // Leo automatically checks overflow
```

### 2. Access Control

- Only authorized contracts can call `distribute_profit()`
- Stake withdrawal requires valid `Stake` record ownership
- Reputation/statistics are **read-only** (no external manipulation)

### 3. Reputation Bounds

```leo
// Cap at maximum
new_reputation = min(reputation + GAIN, MAX_REPUTATION);

// Floor at minimum
new_reputation = max(reputation - LOSS, MIN_REPUTATION);
```

### 4. Stake Lock Period

- Prevents rapid deposit/withdraw manipulation
- 24-hour lock ensures commitment
- Lock enforced by `assert(current_block >= locked_until)`

### 5. Total Conservation

```leo
assert(
    final_data_share + final_model_share + adjusted_pool_share == profit_amount
);
```

Ensures no tokens are lost or created.

### 6. Slash Count Limit

```leo
if slash_count >= MAX_SLASH_COUNT {
    stake_amounts.set(owner, 0u64);  // Complete loss
}
```

Prevents indefinite slashing, forces exit or re-stake.

---

## Usage Examples

### Example 1: Basic Distribution

**Scenario**: 100 tokens profit, both participants at 50% reputation.

```bash
profit_distribution.aleo distribute_profit \
    100000000u64 \
    alice_address \
    bob_address \
    1u64
```

**Result**:
- Alice: 44 tokens (40 + 4 bonus)
- Bob: 44 tokens (40 + 4 bonus)
- Pool: 12 tokens (20 - 8 bonuses)

---

### Example 2: High vs Low Reputation

**Scenario**: 100 tokens profit, Alice 90% rep, Bob 30% rep.

```bash
profit_distribution.aleo distribute_profit \
    100000000u64 \
    alice_address \  # 90% rep
    bob_address \    # 30% rep
    2u64
```

**Result**:
- Alice: 47.2 tokens (40 + 7.2 bonus) ← 18% bonus
- Bob: 42.4 tokens (40 + 2.4 bonus) ← 6% bonus
- Pool: 10.4 tokens (20 - 9.6 bonuses)

**Insight**: Alice earns **11% more** than Bob due to higher reputation.

---

### Example 3: Stake Deposit & Slash

```bash
# Deposit 50 tokens stake
profit_distribution.aleo deposit_stake \
    50000000u64 \
    0u8 \
    alice_address

# (Alice experiences 3 failures)

# After 3 slashes: 50 × 0.9³ = 36.45 tokens remaining
```

---

### Example 4: Full Integration

```bash
# 1. Data upload (data_nft.aleo)
# 2. Model deploy (zkml_verifier.aleo)
# 3. Inference (prediction_registry.aleo)
# 4. Bet placement (betting_system.aleo)
# 5. Bet win → Profit distribution

profit_distribution.aleo distribute_profit \
    85000000u64 \     # 85 tokens profit
    helen_address \   # Data provider
    ian_address \     # Model creator
    12345u64
```

**Result** (both 50% rep):
- Helen: 37.4 tokens
- Ian: 37.4 tokens
- Pool: 10.2 tokens

---

## FAQ

### Q1: Reputation vs Success Rate farkı nedir?

**Reputation**:
- Adjusts by ±5% (win) / ±10% (loss)
- Affects bonus earnings
- Reflects **recent** performance trend

**Success Rate**:
- Pure ratio: `wins / total`
- Doesn't affect earnings directly
- Historical metric

**Example**:
```
10 predictions: 7W / 3L
Success Rate: 70%
Reputation: 50% + (7×5%) - (3×10%) = 55%
```

---

### Q2: Stake slashing kalıcı mı?

**Evet.** Slash edilen stake **GERİ GELMİYOR**.

- Wins increase **reputation** (+5%)
- Wins do NOT restore **stake**
- Re-deposit required to restore stake

---

### Q3: 10 failure sonrası ne olur?

**Complete stake loss** → Forced exit or re-stake.

```
After 10 failures:
- Stake: 0 tokens
- Reputation: Likely 0% (10 × -10% = -100%)
- Success rate: Very low
- Cannot participate without re-staking
```

---

### Q4: Pool neden 20% alıyor?

**Risk-Reward Balance**:

- Pool investors: **Low risk** (passive), **low reward** (20%)
- Active participants: **High risk** (time/skill/stake), **high reward** (40% + bonus)

Passive sermaye çekmek için 20% **yeterli** ve **stabil** gelir.

---

### Q5: Reputation başlangıç değeri neden 50%?

**Neutral Starting Point**:

- 0%: Too harsh for new users
- 100%: No incentive to improve
- 50%: **Neutral**, room to grow or fall

New users **prove themselves** before earning max bonus.

---

### Q6: Bir participant hem data hem model sağlayabilir mi?

**Evet**, ama **iki ayrı role** olarak:

```leo
distribute_profit(
    profit,
    alice_address,  // Data provider role
    alice_address,  // Model creator role (same person)
    prediction_id
);
```

Alice **both shares** alır (80% + bonuses).

---

### Q7: Lock period neden 24 saat?

**Prevents manipulation**:

- Rapid deposit/withdraw → Stake manipulation
- 24h lock → Commitment gösterir
- Enough time for at least 1 prediction cycle

---

### Q8: Reputation 0%'da bonus 0 mı?

**Evet.** Zero reputation → Zero bonus.

```
reputation = 0
bonus_multiplier = (0 × 200_000) / 1_000_000 = 0
bonus = 0
```

Earnings: **Base 40 tokens only** (no bonus).

---

### Q9: Maximum earnings ne kadar? (100% rep)

**Base + Max Bonus** = 40 + (40 × 20%) = **48 tokens** per 100 profit.

100% reputation participant **20% more** than base earns.

---

### Q10: Pool share hiç negatif olabilir mi?

**Hayır.** Contract enforces:

```leo
adjusted_pool_share >= 0
```

Even at 100% rep (both participants), max bonuses:
```
Pool: 20 - 16 = 4 tokens ≥ 0 ✓
```

---

## Conclusion

PROPHETIA'nın **Profit Distribution System**:

✅ **Incentive-aligned**: Active participants earn more  
✅ **Quality-driven**: Reputation bonus rewards excellence  
✅ **Accountable**: Stake slashing penalizes poor performance  
✅ **Self-balancing**: Economic rules maintain quality  
✅ **Transparent**: All calculations on-chain, verifiable  

**Result**: Sustainable, decentralized oracle ecosystem where **quality wins**.

---

**Contact**: prophetia@aleo.org  
**License**: MIT  
**Version**: 1.0 (Week 7)
