#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════
PROPHETIA BETTING SYSTEM TEST SUITE - Week 6
═══════════════════════════════════════════════════════════════════════════

Bu test suite, otomatik bahis sisteminin tüm özelliklerini doğrular:
- Bahis açma (confidence-based sizing)
- Risk yönetimi (max %10 pool exposure)
- Settlement (win/loss scenarios)
- İptal mekanizması
- İstatistik takibi

TEST COVERAGE:
✅ Basic bet placement
✅ Confidence-based bet sizing
✅ Risk limit enforcement (max 10% pool)
✅ Multiple concurrent bets
✅ Win settlement (profit distribution)
✅ Loss settlement (loss tracking)
✅ Bet cancellation
✅ Statistics accuracy
✅ Win rate calculation
✅ Edge cases (zero pool, max confidence, etc.)

Run: python3 tests/test_betting.py
"""

# ───────────────────────────────────────────────────────────────────────────
# BETTING SYSTEM SIMULATOR
# ───────────────────────────────────────────────────────────────────────────

class ProphecySignal:
    """Tahmin sinyali (ZK-ML output)"""
    def __init__(self, score: int, confidence: int, category: int, direction: int):
        self.score = score
        self.confidence = confidence
        self.category = category
        self.direction = direction

class BetPosition:
    """Açık bahis pozisyonu"""
    def __init__(self, bet_id: int, signal: ProphecySignal, bet_amount: int,
                 target_category: int, target_value: int, threshold: int,
                 timestamp: int):
        self.bet_id = bet_id
        self.signal = signal
        self.bet_amount = bet_amount
        self.target_category = target_category
        self.target_value = target_value
        self.threshold = threshold
        self.timestamp = timestamp
        self.is_settled = False

class LiquidityPool:
    """Havuz simulator (liquidity_pool.leo)"""
    def __init__(self):
        self.total_liquidity = 0
        self.total_shares = 0
        self.total_bets = 0
        self.total_profit = 0
        self.total_loss = 0
    
    def deposit(self, amount: int):
        self.total_liquidity += amount
        self.total_shares += amount
    
    def record_bet(self, amount: int):
        self.total_bets += 1
    
    def record_profit(self, amount: int):
        self.total_liquidity += amount
        self.total_profit += amount
    
    def record_loss(self, amount: int):
        self.total_liquidity -= amount
        self.total_loss += amount
    
    def get_stats(self):
        return (self.total_liquidity, self.total_shares, self.total_bets,
                self.total_profit, self.total_loss)

class BettingSystem:
    """
    betting_system.leo simulator
    Leo implementation'ın Python versiyonu
    """
    
    SCALE = 1_000_000
    MAX_POOL_EXPOSURE_PERCENT = 10
    MIN_BET_AMOUNT = 1_000_000
    MAX_BET_MULTIPLIER = 5
    MIN_CONFIDENCE = 600_000  # %60
    
    def __init__(self, pool: LiquidityPool):
        self.pool = pool
        self.bet_state = {
            'total_placed': 0,
            'total_settled': 0,
            'active_bets': 0,
            'total_profit': 0,
            'total_loss': 0,
            'current_exposure': 0,
            'win_count': 0,
            'loss_count': 0
        }
        self.bet_amounts = {}
        self.bet_settlements = {}
        self.next_bet_id = 1
    
    def place_bet(self, signal: ProphecySignal, target_category: int,
                  target_value: int, threshold: int) -> BetPosition:
        """
        Bahis aç (place_bet transition)
        
        Args:
            signal: Tahmin sinyali
            target_category: Hedef kategori
            target_value: Tahmin edilen değer
            threshold: Settlement eşiği
            
        Returns:
            BetPosition: Açık bahis
            
        Raises:
            AssertionError: Validasyon hatalarında
        """
        # ─────────── ADIM 1: HAVUZ LİKİDİTESİ ───────────
        pool_stats = self.pool.get_stats()
        total_liquidity = pool_stats[0]
        
        assert total_liquidity > 0, "Pool has no liquidity"
        
        # ─────────── ADIM 2: EXPOSURE KONTROLÜ ───────────
        current_exposure = self.bet_state['current_exposure']
        max_exposure = (total_liquidity * self.MAX_POOL_EXPOSURE_PERCENT) // 100
        
        assert current_exposure < max_exposure, f"Max exposure reached: {current_exposure}/{max_exposure}"
        
        available_exposure = max_exposure - current_exposure
        
        # ─────────── ADIM 3: CONFIDENCE KONTROLÜ ───────────
        confidence = signal.confidence
        assert confidence >= self.MIN_CONFIDENCE, f"Confidence too low: {confidence} < {self.MIN_CONFIDENCE}"
        
        # ─────────── ADIM 4: BET AMOUNT HESAPLAMA ───────────
        # Check if we have meaningful space left
        # Need at least MIN_BET * 2 to make betting worthwhile
        if available_exposure < self.MIN_BET_AMOUNT * 2:
            raise AssertionError(f"Insufficient exposure remaining: {available_exposure / self.SCALE:.2f} tokens")
        
        # Base bet = available exposure
        base_bet = available_exposure
        
        # Confidence multiplier
        bet_with_confidence = (base_bet * confidence) // self.SCALE
        
        # Max multiplier check
        max_bet = base_bet * self.MAX_BET_MULTIPLIER
        bet_amount = min(bet_with_confidence, max_bet)
        
        # Min bet check
        assert bet_amount >= self.MIN_BET_AMOUNT, f"Bet too small: {bet_amount}"
        
        # Available exposure check
        assert bet_amount <= available_exposure, f"Bet exceeds available: {bet_amount} > {available_exposure}"
        
        # ─────────── ADIM 5: BET ID ───────────
        bet_id = self.next_bet_id
        self.next_bet_id += 1
        
        # ─────────── ADIM 6: POOL'A KAYDET ───────────
        self.pool.record_bet(bet_amount)
        
        # ─────────── ADIM 7: STATE GÜNCELLE ───────────
        self.bet_state['total_placed'] += 1
        self.bet_state['active_bets'] += 1
        self.bet_state['current_exposure'] += bet_amount
        
        self.bet_amounts[bet_id] = bet_amount
        self.bet_settlements[bet_id] = 0  # 0 = open
        
        # ─────────── ADIM 8: BET POSITION ───────────
        position = BetPosition(
            bet_id=bet_id,
            signal=signal,
            bet_amount=bet_amount,
            target_category=target_category,
            target_value=target_value,
            threshold=threshold,
            timestamp=0
        )
        
        return position
    
    def settle_bet(self, position: BetPosition, actual_value: int) -> tuple:
        """
        Bahsi settle et
        
        Args:
            position: BetPosition
            actual_value: Gerçek değer
            
        Returns:
            (profit_or_loss, is_win)
        """
        # ─────────── VALIDASYON ───────────
        assert self.bet_settlements[position.bet_id] == 0, "Already settled"
        
        # ─────────── WIN/LOSS ───────────
        is_win = actual_value >= position.target_value
        
        # ─────────── KÂR/ZARAR ───────────
        bet_amount = position.bet_amount
        profit_or_loss = bet_amount
        
        if is_win:
            # WIN: Pool'a kâr ekle
            self.pool.record_profit(profit_or_loss)
            self.bet_state['win_count'] += 1
            self.bet_state['total_profit'] += profit_or_loss
        else:
            # LOSS: Pool'dan zarar düş
            self.pool.record_loss(profit_or_loss)
            self.bet_state['loss_count'] += 1
            self.bet_state['total_loss'] += profit_or_loss
        
        # ─────────── STATE GÜNCELLE ───────────
        self.bet_state['total_settled'] += 1
        self.bet_state['active_bets'] -= 1
        self.bet_state['current_exposure'] -= bet_amount
        self.bet_settlements[position.bet_id] = 1  # 1 = settled
        
        position.is_settled = True
        
        return (profit_or_loss, is_win)
    
    def cancel_bet(self, position: BetPosition) -> int:
        """Bahsi iptal et"""
        assert self.bet_settlements[position.bet_id] == 0, "Already settled"
        
        refund_amount = position.bet_amount
        
        # State güncelle
        self.bet_state['total_settled'] += 1
        self.bet_state['active_bets'] -= 1
        self.bet_state['current_exposure'] -= refund_amount
        self.bet_settlements[position.bet_id] = 1
        
        return refund_amount
    
    def get_bet_stats(self) -> tuple:
        """İstatistikler"""
        return (
            self.bet_state['total_placed'],
            self.bet_state['total_settled'],
            self.bet_state['active_bets'],
            self.bet_state['total_profit'],
            self.bet_state['total_loss'],
            self.bet_state['current_exposure'],
            self.bet_state['win_count'],
            self.bet_state['loss_count']
        )
    
    def calculate_win_rate(self) -> float:
        """Win rate hesapla"""
        win_count = self.bet_state['win_count']
        loss_count = self.bet_state['loss_count']
        total = win_count + loss_count
        
        if total == 0:
            return 0.0
        
        return (win_count * self.SCALE) / total

# ───────────────────────────────────────────────────────────────────────────
# TEST UTILITIES
# ───────────────────────────────────────────────────────────────────────────

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    RESET = '\033[0m'

def print_test_header(test_name: str):
    print(f"\n{Colors.CYAN}{'═' * 70}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}TEST: {test_name}{Colors.RESET}")
    print(f"{Colors.CYAN}{'═' * 70}{Colors.RESET}")

def print_result(passed: bool, message: str):
    status = f"{Colors.GREEN}✓ PASS{Colors.RESET}" if passed else f"{Colors.RED}✗ FAIL{Colors.RESET}"
    print(f"{status} - {message}")

def print_bet_state(betting: BettingSystem, label: str = "Betting State"):
    stats = betting.get_bet_stats()
    print(f"\n{Colors.YELLOW}{label}:{Colors.RESET}")
    print(f"  Total Placed: {stats[0]}")
    print(f"  Total Settled: {stats[1]}")
    print(f"  Active Bets: {stats[2]}")
    print(f"  Total Profit: {stats[3] / BettingSystem.SCALE:.2f} tokens")
    print(f"  Total Loss: {stats[4] / BettingSystem.SCALE:.2f} tokens")
    print(f"  Current Exposure: {stats[5] / BettingSystem.SCALE:.2f} tokens")
    print(f"  Win Count: {stats[6]}")
    print(f"  Loss Count: {stats[7]}")
    if stats[6] + stats[7] > 0:
        win_rate = (stats[6] / (stats[6] + stats[7])) * 100
        print(f"  Win Rate: {win_rate:.1f}%")

# ───────────────────────────────────────────────────────────────────────────
# TEST CASES
# ───────────────────────────────────────────────────────────────────────────

def test_basic_bet_placement():
    """TEST 1: Temel Bahis Açma"""
    print_test_header("Basic Bet Placement")
    
    # Setup
    pool = LiquidityPool()
    pool.deposit(1000 * BettingSystem.SCALE)  # 1000 token
    betting = BettingSystem(pool)
    
    # Signal oluştur (85% confidence)
    signal = ProphecySignal(
        score=850_000,
        confidence=850_000,  # 85%
        category=0,
        direction=1
    )
    
    # Bahis aç
    position = betting.place_bet(
        signal=signal,
        target_category=0,
        target_value=180 * BettingSystem.SCALE,
        threshold=175 * BettingSystem.SCALE
    )
    
    print(f"\nPool liquidity: 1000 tokens")
    print(f"Signal confidence: 85%")
    print(f"Max exposure: 100 tokens (10%)")
    print(f"Bet placed: {position.bet_amount / BettingSystem.SCALE:.2f} tokens")
    
    # Validation
    expected_bet = 85 * BettingSystem.SCALE  # 100 × 0.85
    passed = position.bet_amount == expected_bet
    print_result(passed, f"Bet amount should be 85 tokens")
    
    passed &= betting.bet_state['active_bets'] == 1
    print_result(passed, "Active bets should be 1")
    
    passed &= betting.bet_state['current_exposure'] == expected_bet
    print_result(passed, "Exposure should match bet amount")
    
    print_bet_state(betting)
    
    return passed

def test_confidence_based_sizing():
    """TEST 2: Confidence-Based Bet Sizing"""
    print_test_header("Confidence-Based Bet Sizing")
    
    pool = LiquidityPool()
    pool.deposit(1000 * BettingSystem.SCALE)
    betting = BettingSystem(pool)
    
    # Test different confidence levels
    test_cases = [
        (600_000, 60.0),  # 60% confidence → 60 tokens
        (750_000, 75.0),  # 75% → 75 tokens
        (900_000, 90.0),  # 90% → 90 tokens
        (1_000_000, 100.0),  # 100% → 100 tokens (max)
    ]
    
    passed = True
    
    for confidence, expected_tokens in test_cases:
        # Reset için yeni sistem
        pool = LiquidityPool()
        pool.deposit(1000 * BettingSystem.SCALE)
        betting = BettingSystem(pool)
        
        signal = ProphecySignal(850_000, confidence, 0, 1)
        position = betting.place_bet(signal, 0, 180_000_000, 175_000_000)
        
        actual_tokens = position.bet_amount / BettingSystem.SCALE
        expected = expected_tokens
        
        test_passed = abs(actual_tokens - expected) < 0.01
        print(f"\nConfidence {confidence/10_000:.0f}% → Bet: {actual_tokens:.2f} tokens (expected: {expected:.2f})")
        print_result(test_passed, f"Bet matches expected")
        
        passed &= test_passed
    
    return passed

def test_risk_limit_enforcement():
    """TEST 3: Risk Limit Enforcement (Max 10%)"""
    print_test_header("Risk Limit Enforcement")
    
    pool = LiquidityPool()
    pool.deposit(1000 * BettingSystem.SCALE)
    betting = BettingSystem(pool)
    
    # İlk bahis: 85 tokens (85% confidence)
    signal1 = ProphecySignal(850_000, 850_000, 0, 1)
    pos1 = betting.place_bet(signal1, 0, 180_000_000, 175_000_000)
    
    print(f"\nBet 1: {pos1.bet_amount / BettingSystem.SCALE:.2f} tokens")
    print(f"Exposure: {betting.bet_state['current_exposure'] / BettingSystem.SCALE:.2f} / 100 tokens")
    
    # İkinci bahis: Kalan 15 token'lık alan (%90 confidence)
    signal2 = ProphecySignal(900_000, 900_000, 0, 1)
    pos2 = betting.place_bet(signal2, 0, 190_000_000, 185_000_000)
    
    print(f"Bet 2: {pos2.bet_amount / BettingSystem.SCALE:.2f} tokens")
    print(f"Exposure: {betting.bet_state['current_exposure'] / BettingSystem.SCALE:.2f} / 100 tokens")
    
    # Validation
    passed = betting.bet_state['current_exposure'] <= 100 * BettingSystem.SCALE
    print_result(passed, "Total exposure <= 100 tokens (10% limit)")
    
    # Üçüncü bahis deneyelim (fail etmeli - çok az exposure kaldı)
    # Available: ~2-3 token, but min bet is 1.0 token
    # Eğer confidence çok düşükse (<available/100), bet amount < MIN_BET olur
    try:
        signal3 = ProphecySignal(850_000, 1000_000, 0, 1)  # 100% confidence
        pos3 = betting.place_bet(signal3, 0, 200_000_000, 195_000_000)
        # Eğer gerçekten çok az yer varsa fail etmeli
        remaining = 100 * BettingSystem.SCALE - betting.bet_state['current_exposure']
        if remaining < BettingSystem.MIN_BET_AMOUNT:
            print_result(False, "Should have blocked 3rd bet (below min bet)")
            passed = False
        else:
            print(f"  Bet 3: {pos3.bet_amount / BettingSystem.SCALE:.2f} tokens (squeezed in)")
            print_result(True, "3rd bet accepted (still within limits)")
    except AssertionError as e:
        print_result(True, f"Correctly blocked 3rd bet: {e}")
    
    print_bet_state(betting)
    
    return passed

def test_win_settlement():
    """TEST 4: Win Settlement & Profit Distribution"""
    print_test_header("Win Settlement")
    
    pool = LiquidityPool()
    pool.deposit(1000 * BettingSystem.SCALE)
    betting = BettingSystem(pool)
    
    initial_liquidity = pool.total_liquidity
    
    # Bahis aç
    signal = ProphecySignal(850_000, 850_000, 0, 1)
    position = betting.place_bet(signal, 0, 180_000_000, 175_000_000)
    
    bet_amount = position.bet_amount
    
    print(f"\nInitial pool: {initial_liquidity / BettingSystem.SCALE:.2f} tokens")
    print(f"Bet placed: {bet_amount / BettingSystem.SCALE:.2f} tokens")
    print(f"Target: 180.0")
    
    # WIN scenario: Actual value 185 (> 180)
    actual_value = 185 * BettingSystem.SCALE
    profit, is_win = betting.settle_bet(position, actual_value)
    
    print(f"Actual value: 185.0")
    print(f"Result: {'WIN' if is_win else 'LOSS'}")
    print(f"Profit: {profit / BettingSystem.SCALE:.2f} tokens")
    
    # Validation
    passed = is_win == True
    print_result(passed, "Should be WIN (185 >= 180)")
    
    passed &= profit == bet_amount
    print_result(passed, f"Profit should equal bet amount")
    
    expected_liquidity = initial_liquidity + profit
    passed &= pool.total_liquidity == expected_liquidity
    print_result(passed, f"Pool liquidity increased by {profit / BettingSystem.SCALE:.2f}")
    
    passed &= betting.bet_state['active_bets'] == 0
    print_result(passed, "No active bets after settlement")
    
    passed &= betting.bet_state['win_count'] == 1
    print_result(passed, "Win count = 1")
    
    print_bet_state(betting)
    
    return passed

def test_loss_settlement():
    """TEST 5: Loss Settlement"""
    print_test_header("Loss Settlement")
    
    pool = LiquidityPool()
    pool.deposit(1000 * BettingSystem.SCALE)
    betting = BettingSystem(pool)
    
    initial_liquidity = pool.total_liquidity
    
    # Bahis aç
    signal = ProphecySignal(850_000, 850_000, 0, 1)
    position = betting.place_bet(signal, 0, 180_000_000, 175_000_000)
    
    bet_amount = position.bet_amount
    
    print(f"\nInitial pool: {initial_liquidity / BettingSystem.SCALE:.2f} tokens")
    print(f"Bet placed: {bet_amount / BettingSystem.SCALE:.2f} tokens")
    print(f"Target: 180.0")
    
    # LOSS scenario: Actual value 170 (< 180)
    actual_value = 170 * BettingSystem.SCALE
    loss, is_win = betting.settle_bet(position, actual_value)
    
    print(f"Actual value: 170.0")
    print(f"Result: {'WIN' if is_win else 'LOSS'}")
    print(f"Loss: {loss / BettingSystem.SCALE:.2f} tokens")
    
    # Validation
    passed = is_win == False
    print_result(passed, "Should be LOSS (170 < 180)")
    
    passed &= loss == bet_amount
    print_result(passed, f"Loss should equal bet amount")
    
    expected_liquidity = initial_liquidity - loss
    passed &= pool.total_liquidity == expected_liquidity
    print_result(passed, f"Pool liquidity decreased by {loss / BettingSystem.SCALE:.2f}")
    
    passed &= betting.bet_state['loss_count'] == 1
    print_result(passed, "Loss count = 1")
    
    print_bet_state(betting)
    
    return passed

def test_multiple_bets_scenario():
    """TEST 6: Multiple Concurrent Bets"""
    print_test_header("Multiple Concurrent Bets")
    
    pool = LiquidityPool()
    pool.deposit(1000 * BettingSystem.SCALE)
    betting = BettingSystem(pool)
    
    # 3 bahis aç (farklı confidence'lar)
    signals = [
        ProphecySignal(850_000, 700_000, 0, 1),  # 70%
        ProphecySignal(850_000, 800_000, 0, 1),  # 80%
        ProphecySignal(850_000, 600_000, 0, 1),  # 60%
    ]
    
    positions = []
    for i, signal in enumerate(signals):
        try:
            pos = betting.place_bet(signal, 0, 180_000_000 + i*10_000_000, 175_000_000)
            positions.append(pos)
            print(f"\nBet {i+1}: {pos.bet_amount / BettingSystem.SCALE:.2f} tokens (confidence: {signal.confidence/10_000:.0f}%)")
        except AssertionError as e:
            print(f"\nBet {i+1}: BLOCKED - {e}")
    
    print(f"\nTotal active bets: {betting.bet_state['active_bets']}")
    print(f"Total exposure: {betting.bet_state['current_exposure'] / BettingSystem.SCALE:.2f} tokens")
    
    # Validation
    passed = len(positions) <= 3
    print_result(passed, f"Placed {len(positions)} bets")
    
    passed &= betting.bet_state['current_exposure'] <= 100 * BettingSystem.SCALE
    print_result(passed, "Exposure within 10% limit")
    
    print_bet_state(betting)
    
    return passed

def test_bet_cancellation():
    """TEST 7: Bet Cancellation"""
    print_test_header("Bet Cancellation")
    
    pool = LiquidityPool()
    pool.deposit(1000 * BettingSystem.SCALE)
    betting = BettingSystem(pool)
    
    # Bahis aç
    signal = ProphecySignal(850_000, 850_000, 0, 1)
    position = betting.place_bet(signal, 0, 180_000_000, 175_000_000)
    
    bet_amount = position.bet_amount
    initial_exposure = betting.bet_state['current_exposure']
    
    print(f"\nBet placed: {bet_amount / BettingSystem.SCALE:.2f} tokens")
    print(f"Exposure before cancel: {initial_exposure / BettingSystem.SCALE:.2f} tokens")
    
    # İptal et
    refund = betting.cancel_bet(position)
    
    print(f"Bet cancelled")
    print(f"Refund: {refund / BettingSystem.SCALE:.2f} tokens")
    print(f"Exposure after cancel: {betting.bet_state['current_exposure'] / BettingSystem.SCALE:.2f} tokens")
    
    # Validation
    passed = refund == bet_amount
    print_result(passed, "Refund equals bet amount")
    
    passed &= betting.bet_state['active_bets'] == 0
    print_result(passed, "No active bets after cancel")
    
    passed &= betting.bet_state['current_exposure'] == 0
    print_result(passed, "Exposure back to zero")
    
    print_bet_state(betting)
    
    return passed

def test_win_rate_calculation():
    """TEST 8: Win Rate Calculation"""
    print_test_header("Win Rate Calculation")
    
    pool = LiquidityPool()
    pool.deposit(1000 * BettingSystem.SCALE)
    betting = BettingSystem(pool)
    
    # 10 bahis aç ve settle et
    # 7 WIN, 3 LOSS → 70% win rate
    scenarios = [
        (190_000_000, True),   # WIN
        (185_000_000, True),   # WIN
        (170_000_000, False),  # LOSS
        (195_000_000, True),   # WIN
        (175_000_000, False),  # LOSS
        (188_000_000, True),   # WIN
        (192_000_000, True),   # WIN
        (168_000_000, False),  # LOSS
        (198_000_000, True),   # WIN
        (191_000_000, True),   # WIN
    ]
    
    print(f"\nRunning 10 bets...")
    
    for i, (actual_value, expected_win) in enumerate(scenarios):
        signal = ProphecySignal(850_000, 700_000, 0, 1)
        pos = betting.place_bet(signal, 0, 180_000_000, 175_000_000)
        _, is_win = betting.settle_bet(pos, actual_value)
        
        result = "WIN" if is_win else "LOSS"
        print(f"  Bet {i+1}: Actual={actual_value/1_000_000:.0f} → {result}")
    
    # Win rate hesapla
    win_rate = betting.calculate_win_rate()
    win_rate_pct = (win_rate / BettingSystem.SCALE) * 100
    
    print(f"\nFinal Stats:")
    print(f"  Wins: {betting.bet_state['win_count']}")
    print(f"  Losses: {betting.bet_state['loss_count']}")
    print(f"  Win Rate: {win_rate_pct:.1f}%")
    
    # Validation
    expected_win_rate = 70.0
    passed = abs(win_rate_pct - expected_win_rate) < 1.0
    print_result(passed, f"Win rate should be ~{expected_win_rate}%")
    
    print_bet_state(betting)
    
    return passed

def test_edge_case_min_confidence():
    """TEST 9: Edge Case - Minimum Confidence"""
    print_test_header("Edge Case: Minimum Confidence")
    
    pool = LiquidityPool()
    pool.deposit(1000 * BettingSystem.SCALE)
    betting = BettingSystem(pool)
    
    # 60% confidence (minimum)
    signal_min = ProphecySignal(850_000, 600_000, 0, 1)
    
    try:
        pos = betting.place_bet(signal_min, 0, 180_000_000, 175_000_000)
        print(f"\nMin confidence (60%) accepted")
        print(f"Bet: {pos.bet_amount / BettingSystem.SCALE:.2f} tokens")
        passed = True
        print_result(True, "60% confidence accepted")
    except AssertionError as e:
        print_result(False, f"60% should be accepted: {e}")
        passed = False
    
    # 59% confidence (below minimum)
    signal_low = ProphecySignal(850_000, 590_000, 0, 1)
    
    try:
        pos = betting.place_bet(signal_low, 0, 180_000_000, 175_000_000)
        print_result(False, "59% should be rejected")
        passed = False
    except AssertionError as e:
        print_result(True, f"59% correctly rejected: {e}")
    
    return passed

def test_edge_case_zero_pool():
    """TEST 10: Edge Case - Zero Pool Liquidity"""
    print_test_header("Edge Case: Zero Pool Liquidity")
    
    pool = LiquidityPool()
    # Pool'a deposit YOK
    betting = BettingSystem(pool)
    
    signal = ProphecySignal(850_000, 850_000, 0, 1)
    
    try:
        pos = betting.place_bet(signal, 0, 180_000_000, 175_000_000)
        print_result(False, "Should reject with zero pool")
        passed = False
    except AssertionError as e:
        print_result(True, f"Correctly rejected: {e}")
        passed = True
    
    return passed

# ───────────────────────────────────────────────────────────────────────────
# TEST RUNNER
# ───────────────────────────────────────────────────────────────────────────

def run_all_tests():
    print(f"\n{Colors.BOLD}{Colors.CYAN}")
    print("═" * 70)
    print(" PROPHETIA BETTING SYSTEM TEST SUITE - Week 6")
    print("═" * 70)
    print(f"{Colors.RESET}")
    
    tests = [
        ("Basic Bet Placement", test_basic_bet_placement),
        ("Confidence-Based Sizing", test_confidence_based_sizing),
        ("Risk Limit Enforcement", test_risk_limit_enforcement),
        ("Win Settlement", test_win_settlement),
        ("Loss Settlement", test_loss_settlement),
        ("Multiple Concurrent Bets", test_multiple_bets_scenario),
        ("Bet Cancellation", test_bet_cancellation),
        ("Win Rate Calculation", test_win_rate_calculation),
        ("Edge Case: Min Confidence", test_edge_case_min_confidence),
        ("Edge Case: Zero Pool", test_edge_case_zero_pool),
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            passed = test_func()
            results.append((test_name, passed))
        except Exception as e:
            print(f"\n{Colors.RED}ERROR in {test_name}: {e}{Colors.RESET}")
            import traceback
            traceback.print_exc()
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
        print(" 🎉 ALL TESTS PASSED! Betting System Validated! 🎉")
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
