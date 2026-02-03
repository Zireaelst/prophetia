# 🚀 PROPHETIA Mainnet Deployment Guide
**Production Deployment Checklist & Procedures**

---

## 📋 Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Security Fixes](#security-fixes)
3. [Testing Validation](#testing-validation)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment Monitoring](#post-deployment-monitoring)
6. [Rollback Procedures](#rollback-procedures)
7. [Emergency Response](#emergency-response)

---

## ✅ Pre-Deployment Checklist

### Code Quality Requirements

- [ ] **All tests passing**
  - [ ] Unit tests: 35+ tests passing
  - [ ] Stress tests: 8 scenarios, 7,000+ operations
  - [ ] Integration tests: 7 workflows, 100% coverage
  - [ ] Frontend tests: 19 security scenarios
  - [ ] **Total:** 69+ tests passing

- [ ] **Code coverage metrics**
  - [ ] Overall: >85% coverage
  - [ ] Critical paths: 100% coverage
  - [ ] Edge cases: >90% coverage

- [ ] **Security requirements**
  - [ ] Security audit completed (SECURITY_AUDIT.md)
  - [ ] All critical issues resolved (0 remaining)
  - [ ] All high priority issues resolved (0 remaining)
  - [ ] Medium priority fixes implemented (3 total)
  - [ ] ZK-proof verification tested

- [ ] **Documentation complete**
  - [ ] ARCHITECTURE.md updated to v1.9
  - [ ] API documentation finalized
  - [ ] User guides for all personas
  - [ ] Deployment procedures documented
  - [ ] Troubleshooting guides created

### Infrastructure Requirements

- [ ] **Testnet validation**
  - [ ] All 7 contracts deployed to testnet
  - [ ] Integration tests run against testnet
  - [ ] 24+ hours of testnet operation
  - [ ] No critical issues discovered
  - [ ] Gas costs verified on testnet

- [ ] **Monitoring setup**
  - [ ] Dashboard configured
  - [ ] Alerting rules defined
  - [ ] On-call rotation established
  - [ ] Incident response plan documented
  - [ ] Communication channels ready

- [ ] **Team readiness**
  - [ ] Deployment team identified
  - [ ] Roles and responsibilities assigned
  - [ ] Communication plan established
  - [ ] Rollback procedures reviewed
  - [ ] Emergency contacts confirmed

---

## 🔧 Security Fixes

### Priority 1: Quality Score Validation

**Issue:** Missing validation for quality_score range (0-100)

**File:** `contracts/data_records/src/main.leo`

**Current Code (Lines ~30-45):**
```leo
transition upload_data_record(
    public file_hash: field,
    public category: field,
    public quality_score: u64,
) -> DataRecord {
    // ❌ Missing validation
    return DataRecord {
        owner: self.caller,
        file_hash,
        category,
        quality_score,
        timestamp: block.height,
    };
}
```

**Fixed Code:**
```leo
transition upload_data_record(
    public file_hash: field,
    public category: field,
    public quality_score: u64,
) -> DataRecord {
    // ✅ Add validation
    assert(quality_score <= 100u64);
    
    return DataRecord {
        owner: self.caller,
        file_hash,
        category,
        quality_score,
        timestamp: block.height,
    };
}
```

**Testing:**
```bash
# Test valid scores
leo run upload_data_record <hash> <category> 50u64  # Should succeed
leo run upload_data_record <hash> <category> 100u64 # Should succeed

# Test invalid scores
leo run upload_data_record <hash> <category> 101u64 # Should fail
leo run upload_data_record <hash> <category> 255u64 # Should fail
```

---

### Priority 2: Division by Zero Protection

**Issue:** Missing zero-check in calculate_share_price()

**File:** `contracts/liquidity_pool/src/main.leo`

**Current Code (Lines ~120-135):**
```leo
function calculate_share_price(pool: Pool) -> u64 {
    // ❌ Crashes if pool.total_shares == 0
    return pool.total_liquidity * SCALE / pool.total_shares;
}
```

**Fixed Code:**
```leo
function calculate_share_price(pool: Pool) -> u64 {
    // ✅ Add zero-check
    if pool.total_shares == 0u64 {
        return SCALE;  // 1:1 ratio for first deposit
    }
    return pool.total_liquidity * SCALE / pool.total_shares;
}
```

**Testing:**
```bash
# Test empty pool
leo run calculate_share_price <empty_pool>  # Should return SCALE (1000000)

# Test pool with shares
leo run calculate_share_price <pool_with_shares>  # Should calculate correctly
```

---

### Priority 3: Double Distribution Prevention

**Issue:** No flag to prevent distributing profit twice

**File:** `contracts/profit_distribution/src/main.leo`

**Current Record (Lines ~15-25):**
```leo
record BetResult {
    owner: address,
    prediction_id: field,
    actual_value: u64,
    predicted_value: u64,
    profit: u64,
    // ❌ Missing distributed flag
}
```

**Fixed Record:**
```leo
record BetResult {
    owner: address,
    prediction_id: field,
    actual_value: u64,
    predicted_value: u64,
    profit: u64,
    distributed: bool,  // ✅ Add flag
}
```

**Current Transition (Lines ~80-100):**
```leo
transition distribute_profit(
    bet_result: BetResult,
    data_provider: address,
    model_creator: address,
) -> (TokenRecord, TokenRecord, TokenRecord) {
    // ❌ No check for already distributed
    
    let provider_share = bet_result.profit * 400u64 / 1000u64;
    let creator_share = bet_result.profit * 400u64 / 1000u64;
    let pool_share = bet_result.profit * 200u64 / 1000u64;
    
    // ... create records
}
```

**Fixed Transition:**
```leo
transition distribute_profit(
    bet_result: BetResult,
    data_provider: address,
    model_creator: address,
) -> (BetResult, TokenRecord, TokenRecord, TokenRecord) {
    // ✅ Check distribution flag
    assert(!bet_result.distributed);
    
    let provider_share = bet_result.profit * 400u64 / 1000u64;
    let creator_share = bet_result.profit * 400u64 / 1000u64;
    let pool_share = bet_result.profit * 200u64 / 1000u64;
    
    // Create updated bet result with flag set
    let updated_result = BetResult {
        owner: bet_result.owner,
        prediction_id: bet_result.prediction_id,
        actual_value: bet_result.actual_value,
        predicted_value: bet_result.predicted_value,
        profit: bet_result.profit,
        distributed: true,  // ✅ Mark as distributed
    };
    
    // ... create token records
    
    return (updated_result, provider_record, creator_record, pool_record);
}
```

**Testing:**
```bash
# Test first distribution
leo run distribute_profit <bet_result> <provider> <creator>  # Should succeed

# Test double distribution
leo run distribute_profit <used_result> <provider> <creator>  # Should fail
```

---

## 🧪 Testing Validation

### Unit Tests

```bash
cd contracts
leo test

# Expected output:
Running 35+ tests...
✅ test_data_upload_valid
✅ test_quality_score_validation  # New test for fix #1
✅ test_model_deployment
✅ test_linear_prediction
✅ test_logistic_prediction
✅ test_decision_tree_prediction
✅ test_pool_deposit
✅ test_share_price_calculation  # Updated for fix #2
✅ test_profit_distribution
✅ test_double_distribution_prevention  # New test for fix #3
...

All tests passed! (35/35)
```

### Stress Tests

```bash
cd tests/stress
python test_stress.py

# Expected output:
🧪 PROPHETIA Stress Testing Suite
================================================================================

Test 1: Mass Data Uploads
  ✅ 1000 operations, 95.2% success, 10.5s
  
Test 2: Concurrent Model Deployments
  ✅ 100 operations, 98.0% success, 5.2s
  
Test 3: Prediction Throughput
  ✅ 5000 operations, 96.1% success, 102.3s

...

📊 SUMMARY
  Total tests: 8
  Passed: 8 ✅
  Failed: 0 ❌
  Success rate: 100%
```

### Integration Tests

```bash
cd tests/integration
python test_integration.py

# Expected output:
🔗 PROPHETIA Integration Testing Suite
================================================================================

Test 1: Full Prediction Workflow
  ✅ TEST PASSED (0.05s)
  
Test 2: Multi-User Pool Workflow
  ✅ TEST PASSED (0.08s)

...

Overall Results:
  Total tests:   7
  Passed:        7 ✅
  Failed:        0 ❌
  Success rate:  100.0%
```

### Frontend Security Tests

```bash
cd tests/frontend
npm test security.spec.ts

# Expected output:
 PASS  tests/frontend/security.spec.ts
  Frontend Security Tests
    ✓ XSS Prevention (3 tests)
    ✓ Input Validation (4 tests)
    ✓ Wallet Security (4 tests)
    ✓ CSRF Protection (2 tests)
    ✓ Rate Limiting (2 tests)
    ✓ CSP (2 tests)
    ✓ Sensitive Data (2 tests)

Test Suites: 1 passed, 1 total
Tests:       19 passed, 19 total
```

---

## 🚢 Deployment Steps

### Phase 1: Testnet Deployment

#### Step 1: Environment Setup

```bash
# Set environment variables
export ALEO_NETWORK="testnet3"
export ALEO_PRIVATE_KEY="<your-testnet-private-key>"

# Verify Leo installation
leo --version  # Should be v1.9.0+

# Verify Aleo wallet
aleo account new  # Generate testnet account if needed
```

#### Step 2: Build All Contracts

```bash
cd contracts

# Build data_records
cd data_records
leo build
cd ..

# Build ml_models
cd ml_models
leo build
cd ..

# Build inference_engine
cd inference_engine
leo build
cd ..

# Build liquidity_pool
cd liquidity_pool
leo build
cd ..

# Build betting_logic
cd betting_logic
leo build
cd ..

# Build profit_distribution
cd profit_distribution
leo build
cd ..

# Build reputation_system
cd reputation_system
leo build
cd ..

# Verify all builds successful
echo "✅ All contracts built successfully"
```

#### Step 3: Deploy to Testnet

```bash
# Deploy contracts in dependency order

# 1. Data Records (no dependencies)
cd data_records
leo deploy --network testnet3
export DATA_RECORDS_ADDRESS="<deployed-address>"
cd ..

# 2. ML Models (depends on data_records)
cd ml_models
leo deploy --network testnet3
export ML_MODELS_ADDRESS="<deployed-address>"
cd ..

# 3. Inference Engine (depends on ml_models, data_records)
cd inference_engine
leo deploy --network testnet3
export INFERENCE_ENGINE_ADDRESS="<deployed-address>"
cd ..

# 4. Liquidity Pool (standalone)
cd liquidity_pool
leo deploy --network testnet3
export LIQUIDITY_POOL_ADDRESS="<deployed-address>"
cd ..

# 5. Betting Logic (depends on inference_engine, liquidity_pool)
cd betting_logic
leo deploy --network testnet3
export BETTING_LOGIC_ADDRESS="<deployed-address>"
cd ..

# 6. Profit Distribution (depends on betting_logic)
cd profit_distribution
leo deploy --network testnet3
export PROFIT_DISTRIBUTION_ADDRESS="<deployed-address>"
cd ..

# 7. Reputation System (depends on profit_distribution)
cd reputation_system
leo deploy --network testnet3
export REPUTATION_SYSTEM_ADDRESS="<deployed-address>"
cd ..

# Save addresses to file
cat > deployed_addresses.txt << EOF
DATA_RECORDS=$DATA_RECORDS_ADDRESS
ML_MODELS=$ML_MODELS_ADDRESS
INFERENCE_ENGINE=$INFERENCE_ENGINE_ADDRESS
LIQUIDITY_POOL=$LIQUIDITY_POOL_ADDRESS
BETTING_LOGIC=$BETTING_LOGIC_ADDRESS
PROFIT_DISTRIBUTION=$PROFIT_DISTRIBUTION_ADDRESS
REPUTATION_SYSTEM=$REPUTATION_SYSTEM_ADDRESS
EOF

echo "✅ All contracts deployed to testnet"
```

#### Step 4: Verify Deployments

```bash
# Verify each contract on Aleo Explorer
open "https://explorer.aleo.org/program/${DATA_RECORDS_ADDRESS}"
open "https://explorer.aleo.org/program/${ML_MODELS_ADDRESS}"
open "https://explorer.aleo.org/program/${INFERENCE_ENGINE_ADDRESS}"
open "https://explorer.aleo.org/program/${LIQUIDITY_POOL_ADDRESS}"
open "https://explorer.aleo.org/program/${BETTING_LOGIC_ADDRESS}"
open "https://explorer.aleo.org/program/${PROFIT_DISTRIBUTION_ADDRESS}"
open "https://explorer.aleo.org/program/${REPUTATION_SYSTEM_ADDRESS}"

# Verify contract code matches source
# Manual verification on explorer
```

#### Step 5: Test Contracts on Testnet

```bash
# Test with small amounts

# 1. Upload test data
leo run upload_data_record \
  <test_hash> \
  <test_category> \
  85u64 \
  --network testnet3

# 2. Deploy test model
leo run deploy_model \
  <model_id> \
  <algorithm> \
  <weights> \
  <bias> \
  --network testnet3

# 3. Run test prediction
leo run predict \
  <model_id> \
  <features> \
  --network testnet3

# 4. Test pool deposit (small amount)
leo run deposit \
  100u64 \
  --network testnet3

# 5. Monitor for 24 hours
# Check for unexpected behavior, errors, gas issues
```

---

### Phase 2: Mainnet Deployment

#### Pre-Mainnet Checklist

- [ ] Testnet deployed and tested for 24+ hours
- [ ] All integration tests pass against testnet
- [ ] Gas costs verified and acceptable
- [ ] No critical issues discovered
- [ ] Team approval for mainnet deployment
- [ ] Communication plan ready (announcements, social media)

#### Step 1: Mainnet Environment

```bash
# Switch to mainnet
export ALEO_NETWORK="mainnet"
export ALEO_PRIVATE_KEY="<your-mainnet-private-key>"

# ⚠️ CAUTION: Real funds on mainnet!
# Double-check private key security
# Verify sufficient balance for deployment
```

#### Step 2: Deploy to Mainnet

```bash
# Follow same deployment order as testnet
# Deploy contracts one at a time, verify each

cd contracts/data_records
leo deploy --network mainnet
# ⏳ Wait for confirmation
# ✅ Verify on explorer

cd ../ml_models
leo deploy --network mainnet
# ⏳ Wait for confirmation
# ✅ Verify on explorer

# ... repeat for all 7 contracts

# Save mainnet addresses
cat > mainnet_addresses.txt << EOF
DATA_RECORDS=<mainnet-address>
ML_MODELS=<mainnet-address>
INFERENCE_ENGINE=<mainnet-address>
LIQUIDITY_POOL=<mainnet-address>
BETTING_LOGIC=<mainnet-address>
PROFIT_DISTRIBUTION=<mainnet-address>
REPUTATION_SYSTEM=<mainnet-address>
EOF
```

#### Step 3: Gradual Rollout

```bash
# Phase 1: Limited Access (Week 1)
# - Whitelist first 10 users
# - Low deposit limits (max 1000 tokens)
# - Monitor closely

# Phase 2: Beta Access (Week 2-4)
# - Expand to 100 users
# - Increase limits (max 10,000 tokens)
# - Gather feedback

# Phase 3: Public Launch (Week 5+)
# - Open to all users
# - Full limits
# - Marketing push
```

---

## 📊 Post-Deployment Monitoring

### Monitoring Dashboard

**Metrics to Track:**

1. **Transaction Metrics**
   - Total transactions per hour
   - Success rate (target: >95%)
   - Average gas cost per operation
   - Failed transaction rate (alert if >5%)

2. **Contract Usage**
   - Data uploads per hour
   - Model deployments per day
   - Predictions per hour
   - Active users

3. **Economic Metrics**
   - Total liquidity in pool
   - Average bet size
   - Win rate
   - Profit distribution totals

4. **Performance Metrics**
   - Transaction confirmation time
   - API response time (target: <2s)
   - Error rates by endpoint
   - Peak gas usage (alert if >150K)

### Alerting Rules

**🟢 GREEN (Normal Operation)**
- Success rate: >95%
- Gas usage: <100K credits
- Error rate: <1%
- Response time: <2s

**🟡 YELLOW (Investigation Needed)**
- Success rate: 90-95%
- Gas usage: 100-150K credits
- Error rate: 1-5%
- Response time: 2-5s
- **Action:** Monitor closely, investigate if persists >1 hour

**🔴 RED (Immediate Action Required)**
- Success rate: <90%
- Gas usage: >150K credits
- Error rate: >5%
- Response time: >5s
- **Action:** Page on-call, investigate immediately

### Daily Checks

**First Week (Days 1-7):**
- [ ] Check dashboard every 4 hours
- [ ] Review all error logs
- [ ] Verify no critical alerts
- [ ] Monitor user feedback
- [ ] Check gas costs vs estimates

**First Month (Days 8-30):**
- [ ] Check dashboard daily
- [ ] Weekly review of metrics
- [ ] User feedback sessions
- [ ] Performance optimization reviews
- [ ] Security review

**Ongoing (Day 31+):**
- [ ] Weekly dashboard reviews
- [ ] Monthly performance reports
- [ ] Quarterly security audits
- [ ] Continuous optimization

---

## 🔄 Rollback Procedures

### When to Rollback

**Immediate Rollback Required:**
- Critical security vulnerability discovered
- >10% transaction failure rate for >1 hour
- Funds at risk
- Contract exploit detected

**Consider Rollback:**
- Gas costs significantly higher than expected
- Poor user experience (>50% negative feedback)
- Unexpected contract behavior

### Rollback Steps

#### Option 1: Pause Contracts (Preferred)

```leo
// If pause functionality exists
transition pause_contract() {
    assert(self.caller == owner);
    self.paused = true;
}

// Execute pause
leo run pause_contract --network mainnet
```

#### Option 2: Frontend Disable

```bash
# Disable frontend access
# Update ENABLE_TRANSACTIONS=false
# Deploy updated frontend
# Investigate issue offline
```

#### Option 3: New Contract Version

```bash
# Deploy fixed version
cd contracts/fixed_contract
leo deploy --network mainnet

# Update frontend to use new address
# Migrate user funds if necessary
# Deprecate old contract
```

### Communication During Rollback

```
🚨 PROPHETIA Status Update

We've temporarily paused contract operations while we investigate [issue].

Your funds are safe and secured by Aleo's cryptography.

Expected resolution: [timeframe]
Updates will be posted every [frequency]

Follow for updates: [Twitter/Discord links]
```

---

## 🚨 Emergency Response

### Emergency Contacts

**On-Call Rotation:**
- Primary: [Name] - [Phone] - [Signal/Telegram]
- Secondary: [Name] - [Phone] - [Signal/Telegram]
- Escalation: [Name] - [Phone] - [Signal/Telegram]

**Communication Channels:**
- Internal: Slack #prophetia-ops
- Public: Twitter @prophetia_aleo
- Community: Discord #status-updates

### Incident Response Playbook

#### Step 1: Detection (0-5 minutes)
- [ ] Alert triggered or issue reported
- [ ] Acknowledge alert
- [ ] Assess severity (P0/P1/P2/P3)
- [ ] Page on-call engineer

#### Step 2: Assessment (5-15 minutes)
- [ ] Gather initial data
  - Error logs
  - Transaction failures
  - User reports
  - Dashboard metrics
- [ ] Determine impact
  - Number of users affected
  - Funds at risk
  - Service availability
- [ ] Classify incident
  - P0: Critical (funds at risk, major exploit)
  - P1: High (>10% failure rate)
  - P2: Medium (degraded performance)
  - P3: Low (minor issues)

#### Step 3: Containment (15-30 minutes)
- [ ] **P0/P1:** Execute rollback/pause immediately
- [ ] **P2:** Monitor and prepare fixes
- [ ] **P3:** Schedule fix for next deployment
- [ ] Post initial status update
- [ ] Assemble incident response team

#### Step 4: Investigation (30 minutes - 2 hours)
- [ ] Root cause analysis
- [ ] Review contract code
- [ ] Analyze transaction history
- [ ] Check for exploits/attacks
- [ ] Document findings

#### Step 5: Resolution (2-24 hours)
- [ ] Develop fix
- [ ] Test fix thoroughly
- [ ] Deploy fix (testnet first)
- [ ] Validate resolution
- [ ] Re-enable services

#### Step 6: Post-Mortem (Within 48 hours)
- [ ] Write incident report
  - Timeline of events
  - Root cause
  - Impact assessment
  - Resolution steps
  - Lessons learned
- [ ] Share with team
- [ ] Update procedures
- [ ] Implement preventive measures

### Incident Severity Matrix

| Severity | Description | Response Time | Example |
|----------|-------------|---------------|---------|
| P0 | Critical | <5 min | Funds at risk, contract exploit |
| P1 | High | <15 min | >10% failure rate, service down |
| P2 | Medium | <1 hour | Degraded performance, high latency |
| P3 | Low | <24 hours | Minor bugs, cosmetic issues |

---

## 📝 Deployment Log Template

```markdown
# PROPHETIA Deployment Log

**Date:** YYYY-MM-DD
**Network:** Testnet3 / Mainnet
**Deployer:** [Name]
**Version:** v1.0.0

## Pre-Deployment Checklist
- [ ] All tests passing (69+ tests)
- [ ] Security fixes implemented (3 fixes)
- [ ] Documentation updated
- [ ] Team approval received

## Deployment Timeline

### Contract 1: data_records
- **Time:** HH:MM:SS UTC
- **Address:** aleo1xxx...
- **Gas Used:** XXX credits
- **Status:** ✅ SUCCESS / ❌ FAILED
- **Notes:** [Any issues or observations]

### Contract 2: ml_models
- **Time:** HH:MM:SS UTC
- **Address:** aleo1yyy...
- **Gas Used:** XXX credits
- **Status:** ✅ SUCCESS / ❌ FAILED
- **Notes:** [Any issues or observations]

... [repeat for all 7 contracts]

## Post-Deployment Verification
- [ ] All contracts visible on explorer
- [ ] Integration tests passed
- [ ] Gas costs within estimates
- [ ] No critical errors in logs
- [ ] Monitoring dashboard operational

## Issues Encountered
[List any issues and resolutions]

## Next Steps
- [ ] Monitor for 24 hours
- [ ] Announce deployment
- [ ] Enable gradual rollout
- [ ] Schedule team retrospective

**Deployment Status:** ✅ COMPLETE / ⚠️ PARTIAL / ❌ FAILED
```

---

## ✅ Final Checklist

### Before Going Live

- [ ] **All security fixes implemented**
  - [ ] Quality score validation
  - [ ] Division by zero protection
  - [ ] Double distribution prevention

- [ ] **All tests passing**
  - [ ] Unit tests (35+)
  - [ ] Stress tests (8 scenarios)
  - [ ] Integration tests (7 workflows)
  - [ ] Frontend tests (19 scenarios)

- [ ] **Testnet validated**
  - [ ] 24+ hours operation
  - [ ] No critical issues
  - [ ] Gas costs acceptable

- [ ] **Monitoring ready**
  - [ ] Dashboard configured
  - [ ] Alerts set up
  - [ ] On-call rotation scheduled

- [ ] **Communication ready**
  - [ ] Announcement prepared
  - [ ] Social media scheduled
  - [ ] Community informed

- [ ] **Team ready**
  - [ ] Roles assigned
  - [ ] Procedures reviewed
  - [ ] Emergency contacts confirmed

### Launch Day

- [ ] Deploy to mainnet
- [ ] Verify all contracts
- [ ] Enable monitoring
- [ ] Post announcement
- [ ] Monitor closely (first 4 hours)
- [ ] Team retrospective

---

**🎉 Ready for Launch!**

*"In code we trust. In privacy we believe. In the future we launch."*

