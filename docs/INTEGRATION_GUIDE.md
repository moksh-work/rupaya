# Feature Flags & Deployment Metrics Integration Guide

This guide explains how to integrate the feature flags, metrics, and rollback services into your existing Rupaya backend.

## Quick Start (5 Minutes)

### Step 1: Initialize Services in server.js

```javascript
// server.js
const app = require('./src/app');
const db = require('./src/db'); // Your knex instance
const redis = require('redis').createClient(process.env.REDIS_URL);
const logger = require('./src/utils/logger');

const PORT = process.env.PORT || 3000;

// Initialize deployment services
const { initializeDeploymentServices } = require('./src/app');

const startServer = async () => {
  try {
    // Initialize database
    await db.migrate.latest();
    
    // Initialize Redis
    await redis.connect();
    
    // Initialize feature flags and metrics
    const { featureFlagsService, deploymentMetricsService } = 
      await initializeDeploymentServices(db, redis);

    // Store in app for routes
    app.locals.featureFlagsService = featureFlagsService;
    app.locals.deploymentMetricsService = deploymentMetricsService;

    // Start server
    const server = app.listen(PORT, () => {
      logger.info(`Server running on port ${PORT}`);
    });

    // Graceful shutdown
    process.on('SIGTERM', async () => {
      logger.info('SIGTERM received, shutting down gracefully...');
      server.close(async () => {
        if (deploymentMetricsService) deploymentMetricsService.shutdown();
        await redis.quit();
        process.exit(0);
      });
    });

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();
```

### Step 2: Run Database Migration

```bash
npm run migrate

# Or manually with Knex:
npx knex migrate:latest
```

### Step 3: Add Admin API Token to Environment

```bash
# .env
ADMIN_API_TOKEN=your-secure-token-here
```

### Step 4: Add Feature Flag Checks to Your Routes

```javascript
// Example: transactionRoutes.js
router.post('/api/transactions', authMiddleware, async (req, res) => {
  try {
    // 1. Evaluate feature flag for new payment processor
    const newPaymentEnabled = await req.evaluateFlag('canary.new-payment-processor');

    // 2. Choose implementation
    if (newPaymentEnabled.enabled) {
      transaction = await processWithNewPaymentProcessor(req.body);
    } else {
      transaction = await processWithOldPaymentProcessor(req.body);
    }

    // 3. Record custom metrics
    req.metricsTags = {
      processorVersion: newPaymentEnabled.enabled ? 'new' : 'old',
      canaryStage: newPaymentEnabled.metadata.variant
    };

    res.status(201).json(transaction);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
```

---

## Implementation Patterns

### Pattern 1: Feature Toggle

```javascript
// Simple on/off feature
const result = await req.evaluateFlag('feature.new-dashboard');

if (result.enabled) {
  // New implementation
  dashboard = await generateDashboardV2();
} else {
  // Old implementation
  dashboard = await generateDashboardV1();
}
```

### Pattern 2: Gradual Rollout (Canary)

```javascript
// Automatic gradual rollout
const result = await req.evaluateFlag('canary.new-payment-processor');

if (result.enabled) {
  // New system (percentage controlled)
  processor = new NewPaymentProcessor();
  metrics.canaryStage = result.variant; // "1%", "10%", "25%", "50%", "100%"
} else {
  // Stable system
  processor = new OldPaymentProcessor();
}

transaction = await processor.process(paymentData);
```

### Pattern 3: A/B Testing

```javascript
// Run experiment with variant assignment
const experiment = await req.evaluateFlag('experiment.checkout-redesign', userId);

// User consistently gets same variant
const checkoutComponent = 
  experiment.variant === 'control' 
    ? CheckoutV1
    : CheckoutV2;

// Record metrics per variant
req.metricsTags = {
  experiment: 'checkout-redesign',
  variant: experiment.variant
};

res.json({
  component: checkoutComponent,
  experimentId: 'checkout-redesign',
  variant: experiment.variant
});
```

### Pattern 4: Beta Features

```javascript
// Target specific users for early access
const betaFlag = await req.evaluateFlag('feature.ai-budgeting', userId);

if (betaFlag.enabled) {
  // User is in targeting list or percentage rollout
  recommendations = await generateAiBudgetRecommendations();
} else {
  recommendations = null; // Don't show feature
}
```

---

## Middleware Integration

The feature flags middleware automatically:
- ✅ Adds `req.evaluateFlag()` method to every request
- ✅ Collects response metrics
- ✅ Tags requests with variant/canary-stage
- ✅ Emits events on health issues

```javascript
// Middleware automatically called for every request
// No additional setup needed in routes
```

---

## Monitoring Integration

### 1. Health Endpoint

