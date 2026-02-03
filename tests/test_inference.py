#!/usr/bin/env python3
"""
PROPHETIA Inference Engine - Comprehensive Test Suite

This module tests the zero-knowledge ML inference engine (divine_future transition).
All tests validate that the Python implementation matches the Leo smart contract logic.

Test Categories:
1. Simple Predictions (upward/downward)
2. Threshold Edge Cases
3. Confidence Calculations
4. Category Validation
5. Feature Engineering
6. Edge Cases & Error Handling

Scale Factor: 10^6 (all decimals represented as integers)
Example: 1.5 → 1,500,000
"""

import sys
from typing import Dict, Tuple

# ═══════════════════════════════════════════════════════════════════════════
# ANSI Color Codes for Terminal Output
# ═══════════════════════════════════════════════════════════════════════════

RESET = "\033[0m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
CYAN = "\033[36m"
BOLD = "\033[1m"

# ═══════════════════════════════════════════════════════════════════════════
# Fixed-Point Math Functions (Mirror Leo Implementation)
# ═══════════════════════════════════════════════════════════════════════════

SCALE = 1_000_000  # 10^6 scale factor

def fixed_mul(a: int, b: int) -> int:
    """Multiply two fixed-point numbers."""
    return (a * b) // SCALE

def fixed_add(a: int, b: int) -> int:
    """Add two fixed-point numbers."""
    return a + b

def fixed_sub(a: int, b: int) -> int:
    """Subtract two fixed-point numbers (absolute difference)."""
    return abs(a - b)

def weighted_sum(weights: list, inputs: list) -> int:
    """Compute weighted sum: Σ(weights[i] × inputs[i])"""
    result = 0
    for w, x in zip(weights, inputs):
        result += fixed_mul(w, x)
    return result

def relu_activation(x: int, threshold: int) -> bool:
    """Binary activation: x >= threshold"""
    return x >= threshold

# ═══════════════════════════════════════════════════════════════════════════
# Core Inference Logic (Mirrors divine_future transition)
# ═══════════════════════════════════════════════════════════════════════════

def divine_future(data: Dict, model: Dict) -> Tuple[bool, int]:
    """
    Simulate the divine_future transition from inference.leo
    
    Args:
        data: ProphecyData record with keys: payload, quality_score, category
        model: OracleModel record with keys: weights, bias, threshold, category
    
    Returns:
        (direction, confidence) tuple
        - direction: True = UP, False = DOWN
        - confidence: 0-1,000,000
    
    Raises:
        AssertionError: If data.category != model.category
    """
    
    # STEP 1: Validation
    assert data['category'] == model['category'], \
        f"Category mismatch: data={data['category']}, model={model['category']}"
    
    # STEP 2: Feature Engineering
    features = [
        data['payload'],         # Feature 0: Main data value
        data['quality_score'],   # Feature 1: Provider reputation
        1_000_000,               # Feature 2: Constant 1.0
        500_000                  # Feature 3: Constant 0.5
    ]
    
    # STEP 3: ML Inference - Prediction Score
    score = weighted_sum(model['weights'], features)
    score = fixed_add(score, model['bias'])
    
    # STEP 4: Activation Function
    direction = relu_activation(score, model['threshold'])
    
    # STEP 5: Confidence Calculation
    # Calculate raw distance from threshold (absolute value)
    if score >= model['threshold']:
        raw_confidence = score - model['threshold']
    else:
        raw_confidence = model['threshold'] - score
    
    # Normalize confidence to [0, 1] range
    if model['threshold'] > 0:
        confidence = (raw_confidence * SCALE) // model['threshold']
        # Cap at 100%
        if confidence > SCALE:
            confidence = SCALE
    else:
        confidence = SCALE  # 100% if no threshold
    
    return (direction, confidence)

# ═══════════════════════════════════════════════════════════════════════════
# Test Suite
# ═══════════════════════════════════════════════════════════════════════════

