"""
PROPHETIA Math Utilities - Test Suite (Week 2)
Comprehensive tests for fixed-point arithmetic functions

This test suite validates all mathematical operations in math_utils.leo
using Python to simulate the on-chain Leo computations.

Scale Factor: 10^6 (1.0 = 1,000,000)
"""

import sys
from typing import List, Tuple

# Constants matching Leo implementation
SCALE = 1_000_000
MAX_SAFE_VALUE = 18_446_744_073_709
U64_MAX = 18_446_744_073_709_551_615

# Color codes for terminal output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

# Test counter
tests_passed = 0
tests_failed = 0


def print_test(name: str, passed: bool, expected, actual, details: str = ""):
    """Pretty print test results"""
    global tests_passed, tests_failed
    
    if passed:
        tests_passed += 1
        status = f"{GREEN}✓ PASS{RESET}"
    else:
        tests_failed += 1
        status = f"{RED}✗ FAIL{RESET}"
    
    print(f"{status} | {name}")
    if not passed:
        print(f"  Expected: {expected}")
        print(f"  Actual:   {actual}")
        if details:
            print(f"  Details:  {details}")


# ============================================================================
# FUNCTION IMPLEMENTATIONS (matching Leo)
# ============================================================================

def to_fixed(value: int) -> int:
    """Convert integer to fixed-point representation"""
    assert value <= MAX_SAFE_VALUE, f"Overflow: {value} > {MAX_SAFE_VALUE}"
    return value * SCALE


def fixed_mul(a: int, b: int) -> int:
    """Multiply two fixed-point numbers"""
    # Simulate u128 intermediate calculation
    product = a * b
    result = product // SCALE
    assert result <= U64_MAX, f"Result overflow: {result}"
    return result


def fixed_div(a: int, b: int) -> int:
    """Divide two fixed-point numbers"""
    assert b > 0, "Division by zero"
    scaled_numerator = a * SCALE
    result = scaled_numerator // b
    assert result <= U64_MAX, f"Result overflow: {result}"
    return result


def fixed_add(a: int, b: int) -> int:
    """Add two fixed-point numbers"""
    result = a + b
    assert result <= U64_MAX, f"Addition overflow: {result}"
    return result


def fixed_sub(a: int, b: int) -> int:
    """Subtract two fixed-point numbers"""
    assert a >= b, f"Underflow: {a} < {b}"
    return a - b


def weighted_sum(weights: List[int], inputs: List[int]) -> int:
    """Compute weighted sum of 4 inputs"""
    assert len(weights) == 4 and len(inputs) == 4
    
    total = 0
    for w, inp in zip(weights, inputs):
        term = fixed_mul(w, inp)
        total += term
    
    assert total <= U64_MAX, f"Weighted sum overflow: {total}"
    return total


def relu_activation(x: int, threshold: int) -> bool:
    """ReLU activation function"""
    return x >= threshold


# ============================================================================
# TEST CASES
# ============================================================================

def test_to_fixed():
    """Test integer to fixed-point conversion"""
    print(f"\n{BLUE}=== Testing to_fixed() ==={RESET}")
    
    # Test 1: Convert 5 to fixed-point
    result = to_fixed(5)
    expected = 5_000_000
    print_test("to_fixed(5) = 5.0", result == expected, expected, result)
    
    # Test 2: Convert 0 to fixed-point
    result = to_fixed(0)
    expected = 0
    print_test("to_fixed(0) = 0.0", result == expected, expected, result)
    
    # Test 3: Convert 1000 to fixed-point
    result = to_fixed(1000)
    expected = 1_000_000_000
    print_test("to_fixed(1000) = 1000.0", result == expected, expected, result)
    
    # Test 4: Maximum safe value
    result = to_fixed(MAX_SAFE_VALUE)
    expected = MAX_SAFE_VALUE * SCALE
    print_test(f"to_fixed({MAX_SAFE_VALUE}) = max", result == expected, expected, result)


