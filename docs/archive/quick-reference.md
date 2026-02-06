# RUPAYA: Implementation Quick-Reference Guide
## Code Examples & DevOps Templates (2026)

---

## QUICK SETUP SCRIPTS

### 1. Initialize Monorepo Structure

```bash
#!/bin/bash
# setup-monorepo.sh

mkdir -p rupaya-monorepo
cd rupaya-monorepo

# Backend
mkdir -p backend/src/{api,services,models,middleware,utils,config}
mkdir -p backend/tests backend/migrations
touch backend/package.json backend/Dockerfile backend/docker-compose.yml

# Web
npx create-next-app@latest web --typescript --tailwind --eslint
cd web && npm install zustand @tanstack/react-query axios zod react-hook-form
cd ..

# iOS
mkdir -p mobile-ios/Rupaya/{App,Features,Shared,Resources}

# Android  
mkdir -p mobile-android/app/src/main/java/com/rupaya/{ui,viewmodel,repository,network,di}

# Infrastructure
mkdir -p infrastructure/terraform/{modules,environments}
touch infrastructure/terraform/main.tf infrastructure/terraform/variables.tf

# GitHub workflows
mkdir -p .github/workflows
touch .github/workflows/{backend-ci,web-ci,ios-ci,android-ci,deploy}.yml

# Documentation
mkdir -p docs/{API,ARCHITECTURE,SECURITY,RUNBOOKS}
touch docs/README.md docs/ARCHITECTURE.md docs/SECURITY.md

# Root files
touch README.md .gitignore CONTRIBUTING.md

git init
git add .
git commit -m "chore: initial monorepo structure"

echo "✅ Monorepo initialized successfully!"
```

---

## Environment Configuration Templates

### Backend .env.example

```bash
# Server
NODE_ENV=development
PORT=3000
LOG_LEVEL=debug

# Database
DATABASE_URL=postgresql://rupaya_user:password@localhost:5432/rupaya
DATABASE_SSL=false
DATABASE_POOL_SIZE=10

# Redis
REDIS_URL=redis://localhost:6379/0
REDIS_PASSWORD=

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_REFRESH_SECRET=your-refresh-secret-key
JWT_EXPIRY=3600
JWT_REFRESH_EXPIRY=604800

# CORS
FRONTEND_URL=http://localhost:3000
ALLOWED_ORIGINS=localhost:3000,localhost:3001,*.rupaya.com

# AWS
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_S3_BUCKET=rupaya-media-dev

# Third-party Services
SENTRY_DSN=https://key@sentry.io/project
SENDGRID_API_KEY=your_sendgrid_key
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_KEY_SECRET=your_razorpay_secret

# App
APP_NAME=RUPAYA
APP_VERSION=1.0.0
API_BASE_URL=http://localhost:3000/v1
```

### Web .env.local

```bash
NEXT_PUBLIC_API_URL=http://localhost:3000/v1
NEXT_PUBLIC_APP_NAME=RUPAYA
NEXT_PUBLIC_SENTRY_DSN=https://key@sentry.io/project
```

### Mobile (iOS) Config

```swift
// Config.swift
struct Config {
    static let apiBaseURL = URL(string: "https://api.rupaya.com/v1")!
    static let sentryDSN = "https://key@sentry.io/project"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
}
```

### Mobile (Android) Config

```kotlin
// BuildConfig.gradle
buildConfigField "String", "API_BASE_URL", '"https://api.rupaya.com/v1"'
buildConfigField "String", "SENTRY_DSN", '"https://key@sentry.io/project"'
buildConfigField "String", "APP_VERSION", '"1.0.0"'
```

---

## GitHub Actions CI/CD Workflows

### Backend CI/CD

