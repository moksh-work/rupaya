# RUPAYA Complete Build & Launch Plan (Level 0 → Production)

**Your Goal:** Build industry-grade financial app with Android, iOS, and Web  
**Timeline:** 12-16 weeks (solo/small team)  
**Scope:** Backend API, iOS app, Android app, Web dashboard  
**Target:** Production launch with 100K+ users capacity

---

## Phase 0: Foundation & Planning (Week 1)

### 0.1: Define Requirements & Scope

**Core Features (MVP):**
```
User Authentication:
✓ Email/password signup & signin
✓ 2FA via authenticator app (TOTP)
✓ Biometric login (Face ID, Touch ID, fingerprint)
✓ Password reset with email verification
✓ Device management & logout

Financial Management:
✓ Create accounts (checking, savings, etc)
✓ Add transactions (income/expense)
✓ View transaction history
✓ Transaction search & filtering
✓ Category management (predefined + custom)

Dashboard & Analytics:
✓ Account overview (balance, recent transactions)
✓ Monthly spending breakdown
✓ Budget tracking
✓ Charts & visualizations

Security:
✓ End-to-end data encryption
✓ Rate limiting
✓ OWASP Top 10 protection
✓ Audit logging
```

**Non-MVP (Phase 2):**
- Bill reminders
- Investments tracking
- AI-powered insights
- International transfers
- Cryptocurrency integration

### 0.2: Tech Stack Decision

**Backend:**
- **Runtime:** Node.js 18+ (JavaScript)
- **Framework:** Express.js 4.18+
- **Database:** PostgreSQL 15 (relational, strong ACID)
- **Cache:** Redis 7 (sessions, rate limiting)
- **Job Queue:** Bull (background jobs)
- **Testing:** Jest + Supertest
- **Logging:** Winston
- **Monitoring:** CloudWatch + Sentry

**iOS:**
- **Language:** Swift 5.9+
- **UI:** SwiftUI (modern, declarative)
- **Architecture:** MVVM + Combine
- **Networking:** URLSession (native)
- **Testing:** XCTest
- **Dependency Manager:** CocoaPods

**Android:**
- **Language:** Kotlin 1.9+
- **UI:** Jetpack Compose (modern)
- **Architecture:** MVVM + Coroutines
- **Networking:** Retrofit + OkHttp
- **DI:** Hilt
- **Testing:** JUnit + Espresso

**Web:**
- **Framework:** React 18+ or Next.js 14+
- **Styling:** TailwindCSS
- **State:** Redux or Zustand
- **Deployment:** Vercel or AWS S3 + CloudFront
- **Dashboard:** Recharts or Chart.js

**Infrastructure:**
- **Cloud:** AWS (ap-south-1 region, India)
- **Database:** RDS Aurora PostgreSQL
- **Cache:** ElastiCache Redis
- **Container:** ECS + ECR (or Lambda for serverless)
- **Storage:** S3
- **CDN:** CloudFront
- **DNS:** Route 53
- **SSL:** AWS Certificate Manager

### 0.3: Project Management Setup

**Tools:**
- **Repository:** GitHub
- **Issues:** GitHub Issues or Linear
- **Documentation:** Confluence or GitHub Wiki
- **Communication:** Slack
- **Design:** Figma
- **CI/CD:** GitHub Actions (free)
- **Monitoring:** CloudWatch + Sentry
- **Passwords:** 1Password or Dashlane

**Team Structure:**
```
Phase 1 (solo):
- You: Full-stack (backend + iOS + Android basics)

Phase 2 (add 1 person):
- Backend lead: Focus on API, database, security
- You: iOS + Android + web

Phase 3 (add 2 people):
- Backend lead: API + infrastructure
- iOS lead: All iOS features
- Android lead: All Android features
- (You) Architect & coordinate
```

---

## Phase 1: Infrastructure Setup (Week 1-2)

### 1.1: AWS Account & Configuration

**Step 1: Create AWS Account**
```bash
# 1. Go to aws.amazon.com
# 2. Sign up for free tier account
# 3. Enable MFA on root account (CRITICAL)
# 4. Create IAM user for daily use (never use root)
```

**Step 2: Set Up IAM User (for you)**
```
AWS Console → IAM → Users → Add User
- Username: your-name
- Access type: Programmatic access + AWS Console
- Permissions: Administrator (for now)
- Save: Access Key ID + Secret Access Key
```

**Step 3: Configure AWS CLI**
```bash
# Install AWS CLI v2
# macOS: brew install awscliv2
# Linux: Follow https://docs.aws.amazon.com/cli/latest/userguide/install-linux.html

# Configure
aws configure
# AWS Access Key ID: [paste from IAM user]
# AWS Secret Access Key: [paste from IAM user]
# Default region: ap-south-1
# Default output format: json

# Verify
aws sts get-caller-identity
# Should show your IAM user
```

**Step 4: Set Budget Alert (prevent surprise bills)**
```
AWS Console → Billing → Budgets → Create budget
- Budget amount: $100/month
- Alert email: your@email.com
- Alert threshold: 80% of budget
```

### 1.2: Infrastructure as Code (Terraform)

**Step 1: Install Terraform**
```bash
# macOS
brew install terraform

# Verify
terraform version
```

**Step 2: Create Repository**
```bash
# On GitHub: Create new repo "rupaya"
git clone https://github.com/yourname/rupaya.git
cd rupaya

# Create folder structure
mkdir -p deployment/terraform
cd deployment/terraform
```

**Step 3: Initialize Terraform**

**File: `deployment/terraform/main.tf`**
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Store state in S3 (not locally)
  backend "s3" {
    bucket         = "rupaya-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "RUPAYA"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "rupaya-vpc"
  }
}

# Subnets (for high availability)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "rupaya-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "rupaya-private-2"
  }
}
```

**File: `deployment/terraform/variables.tf`**
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "rupaya"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 3000
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "rupaya_prod"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "rupaya_admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}
```

**Step 4: Create RDS (Database)**

