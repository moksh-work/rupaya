# CI/CD Integration Guide: Feature Flags + Dev Preview Deployment

## Overview

This guide shows how the **Feature Flags & Deployment Features** (implemented in previous phase) integrate with the **Dev Preview Deploy Workflow** (Workflow 03) to create a production-grade CI/CD pipeline.

## Architecture Integration

```
┌─────────────────────────────────────────────────────────────────┐
│                         Developer's Workflow                      │
├─────────────────────────────────────────────────────────────────┤
│ 1. Create feature branch with code changes                       │
│ 2. Push to GitHub                                                │
└──────────────────────────┬──────────────────────────────────────┘
                           │
        ┌──────────────────▼──────────────────┐
        │  WORKFLOW 03: Dev Preview Deploy    │
        ├────────────────────────────────────┤
        │ ✓ Lint & Unit Tests (5 min)        │
        │ ✓ Docker Build & Push (8 min)      │
        │ ✓ Deploy to Dev ECS (10 min)       │
        │ ✓ E2E Tests (15 min)               │
        │ ✓ Post Results (2 min)             │
        └──────────────────┬──────────────────┘
                           │ ✅ All Checks Pass
        ┌──────────────────▼──────────────────┐
        │  Create Pull Request to Develop     │
        │  - Automatic PR checks pass        │
        │  - Dev deployment linked in PR     │
        │  - E2E test results ready for      │
        │    manual verification             │
        └──────────────────┬──────────────────┘
                           │ 👨‍💻 Code Review
        ┌──────────────────▼──────────────────┐
        │  Merge PR to Develop                │
        │  - Triggers WORKFLOW 05             │
        │  - Runs integration tests again     │
        │  - Deploys to staging (manual)      │
        └──────────────────┬──────────────────┘
                           │ 🧪 QA Testing
        ┌──────────────────▼──────────────────┐
        │  Create PR from Develop → Main      │
        │  - WORKFLOW 08 runs on main         │
        │  - Full prod test suite             │
        │  - Auto-deploy to production        │
        └──────────────────┬──────────────────┘
                           │ 📊 Monitoring
        ┌──────────────────▼──────────────────┐
        │  Production with Canary Deploy      │
        │  - Feature flags switch traffic     │
        │  - Gradual rollout (1% → 100%)     │
        │  - Auto-rollback on health issues   │
        └──────────────────────────────────────┘
```

## Feature Flags + Dev Deployment Integration

### Phase 1: Feature Development (Local + Dev Preview)

**What Happens:**
- Developer writes code with feature flags
- Pushes to `feature/new-dashboard` branch
- Workflow 03 triggers automatically
- Code deployed to dev environment within 40 minutes
- Developer can immediately test live with real database

**Example Workflow:**

```bash
# 1. Create feature with flag
git checkout -b feature/new-dashboard

# In code, use feature flags for feature toggle:
# backend/src/routes/dashboardRoutes.js
```

```javascript
router.get('/dashboard', authMiddleware, async (req, res) => {
  // Feature flag evaluation happens in middleware
  const hasNewDash = await req.evaluateFlag('feature.new-dashboard', req.user.id);
  
  if (hasNewDash.enabled) {
    // New dashboard code (v2)
    res.json(await dashboardV2.getMetrics(req.user.id));
  } else {
    // Legacy dashboard (v1)
    res.json(await dashboardV1.getMetrics(req.user.id));
  }
});
```

```bash
# 2. Push code
git add .
git commit -m "feat: implement new dashboard with feature flag"
git push origin feature/new-dashboard

# 3. Workflow 03 automatically:
#    - Tests code
#    - Builds Docker image
#    - Deploys to dev
#    - Runs E2E tests
#    - Posts results to PR

# 4. Developer tests in dev environment
# Navigate to: https://dev-feature-xyz.rupaya.internal
# Toggle flag ON/OFF via admin API to test both code paths
```

### Phase 2: Code Review (PR to Develop)

**Pre-requisites:**
- Workflow 03 completed successfully ✅
- E2E tests passed ✅
- Dev deployment accessible for manual testing ✅

**Code Review Checklist:**

```markdown
## Dev Preview Deployment Report

| Check | Status | Notes |
|-------|--------|-------|
| Lint & Unit Tests | ✅ | No errors |
| Docker Build | ✅ | 127 MB image |
| Deploy to Dev | ✅ | Rolled out successfully |
| E2E Tests | ✅ | 45/45 tests passed |
| Manual Testing | ⏳ | QA testing in progress |
| Feature Flag Config | ✅ | Properly configured |

✅ Ready for review after manual testing
```

**Feature Flag Checklist for Reviewers:**