```yaml
# .github/workflows/backend-ci.yml
name: Backend CI/CD

on:
  push:
    branches: [main, develop, staging]
    paths:
      - 'backend/**'
      - '.github/workflows/backend-ci.yml'
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: rupaya_user
          POSTGRES_PASSWORD: password
          POSTGRES_DB: rupaya_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: 'backend/package-lock.json'
      
      - name: Install dependencies
        run: cd backend && npm ci
      
      - name: Lint
        run: cd backend && npm run lint
      
      - name: Type check
        run: cd backend && npm run typecheck
      
      - name: Run tests
        run: cd backend && npm run test:coverage
        env:
          DATABASE_URL: postgresql://rupaya_user:password@localhost:5432/rupaya_test
          REDIS_URL: redis://localhost:6379/0
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./backend/coverage/coverage-final.json
      
      - name: SonarQube scan
        uses: SonarSource/sonarcloud-github-action@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      
      - name: Security scan (Snyk)
        run: |
          npm install -g snyk
          snyk test --severity-threshold=high
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to ECR
        run: |
          aws ecr get-login-password --region ap-south-1 | \
          docker login --username AWS --password-stdin ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.ap-south-1.amazonaws.com
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: ./backend
          push: true
          tags: |
            ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.ap-south-1.amazonaws.com/rupaya-backend:${{ github.sha }}
            ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.ap-south-1.amazonaws.com/rupaya-backend:latest
          cache-from: type=registry,ref=${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.ap-south-1.amazonaws.com/rupaya-backend:buildcache
          cache-to: type=registry,ref=${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.ap-south-1.amazonaws.com/rupaya-backend:buildcache,mode=max

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster rupaya-cluster \
            --service rupaya-service \
            --force-new-deployment
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION: ap-south-1
      
      - name: Wait for service stability
        run: |
          aws ecs wait services-stable \
            --cluster rupaya-cluster \
            --services rupaya-service
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION: ap-south-1
      
      - name: Smoke test
        run: |
          curl -f https://api.rupaya.com/health || exit 1
```

### Web CI/CD

```yaml
# .github/workflows/web-ci.yml
name: Web CI/CD

on:
  push:
    branches: [main, develop, staging]
    paths:
      - 'web/**'
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: 'web/package-lock.json'
      
      - name: Install dependencies
        run: cd web && npm ci
      
      - name: Lint
        run: cd web && npm run lint
      
      - name: Type check
        run: cd web && npm run typecheck
      
      - name: Run tests
        run: cd web && npm run test -- --coverage
      
      - name: Build
        run: cd web && npm run build
      
      - name: Lighthouse audit
        uses: treosh/lighthouse-ci-action@v10
        with:
          uploadArtifacts: true
          temporaryPublicStorage: true
          configPath: './web/lighthouse-config.json'

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to Vercel
        run: |
          npm install -g vercel
          vercel --prod --token=${{ secrets.VERCEL_TOKEN }}
        env:
          VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
          VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
```

---

## Docker Configuration

### Backend Dockerfile

```dockerfile
# backend/Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source
COPY . .

# Build (if needed)
RUN npm run build || true

# Production stage
FROM node:20-alpine

WORKDIR /app

# Install dumb-init
RUN apk add --no-cache dumb-init

# Copy from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Expose port
EXPOSE 3000

# Run with dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/index.js"]
```

### Docker Compose (Local Dev)

```yaml
# backend/docker-compose.yml
version: '3.9'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: rupaya_user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: rupaya
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U rupaya_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    volumes:
      - redis_data:/data

  backend:
    build: .
    environment:
      NODE_ENV: development
      DATABASE_URL: postgresql://rupaya_user:password@postgres:5432/rupaya
      REDIS_URL: redis://redis:6379/0
      JWT_SECRET: dev-secret-key
      JWT_REFRESH_SECRET: dev-refresh-secret
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: npm run dev

volumes:
  postgres_data:
  redis_data:

networks:
  default:
    name: rupaya_network
```

---

## Database Initialization Script