**File: `deployment/terraform/rds.tf`**
```hcl
# RDS Aurora PostgreSQL (managed, highly available)
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.app_name}-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "15.2"
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  backup_retention_period = 30
  preferred_backup_window = "03:00-04:00"
  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.app_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  db_subnet_group_name            = aws_db_subnet_group.main.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  vpc_security_group_ids          = [aws_security_group.rds.id]

  enabled_cloudwatch_logs_exports = ["postgresql"]
  storage_encrypted               = true

  tags = {
    Name = "${var.app_name}-db-cluster"
  }
}

# RDS Instances (2 for high availability)
resource "aws_rds_cluster_instance" "main" {
  count              = 2
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t3.small"  # Start small, scale up later
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version
  publicly_accessible = false

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

  tags = {
    Name = "${var.app_name}-db-instance-${count.index + 1}"
  }
}

# DB Subnet Group (for network isolation)
resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.app_name}-db-subnet-group"
  }
}
```

**Step 5: Create ElastiCache (Redis for caching)**

**File: `deployment/terraform/elasticache.tf`**
```hcl
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.app_name}-cache"
  engine               = "redis"
  node_type            = "cache.t3.micro"  # Start small
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379

  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.redis.id]
  automatic_failover_enabled = false  # Enable when scaling

  tags = {
    Name = "${var.app_name}-cache"
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.app_name}-cache-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}
```

**Step 6: Create ECS (Container Orchestration)**

**File: `deployment/terraform/ecs.tf`**
```hcl
# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.app_name}-cluster"
  }
}

# ECS Task Definition (Docker container specification)
resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = tostring(var.container_port)
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.db_password.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.app_name}-task"
  }
}

# ECS Service (manages running tasks)
resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy.ecs_task_execution_role_policy
  ]

  tags = {
    Name = "${var.app_name}-service"
  }
}
```

**Step 7: Create Load Balancer (for distributing traffic)**

**File: `deployment/terraform/alb.tf`**
```hcl
# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.app_name}-alb"
  }
}

# Target Group (where ALB sends traffic)
resource "aws_lb_target_group" "app" {
  name        = "${var.app_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "${var.app_name}-tg"
  }
}

# Listener (listens on port 80 → sends to target group)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# HTTPS Listener (after SSL certificate is ready)
# Will be added in Phase 2
```

**Step 8: Deploy Infrastructure**
```bash
cd deployment/terraform

# Initialize Terraform
terraform init

# Plan (see what will be created)
terraform plan -out=tfplan

# Apply (actually create resources)
terraform apply tfplan

# Save outputs
terraform output -json > outputs.json
```

**Step 9: Verify Deployment**
```bash
# Check RDS
aws rds describe-db-clusters --region ap-south-1

# Check Redis
aws elasticache describe-cache-clusters --region ap-south-1

# Check ECS
aws ecs list-clusters --region ap-south-1
```

---

## Phase 2: Backend API Development (Week 2-5)

### 2.1: Setup Backend Project

```bash
# Create backend folder
mkdir rupaya/backend
cd rupaya/backend

# Initialize Node.js project
npm init -y

# Install dependencies
npm install express dotenv cors helmet express-validator bcryptjs jsonwebtoken speakeasy pg redis
npm install --save-dev nodemon jest supertest @types/node

# Create folder structure
mkdir -p src/{controllers,services,models,middleware,routes,utils,config,jobs}
mkdir -p __tests__/{unit,integration}
mkdir migrations
```

### 2.2: Environment Configuration

**File: `backend/.env.example`**
```env
# Server
NODE_ENV=development
PORT=3000
API_URL=http://localhost:3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=rupaya_dev
DB_PASSWORD=dev_password
DB_NAME=rupaya_dev

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# JWT
JWT_SECRET=min_32_chars_secret_for_testing
JWT_REFRESH_SECRET=min_32_chars_refresh_secret_for_testing
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Email (for signup verification)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# AWS (for S3 file uploads, optional)
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_S3_BUCKET=

# Security
PASSWORD_MIN_LENGTH=12
MAX_LOGIN_ATTEMPTS=5
LOCK_TIME_MINUTES=15

# Monitoring
SENTRY_DSN=
LOG_LEVEL=info
```

### 2.3: Core API Structure

**File: `backend/src/app.js`**
```javascript
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const { errorHandler } = require('./middleware/errorHandler');
const authRoutes = require('./routes/auth');
const transactionRoutes = require('./routes/transactions');

const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/transactions', transactionRoutes);

// Error handling (must be last)
app.use(errorHandler);

module.exports = app;
```

**File: `backend/src/server.js`**
```javascript
const app = require('./app');
const { initializeDatabase } = require('./config/database');
const { initializeRedis } = require('./config/redis');

const PORT = process.env.PORT || 3000;

async function start() {
  try {
    // Initialize database
    await initializeDatabase();
    console.log('✓ Database connected');

    // Initialize Redis
    await initializeRedis();
    console.log('✓ Redis connected');

    // Start server
    app.listen(PORT, () => {
      console.log(`✓ Server running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('✗ Failed to start server:', error);
    process.exit(1);
  }
}

start();
```

### 2.4: Database Models & Migrations

**File: `backend/migrations/001_init.sql`**
```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  phone VARCHAR(20),
  mfa_secret VARCHAR(255),
  mfa_enabled BOOLEAN DEFAULT FALSE,
  email_verified BOOLEAN DEFAULT FALSE,
  email_verified_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE
);

-- Accounts table (checking, savings, etc)
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  name VARCHAR(100) NOT NULL,
  account_type VARCHAR(50) NOT NULL, -- 'checking', 'savings', etc
  balance DECIMAL(15,2) DEFAULT 0,
  currency VARCHAR(3) DEFAULT 'INR',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE,
  UNIQUE(user_id, name)
);

-- Transactions table
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id),
  amount DECIMAL(15,2) NOT NULL,
  type VARCHAR(20) NOT NULL, -- 'income', 'expense', 'transfer'
  category_id UUID REFERENCES categories(id),
  description VARCHAR(500),
  transaction_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE
);

-- Categories table
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  name VARCHAR(100) NOT NULL,
  type VARCHAR(20) NOT NULL, -- 'income', 'expense'
  color VARCHAR(7),
  is_system BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE
);

-- Devices table (for multi-device support)
CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  device_fingerprint VARCHAR(255),
  device_name VARCHAR(255),
  os VARCHAR(50),
  browser VARCHAR(50),
  last_used_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE
);