def test_fixed_mul():
    """Test fixed-point multiplication"""
    print(f"\n{BLUE}=== Testing fixed_mul() ==={RESET}")
    
    # Test 1: 0.5 * 0.5 = 0.25
    a, b = 500_000, 500_000
    result = fixed_mul(a, b)
    expected = 250_000
    print_test("0.5 * 0.5 = 0.25", result == expected, expected, result, 
               f"({a/SCALE} * {b/SCALE} = {result/SCALE})")
    
    # Test 2: 1.5 * 2.0 = 3.0
    a, b = 1_500_000, 2_000_000
    result = fixed_mul(a, b)
    expected = 3_000_000
    print_test("1.5 * 2.0 = 3.0", result == expected, expected, result,
               f"({a/SCALE} * {b/SCALE} = {result/SCALE})")
    
    # Test 3: 1.0 * 1.0 = 1.0
    a, b = 1_000_000, 1_000_000
    result = fixed_mul(a, b)
    expected = 1_000_000
    print_test("1.0 * 1.0 = 1.0", result == expected, expected, result)
    
    # Test 4: 2.5 * 4.0 = 10.0
    a, b = 2_500_000, 4_000_000
    result = fixed_mul(a, b)
    expected = 10_000_000
    print_test("2.5 * 4.0 = 10.0", result == expected, expected, result)
    
    # Test 5: 0.1 * 0.1 = 0.01
    a, b = 100_000, 100_000
    result = fixed_mul(a, b)
    expected = 10_000
    print_test("0.1 * 0.1 = 0.01", result == expected, expected, result)


def test_fixed_div():
    """Test fixed-point division"""
    print(f"\n{BLUE}=== Testing fixed_div() ==={RESET}")
    
    # Test 1: 3.0 / 2.0 = 1.5
    a, b = 3_000_000, 2_000_000
    result = fixed_div(a, b)
    expected = 1_500_000
    print_test("3.0 / 2.0 = 1.5", result == expected, expected, result,
               f"({a/SCALE} / {b/SCALE} = {result/SCALE})")
    
    # Test 2: 1.0 / 4.0 = 0.25
    a, b = 1_000_000, 4_000_000
    result = fixed_div(a, b)
    expected = 250_000
    print_test("1.0 / 4.0 = 0.25", result == expected, expected, result)
    
    # Test 3: 5.0 / 1.0 = 5.0
    a, b = 5_000_000, 1_000_000
    result = fixed_div(a, b)
    expected = 5_000_000
    print_test("5.0 / 1.0 = 5.0", result == expected, expected, result)
    
    # Test 4: 10.0 / 3.0 ≈ 3.333333
    a, b = 10_000_000, 3_000_000
    result = fixed_div(a, b)
    expected = 3_333_333  # Truncated
    print_test("10.0 / 3.0 ≈ 3.333333", result == expected, expected, result)
    
    # Test 5: Division by zero protection
    try:
        result = fixed_div(5_000_000, 0)
        print_test("Division by zero caught", False, "AssertionError", "No error")
    except AssertionError:
        print_test("Division by zero caught", True, "AssertionError", "AssertionError")


def test_fixed_add():
    """Test fixed-point addition"""
    print(f"\n{BLUE}=== Testing fixed_add() ==={RESET}")
    
    # Test 1: 1.5 + 2.5 = 4.0
    a, b = 1_500_000, 2_500_000
    result = fixed_add(a, b)
    expected = 4_000_000
    print_test("1.5 + 2.5 = 4.0", result == expected, expected, result)
    
    # Test 2: 1.0 + 1.0 = 2.0
    a, b = 1_000_000, 1_000_000
    result = fixed_add(a, b)
    expected = 2_000_000
    print_test("1.0 + 1.0 = 2.0", result == expected, expected, result)
    
    # Test 3: 0.25 + 0.75 = 1.0
    a, b = 250_000, 750_000
    result = fixed_add(a, b)
    expected = 1_000_000
    print_test("0.25 + 0.75 = 1.0", result == expected, expected, result)


