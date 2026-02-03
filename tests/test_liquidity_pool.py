#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════
PROPHETIA LIQUIDITY POOL TEST SUITE - Week 5
═══════════════════════════════════════════════════════════════════════════

This test suite validates the liquidity pool system that powers PROPHETIA's
economic layer. Investors deposit capital, earn returns from successful
predictions, and can withdraw at any time.

TEST COVERAGE:
✅ First deposit (1:1 share ratio)
✅ Subsequent deposits (proportional shares)
✅ Full withdrawal (burn all shares)
✅ Partial withdrawal (burn some shares)
✅ Profit distribution (share value increases)
✅ Loss distribution (share value decreases)
✅ Multiple depositors (fair allocation)
✅ Minimum deposit check (security)
✅ Share value calculation (helper function)

TESTING APPROACH:
- Simulate Leo contract logic in Python
- Validate mathematical correctness
- Check edge cases and security
- Verify economic fairness

Run: python3 tests/test_liquidity_pool.py
"""

# ───────────────────────────────────────────────────────────────────────────
# LIQUIDITY POOL SIMULATOR (Python Implementation)
# ───────────────────────────────────────────────────────────────────────────

class LiquidityPool:
    """
    Simulates prophetia_pool.aleo contract behavior.
    Mirrors Leo implementation for testing validation.
    """
    
    SCALE = 1_000_000  # Fixed-point scale factor
    MIN_DEPOSIT = 1_000_000  # Minimum deposit (1.0 token)
    
    def __init__(self):
        """Initialize empty pool"""
        self.total_liquidity = 0
        self.total_shares = 0
        self.total_bets = 0
        self.total_profit = 0
        self.total_loss = 0
        self.next_share_id = 1
        self.shares = {}  # share_id -> amount
        
    def deposit_liquidity(self, amount: int) -> dict:
        """
        Deposit tokens into pool, receive shares.
        
        Args:
            amount: Token amount to deposit (scaled by 10^6)
            
        Returns:
            dict with:
                - share_id: Unique identifier
                - shares: Number of shares minted
                - share_value: Current value per share
                
        Raises:
            AssertionError: If amount < MIN_DEPOSIT
        """
        # Validation
        assert amount >= self.MIN_DEPOSIT, f"Deposit {amount} below minimum {self.MIN_DEPOSIT}"
        
        # Calculate shares to mint
        if self.total_liquidity == 0:
            # First deposit: 1:1 ratio
            new_shares = amount
        else:
            # Subsequent: proportional
            # new_shares = (amount × total_shares) / total_liquidity
            new_shares = (amount * self.total_shares) // self.total_liquidity
            
        # Update pool state
        self.total_liquidity += amount
        self.total_shares += new_shares
        
        # Mint share record
        share_id = self.next_share_id
        self.shares[share_id] = new_shares
        self.next_share_id += 1
        
        # Calculate value per share
        share_value_per_share = self.total_liquidity / self.total_shares if self.total_shares > 0 else 1.0
        
        return {
            'share_id': share_id,
            'shares': new_shares,
            'share_value': share_value_per_share  # Value per single share
        }
    
    def withdraw_liquidity(self, share_id: int) -> dict:
        """
        Burn shares and withdraw proportional liquidity.
        
        Args:
            share_id: ID of share record to burn
            
        Returns:
            dict with:
                - withdrawal: Token amount withdrawn
                - share_value: Value per share at withdrawal
                
        Raises:
            AssertionError: If share_id invalid or pool empty
        """
        # Validation
        assert share_id in self.shares, f"Invalid share_id {share_id}"
        assert self.total_liquidity > 0, "Pool empty"
        assert self.total_shares > 0, "No shares outstanding"
        
        # Get user's shares
        user_shares = self.shares[share_id]
        
        # Calculate withdrawal amount
        # withdrawal = (user_shares × total_liquidity) / total_shares
        withdrawal = (user_shares * self.total_liquidity) // self.total_shares
        
        # Update pool state
        self.total_liquidity -= withdrawal
        self.total_shares -= user_shares
        
        # Burn share record
        del self.shares[share_id]
        
        # Calculate value per share at withdrawal
        share_value_per_share = (withdrawal / user_shares) if user_shares > 0 else 0
        
        return {
            'withdrawal': withdrawal,
            'share_value': share_value_per_share  # Value per single share at withdrawal
        }
    
    def record_bet(self, bet_amount: int):
        """Record a bet placement (increments counter)"""
        self.total_bets += 1
    
    def record_profit(self, profit_amount: int):
        """
        Record pool profit from successful prediction.
        Increases liquidity (share value rises).
        """
        self.total_liquidity += profit_amount
        self.total_profit += profit_amount
    
    def record_loss(self, loss_amount: int):
        """
        Record pool loss from failed prediction.
        Decreases liquidity (share value falls).
        """
        assert self.total_liquidity >= loss_amount, "Insufficient liquidity for loss"
        self.total_liquidity -= loss_amount
        self.total_loss += loss_amount
    
    def get_pool_stats(self) -> dict:
        """Get comprehensive pool statistics"""
        return {
            'total_liquidity': self.total_liquidity,
            'total_shares': self.total_shares,
            'total_bets': self.total_bets,
            'total_profit': self.total_profit,
            'total_loss': self.total_loss,
            'share_value': self.total_liquidity / self.total_shares if self.total_shares > 0 else 0,
            'net_profit': self.total_profit - self.total_loss,
            'roi': ((self.total_profit - self.total_loss) / (self.total_liquidity - self.total_profit + self.total_loss)) * 100 if (self.total_liquidity - self.total_profit + self.total_loss) > 0 else 0
        }
    
    def calculate_share_value_internal(self, shares: int) -> int:
        """Calculate current value of given shares"""
        if self.total_shares == 0:
            return 0
        return (shares * self.total_liquidity) // self.total_shares

# ───────────────────────────────────────────────────────────────────────────
# TEST UTILITIES
# ───────────────────────────────────────────────────────────────────────────

# ANSI color codes for output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    RESET = '\033[0m'

def print_test_header(test_name: str):
    """Print formatted test header"""
    print(f"\n{Colors.CYAN}{'═' * 70}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}TEST: {test_name}{Colors.RESET}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.RESET}")

def print_result(passed: bool, message: str):
    """Print test result with color"""
    status = f"{Colors.GREEN}✓ PASS{Colors.RESET}" if passed else f"{Colors.RED}✗ FAIL{Colors.RESET}"
    print(f"{status} - {message}")

def print_pool_state(pool: LiquidityPool, label: str = "Pool State"):
    """Print formatted pool statistics"""
    stats = pool.get_pool_stats()
    print(f"\n{Colors.YELLOW}{label}:{Colors.RESET}")
    print(f"  Total Liquidity: {stats['total_liquidity']:,} ({stats['total_liquidity'] / LiquidityPool.SCALE:.6f} tokens)")
    print(f"  Total Shares: {stats['total_shares']:,} ({stats['total_shares'] / LiquidityPool.SCALE:.6f} shares)")
    print(f"  Share Value: {stats['share_value']:.6f} tokens/share")
    print(f"  Total Bets: {stats['total_bets']}")
    print(f"  Total Profit: {stats['total_profit']:,} ({stats['total_profit'] / LiquidityPool.SCALE:.6f} tokens)")
    print(f"  Total Loss: {stats['total_loss']:,} ({stats['total_loss'] / LiquidityPool.SCALE:.6f} tokens)")
    print(f"  Net Profit: {stats['net_profit']:,} ({stats['net_profit'] / LiquidityPool.SCALE:.6f} tokens)")
    print(f"  ROI: {stats['roi']:.2f}%")

# ───────────────────────────────────────────────────────────────────────────
# TEST CASES
# ───────────────────────────────────────────────────────────────────────────

def test_first_deposit():
    """
    TEST 1: First Deposit (1:1 Share Ratio)
    
    Validates that the first depositor receives shares equal to their deposit.
    This establishes the initial 1:1 ratio.
    
    Scenario:
    - Alice deposits 100 tokens
    - Should receive 100 shares
    - Share value should be 1.0
    """
    print_test_header("First Deposit (1:1 Ratio)")
    
    pool = LiquidityPool()
    
    # Alice deposits 100 tokens
    alice_deposit = 100 * LiquidityPool.SCALE
    result = pool.deposit_liquidity(alice_deposit)
    
    print(f"\nAlice deposits: {alice_deposit:,} ({alice_deposit / LiquidityPool.SCALE:.1f} tokens)")
    print(f"Alice receives: {result['shares']:,} ({result['shares'] / LiquidityPool.SCALE:.1f} shares)")
    
    # Validate
    expected_shares = alice_deposit  # 1:1 ratio
    passed = result['shares'] == expected_shares
    print_result(passed, f"Alice should receive {expected_shares:,} shares")
    
    # Check share value (it's already a ratio, not scaled)
    share_value = result['share_value']
    passed &= abs(share_value - 1.0) < 0.000001
    print_result(passed, f"Share value should be 1.0 (actual: {share_value:.6f})")
    
    print_pool_state(pool, "Pool State After First Deposit")
    
    return passed

def test_subsequent_deposit():
    """
    TEST 2: Subsequent Deposit (Proportional Shares)
    
    Validates that later depositors receive proportional shares.
    This ensures fair treatment of all investors.
    
    Scenario:
    - Alice deposits 100 tokens (receives 100 shares)
    - Bob deposits 50 tokens
    - Bob should receive 50 shares (proportional)
    - Share value remains 1.0 for both
    """
    print_test_header("Subsequent Deposit (Proportional Shares)")
    
    pool = LiquidityPool()
    
    # Alice deposits 100 tokens
    alice_deposit = 100 * LiquidityPool.SCALE
    alice_result = pool.deposit_liquidity(alice_deposit)
    print(f"\nAlice deposits: {alice_deposit / LiquidityPool.SCALE:.1f} tokens → {alice_result['shares'] / LiquidityPool.SCALE:.1f} shares")
    
    # Bob deposits 50 tokens
    bob_deposit = 50 * LiquidityPool.SCALE
    bob_result = pool.deposit_liquidity(bob_deposit)
    print(f"Bob deposits: {bob_deposit / LiquidityPool.SCALE:.1f} tokens → {bob_result['shares'] / LiquidityPool.SCALE:.1f} shares")
    
    # Validate Bob's shares
    # Formula: (50 × 100) / 100 = 50
    expected_bob_shares = (bob_deposit * pool.total_shares - bob_result['shares']) // (pool.total_liquidity - bob_deposit)
    expected_bob_shares = 50 * LiquidityPool.SCALE
    
    passed = bob_result['shares'] == expected_bob_shares
    print_result(passed, f"Bob should receive {expected_bob_shares / LiquidityPool.SCALE:.1f} shares")
    
    # Check share values are equal
    alice_value = alice_result['share_value']
    bob_value = bob_result['share_value']
    values_equal = abs(alice_value - bob_value) < 0.000001
    
    passed &= values_equal
    print_result(passed, f"Share values equal (Alice: {alice_value:.6f}, Bob: {bob_value:.6f})")
    
    print_pool_state(pool, "Pool State After Both Deposits")
    
    return passed

def test_full_withdrawal():
    """
    TEST 3: Full Withdrawal (Burn All Shares)
    
    Validates that a user can withdraw their entire position.
    
    Scenario:
    - Alice deposits 100 tokens
    - Alice withdraws all shares
    - Should receive 100 tokens back
    - Pool should be empty
    """
    print_test_header("Full Withdrawal")
    
    pool = LiquidityPool()
    
    # Alice deposits 100 tokens
    alice_deposit = 100 * LiquidityPool.SCALE
    alice_result = pool.deposit_liquidity(alice_deposit)
    alice_share_id = alice_result['share_id']
    
    print(f"\nAlice deposits: {alice_deposit / LiquidityPool.SCALE:.1f} tokens")
    print(f"Alice receives share_id: {alice_share_id}")
    
    # Alice withdraws
    withdrawal_result = pool.withdraw_liquidity(alice_share_id)
    withdrawal = withdrawal_result['withdrawal']
    
    print(f"Alice withdraws: {withdrawal / LiquidityPool.SCALE:.1f} tokens")
    
    # Validate
    passed = withdrawal == alice_deposit
    print_result(passed, f"Alice should receive {alice_deposit / LiquidityPool.SCALE:.1f} tokens back")
    
    # Check pool is empty
    passed &= pool.total_liquidity == 0
    passed &= pool.total_shares == 0
    print_result(passed, "Pool should be empty after full withdrawal")
    
    print_pool_state(pool, "Pool State After Withdrawal")
    
    return passed

def test_partial_withdrawal():
    """
    TEST 4: Partial Withdrawal (Multi-User Pool)
    
    Validates withdrawal with multiple shareholders.
    
    Scenario:
    - Alice deposits 100 tokens (100 shares)
    - Bob deposits 50 tokens (50 shares)
    - Alice withdraws (should get 100 tokens)
    - Bob remains with 50 tokens worth of shares
    """
    print_test_header("Partial Withdrawal (Multi-User)")
    
    pool = LiquidityPool()
    
    # Setup: Two depositors
    alice_deposit = 100 * LiquidityPool.SCALE
    alice_result = pool.deposit_liquidity(alice_deposit)
    
    bob_deposit = 50 * LiquidityPool.SCALE
    bob_result = pool.deposit_liquidity(bob_deposit)
    
    print(f"\nInitial State:")
    print(f"  Alice: {alice_deposit / LiquidityPool.SCALE:.1f} tokens → {alice_result['shares'] / LiquidityPool.SCALE:.1f} shares")
    print(f"  Bob: {bob_deposit / LiquidityPool.SCALE:.1f} tokens → {bob_result['shares'] / LiquidityPool.SCALE:.1f} shares")
    print(f"  Pool Total: 150 tokens, 150 shares")
    
    # Alice withdraws
    alice_withdrawal = pool.withdraw_liquidity(alice_result['share_id'])
    
    print(f"\nAlice withdraws: {alice_withdrawal['withdrawal'] / LiquidityPool.SCALE:.1f} tokens")
    
    # Validate Alice's withdrawal
    passed = alice_withdrawal['withdrawal'] == alice_deposit
    print_result(passed, f"Alice should receive {alice_deposit / LiquidityPool.SCALE:.1f} tokens")
    
    # Validate pool state
    passed &= pool.total_liquidity == bob_deposit
    passed &= pool.total_shares == bob_result['shares']
    print_result(passed, "Pool should have Bob's 50 tokens and 50 shares remaining")
    
    # Validate Bob's share value unchanged
    bob_value = pool.calculate_share_value_internal(bob_result['shares'])
    passed &= bob_value == bob_deposit
    print_result(passed, f"Bob's shares should still be worth {bob_deposit / LiquidityPool.SCALE:.1f} tokens")
    
    print_pool_state(pool, "Pool State After Alice Withdrawal")
    
    return passed

def test_profit_distribution():
    """
    TEST 5: Profit Distribution (Share Value Increases)
    
    Validates that pool profits automatically increase share value.
    
    Scenario:
    - Alice deposits 100 tokens (100 shares)
    - Pool earns 20 tokens profit
    - Alice's shares now worth 120 tokens (20% gain)
    - Alice withdraws and receives 120 tokens
    """
    print_test_header("Profit Distribution")
    
    pool = LiquidityPool()
    
    # Alice deposits 100 tokens
    alice_deposit = 100 * LiquidityPool.SCALE
    alice_result = pool.deposit_liquidity(alice_deposit)
    
    print(f"\nAlice deposits: {alice_deposit / LiquidityPool.SCALE:.1f} tokens")
    print_pool_state(pool, "Pool State After Deposit")
    
    # Pool earns 20 tokens profit
    profit = 20 * LiquidityPool.SCALE
    pool.record_profit(profit)
    
    print(f"\n{Colors.GREEN}Pool earns profit: {profit / LiquidityPool.SCALE:.1f} tokens{Colors.RESET}")
    print_pool_state(pool, "Pool State After Profit")
    
    # Check share value increased
    new_share_value = pool.calculate_share_value_internal(alice_result['shares'])
    expected_value = alice_deposit + profit  # 120 tokens
    
    passed = new_share_value == expected_value
    print_result(passed, f"Alice's shares should now be worth {expected_value / LiquidityPool.SCALE:.1f} tokens")
    
    # Alice withdraws
    withdrawal = pool.withdraw_liquidity(alice_result['share_id'])
    
    print(f"\nAlice withdraws: {withdrawal['withdrawal'] / LiquidityPool.SCALE:.1f} tokens")
    
    # Validate withdrawal amount
    passed &= withdrawal['withdrawal'] == expected_value
    print_result(passed, f"Alice should receive {expected_value / LiquidityPool.SCALE:.1f} tokens (20% profit!)")
    
    # Calculate ROI
    roi = ((withdrawal['withdrawal'] - alice_deposit) / alice_deposit) * 100
    print(f"\n{Colors.GREEN}Alice's ROI: {roi:.1f}%{Colors.RESET}")
    
    return passed

def test_loss_distribution():
    """
    TEST 6: Loss Distribution (Share Value Decreases)
    
    Validates that pool losses automatically decrease share value.
    
    Scenario:
    - Alice deposits 100 tokens (100 shares)
    - Pool loses 20 tokens
    - Alice's shares now worth 80 tokens (20% loss)
    - Alice withdraws and receives 80 tokens
    """
    print_test_header("Loss Distribution")
    
    pool = LiquidityPool()
    
    # Alice deposits 100 tokens
    alice_deposit = 100 * LiquidityPool.SCALE
    alice_result = pool.deposit_liquidity(alice_deposit)
    
    print(f"\nAlice deposits: {alice_deposit / LiquidityPool.SCALE:.1f} tokens")
    print_pool_state(pool, "Pool State After Deposit")
    
    # Pool loses 20 tokens
    loss = 20 * LiquidityPool.SCALE
    pool.record_loss(loss)
    
    print(f"\n{Colors.RED}Pool incurs loss: {loss / LiquidityPool.SCALE:.1f} tokens{Colors.RESET}")
    print_pool_state(pool, "Pool State After Loss")
    
    # Check share value decreased
    new_share_value = pool.calculate_share_value_internal(alice_result['shares'])
    expected_value = alice_deposit - loss  # 80 tokens
    
    passed = new_share_value == expected_value
    print_result(passed, f"Alice's shares should now be worth {expected_value / LiquidityPool.SCALE:.1f} tokens")
    
    # Alice withdraws
    withdrawal = pool.withdraw_liquidity(alice_result['share_id'])
    
    print(f"\nAlice withdraws: {withdrawal['withdrawal'] / LiquidityPool.SCALE:.1f} tokens")
    
    # Validate withdrawal amount
    passed &= withdrawal['withdrawal'] == expected_value
    print_result(passed, f"Alice should receive {expected_value / LiquidityPool.SCALE:.1f} tokens (20% loss)")
    
    # Calculate loss percentage
    loss_pct = ((alice_deposit - withdrawal['withdrawal']) / alice_deposit) * 100
    print(f"\n{Colors.RED}Alice's Loss: {loss_pct:.1f}%{Colors.RESET}")
    
    return passed

def test_multiple_depositors():
    """
    TEST 7: Multiple Depositors (Fairness Check)
    
    Validates fair profit/loss distribution among multiple investors.
    
    Scenario:
    - Alice deposits 100 tokens (66.67% of pool)
    - Bob deposits 50 tokens (33.33% of pool)
    - Pool earns 30 tokens profit
    - Alice gets 20 tokens profit (66.67%)
    - Bob gets 10 tokens profit (33.33%)
    """
    print_test_header("Multiple Depositors (Fairness)")
    
    pool = LiquidityPool()
    
    # Setup deposits
    alice_deposit = 100 * LiquidityPool.SCALE
    alice_result = pool.deposit_liquidity(alice_deposit)
    
    bob_deposit = 50 * LiquidityPool.SCALE
    bob_result = pool.deposit_liquidity(bob_deposit)
    
    print(f"\nInitial Deposits:")
    print(f"  Alice: {alice_deposit / LiquidityPool.SCALE:.1f} tokens (66.67% of pool)")
    print(f"  Bob: {bob_deposit / LiquidityPool.SCALE:.1f} tokens (33.33% of pool)")
    print_pool_state(pool, "Pool State After Deposits")
    
    # Pool earns profit
    profit = 30 * LiquidityPool.SCALE
    pool.record_profit(profit)
    
    print(f"\n{Colors.GREEN}Pool earns profit: {profit / LiquidityPool.SCALE:.1f} tokens{Colors.RESET}")
    print_pool_state(pool, "Pool State After Profit")
    
    # Calculate expected values
    total_pool = alice_deposit + bob_deposit + profit  # 180 tokens
    alice_expected = (alice_result['shares'] * total_pool) // pool.total_shares  # ~120 tokens
    bob_expected = (bob_result['shares'] * total_pool) // pool.total_shares  # ~60 tokens
    
    # Alice withdraws
    alice_withdrawal = pool.withdraw_liquidity(alice_result['share_id'])
    alice_profit = alice_withdrawal['withdrawal'] - alice_deposit
    
    print(f"\nAlice withdraws: {alice_withdrawal['withdrawal'] / LiquidityPool.SCALE:.1f} tokens")
    print(f"Alice's profit: {alice_profit / LiquidityPool.SCALE:.1f} tokens")
    
    # Bob withdraws
    bob_withdrawal = pool.withdraw_liquidity(bob_result['share_id'])
    bob_profit = bob_withdrawal['withdrawal'] - bob_deposit
    
    print(f"Bob withdraws: {bob_withdrawal['withdrawal'] / LiquidityPool.SCALE:.1f} tokens")
    print(f"Bob's profit: {bob_profit / LiquidityPool.SCALE:.1f} tokens")
    
    # Validate proportional profit distribution
    # Alice should get ~20 tokens (66.67% of 30)
    # Bob should get ~10 tokens (33.33% of 30)
    alice_expected_profit = 20 * LiquidityPool.SCALE
    bob_expected_profit = 10 * LiquidityPool.SCALE
    
    passed = abs(alice_profit - alice_expected_profit) < 1000  # Allow small rounding error
    print_result(passed, f"Alice should profit ~{alice_expected_profit / LiquidityPool.SCALE:.1f} tokens (66.67% of profit)")
    
    passed &= abs(bob_profit - bob_expected_profit) < 1000
    print_result(passed, f"Bob should profit ~{bob_expected_profit / LiquidityPool.SCALE:.1f} tokens (33.33% of profit)")
    
    # Verify profit distribution is fair
    total_distributed = alice_profit + bob_profit
    passed &= abs(total_distributed - profit) < 1000
    print_result(passed, f"Total profit distributed: {total_distributed / LiquidityPool.SCALE:.1f} tokens")
    
    return passed

def test_minimum_deposit():
    """
    TEST 8: Minimum Deposit Validation
    
    Validates that deposits below minimum are rejected.
    
    Scenario:
    - Try to deposit 0.5 tokens (below 1.0 minimum)
    - Should fail with assertion error
    """
    print_test_header("Minimum Deposit Validation")
    
    pool = LiquidityPool()
    
    # Try deposit below minimum
    invalid_deposit = 0.5 * LiquidityPool.SCALE
    
    print(f"\nAttempting deposit: {invalid_deposit / LiquidityPool.SCALE:.1f} tokens")
    print(f"Minimum required: {LiquidityPool.MIN_DEPOSIT / LiquidityPool.SCALE:.1f} tokens")
    
    try:
        pool.deposit_liquidity(int(invalid_deposit))
        passed = False
        print_result(False, "Should have rejected deposit below minimum")
    except AssertionError as e:
        passed = True
        print_result(True, f"Correctly rejected: {e}")
    
    # Try valid deposit
    valid_deposit = 1.0 * LiquidityPool.SCALE
    result = pool.deposit_liquidity(int(valid_deposit))
    
    print(f"\nAttempting deposit: {valid_deposit / LiquidityPool.SCALE:.1f} tokens")
    passed &= result['shares'] == valid_deposit
    print_result(passed, "Correctly accepted deposit at minimum")
    
    return passed

def test_share_value_calculation():
    """
    TEST 9: Share Value Calculation (Helper Function)
    
    Validates the calculate_share_value helper function.
    
    Scenario:
    - Alice deposits 100 tokens
    - Pool earns 20 tokens profit
    - Check share value via helper: should be 1.2 tokens/share
    """
    print_test_header("Share Value Calculation")
    
    pool = LiquidityPool()
    
    # Alice deposits
    alice_deposit = 100 * LiquidityPool.SCALE
    alice_result = pool.deposit_liquidity(alice_deposit)
    
    print(f"\nAlice deposits: {alice_deposit / LiquidityPool.SCALE:.1f} tokens")
    
    # Initial share value
    initial_value = pool.calculate_share_value_internal(alice_result['shares'])
    initial_value_per_share = initial_value / alice_result['shares']
    
    passed = abs(initial_value_per_share - 1.0) < 0.000001
    print_result(passed, f"Initial share value: {initial_value_per_share:.6f} tokens/share")
    
    # Pool profits
    profit = 20 * LiquidityPool.SCALE
    pool.record_profit(profit)
    
    print(f"\nPool earns: {profit / LiquidityPool.SCALE:.1f} tokens profit")
    
    # New share value
    new_value = pool.calculate_share_value_internal(alice_result['shares'])
    new_value_per_share = new_value / alice_result['shares']
    expected_per_share = 1.2  # 120 tokens / 100 shares
    
    passed &= abs(new_value_per_share - expected_per_share) < 0.000001
    print_result(passed, f"New share value: {new_value_per_share:.6f} tokens/share (expected: {expected_per_share:.6f})")
    
    # Check total value
    expected_total = alice_deposit + profit
    passed &= new_value == expected_total
    print_result(passed, f"Total value: {new_value / LiquidityPool.SCALE:.1f} tokens (expected: {expected_total / LiquidityPool.SCALE:.1f})")
    
    return passed

# ───────────────────────────────────────────────────────────────────────────
# TEST RUNNER
# ───────────────────────────────────────────────────────────────────────────

def run_all_tests():
    """Execute all test cases and report results"""
    
    print(f"\n{Colors.BOLD}{Colors.CYAN}")
    print("═" * 70)
    print(" PROPHETIA LIQUIDITY POOL TEST SUITE - Week 5")
    print("═" * 70)
    print(f"{Colors.RESET}")
    
    tests = [
        ("First Deposit (1:1 Ratio)", test_first_deposit),
        ("Subsequent Deposit (Proportional)", test_subsequent_deposit),
        ("Full Withdrawal", test_full_withdrawal),
        ("Partial Withdrawal", test_partial_withdrawal),
        ("Profit Distribution", test_profit_distribution),
        ("Loss Distribution", test_loss_distribution),
        ("Multiple Depositors", test_multiple_depositors),
        ("Minimum Deposit Validation", test_minimum_deposit),
        ("Share Value Calculation", test_share_value_calculation),
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            passed = test_func()
            results.append((test_name, passed))
        except Exception as e:
            print(f"\n{Colors.RED}ERROR in {test_name}: {e}{Colors.RESET}")
            results.append((test_name, False))
    
    # Summary
    print(f"\n{Colors.BOLD}{Colors.CYAN}")
    print("═" * 70)
    print(" TEST SUMMARY")
    print("═" * 70)
    print(f"{Colors.RESET}")
    
    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)
    
    for test_name, passed in results:
        status = f"{Colors.GREEN}✓ PASS{Colors.RESET}" if passed else f"{Colors.RED}✗ FAIL{Colors.RESET}"
        print(f"{status} - {test_name}")
    
    print(f"\n{Colors.BOLD}Results: {passed_count}/{total_count} tests passed{Colors.RESET}")
    
    if passed_count == total_count:
        print(f"{Colors.GREEN}{Colors.BOLD}")
        print("━" * 70)
        print(" 🎉 ALL TESTS PASSED! Liquidity Pool System Validated! 🎉")
        print("━" * 70)
        print(f"{Colors.RESET}")
    else:
        print(f"{Colors.RED}{Colors.BOLD}")
        print("━" * 70)
        print(f" ⚠️  {total_count - passed_count} TEST(S) FAILED")
        print("━" * 70)
        print(f"{Colors.RESET}")
    
    return passed_count == total_count

if __name__ == "__main__":
    success = run_all_tests()
    exit(0 if success else 1)
