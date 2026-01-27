const User = require('../models/User');
const jwt = require('jsonwebtoken');
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const { v4: uuidv4 } = require('uuid');
const pwned = require('havebeenpwned');

class AuthService {
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
    const passwordScore = this.calculatePasswordEntropy(password);
    if (passwordScore < 50) {
      throw new Error('Password is too weak');
    }

    // Check if password has been pwned
    const isPwned = await pwned.check(password);
    if (isPwned) {
      throw new Error('This password has been breached. Please use a different password.');
    }

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

      return this.generateAccessToken(decoded.userId, decoded.deviceId);
    } catch (error) {
      throw new Error('Invalid refresh token');
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
      name: user.name,
      currency: user.currency_preference,
      timezone: user.timezone,
      theme: user.theme_preference,
      language: user.language_preference
    };
  }
}

module.exports = AuthService;