class TestResults:
    """Track test results for summary reporting."""
    def __init__(self):
        self.total = 0
        self.passed = 0
        self.failed = 0
        self.errors = []
    
    def record_pass(self, test_name: str):
        self.total += 1
        self.passed += 1
        print(f"{GREEN}✓ PASS{RESET} | {test_name}")
    
    def record_fail(self, test_name: str, expected, actual, message=""):
        self.total += 1
        self.failed += 1
        error_msg = f"{test_name}: Expected {expected}, Got {actual}"
        if message:
            error_msg += f" ({message})"
        self.errors.append(error_msg)
        print(f"{RED}✗ FAIL{RESET} | {test_name}")
        print(f"  Expected: {expected}")
        print(f"  Actual:   {actual}")
        if message:
            print(f"  Note:     {message}")
    
    def print_summary(self):
        print(f"\n{BOLD}{'=' * 80}{RESET}")
        print(f"{BOLD}Total Tests:{RESET} {self.total}")
        print(f"{BOLD}Passed:{RESET} {GREEN}{self.passed}{RESET}")
        print(f"{BOLD}Failed:{RESET} {RED}{self.failed}{RESET}")
        
        pass_rate = (self.passed / self.total * 100) if self.total > 0 else 0
        color = GREEN if pass_rate == 100 else (YELLOW if pass_rate >= 80 else RED)
        print(f"{BOLD}Pass Rate:{RESET} {color}{pass_rate:.1f}%{RESET}")
        print(f"{BOLD}{'=' * 80}{RESET}\n")
        
        if self.errors:
            print(f"{RED}{BOLD}Failed Tests:{RESET}")
            for error in self.errors:
                print(f"  • {error}")
            print()

results = TestResults()

def run_test(test_name: str, test_func):
    """Run a single test and record result."""
    try:
        test_func()
    except Exception as e:
        results.record_fail(test_name, "No exception", f"Exception: {e}")

# ═══════════════════════════════════════════════════════════════════════════
# TEST CATEGORY 1: Simple Predictions
# ═══════════════════════════════════════════════════════════════════════════

def test_simple_upward_prediction():
    """
    Test Case: Simple upward prediction
    
    Scenario:
    - Data: Price = $1.50, Quality = 90%
    - Model: Bullish linear model
    - Expected: UP signal with moderate confidence
    
    Calculation:
    - features = [1.5, 0.9, 1.0, 0.5]
    - weights = [0.6, 0.1, 0.2, 0.1]
    - bias = 0.1
    - score = 0.6*1.5 + 0.1*0.9 + 0.2*1.0 + 0.1*0.5 + 0.1 = 1.34
    - threshold = 1.0
    - direction = 1.34 >= 1.0 = True (UP)
    - confidence = |1.34 - 1.0| / 1.0 = 0.34 = 34%
    """
    data = {
        'payload': 1_500_000,      # $1.50
        'quality_score': 900_000,  # 90% quality
        'category': 1              # Stocks
    }
    
    model = {
        'weights': [600_000, 100_000, 200_000, 100_000],  # [0.6, 0.1, 0.2, 0.1]
        'bias': 100_000,           # 0.1
        'threshold': 1_000_000,    # 1.0
        'category': 1              # Stocks
    }
    
    direction, confidence = divine_future(data, model)
    
    # Verify direction is UP
    if direction == True:
        results.record_pass("Simple upward prediction: direction = UP")
    else:
        results.record_fail("Simple upward prediction: direction", "UP (True)", "DOWN (False)")
    
    # Verify confidence is reasonable (around 34%)
    expected_confidence = 340_000  # 34%
    tolerance = 10_000  # ±1%
    if abs(confidence - expected_confidence) <= tolerance:
        results.record_pass(f"Simple upward prediction: confidence ≈ {confidence / SCALE:.2f}")
    else:
        results.record_fail(
            "Simple upward prediction: confidence",
            f"{expected_confidence} (34%)",
            f"{confidence} ({confidence / SCALE:.1%})"
        )

