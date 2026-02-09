// PROPHETIA Data Records Module
// Manages privacy-preserving data contributions for the oracle network
// Each ProphecyData record represents a single encrypted data point from a provider

program prophetia.aleo {
    
    // ProphecyData: Zero-knowledge record representing a single data contribution
    // All fields are private by default, protecting contributor identity and data values
    record ProphecyData {
        // Data provider's address - only they can spend this record
        owner: address,
        
        // Normalized data value scaled by 10^6 for fixed-point arithmetic
        // Example: 1.234567 → 1234567u64
        // Range: 0 to 18_446_744_073_709 (max u64 / 10^6)
        payload: u64,
        
        // Data category classification
        // 1 = Stock/Equity prices
        // 2 = Weather/Climate data
        // 3 = Commodity prices
        // 4 = Cryptocurrency prices
        category: u8,
        
        // Provider reputation score (0-1000000)
        // Higher scores = more trusted/accurate historical data
        // Used for weighted aggregation in prediction models
        quality_score: u64,
        
        // Unix timestamp (seconds since epoch)
        // Using u32 for dates until year 2106
        timestamp: u32,
        
        // Unique nonce for record privacy
        // Prevents record linkability on-chain

    }

    // Create a new data contribution record
    // This is the primary entry point for data providers to submit information
    // 
    // Parameters:
    //   payload: The normalized data value (scaled by 10^6)
    //   category: Type of data being submitted (1-4)
    //   quality_score: Provider's current reputation score (0-1000000)
    //
    // Returns:
    //   ProphecyData record owned by the caller
    //
    // Privacy guarantees:
    //   - Caller identity hidden via ZK proof
    //   - Data value encrypted in record
    //   - Only owner can access/spend the record
    transition create_data(
        payload: u64,
        category: u8,
        quality_score: u64
    ) -> ProphecyData {
        
        // Validate category is within acceptable range
        assert(category >= 1u8 && category <= 4u8);
        
        // Validate quality score doesn't exceed maximum
        assert(quality_score <= 1000000u64);
        
        // Get current block height as timestamp proxy
        // Note: Leo doesn't have direct timestamp access
        // In production, use block height or external oracle
        let current_time: u32 = 0u32; // Placeholder - will use block.height in actual deployment
        
        // Create and return the data record
        // Owner is automatically set to the transaction caller
        return ProphecyData {
            owner: self.caller,
            payload: payload,
            category: category,
            quality_score: quality_score,
            timestamp: current_time,

        };
    }

    // Transfer data record to a new owner
    // Useful for data marketplaces or delegation scenarios
    //
    // Parameters:
    //   data: The ProphecyData record to transfer
    //   recipient: Address of the new owner
    //
    // Returns:
    //   ProphecyData record with updated owner
    transition transfer_data(
        data: ProphecyData,
        recipient: address
    ) -> ProphecyData {
        
        // Create new record with same data but different owner
        return ProphecyData {
            owner: recipient,
            payload: data.payload,
            category: data.category,
            quality_score: data.quality_score,
            timestamp: data.timestamp,

        };
    }

    // Update quality score of existing data record
    // Called by reputation system to reflect provider performance
    //
    // Parameters:
    //   data: The ProphecyData record to update
    //   new_quality_score: Updated reputation score
    //
    // Returns:
    //   ProphecyData record with updated quality score
    transition update_quality_score(
        data: ProphecyData,
        new_quality_score: u64
    ) -> ProphecyData {
        
        // Validate new quality score
        assert(new_quality_score <= 1000000u64);
        
        // Return updated record
        return ProphecyData {
            owner: data.owner,
            payload: data.payload,
            category: data.category,
            quality_score: new_quality_score,
            timestamp: data.timestamp,

        };
    }
}
