// PROPHETIA Models Module
// Manages zero-knowledge machine learning models for predictions
// Models remain private while producing verifiable public predictions

program prophetia.aleo {
    
    // OracleModel: Zero-knowledge ML model record
    // Encapsulates model parameters and metadata in a private record
    // Enables predictions without revealing the model architecture or training data
    record OracleModel {
        // Model owner - typically the data scientist or model trainer
        owner: address,
        
        // Model weights for up to 4 features
        // Each weight scaled by 10^6 for fixed-point arithmetic
        // Example: weight 0.5 → 500000u64
        // Supports linear combinations of input features
        weights: [u64; 4],
        
        // Bias term (intercept) scaled by 10^6
        // Added to weighted sum in prediction calculation
        bias: u64,
        
        // Algorithm identifier
        // 1 = Linear Regression (continuous predictions)
        // 2 = Logistic Regression (binary classification)
        // 3 = Decision Tree (rule-based classification)
        algorithm_id: u8,
        
        // Decision threshold for classification models (scaled by 10^6)
        // For logistic regression: probability threshold
        // For linear regression: value threshold
        threshold: u64,
        
        // Historical performance score (0-1000000)
        // Based on prediction accuracy, precision, recall
        // Used for model selection and weighting in ensembles
        performance_score: u64,
        
        // Unique nonce for record privacy
        _nonce: group,
    }

    // Create a new machine learning model record
    // This is the primary entry point for model creators
    //
    // Parameters:
    //   weights: Array of 4 feature weights (scaled by 10^6)
    //   bias: Model bias/intercept term (scaled by 10^6)
    //   algorithm_id: Type of ML algorithm (1-3)
    //   threshold: Decision boundary for predictions (scaled by 10^6)
    //   performance_score: Model's historical accuracy (0-1000000)
    //
    // Returns:
    //   OracleModel record owned by the caller
    //
    // Privacy guarantees:
    //   - Model parameters hidden in encrypted record
    //   - Only owner can access full model details
    //   - Predictions can be made without revealing weights
    transition create_model(
        weights: [u64; 4],
        bias: u64,
        algorithm_id: u8,
        threshold: u64,
        performance_score: u64
    ) -> OracleModel {
        
        // Validate algorithm ID is within acceptable range
        assert(algorithm_id >= 1u8 && algorithm_id <= 3u8);
        
        // Validate performance score doesn't exceed maximum
        assert(performance_score <= 1000000u64);
        
        // Validate threshold is within reasonable bounds
        assert(threshold <= 10000000u64);
        
        // Create and return the model record
        return OracleModel {
            owner: self.caller,
            weights: weights,
            bias: bias,
            algorithm_id: algorithm_id,
            threshold: threshold,
            performance_score: performance_score,
            _nonce: group::GEN,
        };
    }

    // Transfer model ownership to a new address
    // Enables model trading/licensing in a marketplace
    //
    // Parameters:
    //   model: The OracleModel record to transfer
    //   recipient: Address of the new owner
    //
    // Returns:
    //   OracleModel record with updated owner
    transition transfer_model(
        model: OracleModel,
        recipient: address
    ) -> OracleModel {
        
        return OracleModel {
            owner: recipient,
            weights: model.weights,
            bias: model.bias,
            algorithm_id: model.algorithm_id,
            threshold: model.threshold,
            performance_score: model.performance_score,
            _nonce: group::GEN,
        };
    }

    // Update model performance score based on prediction accuracy
    // Called by the reputation system after prediction validation
    //
    // Parameters:
    //   model: The OracleModel record to update
    //   new_performance_score: Updated accuracy score
    //
    // Returns:
    //   OracleModel record with updated performance score
    transition update_performance(
        model: OracleModel,
        new_performance_score: u64
    ) -> OracleModel {
        
        // Validate new performance score
        assert(new_performance_score <= 1000000u64);
        
        return OracleModel {
            owner: model.owner,
            weights: model.weights,
            bias: model.bias,
            algorithm_id: model.algorithm_id,
            threshold: model.threshold,
            performance_score: new_performance_score,
            _nonce: group::GEN,
        };
    }

    // Make a prediction using the model (linear combination)
    // Computes: prediction = w1*x1 + w2*x2 + w3*x3 + w4*x4 + bias
    // All values are scaled by 10^6 (fixed-point arithmetic)
    //
    // Parameters:
    //   model: The OracleModel to use for prediction
    //   features: Input features [x1, x2, x3, x4] (scaled by 10^6)
    //
    // Returns:
    //   prediction: Computed output value (scaled by 10^6)
    //   updated_model: Original model record returned for chaining
    //
    // Note: Result is divided by 10^6 to maintain scale after multiplication
    transition predict(
        model: OracleModel,
        features: [u64; 4]
    ) -> (u64, OracleModel) {
        
        // Compute weighted sum: Σ(weight_i * feature_i)
        let weighted_sum: u128 = 0u128;
        
        // Add each weighted feature (cast to u128 to prevent overflow)
        weighted_sum += (model.weights[0] as u128) * (features[0] as u128);
        weighted_sum += (model.weights[1] as u128) * (features[1] as u128);
        weighted_sum += (model.weights[2] as u128) * (features[2] as u128);
        weighted_sum += (model.weights[3] as u128) * (features[3] as u128);
        
        // Divide by 10^6 to descale after multiplication
        weighted_sum = weighted_sum / 1000000u128;
        
        // Add bias term
        weighted_sum += model.bias as u128;
        
        // Cast back to u64 (safe if result < 2^64)
        let prediction: u64 = weighted_sum as u64;
        
        // Return prediction and original model
        return (prediction, model);
    }

    // Make a binary classification prediction
    // Returns 1 if prediction > threshold, else 0
    //
    // Parameters:
    //   model: The OracleModel to use
    //   features: Input features (scaled by 10^6)
    //
    // Returns:
    //   classification: Binary result (0 or 1)
    //   updated_model: Original model record
    transition classify(
        model: OracleModel,
        features: [u64; 4]
    ) -> (u8, OracleModel) {
        
        // First compute the continuous prediction
        let weighted_sum: u128 = 0u128;
        weighted_sum += (model.weights[0] as u128) * (features[0] as u128);
        weighted_sum += (model.weights[1] as u128) * (features[1] as u128);
        weighted_sum += (model.weights[2] as u128) * (features[2] as u128);
        weighted_sum += (model.weights[3] as u128) * (features[3] as u128);
        weighted_sum = weighted_sum / 1000000u128;
        weighted_sum += model.bias as u128;
        
        let prediction: u64 = weighted_sum as u64;
        
        // Apply threshold to get binary classification
        let classification: u8 = 0u8;
        if prediction > model.threshold {
            classification = 1u8;
        }
        
        return (classification, model);
    }
}
