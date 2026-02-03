// ═══════════════════════════════════════════════════════════════════════════
// PROPHETIA Algorithm Comparison Example - Week 4
// ═══════════════════════════════════════════════════════════════════════════
//
// This example demonstrates how to use all three ML algorithms on the same
// data to compare their predictions. This is useful for:
//   - Understanding algorithm differences
//   - Ensemble predictions (combining multiple algorithms)
//   - Model selection based on confidence
//   - Educational purposes
//
// USAGE:
//   1. Deploy this program: `leo deploy algorithm_showcase.aleo`
//   2. Run comparison: `leo execute compare_algorithms [data_record]`
//   3. Observe three different predictions from same input
//
// ═══════════════════════════════════════════════════════════════════════════

// Import inference engine (in practice, this would be a real import)
// For this example, we assume prophetia_inference.aleo is deployed

program algorithm_showcase.aleo {
    
    // ───────────────────────────────────────────────────────────────────────
    // RECORD DEFINITIONS
    // ───────────────────────────────────────────────────────────────────────
    
    // ProphecyData record structure
    record ProphecyData {
        owner: address,
        payload: u64,
        category: u8,
        quality_score: u64,
        timestamp: u32,
        _nonce: group,
    }
    
    // OracleModel record structure
    record OracleModel {
        owner: address,
        weights: [u64; 4],
        bias: u64,
        algorithm_id: u8,
        threshold: u64,
        performance_score: u64,
        category: u8,
        _nonce: group,
    }
    
    // ProphecySignal output (public)
    struct ProphecySignal {
        predictor: address,
        direction: bool,
        confidence: u64,
        timestamp: u32,
        category: u8,
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // MAIN COMPARISON TRANSITION
    // ───────────────────────────────────────────────────────────────────────
    
    /// Compare all three algorithms on the same input data
    ///
    /// This transition:
    ///   1. Creates three different model configurations (linear, logistic, tree)
    ///   2. Runs the same data through all three algorithms
    ///   3. Returns three public signals for comparison
    ///
    /// Parameters:
    ///   - data: The input data to predict on
    ///
    /// Returns:
    ///   - signal1: Linear regression prediction
    ///   - signal2: Logistic regression prediction
    ///   - signal3: Decision tree prediction
    ///
    /// Example Output:
    ///   Linear:   direction=UP,   confidence=0.41
    ///   Logistic: direction=UP,   confidence=0.21, probability=0.61
    ///   Tree:     direction=DOWN, confidence=0.70
    ///
    /// Use Cases:
    ///   - Algorithm benchmarking
    ///   - Ensemble voting (majority prediction)
    ///   - Confidence-based model selection
    ///   - Educational comparison
    transition compare_algorithms(
        data: ProphecyData
    ) -> (ProphecySignal, ProphecySignal, ProphecySignal) {
        
        // ───────────────────────────────────────────────────────────────
        // MODEL 1: LINEAR REGRESSION
        // ───────────────────────────────────────────────────────────────
        //
        // Configuration:
        //   - Balanced weights across features
        //   - Moderate threshold for classification
        //   - Best for: General-purpose regression
        //
        let linear_model: OracleModel = OracleModel {
            owner: self.caller,
            weights: [500000u64, 300000u64, 200000u64, 100000u64],  // [0.5, 0.3, 0.2, 0.1]
            bias: 100000u64,  // 0.1
            algorithm_id: 1u8,  // Linear
            threshold: 1000000u64,  // 1.0
            performance_score: 800000u64,  // 0.8 (historical accuracy)
            category: data.category,  // Match data category
            _nonce: group::GEN
        };
        
        // ───────────────────────────────────────────────────────────────
        // MODEL 2: LOGISTIC REGRESSION
        // ───────────────────────────────────────────────────────────────
        //
        // Configuration:
        //   - Higher weights on primary features
        //   - Small bias (sigmoid handles centering)
        //   - Best for: Probability estimates
        //
        let logistic_model: OracleModel = OracleModel {
            owner: self.caller,
            weights: [400000u64, 400000u64, 150000u64, 150000u64],  // [0.4, 0.4, 0.15, 0.15]
            bias: 50000u64,  // 0.05 (small bias for logistic)
            algorithm_id: 2u8,  // Logistic
            threshold: 500000u64,  // Not used, but required field
            performance_score: 850000u64,  // 0.85 (highest accuracy)
            category: data.category,
            _nonce: group::GEN
        };
        
        // ───────────────────────────────────────────────────────────────
        // MODEL 3: DECISION TREE
        // ───────────────────────────────────────────────────────────────
        //
        // Configuration:
        //   - Weights used as thresholds (not multiplication)
        //   - Larger bias for confidence boost
        //   - Best for: Interpretable rules, gas efficiency
        //
        // Tree structure:
        //   if payload > 1.2M:
        //       if quality > 0.8M: UP (0.8)
        //       else: DOWN (0.6)
        //   else:
        //       if quality > 0.6M: UP (0.7)
        //       else: DOWN (0.9)
        //
        let tree_model: OracleModel = OracleModel {
            owner: self.caller,
            weights: [1200000u64, 800000u64, 600000u64, 400000u64],  // Thresholds
            bias: 200000u64,  // 0.2 (confidence adjustment)
            algorithm_id: 3u8,  // Decision Tree
            threshold: 1000000u64,  // Not used by tree
            performance_score: 780000u64,  // 0.78 (good, but lower than logistic)
            category: data.category,
            _nonce: group::GEN
        };
        
        // ───────────────────────────────────────────────────────────────
        // EXECUTE ALL THREE ALGORITHMS
        // ───────────────────────────────────────────────────────────────
        //
        // Note: In production, these would call prophetia_inference.aleo
        // For this example, we simulate the calls
        //
        // Real code would be:
        //   let (d1, m1, signal1) = prophetia_inference.aleo/divine_future(data, linear_model);
        //   let (d2, m2, signal2) = prophetia_inference.aleo/divine_future_logistic(data, logistic_model);
        //   let (d3, m3, signal3) = prophetia_inference.aleo/divine_future_tree(data, tree_model);
        //
        
        // For demonstration, create placeholder signals
        // (Replace these with actual inference calls in production)
        
        let signal1: ProphecySignal = ProphecySignal {
            predictor: self.caller,
            direction: true,  // Example: Linear predicts UP
            confidence: 410000u64,  // 0.41 confidence
            timestamp: data.timestamp,
            category: data.category
        };
        
        let signal2: ProphecySignal = ProphecySignal {
            predictor: self.caller,
            direction: true,  // Example: Logistic predicts UP
            confidence: 210000u64,  // 0.21 confidence (distance from 0.5 probability)
            timestamp: data.timestamp,
            category: data.category
        };
        
        let signal3: ProphecySignal = ProphecySignal {
            predictor: self.caller,
            direction: false,  // Example: Tree predicts DOWN
            confidence: 700000u64,  // 0.70 confidence
            timestamp: data.timestamp,
            category: data.category
        };
        
        // ───────────────────────────────────────────────────────────────
        // RETURN ALL THREE SIGNALS
        // ───────────────────────────────────────────────────────────────
        //
        // All signals are public, so anyone can see the predictions
        // User can now:
        //   1. Compare algorithm predictions
        //   2. Choose most confident prediction
        //   3. Use majority voting
        //   4. Average confidence scores
        //
        return (signal1, signal2, signal3);
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // ENSEMBLE VOTING TRANSITION
    // ───────────────────────────────────────────────────────────────────────
    
    /// Combine three predictions using majority voting
    ///
    /// Parameters:
    ///   - signal1: Linear regression prediction
    ///   - signal2: Logistic regression prediction
    ///   - signal3: Decision tree prediction
    ///
    /// Returns:
    ///   - consensus_signal: Final prediction based on majority vote
    ///
    /// Logic:
    ///   - If 2+ algorithms agree on direction: Use that direction
    ///   - Confidence = average of agreeing algorithms
    ///   - If tie (impossible with 3): Use highest confidence prediction
    ///
    transition ensemble_vote(
        signal1: ProphecySignal,
        signal2: ProphecySignal,
        signal3: ProphecySignal
    ) -> ProphecySignal {
        
        // Count votes for UP (direction = true)
        let up_votes: u8 = 0u8;
        if (signal1.direction) { up_votes = up_votes + 1u8; }
        if (signal2.direction) { up_votes = up_votes + 1u8; }
        if (signal3.direction) { up_votes = up_votes + 1u8; }
        
        // Majority vote
        let final_direction: bool = up_votes >= 2u8;
        
        // Calculate average confidence of agreeing algorithms
        let total_confidence: u64 = 0u64;
        let count: u64 = 0u64;
        
        if (signal1.direction == final_direction) {
            total_confidence = total_confidence + signal1.confidence;
            count = count + 1u64;
        }
        if (signal2.direction == final_direction) {
            total_confidence = total_confidence + signal2.confidence;
            count = count + 1u64;
        }
        if (signal3.direction == final_direction) {
            total_confidence = total_confidence + signal3.confidence;
            count = count + 1u64;
        }
        
        let avg_confidence: u64 = total_confidence / count;
        
        // Create consensus signal
        let consensus: ProphecySignal = ProphecySignal {
            predictor: self.caller,
            direction: final_direction,
            confidence: avg_confidence,
            timestamp: signal1.timestamp,  // Use first signal's timestamp
            category: signal1.category
        };
        
        return consensus;
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // HELPER: SELECT MOST CONFIDENT PREDICTION
    // ───────────────────────────────────────────────────────────────────────
    
    /// Select the prediction with highest confidence
    ///
    /// Parameters:
    ///   - signal1, signal2, signal3: The three predictions
    ///
    /// Returns:
    ///   - best_signal: Prediction with highest confidence score
    ///
    /// Use Case:
    ///   When you trust the most confident algorithm
    ///   (Assumes higher confidence = more reliable)
    ///
    transition select_most_confident(
        signal1: ProphecySignal,
        signal2: ProphecySignal,
        signal3: ProphecySignal
    ) -> ProphecySignal {
        
        // Find maximum confidence
        let best: ProphecySignal = signal1;
        
        if (signal2.confidence > best.confidence) {
            best = signal2;
        }
        
        if (signal3.confidence > best.confidence) {
            best = signal3;
        }
        
        return best;
    }
    
    // ───────────────────────────────────────────────────────────────────────
    // DEMO: CREATE SAMPLE DATA FOR TESTING
    // ───────────────────────────────────────────────────────────────────────
    
    /// Create sample data for algorithm comparison testing
    ///
    /// Returns:
    ///   - Sample ProphecyData record with realistic values
    ///
    /// Example values:
    ///   - payload: $1.60 (market price)
    ///   - quality_score: 0.88 (high quality data)
    ///   - category: 1 (e.g., commodities)
    ///
    transition create_sample_data() -> ProphecyData {
        let sample: ProphecyData = ProphecyData {
            owner: self.caller,
            payload: 1600000u64,  // $1.60
            category: 1u8,  // Commodities
            quality_score: 880000u64,  // 0.88 quality
            timestamp: 0u32,  // Current time (placeholder)
            _nonce: group::GEN
        };
        
        return sample;
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// USAGE EXAMPLES
// ═══════════════════════════════════════════════════════════════════════════

/*

EXAMPLE 1: Compare algorithms on same data
──────────────────────────────────────────

# Create sample data
leo execute create_sample_data

# Run comparison
leo execute compare_algorithms [data_record_from_above]

# Output:
Signal 1 (Linear):   {direction: true, confidence: 410000, ...}
Signal 2 (Logistic): {direction: true, confidence: 210000, ...}
Signal 3 (Tree):     {direction: false, confidence: 700000, ...}

# Analysis:
- Linear and Logistic agree: UP
- Tree disagrees: DOWN (but with high confidence!)
- Majority vote: UP
- Most confident: Tree (DOWN)


EXAMPLE 2: Ensemble voting
──────────────────────────

# Get three signals from comparison
signals = compare_algorithms(data)

# Vote for consensus
consensus = ensemble_vote(signals[0], signals[1], signals[2])

# Output:
Consensus: {direction: true, confidence: 310000, ...}
# 2/3 voted UP, average confidence = (0.41 + 0.21)/2 = 0.31


EXAMPLE 3: Select most confident
─────────────────────────────────

# Get three signals
signals = compare_algorithms(data)

# Pick highest confidence
best = select_most_confident(signals[0], signals[1], signals[2])

# Output:
Best: {direction: false, confidence: 700000, ...}
# Tree's prediction selected (0.70 confidence)


DEPLOYMENT INSTRUCTIONS
───────────────────────

1. Deploy inference engine first:
   cd contracts
   leo deploy prophetia_inference.aleo --network testnet

2. Deploy this comparison program:
   leo deploy algorithm_showcase.aleo --network testnet

3. Test comparison:
   # Create data
   leo execute create_sample_data --network testnet
   
   # Compare algorithms
   leo execute compare_algorithms [data_record] --network testnet

4. Interpret results:
   - Compare direction predictions (agree/disagree?)
   - Compare confidence scores (who's more certain?)
   - Use ensemble voting for robustness
   - Use highest confidence for aggressive strategy

*/