- [ ] Flag is properly configured (type, default, env overrides)
- [ ] Both code paths tested (flag on/off)
- [ ] Canary config matches rollout plan
- [ ] A/B test properly assigns variants
- [ ] Rollback triggers are appropriate
- [ ] Metrics collection implemented
- [ ] Admin API endpoints functional
- [ ] Database migrations included

### Phase 3: Merge to Develop (Integration Testing)

**Workflow 05 Trigger:**
- Runs full integration test suite (not just unit tests)
- Tests against local Docker PostgreSQL & Redis
- Verifies database migrations apply cleanly
- 15-20 minutes execution time

**Feature Flag Validation:**
- Create test user in integration tests
- Verify flag evaluation with database
- Test canary progression logic
- Verify metrics collection
- Test A/B variant assignment

```javascript
// Example integration test
describe('Feature Flags Integration', () => {
  it('should evaluate new-dashboard flag for user', async () => {
    const flag = await featureFlagsService.evaluateFlag(
      'feature.new-dashboard',
      testUser.id,
      { env: 'development' }
    );
    
    expect(flag).toBeDefined();
    expect(flag.enabled).toBe(true); // dev environment override
    expect(flag.metadata).toBeDefined();
  });
});
```

### Phase 4: Staging Deployment (Manual Test)

**Manual Trigger:**
```bash
# Maintainer runs workflow 01 or triggers manual deployment
# This deploys to staging-backend ECS service
```

**Staging Feature Flag Configuration:**

In `backend/src/config/feature-flags.js`:

```javascript
{
  key: 'feature.new-dashboard',
  type: 'boolean',
  enabled: true,
  rolloutPercentage: 50, // Gradual rollout in staging
  environmentOverrides: {
    dev: { enabled: true, rolloutPercentage: 100 },
    staging: { enabled: true, rolloutPercentage: 50 }, // ← Staging config
    prod: { enabled: false, rolloutPercentage: 0 }     // ← Disabled in prod initially
  }
}
```

**Staging Testing Steps:**

1. **Enable Feature in Admin Panel:**
   ```bash
   curl -X PUT https://staging-api.rupaya.com/api/admin/deployment/feature-flags/feature.new-dashboard \
     -H "Authorization: Bearer $ADMIN_API_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "enabled": true,
       "rolloutPercentage": 50,
       "reason": "Staging test - 50% rollout"
     }'
   ```

2. **QA Tests Both Paths:**
   - 50% of sessions see new dashboard ✅
   - 50% of sessions see legacy dashboard ✅
   - Feature properly hidden from old UIs ✅
   - No database corruption ✅

3. **Monitor Metrics:**
   ```bash
   curl https://staging-api.rupaya.com/api/admin/deployment/metrics/health \
     -H "Authorization: Bearer $ADMIN_API_TOKEN"
   ```

### Phase 5: Production Deployment (Canary + Gradual Rollout)

**Production Feature Flag Config:**

```javascript
{
  key: 'feature.new-dashboard',
  type: 'canary',
  enabled: true,
  canaryStages: [
    { percentage: 1, durationMinutes: 30 },      // Stage 0: 1% for 30 min
    { percentage: 10, durationMinutes: 60 },     // Stage 1: 10% for 1 hour
    { percentage: 25, durationMinutes: 120 },    // Stage 2: 25% for 2 hours
    { percentage: 50, durationMinutes: 120 },    // Stage 3: 50% for 2 hours
    { percentage: 100, durationMinutes: 0 }      // Stage 4: 100% (final)
  ],
  currentStage: 0,
  rolloutStartTime: new Date(),
  environmentOverrides: {
    prod: { enabled: true, rolloutPercentage: 0 } // ← Canary controls rollout
  }
}
```

**Workflow 08 (Backend CI/CD) Triggers on Push to Main:**

```yaml
# .github/workflows/08-backend-cicd.yml
on:
  push:
    branches: [main]
```

**Production Rollout Process:**

```
T+0min (Stage 0: 1%)
├─ Deployed to all production nodes
├─ Feature flag at 1% rollout
├─ Error rate: < 0.5%
├─ Response time P99: < 1000ms
└─ Auto-advance window: 30 minutes ✅

T+30min (Stage 1: 10%)
├─ Automatically advance to stage 1
├─ Feature flag now at 10% rollout
├─ Metrics check: healthy ✅
├─ Monitor dashboard: no issues ✅
└─ Next auto-advance: 90 minutes from T+0 ✅

T+90min (Auto-Rollback?)
├─ IF error rate > 5% OR P99 > 2000ms
│  └─ AUTOMATIC ROLLBACK to previous stage
│     ├─ Sends alert to on-call team
│     ├─ Posts to #incidents Slack channel
│     ├─ Snapshot of metrics saved
│     └─ Engineering reviews metrics
├─ ELSE continue to stage 2
└─ Stage 2: 25% rollout ✅

T+210min (Stage 3: 50%)
├─ Half of users see new dashboard
├─ Metrics looking good
└─ Continue monitoring...

T+330min (Stage 4: 100%)
├─ Full production rollout
├─ Feature flag at 100%
├─ Auto-disable monitoring (permanent state)
└─ New dashboard live for everyone ✅
```

