const db = require('../config/database');

class Settings {
  static async findByUserId(userId) {
    return await db('user_settings')
      .where({ user_id: userId })
      .first();
  }

  static async create(userId) {
    const [settingId] = await db('user_settings').insert({
      user_id: userId,
      theme: 'light',
      language: 'en',
      currency: 'USD',
      date_format: 'MM/DD/YYYY',
      timezone: 'UTC',
      notifications_enabled: true,
      two_factor_enabled: false,
      auto_logout_minutes: 30,
      data_retention_days: 365,
      privacy_level: 'private',
      allow_analytics: true,
      created_at: new Date(),
      updated_at: new Date()
    });

    return this.findByUserId(userId);
  }

  static async update(userId, data) {
    const {
      theme,
      language,
      currency,
      date_format,
      timezone,
      notifications_enabled,
      auto_logout_minutes,
      data_retention_days,
      privacy_level,
      allow_analytics
    } = data;

    const updateData = { updated_at: new Date() };

    if (theme !== undefined) updateData.theme = theme;
    if (language !== undefined) updateData.language = language;
    if (currency !== undefined) updateData.currency = currency;
    if (date_format !== undefined) updateData.date_format = date_format;
    if (timezone !== undefined) updateData.timezone = timezone;
    if (notifications_enabled !== undefined) updateData.notifications_enabled = notifications_enabled;
    if (auto_logout_minutes !== undefined) updateData.auto_logout_minutes = auto_logout_minutes;
    if (data_retention_days !== undefined) updateData.data_retention_days = data_retention_days;
    if (privacy_level !== undefined) updateData.privacy_level = privacy_level;
    if (allow_analytics !== undefined) updateData.allow_analytics = allow_analytics;

    await db('user_settings')
      .where({ user_id: userId })
      .update(updateData);

    return this.findByUserId(userId);
  }
}

class SecuritySettings {
  static async findByUserId(userId) {
    return await db('security_settings')
      .where({ user_id: userId })
      .first();
  }

  static async create(userId) {
    const [settingId] = await db('security_settings').insert({
      user_id: userId,
      two_factor_enabled: false,
      two_factor_method: 'email',
      biometric_enabled: false,
      login_alerts_enabled: true,
      password_changed_at: new Date(),
      last_login_at: new Date(),
      session_timeout_minutes: 30,
      allow_remember_device: true,
      ip_whitelist_enabled: false,
      active_sessions: 1,
      created_at: new Date(),
      updated_at: new Date()
    });

    return this.findByUserId(userId);
  }

  static async update(userId, data) {
    const {
      two_factor_enabled,
      two_factor_method,
      biometric_enabled,
      login_alerts_enabled,
      session_timeout_minutes,
      allow_remember_device,
      ip_whitelist_enabled
    } = data;

    const updateData = { updated_at: new Date() };

    if (two_factor_enabled !== undefined) updateData.two_factor_enabled = two_factor_enabled;
    if (two_factor_method !== undefined) updateData.two_factor_method = two_factor_method;
    if (biometric_enabled !== undefined) updateData.biometric_enabled = biometric_enabled;
    if (login_alerts_enabled !== undefined) updateData.login_alerts_enabled = login_alerts_enabled;
    if (session_timeout_minutes !== undefined) updateData.session_timeout_minutes = session_timeout_minutes;
    if (allow_remember_device !== undefined) updateData.allow_remember_device = allow_remember_device;
    if (ip_whitelist_enabled !== undefined) updateData.ip_whitelist_enabled = ip_whitelist_enabled;

    await db('security_settings')
      .where({ user_id: userId })
      .update(updateData);

    return this.findByUserId(userId);
  }

  static async updateLastLogin(userId) {
    await db('security_settings')
      .where({ user_id: userId })
      .update({
        last_login_at: new Date(),
        updated_at: new Date()
      });
  }
}

class DataExport {
  static async create(userId, data) {
    const { export_type, status, file_path } = data;

    const [exportId] = await db('data_exports').insert({
      user_id: userId,
      export_type,
      status: status || 'pending',
      file_path: file_path || null,
      requested_at: new Date(),
      completed_at: null,
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      created_at: new Date(),
      updated_at: new Date()
    });

    return this.findById(exportId);
  }

  static async findById(id) {
    return await db('data_exports')
      .where({ export_id: id })
      .first();
  }

  static async findByUserId(userId) {
    return await db('data_exports')
      .where({ user_id: userId })
      .orderBy('requested_at', 'desc');
  }

  static async updateStatus(id, status, filePath = null) {
    const updateData = {
      status,
      updated_at: new Date()
    };

    if (status === 'completed') {
      updateData.completed_at = new Date();
      updateData.file_path = filePath;
    }

    await db('data_exports')
      .where({ export_id: id })
      .update(updateData);

    return this.findById(id);
  }

  static async list(userId, limit = 10, offset = 0) {
    const exports = await db('data_exports')
      .where({ user_id: userId })
      .orderBy('requested_at', 'desc')
      .limit(limit)
      .offset(offset);

    const totalResult = await db('data_exports')
      .where({ user_id: userId })
      .count('* as total')
      .first();

    return {
      total: totalResult.total,
      limit,
      offset,
      exports
    };
  }
}

class DataAccessRequest {
  static async create(userId, data) {
    const { request_type, reason, status } = data;

    const [requestId] = await db('data_access_requests').insert({
      user_id: userId,
      request_type,
      reason,
      status: status || 'pending',
      requested_at: new Date(),
      approved_at: null,
      created_at: new Date(),
      updated_at: new Date()
    });

    return this.findById(requestId);
  }

  static async findById(id) {
    return await db('data_access_requests')
      .where({ request_id: id })
      .first();
  }

  static async findByUserId(userId) {
    return await db('data_access_requests')
      .where({ user_id: userId })
      .orderBy('requested_at', 'desc');
  }

  static async updateStatus(id, status, approvedAt = null) {
    const updateData = {
      status,
      updated_at: new Date()
    };

    if (status === 'approved' && approvedAt) {
      updateData.approved_at = approvedAt;
    }

    await db('data_access_requests')
      .where({ request_id: id })
      .update(updateData);

    return this.findById(id);
  }

  static async list(userId, limit = 10, offset = 0) {
    const requests = await db('data_access_requests')
      .where({ user_id: userId })
      .orderBy('requested_at', 'desc')
      .limit(limit)
      .offset(offset);

    const totalResult = await db('data_access_requests')
      .where({ user_id: userId })
      .count('* as total')
      .first();

    return {
      total: totalResult.total,
      limit,
      offset,
      requests
    };
  }

  static async hasRecentRequest(userId, requestType) {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const request = await db('data_access_requests')
      .where({ user_id: userId, request_type: requestType })
      .andWhere('created_at', '>', thirtyDaysAgo)
      .first();

    return !!request;
  }
}

module.exports = { Settings, SecuritySettings, DataExport, DataAccessRequest };
