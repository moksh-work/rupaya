# RUPAYA: Complete Industry-Level Launch Roadmap
## From Zero to App Store Launch (2026)

**Document Version:** 1.0  
**Created:** February 2026  
**Target Timeline:** 6-9 months from foundation to production launch

---

## TABLE OF CONTENTS

1. [Phase 0: Foundation (Weeks 1-4)](#phase-0-foundation)
2. [Phase 1: Architecture & Infrastructure (Weeks 5-8)](#phase-1-architecture--infrastructure)
3. [Phase 2: Backend Development (Weeks 9-16)](#phase-2-backend-development)
4. [Phase 3: Frontend Development - Web (Weeks 9-18)](#phase-3-frontend-development--web)
5. [Phase 4: Mobile Development - iOS (Weeks 9-20)](#phase-4-mobile-development--ios)
6. [Phase 5: Mobile Development - Android (Weeks 9-20)](#phase-5-mobile-development--android)
7. [Phase 6: Testing & QA (Weeks 17-22)](#phase-6-testing--qa)
8. [Phase 7: Security & Compliance (Weeks 18-24)](#phase-7-security--compliance)
9. [Phase 8: App Store Preparation (Weeks 22-24)](#phase-8-app-store-preparation)
10. [Phase 9: Deployment & Launch (Weeks 25-26)](#phase-9-deployment--launch)

---

# PHASE 0: FOUNDATION (Weeks 1-4)

## Step 1: Team Structure & Roles

### Backend Team (2-3 people)
- **Senior Backend Engineer**: Architecture, API design, database
- **Backend Engineer**: Feature development, integrations
- **DevOps Engineer**: Infrastructure, deployment, monitoring

### Frontend Web Team (2 people)
- **Frontend Engineer**: React/Next.js development
- **UI/UX Designer**: Design system, wireframes, prototypes

### iOS Team (2 people)
- **Senior iOS Engineer**: Architecture, code reviews
- **iOS Engineer**: Feature development

### Android Team (2 people)
- **Senior Android Engineer**: Architecture, code reviews
- **Android Engineer**: Feature development

### QA Team (1-2 people)
- **QA Engineer**: Testing strategy, automation
- **QA Engineer**: Manual testing, UAT

### Leadership (1-2 people)
- **Product Manager**: Feature prioritization, roadmap
- **Tech Lead**: Overall architecture, cross-team coordination

**Total Team Size:** 11-14 people

---

## Step 2: Project Management & Communication Setup

### Tools Setup

```
Project Management:
├── GitHub Projects (code management + issue tracking)
├── Jira (task management, optional alternative)
├── Linear (modern alternative, faster than Jira)
└── Confluence (documentation)

Communication:
├── Slack (#rupaya-general, #rupaya-dev, #rupaya-ios, 
│   #rupaya-android, #rupaya-backend, #rupaya-web, 
│   #rupaya-alerts)
├── Google Meet (daily standups, meetings)
└── GitHub Discussions (technical decisions)

Design:
├── Figma (UI/UX design, prototypes)
└── Miro (architecture diagrams, brainstorming)

Documentation:
├── Confluence or GitHub Wiki
└── README in each repository
```

### Communication Schedule

```
Daily:
- 10:00 AM IST: Backend standup (15 min)
- 10:30 AM IST: Mobile standup (15 min)
- 11:00 AM IST: Web standup (15 min)
- 4:00 PM IST: All-hands standup (30 min)

Weekly:
- Monday 10 AM: Architecture review
- Wednesday 2 PM: Design review
- Friday 4 PM: Demo & retrospective

Monthly:
- First Monday: Strategic roadmap review
```

---

## Step 3: Design System & Brand Guidelines

### Design Foundation (Week 1-2)

```
1. Brand Identity
   ├── Logo (multiple formats: .svg, .png, favicon)
   ├── Color palette (primary, secondary, accent, status colors)
   ├── Typography (Heading, Body, Mono fonts)
   ├── Icons set (Material Icons or custom SVG)
   └── Illustration style

2. Component Library (Figma)
   ├── Buttons (primary, secondary, ghost, danger)
   ├── Forms (input, select, checkbox, radio, toggle)
   ├── Cards (basic, interactive, expandable)
   ├── Navigation (tabs, breadcrumbs, sidebar)
   ├── Modals (dialog, alert, confirmation)
   ├── Toast notifications
   ├── Skeleton loaders
   └── Empty states

3. Layout System
   ├── Spacing scale (4px, 8px, 12px, 16px, 20px, 24px, 32px...)
   ├── Grid system (12-column for web, responsive)
   ├── Breakpoints (mobile: 320-767px, tablet: 768-1023px, desktop: 1024px+)
   └── Safe area guidelines (iOS notch, Android status bar)

4. Design Tokens (CSS Variables)
   ├── Colors: --color-primary, --color-error, --color-success
   ├── Typography: --font-size-lg, --font-weight-bold
   ├── Spacing: --space-8, --space-16
   └── Shadows: --shadow-sm, --shadow-lg
```

### Figma Workspace Structure

```
Figma Project: RUPAYA Design System
├── 📋 Components
│   ├── Atoms (Button, Input, Label)
│   ├── Molecules (Search bar, Card, Form group)
│   └── Organisms (Header, Navigation, Transaction list)
├── 📱 Mobile (iOS & Android)
├── 🌐 Web
├── 🎨 Styles (colors, typography, shadows)
└── 📐 Prototypes (user flows, interactions)
```

---

## Step 4: Repository Structure

### Main Repositories

```bash
rupaya-monorepo/
├── backend/                          # Node.js/Express API
│   ├── src/
│   │   ├── api/                      # Express routes
│   │   ├── services/                 # Business logic
│   │   ├── models/                   # Database models
│   │   ├── middleware/               # Auth, validation
│   │   ├── utils/                    # Helpers
│   │   └── config/                   # Configuration
│   ├── tests/                        # Jest unit/integration tests
│   ├── migrations/                   # Database migrations (Sequelize/Typeorm)
│   ├── Dockerfile                    # Container image
│   ├── docker-compose.yml            # Local development
│   ├── .env.example                  # Environment template
│   ├── package.json
│   └── README.md
│
├── web/                              # React/Next.js
│   ├── src/
│   │   ├── pages/                    # Next.js pages/routes
│   │   ├── components/               # React components
│   │   ├── hooks/                    # Custom React hooks
│   │   ├── context/                  # State management
│   │   ├── services/                 # API calls
│   │   ├── utils/                    # Helpers
│   │   ├── styles/                   # Global CSS
│   │   └── assets/                   # Images, fonts
│   ├── tests/                        # Jest + React Testing Library
│   ├── public/                       # Static files
│   ├── next.config.js
│   ├── package.json
│   └── README.md
│
├── mobile-ios/                       # Swift + Xcode project
│   ├── Rupaya/
│   │   ├── App/                      # App delegate, main entry
│   │   ├── Features/                 # Feature modules
│   │   │   ├── Login/
│   │   │   ├── Dashboard/
│   │   │   ├── Transactions/
│   │   │   └── Profile/
│   │   ├── Shared/                   # Reusable code
│   │   │   ├── Models/
│   │   │   ├── Services/
│   │   │   ├── ViewModels/
│   │   │   └── UI/
│   │   ├── Resources/                # Assets, strings
│   │   └── Rupaya.xcodeproj
│   ├── RupayaTests/
│   ├── Podfile                       # CocoaPods dependencies
│   └── README.md
│
├── mobile-android/                   # Kotlin + Android Studio
│   ├── app/
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── java/com/rupaya/
│   │   │   │   │   ├── ui/           # Activities, Fragments
│   │   │   │   │   ├── viewmodel/    # ViewModels
│   │   │   │   │   ├── repository/   # Data repositories
│   │   │   │   │   ├── network/      # API service
│   │   │   │   │   └── di/           # Dependency injection
│   │   │   │   ├── res/              # Resources (layouts, strings, colors)
│   │   │   │   └── AndroidManifest.xml
│   │   │   └── test/
│   │   ├── build.gradle
│   │   └── proguard-rules.pro
│   ├── build.gradle
│   ├── settings.gradle
│   └── README.md
│
├── infrastructure/                   # IaC (Terraform/CDK)
│   ├── terraform/
│   │   ├── main.tf                   # VPC, subnets, security groups
│   │   ├── rds.tf                    # Database
│   │   ├── ecs.tf                    # Container orchestration
│   │   ├── s3.tf                     # Storage
│   │   ├── cloudfront.tf             # CDN
│   │   ├── secrets.tf                # Secrets Manager
│   │   ├── monitoring.tf             # CloudWatch
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── aws-cdk/
│       ├── lib/
│       │   ├── vpc-stack.ts
│       │   ├── rds-stack.ts
│       │   ├── ecs-stack.ts
│       │   └── monitoring-stack.ts
│       ├── bin/
│       │   └── app.ts
│       └── package.json
│
├── .github/
│   └── workflows/
│       ├── backend-ci.yml            # Backend tests + build
│       ├── web-ci.yml                # Web tests + build
│       ├── ios-ci.yml                # iOS build
│       ├── android-ci.yml            # Android build
│       ├── backend-deploy.yml        # Deploy backend
│       ├── web-deploy.yml            # Deploy web
│       └── security-scan.yml         # SAST, dependency check
│
├── docs/
│   ├── API_DOCUMENTATION.md          # OpenAPI/Swagger
│   ├── ARCHITECTURE.md               # System design
│   ├── DEPLOYMENT.md                 # How to deploy
│   ├── SECURITY.md                   # Security guidelines
│   ├── CONTRIBUTING.md               # Development guide
│   ├── RUNBOOKS/                     # Incident response guides
│   │   ├── backend-down.md
│   │   ├── database-issues.md
│   │   └── deployment-rollback.md
│   └── DESIGN_SYSTEM.md              # UI component docs
│
└── README.md                         # Project overview
```

---

## Step 5: Version Control & Branching Strategy

### Git Workflow (Git Flow)

```
Main Branch (main):
- Production-ready code only
- Protected branch (require PR reviews)
- Auto-deploy to production on merge

Staging Branch (staging):
- Pre-production environment
- Auto-deploy to staging on merge
- Used for final testing

Development Branch (develop):
- Integration branch for features
- Auto-deploy to development environment

Feature Branches:
- Pattern: feature/JIRA-123-feature-name
- Example: feature/RUPAYA-45-transaction-export
- Create from: develop
- Merge to: develop (via pull request)
- Delete after merge

Hotfix Branches:
- Pattern: hotfix/JIRA-456-bug-fix
- Create from: main
- Merge to: main and develop
- Used for critical production fixes
```

### Pull Request Process

```
1. Create feature branch from develop
2. Make changes with meaningful commits:
   - "feat: add transaction export feature"
   - "fix: handle null balance in dashboard"
   - "docs: update API endpoint documentation"
3. Push and create pull request
4. PR Checklist:
   ✓ Tests pass (CI/CD)
   ✓ Code coverage maintained (>80%)
   ✓ Linting passes (ESLint, Prettier)
   ✓ No security vulnerabilities (Snyk, SAST)
   ✓ Design approved by designer
   ✓ At least 2 code reviews approved
5. Merge to develop
6. Delete feature branch
```

---

## Step 6: Technology Stack Decision

### Backend Stack

```
Runtime:          Node.js 20 LTS
Framework:        Express.js or Fastify
Language:         TypeScript
ORM:              Sequelize or TypeORM
Database:         PostgreSQL 15
Cache:            Redis (for sessions, rate limiting)
Search:           Elasticsearch (optional, for transaction search)
Queue:            Bull or RabbitMQ (async jobs)
Auth:             JWT + Refresh tokens
API Doc:          OpenAPI/Swagger
Testing:          Jest (unit), Supertest (integration)
Linting:          ESLint, Prettier
Monitoring:       CloudWatch, Datadog, or ELK
```

### Web Frontend Stack

```
Framework:        Next.js 14+ (React 18+)
Language:         TypeScript
Styling:          Tailwind CSS (utility-first)
State Management: Zustand or TanStack Query
Forms:            React Hook Form + Zod validation
HTTP Client:      Axios or Fetch API
Testing:          Jest + React Testing Library
E2E Testing:      Playwright or Cypress
Linting:          ESLint, Prettier
Build:            Next.js built-in (Webpack)
Deployment:       Vercel or AWS Amplify
```

### iOS Stack

```
Language:         Swift 5.9+
UI Framework:     SwiftUI (modern) or UIKit (UIViewControllers)
Architecture:     MVVM with Combine or SwiftUI State
HTTP Client:      URLSession or Alamofire
Async:            async/await
JSON Parsing:     Codable
Local Storage:    SQLite (via SQLite.swift) or Core Data
Networking:       Combine publishers or async/await
Authentication:   Keychain for token storage
Analytics:        Firebase Analytics
Crash Reporting:  Firebase Crashlytics or Sentry
Testing:          XCTest
Build System:     Xcode 15+
Dependency Mgr:   CocoaPods or Swift Package Manager
```

### Android Stack

```
Language:         Kotlin 1.9+
UI Framework:     Jetpack Compose (modern) or XML layouts
Architecture:     MVVM with StateFlow
HTTP Client:      Retrofit + OkHttp
Async:            Coroutines + Flow
JSON Parsing:     Kotlinx Serialization or Gson
Local Storage:    Room (SQLite wrapper)
Dependency Inj:   Hilt
Navigation:       Jetpack Navigation
Authentication:   EncryptedSharedPreferences
Analytics:        Firebase Analytics
Crash Reporting:  Firebase Crashlytics or Sentry
Testing:          JUnit, Espresso, MockK
Build System:     Android Studio Koala+, Gradle 8.5+
```

---

# PHASE 1: ARCHITECTURE & INFRASTRUCTURE (Weeks 5-8)

## Step 7: AWS Infrastructure Setup

### AWS Account Structure

```
AWS Organization:
├── Master Account (billing, organization)
├── Production Account
│   ├── VPC: 10.0.0.0/16
│   ├── Availability Zones: ap-south-1a, ap-south-1b, ap-south-1c
│   └── Environment: prod
├── Staging Account (optional, for larger team)
│   └── Environment: staging
└── Development Account
    ├── Shared dev VPC
    └── Developers can create personal dev spaces
```

### Core AWS Services

```
Compute:
├── ECS (Fargate) for containerized backend
│   ├── Cluster: rupaya-cluster
│   ├── Service: rupaya-api
│   └── Task Definition: rupaya-task:X
├── Application Load Balancer (ALB)
└── Auto Scaling Groups

Database:
├── RDS PostgreSQL 15
│   ├── Multi-AZ deployment (for redundancy)
│   ├── Automated backups (30 days retention)
│   └── Enhanced monitoring enabled
├── ElastiCache Redis
│   ├── Multi-AZ replication
│   └── Automatic failover
└── S3 for backups

Storage:
├── S3 Buckets
│   ├── rupaya-media (user uploads)
│   ├── rupaya-backups (database backups)
│   ├── rupaya-logs (application logs)
│   └── rupaya-cdn (static assets)
└── CloudFront (CDN) for global distribution

Networking:
├── VPC with public/private subnets
├── NAT Gateway for outbound traffic
├── Security Groups (principle of least privilege)
└── VPC Endpoints (for AWS services)

Monitoring & Logging:
├── CloudWatch
│   ├── Metrics (CPU, Memory, Network, Errors)
│   ├── Logs (/ecs/rupaya-api, /rds/rupaya)
│   └── Alarms (high CPU, high error rate)
├── X-Ray (distributed tracing)
└── CloudTrail (audit logs)

Security:
├── IAM (least privilege roles)
├── Secrets Manager (database password, API keys)
├── KMS encryption (at rest)
├── WAF (Web Application Firewall)
└── VPC Flow Logs

CI/CD:
├── GitHub Actions (CI/CD pipeline)
├── ECR (Docker image registry)
└── CodeDeploy (deployment automation)
```

### Infrastructure as Code (Terraform)

**File: `infrastructure/terraform/main.tf`**

```hcl
# Configure Terraform
terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Store state in S3 (not local)
  backend "s3" {
    bucket         = "rupaya-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "RUPAYA"
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# VPC and Networking
module "vpc" {
  source = "./modules/vpc"
  
  cidr_block           = "10.0.0.0/16"
  availability_zones   = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  enable_nat_gateway   = true
  enable_vpc_flow_logs = true
}

# RDS PostgreSQL
module "rds" {
  source = "./modules/rds"
  
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  db_name             = "rupaya"
  db_username         = "rupaya_admin"
  db_password         = data.aws_secretsmanager_secret_version.db_password.secret_string
  instance_class      = "db.t3.medium"
  allocated_storage   = 100
  multi_az            = true
  backup_retention    = 30
  
  depends_on = [module.vpc]
}

# ElastiCache Redis
module "redis" {
  source = "./modules/redis"
  
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  node_type           = "cache.t3.micro"
  engine_version      = "7.0"
  multi_az            = true
  automatic_failover  = true
  
  depends_on = [module.vpc]
}

# ECS Cluster for Backend
module "ecs" {
  source = "./modules/ecs"
  
  cluster_name        = "rupaya-cluster"
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  container_image     = var.backend_image_uri
  container_port      = 3000
  cpu                 = 512
  memory              = 1024
  desired_count       = 3  # Minimum 3 for high availability
  
  environment_variables = {
    DATABASE_URL = module.rds.connection_string
    REDIS_URL    = module.redis.endpoint
    NODE_ENV     = var.environment
  }
  
  secrets = {
    JWT_SECRET     = "rupaya/jwt-secret"
    DB_PASSWORD    = "rupaya/db-password"
    API_KEY        = "rupaya/api-key"
  }
  
  depends_on = [module.vpc, module.rds, module.redis]
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"
  
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  ecs_cluster_name  = module.ecs.cluster_name
  ecs_service_name  = module.ecs.service_name
  target_port       = 3000
  
  ssl_certificate_arn = data.aws_acm_certificate.wildcard.arn
  
  depends_on = [module.ecs]
}

# S3 Buckets
module "s3" {
  source = "./modules/s3"
  
  project_name        = "rupaya"
  enable_versioning   = true
  enable_encryption   = true
  enable_public_access_block = true
  
  buckets = {
    media_bucket   = "rupaya-media-${var.environment}"
    backups_bucket = "rupaya-backups-${var.environment}"
  }
}

# CloudFront CDN
module "cloudfront" {
  source = "./modules/cloudfront"
  
  s3_bucket_domain_name = module.s3.media_bucket_domain
  api_domain_name       = module.alb.dns_name
  
  ssl_certificate_arn = data.aws_acm_certificate.wildcard.arn
  
  depends_on = [module.s3, module.alb]
}

# Monitoring and Alarms
module "monitoring" {
  source = "./modules/monitoring"
  
  cluster_name      = module.ecs.cluster_name
  service_name      = module.ecs.service_name
  sns_topic_arn     = aws_sns_topic.alerts.arn
  
  alarm_thresholds = {
    cpu_utilization_percent = 80
    memory_utilization_percent = 85
    error_rate_percent = 5
    api_response_time_ms = 500
  }
}

# Secrets Manager
resource "aws_secretsmanager_secret" "database_password" {
  name_prefix = "rupaya/db-password-"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "database_password" {
  secret_id     = aws_secretsmanager_secret.database_password.id
  secret_string = random_password.db_password.result
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "rupaya-alerts-${var.environment}"
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Outputs
output "alb_dns_name" {
  value = module.alb.dns_name
  description = "Load balancer DNS name"
}

output "database_endpoint" {
  value = module.rds.endpoint
  sensitive = true
}

output "redis_endpoint" {
  value = module.redis.endpoint
}

output "cloudfront_domain" {
  value = module.cloudfront.domain_name
}
```

### Deployment Commands

```bash
# Initialize Terraform
terraform init

# Format and validate
terraform fmt -recursive
terraform validate

# Plan changes (review before applying)
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan

# Destroy (for cleanup, careful!)
terraform destroy

# View outputs
terraform output
```

---

## Step 8: Database Design

### ERD (Entity Relationship Diagram)

```
Users
├── id (UUID primary key)
├── email (unique)
├── password_hash
├── phone_number
├── full_name
├── profile_picture_url
├── kyc_status (enum: pending, verified, rejected)
├── kyc_document_url
├── created_at
├── updated_at
└── deleted_at (soft delete)

Wallets
├── id (UUID primary key)
├── user_id (FK → Users)
├── currency (enum: INR, USD)
├── balance (numeric)
├── is_active (boolean)
├── created_at
├── updated_at

Transactions
├── id (UUID primary key)
├── from_wallet_id (FK → Wallets)
├── to_wallet_id (FK → Wallets)
├── type (enum: income, expense, transfer, refund)
├── category (enum: salary, food, transport, utilities...)
├── amount (numeric)
├── description (text)
├── status (enum: pending, completed, failed, reversed)
├── metadata (jsonb - for custom fields)
├── created_at
├── updated_at

Categories
├── id (UUID primary key)
├── user_id (FK → Users, nullable - for custom categories)
├── name
├── icon (enum or string)
├── color (hex color)
├── is_system_category (boolean)
├── created_at

Budgets
├── id (UUID primary key)
├── user_id (FK → Users)
├── category_id (FK → Categories)
├── period (enum: daily, weekly, monthly, yearly)
├── amount (numeric)
├── alert_threshold (percentage: 80, 100)
├── active_from (date)
├── active_to (date, nullable)
├── created_at
├── updated_at

Notifications
├── id (UUID primary key)
├── user_id (FK → Users)
├── type (enum: transaction, budget_alert, security)
├── title
├── message
├── data (jsonb)
├── read (boolean)
├── created_at

Sessions
├── id (UUID primary key)
├── user_id (FK → Users)
├── token_hash (hashed refresh token)
├── device_info (jsonb)
├── ip_address
├── expires_at
├── created_at

AuditLogs
├── id (UUID primary key)
├── user_id (FK → Users)
├── action (string: login, logout, transaction_created, settings_changed)
├── resource_type (string: user, transaction, settings)
├── resource_id (string)
├── changes (jsonb)
├── ip_address
├── user_agent
├── created_at
```

### Database Migration (Sequelize/TypeORM)

**File: `backend/migrations/001_create_tables.ts`**

```typescript
import { Migration } from 'typeorm'
import { QueryRunner, Table } from 'typeorm'

export class CreateInitialTables1000000000001 implements Migration {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Users table
    await queryRunner.createTable(
      new Table({
        name: 'users',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            default: 'gen_random_uuid()',
          },
          {
            name: 'email',
            type: 'varchar',
            isUnique: true,
          },
          {
            name: 'password_hash',
            type: 'varchar',
          },
          {
            name: 'full_name',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'kyc_status',
            type: 'enum',
            enum: ['pending', 'verified', 'rejected'],
            default: "'pending'",
          },
          {
            name: 'created_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
          {
            name: 'updated_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
            onUpdate: 'CURRENT_TIMESTAMP',
          },
          {
            name: 'deleted_at',
            type: 'timestamp',
            isNullable: true,
          },
        ],
        indices: [
          {
            columnNames: ['email'],
            isUnique: true,
          },
          {
            columnNames: ['created_at'],
          },
        ],
      })
    )

    // Wallets table
    await queryRunner.createTable(
      new Table({
        name: 'wallets',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            default: 'gen_random_uuid()',
          },
          {
            name: 'user_id',
            type: 'uuid',
          },
          {
            name: 'currency',
            type: 'varchar',
            default: "'INR'",
          },
          {
            name: 'balance',
            type: 'numeric',
            precision: 15,
            scale: 2,
            default: 0,
          },
          {
            name: 'is_active',
            type: 'boolean',
            default: true,
          },
          {
            name: 'created_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
        foreignKeys: [
          {
            columnNames: ['user_id'],
            referencedTableName: 'users',
            referencedColumnNames: ['id'],
            onDelete: 'CASCADE',
          },
        ],
      })
    )

    // Transactions table
    await queryRunner.createTable(
      new Table({
        name: 'transactions',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            default: 'gen_random_uuid()',
          },
          {
            name: 'from_wallet_id',
            type: 'uuid',
            isNullable: true,
          },
          {
            name: 'to_wallet_id',
            type: 'uuid',
          },
          {
            name: 'type',
            type: 'varchar',
          },
          {
            name: 'amount',
            type: 'numeric',
            precision: 15,
            scale: 2,
          },
          {
            name: 'status',
            type: 'enum',
            enum: ['pending', 'completed', 'failed', 'reversed'],
            default: "'pending'",
          },
          {
            name: 'created_at',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
        foreignKeys: [
          {
            columnNames: ['to_wallet_id'],
            referencedTableName: 'wallets',
            referencedColumnNames: ['id'],
          },
        ],
        indices: [
          {
            columnNames: ['to_wallet_id', 'created_at'],
          },
        ],
      })
    )
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('transactions')
    await queryRunner.dropTable('wallets')
    await queryRunner.dropTable('users')
  }
}
```

---

## Step 9: API Design (OpenAPI/Swagger)

**File: `backend/openapi.yaml`**

```yaml
openapi: 3.0.0
info:
  title: RUPAYA API
  version: 1.0.0
  description: Personal finance management API
servers:
  - url: https://api.rupaya.com/v1
    description: Production
  - url: https://staging-api.rupaya.com/v1
    description: Staging

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    User:
      type: object
      properties:
        id:
          type: string
          format: uuid
        email:
          type: string
          format: email
        full_name:
          type: string
        kyc_status:
          type: string
          enum: [pending, verified, rejected]
        created_at:
          type: string
          format: date-time

    Transaction:
      type: object
      properties:
        id:
          type: string
          format: uuid
        amount:
          type: number
          format: decimal
        type:
          type: string
          enum: [income, expense, transfer]
        status:
          type: string
          enum: [pending, completed, failed]
        created_at:
          type: string
          format: date-time

paths:
  /auth/signup:
    post:
      summary: Register a new user
      tags: [Auth]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                email:
                  type: string
                  format: email
                password:
                  type: string
                  minLength: 8
                full_name:
                  type: string
      responses:
        201:
          description: User created successfully
          content:
            application/json:
              schema:
                type: object
                properties:
                  access_token:
                    type: string
                  refresh_token:
                    type: string
                  user:
                    $ref: '#/components/schemas/User'
        400:
          description: Invalid input

  /auth/login:
    post:
      summary: Login user
      tags: [Auth]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                email:
                  type: string
                password:
                  type: string
      responses:
        200:
          description: Login successful
          content:
            application/json:
              schema:
                type: object
                properties:
                  access_token:
                    type: string
                  refresh_token:
                    type: string

  /transactions:
    get:
      summary: Get all transactions
      tags: [Transactions]
      security:
        - BearerAuth: []
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
        - name: type
          in: query
          schema:
            type: string
            enum: [income, expense, transfer]
      responses:
        200:
          description: List of transactions
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/Transaction'
                  total:
                    type: integer
                  page:
                    type: integer
    post:
      summary: Create transaction
      tags: [Transactions]
      security:
        - BearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                amount:
                  type: number
                type:
                  type: string
                  enum: [income, expense, transfer]
                category_id:
                  type: string
                  format: uuid
                description:
                  type: string
      responses:
        201:
          description: Transaction created

  /wallets:
    get:
      summary: Get all wallets
      tags: [Wallets]
      security:
        - BearerAuth: []
      responses:
        200:
          description: List of wallets

  /user/profile:
    get:
      summary: Get user profile
      tags: [User]
      security:
        - BearerAuth: []
      responses:
        200:
          description: User profile
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
    patch:
      summary: Update user profile
      tags: [User]
      security:
        - BearerAuth: []
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                full_name:
                  type: string
                phone_number:
                  type: string
      responses:
        200:
          description: Profile updated
```

---

# PHASE 2: BACKEND DEVELOPMENT (Weeks 9-16)

## Step 10: Backend Project Setup

**File: `backend/package.json`**

```json
{
  "name": "rupaya-backend",
  "version": "1.0.0",
  "description": "RUPAYA API Backend",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc && npm run compile",
    "start": "node dist/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src --fix",
    "format": "prettier --write src",
    "typecheck": "tsc --noEmit",
    "migrate": "typeorm migration:run",
    "migrate:revert": "typeorm migration:revert",
    "seed": "ts-node src/database/seeds/index.ts"
  },
  "dependencies": {
    "express": "^4.18.2",
    "typescript": "^5.3.0",
    "dotenv": "^16.3.1",
    "jsonwebtoken": "^9.1.0",
    "bcryptjs": "^2.4.3",
    "typeorm": "^0.3.17",
    "pg": "^8.11.3",
    "redis": "^4.6.11",
    "zod": "^3.22.4",
    "axios": "^1.6.0",
    "pino": "^8.17.2",
    "helmet": "^7.1.0",
    "cors": "^2.8.5",
    "express-async-errors": "^3.1.1",
    "bull": "^4.11.4"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.10.6",
    "@types/jest": "^29.5.11",
    "jest": "^29.7.0",
    "ts-jest": "^29.1.1",
    "tsx": "^4.7.0",
    "supertest": "^6.3.3",
    "@types/supertest": "^2.0.16",
    "eslint": "^8.56.0",
    "@typescript-eslint/eslint-plugin": "^6.17.0",
    "@typescript-eslint/parser": "^6.17.0",
    "prettier": "^3.1.1",
    "ts-node": "^10.9.2"
  }
}
```

---

## Step 11: Backend Application Structure

**File: `backend/src/index.ts`**

```typescript
import 'express-async-errors'
import express, { Request, Response, NextFunction } from 'express'
import helmet from 'helmet'
import cors from 'cors'
import dotenv from 'dotenv'
import { AppDataSource } from './database/data-source'
import logger from './utils/logger'

// Routes
import authRoutes from './routes/auth.routes'
import transactionRoutes from './routes/transaction.routes'
import walletRoutes from './routes/wallet.routes'
import userRoutes from './routes/user.routes'

// Middleware
import { errorHandler } from './middleware/error-handler'
import { requestLogger } from './middleware/request-logger'
import { authentication } from './middleware/authentication'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3000

// Security Middleware
app.use(helmet())
app.use(cors({
  origin: process.env.FRONTEND_URL || '*',
  credentials: true,
}))

// Body Parser
app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ limit: '10mb', extended: true }))

// Request Logging
app.use(requestLogger)

// Health Check
app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  })
})

// API Routes (with /v1 prefix)
app.use('/v1/auth', authRoutes)
app.use('/v1/transactions', authentication, transactionRoutes)
app.use('/v1/wallets', authentication, walletRoutes)
app.use('/v1/user', authentication, userRoutes)

// 404 Handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.path,
  })
})

// Error Handler (must be last)
app.use(errorHandler)

// Initialize Database and Start Server
const startServer = async () => {
  try {
    // Initialize database
    await AppDataSource.initialize()
    logger.info('Database connected successfully')

    // Start express server
    app.listen(PORT, () => {
      logger.info(`Server running on port ${PORT}`)
    })
  } catch (error) {
    logger.error('Failed to start server', error)
    process.exit(1)
  }
}

// Handle unhandled rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason)
})

startServer()

export default app
```

---

## Step 12: Authentication & Authorization

**File: `backend/src/services/auth.service.ts`**

```typescript
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { AppDataSource } from '../database/data-source'
import { User } from '../entities/User'
import { BadRequestError, UnauthorizedError } from '../utils/errors'

export class AuthService {
  private userRepository = AppDataSource.getRepository(User)

  async signup(email: string, password: string, fullName: string) {
    // Check if user exists
    const existingUser = await this.userRepository.findOne({ where: { email } })
    if (existingUser) {
      throw new BadRequestError('Email already registered')
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10)

    // Create user
    const user = this.userRepository.create({
      email,
      passwordHash,
      fullName,
      kycStatus: 'pending',
    })

    await this.userRepository.save(user)

    // Create wallet
    // ... (create default wallet)

    return this.generateTokens(user)
  }

  async login(email: string, password: string) {
    const user = await this.userRepository.findOne({ where: { email } })
    if (!user) {
      throw new UnauthorizedError('Invalid credentials')
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash)
    if (!isPasswordValid) {
      throw new UnauthorizedError('Invalid credentials')
    }

    return this.generateTokens(user)
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = jwt.verify(
        refreshToken,
        process.env.JWT_REFRESH_SECRET!
      ) as { userId: string }

      const user = await this.userRepository.findOne({
        where: { id: payload.userId },
      })
      if (!user) {
        throw new UnauthorizedError('User not found')
      }

      return this.generateTokens(user)
    } catch (error) {
      throw new UnauthorizedError('Invalid refresh token')
    }
  }

  private generateTokens(user: User) {
    const accessToken = jwt.sign(
      {
        userId: user.id,
        email: user.email,
      },
      process.env.JWT_SECRET!,
      {
        expiresIn: '1h',
        algorithm: 'HS256',
      }
    )

    const refreshToken = jwt.sign(
      {
        userId: user.id,
      },
      process.env.JWT_REFRESH_SECRET!,
      {
        expiresIn: '7d',
      }
    )

    return {
      accessToken,
      refreshToken,
      expiresIn: 3600,
    }
  }
}
```

---

## Step 13: Core Business Logic

**File: `backend/src/services/transaction.service.ts`**

```typescript
import { AppDataSource } from '../database/data-source'
import { Transaction } from '../entities/Transaction'
import { Wallet } from '../entities/Wallet'
import { BadRequestError } from '../utils/errors'

export class TransactionService {
  private transactionRepository = AppDataSource.getRepository(Transaction)
  private walletRepository = AppDataSource.getRepository(Wallet)

  async createTransaction(
    userId: string,
    type: string,
    amount: number,
    walletId: string,
    categoryId?: string,
    description?: string
  ) {
    const wallet = await this.walletRepository.findOne({
      where: { id: walletId, user: { id: userId } },
    })

    if (!wallet) {
      throw new BadRequestError('Wallet not found')
    }

    if (type === 'expense' && wallet.balance < amount) {
      throw new BadRequestError('Insufficient balance')
    }

    // Create transaction
    const transaction = this.transactionRepository.create({
      wallet,
      type,
      amount,
      category: categoryId ? { id: categoryId } : null,
      description,
      status: 'completed',
    })

    // Update wallet balance
    if (type === 'income') {
      wallet.balance += amount
    } else if (type === 'expense') {
      wallet.balance -= amount
    }

    await this.transactionRepository.save(transaction)
    await this.walletRepository.save(wallet)

    return transaction
  }

  async getTransactions(
    userId: string,
    page: number = 1,
    limit: number = 20,
    filters?: {
      type?: string
      categoryId?: string
      dateFrom?: Date
      dateTo?: Date
    }
  ) {
    let query = this.transactionRepository
      .createQueryBuilder('t')
      .innerJoinAndSelect('t.wallet', 'w')
      .where('w.user_id = :userId', { userId })

    if (filters?.type) {
      query = query.andWhere('t.type = :type', { type: filters.type })
    }

    if (filters?.categoryId) {
      query = query.andWhere('t.category_id = :categoryId', {
        categoryId: filters.categoryId,
      })
    }

    if (filters?.dateFrom) {
      query = query.andWhere('t.created_at >= :dateFrom', {
        dateFrom: filters.dateFrom,
      })
    }

    if (filters?.dateTo) {
      query = query.andWhere('t.created_at <= :dateTo', {
        dateTo: filters.dateTo,
      })
    }

    const total = await query.getCount()
    const data = await query
      .orderBy('t.created_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getMany()

    return {
      data,
      total,
      page,
      pages: Math.ceil(total / limit),
    }
  }

  async getSummary(userId: string, year: number, month: number) {
    const startDate = new Date(year, month - 1, 1)
    const endDate = new Date(year, month, 1)

    const transactions = await this.transactionRepository
      .createQueryBuilder('t')
      .innerJoin('t.wallet', 'w')
      .where('w.user_id = :userId', { userId })
      .andWhere('t.created_at >= :startDate AND t.created_at < :endDate', {
        startDate,
        endDate,
      })
      .getMany()

    const summary = {
      income: 0,
      expense: 0,
      net: 0,
      byCategory: {} as Record<string, number>,
    }

    for (const txn of transactions) {
      if (txn.type === 'income') {
        summary.income += txn.amount
      } else if (txn.type === 'expense') {
        summary.expense += txn.amount
      }
    }

    summary.net = summary.income - summary.expense
    return summary
  }
}
```

---

## Step 14: Testing & Quality

**File: `backend/src/services/__tests__/transaction.service.test.ts`**

```typescript
import { TransactionService } from '../transaction.service'
import { AppDataSource } from '../../database/data-source'

describe('TransactionService', () => {
  let service: TransactionService

  beforeAll(async () => {
    await AppDataSource.initialize()
    service = new TransactionService()
  })

  afterAll(async () => {
    await AppDataSource.destroy()
  })

  describe('createTransaction', () => {
    it('should create an income transaction', async () => {
      const transaction = await service.createTransaction(
        'user123',
        'income',
        1000,
        'wallet123'
      )

      expect(transaction.type).toBe('income')
      expect(transaction.amount).toBe(1000)
      expect(transaction.status).toBe('completed')
    })

    it('should throw error if insufficient balance for expense', async () => {
      await expect(
        service.createTransaction('user123', 'expense', 10000, 'wallet123')
      ).rejects.toThrow('Insufficient balance')
    })
  })

  describe('getTransactions', () => {
    it('should return paginated transactions', async () => {
      const result = await service.getTransactions('user123', 1, 10)

      expect(result).toHaveProperty('data')
      expect(result).toHaveProperty('total')
      expect(result).toHaveProperty('page')
      expect(Array.isArray(result.data)).toBe(true)
    })
  })
})
```

---

# PHASE 3: FRONTEND DEVELOPMENT - WEB (Weeks 9-18)

## Step 15: Web Project Setup (Next.js)

**File: `web/package.json`**

```json
{
  "name": "rupaya-web",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint && tsc --noEmit",
    "test": "jest",
    "test:watch": "jest --watch",
    "format": "prettier --write ."
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "zustand": "^4.4.1",
    "tanstack-react-query": "^5.28.0",
    "axios": "^1.6.0",
    "zod": "^3.22.4",
    "react-hook-form": "^7.48.0",
    "tailwindcss": "^3.3.6",
    "chart.js": "^4.4.0",
    "react-chartjs-2": "^5.2.0"
  },
  "devDependencies": {
    "typescript": "^5.3.0",
    "@types/react": "^18.2.37",
    "@types/node": "^20.10.6",
    "@types/jest": "^29.5.11",
    "jest": "^29.7.0",
    "jest-environment-jsdom": "^29.7.0",
    "@testing-library/react": "^14.1.2",
    "@testing-library/jest-dom": "^6.1.5",
    "tailwindcss": "^3.3.6",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.32",
    "prettier": "^3.1.1",
    "eslint": "^8.56.0"
  }
}
```

**File: `web/tailwind.config.ts`**

```typescript
import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: 'rgb(33, 128, 141)',
        secondary: 'rgb(94, 82, 64)',
        success: 'rgb(34, 197, 94)',
        error: 'rgb(239, 68, 68)',
        warning: 'rgb(251, 146, 60)',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['Fira Code', 'monospace'],
      },
    },
  },
  plugins: [],
}

export default config
```

---

## Step 16: Web App Structure

**File: `web/src/pages/dashboard.tsx`**

```typescript
import { useQuery } from '@tanstack/react-query'
import { useAuthStore } from '@/store/auth'
import { transactionAPI } from '@/services/api'
import TransactionList from '@/components/TransactionList'
import BalanceCard from '@/components/BalanceCard'
import SummaryChart from '@/components/SummaryChart'

export default function Dashboard() {
  const { user } = useAuthStore()

  const { data: wallets, isLoading: walletsLoading } = useQuery({
    queryKey: ['wallets'],
    queryFn: () => transactionAPI.getWallets(),
  })

  const { data: transactions, isLoading: txnLoading } = useQuery({
    queryKey: ['transactions', { page: 1, limit: 20 }],
    queryFn: () => transactionAPI.getTransactions(1, 20),
  })

  const { data: summary } = useQuery({
    queryKey: ['summary', new Date().getFullYear(), new Date().getMonth() + 1],
    queryFn: () => transactionAPI.getSummary(),
  })

  if (walletsLoading || txnLoading) {
    return <div className="p-4">Loading...</div>
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Welcome, {user?.full_name}</h1>

      {/* Balance Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        {wallets?.map((wallet) => (
          <BalanceCard key={wallet.id} wallet={wallet} />
        ))}
      </div>

      {/* Summary Charts */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
        <SummaryChart summary={summary} />
        {/* Budget vs Actual Chart */}
      </div>

      {/* Recent Transactions */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold mb-4">Recent Transactions</h2>
        <TransactionList transactions={transactions?.data} />
      </div>
    </div>
  )
}
```

**File: `web/src/services/api.ts`**

```typescript
import axios, { AxiosInstance } from 'axios'
import { useAuthStore } from '@/store/auth'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/v1'

const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
})

// Add JWT token to requests
apiClient.interceptors.request.use((config) => {
  const { accessToken } = useAuthStore.getState()
  if (accessToken) {
    config.headers.Authorization = `Bearer ${accessToken}`
  }
  return config
})

// Handle token refresh on 401
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      const { refreshToken: refresh } = useAuthStore.getState()
      if (refresh) {
        try {
          const { data } = await axios.post(
            `${API_BASE_URL}/auth/refresh`,
            { refreshToken: refresh }
          )
          useAuthStore.setState({ accessToken: data.accessToken })
          // Retry original request
          return apiClient(error.config)
        } catch (err) {
          useAuthStore.setState({ accessToken: null, user: null })
          window.location.href = '/login'
        }
      }
    }
    return Promise.reject(error)
  }
)

export const transactionAPI = {
  getTransactions: (page: number, limit: number) =>
    apiClient.get('/transactions', { params: { page, limit } }),
  
  createTransaction: (data: any) =>
    apiClient.post('/transactions', data),
  
  getWallets: () =>
    apiClient.get('/wallets'),
  
  getSummary: () =>
    apiClient.get('/user/summary'),
}

export const authAPI = {
  signup: (email: string, password: string, fullName: string) =>
    apiClient.post('/auth/signup', { email, password, full_name: fullName }),
  
  login: (email: string, password: string) =>
    apiClient.post('/auth/login', { email, password }),
}

export default apiClient
```

---

# PHASE 4: MOBILE DEVELOPMENT - iOS (Weeks 9-20)

## Step 17: iOS Project Setup

**File: `mobile-ios/Podfile`**

```ruby
platform :ios, '14.0'

target 'Rupaya' do
  pod 'Alamofire', '~> 5.8'
  pod 'KeychainAccess'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-swift.git'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

**Swift Project Structure:**

```
Rupaya/
├── App/
│   └── RupayaApp.swift
├── Features/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   ├── SignupView.swift
│   │   └── AuthViewModel.swift
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── DashboardViewModel.swift
│   ├── Transactions/
│   │   ├── TransactionListView.swift
│   │   ├── TransactionDetailView.swift
│   │   └── TransactionViewModel.swift
│   └── Profile/
│       ├── ProfileView.swift
│       └── ProfileViewModel.swift
├── Shared/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Transaction.swift
│   │   └── Wallet.swift
│   ├── Services/
│   │   ├── APIClient.swift
│   │   ├── AuthService.swift
│   │   └── TransactionService.swift
│   ├── ViewModels/
│   │   └── BaseViewModel.swift
│   └── UI/
│       ├── Components/
│       └── Modifiers/
├── Resources/
│   ├── Assets/
│   ├── Localizable.strings
│   └── LaunchScreen.storyboard
└── Rupaya.xcodeproj
```

---

## Step 18: iOS App Implementation (SwiftUI)

**File: `mobile-ios/Rupaya/App/RupayaApp.swift`**

```swift
import SwiftUI
import Firebase
import Sentry

@main
struct RupayaApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var coordinator = NavigationCoordinator()
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Initialize Sentry
        SentrySDK.start { options in
            options.dsn = "https://key@sentry.io/project"
            options.tracesSampleRate = 1.0
            options.environment = "production"
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authViewModel.isAuthenticated {
                    TabView {
                        DashboardView()
                            .tabItem {
                                Label("Dashboard", systemImage: "chart.bar.fill")
                            }
                        
                        TransactionListView()
                            .tabItem {
                                Label("Transactions", systemImage: "list.bullet")
                            }
                        
                        ProfileView()
                            .tabItem {
                                Label("Profile", systemImage: "person.fill")
                            }
                    }
                } else {
                    AuthView(viewModel: authViewModel)
                }
            }
            .environmentObject(authViewModel)
            .environmentObject(coordinator)
        }
    }
}
```

**File: `mobile-ios/Rupaya/Features/Auth/AuthViewModel.swift`**

```swift
import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var error: String?
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let authService = AuthService()
    
    func login(email: String, password: String) {
        isLoading = true
        authService.login(email: email, password: password)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.error = error.localizedDescription
                    self?.isLoading = false
                case .finished:
                    self?.isLoading = false
                }
            } receiveValue: { [weak self] response in
                self?.user = response.user
                self?.isAuthenticated = true
                self?.storeTokens(response.accessToken, response.refreshToken)
            }
            .store(in: &cancellables)
    }
    
    func signup(email: String, password: String, fullName: String) {
        isLoading = true
        authService.signup(email: email, password: password, fullName: fullName)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.error = error.localizedDescription
                    self?.isLoading = false
                case .finished:
                    break
                }
            } receiveValue: { [weak self] response in
                self?.user = response.user
                self?.isAuthenticated = true
                self?.storeTokens(response.accessToken, response.refreshToken)
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    func logout() {
        isAuthenticated = false
        user = nil
        removeTokens()
    }
    
    private func storeTokens(_ accessToken: String, _ refreshToken: String) {
        let keychain = KeychainAccess()
        try? keychain.store(accessToken, forKey: "accessToken")
        try? keychain.store(refreshToken, forKey: "refreshToken")
    }
    
    private func removeTokens() {
        let keychain = KeychainAccess()
        try? keychain.remove("accessToken")
        try? keychain.remove("refreshToken")
    }
}
```

**File: `mobile-ios/Rupaya/Shared/Services/APIClient.swift`**

```swift
import Foundation
import Combine

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = URL(string: "https://api.rupaya.com/v1")!
    private let keychain = KeychainAccess()
    
    func request<T: Decodable>(_ endpoint: String, method: HTTPMethod = .get, body: Data? = nil) -> AnyPublisher<T, APIError> {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add JWT token
        if let token = try? keychain.retrieve("accessToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { _ in APIError.networkError }
            .flatMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.invalidResponse).eraseToAnyPublisher()
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    return Fail(error: APIError.httpError(httpResponse.statusCode)).eraseToAnyPublisher()
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                return Just(data)
                    .decode(type: T.self, decoder: decoder)
                    .mapError { _ in APIError.decodingError }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIError: LocalizedError {
    case networkError
    case invalidResponse
    case httpError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .decodingError:
            return "Failed to parse response"
        }
    }
}
```

---

# PHASE 5: MOBILE DEVELOPMENT - ANDROID (Weeks 9-20)

## Step 19: Android Project Setup

**File: `mobile-android/build.gradle`**

```gradle
plugins {
    id 'com.android.application' version '8.1.3'
    id 'kotlin-android'
    id 'kotlin-kapt'
    id 'com.google.dagger.hilt.android' version '2.48'
    id 'com.google.gms.google-services'
}

android {
    namespace "com.rupaya"
    compileSdk 34
    
    defaultConfig {
        applicationId "com.rupaya"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
        
        vectorDrawables {
            useSupportLibrary true
        }
    }
    
    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = '17'
    }
    
    buildFeatures {
        compose true
    }
    
    composeOptions {
        kotlinCompilerExtensionVersion '1.5.1'
    }
}

dependencies {
    // Jetpack Compose
    implementation 'androidx.compose.ui:ui:1.5.4'
    implementation 'androidx.compose.material3:material3:1.1.1'
    implementation 'androidx.lifecycle:lifecycle-runtime-compose:2.6.2'
    
    // Networking
    implementation 'com.squareup.retrofit2:retrofit:2.10.0'
    implementation 'com.squareup.retrofit2:converter-kotlinx-serialization:2.10.0'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
    implementation 'com.squareup.okhttp3:logging-interceptor:4.11.0'
    
    // Kotlin Serialization
    implementation 'org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0'
    
    // Coroutines
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.1'
    
    // Room Database
    implementation 'androidx.room:room-runtime:2.5.2'
    implementation 'androidx.room:room-ktx:2.5.2'
    kapt 'androidx.room:room-compiler:2.5.2'
    
    // Hilt Dependency Injection
    implementation 'com.google.dagger:hilt-android:2.48'
    kapt 'com.google.dagger:hilt-compiler:2.48'
    implementation 'androidx.hilt:hilt-navigation-compose:1.0.0'
    
    // Firebase
    implementation platform('com.google.firebase:firebase-bom:32.3.1')
    implementation 'com.google.firebase:firebase-analytics-ktx'
    implementation 'com.google.firebase:firebase-crashlytics-ktx'
    
    // Sentry
    implementation 'io.sentry:sentry-android:7.0.0'
    
    // Encrypted SharedPreferences
    implementation 'androidx.security:security-crypto:1.1.0-alpha06'
    
    // Testing
    testImplementation 'junit:junit:4.13.2'
    testImplementation 'org.mockito.kotlin:mockito-kotlin:5.1.0'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
```

---

## Step 20: Android App Structure (Jetpack Compose)

**File: `mobile-android/app/src/main/java/com/rupaya/MainActivity.kt`**

```kotlin
package com.rupaya

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.rupaya.ui.navigation.RupayaNavigation
import com.rupaya.ui.theme.RupayaTheme
import com.rupaya.viewmodel.AuthViewModel
import dagger.hilt.android.AndroidEntryPoint
import io.sentry.android.core.SentryAndroid

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Sentry
        SentryAndroid.init(this) { options ->
            options.dsn = "https://key@sentry.io/project"
            options.tracesSampleRate = 1.0
            options.environment = "production"
        }
        
        setContent {
            RupayaTheme {
                val authViewModel: AuthViewModel = hiltViewModel()
                val isAuthenticated = authViewModel.isAuthenticated.collectAsStateWithLifecycle()
                val isLoading = authViewModel.isLoading.collectAsStateWithLifecycle()
                
                when {
                    isLoading.value -> {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator()
                        }
                    }
                    isAuthenticated.value -> {
                        RupayaNavigation(authViewModel)
                    }
                    else -> {
                        RupayaNavigation(authViewModel)
                    }
                }
            }
        }
    }
}
```

**File: `mobile-android/app/src/main/java/com/rupaya/viewmodel/AuthViewModel.kt`**

```kotlin
package com.rupaya.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rupaya.data.model.User
import com.rupaya.data.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {
    
    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error
    
    private val _user = MutableStateFlow<User?>(null)
    val user: StateFlow<User?> = _user
    
    init {
        checkAuthStatus()
    }
    
    fun login(email: String, password: String) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val response = authRepository.login(email, password)
                _user.value = response.user
                _isAuthenticated.value = true
                _error.value = null
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    fun signup(email: String, password: String, fullName: String) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val response = authRepository.signup(email, password, fullName)
                _user.value = response.user
                _isAuthenticated.value = true
                _error.value = null
            } catch (e: Exception) {
                _error.value = e.message
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    fun logout() {
        viewModelScope.launch {
            authRepository.logout()
            _isAuthenticated.value = false
            _user.value = null
        }
    }
    
    private fun checkAuthStatus() {
        viewModelScope.launch {
            _isAuthenticated.value = authRepository.isAuthenticated()
        }
    }
}
```

---

# PHASE 6: TESTING & QA (Weeks 17-22)

## Step 21: Testing Strategy

### Unit Testing

```bash
# Backend
npm run test:coverage
# Expected: >80% coverage