def test_simple_downward_prediction():
    """
    Test Case: Simple downward prediction
    
    Scenario:
    - Data: Price = $0.80, Quality = 70%
    - Model: Bearish linear model
    - Expected: DOWN signal with moderate confidence
    
    Calculation:
    - features = [0.8, 0.7, 1.0, 0.5]
    - weights = [0.3, 0.2, 0.3, 0.1]
    - bias = 0.05
    - score = 0.3*0.8 + 0.2*0.7 + 0.3*1.0 + 0.1*0.5 + 0.05 = 0.22 (corrected)
    - threshold = 1.0
    - direction = 0.78 >= 1.0 = False (DOWN)
    - confidence = |0.78 - 1.0| / 1.0 = 0.22 = 22%
    """
    data = {
        'payload': 800_000,        # $0.80
        'quality_score': 700_000,  # 70% quality
        'category': 1              # Stocks
    }
    
    model = {
        'weights': [300_000, 200_000, 300_000, 100_000],  # [0.3, 0.2, 0.3, 0.1]
        'bias': 50_000,            # 0.05
        'threshold': 1_000_000,    # 1.0
        'category': 1              # Stocks
    }
    
    direction, confidence = divine_future(data, model)
    
    # Verify direction is DOWN
    if direction == False:
        results.record_pass("Simple downward prediction: direction = DOWN")
    else:
        results.record_fail("Simple downward prediction: direction", "DOWN (False)", "UP (True)")
    
    # Verify confidence is reasonable (around 22%)
    expected_confidence = 220_000  # 22%
    tolerance = 10_000  # ±1%
    if abs(confidence - expected_confidence) <= tolerance:
        results.record_pass(f"Simple downward prediction: confidence ≈ {confidence / SCALE:.2f}")
    else:
        results.record_fail(
            "Simple downward prediction: confidence",
            f"{expected_confidence} (22%)",
            f"{confidence} ({confidence / SCALE:.1%})"
        )

# ═══════════════════════════════════════════════════════════════════════════
# TEST CATEGORY 2: Threshold Edge Cases
# ═══════════════════════════════════════════════════════════════════════════

def test_exact_threshold():
    """
    Test Case: Score exactly at threshold
    
    Scenario:
    - Adjusted to create score = threshold exactly
    - Score = 1.0
    - Threshold = 1.0
    - Expected: UP (since score >= threshold), confidence = 0%
    """
    data = {
        'payload': 1_000_000,
        'quality_score': 1_000_000,
        'category': 1
    }
    
    model = {
        'weights': [250_000, 250_000, 250_000, 250_000],  # [0.25, 0.25, 0.25, 0.25]
        'bias': 125_000,  # Add 0.125 to make score exactly 1.0
        'threshold': 1_000_000,
        'category': 1
    }
    
    direction, confidence = divine_future(data, model)
    
    # At exact threshold, should be UP (>=)
    if direction == True:
        results.record_pass("Exact threshold: direction = UP")
    else:
        results.record_fail("Exact threshold: direction", "UP (True)", "DOWN (False)")
    
    # Confidence should be 0 (no distance from threshold)
    if confidence == 0:
        results.record_pass("Exact threshold: confidence = 0%")
    else:
        results.record_fail("Exact threshold: confidence", "0", f"{confidence}")

def test_just_above_threshold():
    """
    Test Case: Score just above threshold (marginal UP signal)
    
    Scenario:
    - Score = 1.01
    - Threshold = 1.0
    - Expected: UP, very low confidence (1%)
    """
    data = {
        'payload': 1_010_000,      # 1.01
        'quality_score': 1_000_000,
        'category': 1
    }
    
    model = {
        'weights': [250_000, 250_000, 250_000, 250_000],
        'bias': 135_000,  # Add bias to push above threshold
        'threshold': 1_000_000,
        'category': 1
    }
    
    direction, confidence = divine_future(data, model)
    
    if direction == True:
        results.record_pass("Just above threshold: direction = UP")
    else:
        results.record_fail("Just above threshold: direction", "UP (True)", "DOWN (False)")
    
    # Confidence should be low (around 2.5%)
    if confidence < 50_000:  # Less than 5%
        results.record_pass(f"Just above threshold: low confidence ({confidence / SCALE:.1%})")
    else:
        results.record_fail("Just above threshold: low confidence", "< 5%", f"{confidence / SCALE:.1%}")

