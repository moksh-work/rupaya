# RUPAYA - Deployment Guide

## Prerequisites

- Node.js 18+
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose
- AWS Account (for production)
- Domain name with SSL certificate

## Backend Deployment

### Local Development

1. **Install dependencies:**
```bash
cd backend
npm install
```

2. **Configure environment:**
```bash
cp .env.example .env
# Edit .env with your configurations
```

3. **Start services with Docker:**
```bash
docker-compose up -d
```

4. **Run migrations:**
```bash
npm run migrate
```

5. **Start development server:**
```bash
npm run dev
```

### Production Deployment (AWS)

#### 1. Database Setup (RDS Aurora PostgreSQL)

```bash
aws rds create-db-cluster \
  --db-cluster-identifier rupaya-cluster \
  --engine aurora-postgresql \
  --engine-version 15.3 \
  --master-username admin \
  --master-user-password <secure-password> \
  --database-name rupaya_prod
```

#### 2. Redis Setup (ElastiCache)

```bash
aws elasticache create-replication-group \
  --replication-group-id rupaya-redis \
  --replication-group-description "RUPAYA Redis Cluster" \
  --engine redis \
  --cache-node-type cache.t3.micro \
  --num-cache-clusters 2
```

#### 3. Container Registry (ECR)

```bash
# Create repository
aws ecr create-repository --repository-name rupaya-backend

# Build and push image
docker build -t rupaya-backend .
docker tag rupaya-backend:latest <account-id>.dkr.ecr.<region>.amazonaws.com/rupaya-backend:latest
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/rupaya-backend:latest
```

#### 4. ECS Deployment

Create `task-definition.json`:
```json
{
  "family": "rupaya-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [{
    "name": "rupaya-backend",
    "image": "<account-id>.dkr.ecr.<region>.amazonaws.com/rupaya-backend:latest",
    "portMappings": [{
      "containerPort": 3000,
      "protocol": "tcp"
    }],
    "environment": [
      {"name": "NODE_ENV", "value": "production"},
      {"name": "PORT", "value": "3000"}
    ],
    "secrets": [
      {"name": "DB_PASSWORD", "valueFrom": "arn:aws:secretsmanager:..."},
      {"name": "JWT_SECRET", "valueFrom": "arn:aws:secretsmanager:..."}
    ]
  }]
}
```

Deploy:
```bash
aws ecs create-service \
  --cluster rupaya-cluster \
  --service-name rupaya-backend \
  --task-definition rupaya-backend \
  --desired-count 2 \
  --launch-type FARGATE
```

## iOS Deployment

### 1. Configure Xcode Project

1. Open `ios/RUPAYA.xcodeproj`
2. Update Bundle Identifier: `com.yourcompany.rupaya`
3. Configure Signing & Capabilities
4. Add Push Notifications capability
5. Update API endpoint in production build

### 2. App Store Connect Setup

1. Create app in App Store Connect
2. Fill app information
3. Upload screenshots (required sizes)
4. Set pricing and availability

### 3. Build and Upload

```bash
# Install dependencies
cd ios
pod install

# Archive for distribution
xcodebuild -workspace RUPAYA.xcworkspace \
  -scheme RUPAYA \
  -configuration Release \
  -archivePath build/RUPAYA.xcarchive \
  archive

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/RUPAYA.xcarchive \
  -exportPath build \
  -exportOptionsPlist ExportOptions.plist

# Upload to App Store
xcrun altool --upload-app \
  --type ios \
  --file build/RUPAYA.ipa \
  --username "your@email.com" \
  --password "@keychain:AC_PASSWORD"
```

## Android Deployment

### 1. Generate Signing Key

```bash
keytool -genkey -v -keystore rupaya-release-key.jks \
  -alias rupaya -keyalg RSA -keysize 2048 -validity 10000
```

### 2. Configure Gradle

Add to `android/app/build.gradle.kts`:
```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file("../rupaya-release-key.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = "rupaya"
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 3. Build Release APK/AAB

```bash
cd android

# Build AAB (for Play Store)
./gradlew bundleRelease

# Build APK
./gradlew assembleRelease
```

### 4. Upload to Play Console

1. Go to Google Play Console
2. Create new app
3. Fill store listing
4. Upload AAB: `app/build/outputs/bundle/release/app-release.aab`
5. Complete content rating questionnaire
6. Set pricing & distribution
7. Submit for review

## Monitoring & Maintenance

### CloudWatch Alarms

```bash
# CPU utilization alarm
aws cloudwatch put-metric-alarm \
  --alarm-name rupaya-cpu-high \
  --alarm-description "CPU over 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold

# Database connections alarm
aws cloudwatch put-metric-alarm \
  --alarm-name rupaya-db-connections \
  --alarm-description "DB connections over 80%" \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --statistic Average \
  --period 60 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

### Backup Strategy

1. **Database Backups:**
   - RDS automated backups: 7 days retention
   - Manual snapshots before major deployments

2. **Application Logs:**
   - CloudWatch Logs retention: 30 days
   - Archive to S3 after 30 days

3. **User Data Backups:**
   - Daily incremental backups
   - Weekly full backups to S3 Glacier

## Security Checklist

- ✅ SSL/TLS certificates configured
- ✅ API rate limiting enabled
- ✅ Database encryption at rest
- ✅ Secrets stored in AWS Secrets Manager
- ✅ WAF rules configured
- ✅ Security groups properly configured
- ✅ CloudTrail logging enabled
- ✅ Regular security audits scheduled

## Rollback Procedure

1. **Backend Rollback:**
```bash
# Update ECS service to previous task definition
aws ecs update-service \
  --cluster rupaya-cluster \
  --service rupaya-backend \
  --task-definition rupaya-backend:PREVIOUS_REVISION
```

2. **Database Rollback:**
```bash
# Restore from snapshot
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier rupaya-cluster-restored \
  --snapshot-identifier snapshot-name
```

3. **Mobile App Rollback:**
   - iOS: Resubmit previous version
   - Android: Rollback in Play Console (up to 90 days)