# Web
npm run test -- --coverage

# iOS
Product > Scheme > Edit Scheme > Test
# Run tests in Xcode

# Android
./gradlew test
```

### Integration Testing

```bash
# Backend API tests
supertest('http://localhost:3000')
  .post('/v1/auth/login')
  .send({ email: 'test@example.com', password: 'password123' })
  .expect(200)

# Web E2E
npx cypress run --spec "cypress/e2e/auth.cy.ts"

# Mobile: Manual testing on device/emulator
```

### QA Checklist

```
Frontend (Web):
[ ] All pages load correctly
[ ] Form validations work
[ ] API calls succeed
[ ] Error handling displays properly
[ ] Responsive design tested (mobile, tablet, desktop)
[ ] Accessibility (WCAG 2.1 AA)
[ ] Performance (Lighthouse score >90)
[ ] Cross-browser testing (Chrome, Safari, Firefox, Edge)

Mobile (iOS):
[ ] App launches without crashes
[ ] Login/signup flow works
[ ] Transactions can be created/viewed
[ ] Offline functionality works
[ ] Tested on iOS 14+ devices
[ ] Memory leaks tested (Xcode Instruments)
[ ] Battery usage optimized
[ ] Network requests on slow 3G

Mobile (Android):
[ ] App launches without crashes
[ ] Login/signup flow works
[ ] Transactions can be created/viewed
[ ] Offline functionality works
[ ] Tested on Android 8+ devices
[ ] Memory leaks tested (Android Profiler)
[ ] Battery usage optimized
[ ] Permissions properly requested

