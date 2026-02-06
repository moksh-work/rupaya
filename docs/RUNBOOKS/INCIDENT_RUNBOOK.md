# RUPAYA Incident Response Runbook

**Version:** 1.0  
**Last Updated:** January 30, 2026  
**On-Call Lead:** [Your Name]  
**Escalation:** @tech-lead → @devops-team  

---

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Incident Severity Levels](#incident-severity-levels)
3. [General Incident Response Process](#general-incident-response-process)
4. [Specific Incidents & Solutions](#specific-incidents--solutions)
5. [Rollback Procedures](#rollback-procedures)
6. [Communication Templates](#communication-templates)
7. [Post-Incident Review](#post-incident-review)

---

## Quick Reference

### Emergency Contacts

| Role | Name | Phone | Slack |
|------|------|-------|-------|
| Tech Lead | [Name] | [+91-XXX-XXX-XXXX] | @tech-lead |
| DevOps Lead | [Name] | [+91-XXX-XXX-XXXX] | @devops-team |
| Backend Lead | [Name] | [+91-XXX-XXX-XXXX] | @backend-team |
| iOS Lead | [Name] | [+91-XXX-XXX-XXXX] | @ios-team |
| Android Lead | [Name] | [+91-XXX-XXX-XXXX] | @android-team |

### Critical Links

| Resource | URL | Notes |
|----------|-----|-------|
| AWS Console | https://console.aws.amazon.com | Production infrastructure |
| CloudWatch | https://console.aws.amazon.com/cloudwatch | Real-time monitoring |
| GitHub Repo | https://github.com/yourcompany/rupaya | Source code |
| Sentry | https://sentry.io/rupaya | Error tracking |
| PagerDuty | https://rupaya.pagerduty.com | On-call management |
| Slack | #rupaya-alerts | Incident channel |
| Statuspage | https://status.rupaya.com | Public status page |

### Critical Commands

```bash
# SSH into backend server (AWS ECS)
aws ecs describe-tasks --cluster rupaya-cluster --tasks [task-id]
aws ecs stop-task --cluster rupaya-cluster --task [task-id]

# View logs
aws logs tail /ecs/rupaya-backend --follow

# Check database
psql -h rupaya-db.xxxxx.ap-south-1.rds.amazonaws.com -U rupaya_prod -d rupaya
SELECT * FROM pg_stat_activity;

# Check Redis
redis-cli -h rupaya-cache.xxxxx.ap-south-1.cache.amazonaws.com -p 6379
INFO memory

# Restart services
aws ecs update-service --cluster rupaya-cluster --service rupaya-service --force-new-deployment

# Scale instances (if CPU high)
aws ecs update-service --cluster rupaya-cluster --service rupaya-service --desired-count 3
```

---

## Incident Severity Levels

### **SEVERITY 1 - CRITICAL 🔴**

**Definition:** Complete service outage, data loss, security breach, or >5% of users affected

**Response Time:** Immediately (within 5 minutes)  
**Who:** Tech lead, DevOps lead, Backend lead, ALL team on-call  
**Actions:**
1. Page on-call team immediately
2. Create #incident-SEVERITY1 Slack channel
3. Establish war room (video call)
4. Status page: "MAJOR OUTAGE - Investigating"
5. Every 15 minutes: status update
6. Deploy hotfix or rollback within 30 min

**Examples:**
- Backend API completely down (500 errors for all requests)
- Database unavailable
- User data corruption/loss
- Security vulnerability exposed
- All transactions failing
- Authentication system down

---

### **SEVERITY 2 - HIGH 🟠**

**Definition:** Degraded service (slow API, >1% of users affected), partial feature outage

**Response Time:** Within 15 minutes  
**Who:** Tech lead, relevant platform lead (backend/iOS/Android)  
**Actions:**
1. Create #incident-SEVERITY2 Slack thread
2. Communicate issue in #rupaya-general
3. Status page: "DEGRADED - Limited impact"
4. Every 30 minutes: status update
5. Target fix: within 2 hours

**Examples:**
- API response time >2 seconds
- Database connection pool exhausted
- Specific feature returning 500 errors (e.g., export endpoint)
- Mobile app crashes for >1% of users
- Memory leak causing gradual degradation
- Cache not responding

---

### **SEVERITY 3 - MEDIUM 🟡**

**Definition:** Minor service degradation, <0.1% users affected, cosmetic issues

**Response Time:** Within 1 hour  
**Who:** Relevant team lead only  
**Actions:**
1. Create #incident-SEVERITY3 Slack thread
2. Fix during next business day if possible
3. Status page: No update needed
4. Daily update to team

**Examples:**
- Single endpoint slow (but not down)
- One user reports transaction issue
- UI cosmetic bug
- Minor error logs not related to functionality
- Non-critical feature not working

---

### **SEVERITY 4 - LOW 🟢**

**Definition:** No user impact, internal issue, planned maintenance

**Response Time:** Next business day  
**Who:** Relevant developer  
**Actions:**
1. Create GitHub issue
2. Add to backlog
3. No status page update

**Examples:**
- Linting warnings
- Performance improvement opportunity
- Code refactoring needed
- Test failures not blocking deployment

---

## General Incident Response Process

### Step 1: Detect the Incident (0-5 min)

**Automated detection (preferred):**
```
CloudWatch alert → SNS → Slack #rupaya-alerts
OR
Sentry error spike → Email → Slack
OR
PagerDuty alert → Phone call → Slack
```

**Manual detection:**
- User reports issue in Slack
- Team member notices errors
- Status page shows high error rate

**On detection:**
```bash
# 1. Immediately check what's failing
curl -I https://api.rupaya.in/health

# 2. Check CloudWatch for error spike
aws logs tail /ecs/rupaya-backend --follow

# 3. Check Sentry for error messages
open https://sentry.io/rupaya/

# 4. Check status of infrastructure
aws ecs describe-services --cluster rupaya-cluster --services rupaya-service
```

---

### Step 2: Initial Assessment (5-10 min)

**Gather information:**

```bash
# Is the problem backend, mobile, or infrastructure?

# Backend check
curl -v https://api.rupaya.in/health
# Should return: { "status": "ok", "timestamp": "..." }

# Database check
aws rds describe-db-instances --db-instance-identifier rupaya-prod
# Look for: Status=available, should see no reboot in progress

# Cache check
aws elasticache describe-cache-clusters --cache-cluster-id rupaya-cache
# Look for: Status=available, should see healthy nodes

# ECS check
aws ecs describe-services --cluster rupaya-cluster --services rupaya-service
# Look for: desiredCount == runningCount

# Network/Load Balancer check
aws elbv2 describe-target-health --target-group-arn arn:...
# Look for: healthy targets
```

**Fill out incident form:**

```
[ ] What is broken? (API / Database / Cache / Mobile / Web)
[ ] Who reported it? (User / Monitoring / Internal team)
[ ] When did it start? (Exact time)
[ ] How many users affected? (All / Some / Unknown)
[ ] Is there an error message? (What does it say?)
[ ] Does it affect production only? (Or staging/dev too?)
[ ] Has there been a recent deployment? (Last 30 min)
[ ] Are there any unusual metrics? (CPU / Memory / DB connections)
```

---

### Step 3: Severity Classification (10 min)

**Determine severity based on:**
- Number of users affected
- Service availability (uptime %)
- Data loss risk
- User impact (critical vs nice-to-have feature)
- Revenue impact

**Use the matrix:**

| Users Affected | Service Impact | Severity |
|---|---|---|
| All (>100k) | Service down | SEVERITY 1 🔴 |
| Many (1k-100k) | Service down | SEVERITY 2 🟠 |
| Some (1-1k) | Service degraded | SEVERITY 3 🟡 |
| Few (<1) | Minor issue | SEVERITY 4 🟢 |

---

### Step 4: Declare Incident (10 min)

**Create incident:**

```bash
# Create Slack channel
/channel create incident-2026-01-30-backend-down

# Add team members
/invite @tech-lead @devops-team @backend-team

# Post initial message
"""
🚨 INCIDENT DECLARED - SEVERITY 1

**Issue:** Backend API returning 500 errors
**Impact:** All users unable to view transactions
**Started:** 2026-01-30 21:15:00 UTC
**Status:** Investigating
**ETA:** 15 minutes

**What we're doing:**
1. Checking logs for errors
2. Verifying database connectivity
3. Rolling back last deployment if needed

@tech-lead - Are you joining war room?
"""

# Start video call
/call join incident-2026-01-30-backend-down

# Update status page
# Open https://status.rupaya.com → Incidents → New Incident
```

---

### Step 5: Investigation & Root Cause (10-30 min)

**Check logs systematically:**

```bash
# Backend logs (last 5 minutes)
aws logs tail /ecs/rupaya-backend --follow --start-time 5m

# Look for patterns:
# - OutOfMemoryError → Memory leak
# - ConnectionRefused → Database down
# - TimeoutError → External service slow
# - AuthorizationException → AWS credentials invalid

# Application logs
grep -i error /var/log/rupaya/app.log | tail -20

# Database slow query log
psql -h rupaya-db.xxxxx.ap-south-1.rds.amazonaws.com -U rupaya_prod -d rupaya
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;

# Check recent deployments
git log --oneline -10
# Did deployment happen within last 30 min?

# Check for resource exhaustion
aws ecs describe-tasks --cluster rupaya-cluster --tasks [current-tasks]
# Look for: cpuUtilization, memoryUtilization

# Check database connections
psql ... -c "SELECT count(*) FROM pg_stat_activity;"
# If high (>100): connection leak or under load
```

**Common Root Causes:**

| Symptom | Cause | Fix |
|---------|-------|-----|
| All requests timeout | Backend down | Restart ECS service |
| Some requests fail | DB connection pool exhausted | Scale DB / reduce connections |
| Memory keeps growing | Memory leak in app | Deploy previous version / hotfix |
| CPU at 100% | Infinite loop / bad query | Kill process / deploy hotfix |
| Database slow | Long-running query | Kill query / add index |
| Spike in errors after deploy | Bad code | Rollback deployment |
| Spike in errors without deploy | External service down | Wait or switch to fallback |

---

### Step 6: Mitigation (30 min max)

**Option A: Quick Fix (if root cause is known)**

```bash
# Example: Bad database query in recent code
git log --oneline -5
git show abc1234  # Review recent change

# Fix locally
# Make fix in codebase
git commit -m "hotfix: revert bad query logic"
git push origin hotfix/bad-query

# Deploy hotfix
# CI/CD automatically deploys to production
# Check: curl https://api.rupaya.in/health
```

**Option B: Rollback (if recent deployment caused issue)**

```bash
# Check when the issue started
# If <30 min ago, probably the recent deployment

# Get current ECS task definition version
aws ecs describe-services --cluster rupaya-cluster --services rupaya-service

# Rollback to previous version
aws ecs update-service \
  --cluster rupaya-cluster \
  --service rupaya-service \
  --task-definition rupaya-task:15  # Previous version

# Wait for rollout
aws ecs wait services-stable --cluster rupaya-cluster --services rupaya-service

# Verify
curl https://api.rupaya.in/health
```

**Option C: Scale Down (if under heavy load)**

```bash
# If too much traffic causing CPU spike:
aws ecs update-service \
  --cluster rupaya-cluster \
  --service rupaya-service \
  --desired-count 1  # Reduce to 1 instance temporarily

# Then:
# 1. Investigate what caused spike
# 2. Add rate limiting
# 3. Deploy fix
# 4. Scale back up
```

**Option D: Enable Circuit Breaker (if external service is down)**

```bash
# If external payment API is down:
# 1. Update backend to skip payment check (temporary)
# 2. Deploy with feature flag OFF
# 3. Transactions proceed without payment
# 4. When external service recovers, re-enable

# In code:
if (FEATURE_FLAG.payment_enabled) {
  await validatePayment(transaction);
}
```

---

### Step 7: Recovery & Validation (5 min)

**After applying fix:**

```bash
# 1. Verify fix is live
curl https://api.rupaya.in/health
# Should return: { "status": "ok" }

# 2. Run smoke tests
npm run test:smoke

# 3. Check error rate is dropping
# Open CloudWatch → Metric → Errors
# Should see spike going down

# 4. Check a few transactions work
# In mobile app or Postman:
POST /api/transactions
{ "amount": 100, "type": "income" }
# Should succeed

# 5. Check logs are clean
aws logs tail /ecs/rupaya-backend --follow --max-items 20
# Should see no ERROR or WARN

# 6. Verify mobile apps work
# Ask iOS/Android team to test on device
```

---

### Step 8: Communication (ongoing)

**Updates to post:**

```
[10:15] 🚨 INCIDENT DECLARED
Issue: Backend returning 500 errors
Impact: 15,000 users
Status: Investigating

[10:25] 📊 ROOT CAUSE IDENTIFIED
Found: Database connection pool exhausted
Cause: Deployment 30 min ago introduced connection leak
Fix: Rolling back to previous version

[10:30] ✅ ROLLBACK COMPLETE
Service: Now healthy
Error rate: Dropping (was 95%, now 5%)
Status: Monitoring

[10:35] ✅ INCIDENT RESOLVED
All services: Healthy
Error rate: <0.1% (normal)
Cause: Connection leak in transaction service
Next: Post-mortem tomorrow 10am
```

**Update status page:**
- 10:15: "MAJOR OUTAGE - Investigating"
- 10:25: "MAJOR OUTAGE - Root cause identified"
- 10:30: "DEGRADED - Applying fix"
- 10:35: "RESOLVED - Monitoring"

**Notify users (if Severity 1):**
```
RUPAYA INCIDENT UPDATE

We experienced a service outage from 10:15-10:35 IST 
affecting all users.

WHAT HAPPENED:
A recent code deployment introduced a connection leak 
that exhausted our database connection pool.

WHAT WE DID:
We identified the issue within 10 minutes and rolled 
back the deployment.

CURRENT STATUS:
✅ All services are now healthy
✅ Error rates are normal (<0.1%)

NEXT STEPS:
- We'll conduct a post-mortem tomorrow
- We'll implement better connection pooling monitoring
- We'll improve our CI/CD tests to catch this earlier

We apologize for the inconvenience and thank you 
for your patience.

- The RUPAYA Team
```

---

## Specific Incidents & Solutions

### Incident 1: Backend API Completely Down

**Symptoms:**
- `curl https://api.rupaya.in/health` times out
- All requests returning connection refused
- Load balancer showing 0 healthy targets

**Investigation:**

```bash
# Step 1: Check ECS service
aws ecs describe-services \
  --cluster rupaya-cluster \
  --services rupaya-service

# Look for:
# desiredCount: 2
# runningCount: 0  ← Problem!

# Step 2: Check task logs
aws ecs describe-task-definition --task-definition rupaya-task
aws ecs list-tasks --cluster rupaya-cluster
aws ecs describe-tasks --cluster rupaya-cluster --tasks [task-id]

# Look for:
# lastStatus: STOPPED
# stoppedReason: "Task failed to start"
```

**Common Causes & Fixes:**

| Cause | Fix |
|-------|-----|
| Docker image doesn't exist in ECR | Push new image: `docker build -t ... && docker push ...` |
| Port conflict (3000 in use) | Kill process: `lsof -ti:3000 \| xargs kill -9` |
| Out of memory | Scale to larger instance or reduce memory needs |
| Environment variables missing | Update ECS task definition secrets |
| Database connection failed | Verify DB is up: `aws rds describe-db-instances` |

**Solution:**

```bash
# Option 1: Restart service
aws ecs update-service \
  --cluster rupaya-cluster \
  --service rupaya-service \
  --force-new-deployment

# Option 2: Rollback
aws ecs update-service \
  --cluster rupaya-cluster \
  --service rupaya-service \
  --task-definition rupaya-task:15

# Option 3: Check and fix code
git log --oneline -5
# Deploy hotfix

# Verify recovery
aws ecs wait services-stable --cluster rupaya-cluster --services rupaya-service
curl https://api.rupaya.in/health
```

---

### Incident 2: Database Connection Pool Exhausted

**Symptoms:**
- Some requests timeout
- CloudWatch: DB connection count stays at max (usually 100)
- Errors: "could not connect to server"

**Investigation:**

```bash
# Check current connections
psql -h rupaya-db.xxxxx.ap-south-1.rds.amazonaws.com \
    -U rupaya_prod \
    -d rupaya \
    -c "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"

# Output:
# count | state
# ------+--------
#    95 | active
#     5 | idle in transaction

# Look for idle connections that should be closed

# Check slow queries
psql ... -c "SELECT query, calls, total_time FROM pg_stat_statements ORDER BY total_time DESC LIMIT 5;"
```

**Common Causes:**

| Cause | Symptoms | Fix |
|-------|----------|-----|
| Connection leak | Connections grow over time | Restart app / deploy fix |
| Slow query | One query blocks all others | Kill query / add index |
| Too many concurrent users | Legitimate high load | Scale DB / add connection pooling |
| Database under-resourced | Even simple queries timeout | Increase DB size |

**Solution:**

```bash
# Kill idle connections
psql ... -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle in transaction';"

# Kill a specific slow query
psql ... -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE query LIKE '%expensive_query%';"

# Temporarily reduce traffic
aws ecs update-service --cluster rupaya-cluster --service rupaya-service --desired-count 1

# Or add connection pooling middleware (PgBouncer)
# Then scale back up

# Deploy fix to reduce queries
git commit -m "fix: add connection pooling + reduce queries"
aws ecs update-service --cluster rupaya-cluster --service rupaya-service --force-new-deployment
```

---

### Incident 3: Memory Leak / Growing Memory Usage

**Symptoms:**
- CloudWatch: Memory usage keeps growing (80% → 90% → 95%)
- Eventually OOMKilled by ECS
- Errors: "JavaScript heap out of memory"

**Investigation:**

```bash
# Check memory over time
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ServiceName,Value=rupaya-service \
  --start-time 2026-01-30T20:00:00Z \
  --end-time 2026-01-30T21:00:00Z \
  --period 300 \
  --statistics Average

# If growing: memory leak
# If stable: just high load

# Check logs for patterns
aws logs tail /ecs/rupaya-backend --follow --filter-pattern "allocation"
```

**Common Causes:**

| Cause | Fix |
|-------|-----|
| Event listener not removed | Review code changes, add cleanup |
| Cache growing unbounded | Add TTL to cache entries |
| Array accumulating data | Use circular buffer or clear periodically |
| Third-party module leak | Update dependency version |

**Solution:**

```bash
# Short term: Restart service
aws ecs update-service --cluster rupaya-cluster --service rupaya-service --force-new-deployment

# Find the leak
npm install --save-dev heapdump
# Add to code: heapdump.writeSnapshot()
# Analyze with Chrome DevTools

# Deploy fix
git commit -m "fix: add cache TTL to prevent memory leak"
aws ecs update-service --cluster rupaya-cluster --service rupaya-service --force-new-deployment
```

---

### Incident 4: High Error Rate (500s) in Specific Endpoint

**Symptoms:**
- `/api/transactions/export` returning 500
- Other endpoints working fine
- Errors started after recent deployment

**Investigation:**

```bash
# Check recent code changes
git log --oneline -10
git show abc1234

# Look at specific error logs
aws logs filter-log-events \
  --log-group-name /ecs/rupaya-backend \
  --filter-pattern "[ERROR] /transactions/export"

# Check if it's an external service issue
curl -I https://external-api.example.com
```

**Solution:**

```bash
# Option 1: Rollback if recent deployment
git revert abc1234
git push origin develop

# Option 2: Quick fix
# Fix the bug locally
git commit -m "fix: handle null check in export endpoint"
git push origin hotfix/export-bug

# Option 3: Feature flag
# Disable the feature while investigating
update .env EXPORT_ENABLED=false
```

---

### Incident 5: Mobile App Crashes

**Symptoms:**
- iOS/Android app crashes on login screen
- Sentry showing crash spike
- Error: "NSInvalidArgumentException" or "NullPointerException"

**iOS Crash Analysis:**

```bash
# Check Sentry
open https://sentry.io/rupaya/

# Look for:
# - Error message
# - Stack trace
# - Affected versions

# Common issues:
# - URL returned from API changed format
# - API response missing expected field
# - Certificate pinning failing

# Reproduce locally
# Xcode → Debug → Console
# Set breakpoint at crash location
```

**Android Crash Analysis:**

```bash
# Check Sentry / Firebase Crashlytics
open https://console.firebase.google.com/

# Look at stack trace
# Try to reproduce in Android Studio emulator

# Common issues:
# - Network error handling not implemented
# - Null pointer in JSON parsing
# - Permission missing
```

**Solution:**

```bash
# Backend: Check API response
curl https://api.rupaya.in/api/auth/signin | jq .

# iOS: Make API more resilient
// Add nil checks
guard let token = response["token"] as? String else {
  throw APIError.missingToken
}

// Handle errors better
URLSession.shared.dataTask { data, response, error in
  guard error == nil else {
    DispatchQueue.main.async {
      self.errorMessage = error?.localizedDescription
    }
    return
  }
}

# Android: Same pattern
response.token?.let { token ->
  // Use token
} ?: run {
  throw ApiException("Missing token")
}
```

---

### Incident 6: Unusual Traffic / DDoS Attack

**Symptoms:**
- CloudWatch: Requests spike to 1000s/sec (normal: 10s)
- Error rate normal (most requests succeed)
- Specific API endpoint being hammered
- Traffic from suspicious IPs

**Investigation:**

```bash
# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --start-time 2026-01-30T20:00:00Z \
  --end-time 2026-01-30T21:00:00Z \
  --period 60 \
  --statistics Sum

# Check which endpoints are hit
aws logs filter-log-events \
  --log-group-name /ecs/rupaya-backend \
  --filter-pattern "GET /api" \
  | grep -oE "GET /api/[^ ]+" | sort | uniq -c | sort -rn

# Check for suspicious IPs
aws wafv2 list-ip-sets --scope REGIONAL
```

**Solution:**

```bash
# Option 1: Rate limiting (already in place)
# Check if rate limiter is working
# Should return 429 after 100 requests in 15 min

# Option 2: Add WAF rule
aws wafv2 create-ip-set \
  --name BlockedIPs \
  --scope REGIONAL \
  --ip-address-version IPV4 \
  --addresses "[\"203.0.113.0/24\"]"

# Option 3: Cloudflare or AWS Shield
# Enable AWS Shield Standard (free)
# Or AWS Shield Advanced ($3000/month)

# Option 4: Whitelist known IPs
# If internal tool is causing spike
# Add to security group whitelist
```

---

## Rollback Procedures

### Rollback Deployment (if it caused issue)

**Scenario:** Deployed at 21:00, errors started 21:05

```bash
# 1. Identify previous good version
aws ecs describe-services --cluster rupaya-cluster --services rupaya-service
# Look at: taskDefinition (e.g., rupaya-task:42)

# 2. Rollback
aws ecs update-service \
  --cluster rupaya-cluster \
  --service rupaya-service \
  --task-definition rupaya-task:41  # Previous version

# 3. Wait for deployment
aws ecs wait services-stable --cluster rupaya-cluster --services rupaya-service

# 4. Verify
curl https://api.rupaya.in/health

# 5. Investigate bad deployment
git log --oneline -5
git show abc1234
# Why did it fail?
```

### Rollback Database Migration

**Scenario:** Migration corrupted data, need to rollback

```bash
# 1. Connect to database
psql -h rupaya-db.xxxxx.ap-south-1.rds.amazonaws.com \
     -U rupaya_prod \
     -d rupaya

# 2. Check migration status
SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;

# 3. Rollback last migration
-- In transaction (so we can rollback if needed)
BEGIN;

-- Run downgrade script
-- e.g., if migration added a column:
ALTER TABLE users DROP COLUMN new_field;

-- Verify data
SELECT COUNT(*) FROM users;

-- If OK:
COMMIT;
-- If problem:
-- ROLLBACK;
```

### Rollback Data Changes

**Scenario:** Bad transaction corrupted user data

```bash
# 1. Find the problematic transaction
SELECT * FROM transactions WHERE user_id = 'user123' ORDER BY created_at DESC LIMIT 10;

# 2. Delete bad transaction
BEGIN;
DELETE FROM transactions WHERE id = 'txn_xyz' AND user_id = 'user123';

# 3. Restore backup if needed
-- Restore from snapshot (AWS RDS)
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier rupaya-recovered \
  --db-snapshot-identifier rupaya-2026-01-30-21-00

# 4. Restore user's balance
UPDATE accounts SET balance = balance + 100 WHERE user_id = 'user123';
COMMIT;
```

---

## Communication Templates

### Initial Incident Notification (Slack)

```
🚨 INCIDENT DECLARED - SEVERITY [1/2/3]

**Issue:** [One-line summary]
**Component:** Backend / iOS / Android / Database
**Impact:** [X users affected / [Feature] not working]
**Started:** [Time] IST
**Current Status:** Investigating

**Next steps:**
1. [Immediate action]
2. [Follow-up action]
3. [Target resolution time]

@tech-lead - Please acknowledge
@[relevant-team] - We may need your help
```

### Status Update (every 15-30 minutes)

```
📊 INCIDENT UPDATE #[number]

**Status:** [Investigating / Identified / Fixing / Monitoring]
**Finding:** [What we discovered]
**Actions taken:** [What we did]
**ETA:** [When it will be fixed]

Last update: [time] | Next update: [time]
```

### Resolution Notification

```
✅ INCIDENT RESOLVED

**What happened:** [Root cause in 1-2 sentences]
**Impact:** [X minutes downtime, Y users affected]
**Resolution:** [How we fixed it]
**Prevent in future:** [2-3 measures]

**Timeline:**
- 21:05: Issue detected
- 21:10: Root cause identified
- 21:20: Fix deployed
- 21:22: All systems healthy

Post-mortem will be held on [date/time] in #rupaya-general

Thank you for your patience! 🙏
```

### Public Status Page Message

```
INCIDENT: [Service] Outage

INVESTIGATING
We are currently investigating an issue affecting [service].
We'll provide an update within 30 minutes.

---

IDENTIFIED
Root cause: [Brief explanation]
We are implementing a fix.

---

MONITORING
Our team deployed a fix. We are monitoring the situation closely.

---

RESOLVED
The incident has been resolved. Normal service has been restored.

We apologize for the inconvenience and thank you for your patience.
```

---

## Post-Incident Review (PIR)

**Timing:** Within 24 hours of incident resolution

**Participants:** Tech lead, relevant team leads, engineers involved

**Duration:** 30-60 minutes

### PIR Agenda

```
1. INCIDENT TIMELINE (5 min)
   - 21:05: Issue detected via CloudWatch alert
   - 21:10: Root cause identified (connection pool leak)
   - 21:20: Hotfix deployed
   - 21:22: Services recovered
   
2. ROOT CAUSE ANALYSIS (10 min)
   - Why: Recent code change introduced connection leak
   - Why: Code review didn't catch the issue
   - Why: No connection pool monitoring in place
   
3. IMPACT ASSESSMENT (5 min)
   - Duration: 17 minutes
   - Users affected: 15,000 (all active users)
   - Transactions failed: ~250
   - Revenue impact: ~$5,000
   
4. WHAT WENT WELL (5 min)
   - ✅ Monitoring detected issue immediately
   - ✅ Team responded within 5 minutes
   - ✅ Root cause found quickly
   - ✅ Communication was clear
   
5. WHAT COULD BE BETTER (10 min)
   Issue 1: Connection pool monitoring
   - Action: Add connection pool alert (warning at 80%, critical at 95%)
   - Owner: DevOps Lead
   - Deadline: 1 week
   
   Issue 2: Better code review
   - Action: Require connection handling review for database changes
   - Owner: Backend Lead
   - Deadline: Immediate
   
   Issue 3: Faster rollback
   - Action: Document rollback procedure, practice monthly
   - Owner: DevOps Lead
   - Deadline: 2 weeks
   
6. ACTION ITEMS (5 min)
   [ ] Add connection pool monitoring alert (DevOps - 1 week)
   [ ] Add pre-deployment connection leak check (Backend - 1 week)
   [ ] Practice rollback procedure (DevOps - 2 weeks)
   [ ] Update incident response guide (Tech Lead - 3 days)
```

### PIR Document

**File: `docs/RUNBOOKS/incident-[date]-analysis.md`**

```markdown
# Incident Post-Mortem: Backend Connection Pool Exhaustion

**Date:** January 30, 2026  
**Duration:** 17 minutes (21:05 - 21:22 IST)  
**Severity:** SEVERITY 1 - Critical  
**Participants:** @tech-lead, @backend-team, @devops-team  

## Executive Summary
A code deployment at 21:00 introduced a connection leak that exhausted the database connection pool within 5 minutes. This caused all transactions to fail for 17 minutes. The issue was identified quickly via monitoring and resolved by rolling back the deployment.

## Timeline
| Time | Event | Owner |
|------|-------|-------|
| 21:00 | Deployed v1.2.0 | @backend-dev |
| 21:05 | CloudWatch alert: connection count 100 | Monitoring |
| 21:07 | Incident declared in Slack | @tech-lead |
| 21:10 | Root cause identified: leak in connection handling | @backend-team |
| 21:15 | Rollback triggered | @devops-team |
| 21:20 | Rollback complete, services recovered | @devops-team |
| 21:22 | All tests passing, error rate normal | @backend-team |

## Root Cause
In commit abc1234, a transaction handler was refactored to use connection pooling. However, the implementation had a bug where connections were not properly released after use. Each request would acquire a connection but not release it, causing exhaustion within ~500 requests (~5 minutes at 100 req/sec).

**Code snippet (buggy):**
```javascript
const transaction = await pool.query('BEGIN');
// ... do work ...
// Missing: await pool.query('COMMIT');
```

## Why Did It Happen?

1. **Code Review:** The PR was reviewed but the connection handling was not thoroughly checked
2. **Testing:** Unit tests didn't cover the full transaction lifecycle
3. **Staging:** The issue wasn't caught in staging because load was lower
4. **Monitoring:** No specific connection pool monitoring alert was in place

## Impact
- **Duration:** 17 minutes
- **Users Affected:** All 15,000 concurrent users
- **Transactions Failed:** ~250
- **Revenue Impact:** ~$5,000
- **Support Tickets:** 47

## Resolution
Rolled back to v1.2.0-beta (previous version). Fix deployed in v1.2.1 with proper connection handling.

## Lessons Learned

✅ **Positive:**
- Monitoring detected issue immediately
- Team responded quickly (within 2 minutes)
- Root cause found in <5 minutes
- Rollback was smooth and fast
- Communication was clear

🔄 **Improvements Needed:**
1. Connection pool monitoring needs alert at 80% utilization
2. Code review checklist must include connection handling review
3. Load testing before production deployment
4. Better logging for connection operations

## Action Items

| Item | Owner | Deadline | Status |
|------|-------|----------|--------|
| Add connection pool monitoring alert | @devops-lead | 1 week | [ ] |
| Add connection handling review to code review checklist | @backend-lead | 3 days | [ ] |
| Implement load testing in CI/CD | @devops-lead | 2 weeks | [ ] |
| Document connection pooling best practices | @backend-lead | 1 week | [ ] |
| Practice rollback procedure monthly | @devops-lead | ongoing | [ ] |

## Follow-up
Next review: Feb 6, 2026 - Verify all action items completed

---
*Prepared by: @tech-lead*  
*Date: Jan 31, 2026*
```

---

## Critical Checklist Before Going Live

Before deploying to production, ensure:

```
PRE-DEPLOYMENT CHECKLIST

Code Quality:
[ ] All tests passing (backend, iOS, Android)
[ ] Code reviewed by 2+ team members
[ ] No hardcoded secrets or debug logs
[ ] Linting passing
[ ] Coverage >80%

Performance:
[ ] Load tested (at 2x expected peak load)
[ ] No memory leaks detected
[ ] Database queries optimized
[ ] API response time <500ms

Security:
[ ] No SQL injection vulnerabilities
[ ] No hardcoded credentials
[ ] HTTPS enforced
[ ] Input validation in place
[ ] Rate limiting configured

Monitoring:
[ ] CloudWatch alarms configured
[ ] Sentry error tracking enabled
[ ] Logs being collected
[ ] Dashboards ready

Rollback:
[ ] Previous version identified
[ ] Rollback procedure documented
[ ] Team trained on rollback
[ ] Automated rollback tested

Communication:
[ ] Team notified of deployment time
[ ] Status page ready
[ ] Support team briefed
[ ] Customer communication prepared
```

---

## Emergency Contacts & Escalation

**During Incident:**

```
1. Try to resolve with immediate team
   (5-10 minutes max)

2. If stuck, call tech lead
   [Phone number]

3. If tech lead unreachable, call backup
   [Backup contact]

4. Declare SEVERITY 1 if:
   - No resolution within 10 minutes
   - User data at risk
   - Complete outage
   - Security breach

5. Page on-call team:
   PagerDuty → /incident declare SEVERITY1
```

**Post-Incident:**

```
1. Declare incident resolved
2. Schedule PIR within 24 hours
3. Document findings
4. Create action items
5. Track resolution of action items
```

---

## Summary: Incident Response Playbook

✅ **Detect** → Alert → Slack → Page team  
✅ **Assess** → Gather info → Classify severity  
✅ **Declare** → Create incident channel → War room  
✅ **Investigate** → Check logs → Find root cause  
✅ **Mitigate** → Fix or rollback → Verify  
✅ **Communicate** → Updates every 15 min → Status page  
✅ **Resolve** → All checks pass → Announce  
✅ **Review** → PIR within 24h → Action items → Close  

**Remember:** User > System > Code

If you have to choose between perfect code and happy users, choose happy users. We can fix code later. We can't fix angry users.

---

**Document Version:** 1.0  
**Last Updated:** January 30, 2026  
**Next Review:** April 30, 2026  
**Owner:** @tech-lead

---