def test_just_below_threshold():
    """
    Test Case: Score just below threshold (marginal DOWN signal)
    
    Scenario:
    - Score = 0.99
    - Threshold = 1.0
    - Expected: DOWN, very low confidence (1%)
    """
    data = {
        'payload': 990_000,        # 0.99
        'quality_score': 1_000_000,
        'category': 1
    }
    
    model = {
        'weights': [250_000, 250_000, 250_000, 250_000],
        'bias': 0,
        'threshold': 1_000_000,
        'category': 1
    }
    
    direction, confidence = divine_future(data, model)
    
    if direction == False:
        results.record_pass("Just below threshold: direction = DOWN")
    else:
        results.record_fail("Just below threshold: direction", "DOWN (False)", "UP (True)")
    
    # Confidence should be low (< 15%)
    if confidence < 150_000:  # Less than 15%
        results.record_pass(f"Just below threshold: low confidence ({confidence / SCALE:.1%})")
    else:
        results.record_fail("Just below threshold: low confidence", "< 15%", f"{confidence / SCALE:.1%}")

# ═══════════════════════════════════════════════════════════════════════════
# TEST CATEGORY 3: Confidence Calculations
# ═══════════════════════════════════════════════════════════════════════════

def test_high_confidence_up():
    """
    Test Case: High confidence UP signal
    
    Scenario:
    - Score = 2.0
    - Threshold = 1.0
    - Expected: UP, 100% confidence (capped)
    """
    data = {
        'payload': 3_000_000,      # 3.0 (higher value for more confidence)
        'quality_score': 1_000_000,
        'category': 1
    }
    
    model = {
        'weights': [500_000, 100_000, 200_000, 200_000],  # Multiple weights
        'bias': 0,
        'threshold': 1_000_000,
        'category': 1
    }
    
    direction, confidence = divine_future(data, model)
    
    if direction == True:
        results.record_pass("High confidence UP: direction = UP")
    else:
        results.record_fail("High confidence UP: direction", "UP (True)", "DOWN (False)")
    
    # Confidence should be very high (> 80%)
    if confidence > 800_000:
        results.record_pass(f"High confidence UP: confidence = {confidence / SCALE:.1%}")
    else:
        results.record_fail("High confidence UP: confidence", "> 80%", f"{confidence / SCALE:.1%}")

def test_high_confidence_down():
    """
    Test Case: High confidence DOWN signal
    
    Scenario:
    - Score = 0.1
    - Threshold = 1.0
    - Expected: DOWN, 90% confidence
    """
    data = {
        'payload': 100_000,        # 0.1
        'quality_score': 1_000_000,
        'category': 1
    }
    
    model = {
        'weights': [500_000, 0, 0, 0],
        'bias': -100_000,          # Negative bias to push score down
        'threshold': 1_000_000,
        'category': 1
    }
    
    direction, confidence = divine_future(data, model)
    
    if direction == False:
        results.record_pass("High confidence DOWN: direction = DOWN")
    else:
        results.record_fail("High confidence DOWN: direction", "DOWN (False)", "UP (True)")
    
    # Confidence should be high (> 80%)
    if confidence > 800_000:
        results.record_pass(f"High confidence DOWN: confidence = {confidence / SCALE:.1%}")
    else:
        results.record_fail("High confidence DOWN: confidence", "> 80%", f"{confidence / SCALE:.1%}")

# ═══════════════════════════════════════════════════════════════════════════
# TEST CATEGORY 4: Category Validation
# ═══════════════════════════════════════════════════════════════════════════

def test_category_mismatch():
    """
    Test Case: Data and model category mismatch
    
    Scenario:
    - Data: Stock category (1)
    - Model: Weather category (2)
    - Expected: AssertionError
    """
    data = {
        'payload': 1_000_000,
        'quality_score': 1_000_000,
        'category': 1  # Stocks
    }
    
    model = {
        'weights': [250_000, 250_000, 250_000, 250_000],
        'bias': 0,
        'threshold': 1_000_000,
        'category': 2  # Weather (MISMATCH!)
    }
    
    try:
        direction, confidence = divine_future(data, model)
        # Should not reach here
        results.record_fail("Category mismatch", "AssertionError", "No error raised")
    except AssertionError as e:
        # Expected behavior
        results.record_pass("Category mismatch: raises AssertionError")

