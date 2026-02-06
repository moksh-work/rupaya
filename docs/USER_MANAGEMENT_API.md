# User Management API Endpoints

All user endpoints require authentication via JWT token in the `Authorization: Bearer <token>` header.

## User Profile Endpoints

### 1. Get User Profile
**GET** `/api/v1/users/profile`

Retrieve the authenticated user's profile information.

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**Response:** `200 OK`
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "name": "John Doe",
  "phoneNumber": "+919876543210",
  "phoneVerified": false,
  "countryCode": "IN",
  "currencyPreference": "INR",
  "profilePictureUrl": "/uploads/profile-pictures/abc-123",
  "createdAt": "2026-01-27T10:00:00Z",
  "updatedAt": "2026-01-27T10:00:00Z"
}
```

**Errors:**
- `401` - Unauthorized
- `404` - User not found

---

### 2. Update User Profile
**PUT** `/api/v1/users/profile`

Update user profile information.

**Request:**
```json
{
  "name": "John Smith",
  "phoneNumber": "+919876543210",
  "countryCode": "IN",
  "currencyPreference": "USD"
}
```

**Validations:**
- `name` - String, 1-100 characters
- `phoneNumber` - Valid phone format (8-15 chars)
- `countryCode` - ISO 3166-1 alpha-2 code
- `currencyPreference` - ISO 4217 currency code (3 chars)

**Response:** `200 OK`
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "name": "John Smith",
  "phoneNumber": "+919876543210",
  "countryCode": "IN",
  "currencyPreference": "USD",
  ...
}
```

**Errors:**
- `400` - Validation error
- `401` - Unauthorized
- `404` - User not found

---

### 3. Change Password
**PUT** `/api/v1/users/change-password`

Change user password.

**Request:**
```json
{
  "currentPassword": "OldPassword@123",
  "newPassword": "NewSecurePass@123"
}
```

**Password Requirements:**
- Minimum 12 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character (!@#$%^&*)

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

**Errors:**
- `400` - Current password incorrect or password too weak
- `400` - Validation error
- `401` - Unauthorized
- `404` - User not found

---

### 4. Upload Profile Picture
**POST** `/api/v1/users/profile-picture`

Upload a profile picture.

**Request:**
- Content-Type: `multipart/form-data`
- File field: `profilePicture`

**Accepted File Types:**
- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)

**File Size Limit:** 5 MB

**Example (cURL):**
```bash
curl -X POST http://localhost:3000/api/v1/users/profile-picture \
  -H "Authorization: Bearer <token>" \
  -F "profilePicture=@/path/to/image.jpg"
```

**Response:** `200 OK`
```json
{
  "success": true,
  "profilePictureUrl": "/uploads/profile-pictures/abc-123-def-456",
  "message": "Profile picture uploaded successfully"
}
```

**Errors:**
- `400` - No file provided or invalid file type
- `401` - Unauthorized
- `413` - File too large

---

## Account Management Endpoints

### 5. Delete Account
**DELETE** `/api/v1/users/delete-account`

Permanently delete user account and all associated data.

**Request:**
```json
{
  "password": "CurrentPassword@123"
}
```

**Warning:** This action is irreversible and will delete:
- User profile
- All accounts
- All transactions
- All preferences

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Account deleted successfully"
}
```

**Errors:**
- `400` - Password incorrect or missing
- `401` - Unauthorized
- `404` - User not found

---

## User Preferences Endpoints

### 6. Get User Preferences
**GET** `/api/v1/users/preferences`

Retrieve user preferences and settings.

**Response:** `200 OK`
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "currency": "INR",
  "timezone": "Asia/Kolkata",
  "language": "en",
  "theme": "system",
  "notifications": {
    "email": true,
    "push": true,
    "sms": false
  },
  "privacy": {
    "profile_visibility": "private",
    "data_sharing": false
  }
}
```

**Errors:**
- `401` - Unauthorized
- `404` - User not found

---

### 7. Update User Preferences
**PUT** `/api/v1/users/preferences`

Update user preferences and settings.

**Request:**
```json
{
  "currency": "USD",
  "timezone": "America/New_York",
  "language": "en",
  "theme": "dark",
  "notifications": {
    "email": true,
    "push": false,
    "sms": false
  },
  "privacy": {
    "profile_visibility": "public",
    "data_sharing": true
  }
}
```

**Validations:**
- `currency` - ISO 4217 currency code (3 chars)
- `timezone` - Valid IANA timezone string
- `language` - ISO 639-1 language code (2-5 chars)
- `theme` - One of: `light`, `dark`, `system`

**Response:** `200 OK`
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "currency": "USD",
  "timezone": "America/New_York",
  "language": "en",
  "theme": "dark",
  "notifications": {
    "email": true,
    "push": false,
    "sms": false
  },
  "privacy": {
    "profile_visibility": "public",
    "data_sharing": true
  }
}
```

**Errors:**
- `400` - Validation error
- `401` - Unauthorized
- `404` - User not found

---

## Error Response Format

```json
{
  "error": "Error message",
  "errors": [
    {
      "location": "body",
      "param": "fieldName",
      "msg": "Field validation error"
    }
  ]
}
```

## Example Requests

### Update Profile
```bash
curl -X PUT http://localhost:3000/api/v1/users/profile \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Smith",
    "currencyPreference": "USD"
  }'
```

### Change Password
```bash
curl -X PUT http://localhost:3000/api/v1/users/change-password \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "currentPassword": "OldPassword@123",
    "newPassword": "NewSecurePass@123"
  }'
```

### Get Preferences
```bash
curl -X GET http://localhost:3000/api/v1/users/preferences \
  -H "Authorization: Bearer <token>"
```

### Update Preferences
```bash
curl -X PUT http://localhost:3000/api/v1/users/preferences \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "theme": "dark",
    "language": "en"
  }'
```

### Delete Account
```bash
curl -X DELETE http://localhost:3000/api/v1/users/delete-account \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "CurrentPassword@123"
  }'
```
