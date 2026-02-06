# Backend Monitoring & Alerting Guide

## Overview
This guide documents the monitoring systems for the Rupaya backend, with special focus on the token revocation cleanup job.

## Token Revocation Cleanup Job

### Overview
- **Interval**: Every 24 hours
- **Purpose**: Remove expired revoked refresh tokens from database
- **Status**: Automatically started on app initialization
- **Location**: `src/app.js` (lines 84-150)

### Metrics Tracked

The cleanup job tracks the following metrics:

```javascript
{
  lastRun: ISO timestamp,           // When the job last executed
  lastSuccess: ISO timestamp,        // When the job last succeeded
  lastFailure: ISO timestamp,        // When the job last failed
  totalRuns: number,                 // Total execution count
  successfulRuns: number,            // Successful executions
  failedRuns: number,                // Failed executions
  totalTokensDeleted: number,        // Cumulative tokens deleted
  averageCleanupMs: number,          // Average execution time in ms
  lastErrorMessage: string           // Last error encountered
}
```

### Monitoring Endpoints

#### Check Cleanup Metrics
```bash
GET /admin/cleanup-metrics
```

**Response:**
```json
{
  "metrics": {
    "lastRun": "2026-02-01T12:00:00.000Z",
    "lastSuccess": "2026-02-01T12:00:00.000Z",
    "lastFailure": null,
    "totalRuns": 30,
    "successfulRuns": 30,
    "failedRuns": 0,
    "totalTokensDeleted": 1250,
    "averageCleanupMs": 245,
    "lastErrorMessage": null
  },
  "status": "healthy",
  "nextScheduledRun": "2026-02-02T12:00:00.000Z"
}
```

### Health Status Indicators

| Status | Condition | Action Required |
|--------|-----------|-----------------|
| ✅ `healthy` | All runs succeeded, tokens being cleaned | Monitor normally |
| ⚠️ `degraded` | 1-2 consecutive failures | Check database connection |
| 🔴 `critical` | 3+ consecutive failures | IMMEDIATE: Page ops team |

### Alerts & Logging

#### Log Levels
- **INFO**: Successful cleanup with deleted count
- **WARN**: Unusual patterns (e.g., 0 tokens for 3+ runs, timing anomalies)
- **ERROR**: Single cleanup failure
- **CRITICAL**: Multiple consecutive failures or system degradation

#### Example Logs

**Success:**
```json
{
  "message": "Revoked token cleanup completed successfully",
  "deleted": 42,
  "durationMs": 234,
  "metrics": {...}
}
```

**Warning - No tokens found:**
```json
{
  "severity": "WARNING",
  "message": "ALERT: No expired tokens found in cleanup",
  "consecutiveZeroRuns": true,
  "suggestedAction": "Verify if tokens are being revoked properly or if system time is incorrect"
}
```

**Critical - Multiple failures:**
```json
{
  "severity": "CRITICAL_ALERT",
  "message": "Token cleanup has failed 2 consecutive times",
  "action": "IMMEDIATE_ACTION_REQUIRED: Check database connection and revoked_tokens table integrity",
  "contactOps": true
}
```

### Cleanup Method Metrics

The `AuthService.cleanupRevokedTokens()` method returns detailed metrics:

```javascript
{
  deleted: number,           // Tokens actually deleted
  expectedDeleted: number,   // Tokens found before deletion
  activeRevoked: number,     // Non-expired revoked tokens still in DB
  remainingExpired: number   // Expired tokens that failed to delete
}
```

## Recommended Monitoring Setup

### For Development
- Check logs locally: `tail -f logs/app.log | grep -i "cleanup"`
- Check metrics endpoint: `curl http://localhost:3000/admin/cleanup-metrics`

### For Production

#### Log Aggregation (ELK/DataDog/New Relic)
```
Filter: "cleanup" OR "revoked_token"
Alert if: failedRuns > 2 OR averageCleanupMs > 1000
```

#### Automated Alerts
```
1. Slack/PagerDuty: If failedRuns >= 2, trigger alert
2. Email: Daily cleanup summary at 1 PM
3. Dashboard: Show cleanup metrics on ops dashboard
```

#### Database Monitoring
```sql
-- Check revoked_tokens table size
SELECT COUNT(*) as total, COUNT(CASE WHEN expires_at < NOW() THEN 1 END) as expired
FROM revoked_tokens;

-- Monitor index performance
EXPLAIN ANALYZE SELECT * FROM revoked_tokens WHERE expires_at < NOW();
```

## Scaling Considerations

### Current Setup (Good for 10k-100k users)
- 24-hour cleanup interval
- Single cleanup job per server
- No extra infrastructure needed

### Recommended Upgrades at Different Scales

**100k-500k users:**
- Reduce cleanup interval to 12 hours
- Monitor cleanup duration (should stay < 500ms)
- Consider moving to dedicated cleanup worker

**500k-1M+ users:**
- Switch to Redis cache for hot token blacklist
- Keep periodic batch cleanup for audit trail
- Implement event-driven revocation via message queue

## Troubleshooting

### Issue: Cleanup failing with "Database connection"
```javascript
// Check database config in src/config/database.js
// Verify pool settings: max connections, timeout, idle
```

### Issue: Cleanup taking > 1 second
```sql
-- Add missing indexes if they don't exist
CREATE INDEX idx_revoked_tokens_expires_at ON revoked_tokens(expires_at);
CREATE INDEX idx_revoked_tokens_user_id ON revoked_tokens(user_id);

-- Check index usage
ANALYZE revoked_tokens;
```

### Issue: Cleanup not running
```javascript
// Check app.js for cleanup initialization
console.log('Cleanup metrics:', cleanupMetrics);
// Verify database has revoked_tokens table
SELECT * FROM information_schema.tables WHERE table_name = 'revoked_tokens';
```

## Future Enhancements

- [ ] Configurable cleanup interval via environment variable
- [ ] Graceful shutdown for cleanup jobs in-flight
- [ ] Backup of deleted tokens (for audit compliance)
- [ ] Per-user token revocation analytics
- [ ] Redis caching layer for token blacklist checks