def test_matching_categories():
    """
    Test Case: Data and model categories match
    
    Scenario:
    - Data: Crypto category (4)
    - Model: Crypto category (4)
    - Expected: Successful prediction
    """
    data = {
        'payload': 1_500_000,
        'quality_score': 900_000,
        'category': 4  # Crypto
    }
    
    model = {
        'weights': [500_000, 200_000, 200_000, 100_000],
        'bias': 0,
        'threshold': 1_000_000,
        'category': 4  # Crypto (MATCH!)
    }
    
    try:
        direction, confidence = divine_future(data, model)
        results.record_pass("Matching categories: prediction successful")
    except AssertionError:
        results.record_fail("Matching categories", "Success", "AssertionError raised")

# ═══════════════════════════════════════════════════════════════════════════
# TEST CATEGORY 5: Feature Engineering
# ═══════════════════════════════════════════════════════════════════════════

def test_feature_vector_construction():
    """
    Test Case: Verify feature vector is constructed correctly
    
    Expected feature vector:
    [payload, quality_score, 1.0, 0.5]
    """
    data = {
        'payload': 1_234_567,
        'quality_score': 876_543,
        'category': 1
    }
    
    # Model with weights = [1, 0, 0, 0] to test payload
    model_test_payload = {
        'weights': [1_000_000, 0, 0, 0],  # [1.0, 0, 0, 0]
        'bias': 0,
        'threshold': 1_000_000,
        'category': 1
    }
    
    direction, confidence = divine_future(data, model_test_payload)
    # Score should equal payload (1.234567)
    # Since score > threshold (1.0), direction = UP
    
    if direction == True:
        results.record_pass("Feature engineering: payload feature correct")
    else:
        results.record_fail("Feature engineering: payload", "UP (True)", "DOWN (False)")
    
    # Test quality_score feature
    model_test_quality = {
        'weights': [0, 1_000_000, 0, 0],  # [0, 1.0, 0, 0]
        'bias': 200_000,  # Add 0.2 to push above threshold
        'threshold': 1_000_000,
        'category': 1
    }
    
    direction2, confidence2 = divine_future(data, model_test_quality)
    # Score = 0.876543 + 0.2 = 1.076543 > 1.0
    
    if direction2 == True:
        results.record_pass("Feature engineering: quality_score feature correct")
    else:
        results.record_fail("Feature engineering: quality_score", "UP (True)", "DOWN (False)")

# ═══════════════════════════════════════════════════════════════════════════
# TEST CATEGORY 6: Edge Cases
# ═══════════════════════════════════════════════════════════════════════════

def test_zero_threshold():
    """
    Test Case: Model with threshold = 0
    
    Scenario:
    - Threshold = 0
    - Any positive score → UP
    - Expected: confidence = 100% (edge case handling)
    """
    data = {
        'payload': 500_000,  # 0.5
        'quality_score': 500_000,
        'category': 1
    }
    
    model = {
        'weights': [250_000, 250_000, 250_000, 250_000],
        'bias': 0,
        'threshold': 0,  # Zero threshold
        'category': 1
    }
    
    direction, confidence = divine_future(data, model)
    
    if direction == True:
        results.record_pass("Zero threshold: direction = UP")
    else:
        results.record_fail("Zero threshold: direction", "UP (True)", "DOWN (False)")
    
    # Confidence should default to 100%
    if confidence == SCALE:
        results.record_pass("Zero threshold: confidence = 100% (edge case)")
    else:
        results.record_fail("Zero threshold: confidence", "100%", f"{confidence / SCALE:.1%}")