def test_fixed_sub():
    """Test fixed-point subtraction"""
    print(f"\n{BLUE}=== Testing fixed_sub() ==={RESET}")
    
    # Test 1: 5.0 - 2.0 = 3.0
    a, b = 5_000_000, 2_000_000
    result = fixed_sub(a, b)
    expected = 3_000_000
    print_test("5.0 - 2.0 = 3.0", result == expected, expected, result)
    
    # Test 2: 1.0 - 0.5 = 0.5
    a, b = 1_000_000, 500_000
    result = fixed_sub(a, b)
    expected = 500_000
    print_test("1.0 - 0.5 = 0.5", result == expected, expected, result)
    
    # Test 3: 3.0 - 3.0 = 0.0
    a, b = 3_000_000, 3_000_000
    result = fixed_sub(a, b)
    expected = 0
    print_test("3.0 - 3.0 = 0.0", result == expected, expected, result)
    
    # Test 4: Underflow protection
    try:
        result = fixed_sub(2_000_000, 5_000_000)
        print_test("Underflow caught", False, "AssertionError", "No error")
    except AssertionError:
        print_test("Underflow caught", True, "AssertionError", "AssertionError")


def test_weighted_sum():
    """Test weighted sum (critical for ML)"""
    print(f"\n{BLUE}=== Testing weighted_sum() ==={RESET}")
    
    # Test 1: Linear model prediction
    # weights = [0.5, 0.3, 0.2, 0.1]
    # inputs  = [1.0, 2.0, 1.5, 0.5]
    # result  = 0.5*1.0 + 0.3*2.0 + 0.2*1.5 + 0.1*0.5 = 1.45
    weights = [500_000, 300_000, 200_000, 100_000]
    inputs = [1_000_000, 2_000_000, 1_500_000, 500_000]
    result = weighted_sum(weights, inputs)
    expected = 1_450_000
    print_test("Weighted sum: [0.5,0.3,0.2,0.1]·[1.0,2.0,1.5,0.5] = 1.45",
               result == expected, expected, result,
               f"Result: {result/SCALE}")
    
    # Test 2: Equal weights
    # weights = [0.25, 0.25, 0.25, 0.25]
    # inputs  = [1.0, 2.0, 3.0, 4.0]
    # result  = 0.25*1 + 0.25*2 + 0.25*3 + 0.25*4 = 2.5
    weights = [250_000, 250_000, 250_000, 250_000]
    inputs = [1_000_000, 2_000_000, 3_000_000, 4_000_000]
    result = weighted_sum(weights, inputs)
    expected = 2_500_000
    print_test("Equal weights: average of [1,2,3,4] = 2.5",
               result == expected, expected, result)
    
    # Test 3: Single dominant weight
    # weights = [1.0, 0.0, 0.0, 0.0]
    # inputs  = [5.0, 2.0, 3.0, 4.0]
    # result  = 1.0*5.0 = 5.0
    weights = [1_000_000, 0, 0, 0]
    inputs = [5_000_000, 2_000_000, 3_000_000, 4_000_000]
    result = weighted_sum(weights, inputs)
    expected = 5_000_000
    print_test("Single weight: only first term = 5.0",
               result == expected, expected, result)
    
    # Test 4: Real ML scenario
    # weights = [0.6, 0.3, 0.08, 0.02] (stock price prediction)
    # inputs  = [1.2, 0.98, 1.05, 1.1] (normalized features)
    # result  = 0.6*1.2 + 0.3*0.98 + 0.08*1.05 + 0.02*1.1
    #         = 0.72 + 0.294 + 0.084 + 0.022 = 1.12
    weights = [600_000, 300_000, 80_000, 20_000]
    inputs = [1_200_000, 980_000, 1_050_000, 1_100_000]
    result = weighted_sum(weights, inputs)
    expected = 1_120_000  # Fixed: actual calculation gives 1.12, not 1.13
    print_test("ML prediction: weighted features = 1.12",
               result == expected, expected, result)


