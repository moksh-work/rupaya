# Docker Deployment Guide for RUPAYA Backend

## Overview

This guide covers Docker deployment for RUPAYA Backend with support for multiple environments:
- 🚀 **Development** (Local testing with hot reload)
- 🏢 **Production** (Optimized for performance)
- ☁️ **AWS ECS** (Container orchestration)
- 🌐 **Heroku** (Simple cloud deployment)

---

## 📋 Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ RAM available
- Ports 3000, 5432, 6379 available

Verify installation:
```bash
docker --version
docker-compose --version
```

---

## 🚀 Quick Start - Development Mode

### Option 1: Automated Script (Recommended)

```bash
cd backend
chmod +x docker-start-dev.sh
./docker-start-dev.sh
```

### Option 2: Manual Commands

```bash
cd backend

# Copy environment file
cp .env.docker .env

# Build and start services
docker-compose -f docker-compose.dev.yml build
docker-compose -f docker-compose.dev.yml up -d

# Wait for PostgreSQL
sleep 10

# Run migrations
docker-compose -f docker-compose.dev.yml exec backend npm run migrate

# Check status
docker-compose -f docker-compose.dev.yml ps
```

### Verify Backend is Running

```bash
# Check health
curl http://localhost:3000/health

# Expected response:
# {"status":"OK","timestamp":"2026-01-27T..."}
```

---

## 🧪 Testing the API

### 1. Sign Up
```bash
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "deviceId": "docker-test",
    "deviceName": "Docker Test"
  }'
```

### 2. Create Account
```bash
# Replace TOKEN with the accessToken from signup response
curl -X POST http://localhost:3000/api/v1/accounts \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Checking",
    "account_type": "bank",
    "current_balance": 5000
  }'
```

### 3. Create Transaction
```bash
# Replace TOKEN, ACCOUNT_ID, and CATEGORY_ID
curl -X POST http://localhost:3000/api/v1/transactions \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "accountId": "ACCOUNT_ID",
    "amount": 100,
    "type": "expense",
    "categoryId": "CATEGORY_ID",
    "description": "Test expense"
  }'
```

### 4. Get Dashboard
```bash
curl "http://localhost:3000/api/v1/analytics/dashboard?period=month" \
  -H "Authorization: Bearer TOKEN"
```

---

## 📊 Docker Container Management

### View Logs
```bash
# All services
docker-compose -f docker-compose.dev.yml logs -f

# Backend only
docker-compose -f docker-compose.dev.yml logs -f backend

# Follow new entries
docker-compose -f docker-compose.dev.yml logs -f --tail=50
```

### Access Services Directly

#### PostgreSQL Shell
```bash
docker-compose -f docker-compose.dev.yml exec postgres psql -U rupaya -d rupaya_dev
```

#### Redis CLI
```bash
docker-compose -f docker-compose.dev.yml exec redis redis-cli
```

#### Backend Shell
```bash
docker-compose -f docker-compose.dev.yml exec backend sh
```

### Stop Services
```bash
# Stop but keep data
docker-compose -f docker-compose.dev.yml stop

# Remove containers and volumes (clean slate)
docker-compose -f docker-compose.dev.yml down -v
```

### Rebuild Services
```bash
# Rebuild after dependency changes
docker-compose -f docker-compose.dev.yml build --no-cache

# Start updated services
docker-compose -f docker-compose.dev.yml up -d
```

---

## 🏢 Production Mode

### Prepare Environment

Create `.env.prod` with production values:
```bash
NODE_ENV=production
PORT=3000
DB_HOST=<your-rds-endpoint>
DB_PORT=5432
DB_USER=rupaya
DB_PASSWORD=<strong-password>
DB_NAME=rupaya_prod
REDIS_URL=redis://<your-elasticache-endpoint>:6379
JWT_SECRET=<32-char-min-secret>
REFRESH_TOKEN_SECRET=<32-char-min-secret>
ENCRYPTION_KEY=<32-char-min-secret>
FRONTEND_URL=https://yourdomain.com
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>
AWS_S3_BUCKET=rupaya-backups
```

### Start Production Stack

```bash
cd backend

# Use environment file
export $(cat .env.prod | xargs)

# Start services
docker-compose -f docker-compose.prod.yml up -d

# Verify services are healthy
docker-compose -f docker-compose.prod.yml ps
```

