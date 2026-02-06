# RUPAYA - Security Guidelines

## Security Architecture

### Defense in Depth

RUPAYA implements multiple layers of security:

1. **Application Layer**
   - Input validation & sanitization
   - Output encoding
   - CSRF protection
   - XSS prevention

2. **Authentication Layer**
   - Password entropy checking (minimum 50 bits)
   - HaveIBeenPwned integration
   - Multi-factor authentication (TOTP)
   - Biometric authentication
   - Session management with JWT

3. **Network Layer**
   - TLS 1.3 only
   - Certificate pinning
   - API rate limiting
   - WAF rules

4. **Data Layer**
   - Encryption at rest (AES-256)
   - Encryption in transit (TLS 1.3)
   - Database access controls
   - Regular backups

## Authentication & Authorization

### Password Requirements

- Minimum 12 characters
- Must contain: uppercase, lowercase, digit, special character
- Cannot be in breach database (HaveIBeenPwned)
- Minimum entropy: 50 bits

### Account Lockout Policy

Progressive lockout:
- 5 failed attempts: 15 minutes lockout
- 6 failed attempts: 1 hour lockout
- 10 failed attempts: 24 hours lockout

### Multi-Factor Authentication

- TOTP (Time-based One-Time Password)
- 32-character base32 secret
- 30-second time window
- 2-step tolerance window
- 10 backup codes per user

### Session Management

**Access Tokens:**
- Duration: 15 minutes
- Algorithm: RS256
- Claims: userId, deviceId, type

**Refresh Tokens:**
- Duration: 7 days
- Algorithm: RS256
- Stored in secure storage only
- Can be revoked

## Mobile App Security

### iOS

**Keychain Storage:**
```swift
kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
```

**Certificate Pinning:**
```swift
func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
) {
    // Validate server certificate
    // Reject if not matching pinned cert
}
```

**Data Protection:**
- Files: NSFileProtectionComplete
- UserDefaults: Not for sensitive data
- Keychain: All tokens & secrets

### Android

**Encrypted Storage:**
```kotlin
EncryptedSharedPreferences.create(
    context,
    "rupaya_secure_prefs",
    masterKey,
    PrefKeyEncryptionScheme.AES256_SIV,
    PrefValueEncryptionScheme.AES256_GCM
)
```

**Certificate Pinning:**
```kotlin
CertificatePinner.Builder()
    .add("api.rupaya.com", "sha256/PUBLIC_KEY_HASH")
    .build()
```

**ProGuard Rules:**
```
-keep class com.rupaya.** { *; }
-keepclassmembers class com.rupaya.** { *; }
```

## API Security

### Rate Limiting

**Standard Endpoints:**
- 100 requests per 15 minutes per IP
- Headers: X-RateLimit-Limit, X-RateLimit-Remaining

**Authentication Endpoints:**
- 5 requests per 15 minutes per IP
- Stricter limits for failed attempts

### Request Validation

All requests include:
```
X-API-Version: v1
X-Request-ID: <UUID>
X-Timestamp: <epoch-ms>
X-Device-ID: <device-fingerprint>
Authorization: Bearer <token>
```

### Response Headers

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
```

## Database Security

### Encryption

**At Rest:**
- RDS encryption with KMS
- AES-256-GCM algorithm
- Automated key rotation

**In Transit:**
- TLS 1.3 for all connections
- SSL mode: require

### Access Control

```sql
-- Read-only user for analytics
CREATE USER rupaya_readonly WITH PASSWORD 'secure_password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rupaya_readonly;

-- Application user with limited permissions
CREATE USER rupaya_app WITH PASSWORD 'secure_password';
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO rupaya_app;
REVOKE DELETE ON audit_log FROM rupaya_app;
```

### Sensitive Data

**Stored Encrypted:**
- MFA secrets (AES-256-GCM with app key)
- OAuth tokens
- Backup codes

**Never Stored:**
- Passwords (only bcrypt hashes with cost 10)
- Credit card numbers
- SSN/PAN numbers

## Audit Logging

All sensitive operations logged:
```sql
INSERT INTO audit_log (
    user_id,
    action,
    entity_type,
    entity_id,
    old_value,
    new_value,
    ip_address,
    user_agent
) VALUES (...);
```

**Logged Actions:**
- Authentication attempts
- Password changes
- MFA setup/removal
- Account deletions
- Large transactions
- Settings changes

## Incident Response

### Detection

**Monitoring:**
- Failed login attempts
- Unusual API patterns
- Database performance
- Error rates

**Alerts:**
- CloudWatch alarms
- PagerDuty integration
- Email notifications

### Response Procedure

1. **Identify:** Confirm security incident
2. **Contain:** Isolate affected systems
3. **Eradicate:** Remove threat
4. **Recover:** Restore services
5. **Learn:** Post-incident review

### Contact

**Security Team:**
- Email: security@rupaya.com
- PGP Key: Available at https://rupaya.com/security.asc

**Bug Bounty:**
- Responsible disclosure program
- Rewards for valid security findings

## Compliance

### Data Protection

- GDPR compliant
- User data deletion on request
- Data portability support
- Privacy policy: https://rupaya.com/privacy

### Financial Regulations

- PCI-DSS compliance (not storing card data)
- AML/KYC procedures
- Regular security audits

## Security Updates

### Dependency Management

```bash
# Check for vulnerabilities
npm audit
pod outdated
./gradlew dependencyUpdates

# Update dependencies monthly
npm update
pod update
```

### Patch Schedule

- Critical: Within 24 hours
- High: Within 1 week
- Medium: Within 1 month
- Low: Next release cycle

## Penetration Testing

**Annual Tests:**
- External penetration test
- Internal vulnerability assessment
- Mobile app security review
- API security audit

**Continuous:**
- Automated SAST/DAST scans
- Dependency vulnerability scanning
- Container security scanning

## Security Training

**Developer Training:**
- Secure coding practices
- OWASP Top 10
- Mobile security best practices
- Quarterly security reviews

**Resources:**
- OWASP Mobile Security Testing Guide
- NIST Cybersecurity Framework
- CIS Controls

---

**Last Updated:** February 1, 2026
**Next Review:** August 1, 2026