Automatically enhanced with metrics:

```bash
GET /health

Response:
{
  "status": "OK",
  "timestamp": "2024-01-15T10:30:00Z",
  "deployment": {
    "status": "healthy",
    "errorRate": 0.5,
    "p99ResponseTime": 1200,
    "requestsPerSecond": 150
  },
  "featureFlags": {
    "checksTotal": 150000,
    "checksPerFlag": {
      "feature.new-dashboard": 45000
    }
  }
}
```

### 2. CloudWatch Integration

```javascript
// Add to app initialization
const cloudwatch = new AWS.CloudWatch();

deploymentMetricsService.on('metrics:aggregated', (metrics) => {
  // Send to CloudWatch
  cloudwatch.putMetricData({
    Namespace: 'Rupaya/Deployment',
    MetricData: [
      {
        MetricName: 'ErrorRate',
        Value: metrics.errorRate,
        Timestamp: new Date()
      },
      {
        MetricName: 'P99ResponseTime',
        Value: metrics.p99ResponseTime,
        Timestamp: new Date()
      }
    ]
  });
});

deploymentMetricsService.on('rollback:triggered', (event) => {
  // Alert ops team
  sns.publish({
    Message: `ALERT: Auto-rollback triggered!\n${event.reason}`,
    TopicArn: process.env.ALERT_TOPIC_ARN
  });
});
```

### 3. Datadog Integration

```javascript
// Send metrics to Datadog
const StatsD = require('node-dogstatsd').StatsD;
const dogstatsd = new StatsD();

deploymentMetricsService.on('metrics:aggregated', (metrics) => {
  dogstatsd.gauge('deployment.error_rate', metrics.errorRate);
  dogstatsd.gauge('deployment.p99_response_time', metrics.p99ResponseTime);
  dogstatsd.gauge('deployment.requests_per_second', metrics.requestsPerSecond);
});
```

---

## Database Setup

After migrations run, seed default flags:

```javascript
// scripts/seed-feature-flags.js
const flagConfig = require('../src/config/feature-flags');

exports.seed = async (knex) => {
  // Delete existing records
  await knex('feature_flags').del();

  // Insert defaults
  const flags = Object.entries(flagConfig.defaultFlags).map(([key, value]) => ({
    key,
    type: value.type,
    config: JSON.stringify(value),
    created_at: new Date(),
    updated_at: new Date()
  }));

  await knex('feature_flags').insert(flags);
};
```

Run seed:

```bash
npm run seed
```

---

## Admin Authentication

Protect admin endpoints:

```javascript
// middleware/adminAuth.js
const adminAuth = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (token !== process.env.ADMIN_API_TOKEN) {
    return res.status(401).json({ 
      error: 'Unauthorized: Invalid admin token' 
    });
  }
  
  next();
};

// Apply to admin routes
router.use('/admin', adminAuth);
```

---

## Configuration

### Environment Variables

```bash
# Feature Flags
FEATURE_FLAGS_CACHE_TTL=300           # 5 minutes
FEATURE_FLAGS_SYNC_INTERVAL=60000     # 1 minute

# Metrics
METRICS_WINDOW_SIZE=60               # 60 seconds
METRICS_AGGREGATION_INTERVAL=10000   # 10 seconds
METRICS_RETENTION_HOURS=24            # Keep 24 hours

# Rollback
ROLLBACK_ERROR_RATE_THRESHOLD=5      # %
ROLLBACK_RESPONSE_TIME_THRESHOLD=2000 # ms
ADMIN_API_TOKEN=your-secure-token

# Monitoring
ALERT_TOPIC_ARN=arn:aws:sns:...
ENABLE_CLOUDWATCH=true
ENABLE_DATADOG=true
```

---

## Testing

### Unit Tests

```javascript
// __tests__/unit/FeatureFlagsService.test.js
describe('FeatureFlagsService', () => {
  let service;
  let mockDb, mockRedis;

  beforeEach(() => {
    mockDb = {
      'feature_flags': { where: jest.fn() },
    };
    mockRedis = {
      get: jest.fn().mockResolvedValue(null),
      set: jest.fn().mockResolvedValue('OK'),
      del: jest.fn().mockResolvedValue(1)
    };

    service = new FeatureFlagsService(mockDb, mockRedis);
  });

  test('evaluates boolean flag correctly', async () => {
    const result = await service.evaluateFlag('feature.test', userId);
    expect(result.enabled).toBeDefined();
    expect(result.metadata.reason).toBeDefined();
  });

  test('returns consistent variant for same user', async () => {
    const result1 = await service.evaluateFlag('experiment.test', userId);
    const result2 = await service.evaluateFlag('experiment.test', userId);
    
    expect(result1.variant).toBe(result2.variant);
  });

  test('respects canary percentage', async () => {
    service.evaluateFlagConfig = { 
      percentage: 50, 
      type: 'boolean' 
    };
    
    // With proper hash, 50% of users should be enabled
    const enabledCount = Array.from({ length: 100 }, (_, i) => i)
      .filter(i => service.hashUserId('flag', i) < 50).length;
    
    expect(enabledCount).toBeCloseTo(50, 5);
  });
});
```