```sql
-- backend/migrations/init.sql
-- Initialize database roles and permissions

-- Create role
CREATE ROLE rupaya_user WITH LOGIN PASSWORD 'password';

-- Grant permissions
GRANT CONNECT ON DATABASE rupaya TO rupaya_user;
GRANT USAGE ON SCHEMA public TO rupaya_user;
GRANT CREATE ON SCHEMA public TO rupaya_user;

-- Create audit log
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  action VARCHAR(255),
  resource_type VARCHAR(255),
  resource_id VARCHAR(255),
  changes JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- Enable row-level security
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, resource_type, resource_id, changes)
  VALUES (
    COALESCE(current_setting('app.current_user_id')::UUID, NULL),
    TG_OP,
    TG_TABLE_NAME,
    NEW.id::TEXT,
    row_to_json(NEW)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## Monitoring & Alerting Setup

### CloudWatch Monitoring (Terraform)

```hcl
# infrastructure/terraform/modules/monitoring/main.tf

resource "aws_cloudwatch_metric_alarm" "api_error_rate" {
  alarm_name          = "rupaya-api-error-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ErrorCount"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_response_time" {
  alarm_name          = "rupaya-api-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1.0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name          = "rupaya-db-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "db_connections" {
  alarm_name          = "rupaya-db-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}
```

---

## API Rate Limiting

```typescript
// backend/src/middleware/rate-limit.ts

import rateLimit, { Options } from 'express-rate-limit'
import RedisStore from 'rate-limit-redis'
import redis from 'redis'

const redisClient = redis.createClient({
  url: process.env.REDIS_URL,
})

// General API limiter: 100 requests per 15 minutes
export const apiLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:api:',
  }),
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Too many requests, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
})

// Login limiter: 5 attempts per 15 minutes
export const loginLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:login:',
  }),
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true,
  skipFailedRequests: false,
})

// Transaction limiter: 1000 per hour
export const transactionLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:txn:',
  }),
  windowMs: 60 * 60 * 1000,
  max: 1000,
  keyGenerator: (req) => req.user?.id || req.ip,
})
```

---

## Logging Configuration

```typescript
// backend/src/utils/logger.ts

import pino from 'pino'

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'SYS:standard',
      ignore: 'pid,hostname',
    },
  },
})

// For production, send to CloudWatch
if (process.env.NODE_ENV === 'production') {
  const transport = pino.transport({
    targets: [
      {
        target: 'pino-stackdriver',
        options: {
          projectId: process.env.GCP_PROJECT_ID,
        },
      },
      {
        target: 'pino-http-send',
        options: {
          uri: 'https://logs.rupaya.com/ingest',
        },
      },
    ],
  })
  logger.addTransport(transport)
}

export default logger
```

---

## Testing Examples

### Backend Integration Test

```typescript
// backend/src/routes/__tests__/auth.test.ts

import request from 'supertest'
import app from '../../index'
import { AppDataSource } from '../../database/data-source'