-- Audit logs
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  action VARCHAR(255),
  resource_type VARCHAR(100),
  resource_id VARCHAR(255),
  details JSONB,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indices for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_accounts_user_id ON accounts(user_id);
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_categories_user_id ON categories(user_id);
CREATE INDEX idx_devices_user_id ON devices(user_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
```

**Run migrations:**
```bash
# Install migration tool
npm install --save-dev db-migrate

# Run migration
npx db-migrate up
```

### 2.5: Authentication Service

**File: `backend/src/services/AuthService.js`**
```javascript
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const { db } = require('../config/database');

class AuthService {
  async signup(email, password, firstName, lastName) {
    // Check if user exists
    const existing = await db.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );
    if (existing.rows.length > 0) {
      throw new Error('Email already registered');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    // Create user
    const result = await db.query(
      `INSERT INTO users (email, password_hash, first_name, last_name)
       VALUES ($1, $2, $3, $4)
       RETURNING id, email, first_name, last_name`,
      [email, passwordHash, firstName, lastName]
    );

    const user = result.rows[0];

    // Send verification email (implement in EmailService)
    await this.sendVerificationEmail(user.email, user.id);

    return user;
  }

  async signin(email, password) {
    // Find user
    const result = await db.query(
      'SELECT * FROM users WHERE email = $1 AND is_deleted = FALSE',
      [email]
    );

    if (result.rows.length === 0) {
      throw new Error('Invalid credentials');
    }

    const user = result.rows[0];

    // Check password
    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) {
      throw new Error('Invalid credentials');
    }

    // Generate tokens
    const accessToken = this.generateAccessToken(user);
    const refreshToken = this.generateRefreshToken(user);

    return {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name
      },
      accessToken,
      refreshToken
    };
  }

  async generateMFASecret(userId) {
    const secret = speakeasy.generateSecret({
      name: `RUPAYA (${userId})`,
      issuer: 'RUPAYA',
      length: 32
    });

    const qrCode = await QRCode.toDataURL(secret.otpauth_url);

    return {
      secret: secret.base32,
      qrCode
    };
  }

  async verifyMFAToken(userId, token) {
    const result = await db.query(
      'SELECT mfa_secret FROM users WHERE id = $1',
      [userId]
    );

    const user = result.rows[0];
    if (!user || !user.mfa_secret) {
      throw new Error('MFA not enabled');
    }

    const verified = speakeasy.totp.verify({
      secret: user.mfa_secret,
      encoding: 'base32',
      token,
      window: 2 // Allow 2 window tolerance
    });

    return verified;
  }

  generateAccessToken(user) {
    return jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );
  }

  generateRefreshToken(user) {
    return jwt.sign(
      { id: user.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN }
    );
  }

  verifyAccessToken(token) {
    return jwt.verify(token, process.env.JWT_SECRET);
  }

  async sendVerificationEmail(email, userId) {
    // Implement email sending (Sendgrid, AWS SES, etc)
    // For now, just log
    console.log(`Send verification email to ${email}`);
  }
}

module.exports = new AuthService();
```

### 2.6: API Endpoints

**File: `backend/src/routes/auth.js`**
```javascript
const express = require('express');
const { body, validationResult } = require('express-validator');
const AuthService = require('../services/AuthService');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Signup
router.post('/signup',
  body('email').isEmail(),
  body('password').isLength({ min: 12 }),
  body('firstName').notEmpty(),
  body('lastName').notEmpty(),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const user = await AuthService.signup(
        req.body.email,
        req.body.password,
        req.body.firstName,
        req.body.lastName
      );
      res.status(201).json(user);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
);

