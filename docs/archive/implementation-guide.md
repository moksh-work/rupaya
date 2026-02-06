# RUPAYA Money Manager - Complete Implementation Guide

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Backend Services](#backend-services)
3. [Database Schema](#database-schema)
4. [API Endpoints](#api-endpoints)
5. [iOS Implementation](#ios-implementation)
6. [Android Implementation](#android-implementation)
7. [Testing Strategy](#testing-strategy)
8. [CI/CD Pipeline](#cicd-pipeline)
9. [AWS Deployment](#aws-deployment)
10. [Security Hardening](#security-hardening)
11. [Monitoring & Alerting](#monitoring--alerting)

---

## System Architecture

### High-Level Overview
```
┌─────────────────┐         ┌─────────────────┐
│   iOS App       │         │  Android App    │
│   (SwiftUI)     │         │  (Jetpack)      │
└────────┬────────┘         └────────┬────────┘
         │                           │
         └───────────────┬───────────┘
                         │
                    ┌────▼─────┐
                    │ API GW   │
                    │ + Auth   │
                    └────┬─────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼─────┐  ┌──────▼──────┐ ┌────▼────┐
    │ Backend   │  │  PostgreSQL │ │  Redis  │
    │ (Node.js) │  │  (Primary)  │ │ (Cache) │
    └────┬─────┘  └─────────────┘ └────────┘
         │
    ┌────▼──────────────┐
    │   AWS Services    │
    │ - S3 (Backups)    │
    │ - CloudWatch      │
    │ - RDS Aurora      │
    │ - Lambda (Jobs)   │
    └───────────────────┘
```

### Technology Stack

**Backend**
- Runtime: Node.js 18+
- Framework: Express.js 4.18+
- Database: PostgreSQL 15+ (Aurora)
- Cache: Redis 7+
- Auth: JWT + OAuth2 + MFA (TOTP)
- Storage: AWS S3
- Message Queue: Redis Streams

**iOS**
- Language: Swift 5.9+
- UI Framework: SwiftUI
- Architecture: MVVM + Combine
- Networking: URLSession
- Storage: Keychain
- Auth: Biometric + Certificate Pinning

**Android**
- Language: Kotlin
- UI Framework: Jetpack Compose
- Architecture: MVVM + Coroutines
- Networking: Retrofit + OkHttp
- Storage: EncryptedSharedPreferences
- Auth: Biometric + Certificate Pinning

---

## Backend Services

### Transaction Service

```javascript
// src/services/TransactionService.js
class TransactionService {
  static async createTransaction(userId, transactionData) {
    // Validate amount
    if (transactionData.amount <= 0) {
      throw new Error('Amount must be positive');
    }

    // Get account and verify ownership
    const account = await Account.findById(transactionData.accountId);
    if (account.user_id !== userId) {
      throw new Error('Unauthorized');
    }

    // Check balance for expense
    if (transactionData.type === 'expense' && account.current_balance < transactionData.amount) {
      throw new Error('Insufficient balance');
    }

    // Create transaction
    const transaction = await db('transactions').insert({
      transaction_id: uuidv4(),
      user_id: userId,
      account_id: transactionData.accountId,
      amount: transactionData.amount,
      currency: transactionData.currency || 'INR',
      transaction_type: transactionData.type,
      category_id: transactionData.categoryId,
      description: transactionData.description,
      transaction_date: transactionData.date || new Date(),
      created_at: new Date()
    }).returning('*');

    // Update account balance
    const multiplier = transactionData.type === 'expense' ? -1 : 1;
    await db('accounts')
      .where({ account_id: transactionData.accountId })
      .update({
        current_balance: db.raw('current_balance + ?', [transactionData.amount * multiplier]),
        updated_at: new Date()
      });

    // Publish event for analytics
    await this.publishTransactionEvent(userId, transaction[0]);

    return transaction[0];
  }

  static async getTransactions(userId, filters = {}) {
    let query = db('transactions')
      .where({ user_id: userId, is_deleted: false })
      .select(
        'transactions.*',
        'categories.name as category_name',
        'accounts.name as account_name'
      )
      .leftJoin('categories', 'transactions.category_id', 'categories.category_id')
      .leftJoin('accounts', 'transactions.account_id', 'accounts.account_id');

    // Apply filters
    if (filters.accountId) {
      query = query.where('transactions.account_id', filters.accountId);
    }

    if (filters.categoryId) {
      query = query.where('transactions.category_id', filters.categoryId);
    }

    if (filters.startDate && filters.endDate) {
      query = query.whereBetween('transactions.transaction_date', [filters.startDate, filters.endDate]);
    }

    if (filters.type) {
      query = query.where('transactions.transaction_type', filters.type);
    }

    const transactions = await query
      .orderBy('transactions.transaction_date', 'desc')
      .limit(filters.limit || 100)
      .offset(filters.offset || 0);

    return transactions;
  }

  static async deleteTransaction(userId, transactionId) {
    const transaction = await db('transactions')
      .where({ transaction_id: transactionId, user_id: userId })
      .first();

    if (!transaction) {
      throw new Error('Transaction not found');
    }

    // Revert balance
    const multiplier = transaction.transaction_type === 'expense' ? 1 : -1;
    await db('accounts')
      .where({ account_id: transaction.account_id })
      .update({
        current_balance: db.raw('current_balance + ?', [transaction.amount * multiplier]),
        updated_at: new Date()
      });

    // Soft delete
    return await db('transactions')
      .where({ transaction_id: transactionId })
      .update({ is_deleted: true });
  }

  static async publishTransactionEvent(userId, transaction) {
    const redis = require('redis').createClient();
    await redis.publish(`user:${userId}:transactions`, JSON.stringify(transaction));
    redis.disconnect();
  }
}

module.exports = TransactionService;
```

### Analytics Service

```javascript
// src/services/AnalyticsService.js
class AnalyticsService {
  static async getDashboardStats(userId, dateRange = 'month') {
    const endDate = new Date();
    const startDate = this.getStartDate(endDate, dateRange);

    // Get transactions for period
    const transactions = await db('transactions')
      .where('user_id', userId)
      .whereBetween('transaction_date', [startDate, endDate])
      .where('is_deleted', false);

    // Calculate totals
    const income = transactions
      .filter(t => t.transaction_type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);

    const expenses = transactions
      .filter(t => t.transaction_type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);

    // Get spending by category
    const spendingByCategory = await db('transactions')
      .select('categories.name', db.raw('SUM(amount) as total'))
      .where('transactions.user_id', userId)
      .where('transactions.transaction_type', 'expense')
      .whereBetween('transactions.transaction_date', [startDate, endDate])
      .join('categories', 'transactions.category_id', 'categories.category_id')
      .groupBy('categories.category_id', 'categories.name')
      .orderBy('total', 'desc');

    return {
      period: dateRange,
      startDate,
      endDate,
      income,
      expenses,
      savings: income - expenses,
      spendingByCategory: spendingByCategory.map(row => ({
        category: row.name,
        amount: parseFloat(row.total)
      })),
      savingsRate: ((income - expenses) / income * 100).toFixed(2)
    };
  }

  static async getBudgetProgress(userId) {
    const budgets = await db('budgets')
      .where('user_id', userId)
      .where('period', 'month')
      .select('*');

    const budgetProgress = await Promise.all(budgets.map(async (budget) => {
      const spent = await db('transactions')
        .where('user_id', userId)
        .where('category_id', budget.category_id)
        .where('transaction_type', 'expense')
        .where('transaction_date', '>=', db.raw('DATE_TRUNC(\'month\', NOW())'))
        .sum('amount as total')
        .first();

      return {
        id: budget.budget_id,
        category: budget.category,
        limit: budget.amount,
        spent: spent.total || 0,
        remaining: budget.amount - (spent.total || 0),
        progress: ((spent.total || 0) / budget.amount * 100).toFixed(2)
      };
    }));

    return budgetProgress;
  }

  static getStartDate(endDate, dateRange) {
    const start = new Date(endDate);
    switch(dateRange) {
      case 'week':
        start.setDate(start.getDate() - 7);
        break;
      case 'month':
        start.setMonth(start.getMonth() - 1);
        break;
      case 'year':
        start.setFullYear(start.getFullYear() - 1);
        break;
      default:
        start.setMonth(start.getMonth() - 1);
    }
    return start;
  }
}

module.exports = AnalyticsService;
```

---

## API Endpoints

### Authentication Endpoints

```
POST /api/v1/auth/signup
Headers: Content-Type: application/json
Body: {
  "email": "user@example.com",
  "password": "SecurePass123!",
  "deviceId": "device-uuid",
  "deviceName": "iPhone 15"
}
Response: {
  "userId": "uuid",
  "accessToken": "jwt-token",
  "refreshToken": "jwt-token",
  "user": { ... }
}

POST /api/v1/auth/signin
Body: {
  "email": "user@example.com",
  "password": "SecurePass123!",
  "deviceId": "device-uuid"
}
Response: { ... same as signup }

POST /api/v1/auth/refresh
Body: { "refreshToken": "jwt-token" }
Response: { "accessToken": "new-jwt-token" }

POST /api/v1/auth/mfa/setup
Headers: Authorization: Bearer {token}
Response: {
  "secret": "base32-secret",
  "qrCode": "data:image/png;base64...",
  "backupCodes": ["CODE1", "CODE2", ...]
}

POST /api/v1/auth/mfa/verify
Body: { "token": "123456" }
Response: { "accessToken": "jwt-token" }
```

### Transaction Endpoints

```
POST /api/v1/transactions
Headers: Authorization: Bearer {token}
Body: {
  "accountId": "uuid",
  "amount": 500.50,
  "type": "expense",
  "categoryId": "uuid",
  "description": "Grocery shopping",
  "date": "2026-01-27"
}
Response: { "transactionId": "uuid", ... }

GET /api/v1/transactions?accountId=uuid&startDate=2026-01-01&endDate=2026-01-31
Response: [
  {
    "transactionId": "uuid",
    "amount": 500.50,
    "type": "expense",
    "categoryName": "Groceries",
    "accountName": "Checking",
    "transactionDate": "2026-01-27"
  }
]

DELETE /api/v1/transactions/{transactionId}
Response: { "success": true }
```

### Analytics Endpoints

```
GET /api/v1/analytics/dashboard?period=month
Response: {
  "period": "month",
  "income": 50000,
  "expenses": 15000,
  "savings": 35000,
  "savingsRate": 70.00,
  "spendingByCategory": [
    { "category": "Groceries", "amount": 5000 },
    { "category": "Dining", "amount": 3000 }
  ]
}

GET /api/v1/analytics/budget-progress
Response: [
  {
    "category": "Groceries",
    "limit": 5000,
    "spent": 3200,
    "remaining": 1800,
    "progress": 64.00
  }
]
```

---

## Testing Strategy

### Unit Tests

```javascript
// backend/__tests__/services/AuthService.test.js
describe('AuthService', () => {
  describe('signup', () => {
    it('should create new user with hashed password', async () => {
      const result = await AuthService.signup(
        'test@example.com',
        'SecurePass123!',
        'device-id',
        'Device Name'
      );

      expect(result.userId).toBeDefined();
      expect(result.accessToken).toBeDefined();
      expect(result.user.email).toBe('test@example.com');
    });

    it('should reject weak passwords', async () => {
      await expect(
        AuthService.signup('test@example.com', 'weak', 'device-id', 'Device')
      ).rejects.toThrow('Password is too weak');
    });

    it('should reject pwned passwords', async () => {
      await expect(
        AuthService.signup('test@example.com', 'password123', 'device-id', 'Device')
      ).rejects.toThrow('This password has been breached');
    });

    it('should reject duplicate email', async () => {
      await AuthService.signup('test@example.com', 'SecurePass123!', 'device-id', 'Device');
      
      await expect(
        AuthService.signup('test@example.com', 'SecurePass456!', 'device-id', 'Device')
      ).rejects.toThrow('User already exists');
    });
  });

  describe('signin', () => {
    beforeEach(async () => {
      await AuthService.signup('test@example.com', 'SecurePass123!', 'device-id', 'Device');
    });

    it('should return tokens on valid credentials', async () => {
      const result = await AuthService.signin('test@example.com', 'SecurePass123!', 'device-id');
      
      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
      expect(result.user.email).toBe('test@example.com');
    });

    it('should reject invalid password', async () => {
      await expect(
        AuthService.signin('test@example.com', 'WrongPassword', 'device-id')
      ).rejects.toThrow('Invalid email or password');
    });

    it('should lock account after 5 failed attempts', async () => {
      for (let i = 0; i < 5; i++) {
        try {
          await AuthService.signin('test@example.com', 'WrongPassword', 'device-id');
        } catch (e) {}
      }

      await expect(
        AuthService.signin('test@example.com', 'SecurePass123!', 'device-id')
      ).rejects.toThrow('Account temporarily locked');
    });
  });
});
```

### Integration Tests

```javascript
// backend/__tests__/integration/transaction.test.js
describe('Transaction API Integration', () => {
  let app, authToken, accountId, userId;

  beforeAll(async () => {
    app = require('../../src/app');
    // Signup
    const signupRes = await request(app)
      .post('/api/v1/auth/signup')
      .send({
        email: 'test@example.com',
        password: 'SecurePass123!',
        deviceId: 'test-device',
        deviceName: 'Test Device'
      });

    authToken = signupRes.body.accessToken;
    userId = signupRes.body.userId;

    // Create account
    const accountRes = await request(app)
      .post('/api/v1/accounts')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: 'Test Checking',
        type: 'checking',
        currency: 'INR'
      });

    accountId = accountRes.body.accountId;
  });

  it('should create transaction and update balance', async () => {
    const res = await request(app)
      .post('/api/v1/transactions')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        accountId: accountId,
        amount: 500,
        type: 'expense',
        categoryId: 'grocery-category',
        description: 'Test transaction'
      });

    expect(res.status).toBe(201);
    expect(res.body.transactionId).toBeDefined();

    // Verify balance updated
    const accountRes = await request(app)
      .get(`/api/v1/accounts/${accountId}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(accountRes.body.currentBalance).toBe(-500);
  });

  it('should prevent overdraft', async () => {
    const res = await request(app)
      .post('/api/v1/transactions')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        accountId: accountId,
        amount: 100000,
        type: 'expense',
        categoryId: 'test-category'
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toContain('Insufficient balance');
  });
});
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: RUPAYA CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  AWS_REGION: ap-south-1
  ECR_REPOSITORY: rupaya-backend
  ECS_SERVICE: rupaya-service
  ECS_CLUSTER: rupaya-cluster

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: rupaya_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: cd backend && npm install

      - name: Run linting
        run: cd backend && npm run lint

      - name: Run unit tests
        run: cd backend && npm test
        env:
          DB_HOST: localhost
          DB_USER: postgres
          DB_PASSWORD: postgres
          DB_NAME: rupaya_test
          REDIS_URL: redis://localhost:6379

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./backend/coverage/lcov.info

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build Docker image
        run: |
          docker build -t ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ github.sha }} \
                       -t ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:latest \
                       -f backend/Dockerfile \
                       ./backend

      - name: Push to ECR
        run: |
          docker push ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ github.sha }}
          docker push ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster ${{ env.ECS_CLUSTER }} \
            --service ${{ env.ECS_SERVICE }} \
            --force-new-deployment

      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK }}
          payload: |
            {
              "text": "RUPAYA deployed successfully to production"
            }