Backend:
[ ] All endpoints tested
[ ] Error responses correct
[ ] Rate limiting works
[ ] Database transactions atomic
[ ] Load testing (1000 concurrent users)
[ ] Security testing (OWASP Top 10)
[ ] API response times <500ms
```

---

# PHASE 7: SECURITY & COMPLIANCE (Weeks 18-24)

## Step 22: Security Hardening

### Backend Security

```typescript
// HTTPS only
const app = express()
app.use((req, res, next) => {
  if (process.env.NODE_ENV === 'production' && !req.secure) {
    return res.redirect(`https://${req.get('host')}${req.url}`)
  }
  next()
})

// Rate limiting
import rateLimit from 'express-rate-limit'
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per windowMs
})
app.use('/v1/', limiter)

// CSRF protection
import csrf from 'csurf'
app.use(csrf())

// SQL Injection prevention (using TypeORM)
// Never: `query = "SELECT * FROM users WHERE id = " + userId`
// Instead:
const user = await userRepository.findOne({
  where: { id: userId }
})

// Input validation (Zod)
const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
})

const loginValidator = (req: Request, res: Response, next: NextFunction) => {
  try {
    schema.parse(req.body)
    next()
  } catch (error) {
    res.status(400).json({ error: 'Invalid input' })
  }
}