def test_relu_activation():
    """Test ReLU activation function"""
    print(f"\n{BLUE}=== Testing relu_activation() ==={RESET}")
    
    # Test 1: Above threshold
    x, threshold = 1_500_000, 1_000_000
    result = relu_activation(x, threshold)
    expected = True
    print_test("1.5 >= 1.0 = True", result == expected, expected, result)
    
    # Test 2: Below threshold
    x, threshold = 500_000, 1_000_000
    result = relu_activation(x, threshold)
    expected = False
    print_test("0.5 >= 1.0 = False", result == expected, expected, result)
    
    # Test 3: Exactly at threshold
    x, threshold = 1_000_000, 1_000_000
    result = relu_activation(x, threshold)
    expected = True
    print_test("1.0 >= 1.0 = True", result == expected, expected, result)
    
    # Test 4: Classification boundary
    x, threshold = 750_000, 500_000
    result = relu_activation(x, threshold)
    expected = True
    print_test("0.75 >= 0.5 = True (positive class)", result == expected, expected, result)


def test_edge_cases():
    """Test edge cases and boundary conditions"""
    print(f"\n{BLUE}=== Testing Edge Cases ==={RESET}")
    
    # Test 1: Multiply by zero
    result = fixed_mul(5_000_000, 0)
    expected = 0
    print_test("5.0 * 0.0 = 0.0", result == expected, expected, result)
    
    # Test 2: Add zero
    result = fixed_add(3_000_000, 0)
    expected = 3_000_000
    print_test("3.0 + 0.0 = 3.0", result == expected, expected, result)
    
    # Test 3: Subtract zero
    result = fixed_sub(3_000_000, 0)
    expected = 3_000_000
    print_test("3.0 - 0.0 = 3.0", result == expected, expected, result)
    
    # Test 4: Very small number multiplication
    a, b = 1, 1  # 0.000001 * 0.000001
    result = fixed_mul(a, b)
    expected = 0  # Rounded down to zero
    print_test("0.000001 * 0.000001 ≈ 0", result == expected, expected, result)


def test_precision():
    """Test precision and rounding behavior"""
    print(f"\n{BLUE}=== Testing Precision ==={RESET}")
    
    # Test 1: Division precision
    # 1.0 / 3.0 = 0.333333... (should truncate to 0.333333)
    a, b = 1_000_000, 3_000_000
    result = fixed_div(a, b)
    expected_min = 333_333
    expected_max = 333_334
    passed = expected_min <= result <= expected_max
    print_test("1.0 / 3.0 ≈ 0.333333 (precision)", passed, 
               f"{expected_min}-{expected_max}", result,
               f"Actual: {result/SCALE:.6f}")
    
    # Test 2: Multiplication precision preservation
    # 1.234567 * 1.0 = 1.234567
    a, b = 1_234_567, 1_000_000
    result = fixed_mul(a, b)
    expected = 1_234_567
    print_test("1.234567 * 1.0 = 1.234567 (precision preserved)",
               result == expected, expected, result)


# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

def run_all_tests():
    """Run complete test suite"""
    print(f"\n{YELLOW}╔═══════════════════════════════════════════════════════╗{RESET}")
    print(f"{YELLOW}║  PROPHETIA Math Utilities - Test Suite (Week 2)      ║{RESET}")
    print(f"{YELLOW}║  Fixed-Point Arithmetic Validation                    ║{RESET}")
    print(f"{YELLOW}╚═══════════════════════════════════════════════════════╝{RESET}")
    
    # Run all test categories
    test_to_fixed()
    test_fixed_mul()
    test_fixed_div()
    test_fixed_add()
    test_fixed_sub()
    test_weighted_sum()
    test_relu_activation()
    test_edge_cases()
    test_precision()
    
    # Print summary
    total = tests_passed + tests_failed
    pass_rate = (tests_passed / total * 100) if total > 0 else 0
    
    print(f"\n{YELLOW}═══════════════════════════════════════════════════════{RESET}")
    print(f"{YELLOW}TEST SUMMARY{RESET}")
    print(f"  Total Tests:  {total}")
    print(f"  {GREEN}Passed:       {tests_passed}{RESET}")
    print(f"  {RED}Failed:       {tests_failed}{RESET}")
    print(f"  Pass Rate:    {pass_rate:.1f}%")
    print(f"{YELLOW}═══════════════════════════════════════════════════════{RESET}\n")
    
    # Exit with appropriate code
    sys.exit(0 if tests_failed == 0 else 1)


if __name__ == "__main__":
    run_all_tests()
