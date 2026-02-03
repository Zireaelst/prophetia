#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
PROPHETIA - Profit Distribution System Test Suite
═══════════════════════════════════════════════════════════════════════════════

Week 7: Kar Dağıtım Sistemi Test Suite

KAPSAM:
- distribute_profit() transition (40-40-20 split)
- Reputation bonus hesaplamaları
- penalize_failure() transition (slash mechanics)
- Stake deposit/withdraw
- Success rate calculations
- Multi-round scenarios
- Edge cases (zero reputation, max slashes, etc.)

═══════════════════════════════════════════════════════════════════════════════
"""

# ─────────────────────────────────────────────────────────────────────────────
# Renk kodları (terminal output için)
# ─────────────────────────────────────────────────────────────────────────────

class Colors:
    """ANSI color codes for terminal output"""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

# ─────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

def print_test_header(test_name: str):
    """Print formatted test header"""
    print(f"\n{Colors.CYAN}{'═' * 70}")
    print(f"TEST: {test_name}")
    print(f"{'═' * 70}{Colors.END}\n")

def print_result(passed: bool, message: str):
    """Print test result with color"""
    if passed:
        print(f"{Colors.GREEN}✓ PASS{Colors.END} - {message}")
    else:
        print(f"{Colors.RED}✗ FAIL{Colors.END} - {message}")

def print_distribution_summary(data_share, model_share, pool_share, total):
    """Print profit distribution breakdown"""
    print(f"\n{Colors.BOLD}Distribution Breakdown:{Colors.END}")
    print(f"  Data Provider:  {data_share / ProfitDistribution.SCALE:.2f} tokens " +
          f"({100 * data_share / total:.1f}%)")
    print(f"  Model Creator:  {model_share / ProfitDistribution.SCALE:.2f} tokens " +
          f"({100 * model_share / total:.1f}%)")
    print(f"  Pool Investors: {pool_share / ProfitDistribution.SCALE:.2f} tokens " +
          f"({100 * pool_share / total:.1f}%)")
    print(f"  {Colors.BOLD}Total: {total / ProfitDistribution.SCALE:.2f} tokens{Colors.END}")

# ─────────────────────────────────────────────────────────────────────────────
# Classes
# ─────────────────────────────────────────────────────────────────────────────

class ProfitShare:
    """ProfitShare record simulator"""
    def __init__(self, owner, amount, role, prediction_id, reputation_bonus, timestamp):
        self.owner = owner
        self.amount = amount
        self.role = role  # 0=data_provider, 1=model_creator, 2=pool
        self.prediction_id = prediction_id
        self.reputation_bonus = reputation_bonus
        self.timestamp = timestamp

class Stake:
    """Stake record simulator"""
    def __init__(self, owner, amount, role, locked_until, slash_count):
        self.owner = owner
        self.amount = amount
        self.role = role  # 0=data_provider, 1=model_creator
        self.locked_until = locked_until
        self.slash_count = slash_count

class ParticipantInfo:
    """ParticipantInfo struct simulator"""
    def __init__(self, address, reputation_score, total_contributions, 
                 successful_predictions, stake_amount):
        self.address = address
        self.reputation_score = reputation_score
        self.total_contributions = total_contributions
        self.successful_predictions = successful_predictions
        self.stake_amount = stake_amount

class ProfitDistribution:
    """
    profit_distribution.leo simulator
    Python implementation for testing
    """
    
    # Constants (matching Leo contract)
    SCALE = 1_000_000
    
    # Distribution shares
    DATA_PROVIDER_SHARE = 400_000  # 40%
    MODEL_CREATOR_SHARE = 400_000  # 40%
    POOL_SHARE = 200_000           # 20%
    
    # Reputation
    MIN_REPUTATION = 0
    MAX_REPUTATION = 1_000_000
    INITIAL_REPUTATION = 500_000   # 50%
    MAX_REPUTATION_BONUS = 200_000 # +20%
    
    # Stake
    MIN_STAKE_AMOUNT = 10_000_000  # 10 tokens
    STAKE_LOCK_PERIOD = 86400      # 24 hours
    SLASH_PENALTY = 100_000        # 10%
    MAX_SLASH_COUNT = 10
    
    # Reputation changes
    REPUTATION_GAIN_WIN = 50_000   # +5%
    REPUTATION_LOSS_FAIL = 100_000 # -10%
    
    def __init__(self):
        # Mappings
        self.reputation_scores = {}
        self.contribution_stats = {}
        self.success_stats = {}
        self.stake_amounts = {}
        self.slash_counts = {}
        self.distribution_history = {}
        
        # System metrics
        self.system_metrics = {
            0: 0,  # total_distributions
            1: 0,  # total_profit_distributed
            2: 0,  # total_data_provider_paid
            3: 0,  # total_model_creator_paid
            4: 0   # total_pool_allocated
        }
        
        self.block_height = 1000000  # Simulated block height
    
    def distribute_profit(self, profit_amount, data_provider, model_creator, prediction_id):
        """
        Distribute profit with 40-40-20 split and reputation bonuses
        
        Returns: (ProfitShare, ProfitShare, pool_share_amount)
        """
        # ═══════════════════════════════════════════════════════════════════
        # ADIM 1: REPUTASYON SKORLARINI ÇEK
        # ═══════════════════════════════════════════════════════════════════
        
        data_rep = self.reputation_scores.get(data_provider, self.INITIAL_REPUTATION)
        model_rep = self.reputation_scores.get(model_creator, self.INITIAL_REPUTATION)
        
        # ═══════════════════════════════════════════════════════════════════
        # ADIM 2: BASE SPLIT (40-40-20)
        # ═══════════════════════════════════════════════════════════════════
        
        base_data_share = (profit_amount * self.DATA_PROVIDER_SHARE) // self.SCALE
        base_model_share = (profit_amount * self.MODEL_CREATOR_SHARE) // self.SCALE
        pool_share = (profit_amount * self.POOL_SHARE) // self.SCALE
        
        # ═══════════════════════════════════════════════════════════════════
        # ADIM 3: REPUTASYON BONUSU
        # ═══════════════════════════════════════════════════════════════════
        
        # Data provider bonus
        data_bonus_multiplier = (data_rep * self.MAX_REPUTATION_BONUS) // self.SCALE
        data_bonus = (base_data_share * data_bonus_multiplier) // self.SCALE
        final_data_share = base_data_share + data_bonus
        
        # Model creator bonus
        model_bonus_multiplier = (model_rep * self.MAX_REPUTATION_BONUS) // self.SCALE
        model_bonus = (base_model_share * model_bonus_multiplier) // self.SCALE
        final_model_share = base_model_share + model_bonus
        
        # Pool payından bonus düş
        adjusted_pool_share = pool_share - data_bonus - model_bonus
        
        # ═══════════════════════════════════════════════════════════════════
        # ADIM 4: ProfitShare RECORD'LARI
        # ═══════════════════════════════════════════════════════════════════
        
        data_profit_share = ProfitShare(
            owner=data_provider,
            amount=final_data_share,
            role=0,
            prediction_id=prediction_id,
            reputation_bonus=data_bonus,
            timestamp=self.block_height
        )
        
        model_profit_share = ProfitShare(
            owner=model_creator,
            amount=final_model_share,
            role=1,
            prediction_id=prediction_id,
            reputation_bonus=model_bonus,
            timestamp=self.block_height
        )
        
        # ═══════════════════════════════════════════════════════════════════
        # ADIM 6: REPUTASYON GÜNCELLE (+5%)
        # ═══════════════════════════════════════════════════════════════════
        
        new_data_rep = min(data_rep + self.REPUTATION_GAIN_WIN, self.MAX_REPUTATION)
        self.reputation_scores[data_provider] = new_data_rep
        
        new_model_rep = min(model_rep + self.REPUTATION_GAIN_WIN, self.MAX_REPUTATION)
        self.reputation_scores[model_creator] = new_model_rep
        
        # ═══════════════════════════════════════════════════════════════════
        # ADIM 7: İSTATİSTİKLER
        # ═══════════════════════════════════════════════════════════════════
        
        # Contributions
        self.contribution_stats[data_provider] = self.contribution_stats.get(data_provider, 0) + 1
        self.contribution_stats[model_creator] = self.contribution_stats.get(model_creator, 0) + 1
        
        # Successes
        self.success_stats[data_provider] = self.success_stats.get(data_provider, 0) + 1
        self.success_stats[model_creator] = self.success_stats.get(model_creator, 0) + 1
        
        # Distribution history
        self.distribution_history[prediction_id] = profit_amount
        
        # System metrics
        self.system_metrics[0] += 1  # total_distributions
        self.system_metrics[1] += profit_amount  # total_profit
        self.system_metrics[2] += final_data_share  # data_paid
        self.system_metrics[3] += final_model_share  # model_paid
        self.system_metrics[4] += adjusted_pool_share  # pool_allocated
        
        return (data_profit_share, model_profit_share, adjusted_pool_share)
    
    def penalize_failure(self, data_provider, model_creator, loss_amount):
        """
        Penalize participants for failed prediction
        - Reputation: -10%
        - Stake: -10% slash (if exists)
        """
        # ═══════════════════════════════════════════════════════════════════
        # REPUTASYON DÜŞÜR (-10%)
        # ═══════════════════════════════════════════════════════════════════
        
        data_rep = self.reputation_scores.get(data_provider, self.INITIAL_REPUTATION)
        new_data_rep = max(data_rep - self.REPUTATION_LOSS_FAIL, self.MIN_REPUTATION)
        self.reputation_scores[data_provider] = new_data_rep
        
        model_rep = self.reputation_scores.get(model_creator, self.INITIAL_REPUTATION)
        new_model_rep = max(model_rep - self.REPUTATION_LOSS_FAIL, self.MIN_REPUTATION)
        self.reputation_scores[model_creator] = new_model_rep
        
        # ═══════════════════════════════════════════════════════════════════
        # CONTRIBUTION ARTIR (başarısızlık da contribution)
        # ═══════════════════════════════════════════════════════════════════
        
        self.contribution_stats[data_provider] = self.contribution_stats.get(data_provider, 0) + 1
        self.contribution_stats[model_creator] = self.contribution_stats.get(model_creator, 0) + 1
        
        # ═══════════════════════════════════════════════════════════════════
        # STAKE SLASH (Eğer varsa %10)
        # ═══════════════════════════════════════════════════════════════════
        
        # Data provider
        data_stake = self.stake_amounts.get(data_provider, 0)
        if data_stake > 0:
            slash = (data_stake * self.SLASH_PENALTY) // self.SCALE
            new_stake = data_stake - slash
            self.stake_amounts[data_provider] = new_stake
            
            data_slashes = self.slash_counts.get(data_provider, 0) + 1
            self.slash_counts[data_provider] = data_slashes
            
            # Max slash → stake sıfır
            if data_slashes >= self.MAX_SLASH_COUNT:
                self.stake_amounts[data_provider] = 0
        
        # Model creator
        model_stake = self.stake_amounts.get(model_creator, 0)
        if model_stake > 0:
            slash = (model_stake * self.SLASH_PENALTY) // self.SCALE
            new_stake = model_stake - slash
            self.stake_amounts[model_creator] = new_stake
            
            model_slashes = self.slash_counts.get(model_creator, 0) + 1
            self.slash_counts[model_creator] = model_slashes
            
            if model_slashes >= self.MAX_SLASH_COUNT:
                self.stake_amounts[model_creator] = 0
    
    def deposit_stake(self, amount, role, owner):
        """Deposit stake (min 10 tokens)"""
        assert amount >= self.MIN_STAKE_AMOUNT, f"Stake too small: {amount / self.SCALE:.2f} tokens"
        assert role in [0, 1], "Invalid role"
        
        current_stake = self.stake_amounts.get(owner, 0)
        new_stake = current_stake + amount
        self.stake_amounts[owner] = new_stake
        
        unlock_time = self.block_height + self.STAKE_LOCK_PERIOD
        self.slash_counts[owner] = 0  # Reset slashes
        
        stake_record = Stake(
            owner=owner,
            amount=amount,
            role=role,
            locked_until=unlock_time,
            slash_count=0
        )
        
        return stake_record
    
    def withdraw_stake(self, stake, current_block):
        """Withdraw stake (after lock period)"""
        assert current_block >= stake.locked_until, "Stake still locked"
        
        current_stake = self.stake_amounts.get(stake.owner, 0)
        withdraw_amount = current_stake
        
        self.stake_amounts[stake.owner] = 0
        self.slash_counts[stake.owner] = 0
        
        return withdraw_amount
    
    def get_participant_info(self, participant):
        """Get all info for a participant"""
        info = ParticipantInfo(
            address=participant,
            reputation_score=self.reputation_scores.get(participant, self.INITIAL_REPUTATION),
            total_contributions=self.contribution_stats.get(participant, 0),
            successful_predictions=self.success_stats.get(participant, 0),
            stake_amount=self.stake_amounts.get(participant, 0)
        )
        return info
    
    def calculate_success_rate(self, participant):
        """Calculate success rate: successes / contributions"""
        contributions = self.contribution_stats.get(participant, 0)
        if contributions == 0:
            return 0
        
        successes = self.success_stats.get(participant, 0)
        success_rate = (successes * self.SCALE) // contributions
        return success_rate
    
    def get_distribution_stats(self):
        """Get system-wide distribution statistics"""
        return (
            self.system_metrics[0],  # total_distributions
            self.system_metrics[1],  # total_profit
            self.system_metrics[2],  # data_paid
            self.system_metrics[3],  # model_paid
            self.system_metrics[4]   # pool_allocated
        )

# ─────────────────────────────────────────────────────────────────────────────
# Test Functions
# ─────────────────────────────────────────────────────────────────────────────

def test_basic_distribution():
    """TEST 1: Basic 40-40-20 Split"""
    print_test_header("Basic 40-40-20 Distribution")
    
    pd = ProfitDistribution()
    
    # 100 tokens profit, both participants at 50% reputation (neutral)
    profit = 100 * ProfitDistribution.SCALE
    data_provider = "alice"
    model_creator = "bob"
    
    (data_share, model_share, pool_share) = pd.distribute_profit(
        profit, data_provider, model_creator, prediction_id=1
    )
    
    print(f"Profit: {profit / ProfitDistribution.SCALE:.2f} tokens")
    print(f"Data provider reputation: 50% (initial)")
    print(f"Model creator reputation: 50% (initial)")
    
    print_distribution_summary(
        data_share.amount, model_share.amount, pool_share, profit
    )
    
    passed = True
    
    # At 50% reputation, there IS a bonus (50% × 20% = 10% bonus)
    # So: 40 + (40 × 0.5 × 0.2) = 40 + 4 = 44 tokens
    expected_with_bonus = 44 * ProfitDistribution.SCALE
    if abs(data_share.amount - expected_with_bonus) > 10000:  # Allow small rounding
        print_result(False, f"Data share mismatch: {data_share.amount / ProfitDistribution.SCALE:.2f} (expected 44)")
        passed = False
    else:
        print_result(True, "Data provider gets 44 tokens (40 base + 4 bonus at 50% rep)")
    
    if abs(model_share.amount - expected_with_bonus) > 10000:
        print_result(False, f"Model share mismatch: {model_share.amount / ProfitDistribution.SCALE:.2f}")
        passed = False
    else:
        print_result(True, "Model creator gets 44 tokens (40 base + 4 bonus at 50% rep)")
    
    # Pool gets 20 - 8 = 12 tokens (since both got 4 tokens bonus)
    expected_pool = 12 * ProfitDistribution.SCALE
    if abs(pool_share - expected_pool) > 10000:
        print_result(False, f"Pool share mismatch: {pool_share / ProfitDistribution.SCALE:.2f}")
        passed = False
    else:
        print_result(True, "Pool gets 12 tokens (20 - 8 bonus)")
    
    # Total should equal profit
    total = data_share.amount + model_share.amount + pool_share
    if abs(total - profit) > 1000:
        print_result(False, f"Total mismatch: {total / ProfitDistribution.SCALE:.2f}")
        passed = False
    else:
        print_result(True, "Total equals profit (conservation)")
    
    return passed

def test_reputation_bonus():
    """TEST 2: Reputation Bonus Impact"""
    print_test_header("Reputation Bonus (High vs Low)")
    
    pd = ProfitDistribution()
    
    # Set high reputation for data provider (90%)
    pd.reputation_scores["alice"] = 900_000
    # Low reputation for model creator (30%)
    pd.reputation_scores["bob"] = 300_000
    
    profit = 100 * ProfitDistribution.SCALE
    
    (data_share, model_share, pool_share) = pd.distribute_profit(
        profit, "alice", "bob", prediction_id=2
    )
    
    print(f"\nProfit: {profit / ProfitDistribution.SCALE:.2f} tokens")
    print(f"Alice (data) reputation: 90% → Bonus: {data_share.reputation_bonus / ProfitDistribution.SCALE:.2f} tokens")
    print(f"Bob (model) reputation: 30% → Bonus: {model_share.reputation_bonus / ProfitDistribution.SCALE:.2f} tokens")
    
    print_distribution_summary(
        data_share.amount, model_share.amount, pool_share, profit
    )
    
    passed = True
    
    # Alice (90% rep) should get more than base (40 + bonus)
    if data_share.amount <= 40 * ProfitDistribution.SCALE:
        print_result(False, "Alice should get reputation bonus")
        passed = False
    else:
        bonus_pct = 100 * data_share.reputation_bonus / (40 * ProfitDistribution.SCALE)
        print_result(True, f"Alice gets +{bonus_pct:.1f}% bonus (high reputation)")
    
    # Bob (30% rep) should get less bonus
    if model_share.reputation_bonus >= data_share.reputation_bonus:
        print_result(False, "Bob's bonus should be lower than Alice's")
        passed = False
    else:
        print_result(True, "Bob gets smaller bonus (low reputation)")
    
    # Total still conserved
    total = data_share.amount + model_share.amount + pool_share
    if abs(total - profit) > 1000:
        print_result(False, "Total conservation violated")
        passed = False
    else:
        print_result(True, "Total still equals profit ✓")
    
    return passed

def test_reputation_update():
    """TEST 3: Reputation Updates (Win/Loss)"""
    print_test_header("Reputation Updates")
    
    pd = ProfitDistribution()
    
    # Start at 50% reputation
    pd.reputation_scores["alice"] = 500_000
    pd.reputation_scores["bob"] = 500_000
    
    print("Initial reputation: 50% (both)")
    
    # Win → +5% reputation
    pd.distribute_profit(100 * ProfitDistribution.SCALE, "alice", "bob", 1)
    
    alice_rep_after_win = pd.reputation_scores["alice"]
    bob_rep_after_win = pd.reputation_scores["bob"]
    
    print(f"\nAfter WIN:")
    print(f"  Alice: {alice_rep_after_win / ProfitDistribution.SCALE * 100:.1f}%")
    print(f"  Bob: {bob_rep_after_win / ProfitDistribution.SCALE * 100:.1f}%")
    
    passed = True
    
    expected_rep = 550_000  # 50% + 5%
    if alice_rep_after_win != expected_rep:
        print_result(False, f"Alice reputation should be 55% (got {alice_rep_after_win / 10000:.1f}%)")
        passed = False
    else:
        print_result(True, "Alice reputation increased to 55% (+5%)")
    
    if bob_rep_after_win != expected_rep:
        print_result(False, "Bob reputation mismatch")
        passed = False
    else:
        print_result(True, "Bob reputation increased to 55% (+5%)")
    
    # Loss → -10% reputation
    pd.penalize_failure("alice", "bob", 100 * ProfitDistribution.SCALE)
    
    alice_rep_after_loss = pd.reputation_scores["alice"]
    bob_rep_after_loss = pd.reputation_scores["bob"]
    
    print(f"\nAfter LOSS:")
    print(f"  Alice: {alice_rep_after_loss / ProfitDistribution.SCALE * 100:.1f}%")
    print(f"  Bob: {bob_rep_after_loss / ProfitDistribution.SCALE * 100:.1f}%")
    
    expected_after_loss = 450_000  # 55% - 10%
    if alice_rep_after_loss != expected_after_loss:
        print_result(False, "Alice reputation should be 45%")
        passed = False
    else:
        print_result(True, "Alice reputation decreased to 45% (-10%)")
    
    if bob_rep_after_loss != expected_after_loss:
        print_result(False, "Bob reputation mismatch")
        passed = False
    else:
        print_result(True, "Bob reputation decreased to 45% (-10%)")
    
    return passed

def test_stake_slash():
    """TEST 4: Stake Slashing Mechanism"""
    print_test_header("Stake Slashing")
    
    pd = ProfitDistribution()
    
    # Alice deposits 50 tokens stake
    initial_stake = 50 * ProfitDistribution.SCALE
    stake = pd.deposit_stake(initial_stake, role=0, owner="alice")
    
    print(f"Alice deposits: {initial_stake / ProfitDistribution.SCALE:.2f} tokens stake")
    print(f"Stake locked until: block {stake.locked_until}")
    
    # 3 failures → 3 slashes
    for i in range(3):
        pd.penalize_failure("alice", "bob", 100 * ProfitDistribution.SCALE)
        current_stake = pd.stake_amounts["alice"]
        slash_count = pd.slash_counts["alice"]
        print(f"\nSlash {i+1}: {current_stake / ProfitDistribution.SCALE:.2f} tokens remaining (slashes: {slash_count})")
    
    final_stake = pd.stake_amounts["alice"]
    final_slashes = pd.slash_counts["alice"]
    
    passed = True
    
    # After 3 slashes of 10% each: 50 × 0.9 × 0.9 × 0.9 = 36.45
    expected_stake = int(50 * 0.9 * 0.9 * 0.9 * ProfitDistribution.SCALE)
    if abs(final_stake - expected_stake) > 100_000:  # Allow some rounding
        print_result(False, f"Stake mismatch: {final_stake / ProfitDistribution.SCALE:.2f} (expected ~36.45)")
        passed = False
    else:
        print_result(True, f"Stake correctly slashed to ~{final_stake / ProfitDistribution.SCALE:.2f} tokens")
    
    if final_slashes != 3:
        print_result(False, f"Slash count should be 3 (got {final_slashes})")
        passed = False
    else:
        print_result(True, "Slash count = 3")
    
    # 10 total slashes → stake goes to zero
    print(f"\n{Colors.YELLOW}Testing MAX_SLASH_COUNT (10 failures)...{Colors.END}")
    
    for i in range(7):  # 7 more slashes (total = 10)
        pd.penalize_failure("alice", "bob", 100 * ProfitDistribution.SCALE)
    
    final_stake_after_max = pd.stake_amounts["alice"]
    
    if final_stake_after_max != 0:
        print_result(False, f"Stake should be 0 after 10 slashes (got {final_stake_after_max / ProfitDistribution.SCALE:.2f})")
        passed = False
    else:
        print_result(True, "Stake completely lost after 10 failures ✓")
    
    return passed

def test_multiple_distributions():
    """TEST 5: Multiple Distribution Rounds"""
    print_test_header("Multiple Distributions Over Time")
    
    pd = ProfitDistribution()
    
    # 5 successful predictions
    profits = [100, 150, 80, 120, 200]
    
    print(f"Running 5 distributions: {profits} tokens\n")
    
    for i, profit in enumerate(profits, 1):
        (data_share, model_share, pool_share) = pd.distribute_profit(
            profit * ProfitDistribution.SCALE,
            "alice",
            "bob",
            prediction_id=i
        )
        
        # Reputation increases each time
        alice_rep = pd.reputation_scores["alice"]
        bob_rep = pd.reputation_scores["bob"]
        
        print(f"Round {i}: {profit} tokens profit")
        print(f"  Alice reputation: {alice_rep / ProfitDistribution.SCALE * 100:.1f}%")
        print(f"  Alice earned: {data_share.amount / ProfitDistribution.SCALE:.2f} tokens")
    
    # Check final stats
    stats = pd.get_distribution_stats()
    total_dists, total_profit, data_paid, model_paid, pool_alloc = stats
    
    print(f"\n{Colors.BOLD}Final System Stats:{Colors.END}")
    print(f"  Total distributions: {total_dists}")
    print(f"  Total profit: {total_profit / ProfitDistribution.SCALE:.2f} tokens")
    print(f"  Data providers earned: {data_paid / ProfitDistribution.SCALE:.2f} tokens")
    print(f"  Model creators earned: {model_paid / ProfitDistribution.SCALE:.2f} tokens")
    print(f"  Pool allocated: {pool_alloc / ProfitDistribution.SCALE:.2f} tokens")
    
    passed = True
    
    expected_dists = 5
    if total_dists != expected_dists:
        print_result(False, f"Distribution count should be {expected_dists}")
        passed = False
    else:
        print_result(True, f"Tracked {total_dists} distributions")
    
    expected_total = sum(profits) * ProfitDistribution.SCALE
    if total_profit != expected_total:
        print_result(False, "Total profit mismatch")
        passed = False
    else:
        print_result(True, f"Total profit = {expected_total / ProfitDistribution.SCALE:.2f} tokens")
    
    # Alice's reputation should be higher now (5 wins × +5%)
    final_alice_rep = pd.reputation_scores["alice"]
    expected_rep = min(500_000 + 5 * 50_000, ProfitDistribution.MAX_REPUTATION)
    if final_alice_rep != expected_rep:
        print_result(False, f"Alice reputation should be {expected_rep / 10000:.1f}%")
        passed = False
    else:
        print_result(True, f"Alice reputation increased to {final_alice_rep / 10000:.1f}% (5 wins)")
    
    return passed

def test_success_rate_calculation():
    """TEST 6: Success Rate Calculation"""
    print_test_header("Success Rate Calculation")
    
    pd = ProfitDistribution()
    
    # Alice: 7 wins, 3 losses (70% success rate)
    for i in range(7):
        pd.distribute_profit(100 * ProfitDistribution.SCALE, "alice", "bob", i)
    
    for i in range(3):
        pd.penalize_failure("alice", "bob", 100 * ProfitDistribution.SCALE)
    
    alice_info = pd.get_participant_info("alice")
    alice_success_rate = pd.calculate_success_rate("alice")
    
    print(f"Alice stats:")
    print(f"  Total contributions: {alice_info.total_contributions}")
    print(f"  Successful predictions: {alice_info.successful_predictions}")
    print(f"  Success rate: {alice_success_rate / ProfitDistribution.SCALE * 100:.1f}%")
    print(f"  Reputation: {alice_info.reputation_score / ProfitDistribution.SCALE * 100:.1f}%")
    
    passed = True
    
    expected_contributions = 10
    if alice_info.total_contributions != expected_contributions:
        print_result(False, f"Contributions should be {expected_contributions}")
        passed = False
    else:
        print_result(True, f"Contributions = {expected_contributions}")
    
    expected_successes = 7
    if alice_info.successful_predictions != expected_successes:
        print_result(False, f"Successes should be {expected_successes}")
        passed = False
    else:
        print_result(True, f"Successes = {expected_successes}")
    
    expected_rate = 700_000  # 70%
    if alice_success_rate != expected_rate:
        print_result(False, f"Success rate should be 70% (got {alice_success_rate / 10000:.1f}%)")
        passed = False
    else:
        print_result(True, "Success rate = 70%")
    
    return passed

def test_stake_withdraw():
    """TEST 7: Stake Withdrawal"""
    print_test_header("Stake Withdrawal")
    
    pd = ProfitDistribution()
    
    # Deposit 30 tokens
    stake_amount = 30 * ProfitDistribution.SCALE
    stake = pd.deposit_stake(stake_amount, role=1, owner="charlie")
    
    print(f"Charlie deposits: {stake_amount / ProfitDistribution.SCALE:.2f} tokens")
    print(f"Locked until block: {stake.locked_until}")
    print(f"Current block: {pd.block_height}")
    
    # Try to withdraw immediately (should fail)
    try:
        pd.withdraw_stake(stake, current_block=pd.block_height)
        print_result(False, "Should not allow immediate withdrawal")
        passed = False
    except AssertionError as e:
        print_result(True, f"Correctly blocked: {e}")
        passed = True
    
    # Advance time
    pd.block_height += ProfitDistribution.STAKE_LOCK_PERIOD + 1000
    
    print(f"\nAdvanced to block: {pd.block_height}")
    
    # Now withdraw should work
    withdrawn = pd.withdraw_stake(stake, current_block=pd.block_height)
    
    print(f"Withdrawn: {withdrawn / ProfitDistribution.SCALE:.2f} tokens")
    
    if withdrawn != stake_amount:
        print_result(False, f"Withdrawn amount mismatch: {withdrawn / ProfitDistribution.SCALE:.2f}")
        passed = False
    else:
        print_result(True, "Full stake withdrawn successfully")
    
    # Check stake cleared
    final_stake = pd.stake_amounts.get("charlie", 0)
    if final_stake != 0:
        print_result(False, f"Stake should be 0 after withdrawal (got {final_stake / ProfitDistribution.SCALE:.2f})")
        passed = False
    else:
        print_result(True, "Stake cleared from mapping")
    
    return passed

def test_edge_case_zero_reputation():
    """TEST 8: Edge Case - Zero Reputation"""
    print_test_header("Edge Case: Zero Reputation")
    
    pd = ProfitDistribution()
    
    # Set reputation to 0%
    pd.reputation_scores["david"] = 0
    pd.reputation_scores["eve"] = 0
    
    profit = 100 * ProfitDistribution.SCALE
    
    (data_share, model_share, pool_share) = pd.distribute_profit(
        profit, "david", "eve", prediction_id=99
    )
    
    print(f"Profit: {profit / ProfitDistribution.SCALE:.2f} tokens")
    print(f"Both participants at 0% reputation")
    
    print_distribution_summary(
        data_share.amount, model_share.amount, pool_share, profit
    )
    
    passed = True
    
    # Zero reputation → no bonus → base shares only (40 tokens each)
    expected_base = 40 * ProfitDistribution.SCALE
    if data_share.amount != expected_base:
        print_result(False, f"Data share should be 40 tokens (no bonus)")
        passed = False
    else:
        print_result(True, "Data share = 40 tokens (no bonus)")
    
    if data_share.reputation_bonus != 0:
        print_result(False, "Bonus should be 0 for zero reputation")
        passed = False
    else:
        print_result(True, "Reputation bonus = 0")
    
    # Pool gets full 20 tokens (no bonus deduction)
    expected_pool = 20 * ProfitDistribution.SCALE
    if pool_share != expected_pool:
        print_result(False, f"Pool should get full 20 tokens")
        passed = False
    else:
        print_result(True, "Pool gets full 20 tokens (no bonus deductions)")
    
    return passed

def test_edge_case_max_reputation():
    """TEST 9: Edge Case - Max Reputation (100%)"""
    print_test_header("Edge Case: Max Reputation")
    
    pd = ProfitDistribution()
    
    # Set reputation to 100%
    pd.reputation_scores["frank"] = ProfitDistribution.MAX_REPUTATION
    pd.reputation_scores["grace"] = ProfitDistribution.MAX_REPUTATION
    
    profit = 100 * ProfitDistribution.SCALE
    
    (data_share, model_share, pool_share) = pd.distribute_profit(
        profit, "frank", "grace", prediction_id=100
    )
    
    print(f"Profit: {profit / ProfitDistribution.SCALE:.2f} tokens")
    print(f"Both participants at 100% reputation (MAX)")
    
    print_distribution_summary(
        data_share.amount, model_share.amount, pool_share, profit
    )
    
    passed = True
    
    # 100% reputation → max bonus (20%)
    # Base: 40, Bonus: 40 × 1.0 × 0.2 = 8, Total: 48
    expected_total = 48 * ProfitDistribution.SCALE
    if abs(data_share.amount - expected_total) > 10_000:  # Allow rounding
        print_result(False, f"Data share should be ~48 tokens (got {data_share.amount / ProfitDistribution.SCALE:.2f})")
        passed = False
    else:
        print_result(True, f"Data share = {data_share.amount / ProfitDistribution.SCALE:.2f} tokens (40 + 20% bonus)")
    
    # Bonus should be 8 tokens (20% of 40)
    expected_bonus = 8 * ProfitDistribution.SCALE
    if abs(data_share.reputation_bonus - expected_bonus) > 10_000:
        print_result(False, f"Bonus should be ~8 tokens")
        passed = False
    else:
        print_result(True, f"Reputation bonus = {data_share.reputation_bonus / ProfitDistribution.SCALE:.2f} tokens (max 20%)")
    
    # Pool gets reduced (20 - 16 = 4 tokens, since both get 8 bonus)
    expected_pool = 4 * ProfitDistribution.SCALE
    if abs(pool_share - expected_pool) > 10_000:
        print_result(False, f"Pool should get ~4 tokens (20 - bonuses)")
        passed = False
    else:
        print_result(True, f"Pool gets {pool_share / ProfitDistribution.SCALE:.2f} tokens (reduced by bonuses)")
    
    # Total still 100
    total = data_share.amount + model_share.amount + pool_share
    if abs(total - profit) > 10_000:
        print_result(False, "Total conservation violated")
        passed = False
    else:
        print_result(True, "Total still equals 100 tokens ✓")
    
    return passed

def test_edge_case_min_stake():
    """TEST 10: Edge Case - Minimum Stake Requirement"""
    print_test_header("Edge Case: Minimum Stake")
    
    pd = ProfitDistribution()
    
    # Try to deposit less than minimum (10 tokens)
    too_small = 5 * ProfitDistribution.SCALE
    
    print(f"Attempting to deposit {too_small / ProfitDistribution.SCALE:.2f} tokens (min: 10)")
    
    passed = True
    
    try:
        pd.deposit_stake(too_small, role=0, owner="helen")
        print_result(False, "Should reject stake below minimum")
        passed = False
    except AssertionError as e:
        print_result(True, f"Correctly rejected: {e}")
    
    # Deposit exactly minimum (should work)
    min_stake = ProfitDistribution.MIN_STAKE_AMOUNT
    
    print(f"\nDepositing minimum: {min_stake / ProfitDistribution.SCALE:.2f} tokens")
    
    stake = pd.deposit_stake(min_stake, role=0, owner="helen")
    
    if stake.amount != min_stake:
        print_result(False, "Stake amount mismatch")
        passed = False
    else:
        print_result(True, "Minimum stake accepted (10 tokens)")
    
    return passed

# ─────────────────────────────────────────────────────────────────────────────
# Main Test Runner
# ─────────────────────────────────────────────────────────────────────────────

def main():
    """Run all tests"""
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'═' * 70}")
    print(" PROPHETIA PROFIT DISTRIBUTION TEST SUITE - Week 7")
    print(f"{'═' * 70}{Colors.END}\n")
    
    tests = [
        ("Basic 40-40-20 Distribution", test_basic_distribution),
        ("Reputation Bonus", test_reputation_bonus),
        ("Reputation Updates", test_reputation_update),
        ("Stake Slashing", test_stake_slash),
        ("Multiple Distributions", test_multiple_distributions),
        ("Success Rate Calculation", test_success_rate_calculation),
        ("Stake Withdrawal", test_stake_withdraw),
        ("Edge Case: Zero Reputation", test_edge_case_zero_reputation),
        ("Edge Case: Max Reputation", test_edge_case_max_reputation),
        ("Edge Case: Min Stake", test_edge_case_min_stake),
    ]
    
    results = []
    
    for name, test_func in tests:
        try:
            passed = test_func()
            results.append((name, passed))
        except Exception as e:
            print(f"{Colors.RED}✗ EXCEPTION{Colors.END} - {name}: {e}")
            results.append((name, False))
    
    # Summary
    print(f"\n{Colors.CYAN}{'═' * 70}")
    print(" TEST SUMMARY")
    print(f"{'═' * 70}{Colors.END}\n")
    
    for name, passed in results:
        if passed:
            print(f"{Colors.GREEN}✓ PASS{Colors.END} - {name}")
        else:
            print(f"{Colors.RED}✗ FAIL{Colors.END} - {name}")
    
    passed_count = sum(1 for _, p in results if p)
    total_count = len(results)
    
    print(f"\n{Colors.BOLD}Results: {passed_count}/{total_count} tests passed{Colors.END}\n")
    
    if passed_count == total_count:
        print(f"{Colors.GREEN}{'━' * 70}")
        print(" 🎉 ALL TESTS PASSED! Profit Distribution System Validated! 🎉")
        print(f"{'━' * 70}{Colors.END}\n")
        return 0
    else:
        print(f"{Colors.RED}{'━' * 70}")
        print(f" ⚠️  {total_count - passed_count} TEST(S) FAILED")
        print(f"{'━' * 70}{Colors.END}\n")
        return 1

if __name__ == "__main__":
    exit(main())
