# PROPHETIA Deployment Guide

> **Deploy Zero-Knowledge ML to Aleo Testnet**

## Overview

This guide walks through deploying PROPHETIA smart contracts to the Aleo testnet. Follow these steps to get your ZK-ML prediction engine running on-chain.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Building Contracts](#building-contracts)
4. [Local Testing](#local-testing)
5. [Testnet Deployment](#testnet-deployment)
6. [Contract Verification](#contract-verification)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

---

## Prerequisites

### Required Software

| Tool | Version | Purpose |
|------|---------|---------|
| **Leo** | 1.9.0+ | Smart contract compiler |
| **snarkOS** | Latest | Aleo network node |
| **Node.js** | 18+ | For automation scripts |
| **Python** | 3.8+ | For testing suite |
| **Git** | Latest | Version control |

### Install Leo

**macOS/Linux:**
```bash
# Install via official installer
curl -L https://raw.githubusercontent.com/AleoHQ/leo/testnet3/install.sh | sh

# Add to PATH
echo 'export PATH="$HOME/.aleo/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
leo --version
# Expected output: leo 1.9.0
```

**Manual Build (if needed):**
```bash
git clone https://github.com/AleoHQ/leo.git
cd leo
cargo install --path .
```

### Aleo Account Setup

**Generate New Account:**
```bash
leo account new

# Output:
# Private Key: APrivateKey1zkp...
# View Key: AViewKey1...
# Address: aleo1...
```

**⚠️ CRITICAL:** Save your private key securely!
- Store in password manager (1Password, Bitwarden, etc.)
- Never commit to version control
- Never share publicly

**Import Existing Account:**
```bash
# Create .env file in contracts/
cd contracts
touch .env

# Add credentials (NEVER commit this file!)
echo "NETWORK=testnet3" >> .env
echo "PRIVATE_KEY=APrivateKey1zkp..." >> .env
```

**Add to .gitignore:**
```bash
echo ".env" >> .gitignore
```

### Get Testnet Credits

**Option 1: Official Faucet**
```
Visit: https://faucet.aleo.org/
Enter address: aleo1...
Receive: 100 credits (~5 minutes)
```

**Option 2: Community Faucet**
```
Visit: https://faucet.aleohq.com/
Connect wallet
Request credits
```

**Check Balance:**
```bash
leo account balance --address aleo1...
# Expected: 100.0 credits
```

---

## Environment Setup

### 1. Clone Repository

```bash
# Clone PROPHETIA repo
git clone <repository-url>
cd prophetia

# Verify structure
ls -la
# Expected: contracts/, docs/, tests/, scripts/, README.md
```

### 2. Configure Leo Project

```bash
cd contracts

# Verify program.json
cat program.json
```

**Expected `program.json`:**
```json
{
  "program": "prophetia.aleo",
  "version": "0.1.0",
  "description": "Zero-Knowledge ML Prediction Engine",
  "license": "MIT"
}
```

### 3. Install Dependencies

**Python Testing Suite:**
```bash
cd ../tests
pip install -r requirements.txt

# Or manually:
pip install pytest colorama
```

**JavaScript Scripts (if using):**
```bash
cd ../scripts
npm install
```

---

## Building Contracts

### 1. Clean Build

```bash
cd contracts

# Remove previous builds
leo clean

# Build fresh
leo build
```

**Expected Output:**
```
Compiling 'prophetia.aleo'...
 • Compiling main.leo...
 • Compiling data_records.leo...
 • Compiling models.leo...
 • Compiling math_utils.leo...
✅ Built 'prophetia.aleo' into './build'
```

### 2. Verify Build Artifacts

```bash
ls -la build/

# Expected files:
# main.aleo
# program.json
# imports/
```

### 3. Check for Errors

**Common Build Errors:**

**Error:** `unexpected token`
- **Cause:** Syntax error in Leo code
- **Fix:** Check line number, verify semicolons, brackets

**Error:** `type mismatch`
- **Cause:** Incorrect type passed to function
- **Fix:** Verify function signatures, cast types explicitly

**Error:** `import not found`
- **Cause:** Missing dependency
- **Fix:** Check `program.json` imports section

---

## Local Testing

### 1. Python Test Suite (Recommended First)

**Run Math Tests:**
```bash
cd tests
python3 test_math_utils.py
```

**Expected Output:**
```
PROPHETIA - Fixed-Point Math Test Suite
========================================

[to_fixed Tests]
✓ PASS | Convert 0 to fixed-point
✓ PASS | Convert 1 to fixed-point
✓ PASS | Convert 5 to fixed-point
✓ PASS | Convert 100 to fixed-point

[fixed_mul Tests]
✓ PASS | Multiply: 0.5 × 0.5 = 0.25
✓ PASS | Multiply: 1.5 × 2.0 = 3.0
✓ PASS | Multiply: 1.0 × 1.0 = 1.0
✓ PASS | Multiply: 2.5 × 4.0 = 10.0
✓ PASS | Multiply: 0.1 × 0.1 = 0.01

[... 35 tests total ...]

========================================
Total Tests: 35
Passed: 35
Failed: 0
Pass Rate: 100.0%
========================================
```

**If Tests Fail:**
- Review error message
- Check expected vs actual values
- Verify math implementation matches Leo code

### 2. Leo Execution Tests

**Test Individual Transitions:**

```bash
cd contracts

# Test multiplication
leo run test_math_mul
# Expected: 3000000u64 (1.5 × 2.0 = 3.0)

# Test division
leo run test_math_div
# Expected: 1500000u64 (3.0 ÷ 2.0 = 1.5)

# Test weighted sum
leo run test_weighted_sum
# Expected: 2500000u64 (weighted average = 2.5)

# Test activation
leo run test_activation
# Expected: true (1.5 >= 1.0)
```

**Test With Custom Inputs:**

```bash
# Submit data
leo run submit_data 1500000u64 1u8 850000u64

# Register model
leo run register_model \
  "[500000u64, 300000u64, 150000u64, 50000u64]" \
  100000u64 \
  1u8 \
  750000u64 \
  900000u64
```

### 3. Integration Tests (Future: Week 3)

```bash
# Run full test suite
leo test --all

# Run specific test file
leo test --file tests/prediction.leo
```

---

## Testnet Deployment

### 1. Pre-Deployment Checklist

- [ ] All Python tests passing (35/35)
- [ ] All Leo test transitions working
- [ ] `.env` file configured with private key
- [ ] Testnet credits available (check balance)
- [ ] Build artifacts present in `build/`

### 2. Deploy Command

```bash
cd contracts

# Deploy to testnet
leo deploy --network testnet3 --private-key <YOUR_PRIVATE_KEY>
```

**Or using .env:**
```bash
leo deploy --network testnet3
```

**Expected Output:**
```
📦 Deploying 'prophetia.aleo' to testnet3...

⏳ Creating deployment transaction...
✅ Transaction created: at1...

⏳ Broadcasting to network...
✅ Transaction broadcast: at1...

⏳ Waiting for confirmation... (this may take 30-60s)
✅ Program deployed successfully!

Program ID: prophetia.aleo
Transaction ID: at1...
Block Height: 123456
```

### 3. Deployment Script (Automated)

**Use provided script:**
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

**`deploy.sh` contents:**
```bash
#!/bin/bash

# PROPHETIA Deployment Script
echo "🔮 PROPHETIA Deployment to Aleo Testnet"
echo "========================================="

# Check Leo installation
if ! command -v leo &> /dev/null; then
    echo "❌ Leo not found. Install: https://developer.aleo.org/leo/"
    exit 1
fi

# Build contracts
echo "📦 Building contracts..."
cd contracts
leo clean
leo build

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Fix errors and try again."
    exit 1
fi

# Run tests
echo "🧪 Running tests..."
cd ../tests
python3 test_math_utils.py

if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Fix errors and try again."
    exit 1
fi

# Deploy
echo "🚀 Deploying to testnet3..."
cd ../contracts
leo deploy --network testnet3

if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
    echo "📝 Save the Program ID and Transaction ID above."
else
    echo "❌ Deployment failed. Check errors above."
    exit 1
fi
```

### 4. Monitor Deployment

**Check Transaction Status:**
```bash
# Via CLI
leo transaction --id at1...

# Via Explorer
open https://explorer.aleo.org/transaction/at1...
```

**Wait for Confirmation:**
- Testnet block time: ~20-30 seconds
- Confirmations required: 1-3 blocks
- Total wait time: ~1-2 minutes

---

## Contract Verification

### 1. Verify Program Exists

```bash
# Check on-chain program
leo program --name prophetia.aleo --network testnet3

# Expected output:
# Program: prophetia.aleo
# Status: Active
# Block: 123456
# Transitions: submit_data, register_model, make_prediction, ...
```

### 2. Test On-Chain Execution

**Execute Transition:**
```bash
# Call submit_data on deployed contract
leo execute submit_data \
  1500000u64 \
  1u8 \
  850000u64 \
  --network testnet3 \
  --private-key <YOUR_PRIVATE_KEY>
```

**Expected Output:**
```
⏳ Executing 'submit_data'...
✅ Execution successful!

Outputs:
  r0: {
    owner: aleo1...,
    payload: 1500000u64,
    category: 1u8,
    quality_score: 850000u64,
    timestamp: <current_block>,
    _nonce: ...
  }

Transaction ID: at1...
```

### 3. Verify Record Creation

```bash
# Check records for your address
leo records --address aleo1...

# Expected: ProphecyData record
```

### 4. Explorer Verification

**Visit Aleo Explorer:**
```
https://explorer.aleo.org/program/prophetia.aleo
```

**Check:**
- ✅ Program deployed
- ✅ Transitions visible
- ✅ Transaction history
- ✅ Record outputs

---

## Troubleshooting

### Common Deployment Issues

#### Error: "Insufficient Credits"

**Symptom:**
```
Error: Account balance too low
Required: 10 credits
Available: 0 credits
```

**Solutions:**
1. Get testnet credits from faucet
2. Check balance: `leo account balance`
3. Wait for faucet transaction to confirm

#### Error: "Program Already Exists"

**Symptom:**
```
Error: Program 'prophetia.aleo' already deployed
```

**Solutions:**
1. **Option A:** Use existing deployment
2. **Option B:** Change program name in `program.json`:
   ```json
   {
     "program": "prophetia_v2.aleo"
   }
   ```
3. **Option C:** Deploy to different network (mainnet)

#### Error: "Build Failed"

**Symptom:**
```
Error: Compilation failed at line 42
```

**Solutions:**
1. Check syntax errors in Leo files
2. Verify all imports are correct
3. Run `leo check` before building
4. Review error message details

#### Error: "Network Timeout"

**Symptom:**
```
Error: Connection timeout to testnet3
```

**Solutions:**
1. Check internet connection
2. Retry deployment (network congestion)
3. Try different RPC endpoint
4. Wait 5 minutes and retry

#### Error: "Invalid Private Key"

**Symptom:**
```
Error: Private key format invalid
```

**Solutions:**
1. Verify key starts with `APrivateKey1`
2. Check for extra spaces/newlines
3. Regenerate account: `leo account new`
4. Use quotes: `--private-key "APrivateKey1..."`

### Leo CLI Issues

**Leo Command Not Found:**
```bash
# Re-install Leo
curl -L https://raw.githubusercontent.com/AleoHQ/leo/testnet3/install.sh | sh

# Add to PATH
export PATH="$HOME/.aleo/bin:$PATH"

# Verify
which leo
```

**Outdated Leo Version:**
```bash
# Update Leo
leo update

# Or reinstall
rm -rf ~/.aleo
# Then reinstall
```

### Gas & Fee Issues

**Estimate Gas Before Deployment:**
```bash
# Dry run (doesn't broadcast)
leo deploy --dry-run --network testnet3

# Expected: Gas estimate (e.g., 5.0 credits)
```

**If Gas Too High:**
1. Optimize contract code (remove unused functions)
2. Split into multiple programs
3. Use smaller data types (u64 → u32 if possible)
4. Wait for network congestion to clear

---

## Best Practices

### Security

**Private Key Management:**
- ✅ Store in `.env` file (add to `.gitignore`)
- ✅ Use hardware wallet for mainnet
- ✅ Never commit keys to Git
- ❌ Never share keys publicly
- ❌ Don't reuse keys across networks

**Smart Contract Security:**
- ✅ Test thoroughly before deploying
- ✅ Use assertions for input validation
- ✅ Audit code for vulnerabilities
- ✅ Start with testnet (ALWAYS)

### Performance

**Optimize Gas Costs:**
1. Use `inline` functions (reduces call overhead)
2. Minimize record updates (expensive)
3. Batch operations when possible
4. Use u64 instead of u128 when safe

**Circuit Optimization:**
1. Keep models small (4-10 features)
2. Avoid complex loops
3. Use lookup tables for common operations
4. Precompute constants off-chain

### Testing

**Test Pyramid:**
```
            /\
           /  \  E2E Tests (few)
          /----\
         /      \ Integration Tests (some)
        /--------\
       /          \ Unit Tests (many)
      /____________\
```

**Recommended Testing Flow:**
1. Python unit tests (35+ tests)
2. Leo execution tests (6+ transitions)
3. Integration tests (future)
4. Testnet deployment
5. Manual verification

### Documentation

**Document Everything:**
- Deployment dates and transaction IDs
- Program addresses
- Account addresses used
- Gas costs observed
- Any issues encountered

**Example Log:**
```markdown
# Deployment Log - 2026-01-20

## Environment
- Network: testnet3
- Leo Version: 1.9.0
- Account: aleo1abc...

## Deployment
- Build Time: 2m 15s
- Gas Used: 8.5 credits
- Transaction: at1xyz...
- Program ID: prophetia.aleo
- Block: 123456

## Tests
- Python Tests: 35/35 passed
- On-Chain Tests: 6/6 passed

## Notes
- First deployment successful
- All math functions working
- Ready for Week 3 enhancements
```

---

## Next Steps

### After Successful Deployment

1. **Week 3: Advanced ML**
   - Deploy neural network functions
   - Test decision tree inference
   - Benchmark gas costs

2. **Week 4-5: Frontend**
   - Connect web interface to deployed contracts
   - Build user dashboard
   - Implement wallet integration

3. **Week 6-7: Data Pipeline**
   - Set up data collection agents
   - Automate model training
   - Deploy prediction automation

4. **Week 8-9: Economics**
   - Deploy token contracts
   - Implement staking mechanisms
   - Launch reputation system

5. **Week 10-12: Production**
   - Security audit
   - Stress testing
   - Mainnet preparation

### Monitoring & Maintenance

**Set Up Monitoring:**
- Transaction success rate
- Gas cost trends
- Error frequency
- User activity

**Regular Maintenance:**
- Update Leo version
- Review security advisories
- Optimize gas usage
- Upgrade contracts (if needed)

---

## Resources

### Official Documentation
- **Aleo Docs:** https://developer.aleo.org/
- **Leo Language:** https://developer.aleo.org/leo/
- **Leo Examples:** https://github.com/AleoHQ/leo/tree/testnet3/examples

### Community
- **Discord:** https://discord.gg/aleo
- **Forum:** https://forum.aleo.org/
- **GitHub:** https://github.com/AleoHQ

### PROPHETIA Docs
- **Architecture:** `docs/ARCHITECTURE.md`
- **Math Reference:** `docs/MATH_REFERENCE.md`
- **README:** `../README.md`

---

## FAQ

**Q: How long does deployment take?**  
A: 1-3 minutes (build: 30s, broadcast: 30s, confirmation: 1-2 min)

**Q: Can I update deployed contracts?**  
A: No. Leo contracts are immutable. Deploy new version with different name.

**Q: What if testnet resets?**  
A: Save contract code locally. Redeploy after reset (testnet may reset during development).

**Q: How much do deployments cost?**  
A: Testnet: Free (use faucet). Mainnet: 5-20 credits estimated.

**Q: Can I test without deploying?**  
A: Yes! Use `leo run` for local execution without blockchain interaction.

**Q: What's the difference between `leo run` and `leo execute`?**  
A: `run` = local only. `execute` = on-chain transaction.

---

**Document Version:** 1.0 (Week 2)  
**Last Updated:** January 2026  
**Next Update:** Week 3 (Advanced deployment strategies)

---

*"Deploy with confidence. Test with diligence. Build with purpose."*

— PROPHETIA Deployment Team