```

---

## AWS Deployment

### Infrastructure as Code (Terraform)

```hcl
# terraform/main.tf

provider "aws" {
  region = var.aws_region
}

# RDS Aurora PostgreSQL
resource "aws_rds_cluster" "rupaya" {
  cluster_identifier      = "rupaya-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "14.6"
  database_name           = "rupaya"
  master_username         = var.db_username
  master_password         = var.db_password
  backup_retention_period = 30
  preferred_backup_window = "03:00-04:00"
  skip_final_snapshot     = false
  final_snapshot_identifier = "rupaya-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name = "rupaya-db"
  }
}

resource "aws_rds_cluster_instance" "rupaya" {
  count              = 2
  cluster_identifier = aws_rds_cluster.rupaya.id
  instance_class     = "db.t4g.medium"
  engine             = aws_rds_cluster.rupaya.engine
  engine_version     = aws_rds_cluster.rupaya.engine_version
  publicly_accessible = false

  tags = {
    Name = "rupaya-db-instance-${count.index + 1}"
  }
}

# ElastiCache Redis
resource "aws_elasticache_cluster" "rupaya" {
  cluster_id           = "rupaya-redis"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379
  automatic_failover_enabled = true

  tags = {
    Name = "rupaya-cache"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "rupaya" {
  name = "rupaya-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECR Repository
resource "aws_ecr_repository" "rupaya" {
  name                 = "rupaya-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# S3 Backup Bucket
resource "aws_s3_bucket" "rupaya_backups" {
  bucket = "rupaya-backups-${var.environment}"
}

resource "aws_s3_bucket_versioning" "rupaya_backups" {
  bucket = aws_s3_bucket.rupaya_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rupaya_backups" {
  bucket = aws_s3_bucket.rupaya_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

---

## Security Hardening

### OWASP Top 10 Protection

```javascript
// src/middleware/securityHeaders.js
const securityHeaders = (req, res, next) => {
  // Prevent clickjacking
  res.setHeader('X-Frame-Options', 'DENY');

  // Prevent MIME sniffing
  res.setHeader('X-Content-Type-Options', 'nosniff');

  // Enable XSS protection
  res.setHeader('X-XSS-Protection', '1; mode=block');

  // Content Security Policy
  res.setHeader('Content-Security-Policy', 
    "default-src 'self'; " +
    "script-src 'self' 'unsafe-inline'; " +
    "style-src 'self' 'unsafe-inline'; " +
    "img-src 'self' data: https:; " +
    "font-src 'self' data:; " +
    "connect-src 'self' https://api.rupaya.in"
  );

  // Strict Transport Security
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');

  // Referrer Policy
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

  // Permissions Policy
  res.setHeader('Permissions-Policy', 
    'geolocation=(), microphone=(), camera=(), payment=()'
  );

  next();
};

module.exports = securityHeaders;
```

### Input Validation & Sanitization

```javascript
// src/middleware/validation.js
const { body, query, validationResult } = require('express-validator');
const xss = require('xss');
const mongoSanitize = require('mongo-sanitize');

// Transaction validation
const validateTransaction = [
  body('amount')
    .isFloat({ min: 0.01, max: 999999999 })
    .withMessage('Invalid amount'),
  body('description')
    .trim()
    .isLength({ max: 500 })
    .withMessage('Description too long')
    .custom(value => {
      const clean = xss(value);
      if (clean !== value) throw new Error('XSS detected');
      return true;
    }),
  body('categoryId')
    .isUUID()
    .withMessage('Invalid category'),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    next();
  }
];

// Query sanitization
const sanitizeQuery = (req, res, next) => {
  Object.keys(req.query).forEach(key => {
    req.query[key] = mongoSanitize.sanitize(req.query[key]);
  });
  next();
};

module.exports = { validateTransaction, sanitizeQuery };
```

---

## Monitoring & Alerting

### CloudWatch Configuration

```javascript
// src/utils/monitoring.js
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

class MonitoringService {
  static async logMetric(metricName, value, unit = 'Count') {
    const params = {
      MetricData: [
        {
          MetricName: metricName,
          Value: value,
          Unit: unit,
          Timestamp: new Date()
        }
      ],
      Namespace: 'RUPAYA'
    };

    await cloudwatch.putMetricData(params).promise();
  }

  static async logApiLatency(endpoint, duration) {
    await this.logMetric(`API_${endpoint}_Latency`, duration, 'Milliseconds');
  }

  static async logTransactionCount(userId) {
    await this.logMetric('Transactions_Created', 1);
  }

  static async logError(errorType, context) {
    const params = {
      LogGroupName: '/aws/rupaya/errors',
      LogStreamName: new Date().toISOString().split('T')[0],
      LogEvents: [
        {
          Message: JSON.stringify({
            type: errorType,
            context,
            timestamp: new Date().toISOString()
          }),
          Timestamp: Date.now()
        }
      ]
    };

    const cloudwatchlogs = new AWS.CloudWatchLogs();
    await cloudwatchlogs.putLogEvents(params).promise();
  }
}

module.exports = MonitoringService;
```

### Alerting Configuration

```yaml
# monitoring/cloudwatch-alarms.yaml
Alarms:
  - AlarmName: RUPAYA-API-HighErrorRate
    MetricName: APIErrors
    Threshold: 100
    ComparisonOperator: GreaterThanThreshold
    Period: 300
    EvaluationPeriods: 2
    AlarmActions:
      - arn:aws:sns:ap-south-1:123456789:rupaya-alerts

  - AlarmName: RUPAYA-DB-HighCPU
    MetricName: CPUUtilization
    Threshold: 80
    ComparisonOperator: GreaterThanThreshold
    Period: 300
    AlarmActions:
      - arn:aws:sns:ap-south-1:123456789:rupaya-alerts

  - AlarmName: RUPAYA-Cache-MemoryHigh
    MetricName: DatabaseMemoryUsagePercentage
    Threshold: 90
    ComparisonOperator: GreaterThanThreshold
    Period: 300
    AlarmActions:
      - arn:aws:sns:ap-south-1:123456789:rupaya-alerts

  - AlarmName: RUPAYA-Auth-HighFailureRate
    MetricName: FailedAuthAttempts
    Threshold: 50
    ComparisonOperator: GreaterThanThreshold
    Period: 300
    AlarmActions:
      - arn:aws:sns:ap-south-1:123456789:rupaya-alerts
```

---

## Performance Optimization

### Database Query Optimization

```sql
-- Add indices for common queries
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX idx_transactions_account_date ON transactions(account_id, transaction_date DESC);
CREATE INDEX idx_accounts_user ON accounts(user_id);
CREATE INDEX idx_categories_user ON categories(user_id);

-- Composite index for analytics
CREATE INDEX idx_analytics_lookup ON transactions(user_id, transaction_type, transaction_date);
```

### Caching Strategy

```javascript
// src/middleware/caching.js
const redis = require('redis');
const client = redis.createClient({
  url: process.env.REDIS_URL
});

const cacheMiddleware = (duration = 300) => {
  return async (req, res, next) => {
    const cacheKey = `${req.user.userId}:${req.path}`;
    
    try {
      const cached = await client.get(cacheKey);
      if (cached) {
        return res.json(JSON.parse(cached));
      }
    } catch (err) {
      // Continue on cache miss
    }

    const originalJson = res.json;
    res.json = function(data) {
      client.setex(cacheKey, duration, JSON.stringify(data)).catch(err => {
        logger.error('Cache set error:', err);
      });
      
      return originalJson.call(this, data);
    };

    next();
  };
};

module.exports = cacheMiddleware;
```

---

## Deployment Checklist

### Pre-Production
- [ ] All tests passing (>80% coverage)
- [ ] Code review completed
- [ ] Security audit passed
- [ ] Performance testing completed
- [ ] Database backups verified
- [ ] Secrets rotated
- [ ] SSL certificates valid
- [ ] Documentation updated

### Production Deployment
- [ ] Blue-green deployment setup
- [ ] Health checks configured
- [ ] Monitoring alerts active
- [ ] Rollback plan ready
- [ ] Communication plan executed
- [ ] On-call team notified
- [ ] Database migration tested
- [ ] Backup completed

### Post-Deployment
- [ ] Monitor error rates (should be <0.1%)
- [ ] Check performance metrics
- [ ] Verify all endpoints responding
- [ ] Monitor database performance
- [ ] Review logs for issues
- [ ] Get team feedback
- [ ] Document lessons learned

---

## Support & Resources

- **GitHub Issues**: Report bugs
- **Slack Channel**: #rupaya-dev
- **Documentation**: `/docs/`
- **Architecture Decisions**: `/docs/ADR/`
- **Runbooks**: `/docs/RUNBOOKS/`