// Signin
router.post('/signin', async (req, res) => {
  try {
    const result = await AuthService.signin(
      req.body.email,
      req.body.password
    );
    res.json(result);
  } catch (error) {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

// Setup MFA
router.post('/mfa/setup',
  authMiddleware,
  async (req, res) => {
    try {
      const mfaData = await AuthService.generateMFASecret(req.user.id);
      res.json(mfaData);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
);

module.exports = router;
```

### 2.7: Testing

**File: `backend/__tests__/integration/auth.test.js`**
```javascript
const request = require('supertest');
const app = require('../../src/app');
const { db } = require('../../src/config/database');

describe('Authentication', () => {
  beforeAll(async () => {
    await db.query('TRUNCATE users CASCADE');
  });

  it('should signup a new user', async () => {
    const res = await request(app)
      .post('/api/auth/signup')
      .send({
        email: 'test@example.com',
        password: 'SecurePassword123!',
        firstName: 'John',
        lastName: 'Doe'
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.email).toBe('test@example.com');
  });

  it('should signin with credentials', async () => {
    // First signup
    await request(app)
      .post('/api/auth/signup')
      .send({
        email: 'test@example.com',
        password: 'SecurePassword123!',
        firstName: 'John',
        lastName: 'Doe'
      });

    // Then signin
    const res = await request(app)
      .post('/api/auth/signin')
      .send({
        email: 'test@example.com',
        password: 'SecurePassword123!'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.refreshToken).toBeDefined();
  });

  it('should reject invalid password', async () => {
    const res = await request(app)
      .post('/api/auth/signin')
      .send({
        email: 'test@example.com',
        password: 'WrongPassword'
      });

    expect(res.statusCode).toBe(401);
  });
});
```

**Run tests:**
```bash
npm test

# With coverage
npm run test:coverage
```

---

## Phase 3: CI/CD Pipeline Setup (Week 5-6)

### 3.1: GitHub Workflows

**File: `.github/workflows/backend-tests.yml`**
```yaml
name: Backend Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_PASSWORD: test
          POSTGRES_DB: rupaya_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json

      - run: cd backend && npm install
      - run: cd backend && npm run lint
      - run: cd backend && npm test
      - run: cd backend && npm run test:coverage

      - uses: codecov/codecov-action@v3
        with:
          files: ./backend/coverage/lcov.info
```

**File: `.github/workflows/deploy-production.yml`**
```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write

    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json

      - run: cd backend && npm test

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ap-south-1

      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build and push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          cd backend
          docker build -t $ECR_REGISTRY/rupaya:$IMAGE_TAG .
          docker push $ECR_REGISTRY/rupaya:$IMAGE_TAG

      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster rupaya-cluster \
            --service rupaya-service \
            --force-new-deployment
```

### 3.2: Dockerfile

**File: `backend/Dockerfile`**
```dockerfile
# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

# Production stage
FROM node:18-alpine

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Copy from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy application
COPY src ./src
COPY package*.json ./

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Run with dumb-init
ENTRYPOINT ["/sbin/dumb-init", "--"]
CMD ["node", "src/server.js"]
```

---

## Phase 4: iOS App Development (Week 6-9)

### 4.1: Project Setup

```bash
# Create iOS project
cd rupaya
mkdir ios
cd ios

# Create Xcode project
# Open Xcode → File → New → Project
# Choose: iOS → App
# Product Name: RUPAYA
# Organization: Your Company
# Language: Swift
# Interface: SwiftUI

# Or use command line
xcodebuild -project RUPAYA.xcodeproj -scheme RUPAYA -showBuildSettings
```

### 4.2: Project Structure

```
ios/RUPAYA/
├── RUPAYA/ (main app)
│   ├── RUPAYAApp.swift (entry point)
│   ├── Features/
│   │   ├── Authentication/
│   │   │   ├── Views/
│   │   │   │   ├── LoginView.swift
│   │   │   │   ├── SignupView.swift
│   │   │   │   └── MFAView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── AuthViewModel.swift
│   │   │   └── Models/
│   │   │       ├── LoginRequest.swift
│   │   │       └── AuthResponse.swift
│   │   ├── Dashboard/
│   │   ├── Transactions/
│   │   └── Settings/
│   ├── Core/
│   │   ├── Networking/
│   │   │   ├── APIClient.swift
│   │   │   └── Endpoints.swift
│   │   ├── Security/
│   │   │   ├── KeychainManager.swift
│   │   │   └── BiometricManager.swift
│   │   └── Logging/
│   │       └── Logger.swift
│   └── Resources/
│       └── Assets.xcassets/
├── RUPAYATests/ (tests)
└── RUPAYA.xcodeproj/
```

### 4.3: Network Client

**File: `ios/RUPAYA/Core/Networking/APIClient.swift`**
```swift
import Foundation
import Combine

enum APIError: LocalizedError {
  case invalidURL
  case networkError(Error)
  case invalidResponse
  case decodingError(Error)
  case serverError(Int, String)
  case unauthorized
  case forbidden

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .invalidResponse:
      return "Invalid server response"
    case .decodingError(let error):
      return "Failed to decode response: \(error.localizedDescription)"
    case .serverError(let code, let message):
      return "Server error (\(code)): \(message)"
    case .unauthorized:
      return "Unauthorized - please login again"
    case .forbidden:
      return "Access denied"
    }
  }
}

class APIClient {
  static let shared = APIClient()
  
  private let baseURL: URL
  private let session: URLSession
  private var accessToken: String?
  
  init(baseURL: String = "https://api.rupaya.in") {
    self.baseURL = URL(string: baseURL)!
    
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.waitsForConnectivity = true
    
    self.session = URLSession(configuration: config)
  }
  
  func setAccessToken(_ token: String) {
    self.accessToken = token
  }
  
  func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, APIError> {
    guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
      return Fail(error: .invalidURL).eraseToAnyPublisher()
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method.rawValue
    
    // Add headers
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let token = accessToken {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    // Add body
    if let body = endpoint.body {
      request.httpBody = try? JSONEncoder().encode(body)
    }
    
    return session.dataTaskPublisher(for: request)
      .mapError { .networkError($0) }
      .tryMap { data, response in
        guard let httpResponse = response as? HTTPURLResponse else {
          throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
          return data
        case 401:
          throw APIError.unauthorized
        case 403:
          throw APIError.forbidden
        case 400...599:
          let message = String(data: data, encoding: .utf8) ?? "Unknown error"
          throw APIError.serverError(httpResponse.statusCode, message)
        default:
          throw APIError.invalidResponse
        }
      }
      .mapError { error in
        if let apiError = error as? APIError {
          return apiError
        }
        return .decodingError(error)
      }
      .decode(type: T.self, decoder: JSONDecoder())
      .mapError { .decodingError($0) }
      .eraseToAnyPublisher()
  }
}

enum HTTPMethod: String {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
}

protocol Endpoint {
  var method: HTTPMethod { get }
  var path: String { get }
  var body: Encodable? { get }
}

// API Endpoints
enum AuthEndpoint: Endpoint {
  case signup(SignupRequest)
  case signin(SigninRequest)
  case mfaSetup
  
  var method: HTTPMethod {
    switch self {
    case .signup, .signin, .mfaSetup:
      return .post
    }
  }
  
  var path: String {
    switch self {
    case .signup:
      return "/api/auth/signup"
    case .signin:
      return "/api/auth/signin"
    case .mfaSetup:
      return "/api/auth/mfa/setup"
    }
  }
  
  var body: Encodable? {
    switch self {
    case .signup(let request):
      return request
    case .signin(let request):
      return request
    case .mfaSetup:
      return nil
    }
  }
}
```

### 4.4: Authentication ViewModel

**File: `ios/RUPAYA/Features/Authentication/ViewModels/AuthViewModel.swift`**
```swift
import Foundation
import Combine

class AuthViewModel: ObservableObject {
  @Published var isAuthenticated = false
  @Published var errorMessage: String?
  @Published var isLoading = false
  
  private var cancellables = Set<AnyCancellable>()
  private let apiClient = APIClient.shared
  private let keychain = KeychainManager.shared
  
  func signup(email: String, password: String, firstName: String, lastName: String) {
    isLoading = true
    
    let request = SignupRequest(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName
    )
    
    apiClient.request(AuthEndpoint.signup(request))
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        self?.isLoading = false
        if case .failure(let error) = completion {
          self?.errorMessage = error.localizedDescription
        }
      } receiveValue: { [weak self] (response: AuthResponse) in
        self?.keychain.save(token: response.accessToken, for: "accessToken")
        self?.keychain.save(token: response.refreshToken, for: "refreshToken")
        self?.apiClient.setAccessToken(response.accessToken)
        self?.isAuthenticated = true
      }
      .store(in: &cancellables)
  }
  
  func signin(email: String, password: String) {
    isLoading = true
    
    let request = SigninRequest(email: email, password: password)
    
    apiClient.request(AuthEndpoint.signin(request))
      .receive(on: DispatchQueue.main)
      .sink { [weak self] completion in
        self?.isLoading = false
        if case .failure(let error) = completion {
          self?.errorMessage = error.localizedDescription
        }
      } receiveValue: { [weak self] (response: AuthResponse) in
        self?.keychain.save(token: response.accessToken, for: "accessToken")
        self?.keychain.save(token: response.refreshToken, for: "refreshToken")
        self?.apiClient.setAccessToken(response.accessToken)
        self?.isAuthenticated = true
      }
      .store(in: &cancellables)
  }
  
  func logout() {
    keychain.delete(key: "accessToken")
    keychain.delete(key: "refreshToken")
    isAuthenticated = false
  }
}
```

### 4.5: Login View

**File: `ios/RUPAYA/Features/Authentication/Views/LoginView.swift`**
```swift
import SwiftUI

struct LoginView: View {
  @StateObject var viewModel = AuthViewModel()
  @State private var email = ""
  @State private var password = ""
  @State private var showSignup = false
  
  var body: some View {
    NavigationStack {
      ZStack {
        // Background
        Color(red: 0.97, green: 0.97, blue: 0.96)
          .ignoresSafeArea()
        
        VStack(spacing: 24) {
          // Logo
          VStack(spacing: 8) {
            Text("RUPAYA")
              .font(.system(size: 32, weight: .bold))
              .foregroundColor(Color(red: 0.13, green: 0.50, blue: 0.55))
            
            Text("Money Manager")
              .font(.system(size: 14, weight: .regular))
              .foregroundColor(.gray)
          }
          .padding(.top, 60)
          
          Spacer()
          
          // Form
          VStack(spacing: 16) {
            TextField("Email", text: $email)
              .textFieldStyle(.roundedBorder)
              .keyboardType(.emailAddress)
              .autocapitalization(.none)
            
            SecureField("Password", text: $password)
              .textFieldStyle(.roundedBorder)
            
            if let error = viewModel.errorMessage {
              Text(error)
                .font(.system(size: 12))
                .foregroundColor(.red)
                .padding(.horizontal)
            }
          }
          .padding(.horizontal, 20)
          
          // Login Button
          Button(action: {
            viewModel.signin(email: email, password: password)
          }) {
            if viewModel.isLoading {
              ProgressView()
                .progressViewStyle(.circular)
            } else {
              Text("Sign In")
                .font(.system(size: 16, weight: .semibold))
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Color(red: 0.13, green: 0.50, blue: 0.55))
          .foregroundColor(.white)
          .cornerRadius(8)
          .padding(.horizontal, 20)
          .disabled(viewModel.isLoading)
          
          // Signup Link
          HStack(spacing: 4) {
            Text("Don't have an account?")
              .font(.system(size: 14))
            
            NavigationLink(destination: SignupView()) {
              Text("Sign Up")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.13, green: 0.50, blue: 0.55))
            }
          }
          .padding(.horizontal, 20)
          
          Spacer()
        }
      }
      .navigationBarBackButtonHidden(true)
    }
  }
}

#Preview {
  LoginView()
}
```

---

## Phase 5: Android App Development (Week 9-12)

### 5.1: Project Setup

```bash
# Create Android project in Android Studio
# File → New → New Project
# Choose: Empty Activity
# Name: RUPAYA
# Package: com.rupaya.app
# Language: Kotlin
# Minimum SDK: Android 8.0 (API 26)
```

### 5.2: Dependencies

**File: `android/app/build.gradle.kts`**
```kotlin
android {
    compileSdk = 34

    defaultConfig {
        applicationId = "com.rupaya.app"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
}

dependencies {
    // Jetpack Compose
    implementation(platform("androidx.compose:compose-bom:2024.01.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling")

    // Retrofit (networking)
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")

    // OkHttp (HTTP client)
    implementation("com.squareup.okhttp3:okhttp:4.11.0")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.1")

    // Hilt (dependency injection)
    implementation("com.google.dagger:hilt-android:2.48")
    kapt("com.google.dagger:hilt-compiler:2.48")

    // DataStore (secure preferences)
    implementation("androidx.datastore:datastore-preferences:1.0.0")

    // Biometric
    implementation("androidx.biometric:biometric:1.1.0")

    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
```

### 5.3: API Client (Retrofit)

**File: `android/app/src/main/kotlin/com/rupaya/core/network/ApiClient.kt`**
```kotlin
import com.google.gson.Gson
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

object ApiClient {
    private const val BASE_URL = "https://api.rupaya.in/"
    
    private val okHttpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .addInterceptor { chain ->
            val originalRequest = chain.request()
            val requestBuilder = originalRequest.newBuilder()
            
            // Add auth token if available
            val token = getStoredToken() // Get from secure storage
            if (token.isNotEmpty()) {
                requestBuilder.addHeader("Authorization", "Bearer $token")
            }
            
            requestBuilder.addHeader("Content-Type", "application/json")
            
            chain.proceed(requestBuilder.build())
        }
        .build()
    
    val retrofit: Retrofit = Retrofit.Builder()
        .baseUrl(BASE_URL)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()
}

fun getStoredToken(): String {
    // Get from SecureStorage/DataStore
    return ""
}
```

### 5.4: Authentication API

**File: `android/app/src/main/kotlin/com/rupaya/features/auth/data/api/AuthApi.kt`**
```kotlin
import retrofit2.http.Body
import retrofit2.http.POST

interface AuthApi {
    @POST("api/auth/signup")
    suspend fun signup(@Body request: SignupRequest): AuthResponse
    
    @POST("api/auth/signin")
    suspend fun signin(@Body request: SigninRequest): AuthResponse
    
    @POST("api/auth/mfa/setup")
    suspend fun setupMfa(): MfaSetupResponse
}

data class SignupRequest(
    val email: String,
    val password: String,
    val firstName: String,
    val lastName: String
)

data class SigninRequest(
    val email: String,
    val password: String
)

data class AuthResponse(
    val accessToken: String,
    val refreshToken: String,
    val user: UserData
)

data class UserData(
    val id: String,
    val email: String,
    val firstName: String,
    val lastName: String
)

data class MfaSetupResponse(
    val secret: String,
    val qrCode: String
)
```

### 5.5: ViewModel

**File: `android/app/src/main/kotlin/com/rupaya/features/auth/presentation/viewmodels/AuthViewModel.kt`**
```kotlin
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rupaya.features.auth.data.repository.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class AuthViewModel(private val authRepository: AuthRepository) : ViewModel() {
    
    private val _authState = MutableStateFlow<AuthState>(AuthState.Idle)
    val authState: StateFlow<AuthState> = _authState
    
    fun signin(email: String, password: String) {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            try {
                val response = authRepository.signin(email, password)
                _authState.value = AuthState.Success(response)
            } catch (e: Exception) {
                _authState.value = AuthState.Error(e.message ?: "Unknown error")
            }
        }
    }
    
    fun signup(email: String, password: String, firstName: String, lastName: String) {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            try {
                val response = authRepository.signup(email, password, firstName, lastName)
                _authState.value = AuthState.Success(response)
            } catch (e: Exception) {
                _authState.value = AuthState.Error(e.message ?: "Unknown error")
            }
        }
    }
}

sealed class AuthState {
    object Idle : AuthState()
    object Loading : AuthState()
    data class Success(val data: AuthResponse) : AuthState()
    data class Error(val message: String) : AuthState()
}
```

### 5.6: Login Screen (Jetpack Compose)

**File: `android/app/src/main/kotlin/com/rupaya/features/auth/presentation/screens/LoginScreen.kt`**
```kotlin
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rupaya.features.auth.presentation.viewmodels.AuthViewModel

@Composable
fun LoginScreen(
    viewModel: AuthViewModel = viewModel(),
    onLoginSuccess: () -> Unit = {}
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    
    val authState by viewModel.authState.collectAsState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(red = 0.97f, green = 0.97f, blue = 0.96f))
            .padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Logo
        Text(
            text = "RUPAYA",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            color = Color(red = 0.13f, green = 0.50f, blue = 0.55f)
        )
        
        Text(
            text = "Money Manager",
            fontSize = 14.sp,
            color = Color.Gray,
            modifier = Modifier.padding(bottom = 40.dp)
        )
        
        // Email Field
        TextField(
            value = email,
            onValueChange = { email = it },
            label = { Text("Email") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 12.dp),
            singleLine = true
        )
        
        // Password Field
        TextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 24.dp),
            singleLine = true,
            visualTransformation = PasswordVisualTransformation()
        )
        
        // Error Message
        if (authState is AuthState.Error) {
            Text(
                text = (authState as AuthState.Error).message,
                color = Color.Red,
                fontSize = 12.sp,
                modifier = Modifier.padding(bottom = 12.dp)
            )
        }
        
        // Login Button
        Button(
            onClick = { viewModel.signin(email, password) },
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            enabled = authState !is AuthState.Loading,
            colors = ButtonDefaults.buttonColors(
                containerColor = Color(red = 0.13f, green = 0.50f, blue = 0.55f)
            )
        ) {
            if (authState is AuthState.Loading) {
                CircularProgressIndicator(
                    color = Color.White,
                    modifier = Modifier.size(20.dp)
                )
            } else {
                Text("Sign In", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            }
        }
        
        // Handle success
        LaunchedEffect(authState) {
            if (authState is AuthState.Success) {
                onLoginSuccess()
            }
        }
    }
}
```

---

## Phase 6: Web Dashboard (Week 12-14)

### 6.1: React Setup

```bash
npx create-react-app rupaya-web
cd rupaya-web

# Install dependencies
npm install axios react-router-dom zustand recharts
```

### 6.2: Project Structure

```
rupaya-web/
├── src/
│   ├── components/
│   │   ├── Layout/
│   │   │   ├── Header.jsx
│   │   │   ├── Sidebar.jsx
│   │   │   └── Layout.jsx
│   │   ├── Auth/
│   │   │   ├── LoginForm.jsx
│   │   │   ├── SignupForm.jsx
│   │   │   └── ProtectedRoute.jsx
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.jsx
│   │   │   ├── BalanceCard.jsx
│   │   │   └── TransactionList.jsx
│   │   └── Transactions/
│   │       ├── TransactionForm.jsx
│   │       └── TransactionTable.jsx
│   ├── stores/
│   │   ├── authStore.js
│   │   └── transactionStore.js
│   ├── api/
│   │   ├── apiClient.js
│   │   ├── authApi.js
│   │   └── transactionApi.js
│   ├── pages/
│   │   ├── LoginPage.jsx
│   │   ├── DashboardPage.jsx
│   │   └── TransactionsPage.jsx
│   └── App.jsx
└── package.json
```

### 6.3: API Client

**File: `src/api/apiClient.js`**
```javascript
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://api.rupaya.in';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Add token to requests
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle token refresh
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = localStorage.getItem('refreshToken');
        const response = await axios.post(`${API_BASE_URL}/api/auth/refresh`, {
          refreshToken
        });

        localStorage.setItem('accessToken', response.data.accessToken);
        apiClient.defaults.headers.Authorization = `Bearer ${response.data.accessToken}`;

        return apiClient(originalRequest);
      } catch (err) {
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        window.location.href = '/login';
      }
    }

    return Promise.reject(error);
  }
);

