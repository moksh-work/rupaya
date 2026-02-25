# Enterprise Deployment Features: Feature Flags, Canary, Rollback & A/B Testing

This document explains how to use the advanced deployment features for **Rupaya** that enable Netflix/Facebook-grade deployments.

## Table of Contents

1. [Feature Flags](#feature-flags)
2. [Canary Deployments](#canary-deployments)
3. [Automated Rollback](#automated-rollback)
4. [A/B Testing Framework](#ab-testing-framework)
5. [Architecture Overview](#architecture-overview)
6. [API Reference](#api-reference)
7. [Best Practices](#best-practices)

---

## Feature Flags

Feature flags enable runtime control of features without redeployment. Users can enable/disable features, gradually roll out to users, and target specific user groups.

### Types of Feature Flags

#### 1. Boolean Flags
Simple on/off switch for features.

```javascript
// Usage in code
const newDashboardEnabled = await req.evaluateFlag('feature.new-dashboard');

if (newDashboardEnabled.enabled) {
  // Use new dashboard
} else {
  // Use old dashboard
}
```

**Configuration**:
```json
{
  "enabled": false,
  "type": "boolean",
  "description": "Enable new dashboard UI",
  "percentage": 0,
  "targetUsers": [123, 456],
  "environments": {
    "development": { "enabled": true, "percentage": 100 },
    "staging": { "enabled": true, "percentage": 50 },
    "production": { "enabled": false, "percentage": 0 }
  }
}
```

#### 2. Canary Flags
Gradual rollout of features with automatic stage progression.

```javascript
const result = await req.evaluateFlag('canary.new-payment-processor');

if (result.enabled) {
  // Use new payment processor
  // Stage: "1%", "10%", "25%", "50%", "100%"
}
```

**Stages Configuration**:
```json
{
  "stages": [
    { "name": "1%", "percentage": 1, "durationMinutes": 30 },
    { "name": "10%", "percentage": 10, "durationMinutes": 30 },
    { "name": "25%", "percentage": 25, "durationMinutes": 60 },
    { "name": "50%", "percentage": 50, "durationMinutes": 60 },
    { "name": "100%", "percentage": 100, "durationMinutes": 0 }
  ],
  "currentStage": 0
}
```

#### 3. Experiment Flags (A/B Tests)
Split users between variants for testing.

```javascript
const result = await req.evaluateFlag('experiment.new-onboarding');

switch (result.variant) {
  case 'control':
    // Original onboarding flow
    break;
  case 'variant_a':
    // New simplified flow
    break;
}
```

**Variants Configuration**:
```json
{
  "variants": {
    "control": { "percentage": 50, "description": "Original onboarding" },
    "variant_a": { "percentage": 50, "description": "New simplified flow" }
  }
}
```

#### 4. Config Flags
Runtime configuration values.

```javascript
const errorRateThreshold = await req.evaluateFlag('rollback.error-rate-threshold');
// Returns: { enabled: true, value: 5 }
```

### Flag Lifecycle

```
Create → Configure → Test (dev) → Ramp (staging) → Launch (prod) → Monitor → Cleanup
```

### Using Feature Flags in Code

#### Backend (Node.js)

```javascript
// In express route handler
router.get('/api/dashboard', async (req, res) => {
  // Evaluate flag
  const dashboardV2 = await req.evaluateFlag('feature.new-dashboard', {
    segment: req.user?.segment // Optional context
  });

  // Get user data
  const userData = await User.findById(req.user.id);

  // Choose implementation based on flag
  if (dashboardV2.enabled) {
    const newDashboard = await getNewDashboard(userData);
    res.json(newDashboard);
  } else {
    const oldDashboard = await getOldDashboard(userData);
    res.json(oldDashboard);
  }
});
```

#### Frontend (React/Vue)

```javascript
// Flag state in component
const [dashboardV2Enabled, setDashboardV2Enabled] = useState(false);

// Evaluate flag on mount
useEffect(() => {
  const checkFlag = async () => {
    const response = await fetch('/api/feature-flags/feature.new-dashboard');
    const result = await response.json();
    setDashboardV2Enabled(result.enabled);
  };
  checkFlag();
}, []);

// Render based on flag
{dashboardV2Enabled ? <NewDashboard /> : <OldDashboard />}
```

---

## Canary Deployments

Canary deployments minimize risk by gradually rolling out changes to increasing percentages of users.

### Deployment Strategy

```
Initial → 1% (30 min) → 10% (30 min) → 25% (60 min) → 50% (60 min) → 100%
   ↓
Monitor error rates & response times at each stage
   ↓
If metrics bad → Rollback to previous stage
If metrics good → Advance to next stage
```

### Health Thresholds

**Automatic Rollback Triggers**:
- Error rate > 5% (configurable)
- P99 response time > 2000ms (configurable)
- Memory usage spike
- Database connection pool exhaustion

### Monitoring During Canary

The system automatically collects metrics:

```javascript
// Metrics collected per canary stage
{
  "byCanaryStage": {
    "1%": {
      "count": 1000,
      "errors": 8,
      "errorRate": 0.8,
      "avgResponseTime": 145
    },
    "10%": {
      "count": 10000,
      "errors": 200,
      "errorRate": 2.0,
      "avgResponseTime": 156
    }
  }
}
```

### Advancing Stages

**Automatic**:
- Stages advance automatically based on configured duration
- No action needed if metrics are healthy

**Manual**:
```bash
# Using GitHub Actions workflow UI
# Navigate to: Actions → "Manage Feature Flags & Deployment"
# Select: "advance_canary_stage"
# Input: flag_key, environment, reason
```

### Rollback

**Automatic Rollback**:
- Triggered when health thresholds exceeded
- Automatic notification to ops team
- Logged with metrics and reason

**Manual Rollback**:
```bash
# Using GitHub Actions workflow
# Navigate to: Actions → "Manage Feature Flags & Deployment"
# Select: "rollback_canary_stage"
# Input: flag_key, reason
```

---

## Automated Rollback

The system continuously monitors deployment health and automatically rolls back if issues detected.

### Rollback Mechanism

```
While deployment is active:
  Every 10 seconds:
    - Collect request metrics (errors, response time, etc)
    - Compare against thresholds
    - If unhealthy → Trigger rollback
    - Log decision with reason
```

### Health Metrics

**Collected Metrics**:
- Request count
- Error rate (5xx, 4xx)
- P50, P95, P99 response times
- Top error endpoints
- By canary stage
- By experiment variant

**Example Metrics**:
```json
{
  "totalRequests": 5000,
  "totalErrors": 45,
  "errorRate": 0.9,
  "p50ResponseTime": 120,
  "p95ResponseTime": 450,
  "p99ResponseTime": 1200,
  "requestsPerSecond": 83.3,
  "topErrors": [
    { "error": "POST /api/payments - 500", "count": 30 },
    { "error": "GET /api/accounts - 503", "count": 10 }
  ]
}
```

### Rollback Decision Logic

```javascript
// Simplified decision logic
const shouldRollback = 
  (metrics.errorRate > 5) ||           // Error rate threshold
  (metrics.p99ResponseTime > 2000) ||  // Response time threshold
  (metrics.memory > 80%) ||            // Memory pressure
  (metrics.dbConnections > 95%);       // Database saturation

if (shouldRollback) {
  // Trigger rollback to previous version
  // Set canary.current_stage = original_stage
  // Notify ops team
  // Log decision with metrics
}
```

### Monitoring Rollback Events

```bash
# Get rollback decisions
GET /api/admin/deployment/rollback-decisions?limit=10

# Response
{
  "decisions": [
    {
      "id": 123,
      "version": "v1.2.3",
      "decision": "rollback",
      "reason": "Error rate exceeded 5%",
      "metrics": { ... },
      "decidedBy": "auto",
      "timestamp": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

## A/B Testing Framework

Test new features with users split between control and variant groups.

### A/B Test Workflow

```
1. Define hypothesis
2. Create experiment flag with variants
3. Route users to variants (consistent per user)
4. Collect metrics per variant
5. Calculate statistical significance
6. Deploy winner or iterate
```

### Creating A/B Tests

```javascript
// 1. Define flag configuration
{
  "type": "experiment",
  "description": "Test new onboarding flow",
  "variants": {
    "control": { 
      "percentage": 50, 
      "description": "Original onboarding" 
    },
    "variant_a": { 
      "percentage": 50, 
      "description": "New simplified flow" 
    }
  }
}

// 2. Route users to variant
const result = await req.evaluateFlag('experiment.new-onboarding-flow', userId);
const variant = result.variant; // 'control' or 'variant_a'

// 3. Record which variant they're seeing
req.metricsTags = { 
  experimentVariant: variant 
};

// 4. Collect conversion metrics
deploymentMetricsService.recordRequest({
  userId,
  experimentVariant: variant,
  statusCode: 200,
  responseTimeMs: 145
});

// 5. After sufficient time (24h+), analyze results
// GET /api/admin/deployment/experiments/experiment.new-onboarding-flow/results
```

### Analyzing Results

**Statistical Significance Test** (t-test):

```bash
GET /api/admin/deployment/experiments/experiment.new-onboarding-flow/statistical-significance

Response:
{
  "winner": "variant_a",
  "isSignificant": true,
  "confidence": "95.43%",
  "pValue": "0.0234",
  "samples": {
    "control": {
      "count": 5000,
      "mean": 145.2,
      "stdDev": 23.4
    },
    "variant_a": {
      "count": 5000,
      "mean": 138.7,
      "stdDev": 21.1
    }
  }
}
```

### Metrics to Track

```javascript
// Per variant, track:
- Conversion rate (primary metric)
- Error rate
- Response time (P50, P95, P99)
- Session duration
- Bounce rate
- Custom business metrics (revenue, engagement, etc)
```

### Deploying Winning Variant

```bash
# 1. Confirm winner has p-value < 0.05 (95% confidence)
# 2. Set variant percentage to 100% (or rollout gradually)
PUT /api/admin/deployment/feature-flags/experiment.new-onboarding-flow
{
  "variants": {
    "winner": { "percentage": 100 },
    "loser": { "percentage": 0 }
  }
}

# 3. Alternative: Convert to permanent feature flag
# After winner confirmed, deprecate experiment flag
```

---

## Architecture Overview

### Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        Backend Server                            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Feature Flags Service                          │ │
│  │  - Evaluate flags (boolean, canary, experiment, config)    │ │
│  │  - Cache in Redis (5-min TTL)                              │ │
│  │  - Fallback to database or in-memory defaults              │ │
│  │  - Consistent user hashing for variants                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │          Deployment Metrics Service                         │ │
│  │  - Aggregate metrics every 10 seconds                       │ │
│  │  - Store in Redis for 1-hour retention                      │ │
│  │  - Analyze metrics for rollback triggers                    │ │
│  │  - Emit events for significant changes                      │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         ↓ Metrics              ↓ Flags
    ┌────────────────┐    ┌─────────────┐
    │    Redis      │    │ PostgreSQL   │
    │ (Cache, Buf)  │    │ (Persistent) │
    └────────────────┘    └─────────────┘
         ↓ Historical           ↓ via API
    ┌────────────────┐    ┌──────────────────┐
    │ Time-Series DB │    │ GitHub Actions   │
    │ (CloudWatch)   │    │ Workflow (UI)    │
    └────────────────┘    └──────────────────┘
```

### Request Flow with Feature Flags

```
Client Request
       ↓
   Express Route
       ↓
   req.evaluateFlag('flag.key')
       ↓
   FeatureFlagsService.evaluateFlag()
       ├─→ Check Redis cache (→ return if hit)
       ├─→ Check Database (→ cache and return)
       └─→ Use in-memory defaults
       ↓
   Return: { enabled, variant, metadata }
       ↓
   Route handler branches logic
       ↓
   DeploymentMetricsService.recordRequest()
       ├─→ Record in buffer
       ├─→ Tag with variant/canary-stage
       └─→ Re-emit aggregation
       ↓
   Send response
```

---

## API Reference

### Feature Flags

#### Get All Flags
```bash
GET /api/admin/deployment/feature-flags
Authorization: Bearer {ADMIN_TOKEN}

Response:
{
  "success": true,
  "data": {
    "feature.new-dashboard": { ... },
    "canary.new-payment": { ... },
    "experiment.ab-test-1": { ... }
  },
  "count": 15
}
```

#### Get Specific Flag
```bash
GET /api/admin/deployment/feature-flags/{flagKey}
```

#### Update Flag
```bash
PUT /api/admin/deployment/feature-flags/{flagKey}
Content-Type: application/json

Body:
{
  "enabled": true,
  "percentage": 50,
  "targetUsers": [123, 456]
}
```

#### Advance Canary Stage
```bash
POST /api/admin/deployment/feature-flags/{flagKey}/advance-canary
Content-Type: application/json

Body:
{
  "reason": "Metrics look good, advancing to next stage"
}
```

#### Rollback Canary
```bash
POST /api/admin/deployment/feature-flags/{flagKey}/rollback-canary
Content-Type: application/json

Body:
{
  "reason": "Error rate spike detected"
}
```

### Metrics

#### Get Health Status
```bash
GET /api/admin/deployment/metrics/health

Response:
{
  "success": true,
  "data": {
    "status": "healthy",
    "errorRate": 0.5,
    "p99ResponseTime": 1200,
    "requestsPerSecond": 150
  }
}
```

#### Get Metrics Range
```bash
GET /api/admin/deployment/metrics/range?startTime=2024-01-15T00:00:00Z&endTime=2024-01-15T23:59:59Z
```

#### Get Flag Usage Metrics
```bash
GET /api/admin/deployment/metrics/flag-usage

Response:
{
  "checksTotal": 150000,
  "checksPerFlag": {
    "feature.new-dashboard": 45000,
    "canary.payment": 60000
  }
}
```

### Experiments

#### Get Experiment Results
```bash
GET /api/admin/deployment/experiments/{experimentKey}/results?startTime=...&endTime=...

Response:
{
  "experimentKey": "experiment.onboarding-v2",
  "variantResults": {
    "control": {
      "count": 5000,
      "errors": 25,
      "errorRate": 0.5,
      "avgResponseTime": 145
    },
    "variant_a": {
      "count": 5000,
      "errors": 15,
      "errorRate": 0.3,
      "avgResponseTime": 138
    }
  }
}
```

#### Get Statistical Significance
```bash
GET /api/admin/deployment/experiments/{experimentKey}/statistical-significance

Response:
{
  "winner": "variant_a",
  "isSignificant": true,
  "confidence": "95.43%",
  "pValue": "0.0234"
}
```

---

## Best Practices

### Feature Flag Guidelines

1. **Naming Convention**
   ```
   feature.{domain}-{feature-name}     # feature.dashboard-redesign
   canary.{new-system-name}             # canary.payment-processor-v2
   experiment.{test-name}               # experiment.checkout-flow-ab
   rollback.{config-name}               # rollback.error-rate-threshold
   ```

2. **Description**
   - Always include clear description
   - Document decision criteria for rollout

3. **Default Values**
   - Keep disabled in production by default
   - Set conservative default (smaller %)
   - Document why

4. **Targeting**
   ```javascript
   // Target specific users for early testing
   const flag = {
     enabled: true,
     percentage: 10,
     targetUsers: [1001, 1002, 1003] // Force enable for these
   };
   ```

5. **Cleanup**
   - Remove flags 2+ weeks after 100% rollout
   - Archive old experiments in documentation
   - Don't leave dead code branches

### Canary Best Practices

1. **Stage Duration** - Match time to traffic pattern
   - Low traffic: 60+ minutes per stage
   - High traffic: 30 minutes per stage

2. **Rollback Window** - Keep stages small enough
   - Too large: Risk of many affected users
   - Too small: Can't detect issues
   - Sweet spot: 1-10% increments

3. **Monitor During Rollout**
   - Set up alerts for error rates
   - Watch database metrics
   - Monitor customer support tickets
   - Have runbook ready for quick rollback

4. **Communicate Changes**
   ```javascript
   // Log canary events
   deploymentMetricsService.recordDeploymentEvent({
     type: 'canary_stage_advanced',
     version: 'v1.2.3',
     canaryStage: '10%',
     affectedUsers: 100000
   });
   ```

### A/B Testing Best Practices

1. **Sample Size**
   - Minimum: 1000 samples per variant
   - Better: 5000+ for confidence
   - Account for traffic patterns

2. **Test Duration**
   - Min: 24 hours (to capture daily patterns)
   - Better: 1-2 weeks
   - Avoid holiday/weekend anomalies

3. **Metric Selection**
   ```javascript
   // Primary metric must be:
   // - Actionable (can improve it)
   // - Measurable
   // - Related to business goals
   
   // Examples
   primaryMetric: 'conversion_rate',
   secondaryMetrics: [
     'error_rate',
     'response_time',
     'bounce_rate',
     'engagement_score'
   ]
   ```

4. **Multiple Testing Correction**
   - If testing 5+ metrics, increase p-value threshold
   - Use Bonferroni correction: 0.05 / number_of_metrics

### Monitoring Checklist

```
Before Canary:
☐ All tests passing
☐ Load tests passed
☐ Database migrations completed
☐ Health checks verified
☐ Rollback plan documented
☐ Team notified

During Canary (Every Stage):
☐ Error rate normal (<5%)
☐ Response times normal (<2000ms p99)
☐ No spike in support tickets
☐ Database metrics healthy
☐ Memory/CPU usage normal
☐ Logs for anomalies

After Rollout:
☐ Clean up debug logging
☐ Monitor for 24h post-100%
☐ Document lessons learned
☐ Remove feature flag after 2 weeks
☐ Archive experiment results
```

---

## Examples

### Example 1: Gradual Payment Processor Rollout

```bash
# Week 1: Create canary flag
PUT /api/admin/deployment/feature-flags/canary.new-payment
{
  "enabled": true,
  "type": "canary",
  "stages": [
    { "name": "1%", "percentage": 1, "durationMinutes": 60 },
    { "name": "5%", "percentage": 5, "durationMinutes": 60 },
    { "name": "25%", "percentage": 25, "durationMinutes": 120 },
    { "name": "100%", "percentage": 100 }
  ]
}

# Monitor metrics at each stage
# If error rate stays <1%, system auto-advances
# If error rate spikes, system auto-rolls back
# After 100%, flag stays for 2 weeks then removed
```

### Example 2: A/B Test New Checkout

```bash
# Create experiment
PUT /api/admin/deployment/feature-flags/experiment.checkout-redesign
{
  "type": "experiment",
  "variants": {
    "control": { "percentage": 50 },
    "variant_a": { "percentage": 50 }
  }
}

# After 1 week, analyze
GET /api/admin/deployment/experiments/experiment.checkout-redesign/statistical-significance
# → Response: "variant_a" wins with 96% confidence

# Deploy winner
PUT /api/admin/deployment/feature-flags/experiment.checkout-redesign
{
  "variants": {
    "variant_a": { "percentage": 100 }
  }
}
```

### Example 3: Quick Emergency Disable

```bash
# If critical issue found mid-deployment
PUT /api/admin/deployment/feature-flags/canary.new-payment
{
  "enabled": false
}

# Immediately disables for all new users
# Existing users stay on their current variant
# Traffic routes back to stable version
```

---

## Troubleshooting

### Flag Not Evaluating Correctly

```bash
# 1. Check flag exists
GET /api/admin/deployment/feature-flags

# 2. Verify flag configuration
GET /api/admin/deployment/feature-flags/{flagKey}

# 3. Clear Redis cache (forces DB fetch)
# This happens automatically via API or wait 5 mins

# 4. Check metrics to see evaluation count
GET /api/admin/deployment/metrics/flag-usage
```

### Canary Not Advancing

```bash
# 1. Check current stage
GET /api/admin/deployment/feature-flags/{flagKey}

# 2. Check metrics at current stage
GET /api/admin/deployment/metrics/health

# 3. If metrics bad, system won't auto-advance
# Fix issues, then manually advance:
POST /api/admin/deployment/feature-flags/{flagKey}/advance-canary
```

### Unexpected Rollback

```bash
# Check rollback event log
GET /api/admin/deployment/rollback-decisions?limit=5

# Analyze what triggered it
# Review metrics at time of rollback
# Adjust thresholds if needed
PUT /api/admin/deployment/feature-flags/rollback.error-rate-threshold
{
  "value": 7  # Increase from 5 to 7
}
```

---

## Database Migrations

Run migrations to create necessary tables:

```bash
npm run migrate

# Tables created:
# - feature_flags
# - feature_flags_audit
# - canary_deployment_logs
# - experiment_results
# - deployment_metrics
# - rollback_decisions
```

---

## Contact & Support

For issues or questions about feature flags:
- Check `/docs/FEATURE_FLAGS_FAQ.md`
- Review `/backend/src/services/FeatureFlagsService.js` for implementation details
- File issues in GitHub

---

**Version**: 1.0  
**Last Updated**: January 15, 2024  
**Maintainer**: DevOps Team