**Admin Commands During Rollout:**

```bash
# Check current status
curl https://api.rupaya.com/api/admin/deployment/feature-flags/feature.new-dashboard
# Response: currentStage: 2, percentage: 25%, nextAdvanceTime: 2025-02-26T14:30:00Z

# Manually advance canary (if confident)
curl -X POST https://api.rupaya.com/api/admin/deployment/feature-flags/feature.new-dashboard/advance-canary \
  -H "Authorization: Bearer $ADMIN_API_TOKEN" \
  -d '{"reason": "Manual advance - metrics excellent", "executedBy": "oncall-eng"}'
# Response: currentStage: 3, percentage: 50%

# Rollback if issues detected
curl -X POST https://api.rupaya.com/api/admin/deployment/feature-flags/feature.new-dashboard/rollback-canary \
  -H "Authorization: Bearer $ADMIN_API_TOKEN" \
  -d '{"reason": "P99 spike detected", "executedBy": "oncall-eng"}'
# Response: currentStage: 1, percentage: 10%

# Get detailed metrics
curl https://api.rupaya.com/api/admin/deployment/metrics/range?startTime=1708951800000&endTime=1708952400000 \
  -H "Authorization: Bearer $ADMIN_API_TOKEN"
# Returns: error_rate, p50/p95/p99 latency, requests, variants
```

## Deployment Scenarios

### Scenario 1: Hotfix for Production Bug

```
1. Create hotfix/ branch
2. Push to feature/
3. Workflow 03 runs:
   - Deploy to dev
   - E2E tests pass
4. Quick manual test in dev
5. Create PR to develop & main
6. Merge to main
7. Workflow 08 deploys to prod
8. Use feature flag to enable/disable hotfix
9. Gradual rollout via canary stages
```

### Scenario 2: A/B Test New Feature

```
1. Implement feature with experiment flag
2. Push to feature/
3. In dev environment:
   - Enable experiment
   - Create test accounts
   - Verify 50/50 split
4. Merge to develop
5. Deploy to staging
6. QA tests both variants
7. Merge to main
8. In production:
   - Start with small percentage (1%)
   - Advance stages as metrics confirm
   - Wait for statistical significance
   - Winner data + metrics saved
```

### Scenario 3: Gradual API Deprecation

```
1. Feature flag: "api.v1-endpoints-active"
2. v1 endpoints check flag:
   if (!evaluateFlag('api.v1-endpoints-active', user))
     return 410 GONE
3. Rollout schedule:
   - Week 1: 95% still active (5% early adopters migrate)
   - Week 2: 50% active (upgrade deadline approaching)
   - Week 3: 10% active (final stragglers)
   - Week 4: 0% active (full deprecation)
4. Monitor which services still use v1
5. Contact owners of failing services
```

## Testing Across Environments

### Unit Tests (Local)

```bash
cd backend
npm test -- __tests__/unit
# Tests: Component logic, utilities, helpers
# Speed: < 2 minutes
# Examples: Feature flag evaluation logic, hash functions
```

### Integration Tests (Docker)

```bash
docker-compose up -d postgres redis
npm run migrate:test
npm test -- __tests__/integration
# Tests: Feature flags + database, metrics + Redis, E2E API flow
# Speed: 5-10 minutes
# Examples: Flag persistence, canary progression, experiment variants
```

### E2E Tests (Dev Environment)

```bash
RUN_E2E_TESTS=true \
API_BASE_URL=https://dev-api.rupaya.internal \
npm test -- __tests__/e2e
# Tests: Complete user workflows, feature flag behavior, live API
# Speed: 15-20 minutes
# Examples: User signup with feature flags, account creation, transactions
```

### Smoke Tests (Staging)

```bash
RUN_SMOKE_TESTS=true \
API_BASE_URL=https://staging-api.rupaya.com \
npm test -- __tests__/smoke
# Tests: Critical paths, API availability, database connectivity
# Speed: 5 minutes
# Examples: Health check, auth flow, basic transactions
```

## Metrics & Monitoring

### What Gets Tracked