// Password hashing
const passwordHash = await bcrypt.hash(password, 10)

// JWT secret in environment
const JWT_SECRET = process.env.JWT_SECRET!
if (!JWT_SECRET) throw new Error('JWT_SECRET not set')
```

### Frontend Security

```typescript
// Content Security Policy
// In Next.js next.config.js:
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net;"
  },
  {
    key: 'X-Frame-Options',
    value: 'DENY'
  },
  {
    key: 'X-Content-Type-Options',
    value: 'nosniff'
  }
]

// XSS prevention
// Never: dangerouslySetInnerHTML
// Instead: text content and JSX

// CSRF token in forms
// Include token in state and send with requests

// Secure cookie storage (no localStorage for tokens)
// Use httpOnly cookies when possible
```

### Mobile Security

```swift
// iOS: Keychain for sensitive data
import KeychainAccess

let keychain = KeychainAccess()
try? keychain.set(token, key: "accessToken")
let token = try? keychain.get("accessToken")

// Certificate Pinning
Alamofire.request("https://api.rupaya.com")
  .validate()
  .response { response in
    // Validate certificate
  }
```

```kotlin
// Android: EncryptedSharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences

val encryptedSharedPreferences = EncryptedSharedPreferences.create(
    "secret_shared_prefs",
    MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
    context,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)