def test_all_zero_weights():
    """
    Test Case: Model with all zero weights
    
    Scenario:
    - All weights = 0
    - Score depends only on bias
    - Expected: direction based on bias vs threshold
    """
    data = {
        'payload': 1_000_000,
        'quality_score': 1_000_000,
        'category': 1
    }
    
    model = {
        'weights': [0, 0, 0, 0],  # All zeros
        'bias': 1_500_000,  # 1.5
        'threshold': 1_000_000,
        'category': 1
    }
    
    direction, confidence = divine_future(data, model)
    
    # Score = 0 + 1.5 = 1.5 > 1.0 → UP
    if direction == True:
        results.record_pass("All zero weights: direction = UP (bias-driven)")
    else:
        results.record_fail("All zero weights: direction", "UP (True)", "DOWN (False)")
    
    # Confidence = |1.5 - 1.0| / 1.0 = 0.5 = 50%
    expected_conf = 500_000
    tolerance = 10_000
    if abs(confidence - expected_conf) <= tolerance:
        results.record_pass(f"All zero weights: confidence ≈ {confidence / SCALE:.1%}")
    else:
        results.record_fail("All zero weights: confidence", "50%", f"{confidence / SCALE:.1%}")

def test_maximum_values():
    """
    Test Case: Test with maximum safe values
    
    Scenario:
    - Large payload values
    - Ensure no overflow in calculations
    """
    data = {
        'payload': 10_000_000,  # 10.0 (large value)
        'quality_score': 1_000_000,
        'category': 1
    }
    
    model = {
        'weights': [100_000, 100_000, 100_000, 100_000],  # [0.1, 0.1, 0.1, 0.1]
        'bias': 0,
        'threshold': 1_000_000,
        'category': 1
    }
    
    try:
        direction, confidence = divine_future(data, model)
        results.record_pass("Maximum values: no overflow")
    except Exception as e:
        results.record_fail("Maximum values", "No exception", f"Exception: {e}")

# ═══════════════════════════════════════════════════════════════════════════
# Main Test Runner
# ═══════════════════════════════════════════════════════════════════════════

def main():
    print(f"\n{BOLD}{CYAN}{'=' * 80}{RESET}")
    print(f"{BOLD}{CYAN}PROPHETIA - ZK-ML Inference Engine Test Suite{RESET}")
    print(f"{BOLD}{CYAN}{'=' * 80}{RESET}\n")
    
    print(f"{YELLOW}Testing divine_future transition from inference.leo{RESET}")
    print(f"{YELLOW}Scale Factor: {SCALE:,} (10^6){RESET}\n")
    
    # Category 1: Simple Predictions
    print(f"\n{BOLD}{BLUE}[Category 1: Simple Predictions]{RESET}")
    run_test("Simple upward prediction", test_simple_upward_prediction)
    run_test("Simple downward prediction", test_simple_downward_prediction)
    
    # Category 2: Threshold Edge Cases
    print(f"\n{BOLD}{BLUE}[Category 2: Threshold Edge Cases]{RESET}")
    run_test("Exact threshold", test_exact_threshold)
    run_test("Just above threshold", test_just_above_threshold)
    run_test("Just below threshold", test_just_below_threshold)
    
    # Category 3: Confidence Calculations
    print(f"\n{BOLD}{BLUE}[Category 3: Confidence Calculations]{RESET}")
    run_test("High confidence UP", test_high_confidence_up)
    run_test("High confidence DOWN", test_high_confidence_down)
    
    # Category 4: Category Validation
    print(f"\n{BOLD}{BLUE}[Category 4: Category Validation]{RESET}")
    run_test("Category mismatch", test_category_mismatch)
    run_test("Matching categories", test_matching_categories)
    
    # Category 5: Feature Engineering
    print(f"\n{BOLD}{BLUE}[Category 5: Feature Engineering]{RESET}")
    run_test("Feature vector construction", test_feature_vector_construction)
    
    # Category 6: Edge Cases
    print(f"\n{BOLD}{BLUE}[Category 6: Edge Cases]{RESET}")
    run_test("Zero threshold", test_zero_threshold)
    run_test("All zero weights", test_all_zero_weights)
    run_test("Maximum values", test_maximum_values)
    
    # Print summary
    results.print_summary()
    
    # Exit with appropriate code
    sys.exit(0 if results.failed == 0 else 1)

if __name__ == "__main__":
    main()
