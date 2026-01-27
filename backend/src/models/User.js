const db = require('../config/database');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

class User {
  static async create(userData) {
    const hashedPassword = userData.password 
      ? await bcrypt.hash(userData.password, 10)
      : null;

    const userRecord = {
      user_id: uuidv4(),
      email: userData.email,
      password_hash: hashedPassword,
      name: userData.name,
      country_code: userData.country_code || 'IN',
      currency_preference: userData.currency_preference || 'INR',
      oauth_provider: userData.oauth_provider || null,
      oauth_provider_id: userData.oauth_provider_id || null,
      account_status: 'active',
      created_at: new Date(),
      updated_at: new Date()
    };

    const result = await db('users').insert(userRecord).returning('*');
    return result[0];
  }

  static async findByEmail(email) {
    return await db('users').where({ email }).first();
  }

  static async findById(userId) {
    return await db('users').where({ user_id: userId }).first();
  }

  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  static async updateLastLogin(userId, deviceId) {
    return await db('users')
      .where({ user_id: userId })
      .update({
        last_login_at: new Date(),
        last_login_device_id: deviceId,
        login_attempt_count: 0,
        updated_at: new Date()
      });
  }

  static async incrementLoginAttempt(userId) {
    return await db('users')
      .where({ user_id: userId })
      .update({
        login_attempt_count: db.raw('login_attempt_count + 1'),
        login_attempt_last_at: new Date(),
        updated_at: new Date()
      });
  }

  static async checkIfLockedOut(userId) {
    const user = await this.findById(userId);
    if (!user) return false;

    const loginAttemptLastAt = new Date(user.login_attempt_last_at);
    const timeSinceLastAttempt = (new Date() - loginAttemptLastAt) / 1000 / 60; // minutes

    // Lock escalation logic
    if (user.login_attempt_count >= 10 && timeSinceLastAttempt < 1440) { // 24 hours
      return true;
    }
    if (user.login_attempt_count >= 6 && timeSinceLastAttempt < 60) { // 1 hour
      return true;
    }
    if (user.login_attempt_count >= 5 && timeSinceLastAttempt < 15) { // 15 minutes
      return true;
    }

    return false;
  }

  static async resetLoginAttempts(userId) {
    return await db('users')
      .where({ user_id: userId })
      .update({
        login_attempt_count: 0,
        updated_at: new Date()
      });
  }

  static async setMFASecret(userId, secret) {
    const encrypted = crypto
      .createCipher('aes-256-gcm', process.env.ENCRYPTION_KEY)
      .update(secret, 'utf8', 'hex');

    return await db('users')
      .where({ user_id: userId })
      .update({
        mfa_secret: encrypted,
        mfa_enabled: true,
        updated_at: new Date()
      });
  }

  static async getMFASecret(userId) {
    const user = await this.findById(userId);
    if (!user || !user.mfa_secret) return null;

    const decrypted = crypto
      .createDecipher('aes-256-gcm', process.env.ENCRYPTION_KEY)
      .update(user.mfa_secret, 'hex', 'utf8');

    return decrypted;
  }
}

module.exports = User;