encryptedSharedPreferences.edit().putString("token", token).apply()
```

### Compliance Requirements

```
GDPR (if serving EU users):
[ ] Data processing agreement in place
[ ] User consent for data collection
[ ] Right to be forgotten implemented
[ ] Data breach notification process

RBI/NISM (India):
[ ] KYC verification
[ ] AML compliance
[ ] Transaction monitoring
[ ] Data localization (store in India)

PCI-DSS (if handling payments):
[ ] No card data storage
[ ] Use payment gateway (Razorpay, Stripe)
[ ] Encryption in transit and at rest
[ ] Regular security audits

Security Standards:
[ ] OWASP Top 10 compliance
[ ] Regular penetration testing
[ ] Vulnerability scanning (SAST/DAST)
[ ] Security headers set
[ ] HTTPS enforced
[ ] CSP header configured
```

---

# PHASE 8: APP STORE PREPARATION (Weeks 22-24)

## Step 23: iOS App Store Submission

### Pre-Submission Checklist

```
Requirements:
[ ] Apple Developer Account ($99/year)
[ ] Valid provisioning profile
[ ] Distribution certificate
[ ] App ID created in App Store Connect
[ ] Screenshots (required for each device size)
[ ] Preview video (optional but recommended)
[ ] Privacy policy URL
[ ] Support URL
[ ] Category selected
[ ] Rating set (content rating questionnaire)
[ ] Build signed for distribution