### Integration Tests

```javascript
// __tests__/integration/feature-flags.test.js
describe('Feature Flags Integration', () => {
  test('complete canary deployment flow', async () => {
    // 1. Create canary flag
    const flag = await featureFlagsService.updateFlag('canary.test', {
      enabled: true,
      percentage: 1
    });

    // 2. Evaluate flag for user
    const result = await featureFlagsService.evaluateFlag('canary.test', userId);
    
    // 3. Verify canary stage
    expect(result.metadata.stage).toBeDefined();
    
    // 4. Advance stage
    await featureFlagsService.updateFlag('canary.test', {
      currentStage: 1
    });
    
    // 5. Verify new stage
    const updated = await featureFlagsService.getFlagConfig('canary.test');
    expect(updated.currentStage).toBe(1);
  });
});
```

---

## Deployment Checklist

```
Pre-Deployment:
☐ Run all tests: npm test
☐ Check migrations: npm run migrate --dry-run
☐ Verify Redis connection
☐ Set ADMIN_API_TOKEN in secrets
☐ Review flag configurations

Deployment:
☐ Deploy backend code
☐ Run migrations: npm run migrate
☐ Seed feature flags: npm run seed
☐ Verify health endpoint
☐ Test flag evaluation manually

Post-Deployment:
☐ Monitor error rate (<1%)
☐ Monitor response times (<500ms)
☐ Check feature flag endpoint
☐ Verify metrics collection
☐ Test canary advancement
```

---

## Troubleshooting

### Database Connection Error

```
Error: connect ECONNREFUSED 127.0.0.1:5432

Solution:
☐ Verify PostgreSQL is running
☐ Check DB_HOST, DB_USER, DB_PASSWORD
☐ Verify migrations have run: npm run migrate
```

### Redis Connection Error

```
Error: WRONGPASS invalid username-password pair

Solution:
☐ Verify REDIS_URL is correct
☐ Check Redis is running
☐ Verify authentication credentials
```

### Feature Flag Not Evaluating

```
Expected: flag enabled for user
Got: flag always disabled

Debugging:
☐ Check flag exists: GET /api/admin/deployment/feature-flags/{key}
☐ Verify percentage: should be > 0
☐ Check user hash: hashUserId('key', userId) < percentage
☐ Clear Redis cache: flag auto-clears after 5 mins
```

### Canary Not Advancing

```
Expected: automatic stage progression
Got: stage stuck

Debugging:
☐ Check stage duration elapsed: flag.stageStartedAt < now - durationMs
☐ Verify metrics are good: error rate < 5%, response time < 2000ms
☐ Check database has write permissions
☐ Manually advance: POST /api/admin/deployment/feature-flags/{key}/advance-canary
```

---

## Performance Tips

### 1. Redis Caching

Flags cached for 5 minutes by default. Adjust:

```javascript
// FeatureFlagsService constructor
this.cacheExpireSecs = process.env.FEATURE_FLAGS_CACHE_TTL || 300;
```

### 2. Metrics Aggregation

Adjust aggregation window for more/less frequent analysis:

```javascript
// DeploymentMetricsService constructor
this.aggregationInterval = process.env.METRICS_AGGREGATION_INTERVAL || 10000;
```

### 3. Database Indexes

Migrations include indexes on:
- `feature_flags(key)` - Direct lookup
- `feature_flags(type)` - List flags by type
- `experiment_results(created_at)` - Time-range queries

Add custom indexes if needed:

```javascript
// knex migration
table.index(['flag_key', 'created_at']);
```

---

## Next Steps

1. ✅ Deploy code and run migrations
2. ☐ Configure feature flags via admin API
3. ☐ Set up canary flags for new features
4. ☐ Create A/B tests for hypotheses
5. ☐ Monitor metrics in CloudWatch/Datadog
6. ☐ Train team on flag management

---

## Support

Questions or issues?
- See [FEATURE_FLAGS_AND_DEPLOYMENT.md](./FEATURE_FLAGS_AND_DEPLOYMENT.md) for detailed documentation
- Review [FeatureFlagsService.js](../backend/src/services/FeatureFlagsService.js) for implementation
- Check GitHub issues for known problems