describe('Auth Routes', () => {
  beforeAll(async () => {
    await AppDataSource.initialize()
  })

  afterAll(async () => {
    await AppDataSource.destroy()
  })

  describe('POST /v1/auth/signup', () => {
    it('should create a new user', async () => {
      const response = await request(app)
        .post('/v1/auth/signup')
        .send({
          email: 'test@example.com',
          password: 'SecurePassword123!',
          full_name: 'Test User',
        })
        .expect(201)

      expect(response.body).toHaveProperty('access_token')
      expect(response.body).toHaveProperty('refresh_token')
      expect(response.body.user.email).toBe('test@example.com')
    })

    it('should reject duplicate email', async () => {
      await request(app)
        .post('/v1/auth/signup')
        .send({
          email: 'duplicate@example.com',
          password: 'SecurePassword123!',
          full_name: 'User One',
        })

      await request(app)
        .post('/v1/auth/signup')
        .send({
          email: 'duplicate@example.com',
          password: 'DifferentPassword123!',
          full_name: 'User Two',
        })
        .expect(400)
    })

    it('should reject weak passwords', async () => {
      await request(app)
        .post('/v1/auth/signup')
        .send({
          email: 'weak@example.com',
          password: 'weak',
          full_name: 'Test User',
        })
        .expect(400)
    })
  })

  describe('POST /v1/auth/login', () => {
    beforeEach(async () => {
      await request(app)
        .post('/v1/auth/signup')
        .send({
          email: 'login@example.com',
          password: 'SecurePassword123!',
          full_name: 'Login Test',
        })
    })

    it('should login with correct credentials', async () => {
      const response = await request(app)
        .post('/v1/auth/login')
        .send({
          email: 'login@example.com',
          password: 'SecurePassword123!',
        })
        .expect(200)

      expect(response.body).toHaveProperty('access_token')
      expect(response.body).toHaveProperty('refresh_token')
    })

    it('should reject incorrect password', async () => {
      await request(app)
        .post('/v1/auth/login')
        .send({
          email: 'login@example.com',
          password: 'WrongPassword',
        })
        .expect(401)
    })
  })
})
```

### Web Component Test

```typescript
// web/src/components/__tests__/TransactionList.test.tsx

import { render, screen } from '@testing-library/react'
import TransactionList from '../TransactionList'

describe('TransactionList', () => {
  const mockTransactions = [
    {
      id: '1',
      type: 'income',
      amount: 1000,
      description: 'Salary',
      created_at: '2026-02-01',
    },
    {
      id: '2',
      type: 'expense',
      amount: 500,
      description: 'Groceries',
      created_at: '2026-02-02',
    },
  ]

  it('should render transaction list', () => {
    render(<TransactionList transactions={mockTransactions} />)
    
    expect(screen.getByText('Salary')).toBeInTheDocument()
    expect(screen.getByText('Groceries')).toBeInTheDocument()
    expect(screen.getByText('+₹1000')).toBeInTheDocument()
    expect(screen.getByText('-₹500')).toBeInTheDocument()
  })

  it('should show empty state when no transactions', () => {
    render(<TransactionList transactions={[]} />)
    
    expect(screen.getByText('No transactions yet')).toBeInTheDocument()
  })

  it('should handle loading state', () => {
    render(<TransactionList transactions={undefined} />)
    
    expect(screen.getByRole('status')).toBeInTheDocument()
  })
})
```

---

## Security Headers Configuration

```typescript
// backend/src/middleware/security-headers.ts

import helmet from 'helmet'
import express, { Express } from 'express'

export function setupSecurityHeaders(app: Express) {
  // Helmet middleware
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        connectSrc: ["'self'", 'https://api.rupaya.com'],
        fontSrc: ["'self'", 'https://fonts.googleapis.com'],
        frameSrc: ["'none'"],
      },
    },
    crossOriginEmbedderPolicy: true,
    crossOriginOpenerPolicy: true,
    crossOriginResourcePolicy: { policy: 'same-site' },
    dnsPrefetchControl: true,
    frameguard: { action: 'deny' },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true,
    },
    noSniff: true,
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
    xssFilter: true,
  }))

  // Additional security headers
  app.use((req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff')
    res.setHeader('X-Frame-Options', 'DENY')
    res.setHeader('X-XSS-Protection', '1; mode=block')
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains')
    res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()')
    next()
  })
}
```

---

## Feature Flags Implementation

```typescript
// backend/src/utils/feature-flags.ts

import Redis from 'redis'

export class FeatureFlags {
  private redis: Redis.RedisClient

  constructor(redisClient: Redis.RedisClient) {
    this.redis = redisClient
  }