```javascript
// Per request (auto-collected by middleware)
{
  timestamp: Date,
  method: 'POST',
  path: '/api/v1/accounts',
  statusCode: 201,
  responseTimeMs: 145,
  userId: 'user-123',
  flagsEvaluated: {
    'feature.new-dashboard': { enabled: true, variant: null },
    'experiment.checkout-redesign': { enabled: true, variant: 'variant_a' }
  },
  canaryStages: {
    'canary.new-payment': 2,
    'canary.notification-service': 1
  }
}

// Aggregated every 10 seconds (in DeploymentMetricsService)
{
  window: '10s',
  metrics: {
    errors: { count: 2, rate: 0.1% },
    latency: { p50: 120, p95: 450, p99: 890 },
    throughput: { rps: 20, requests: 200 },
    variants: {
      'feature.new-dashboard': { enabled: 150, disabled: 50 },
      'experiment.checkout-redesign': { control: 100, variant_a: 100 }
    }
  }
}

// Rolled up to 1 hour + 7 days retention
```

### Dashboard Queries

```bash
# Real-time health status
GET /api/admin/deployment/metrics/health
Response: {
  status: "healthy",
  timestamp: "2025-02-26T10:15:00Z",
  metrics: {
    errorRate: 0.2,
    p99Latency: 890,
    requestsPerSecond: 20
  }
}

# Time-range metrics (for dashboard/charts)
GET /api/admin/deployment/metrics/range?startTime=X&endTime=Y
Response: {
  timeRange: { start: X, end: Y, granularity: "60s" },
  metrics: [
    { timestamp: X, errorRate: 0.1, p99: 750, requests: 100, variants: {...} },
    // ... more data points
  ]
}

# Experiment results
GET /api/admin/deployment/experiments/experiment.checkout/statistical-significance
Response: {
  experiment: "experiment.checkout",
  sampleSize: 10000,
  conversionRates: {
    control: 3.2,
    variant_a: 3.5,
    variant_b: 2.8
  },
  statisticalSignificance: 0.95,  // 95% confidence
  winner: "variant_a",
  pValue: 0.042
}
```

## Best Practices

### ✅ DO

- Use feature flags for all significant changes
- Test both code paths (flag on/off) in dev
- Start canary deployments at 1-5%
- Monitor P99 latency and error rates during rollout
- Set appropriate stage durations (5-30 minutes each)
- Document rollout plan in PR description
- Save deployment metrics for analysis
- Use A/B tests for high-impact features
- Keep flags configured for at least 2 weeks post-deployment
- Auto-clean up old/disabled flags monthly

### ❌ DON'T

- Deploy without feature flags for user-facing changes
- Use `if (process.env.NODE_ENV === 'production')` instead of flags
- Merge code with hardcoded feature assumptions
- Skip rollout stages (jump from 1% to 100%)
- Ignore high P99 latency or error rate during rollout
- Delete flags immediately after rollout completes
- Make irreversible changes without experiment validation
- Assume one code path is always faster (test both variants)

## Troubleshooting Workflow 03

### Scenario: Workflow runs but E2E tests fail

**Symptoms:**
- Lint ✅ Unit Tests ✅ Build ✅ Deploy ✅ E2E Tests ⚠️

**Diagnosis:**
1. Check deployed environment:
   ```bash
   curl https://dev-api.rupaya.internal/health
   ```

2. Check feature flags service is initialized:
   ```bash
   curl https://dev-api.rupaya.internal/api/admin/deployment/feature-flags
   ```

3. Check database connectivity:
   ```bash
   # In ECS logs
   CloudWatch → /ecs/rupaya-backend-dev
   grep -i "database\|connection" logs
   ```

**Solutions:**
- Verify DATABASE_URL env var in ECS task definition
- Check RDS security group allows ECS → RDS
- Verify RDS database exists and migrations ran
- Check Redis connectivity similarly

## Summary

**Dev Preview Deploy (Workflow 03)** integrates with **Feature Flags** to create:

✅ Fast feedback loops (40 min from push to test results)
✅ Automated deployment to dev for immediate testing
✅ Comprehensive E2E test validation before merge
✅ Safe production rollouts via canary deployment
✅ If issues: auto-rollback without manual intervention
✅ Data-driven decisions with A/B testing

This matches patterns used by **Netflix, Google, Meta, and Amazon** for production deployments.

---

**Questions?** Review:
- [Feature Flags Implementation](./FEATURE_FLAGS_AND_DEPLOYMENT.md)
- [Dev Preview Deploy Setup](./DEV_PREVIEW_DEPLOY_SETUP.md)
- [GitHub Actions Integration Guide](./GITHUB_WORKFLOWS_GITFLOW_COMPLETE.md)
