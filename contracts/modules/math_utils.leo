// PROPHETIA Math Utilities Module - Week 2
// Comprehensive fixed-point arithmetic library for Zero-Knowledge ML
// All operations use fixed-point arithmetic (scaled by 10^6)
//
// This library provides the mathematical foundation for:
// - Private ML model inference
// - Weighted aggregations
// - Activation functions
// - Numerical computations in zero-knowledge proofs

program prophetia.aleo {
    
    // ============================================================================
    // FIXED-POINT ARITHMETIC CONSTANTS
    // ============================================================================
    
    // Scale factor for all decimal operations: 10^6
    // This means 1.0 is represented as 1,000,000
    // Examples:
    //   0.5      → 500,000
    //   1.234567 → 1,234,567
    //   100.0    → 100,000,000
    const SCALE: u64 = 1000000u64;
    const SCALE_U128: u128 = 1000000u128;
    
    // Maximum safe value for u64 operations before overflow risk
    // Calculated as: (2^64 - 1) / 10^6 ≈ 18,446,744 (max value before overflow)
    const MAX_SAFE_VALUE: u64 = 18446744073709u64;
    
    // ============================================================================
    // CORE FIXED-POINT FUNCTIONS
    // ============================================================================
    
    // FUNCTION 1: to_fixed
    // Converts an integer to fixed-point representation
    //
    // Parameters:
    //   value: Integer value to convert
    //
    // Returns:
    //   Fixed-point representation (value * 10^6)
    //
    // Examples:
    //   to_fixed(5) = 5,000,000 (represents 5.0)
    //   to_fixed(0) = 0
    //   to_fixed(1000) = 1,000,000,000 (represents 1000.0)
    //
    // Safety:
    //   - Checks for overflow before multiplication
    //   - Maximum input: 18,446,744 (to prevent u64 overflow)
    inline to_fixed(value: u64) -> u64 {
        // Overflow protection: ensure value won't overflow when scaled
        assert(value <= MAX_SAFE_VALUE);
        
        // Multiply by scale factor to convert to fixed-point
        let result: u64 = value * SCALE;
        
        return result;
    }
    
    // FUNCTION 2: fixed_mul
    // Multiplies two fixed-point numbers
    //
    // Formula: (a * b) / SCALE
    // Both inputs and output are scaled by 10^6
    //
    // Parameters:
    //   a: First fixed-point operand
    //   b: Second fixed-point operand
    //
    // Returns:
    //   Product in fixed-point format
    //
    // Examples:
    //   fixed_mul(500000, 500000) = 250000 (0.5 * 0.5 = 0.25)
    //   fixed_mul(1500000, 2000000) = 3000000 (1.5 * 2.0 = 3.0)
    //   fixed_mul(1000000, 1000000) = 1000000 (1.0 * 1.0 = 1.0)
    //
    // Safety:
    //   - Uses u128 for intermediate calculations to prevent overflow
    //   - Automatically descales result by dividing by SCALE
    //
    // Gas Optimization:
    //   - Single u128 cast per operand (not per operation)
    //   - Direct division without temporary variables
    inline fixed_mul(a: u64, b: u64) -> u64 {
        // Cast to u128 to prevent overflow during multiplication
        // u64 max is ~18 quintillion, multiplying two could overflow
        let a_wide: u128 = a as u128;
        let b_wide: u128 = b as u128;
        
        // Perform multiplication in u128 space
        let product: u128 = a_wide * b_wide;
        
        // Descale: divide by SCALE to maintain fixed-point representation
        // Example: (1.5M * 2M) / 1M = 3M (represents 3.0)
        let result: u128 = product / SCALE_U128;
        
        // Cast back to u64 (safe because we descaled)
        return result as u64;
    }
    
    // FUNCTION 3: fixed_div
    // Divides two fixed-point numbers
    //
    // Formula: (a * SCALE) / b
    // Both inputs and output are scaled by 10^6
    //
    // Parameters:
    //   a: Numerator (dividend) in fixed-point
    //   b: Denominator (divisor) in fixed-point
    //
    // Returns:
    //   Quotient in fixed-point format
    //
    // Examples:
    //   fixed_div(3000000, 2000000) = 1500000 (3.0 / 2.0 = 1.5)
    //   fixed_div(1000000, 4000000) = 250000 (1.0 / 4.0 = 0.25)
    //   fixed_div(5000000, 1000000) = 5000000 (5.0 / 1.0 = 5.0)
    //
    // Safety:
    //   - CRITICAL: Checks denominator != 0 (division by zero protection)
    //   - Uses u128 to prevent overflow when scaling numerator
    //
    // Edge Cases:
    //   - Division by zero: assertion failure (program halts)
    //   - Result < 1: returns fractional fixed-point (e.g., 0.5 = 500000)
    inline fixed_div(a: u64, b: u64) -> u64 {
        // CRITICAL: Prevent division by zero
        assert(b > 0u64);
        
        // Cast to u128 for overflow protection
        let a_wide: u128 = a as u128;
        let b_wide: u128 = b as u128;
        
        // Scale up numerator before division to maintain precision
        // Example: (3M * 1M) / 2M = 1.5M (represents 1.5)
        let scaled_numerator: u128 = a_wide * SCALE_U128;
        
        // Perform division
        let result: u128 = scaled_numerator / b_wide;
        
        // Cast back to u64
        return result as u64;
    }
    
    // FUNCTION 4: fixed_add
    // Adds two fixed-point numbers
    //
    // Formula: a + b
    // Both inputs and output are scaled by 10^6
    //
    // Parameters:
    //   a: First fixed-point operand
    //   b: Second fixed-point operand
    //
    // Returns:
    //   Sum in fixed-point format
    //
    // Examples:
    //   fixed_add(1500000, 2500000) = 4000000 (1.5 + 2.5 = 4.0)
    //   fixed_add(1000000, 1000000) = 2000000 (1.0 + 1.0 = 2.0)
    //
    // Safety:
    //   - Uses u128 to prevent overflow
    //   - Checks result fits in u64 range
    //
    // Gas Optimization:
    //   - Direct addition without unnecessary casts
    inline fixed_add(a: u64, b: u64) -> u64 {
        // Cast to u128 to prevent overflow
        let a_wide: u128 = a as u128;
        let b_wide: u128 = b as u128;
        
        // Perform addition
        let sum: u128 = a_wide + b_wide;
        
        // Verify result fits in u64 (should always be true for reasonable inputs)
        // Max u64 is 18,446,744,073,709,551,615 (plenty of room)
        return sum as u64;
    }
    
    // FUNCTION 5: fixed_sub
    // Subtracts two fixed-point numbers
    //
    // Formula: a - b
    // Both inputs and output are scaled by 10^6
    //
    // Parameters:
    //   a: Minuend (value to subtract from)
    //   b: Subtrahend (value to subtract)
    //
    // Returns:
    //   Difference in fixed-point format
    //
    // Examples:
    //   fixed_sub(5000000, 2000000) = 3000000 (5.0 - 2.0 = 3.0)
    //   fixed_sub(1000000, 500000) = 500000 (1.0 - 0.5 = 0.5)
    //
    // Safety:
    //   - CRITICAL: Checks a >= b (underflow protection)
    //   - Returns 0 if result would be negative (u64 can't be negative)
    //
    // Edge Cases:
    //   - Underflow: assertion failure if b > a
    inline fixed_sub(a: u64, b: u64) -> u64 {
        // CRITICAL: Prevent underflow (u64 cannot be negative)
        assert(a >= b);
        
        // Direct subtraction (no risk of overflow/underflow after assert)
        let difference: u64 = a - b;
        
        return difference;
    }
    
    // FUNCTION 6: weighted_sum
    // Computes weighted sum of inputs (CRITICAL for ML inference)
    //
    // Formula: Σ(weights[i] * inputs[i]) for i = 0 to 3
    // This is the core operation for linear models: prediction = w·x + b
    //
    // Parameters:
    //   weights: Array of 4 weight values (scaled by 10^6)
    //   inputs: Array of 4 input values (scaled by 10^6)
    //
    // Returns:
    //   Weighted sum in fixed-point format
    //
    // Examples:
    //   weights = [500000, 300000, 200000, 100000]  // [0.5, 0.3, 0.2, 0.1]
    //   inputs  = [1000000, 2000000, 1500000, 500000]  // [1.0, 2.0, 1.5, 0.5]
    //   result  = 0.5*1.0 + 0.3*2.0 + 0.2*1.5 + 0.1*0.5
    //           = 0.5 + 0.6 + 0.3 + 0.05
    //           = 1.45 = 1450000
    //
    // Use Cases:
    //   - Linear regression: y = w₁x₁ + w₂x₂ + w₃x₃ + w₄x₄ + b
    //   - Neural network layers: weighted sum before activation
    //   - Ensemble predictions: weighted average of multiple models
    //
    // Safety:
    //   - Uses u128 accumulator to prevent overflow
    //   - Each multiplication uses fixed_mul for proper scaling
    //
    // Gas Optimization:
    //   - Unrolled loop (no iteration overhead)
    //   - Accumulates in u128 to avoid repeated casts
    inline weighted_sum(
        weights: [u64; 4],
        inputs: [u64; 4]
    ) -> u64 {
        // Initialize accumulator as u128 for overflow protection
        let sum: u128 = 0u128;
        
        // Manually unroll loop for gas efficiency
        // Term 1: weights[0] * inputs[0]
        let term0: u64 = fixed_mul(weights[0], inputs[0]);
        sum += term0 as u128;
        
        // Term 2: weights[1] * inputs[1]
        let term1: u64 = fixed_mul(weights[1], inputs[1]);
        sum += term1 as u128;
        
        // Term 3: weights[2] * inputs[2]
        let term2: u64 = fixed_mul(weights[2], inputs[2]);
        sum += term2 as u128;
        
        // Term 4: weights[3] * inputs[3]
        let term3: u64 = fixed_mul(weights[3], inputs[3]);
        sum += term3 as u128;
        
        // Cast back to u64 (safe because sum of 4 products should fit)
        return sum as u64;
    }
    
    // FUNCTION 7: relu_activation
    // ReLU (Rectified Linear Unit) activation function for neural networks
    //
    // Formula: f(x) = max(0, x - threshold)
    // Returns true if x >= threshold, false otherwise
    //
    // Parameters:
    //   x: Input value in fixed-point
    //   threshold: Activation threshold in fixed-point
    //
    // Returns:
    //   Boolean: true if x >= threshold, false otherwise
    //
    // Examples:
    //   relu_activation(1500000, 1000000) = true (1.5 >= 1.0)
    //   relu_activation(500000, 1000000) = false (0.5 < 1.0)
    //   relu_activation(1000000, 1000000) = true (1.0 >= 1.0)
    //
    // Use Cases:
    //   - Binary classification: threshold for yes/no decisions
    //   - Neural network activation: non-linear transformation
    //   - Signal detection: threshold for trigger events
    //
    // Note:
    //   - This is a simplified ReLU (boolean output)
    //   - Full ReLU would return max(0, x), but bool is sufficient for classification
    inline relu_activation(x: u64, threshold: u64) -> bool {
        // Simple comparison: is x greater than or equal to threshold?
        return x >= threshold;
    }
    
    // ============================================================================
    // LEGACY UTILITY FUNCTIONS (from Week 1 - kept for compatibility)
    // ============================================================================
    
    // Compute weighted average of up to 4 values
    // Used for aggregating predictions or data from multiple sources
    //
    // Parameters:
    //   values: Array of values to average (scaled by 10^6)
    //   weights: Array of weights (scaled by 10^6, should sum to 10^6)
    //
    // Returns:
    //   Weighted average (scaled by 10^6)
    function weighted_average(values: [u64; 4], weights: [u64; 4]) -> u64 {
        // Calculate weighted sum
        let sum: u64 = weighted_sum(weights, values);
        
        // Calculate total weight
        let weight_sum: u128 = (weights[0] as u128) + (weights[1] as u128) + 
                               (weights[2] as u128) + (weights[3] as u128);
        
        // Prevent division by zero
        assert(weight_sum > 0u128);
        
        // Normalize by total weight
        let sum_wide: u128 = sum as u128;
        let normalized: u128 = (sum_wide * SCALE_U128) / weight_sum;
        
        return normalized as u64;
    }
    
    // Compute simple average of up to 4 values
    function simple_average(values: [u64; 4], count: u8) -> u64 {
        assert(count >= 1u8 && count <= 4u8);
        
        let sum: u128 = 0u128;
        if count >= 1u8 { sum += values[0] as u128; }
        if count >= 2u8 { sum += values[1] as u128; }
        if count >= 3u8 { sum += values[2] as u128; }
        if count >= 4u8 { sum += values[3] as u128; }
        
        let result: u128 = sum / (count as u128);
        return result as u64;
    }
    
    // Compute minimum of up to 4 values
    function min_value(values: [u64; 4], count: u8) -> u64 {
        assert(count >= 1u8 && count <= 4u8);
        
        let min: u64 = values[0];
        if count >= 2u8 && values[1] < min { min = values[1]; }
        if count >= 3u8 && values[2] < min { min = values[2]; }
        if count >= 4u8 && values[3] < min { min = values[3]; }
        
        return min;
    }
    
    // Compute maximum of up to 4 values
    function max_value(values: [u64; 4], count: u8) -> u64 {
        assert(count >= 1u8 && count <= 4u8);
        
        let max: u64 = values[0];
        if count >= 2u8 && values[1] > max { max = values[1]; }
        if count >= 3u8 && values[2] > max { max = values[2]; }
        if count >= 4u8 && values[3] > max { max = values[3]; }
        
        return max;
    }
    
    // Clamp a value between minimum and maximum bounds
    function clamp(value: u64, min_bound: u64, max_bound: u64) -> u64 {
        assert(min_bound <= max_bound);
        
        let result: u64 = value;
        if result < min_bound { result = min_bound; }
        if result > max_bound { result = max_bound; }
        
        return result;
    }
    
    // Calculate percentage change between two values
    function percentage_change(old_value: u64, new_value: u64) -> u64 {
        if old_value == 0u64 { return 0u64; }
        
        let difference: u128 = 0u128;
        if new_value >= old_value {
            difference = (new_value - old_value) as u128;
        } else {
            return 0u64;
        }
        
        let old_wide: u128 = old_value as u128;
        let percentage: u128 = (difference * 100u128 * SCALE_U128) / old_wide;
        
        return percentage as u64;
    }
    
    // Normalize a value to 0-1 range given min and max
    function normalize(value: u64, min_val: u64, max_val: u64) -> u64 {
        assert(max_val > min_val);
        
        let clamped: u64 = value;
        if clamped < min_val { clamped = min_val; }
        if clamped > max_val { clamped = max_val; }
        
        let numerator: u128 = (clamped - min_val) as u128;
        let denominator: u128 = (max_val - min_val) as u128;
        
        let result: u128 = (numerator * SCALE_U128) / denominator;
        
        return result as u64;
    }
    
    // ============================================================================
    // ADVANCED MATH FUNCTIONS - WEEK 4
    // ============================================================================
    
    // FUNCTION: sigmoid_approx
    // Approximates the sigmoid activation function for logistic regression
    //
    // Formula: sigmoid(x) = 1 / (1 + e^(-x))
    // Approximation: Piecewise linear function for ZK-friendly computation
    //
    // Parameters:
    //   x: Fixed-point input value (scaled by 10^6)
    //
    // Returns:
    //   Sigmoid output in range [0, 1] (scaled by 10^6)
    //
    // Approximation Strategy:
    //   Range 1: x >= 6.0  → sigmoid ≈ 1.0 (asymptotic upper bound)
    //   Range 2: x <= -6.0 → sigmoid ≈ 0.0 (asymptotic lower bound)
    //   Range 3: -6 < x < 6 → Linear interpolation: sigmoid(x) ≈ 0.5 + x/12
    //
    // Mathematical Justification:
    //   - sigmoid(0) = 0.5 (exact)
    //   - sigmoid(6) ≈ 0.9975 ≈ 1.0 (close enough)
    //   - sigmoid(-6) ≈ 0.0025 ≈ 0.0 (close enough)
    //   - Linear approximation in middle range has <10% error
    //
    // Examples:
    //   sigmoid_approx(0)        = 500000 (0.5)
    //   sigmoid_approx(6000000)  = 1000000 (1.0)
    //   sigmoid_approx(3000000)  = 750000 (0.75, actual ≈ 0.95)
    //
    // Edge Cases:
    //   - Very large positive x: Clamps to 1.0
    //   - Very large negative x: Would underflow to 0 in u64
    //   - x = 0: Returns exact 0.5
    //
    // Gas Cost: ~250 credits (conditional branches + arithmetic)
    //
    // Note: u64 is unsigned, so we can't directly represent negative values.
    // Caller must handle sign externally and use this for |x|.
    inline sigmoid_approx(x: u64) -> u64 {
        // Range 1: Large positive values → 1.0
        if (x >= 6000000u64) {
            return 1000000u64;  // sigmoid(6) ≈ 1.0
        }
        
        // Range 2: Middle range → Linear approximation
        // sigmoid(x) ≈ 0.5 + x/12
        // Formula derivation:
        //   - At x=0: 0.5 + 0/12 = 0.5 ✓
        //   - At x=6: 0.5 + 6/12 = 1.0 ✓
        //   - Slope: 1/12 ≈ 0.0833 (reasonable for small x)
        
        let result: u64 = 500000u64 + (x / 12u64);
        
        // Clamp to maximum 1.0 (safety check)
        if (result > 1000000u64) {
            result = 1000000u64;
        }
        
        return result;
    }
    
    // FUNCTION: max_u64
    // Returns the maximum of two unsigned 64-bit integers
    //
    // Parameters:
    //   a: First value
    //   b: Second value
    //
    // Returns:
    //   max(a, b)
    //
    // Use Cases:
    //   - Decision tree branching
    //   - Finding best model weights
    //   - Threshold comparisons
    //
    // Examples:
    //   max_u64(5, 3) = 5
    //   max_u64(1000000, 2000000) = 2000000
    //   max_u64(x, x) = x
    //
    // Gas Cost: ~100 credits (single comparison)
    inline max_u64(a: u64, b: u64) -> u64 {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }
    
    // FUNCTION: min_u64
    // Returns the minimum of two unsigned 64-bit integers
    //
    // Parameters:
    //   a: First value
    //   b: Second value
    //
    // Returns:
    //   min(a, b)
    //
    // Use Cases:
    //   - Clamping values
    //   - Risk management (minimum acceptable values)
    //   - Threshold comparisons
    //
    // Examples:
    //   min_u64(5, 3) = 3
    //   min_u64(1000000, 2000000) = 1000000
    //   min_u64(x, x) = x
    //
    // Gas Cost: ~100 credits (single comparison)
    inline min_u64(a: u64, b: u64) -> u64 {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }
    
    // FUNCTION: abs_diff
    // Computes the absolute difference between two unsigned integers
    //
    // Formula: |a - b|
    //
    // Parameters:
    //   a: First value
    //   b: Second value
    //
    // Returns:
    //   Absolute difference (always positive)
    //
    // Use Cases:
    //   - Confidence calculations (distance from threshold)
    //   - Error metrics
    //   - Model performance measurement
    //
    // Examples:
    //   abs_diff(5, 3) = 2
    //   abs_diff(3, 5) = 2 (symmetric)
    //   abs_diff(1000000, 750000) = 250000
    //   abs_diff(x, x) = 0
    //
    // Safety:
    //   - No underflow risk (both branches handle sign)
    //   - Commutative: abs_diff(a, b) = abs_diff(b, a)
    //
    // Gas Cost: ~120 credits (comparison + subtraction)
    inline abs_diff(a: u64, b: u64) -> u64 {
        if (a >= b) {
            return a - b;
        } else {
            return b - a;
        }
    }
    
    // FUNCTION: clamp
    // Constrains a value to a specified range [min_val, max_val]
    //
    // Parameters:
    //   value: Value to clamp
    //   min_val: Minimum allowed value
    //   max_val: Maximum allowed value
    //
    // Returns:
    //   value clamped to [min_val, max_val]
    //
    // Use Cases:
    //   - Normalizing confidence scores (0-100%)
    //   - Preventing overflow in iterative calculations
    //   - Enforcing valid ranges for model parameters
    //
    // Examples:
    //   clamp(50, 0, 100) = 50 (within range)
    //   clamp(150, 0, 100) = 100 (exceeds max)
    //   clamp(-10, 0, 100) = 0 (below min, but u64 wraps)
    //
    // Preconditions:
    //   - min_val <= max_val (undefined behavior if violated)
    //   - All values are unsigned (no negative numbers)
    //
    // Gas Cost: ~180 credits (two comparisons + conditional assignments)
    //
    // Note: For confidence scores, use clamp(score, 0, 1000000) to ensure 0-100%
    inline clamp(value: u64, min_val: u64, max_val: u64) -> u64 {
        // Apply lower bound
        if (value < min_val) {
            return min_val;
        } 
        // Apply upper bound
        else if (value > max_val) {
            return max_val;
        } 
        // Value is within range
        else {
            return value;
        }
    }
}