export default apiClient;
```

### 6.4: Auth Store (Zustand)

**File: `src/stores/authStore.js`**
```javascript
import { create } = from 'zustand';
import * as authApi from '../api/authApi';

export const useAuthStore = create((set) => ({
  user: null,
  isLoading: false,
  error: null,

  login: async (email, password) => {
    set({ isLoading: true, error: null });
    try {
      const response = await authApi.signin(email, password);
      localStorage.setItem('accessToken', response.accessToken);
      localStorage.setItem('refreshToken', response.refreshToken);
      set({ user: response.user, isLoading: false });
    } catch (error) {
      set({ error: error.message, isLoading: false });
    }
  },

  logout: () => {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    set({ user: null });
  },

  checkAuth: () => {
    const token = localStorage.getItem('accessToken');
    if (token) {
      set({ user: { authenticated: true } });
    }
  }
}));
```

### 6.5: Dashboard Component

**File: `src/pages/DashboardPage.jsx`**
```jsx
import React, { useEffect, useState } from 'react';
import { PieChart, Pie, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import * as transactionApi from '../api/transactionApi';

export default function DashboardPage() {
  const [accounts, setAccounts] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [categoryBreakdown, setCategoryBreakdown] = useState([]);

  useEffect(() => {
    fetchDashboard();
  }, []);

  const fetchDashboard = async () => {
    try {
      const [accountsData, transactionsData] = await Promise.all([
        transactionApi.getAccounts(),
        transactionApi.getTransactions()
      ]);
      
      setAccounts(accountsData);
      setTransactions(transactionsData);
      
      // Calculate category breakdown
      const breakdown = calculateCategoryBreakdown(transactionsData);
      setCategoryBreakdown(breakdown);
    } catch (error) {
      console.error('Failed to fetch dashboard', error);
    }
  };

  const calculateCategoryBreakdown = (txns) => {
    const breakdown = {};
    txns.forEach(txn => {
      if (!breakdown[txn.category]) {
        breakdown[txn.category] = 0;
      }
      breakdown[txn.category] += txn.amount;
    });
    
    return Object.entries(breakdown).map(([category, amount]) => ({
      name: category,
      value: amount
    }));
  };

  const totalBalance = accounts.reduce((sum, acc) => sum + acc.balance, 0);

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <h1 className="text-3xl font-bold mb-6">Dashboard</h1>

      {/* Balance Card */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <h2 className="text-gray-600 text-sm font-semibold mb-2">Total Balance</h2>
        <p className="text-4xl font-bold text-teal-600">₹{totalBalance.toFixed(2)}</p>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Category Breakdown Pie Chart */}
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold mb-4">Spending by Category</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={categoryBreakdown}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, value }) => `${name}: ₹${value}`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {categoryBreakdown.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={['#0891b2', '#06b6d4', '#0ea5e9'][index % 3]} />
                ))}
              </Pie>
              <Tooltip formatter={(value) => `₹${value}`} />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Recent Transactions */}
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold mb-4">Recent Transactions</h3>
          <div className="space-y-2 max-h-80 overflow-y-auto">
            {transactions.slice(0, 5).map(txn => (
              <div key={txn.id} className="flex justify-between items-center py-2 border-b">
                <div>
                  <p className="font-medium">{txn.category}</p>
                  <p className="text-sm text-gray-500">{new Date(txn.date).toLocaleDateString()}</p>
                </div>
                <span className={`font-semibold ${txn.type === 'income' ? 'text-green-600' : 'text-red-600'}`}>
                  {txn.type === 'income' ? '+' : '-'}₹{txn.amount.toFixed(2)}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

## Phase 7: App Store & Play Store Deployment (Week 14-15)

### 7.1: iOS App Store Deployment

**Step 1: Create Developer Account**
```
1. Go to developer.apple.com
2. Enroll in Apple Developer Program ($99/year)
3. Create App ID: "com.yourcompany.rupaya"
4. Create Provisioning Profiles
5. Download certificates
```

**Step 2: Build for Release**
```
In Xcode:
1. Select Product → Scheme → Edit Scheme
2. Set Build Configuration to Release
3. Product → Archive
4. Organizer → Validate App
5. Upload to App Store
```

**Step 3: App Store Connect Setup**
```
In App Store Connect:
1. Create new App
2. Fill app information
   - App name: RUPAYA
   - Primary category: Finance
   - Subtitle: Money Manager
   - Description: Manage your finances with ease
   - Keywords: finance, money, budget, transaction
3. Add app preview videos
4. Add screenshots (5-5 for each device size)
5. Set up pricing
6. Submit for review
```

**Expected Review Time:** 24-48 hours

### 7.2: Android Play Store Deployment

**Step 1: Create Developer Account**
```
1. Go to play.google.com/console
2. Create account ($25 one-time fee)
3. Create new app: RUPAYA
4. Fill app details
```

**Step 2: Create Signing Key**
```bash
# Generate key store
keytool -genkey -v -keystore rupaya-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias rupaya-key

# Build signed APK/AAB
cd android
./gradlew bundleRelease \
  -Pandroid.injected.signing.store.file=path/to/rupaya-release.jks \
  -Pandroid.injected.signing.store.password=password \
  -Pandroid.injected.signing.key.alias=rupaya-key \
  -Pandroid.injected.signing.key.password=password
```

**Step 3: Upload to Play Store**
```
In Google Play Console:
1. Upload AAB file
2. Fill app information
   - Title: RUPAYA
   - Category: Finance
   - Content rating: Complete questionnaire
   - Privacy policy: Add link
3. Add screenshots (6-8 for different device sizes)
4. Add app description
5. Create release: Internal testing → Beta → Production
```

**Expected Review Time:** 2-3 hours for internal release, 2-7 days for production

### 7.3: Web Deployment

**Option A: Vercel (Recommended for Next.js)**
```bash
npm install -g vercel
vercel login
vercel
# Select project, follow prompts
```

**Option B: AWS S3 + CloudFront**
```bash
# Build
npm run build

# Deploy to S3
aws s3 sync build/ s3://rupaya-web --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id XXXXX --paths "/*"
```

---

## Phase 8: Security Hardening (Week 15)

### 8.1: OWASP Top 10 Checklist

```
✓ A1: Broken Access Control
  - Implement proper JWT validation
  - Check user permissions on all endpoints
  - Implement rate limiting

✓ A2: Cryptographic Failures
  - Use HTTPS everywhere
  - Encrypt sensitive data in transit & at rest
  - Use strong password hashing (bcryptjs)

✓ A3: Injection
  - Use parameterized queries
  - Input validation on all fields
  - Escape user input

✓ A4: Insecure Design
  - Follow secure design principles
  - Threat modeling
  - Security requirements

✓ A5: Security Misconfiguration
  - Remove default credentials
  - Disable debug endpoints
  - Keep dependencies updated

✓ A6: Vulnerable Components
  - `npm audit` weekly
  - `npm update` regularly
  - Use SNYK for vulnerability scanning

✓ A7: Authentication Failures
  - Implement MFA
  - Rate limit login attempts
  - Session management

✓ A8: Data Integrity Failures
  - Validate all API requests
  - Implement CSRF tokens
  - Verify data integrity

✓ A9: Logging & Monitoring
  - Log all important events
  - Monitor error rates
  - Set up alerts

✓ A10: SSRF
  - Validate all URLs
  - Whitelist external services
  - Don't allow redirects to untrusted hosts
```

### 8.2: Security Configuration

**Backend:**
```bash
# Add security headers
npm install helmet express-rate-limit

# Configure HTTPS
# In Nginx/ALB: Force HTTPS redirect

# Set CSP headers
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    styleSrc: ["'self'", "'unsafe-inline'"],
    scriptSrc: ["'self'"],
    imgSrc: ["'self'", "data:", "https:"]
  }
}));

# Add rate limiting
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use(limiter);

# Add MFA
npm install speakeasy qrcode
```

**iOS:**
```swift
// Certificate Pinning
let pinnedCertificates = Set([CertificateHelper.pinnedCertificates()])
let configuration = URLSessionConfiguration.default
let delegate = PinningDelegate(pinnedCertificates)
let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)

// Keychain for sensitive data
KeychainManager.save(token: accessToken, for: "accessToken")
```

**Android:**
```kotlin
// Certificate Pinning
val certificatePinner = CertificatePinner.Builder()
    .add("api.rupaya.in", "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
    .build()

val okHttpClient = OkHttpClient.Builder()
    .certificatePinner(certificatePinner)
    .build()
```

---

## Phase 9: Testing & QA (Week 15)

### 9.1: Testing Strategy

```
Unit Tests: 80% coverage minimum
- Backend: Jest + Supertest
- iOS: XCTest
- Android: JUnit
- Web: Jest + React Testing Library

Integration Tests:
- API endpoint tests
- Database tests
- Auth flow tests

End-to-End Tests:
- Complete user journeys
- Cross-platform testing
- Performance testing

Load Testing:
- Simulate 1000+ concurrent users
- Measure response times
- Identify bottlenecks
```

### 9.2: Test Execution

```bash
# Backend
cd backend
npm run lint
npm test
npm run test:coverage

# iOS
cd ios
xcodebuild test -workspace RUPAYA.xcworkspace -scheme RUPAYA

# Android
cd android
./gradlew test
./gradlew connectedAndroidTest

# Web
cd web
npm test
npm run build
```

---

## Phase 10: Launch & Monitoring (Week 16+)

### 10.1: Pre-Launch Checklist

```
✓ Staging environment tested thoroughly
✓ Production database backups configured
✓ Monitoring & alerting setup
✓ Error tracking (Sentry) enabled
✓ Status page created
✓ Support documentation ready
✓ Team trained on incident response
✓ Rollback procedures documented
✓ Security scan completed (OWASP)
✓ Performance tested (load testing done)
✓ Privacy policy & terms updated
```

### 10.2: Launch Plan

**Week 1: Soft Launch (5% of traffic)**
```
- Release to 5% of users
- Monitor error rates, response times
- Gather feedback from early users
- Watch CloudWatch metrics
```

**Week 2: Ramp to 25%**
```
- If no issues, expand to 25%
- Continue monitoring
- Fix any issues found
```

**Week 3: Ramp to 100%**
```
- Full public launch
- Marketing campaign
- Press release
```

### 10.3: Post-Launch Monitoring

```
Critical Metrics:
- Error rate (<0.1%)
- API response time (<500ms)
- Uptime (99.9%)
- User acquisition
- Daily active users
- Crash rate (mobile apps)

Alerts:
- Error rate > 1%
- Response time > 1s
- Database CPU > 80%
- Memory usage > 90%
- Downtime
```

---

## Cost Estimation

### Monthly Costs (at launch, 100K users)

| Service | Cost | Notes |
|---------|------|-------|
| **AWS** | | |
| RDS Aurora (db.t3.small x 2) | $80 | Scales up with load |
| ElastiCache Redis (cache.t3.micro) | $20 | |
| ECS Fargate (CPU/Memory) | $200-300 | Task count 2-5 |
| Application Load Balancer | $20 | |
| NAT Gateway | $45 | For outgoing traffic |
| S3 (file storage) | $50-100 | Backup + user uploads |
| CloudFront (CDN) | $50-100 | Video/image delivery |
| CloudWatch (monitoring) | $10 | |
| Total AWS | ~$500-800 | |
| **Developer Services** | | |
| Apple Developer | $8 | $99/year ÷ 12 |
| Google Play Store | $2 | $25 one-time |
| Domain Name | $1 | $12/year ÷ 12 |
| SSL Certificate | $0 | AWS Certificate Manager (free) |
| Email Service | $10-20 | SendGrid/SES for emails |
| **Total/Month** | ~$540-850 | |

### Scaling (1M users, peak load)

| Service | Cost | Notes |
|---------|------|-------|
| AWS | $2,000-3,000 | More RDS instances, larger cache, more ECS tasks |
| CDN | $200-500 | More traffic |
| **Total/Month** | ~$2,500-3,500 | |

---

## Timeline Summary

```
Week 1:       Foundation & Planning
Week 2-5:     Backend Development + API
Week 5-6:     CI/CD Pipeline
Week 6-9:     iOS App Development
Week 9-12:    Android App Development
Week 12-14:   Web Dashboard
Week 14-15:   App Store & Play Store Deployment
Week 15:      Security Hardening + Testing
Week 16:      Launch & Monitoring

Total: 16 weeks (~4 months)
```

---

## Key Success Metrics

**At Launch:**
- ✓ 0 critical bugs in first week
- ✓ Error rate < 0.1%
- ✓ API response < 300ms (p95)
- ✓ 99.9% uptime
- ✓ 100% test coverage for critical paths

**Month 1:**
- ✓ 1,000+ active users
- ✓ 50%+ daily active users (DAU/MAU)
- ✓ < 5% churn rate
- ✓ < 2% crash rate on mobile

**Month 3:**
- ✓ 10,000+ users
- ✓ Positive customer feedback
- ✓ Feature requests identified
- ✓ Revenue if applicable

---

## Next Steps (What to Do Monday Morning)

1. **Day 1:** Create GitHub account, set up repository structure
2. **Day 2:** Create AWS account, configure IAM user
3. **Day 3:** Initialize Terraform, create infrastructure
4. **Day 4:** Create backend project, set up database
5. **Day 5:** Create iOS project in Xcode
6. **Week 2:** Start implementing authentication
7. **Week 3:** Implement core features
8. **Week 4:** Start iOS app development

---

## Resources & References

- **Backend:** Node.js docs, Express.js guide
- **iOS:** Apple Developer docs, SwiftUI tutorials
- **Android:** Google Developer docs, Jetpack Compose guide
- **DevOps:** AWS Well-Architected Framework, Terraform docs
- **Security:** OWASP Top 10, AWS Security Best Practices
- **Testing:** Jest docs, XCTest guide, Espresso guide

---

**You've got this! Start small, ship fast, iterate based on feedback. 🚀**

---

This is a complete, production-ready roadmap from zero to launch. It's detailed enough to follow but flexible enough to adapt as you learn. Good luck! 💪
