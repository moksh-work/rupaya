# RUPAYA Architecture

## Overview
RUPAYA is a multi-platform money management system with a shared data model, a single backend API, and native clients for iOS and Android (plus optional web). The architecture prioritizes security, observability, and scalability.

## Core Components
- **Backend API (Node.js/Express)**: Authentication, accounts, transactions, analytics.
- **Database (PostgreSQL)**: System of record for users and financial data.
- **Cache (Redis)**: Token/session caching, rate limiting helpers, and hot data.
- **Mobile Apps (iOS/Android)**: Native clients with secure storage and biometric auth.
- **Shared Models**: Cross-platform contracts and enums in shared/.
- **Infrastructure (Terraform)**: Reproducible AWS resources for production.

## High-Level Data Flow
1. Mobile/Web client authenticates and receives JWT access/refresh tokens.
2. Client calls backend APIs with access token.
3. Backend validates token, enforces rate limits, and queries PostgreSQL.
4. Backend emits structured logs and metrics to monitoring.

## Security Architecture
- **Authentication**: JWT access tokens with refresh tokens; MFA supported.
- **Transport Security**: HTTPS enforced; secure headers via Helmet.
- **Secret Management**: No secrets in code; use environment variables and secret stores.
- **Data Protection**: Encrypt sensitive data at rest and in transit; minimize PII exposure.
- **Input Validation**: Centralized validation and request limits to reduce attack surface.

## Observability
- **Logging**: Structured logs with request metadata.
- **Metrics**: API latency, error rate, and DB connection saturation.
- **Tracing**: Optional distributed tracing for request correlation.
- **Alerting**: PagerDuty/Slack for critical incidents.

## Scalability & Reliability
- **Horizontal scaling**: Stateless API scaled via ECS/EKS.
- **Database**: Read replicas and connection pooling for growth.
- **Caching**: Redis to reduce DB load.
- **Backups**: Automated snapshots and point-in-time recovery.

## Compliance & Audit
- **Least privilege** IAM roles and policies.
- **Audit trails** for critical actions.
- **Change management** via code review and CI/CD gates.

## Environments
- **Development**: Local Docker-based dependencies.
- **Staging**: Pre-production validation.
- **Production**: Highly controlled access and monitoring.

## References
- Deployment details: docs/DEPLOYMENT.md
- Security practices: docs/SECURITY_GUIDELINES.md
- Incident response: docs/RUNBOOKS/incident-response.md
