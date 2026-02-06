const User = require('../models/User');
const db = require('../config/database');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

class UserService {
  static async getProfile(userId) {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    return this.formatUserProfile(user);
  }

  static async updateProfile(userId, profileData) {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    const updates = {
      name: profileData.name || user.name,
      phone_number: profileData.phone_number || user.phone_number,
      country_code: profileData.country_code || user.country_code,
      currency_preference: profileData.currency_preference || user.currency_preference,
      updated_at: new Date()
    };

    const result = await db('users')
      .where({ user_id: userId })
      .update(updates)
      .returning('*');

    return this.formatUserProfile(result[0]);
  }

  static async changePassword(userId, oldPassword, newPassword) {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Verify old password
    const isValidPassword = await User.verifyPassword(oldPassword, user.password_hash);
    if (!isValidPassword) {
      throw new Error('Current password is incorrect');
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await db('users')
      .where({ user_id: userId })
      .update({
        password_hash: hashedPassword,
        updated_at: new Date()
      });

    return { success: true, message: 'Password changed successfully' };
  }

  static async uploadProfilePicture(userId, fileBuffer, fileName) {
    // In production, upload to S3/GCS
    // For now, store metadata in DB
    const profilePictureId = uuidv4();
    const fileUrl = `/uploads/profile-pictures/${profilePictureId}`;

    await db('users')
      .where({ user_id: userId })
      .update({
        profile_picture_url: fileUrl,
        updated_at: new Date()
      });

    return {
      success: true,
      profilePictureUrl: fileUrl,
      message: 'Profile picture uploaded successfully'
    };
  }

  static async deleteAccount(userId, password) {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Verify password before deletion
    const isValidPassword = await User.verifyPassword(password, user.password_hash);
    if (!isValidPassword) {
      throw new Error('Password is incorrect');
    }

    // Mark account as deleted instead of hard delete
    await db('users')
      .where({ user_id: userId })
      .update({
        account_status: 'deleted',
        deleted_at: new Date(),
        updated_at: new Date()
      });

    // Soft delete all related data
    await db('accounts')
      .where({ user_id: userId })
      .update({ deleted_at: new Date() });

    await db('transactions')
      .where({ user_id: userId })
      .update({ deleted_at: new Date() });

    return { success: true, message: 'Account deleted successfully' };
  }

  static async getPreferences(userId) {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Get preferences (could be from separate table in production)
    return {
      userId,
      currency: user.currency_preference || 'INR',
      timezone: user.timezone || 'Asia/Kolkata',
      language: user.language || 'en',
      theme: user.theme || 'system',
      notifications: {
        email: true,
        push: true,
        sms: false
      },
      privacy: {
        profile_visibility: 'private',
        data_sharing: false
      }
    };
  }

  static async updatePreferences(userId, preferences) {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    const updates = {
      currency_preference: preferences.currency || user.currency_preference,
      timezone: preferences.timezone || user.timezone,
      language: preferences.language || user.language,
      theme: preferences.theme || user.theme,
      updated_at: new Date()
    };

    const result = await db('users')
      .where({ user_id: userId })
      .update(updates)
      .returning('*');

    return {
      userId,
      currency: result[0].currency_preference,
      timezone: result[0].timezone,
      language: result[0].language,
      theme: result[0].theme,
      notifications: preferences.notifications || {},
      privacy: preferences.privacy || {}
    };
  }

  static formatUserProfile(user) {
    return {
      userId: user.user_id,
      email: user.email,
      name: user.name,
      phoneNumber: user.phone_number,
      phoneVerified: user.phone_verified,
      countryCode: user.country_code,
      currencyPreference: user.currency_preference,
      profilePictureUrl: user.profile_picture_url || null,
      createdAt: user.created_at,
      updatedAt: user.updated_at
    };
  }
}

module.exports = UserService;
