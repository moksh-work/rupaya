const User = require('../models/User');
const jwt = require('jsonwebtoken');
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const { v4: uuidv4 } = require('uuid');
// const { pwnedPassword } = require('hibp'); // Disabled due to ESM compatibility issue
const db = require('../config/database');
const bcrypt = require('bcryptjs');

class AuthService {
  static generateJWT(payload) {
    return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '24h' });
  }

  static verifyJWT(token) {
    return jwt.verify(token, process.env.JWT_SECRET);
  }

  static async hashPassword(password) {
    return bcrypt.hash(password, 10);
  }

  static async comparePasswords(password, hashedPassword) {
    return bcrypt.compare(password, hashedPassword);
  }

  static validatePasswordStrength(password) {
    const hasMinLength = password.length >= 8;
    const hasUppercase = /[A-Z]/.test(password);
    const hasNumber = /[0-9]/.test(password);
    const hasSpecial = /[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]/.test(password);

    return hasMinLength && hasUppercase && hasNumber && hasSpecial;
  }

  static generateAccessToken(userId, deviceId) {
    return jwt.sign(
      {
        userId,
        deviceId,
        type: 'access'
      },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );
  }

  static generateRefreshToken(userId, deviceId) {
    return jwt.sign(
      {
        userId,
        deviceId,
        type: 'refresh',
        tokenId: uuidv4()
      },
      process.env.REFRESH_TOKEN_SECRET,
      { expiresIn: '7d' }
    );
  }

  static async signup(email, password, deviceId, deviceName) {
    // Validate password strength
    if (process.env.DISABLE_PASSWORD_STRENGTH !== 'true' && process.env.NODE_ENV !== 'test') {
      const passwordScore = this.calculatePasswordEntropy(password);
      if (passwordScore < 50) {
        throw new Error('Password is too weak');
      }
    }

    // Password breach checking disabled (hibp ESM compatibility issue)
    // TODO: Re-enable with ESM-compatible solution
    // if (process.env.DISABLE_PWNED_CHECK !== 'true' && process.env.NODE_ENV !== 'test') {
    //   try {
    //     const pwnedCount = await pwnedPassword(password);
    //     if (pwnedCount > 0) {
    //       throw new Error('This password has been breached. Please use a different password.');
    //     }
    //   } catch (err) {
    //     console.warn('Could not check password breach status:', err.message);
    //   }
    // }

    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      throw new Error('User already exists');
    }

    // Create user
    const user = await User.create({
      email,
      password,
      name: email.split('@')[0]
    });

    // Generate tokens
    const accessToken = this.generateAccessToken(user.user_id, deviceId);
    const refreshToken = this.generateRefreshToken(user.user_id, deviceId);

    // Store device
    await this.storeDevice(user.user_id, deviceId, deviceName, 'email');

    return {
      userId: user.user_id,
      accessToken,
      refreshToken,
      user: this.formatUserResponse(user)
    };
  }

  static async signin(email, password, deviceId) {
    // Find user
    const user = await User.findByEmail(email);
    if (!user) {
      throw new Error('Invalid email or password');
    }

    // Check if account is locked
    const isLockedOut = await User.checkIfLockedOut(user.user_id);
    if (isLockedOut) {
      throw new Error('Account temporarily locked. Try again later.');
    }

    // Verify password
    const isPasswordValid = await User.verifyPassword(password, user.password_hash);
    if (!isPasswordValid) {
      await User.incrementLoginAttempt(user.user_id);
      throw new Error('Invalid email or password');
    }

    // Update login
    await User.updateLastLogin(user.user_id, deviceId);

    // Generate tokens
    const accessToken = this.generateAccessToken(user.user_id, deviceId);
    const refreshToken = this.generateRefreshToken(user.user_id, deviceId);

    return {
      userId: user.user_id,
      accessToken,
      refreshToken,
      user: this.formatUserResponse(user),
      mfaRequired: user.mfa_enabled
    };
  }

  static async requestPhoneOtp(phoneNumber, purpose = 'signup') {
    const normalized = phoneNumber.replace(/\D/g, '');
    if (normalized.length < 8 || normalized.length > 15) {
      throw new Error('Invalid phone number');
    }

    const existingUser = await User.findByPhone(normalized);
    if (purpose === 'signup' && existingUser) {
      throw new Error('Phone already registered');
    }
    if (purpose === 'signin' && !existingUser) {
      throw new Error('Account not found');
    }

    // Generate 6-digit OTP
    const otp = (Math.floor(100000 + Math.random() * 900000)).toString();
    const codeHash = await bcrypt.hash(otp, 10);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Clear previous OTPs for this phone/purpose
    await db('phone_otps').where({ phone_number: normalized, purpose }).del();
    await db('phone_otps').insert({
      phone_number: normalized,
      code_hash: codeHash,
      purpose,
      expires_at: expiresAt
    });

    return {
      message: 'OTP sent',
      // In a real system, send via SMS. For development, return code for testing.
      otp
    };
  }

  static async signupWithPhone(email, phoneNumber, otp, deviceId, deviceName, name) {
    const normalized = phoneNumber.replace(/\D/g, '');
    // Verify OTP first
    await this.verifyPhoneOtp(normalized, otp, 'signup');

    // Check email/phone not already used
    const existingEmail = await User.findByEmail(email);
    if (existingEmail) {
      throw new Error('User already exists');
    }
    const existingPhone = await User.findByPhone(normalized);
    if (existingPhone) {
      throw new Error('Phone already registered');
    }

    const user = await User.create({
      email,
      phone_number: normalized,
      phone_verified: true,
      password: null,
      name: name || email.split('@')[0]
    });

    const accessToken = this.generateAccessToken(user.user_id, deviceId);
    const refreshToken = this.generateRefreshToken(user.user_id, deviceId);

    await this.storeDevice(user.user_id, deviceId, deviceName, 'phone_otp');

    return {
      userId: user.user_id,
      accessToken,
      refreshToken,
      user: this.formatUserResponse(user)
    };
  }

  static async signinWithPhone(phoneNumber, otp, deviceId) {
    const normalized = phoneNumber.replace(/\D/g, '');
    const user = await User.findByPhone(normalized);
    if (!user) {
      throw new Error('Account not found');
    }

    await this.verifyPhoneOtp(normalized, otp, 'signin');
    await User.setPhoneVerified(user.user_id);
    await User.updateLastLogin(user.user_id, deviceId);

    const accessToken = this.generateAccessToken(user.user_id, deviceId);
    const refreshToken = this.generateRefreshToken(user.user_id, deviceId);

    return {
      userId: user.user_id,
      accessToken,
      refreshToken,
      user: this.formatUserResponse(user),
      mfaRequired: user.mfa_enabled
    };
  }

  static async verifyPhoneOtp(phoneNumber, otp, purpose) {
    const record = await db('phone_otps')
      .where({ phone_number: phoneNumber.replace(/\D/g, ''), purpose })
      .andWhere('expires_at', '>', new Date())
      .orderBy('created_at', 'desc')
      .first();

    if (!record) {
      throw new Error('OTP expired or not found');
    }

    if (record.attempt_count >= 5) {
      throw new Error('Too many attempts. Request a new OTP.');
    }

    const isValid = await bcrypt.compare(otp, record.code_hash);
    if (!isValid) {
      await db('phone_otps')
        .where({ otp_id: record.otp_id })
        .update({ attempt_count: record.attempt_count + 1 });
      throw new Error('Invalid OTP');
    }

    // Cleanup after successful verification
    await db('phone_otps').where({ phone_number: phoneNumber.replace(/\D/g, ''), purpose }).del();
    return true;
  }

  static async verifyToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      throw new Error('Invalid token');
    }
  }

  static async refreshAccessToken(refreshToken) {
    try {
      const decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET);
      
      if (!decoded.userId) {
        throw new Error('Invalid refresh token format');
      }

      if (decoded.tokenId) {
        const revoked = await db('revoked_tokens')
          .where({ token_id: decoded.tokenId })
          .first();
        if (revoked) {
          throw new Error('Refresh token has been revoked');
        }
      }

      return this.generateAccessToken(decoded.userId, decoded.deviceId);
    } catch (error) {
      throw new Error('Invalid refresh token');
    }
  }

  static async revokeRefreshToken(refreshToken) {
    const decoded = jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET);

    if (!decoded.tokenId || !decoded.userId) {
      throw new Error('Invalid refresh token format');
    }

    const expiresAt = decoded.exp ? new Date(decoded.exp * 1000) : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await db('revoked_tokens')
      .insert({
        token_id: decoded.tokenId,
        user_id: decoded.userId,
        token_type: 'refresh',
        expires_at: expiresAt
      })
      .onConflict('token_id')
      .ignore();

    return true;
  }

  static async cleanupRevokedTokens() {
    try {
      // Get count of expired tokens before deletion
      const expiredTokens = await db('revoked_tokens')
        .where('expires_at', '<', new Date())
        .count('* as count')
        .first();

      const countBeforeDelete = expiredTokens?.count || 0;

      // Delete expired tokens
      const deletedCount = await db('revoked_tokens')
        .where('expires_at', '<', new Date())
        .del();

      // Verify deletion (as sanity check)
      const remainingExpired = await db('revoked_tokens')
        .where('expires_at', '<', new Date())
        .count('* as count')
        .first();

      // Get total active revoked tokens
      const activeRevoked = await db('revoked_tokens')
        .where('expires_at', '>=', new Date())
        .count('* as count')
        .first();

      return {
        deleted: deletedCount,
        expectedDeleted: countBeforeDelete,
        activeRevoked: activeRevoked?.count || 0,
        remainingExpired: remainingExpired?.count || 0
      };
    } catch (error) {
      throw new Error(`Token cleanup failed: ${error.message}`);
    }
  }

  static async setupMFA(userId) {
    const secret = speakeasy.generateSecret({
      name: `RUPAYA (${userId})`,
      issuer: 'RUPAYA',
      length: 32
    });

    const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url);

    // Generate backup codes
    const backupCodes = [];
    for (let i = 0; i < 10; i++) {
      backupCodes.push(uuidv4().replace(/-/g, '').substring(0, 8).toUpperCase());
    }

    await User.setMFASecret(userId, secret.base32);

    return {
      secret: secret.base32,
      qrCode: qrCodeUrl,
      backupCodes
    };
  }

  static async verifyMFA(userId, token) {
    const secret = await User.getMFASecret(userId);
    if (!secret) {
      throw new Error('MFA not set up');
    }

    const verified = speakeasy.totp.verify({
      secret,
      encoding: 'base32',
      token,
      window: 2
    });

    if (!verified) {
      throw new Error('Invalid MFA token');
    }

    return true;
  }

  static async storeDevice(userId, deviceId, deviceName, source) {
    const db = require('../config/database');
    
    // Check if device already exists
    const existingDevice = await db('devices')
      .where({ device_fingerprint: deviceId, user_id: userId })
      .first();
    
    if (existingDevice) {
      // Update existing device
      return await db('devices')
        .where({ device_fingerprint: deviceId, user_id: userId })
        .update({
          device_name: deviceName,
          is_active: true,
          created_at: new Date()
        });
    }
    
    // Insert new device
    return await db('devices').insert({
      device_id: uuidv4(),
      user_id: userId,
      device_name: deviceName,
      device_fingerprint: deviceId,
      device_type: source,
      is_active: true,
      created_at: new Date()
    });
  }

  static calculatePasswordEntropy(password) {
    const patterns = {
      lowercase: /[a-z]/,
      uppercase: /[A-Z]/,
      numbers: /[0-9]/,
      special: /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/
    };

    let characterSpace = 0;
    Object.values(patterns).forEach(pattern => {
      if (pattern.test(password)) characterSpace += 26;
    });

    // Add additional characters for uppercase and special chars
    if (/[A-Z]/.test(password)) characterSpace += 26;
    if (/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) characterSpace += 32;

    return Math.log2(Math.pow(characterSpace, password.length));
  }

  static formatUserResponse(user) {
    return {
      id: user.user_id,
      email: user.email,
      phoneNumber: user.phone_number || null,
      phoneVerified: user.phone_verified || false,
      name: user.name,
      currency: user.currency_preference || 'INR',
      timezone: user.timezone || 'UTC',
      theme: user.theme_preference || 'light',
      language: user.language_preference || 'en'
    };
  }
}

module.exports = AuthService;