  async isEnabled(flag: string, userId?: string): Promise<boolean> {
    try {
      // Check if feature is enabled globally
      const globalKey = `feature:${flag}:enabled`
      const isGloballyEnabled = await this.redis.get(globalKey)

      if (isGloballyEnabled === 'true') {
        return true
      }

      // Check if enabled for specific user
      if (userId) {
        const userKey = `feature:${flag}:user:${userId}`
        const isUserEnabled = await this.redis.get(userKey)
        return isUserEnabled === 'true'
      }

      return false
    } catch (error) {
      console.error('Feature flag check failed:', error)
      return false // Fail closed for safety
    }
  }

  async setFlag(flag: string, enabled: boolean, ttl = 3600): Promise<void> {
    const key = `feature:${flag}:enabled`
    if (enabled) {
      await this.redis.setex(key, ttl, 'true')
    } else {
      await this.redis.del(key)
    }
  }

  async setUserFlag(flag: string, userId: string, enabled: boolean): Promise<void> {
    const key = `feature:${flag}:user:${userId}`
    if (enabled) {
      await this.redis.set(key, 'true')
    } else {
      await this.redis.del(key)
    }
  }
}

// Usage
const featureFlags = new FeatureFlags(redisClient)

app.get('/api/transactions/export', async (req, res) => {
  const isExportEnabled = await featureFlags.isEnabled('export_transactions', req.user.id)
  
  if (!isExportEnabled) {
    return res.status(403).json({ error: 'Feature not available' })
  }

  // ... export logic
})
```

---

## Deployment Rollback Script

```bash
#!/bin/bash
# scripts/rollback.sh

set -e

CLUSTER_NAME="rupaya-cluster"
SERVICE_NAME="rupaya-service"
REGION="ap-south-1"

echo "🔄 Starting rollback..."

# Get current task definition
CURRENT_TASK_DEF=$(aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --region $REGION \
  --query 'services[0].taskDefinition' \
  --output text)

# Extract version number
CURRENT_VERSION=$(echo $CURRENT_TASK_DEF | awk -F: '{print $NF}')
PREVIOUS_VERSION=$((CURRENT_VERSION - 1))

echo "Current version: $CURRENT_VERSION"
echo "Rolling back to version: $PREVIOUS_VERSION"

# Update service to use previous task definition
TASK_FAMILY=$(echo $CURRENT_TASK_DEF | cut -d: -f6)
PREVIOUS_TASK_DEF="$TASK_FAMILY:$PREVIOUS_VERSION"

aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --task-definition $PREVIOUS_TASK_DEF \
  --region $REGION

echo "⏳ Waiting for rollback to complete..."

aws ecs wait services-stable \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --region $REGION

# Verify health
HEALTH=$(curl -s https://api.rupaya.com/health | jq -r '.status')

if [ "$HEALTH" = "ok" ]; then
  echo "✅ Rollback successful!"
  exit 0
else
  echo "❌ Health check failed after rollback"
  exit 1
fi
```

---

## Useful AWS CLI Commands

```bash
# View ECS logs
aws logs tail /ecs/rupaya-backend --follow

# Restart service
aws ecs update-service --cluster rupaya-cluster --service rupaya-service --force-new-deployment

# Scale service
aws ecs update-service --cluster rupaya-cluster --service rupaya-service --desired-count 5

# Get service details
aws ecs describe-services --cluster rupaya-cluster --services rupaya-service

# SSH into EC2 instance
aws ssm start-session --target i-1234567890abcdef0

# View RDS metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --start-time 2026-02-01T00:00:00Z \
  --end-time 2026-02-02T00:00:00Z \
  --period 300 \
  --statistics Average

# Backup database
aws rds create-db-snapshot \
  --db-instance-identifier rupaya-prod \
  --db-snapshot-identifier rupaya-backup-2026-02-01

# View CloudWatch logs
aws logs describe-log-groups
aws logs describe-log-streams --log-group-name /ecs/rupaya-backend
```

---

This Quick-Reference Guide provides concrete, copy-paste-ready templates for immediate implementation. Combine with the main roadmap for complete coverage!