### Health Checks

The production setup includes health checks that verify:
- PostgreSQL connectivity
- Redis connectivity
- Backend API responsiveness

View health status:
```bash
docker-compose -f docker-compose.prod.yml ps

# Look at HEALTH column - should show "healthy" after startup
```

---

## ☁️ AWS ECS Deployment

### Prerequisites
- AWS Account
- ECR repository created
- ECS cluster configured
- RDS PostgreSQL instance
- ElastiCache Redis instance

### Build and Push Docker Image

```bash
# Authenticate with ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build for production
docker build -t rupaya-backend:latest --target production .

# Tag for ECR
docker tag rupaya-backend:latest \
  <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/rupaya-backend:latest

# Push to ECR
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/rupaya-backend:latest
```

### Update ECS Task Definition

Use the image URI from ECR in your ECS task definition.

---

## 🌐 Heroku Deployment

### Prerequisites
- Heroku CLI installed
- Heroku account
- PostgreSQL add-on
- Redis add-on

### Deploy

```bash
cd backend

# Create Heroku app
heroku create rupaya-backend

# Add PostgreSQL
heroku addons:create heroku-postgresql:standard-0

# Add Redis
heroku addons:create heroku-redis:premium-0

# Set environment variables
heroku config:set \
  JWT_SECRET=<your-secret> \
  REFRESH_TOKEN_SECRET=<your-secret> \
  ENCRYPTION_KEY=<your-secret>

# Deploy
git push heroku main

# View logs
heroku logs --tail
```

---

## 📁 Docker Files Structure

```
backend/
├── Dockerfile                 # Multi-stage production build
├── docker-compose.dev.yml     # Development stack (hot reload)
├── docker-compose.prod.yml    # Production stack
├── docker-compose.ecs.yml     # AWS ECS configuration
├── docker-start-dev.sh        # Dev startup script
├── docker-start-prod.sh       # Prod startup script
├── .dockerignore             # Build ignore rules
├── .env.docker              # Docker environment template
├── Procfile                 # Heroku deployment config
├── package.json             # With Docker scripts
└── src/
    └── app.js               # Express application
```

---

## 🐛 Troubleshooting

### PostgreSQL Connection Refused
```bash
# Wait longer for PostgreSQL to start
sleep 15

# Check PostgreSQL status
docker-compose -f docker-compose.dev.yml logs postgres

# Restart PostgreSQL
docker-compose -f docker-compose.dev.yml restart postgres
```

### Port Already in Use
```bash
# Find what's using the port (macOS)
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or use different port
PORT=3001 docker-compose -f docker-compose.dev.yml up
```

### Out of Memory
```bash
# Increase Docker memory in Docker Desktop Settings
# Or increase Docker resource limits on your system

# Check current usage
docker stats
```

### Database Connection Issues

Check environment variables in running container:
```bash
docker-compose -f docker-compose.dev.yml exec backend env | grep DB_
```

### Build Fails with Permission Denied

```bash
# Make scripts executable
chmod +x docker-start-dev.sh
chmod +x docker-start-prod.sh

# Rebuild
docker-compose -f docker-compose.dev.yml build --no-cache
```

---

## 📈 Performance Optimization

### Development
- Hot reload enabled (nodemon)
- Debug logging enabled
- Direct file mounting for quick changes

### Production
- Multi-stage build (minimal image size ~150MB)
- Non-root user for security
- Health checks configured
- Signal handling with dumb-init

---

## 🔒 Security Best Practices

### Development
- Use .env.docker for local secrets only
- Don't commit .env files

### Production
- Store secrets in environment variables
- Use AWS Secrets Manager or similar
- Enable HTTPS with ALB
- Use VPC endpoints
- Enable encryption at rest and in transit

---

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/dev-best-practices/dockerfile_best-practices/)

---

## ✅ Deployment Checklist

- [ ] Docker and Docker Compose installed
- [ ] Environment variables configured
- [ ] Ports 3000, 5432, 6379 available
- [ ] Database initialized
- [ ] Migrations ran successfully
- [ ] Health check passing
- [ ] API endpoints responding
- [ ] Logs checked for errors
- [ ] Secrets not committed to git
- [ ] Backup strategy planned

---

**Status:** ✅ Ready for Local Testing and Production Deployment