App Icon:
[ ] 1024x1024px PNG
[ ] No transparency
[ ] No rounded corners (OS applies)

Screenshots:
[ ] 5-10 per device size
[ ] Device frame included
[ ] Text clearly readable
[ ] Showcase key features
[ ] Localized (if supporting multiple languages)

Metadata:
[ ] App name (30 chars max)
[ ] Subtitle (30 chars max)
[ ] Description (4000 chars max)
[ ] Keywords (100 chars, comma-separated)
[ ] Version number (semantic versioning)
[ ] Release notes (4000 chars max)
```

### Create Archive & Upload

```bash
# In Xcode
1. Product → Archive
2. Organizer window opens
3. Select archive → Distribute App
4. App Store Connect upload
5. Validate and submit

# Or via Xcode command line
xcodebuild -project Rupaya.xcodeproj \
  -scheme Rupaya \
  -configuration Release \
  archive -archivePath ./Rupaya.xcarchive

xcodebuild -exportArchive \
  -archivePath ./Rupaya.xcarchive \
  -exportPath ./Rupaya.ipa \
  -exportOptionsPlist ExportOptions.plist
```

### Review Process

```
Typical timeline: 24-48 hours
Review guidelines: 
[ ] Functionality works as described
[ ] No crashes or bugs
[ ] Complies with App Store Review Guidelines
[ ] Appropriate content rating
[ ] Privacy policy present
[ ] No rejection reasons (spam, incomplete, etc.)

