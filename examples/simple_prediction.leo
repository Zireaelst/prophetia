// ═══════════════════════════════════════════════════════════════════════════
// PROPHETIA - Simple Prediction Example
// ═══════════════════════════════════════════════════════════════════════════
//
// This file demonstrates how to use PROPHETIA's zero-knowledge inference engine
// to make private ML predictions on-chain.
//
// SCENARIO: Stock Price Prediction
//   - Alice (data provider): Has current stock price and quality score
//   - Bob (model owner): Has trained ML model for price prediction
//   - Goal: Predict if stock will rise or fall without revealing data/model
//
// USAGE:
//   1. Deploy to Aleo testnet
//   2. Run example_prediction_workflow()
//   3. Observe public ProphecySignal output
//   4. Verify that input data and model weights remain private
//
// ═══════════════════════════════════════════════════════════════════════════

program prophetia_example.aleo {
    
    // Import record structures from main prophetia program
    // Note: In actual deployment, these would be imported from prophetia.aleo
    
    record ProphecyData {
        owner: address,
        payload: u64,
        category: u8,
        quality_score: u64,
        timestamp: u32,
        _nonce: group,
    }
    
    record OracleModel {
        owner: address,
        weights: [u64; 4],
        bias: u64,
        algorithm_id: u8,
        threshold: u64,
        performance_score: u64,
        _nonce: group,
    }
    
    struct ProphecySignal {
        predictor: address,
        direction: bool,
        confidence: u64,
        timestamp: u32,
        category: u8,
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // Helper Functions (Inline for efficiency)
    // ═══════════════════════════════════════════════════════════════════════
    
    const SCALE: u64 = 1000000u64;
    
    inline fixed_mul(a: u64, b: u64) -> u64 {
        let a_wide: u128 = a as u128;
        let b_wide: u128 = b as u128;
        let product: u128 = a_wide * b_wide;
        let result: u128 = product / 1000000u128;
        return result as u64;
    }
    
    inline fixed_add(a: u64, b: u64) -> u64 {
        let result: u128 = (a as u128) + (b as u128);
        return result as u64;
    }
    
    inline weighted_sum(weights: [u64; 4], inputs: [u64; 4]) -> u64 {
        let sum: u128 = 0u128;
        let term0: u64 = fixed_mul(weights[0u8], inputs[0u8]);
        sum = sum + (term0 as u128);
        let term1: u64 = fixed_mul(weights[1u8], inputs[1u8]);
        sum = sum + (term1 as u128);
        let term2: u64 = fixed_mul(weights[2u8], inputs[2u8]);
        sum = sum + (term2 as u128);
        let term3: u64 = fixed_mul(weights[3u8], inputs[3u8]);
        sum = sum + (term3 as u128);
        return sum as u64;
    }
    
    inline relu_activation(x: u64, threshold: u64) -> bool {
        return x >= threshold;
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // EXAMPLE 1: Create Sample Data (Alice's Contribution)
    // ═══════════════════════════════════════════════════════════════════════
    //
    // Alice has current stock price data:
    //   - Price: $1.50 (1,500,000 in fixed-point)
    //   - Quality: 90% confidence in data source (900,000)
    //   - Category: 1 (Stocks)
    //
    // This transition creates a private ProphecyData record owned by the caller.
    //
    // USAGE:
    //   leo run create_sample_data
    //
    // OUTPUT:
    //   ProphecyData record (encrypted, only caller can see payload)
    //
    transition create_sample_data() -> ProphecyData {
        return ProphecyData {
            owner: self.caller,
            payload: 1500000u64,        // $1.50 current price
            category: 1u8,              // Stocks category
            quality_score: 900000u64,   // 90% quality
            timestamp: 0u32,            // Placeholder timestamp
            _nonce: group::GEN,         // Privacy nonce
        };
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // EXAMPLE 2: Create Sample Model (Bob's Contribution)
    // ═══════════════════════════════════════════════════════════════════════
    //
    // Bob has a trained ML model for stock predictions:
    //   - Weights: [0.6, 0.1, 0.2, 0.1] (emphasis on current price)
    //   - Bias: 0.1 (small positive bias)
    //   - Threshold: 1.0 (decision boundary)
    //   - Algorithm: 2 (Logistic Regression)
    //   - Performance: 88% historical accuracy
    //
    // This transition creates a private OracleModel record owned by the caller.
    //
    // USAGE:
    //   leo run create_sample_model
    //
    // OUTPUT:
    //   OracleModel record (encrypted, only caller can see weights)
    //
    transition create_sample_model() -> OracleModel {
        return OracleModel {
            owner: self.caller,
            weights: [
                600000u64,   // 0.6 weight on price
                100000u64,   // 0.1 weight on quality
                200000u64,   // 0.2 weight on constant
                100000u64    // 0.1 weight on constant
            ],
            bias: 100000u64,             // 0.1 bias
            algorithm_id: 2u8,           // Logistic Regression
            threshold: 1000000u64,       // 1.0 threshold
            performance_score: 880000u64, // 88% accuracy
            _nonce: group::GEN,
        };
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // EXAMPLE 3: Make Prediction (The Magic Happens Here)
    // ═══════════════════════════════════════════════════════════════════════
    //
    // This is the core zero-knowledge inference transition.
    // It takes Alice's private data and Bob's private model, runs ML inference
    // inside a ZK proof, and produces a public prediction signal.
    //
    // WHAT HAPPENS:
    //   1. Data and model records are validated (category match)
    //   2. Feature vector is constructed: [price, quality, 1.0, 0.5]
    //   3. ML inference: score = weights · features + bias
    //   4. Activation: direction = (score >= threshold)
    //   5. Confidence: |score - threshold| / threshold
    //   6. Public signal is created and returned
    //
    // PRIVACY GUARANTEES:
    //   ✅ Alice's price data (1.50) remains encrypted
    //   ✅ Bob's model weights remain encrypted
    //   ✅ Only the prediction direction and confidence are public
    //   ✅ ZK proof verifies correct computation
    //
    // EXPECTED OUTPUT (for this example):
    //   - features = [1.5, 0.9, 1.0, 0.5]
    //   - score = 0.6×1.5 + 0.1×0.9 + 0.2×1.0 + 0.1×0.5 + 0.1 = 1.34
    //   - direction = 1.34 >= 1.0 = true (BULLISH ↗)
    //   - confidence = |1.34 - 1.0| / 1.0 = 0.34 = 34%
    //
    // USAGE:
    //   leo run make_prediction <data_record> <model_record>
    //
    // OUTPUT:
    //   (ProphecyData, OracleModel, public ProphecySignal)
    //   - Records returned to owners (prevents burning)
    //   - Signal is public and visible on-chain
    //
    transition make_prediction(
        data: ProphecyData,
        model: OracleModel
    ) -> (ProphecyData, OracleModel, public ProphecySignal) {
        
        // Validate: data and model must be same category
        assert_eq(data.category, model.category);
        
        // Feature engineering
        let features: [u64; 4] = [
            data.payload,
            data.quality_score,
            1000000u64,
            500000u64
        ];
        
        // ML inference
        let mut score: u64 = weighted_sum(model.weights, features);
        score = fixed_add(score, model.bias);
        
        // Activation
        let direction: bool = relu_activation(score, model.threshold);
        
        // Confidence calculation
        let raw_confidence: u64 = if score >= model.threshold {
            score - model.threshold
        } else {
            model.threshold - score
        };
        
        let mut confidence: u64 = 0u64;
        if model.threshold > 0u64 {
            let conf_scaled: u128 = (raw_confidence as u128) * (SCALE as u128);
            confidence = (conf_scaled / (model.threshold as u128)) as u64;
            if confidence > SCALE {
                confidence = SCALE;
            }
        } else {
            confidence = SCALE;
        }
        
        // Create public signal
        let signal: ProphecySignal = ProphecySignal {
            predictor: self.caller,
            direction: direction,
            confidence: confidence,
            timestamp: 0u32,
            category: data.category
        };
        
        return (data, model, signal);
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // EXAMPLE 4: Complete Workflow (All Steps Combined)
    // ═══════════════════════════════════════════════════════════════════════
    //
    // This transition demonstrates the complete PROPHETIA workflow:
    //   1. Create sample data
    //   2. Create sample model
    //   3. Make prediction
    //   4. Return public signal
    //
    // This is a simplified version for demonstration. In production:
    //   - Data and models would be created by different users
    //   - Records would be stored and reused
    //   - Multiple predictions would be made from same records
    //
    // USAGE:
    //   leo run example_prediction_workflow
    //
    // OUTPUT:
    //   public ProphecySignal showing prediction result
    //
    transition example_prediction_workflow() -> public ProphecySignal {
        
        // Step 1: Create sample data (Alice's contribution)
        let data: ProphecyData = ProphecyData {
            owner: self.caller,
            payload: 1500000u64,
            category: 1u8,
            quality_score: 900000u64,
            timestamp: 0u32,
            _nonce: group::GEN,
        };
        
        // Step 2: Create sample model (Bob's contribution)
        let model: OracleModel = OracleModel {
            owner: self.caller,
            weights: [600000u64, 100000u64, 200000u64, 100000u64],
            bias: 100000u64,
            algorithm_id: 2u8,
            threshold: 1000000u64,
            performance_score: 880000u64,
            _nonce: group::GEN,
        };
        
        // Step 3: Feature engineering
        let features: [u64; 4] = [
            data.payload,
            data.quality_score,
            1000000u64,
            500000u64
        ];
        
        // Step 4: ML inference
        let mut score: u64 = weighted_sum(model.weights, features);
        score = fixed_add(score, model.bias);
        
        // Step 5: Activation
        let direction: bool = relu_activation(score, model.threshold);
        
        // Step 6: Confidence calculation
        let raw_confidence: u64 = if score >= model.threshold {
            score - model.threshold
        } else {
            model.threshold - score
        };
        
        let mut confidence: u64 = 0u64;
        if model.threshold > 0u64 {
            let conf_scaled: u128 = (raw_confidence as u128) * (SCALE as u128);
            confidence = (conf_scaled / (model.threshold as u128)) as u64;
            if confidence > SCALE {
                confidence = SCALE;
            }
        } else {
            confidence = SCALE;
        }
        
        // Step 7: Create and return public signal
        let signal: ProphecySignal = ProphecySignal {
            predictor: self.caller,
            direction: direction,
            confidence: confidence,
            timestamp: 0u32,
            category: data.category
        };
        
        return signal;
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// USAGE INSTRUCTIONS
// ═══════════════════════════════════════════════════════════════════════════
//
// 1. DEPLOY TO TESTNET:
//    cd examples
//    leo build
//    leo deploy --network testnet3
//
// 2. CREATE SAMPLE DATA (Alice):
//    leo run create_sample_data
//    Save the output record (you'll need it for step 4)
//
// 3. CREATE SAMPLE MODEL (Bob):
//    leo run create_sample_model
//    Save the output record (you'll need it for step 4)
//
// 4. MAKE PREDICTION (Anyone):
//    leo run make_prediction <data_record> <model_record>
//    Observe the public ProphecySignal output
//
// 5. COMPLETE WORKFLOW (All-in-one):
//    leo run example_prediction_workflow
//    See the entire process in one transaction
//
// ═══════════════════════════════════════════════════════════════════════════
// EXPECTED OUTPUT
// ═══════════════════════════════════════════════════════════════════════════
//
// When you run example_prediction_workflow, you should see:
//
// {
//   "predictor": "aleo1...",    // Your address
//   "direction": true,           // BULLISH (stock price expected to rise)
//   "confidence": 340000,        // 34% confidence
//   "timestamp": 0,              // Placeholder
//   "category": 1                // Stocks
// }
//
// INTERPRETATION:
//   - The model predicts the stock will go UP (direction = true)
//   - With moderate confidence of 34%
//   - Based on current price of $1.50 and 90% quality data
//
// PRIVACY NOTE:
//   - The blockchain shows: "Stock will rise with 34% confidence"
//   - The blockchain DOES NOT show: $1.50 price, 90% quality, or model weights
//   - This is the power of zero-knowledge ML!
//
// ═══════════════════════════════════════════════════════════════════════════
