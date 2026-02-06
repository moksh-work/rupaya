const { Settings, SecuritySettings, DataExport, DataAccessRequest } = require('../models/Settings');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

class SettingsService {
  static async getSettings(userId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    let settings = await Settings.findByUserId(userId);

    if (!settings) {
      settings = await Settings.create(userId);
    }

    return settings;
  }

  static async updateSettings(userId, data) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const { theme, language, currency, date_format, timezone, notifications_enabled, auto_logout_minutes, data_retention_days, privacy_level, allow_analytics } = data;

    // Validation
    const validThemes = ['light', 'dark'];
    const validLanguages = ['en', 'es', 'fr', 'de', 'pt', 'ja', 'zh'];
    const validCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'INR'];
    const validDateFormats = ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'];
    const validPrivacyLevels = ['private', 'friends', 'public'];

    if (theme && !validThemes.includes(theme)) {
      throw new Error(`Theme must be one of: ${validThemes.join(', ')}`);
    }

    if (language && !validLanguages.includes(language)) {
      throw new Error(`Language must be one of: ${validLanguages.join(', ')}`);
    }

    if (currency && !validCurrencies.includes(currency)) {
      throw new Error(`Currency must be one of: ${validCurrencies.join(', ')}`);
    }

    if (date_format && !validDateFormats.includes(date_format)) {
      throw new Error(`Date format must be one of: ${validDateFormats.join(', ')}`);
    }

    if (auto_logout_minutes && (auto_logout_minutes < 5 || auto_logout_minutes > 1440)) {
      throw new Error('Auto logout minutes must be between 5 and 1440');
    }

    if (data_retention_days && (data_retention_days < 30 || data_retention_days > 2555)) {
      throw new Error('Data retention days must be between 30 and 2555 (7 years)');
    }

    if (privacy_level && !validPrivacyLevels.includes(privacy_level)) {
      throw new Error(`Privacy level must be one of: ${validPrivacyLevels.join(', ')}`);
    }

    let settings = await Settings.findByUserId(userId);

    if (!settings) {
      settings = await Settings.create(userId);
    }

    return await Settings.update(userId, data);
  }

  static async getSecuritySettings(userId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    let securitySettings = await SecuritySettings.findByUserId(userId);

    if (!securitySettings) {
      securitySettings = await SecuritySettings.create(userId);
    }

    // Remove sensitive data
    const { password_changed_at, ...safeSettings } = securitySettings;

    return safeSettings;
  }

  static async updateSecuritySettings(userId, data) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const { two_factor_enabled, two_factor_method, biometric_enabled, session_timeout_minutes } = data;

    // Validation
    const validTwoFactorMethods = ['email', 'sms', 'authenticator'];

    if (two_factor_method && !validTwoFactorMethods.includes(two_factor_method)) {
      throw new Error(`Two-factor method must be one of: ${validTwoFactorMethods.join(', ')}`);
    }

    if (session_timeout_minutes && (session_timeout_minutes < 5 || session_timeout_minutes > 480)) {
      throw new Error('Session timeout must be between 5 and 480 minutes');
    }

    let securitySettings = await SecuritySettings.findByUserId(userId);

    if (!securitySettings) {
      securitySettings = await SecuritySettings.create(userId);
    }

    return await SecuritySettings.update(userId, data);
  }

  static async exportData(userId, exportType) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const validExportTypes = ['full', 'expenses', 'income', 'budgets', 'transactions'];

    if (!validExportTypes.includes(exportType)) {
      throw new Error(`Export type must be one of: ${validExportTypes.join(', ')}`);
    }

    // Check for recent export requests
    const hasRecentExport = await DataExport.findByUserId(userId);
    const recentExport = hasRecentExport.find(
      e => e.status === 'pending' && new Date() - new Date(e.requested_at) < 24 * 60 * 60 * 1000
    );

    if (recentExport) {
      throw new Error('You already have a pending export. Please wait or check your existing request.');
    }

    // Create export record
    const exportRecord = await DataExport.create(userId, {
      export_type: exportType,
      status: 'pending'
    });

    // In production, trigger async job to generate export
    // For now, return the pending export record

    return {
      export_id: exportRecord.export_id,
      status: exportRecord.status,
      requested_at: exportRecord.requested_at,
      expires_at: exportRecord.expires_at,
      message: 'Your data export has been requested. You will receive an email when it is ready.'
    };
  }

  static async getExportHistory(userId, limit = 10, offset = 0) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    return await DataExport.list(userId, limit, offset);
  }

  static async requestDataAccess(userId, reason) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    if (!reason || reason.trim().length < 10) {
      throw new Error('Reason must be at least 10 characters');
    }

    // Check for recent requests
    const hasRecentRequest = await DataAccessRequest.hasRecentRequest(userId, 'data_access');

    if (hasRecentRequest) {
      throw new Error('You already have a pending data access request. Only one request is allowed per 30 days.');
    }

    // Create access request
    const accessRequest = await DataAccessRequest.create(userId, {
      request_type: 'data_access',
      reason: reason,
      status: 'pending'
    });

    return {
      request_id: accessRequest.request_id,
      status: accessRequest.status,
      requested_at: accessRequest.requested_at,
      message: 'Your data access request has been submitted. Our support team will review it within 5 business days.'
    };
  }

  static async getAccessRequests(userId, limit = 10, offset = 0) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    return await DataAccessRequest.list(userId, limit, offset);
  }
}

module.exports = SettingsService;