Common rejection reasons to avoid:
- Incomplete or missing metadata
- App crashes or bugs
- Misleading description
- Privacy policy missing or not accessible
- KYC documentation incomplete
- Payments not through App Store
```

---

## Step 24: Google Play Store Submission

### Pre-Submission Checklist

```
Requirements:
[ ] Google Play Developer Account ($25, one-time)
[ ] Signed APK/AAB for release
[ ] App icon (192x192px PNG)
[ ] Feature graphic (1024x500px PNG)
[ ] Screenshots (4-8 per orientation)
[ ] Privacy policy URL
[ ] Content rating questionnaire
[ ] Target audience selected

App Icon:
[ ] 192x192px PNG (no rounded corners)
[ ] 512x512px PNG (for playstore)
[ ] 1024x1024px PNG (optional)

Screenshots:
[ ] Minimum 2, maximum 8
[ ] Localized if needed
[ ] JPEG or 24-bit PNG
[ ] Aspect ratio: phone (9:16 to 20:9), tablet (4:3 to 21:9)

Metadata:
[ ] App name (50 chars max)
[ ] Short description (80 chars max)
[ ] Full description (4000 chars max)
[ ] Category
[ ] Content rating
[ ] Privacy policy
[ ] App website (optional)

Signing:
[ ] Release keystore created
[ ] Keystore backup secure
[ ] Build AAB (Android App Bundle) format
```

### Build & Sign APK/AAB

```bash
# Generate signing key
keytool -genkey -v -keystore rupaya-release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias rupaya_release

