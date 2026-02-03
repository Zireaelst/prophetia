# PROPHETIA Mathematics Reference

> **Fixed-Point Arithmetic for Zero-Knowledge Machine Learning**

## Overview

This document provides a complete reference for all mathematical operations in PROPHETIA's fixed-point arithmetic system. All functions are implemented in `contracts/src/math_utils.leo` and validated with comprehensive tests.

---

## Table of Contents

1. [Fixed-Point System](#fixed-point-system)
2. [Core Functions](#core-functions)
3. [ML-Specific Functions](#ml-specific-functions)
4. [Legacy Utility Functions](#legacy-utility-functions)
5. [Usage Examples](#usage-examples)
6. [Testing](#testing)
7. [Performance & Gas Optimization](#performance--gas-optimization)

---

## Fixed-Point System

### Scaling Convention

**Scale Factor:** 10^6 (1,000,000)

All decimal numbers are represented as integers scaled by 10^6:

| Decimal | Fixed-Point | Representation |
|---------|-------------|----------------|
| 0.5 | 500,000 | `500000u64` |
| 1.0 | 1,000,000 | `1000000u64` |
| 1.5 | 1,500,000 | `1500000u64` |
| 2.0 | 2,000,000 | `2000000u64` |
| 3.14159 | 3,141,590 | `3141590u64` |
| 100.0 | 100,000,000 | `100000000u64` |

### Constants

```leo
const SCALE: u64 = 1000000u64;           // Scale factor (10^6)
const SCALE_U128: u128 = 1000000u128;    // Scale factor for u128
const MAX_SAFE_VALUE: u64 = 18446744073709u64;  // Max safe value before overflow
```

### Type Safety

- **Input values**: Always `u64` (scaled by 10^6)
- **Intermediate calculations**: Use `u128` to prevent overflow
- **Output values**: Cast back to `u64`

---

## Core Functions

### 1. to_fixed()

**Convert integer to fixed-point representation**

```leo
inline to_fixed(value: u64) -> u64
```

**Purpose:** Converts a whole number to fixed-point format by multiplying by SCALE.

**Parameters:**
- `value`: Integer to convert (max: 18,446,744)

**Returns:** Fixed-point representation (value × 10^6)

**Examples:**
```leo
to_fixed(5u64)      // Returns 5000000u64 (5.0)
to_fixed(0u64)      // Returns 0u64 (0.0)
to_fixed(1000u64)   // Returns 1000000000u64 (1000.0)
```

**Safety:**
- Checks for overflow: `assert(value <= MAX_SAFE_VALUE)`
- Maximum input: 18,446,744 (to prevent u64 overflow)

**Use Cases:**
- Converting integer constants to fixed-point
- Initializing model parameters
- Setting thresholds

---

### 2. fixed_mul()

**Multiply two fixed-point numbers**

```leo
inline fixed_mul(a: u64, b: u64) -> u64
```

**Formula:** `(a × b) / SCALE`

**Purpose:** Multiplies two scaled numbers while maintaining scale.

**Parameters:**
- `a`: First operand (scaled by 10^6)
- `b`: Second operand (scaled by 10^6)

**Returns:** Product (scaled by 10^6)

**Examples:**
```leo
fixed_mul(500000u64, 500000u64)      // 250000 (0.5 × 0.5 = 0.25)
fixed_mul(1500000u64, 2000000u64)    // 3000000 (1.5 × 2.0 = 3.0)
fixed_mul(1000000u64, 1000000u64)    // 1000000 (1.0 × 1.0 = 1.0)
fixed_mul(2500000u64, 4000000u64)    // 10000000 (2.5 × 4.0 = 10.0)
```

**Implementation Details:**
```leo
let a_wide: u128 = a as u128;         // Cast to u128 for safety
let b_wide: u128 = b as u128;
let product: u128 = a_wide * b_wide;  // Multiply in u128 space
let result: u128 = product / SCALE_U128;  // Descale
return result as u64;                 // Cast back to u64
```

**Why u128?** Multiplying two u64 values can exceed u64 max (2^64). Using u128 prevents overflow.

**Use Cases:**
- Feature weighting in ML models
- Probability calculations
- Scaling operations

---

### 3. fixed_div()

**Divide two fixed-point numbers**

```leo
inline fixed_div(a: u64, b: u64) -> u64
```

**Formula:** `(a × SCALE) / b`

**Purpose:** Divides two scaled numbers while maintaining scale.

**Parameters:**
- `a`: Numerator/dividend (scaled by 10^6)
- `b`: Denominator/divisor (scaled by 10^6)

**Returns:** Quotient (scaled by 10^6)

**Examples:**
```leo
fixed_div(3000000u64, 2000000u64)    // 1500000 (3.0 / 2.0 = 1.5)
fixed_div(1000000u64, 4000000u64)    // 250000 (1.0 / 4.0 = 0.25)
fixed_div(5000000u64, 1000000u64)    // 5000000 (5.0 / 1.0 = 5.0)
fixed_div(10000000u64, 3000000u64)   // 3333333 (10.0 / 3.0 ≈ 3.333333)
```

**Safety:**
- **CRITICAL:** `assert(b > 0u64)` - prevents division by zero
- Scales numerator before division to maintain precision

**Precision:** 
- Result truncates (rounds down) due to integer division
- Example: 10.0 / 3.0 = 3.333333... → 3.333333 (truncated)

**Use Cases:**
- Normalization
- Rate calculations
- Probability normalization

---

### 4. fixed_add()

**Add two fixed-point numbers**

```leo
inline fixed_add(a: u64, b: u64) -> u64
```

**Formula:** `a + b`

**Purpose:** Adds two scaled numbers (straightforward addition).

**Parameters:**
- `a`: First operand (scaled by 10^6)
- `b`: Second operand (scaled by 10^6)

**Returns:** Sum (scaled by 10^6)

**Examples:**
```leo
fixed_add(1500000u64, 2500000u64)    // 4000000 (1.5 + 2.5 = 4.0)
fixed_add(1000000u64, 1000000u64)    // 2000000 (1.0 + 1.0 = 2.0)
fixed_add(250000u64, 750000u64)      // 1000000 (0.25 + 0.75 = 1.0)
```

**Safety:**
- Uses u128 intermediate to prevent overflow
- Max result: ~18.4 quintillion (well within u64 range for typical use)

**Use Cases:**
- Accumulating predictions
- Summing probabilities
- Aggregating features

---

### 5. fixed_sub()

**Subtract two fixed-point numbers**

```leo
inline fixed_sub(a: u64, b: u64) -> u64
```

**Formula:** `a - b`

**Purpose:** Subtracts two scaled numbers.

**Parameters:**
- `a`: Minuend (value to subtract from)
- `b`: Subtrahend (value to subtract)

**Returns:** Difference (scaled by 10^6)

**Examples:**
```leo
fixed_sub(5000000u64, 2000000u64)    // 3000000 (5.0 - 2.0 = 3.0)
fixed_sub(1000000u64, 500000u64)     // 500000 (1.0 - 0.5 = 0.5)
fixed_sub(3000000u64, 3000000u64)    // 0 (3.0 - 3.0 = 0.0)
```

**Safety:**
- **CRITICAL:** `assert(a >= b)` - prevents underflow
- u64 cannot represent negative numbers

**Edge Case:**
- If you need negative results, restructure calculation
- Example: Instead of `(a - b)`, use `if a > b { a - b } else { b - a }`

**Use Cases:**
- Error calculation
- Difference computation
- Range calculations

---

## ML-Specific Functions

### 6. weighted_sum()

**Compute weighted sum of inputs (CORE ML OPERATION)**

```leo
inline weighted_sum(
    weights: [u64; 4],
    inputs: [u64; 4]
) -> u64
```

**Formula:** `Σ(weights[i] × inputs[i])` for i = 0 to 3

**Purpose:** Computes the weighted sum of features - the fundamental operation in linear models.

**Parameters:**
- `weights`: Array of 4 weight values [w₁, w₂, w₃, w₄] (scaled by 10^6)
- `inputs`: Array of 4 input features [x₁, x₂, x₃, x₄] (scaled by 10^6)

**Returns:** Weighted sum (scaled by 10^6)

**Mathematical Representation:**
```
result = w₁·x₁ + w₂·x₂ + w₃·x₃ + w₄·x₄
```

**Examples:**

**Example 1: Equal Weights**
```leo
let weights: [u64; 4] = [250000u64, 250000u64, 250000u64, 250000u64];  // [0.25, 0.25, 0.25, 0.25]
let inputs: [u64; 4] = [1000000u64, 2000000u64, 3000000u64, 4000000u64];  // [1.0, 2.0, 3.0, 4.0]
let result: u64 = weighted_sum(weights, inputs);
// Result: 0.25×1.0 + 0.25×2.0 + 0.25×3.0 + 0.25×4.0 = 2.5 = 2500000u64
```

**Example 2: Feature Importance**
```leo
let weights: [u64; 4] = [600000u64, 300000u64, 80000u64, 20000u64];  // [0.6, 0.3, 0.08, 0.02]
let inputs: [u64; 4] = [1200000u64, 980000u64, 1050000u64, 1100000u64];  // [1.2, 0.98, 1.05, 1.1]
let result: u64 = weighted_sum(weights, inputs);
// Result: 0.6×1.2 + 0.3×0.98 + 0.08×1.05 + 0.02×1.1 = 1.12 = 1120000u64
```

**Example 3: Prediction Model**
```leo
let weights: [u64; 4] = [500000u64, 300000u64, 200000u64, 100000u64];  // [0.5, 0.3, 0.2, 0.1]
let inputs: [u64; 4] = [1000000u64, 2000000u64, 1500000u64, 500000u64];  // [1.0, 2.0, 1.5, 0.5]
let result: u64 = weighted_sum(weights, inputs);
// Result: 0.5×1.0 + 0.3×2.0 + 0.2×1.5 + 0.1×0.5 = 1.45 = 1450000u64
```

**Implementation Details:**
```leo
let sum: u128 = 0u128;
let term0: u64 = fixed_mul(weights[0], inputs[0]);
sum += term0 as u128;
// ... repeat for all 4 terms ...
return sum as u64;
```

**Why Unrolled Loop?**
- Leo doesn't support runtime loops
- Unrolling reduces gas cost
- Fixed size (4 features) is optimal for ZK circuits

**Use Cases:**
- **Linear Regression:** y = w·x + b
- **Logistic Regression:** z = w·x + b, then σ(z)
- **Neural Network Layers:** Pre-activation weighted sum
- **Ensemble Predictions:** Weighted average of model outputs

---

### 7. relu_activation()

**ReLU activation function (threshold-based)**

```leo
inline relu_activation(x: u64, threshold: u64) -> bool
```

**Formula:** `f(x) = x >= threshold`

**Purpose:** Binary classification based on threshold.

**Parameters:**
- `x`: Input value (scaled by 10^6)
- `threshold`: Activation threshold (scaled by 10^6)

**Returns:** `true` if x ≥ threshold, `false` otherwise

**Examples:**
```leo
relu_activation(1500000u64, 1000000u64)   // true (1.5 >= 1.0)
relu_activation(500000u64, 1000000u64)    // false (0.5 < 1.0)
relu_activation(1000000u64, 1000000u64)   // true (1.0 >= 1.0)
relu_activation(750000u64, 500000u64)     // true (0.75 >= 0.5)
```

**Mathematical Context:**

Traditional ReLU: `f(x) = max(0, x)`
```
f(x) = { x  if x > 0
       { 0  if x ≤ 0
```

PROPHETIA Simplified ReLU (boolean output):
```
f(x, threshold) = { true   if x >= threshold
                  { false  if x < threshold
```

**Use Cases:**
- **Binary Classification:** Stock price up/down prediction
- **Signal Detection:** Threshold-based event triggers
- **Decision Boundaries:** Separating positive/negative classes
- **Neural Network Activation:** Simplified neuron output

**Example: Stock Prediction**
```leo
// Predict if stock price will rise
let prediction: u64 = weighted_sum(model_weights, features);
let will_rise: bool = relu_activation(prediction, 1000000u64);  // threshold = 1.0

if will_rise {
    // Take long position
} else {
    // Take short position
}
```

---

## Legacy Utility Functions

### weighted_average()

**Weighted average of up to 4 values**

```leo
function weighted_average(values: [u64; 4], weights: [u64; 4]) -> u64
```

**Use Case:** Ensemble model aggregation

### simple_average()

**Simple average of count values**

```leo
function simple_average(values: [u64; 4], count: u8) -> u64
```

### min_value() / max_value()

**Find minimum/maximum in array**

```leo
function min_value(values: [u64; 4], count: u8) -> u64
function max_value(values: [u64; 4], count: u8) -> u64
```

### clamp()

**Bound value to range**

```leo
function clamp(value: u64, min_bound: u64, max_bound: u64) -> u64
```

### percentage_change()

**Calculate percentage change**

```leo
function percentage_change(old_value: u64, new_value: u64) -> u64
```

### normalize()

**Normalize to 0-1 range**

```leo
function normalize(value: u64, min_val: u64, max_val: u64) -> u64
```

---

## Usage Examples

### Example 1: Linear Regression Prediction

```leo
// Model: price = 0.5×volume + 0.3×sentiment + 0.15×momentum + 0.05×volatility + 0.1

let weights: [u64; 4] = [500000u64, 300000u64, 150000u64, 50000u64];
let bias: u64 = 100000u64;  // 0.1

// Normalized input features
let volume: u64 = 1200000u64;      // 1.2
let sentiment: u64 = 850000u64;    // 0.85
let momentum: u64 = 1050000u64;    // 1.05
let volatility: u64 = 900000u64;   // 0.9

let features: [u64; 4] = [volume, sentiment, momentum, volatility];

// Calculate prediction
let prediction: u64 = weighted_sum(weights, features);
let final_prediction: u64 = fixed_add(prediction, bias);

// Result: 0.5×1.2 + 0.3×0.85 + 0.15×1.05 + 0.05×0.9 + 0.1 = 1.0025
```

### Example 2: Binary Classification

```leo
// Predict if stock will rise (1) or fall (0)

let prediction: u64 = weighted_sum(weights, features);
let threshold: u64 = 1000000u64;  // 1.0

let will_rise: bool = relu_activation(prediction, threshold);

if will_rise {
    // Buy signal
    return 1u8;
} else {
    // Sell signal
    return 0u8;
}
```

### Example 3: Ensemble Prediction

```leo
// Combine predictions from 3 models with confidence weighting

let pred1: u64 = 1200000u64;  // Model 1: 1.2
let pred2: u64 = 1150000u64;  // Model 2: 1.15
let pred3: u64 = 1180000u64;  // Model 3: 1.18

let conf1: u64 = 900000u64;   // Confidence: 0.9
let conf2: u64 = 850000u64;   // Confidence: 0.85
let conf3: u64 = 880000u64;   // Confidence: 0.88

// Use weighted_sum for ensemble
let predictions: [u64; 4] = [pred1, pred2, pred3, 0u64];
let confidences: [u64; 4] = [conf1, conf2, conf3, 0u64];

let ensemble: u64 = weighted_sum(confidences, predictions);

// Normalize by total confidence
let total_conf: u64 = fixed_add(fixed_add(conf1, conf2), conf3);
let final_pred: u64 = fixed_div(ensemble, total_conf);
```

---

## Testing

### Running Tests

```bash
# Python test suite (35 comprehensive tests)
cd tests
python3 test_math_utils.py
```

### Test Coverage

| Function | Tests | Pass Rate |
|----------|-------|-----------|
| to_fixed() | 4 | 100% |
| fixed_mul() | 5 | 100% |
| fixed_div() | 5 | 100% |
| fixed_add() | 3 | 100% |
| fixed_sub() | 4 | 100% |
| weighted_sum() | 4 | 100% |
| relu_activation() | 4 | 100% |
| Edge Cases | 4 | 100% |
| Precision | 2 | 100% |
| **TOTAL** | **35** | **100%** |

### Example Test

```python
# Test: 0.5 × 0.5 = 0.25
a = 500_000
b = 500_000
result = (a * b) // 1_000_000
assert result == 250_000  # ✓ PASS
```

---

## Performance & Gas Optimization

### Gas-Efficient Design Choices

1. **Inline Functions:** All core functions are `inline` to reduce call overhead
2. **Unrolled Loops:** `weighted_sum` uses explicit terms instead of loops
3. **Minimal Branching:** Reduces circuit complexity in ZK proofs
4. **u128 Only When Needed:** Keeps most operations in u64 space

### Gas Cost Estimates

| Operation | Approximate Gas | Notes |
|-----------|----------------|-------|
| fixed_add() | ~50 | Simple addition |
| fixed_sub() | ~50 | Simple subtraction |
| fixed_mul() | ~200 | Requires u128 cast |
| fixed_div() | ~250 | Requires u128 + division |
| weighted_sum() | ~1,000 | 4 multiplications + additions |
| relu_activation() | ~30 | Simple comparison |

### Optimization Tips

1. **Batch Operations:** Combine multiple operations when possible
2. **Precompute Constants:** Calculate fixed values off-chain
3. **Use Addition Over Multiplication:** When semantically equivalent
4. **Minimize Record Updates:** Records are expensive to modify

---

## Troubleshooting

### Common Errors

**"Overflow Error"**
- **Cause:** Value exceeds u64 maximum
- **Solution:** Ensure inputs < MAX_SAFE_VALUE before scaling

**"Division by Zero"**
- **Cause:** Denominator is 0
- **Solution:** Add validation: `assert(denominator > 0u64)`

**"Underflow Error"**
- **Cause:** Subtraction result would be negative
- **Solution:** Ensure `a >= b` before `fixed_sub(a, b)`

**"Precision Loss"**
- **Cause:** Integer division truncates decimals
- **Solution:** Expected behavior; scale up inputs if more precision needed

### Best Practices

✅ **DO:**
- Always validate inputs before operations
- Use u128 for intermediate calculations
- Test with Python suite before deploying
- Document assumptions about input ranges

❌ **DON'T:**
- Assume inputs are pre-scaled
- Ignore overflow/underflow risks
- Skip edge case testing
- Use floating-point in production thinking

---

## References

- **Leo Language Docs:** https://developer.aleo.org/leo/
- **Fixed-Point Arithmetic:** https://en.wikipedia.org/wiki/Fixed-point_arithmetic
- **PROPHETIA Architecture:** `docs/ARCHITECTURE.md`
- **Test Suite:** `tests/test_math_utils.py`

---

**Document Version:** 1.0 (Week 2)  
**Last Updated:** January 2026  
**Next Review:** Week 3 (Advanced ML Implementation)

---

*"Precision in mathematics. Privacy in execution. Perfection in predictions."*

— PROPHETIA Math Team