# In android/app/build.gradle
signingConfigs {
    release {
        storeFile file('rupaya-release.keystore')
        storePassword = System.getenv("KEYSTORE_PASSWORD")
        keyAlias = System.getenv("KEY_ALIAS")
        keyPassword = System.getenv("KEY_PASSWORD")
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}

# Build AAB
./gradlew bundleRelease

# Or APK
./gradlew assembleRelease
```

### Upload to Play Console

```
1. Go to Google Play Console
2. Create app
3. Fill out all details
4. Upload AAB (app/release/app-release.aab)
5. Roll out to test track first (10% of users)
6. Monitor crash reports and ratings
7. After 1-2 weeks, gradually roll out to 100%
```

---

# PHASE 9: DEPLOYMENT & LAUNCH (Weeks 25-26)

## Step 25: Production Deployment

### Backend Deployment (ECS)

```bash
# Build Docker image
docker build -t rupaya-backend:1.0.0 .

# Push to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.ap-south-1.amazonaws.com

docker tag rupaya-backend:1.0.0 123456789.dkr.ecr.ap-south-1.amazonaws.com/rupaya-backend:1.0.0
docker push 123456789.dkr.ecr.ap-south-1.amazonaws.com/rupaya-backend:1.0.0

# Update ECS service
aws ecs update-service \
  --cluster rupaya-cluster \
  --service rupaya-service \
  --force-new-deployment

# Monitor rollout
aws ecs wait services-stable --cluster rupaya-cluster --services rupaya-service
```

### Web Deployment (Vercel or AWS)

```bash
# Deploy to Vercel
npm install -g vercel
vercel --prod

# Or deploy to AWS Amplify
aws amplify deploy
```

### Database Migration

```bash
# Run migrations
npm run migrate

# Verify data integrity
psql -h rupaya-db.xxxxx.ap-south-1.rds.amazonaws.com \
     -U rupaya_admin -d rupaya \
     -c "SELECT COUNT(*) FROM users;"
```

### iOS Launch

```
1. Set build number to 1
2. Set version to 1.0.0
3. Archive and submit
4. Wait for review (~48 hours)
5. Release manually or automatically
6. Monitor crash reports in Xcode
```

### Android Launch

```
1. Start with 10% rollout
2. Monitor crash rates for 2 days
3. If crashes <0.5%, rollout to 50%
4. Monitor for another 2 days
5. Rollout to 100%
```

---

## Step 26: Post-Launch Monitoring

### Metrics to Monitor

```
Application Metrics:
- API response time (target: <500ms)
- Error rate (target: <0.1%)
- Concurrent active users
- Transaction success rate (target: >99.5%)

Infrastructure Metrics:
- CPU utilization (target: <80%)
- Memory utilization (target: <85%)
- Database connections (target: <80% of max)
- Redis memory usage

Business Metrics:
- User signups (daily, weekly)
- Active users (DAU, WAU, MAU)
- Transaction volume
- Customer support tickets
```

### Alerting

```yaml
CloudWatch Alarms:
- High error rate: >1% for 5 minutes → SNS → Slack
- High API latency: >1s for 10 minutes → SNS → Slack
- Database connection pool low: >80% used → SNS → email
- Server CPU high: >85% for 10 minutes → Auto-scale
- Disk usage: >80% → SNS → Slack
```

### Incident Response

Use the RUPAYA Incident Response Runbook (provided earlier in this document) for handling production issues.

---

## Timeline Summary

```
Week 1-4: Foundation
└─ Team setup, project management, design system, repositories

Week 5-8: Architecture & Infrastructure
└─ AWS setup, database design, API specification

Week 9-16: Backend Development
└─ Core API, authentication, business logic, testing

Week 9-18: Web Frontend Development
└─ UI components, pages, integrations, testing

Week 9-20: Mobile Development (iOS & Android)
└─ UI implementation, features, testing

Week 17-22: Testing & QA
└─ Integration tests, E2E tests, user testing

Week 18-24: Security & Compliance
└─ Security hardening, compliance requirements

Week 22-24: App Store Preparation
└─ Screenshots, metadata, builds, submissions

Week 25-26: Launch
└─ Deployment, monitoring, incident response
└─ iOS App Store release
└─ Google Play Store rollout
└─ Web platform launch
```

---

## Repository Checklist Before Launch

```
Code Quality:
✓ All tests passing (>80% coverage)
✓ No console errors or warnings
✓ Linting passing (ESLint, Prettier)
✓ No security vulnerabilities (Snyk, SonarQube)
✓ Code reviewed by 2+ team members
✓ Documentation complete

Performance:
✓ API response time <500ms
✓ Web Lighthouse score >90
✓ Mobile app starts in <2 seconds
✓ Database queries optimized
✓ No memory leaks
✓ Load tested (1000+ concurrent users)

Security:
✓ HTTPS enforced
✓ JWT tokens in place
✓ Password hashed with bcrypt
✓ Sensitive data encrypted
✓ Rate limiting enabled
✓ CORS properly configured
✓ SQL injection prevention
✓ XSS prevention
✓ CSRF tokens
✓ Security headers set

Monitoring:
✓ CloudWatch alarms configured
✓ Error tracking (Sentry/Datadog)
✓ Logging centralized
✓ Dashboard created
✓ On-call rotation setup
✓ Incident response runbook ready

Documentation:
✓ README.md in each repo
✓ API documentation (OpenAPI/Swagger)
✓ Architecture decision records
✓ Deployment guide
✓ Security guidelines
✓ Contributing guide
✓ Incident response procedures
```

---

## Post-Launch Roadmap (Q2 2026+)

```
Month 1 (March 2026):
- Monitor stability and crash rates
- Address user feedback
- Optimize slow queries
- Improve onboarding flow

Month 2-3 (April-May):
- Add analytics dashboard
- Implement budget tracking
- Add recurring transactions
- Improve notifications

Month 4-6 (June-August):
- Add bill reminders
- Implement goals feature
- Add investment tracking
- Multi-currency support

Month 7-12:
- AI-powered spending insights
- Investment recommendations
- Netbanking integration
- International payments
```

---

## Final Checklist

**Before Going Live:**

- [ ] All 14 team members hired and onboarded
- [ ] Architecture approved by tech leads
- [ ] Database backups automated
- [ ] CI/CD pipelines working
- [ ] Monitoring and alerting configured
- [ ] Incident response team trained
- [ ] Customer support team ready
- [ ] Marketing launch plan ready
- [ ] Privacy policy and ToS reviewed by legal
- [ ] KYC processes implemented and tested
- [ ] Payment gateway integrated and tested
- [ ] iOS build submitted to App Store
- [ ] Android build uploaded to Play Console
- [ ] Web platform deployed and tested
- [ ] Post-launch support team staffed 24/7

---

**This is a complete, industry-standard launch plan for building RUPAYA at scale. Follow it phase-by-phase, and you'll have a production-ready application ready for millions of users.**

**Key Success Principles:**
1. **Do basics right first** (security, testing, monitoring)
2. **Automate everything** (CI/CD, deployments, alerting)
3. **Plan for scale from day 1** (architecture, database, caching)
4. **Communication is critical** (daily standups, incident response)
5. **Test rigorously** (unit, integration, E2E, load, security)
6. **Monitor obsessively** (metrics, alerts, dashboards)
7. **Document everything** (architecture, APIs, runbooks)

Good luck building RUPAYA! 🚀