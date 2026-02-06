const { Notification, NotificationPreference } = require('../models/Notification');

class NotificationService {
  static async getNotifications(userId, filters) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const limit = Math.min(parseInt(filters.limit) || 50, 100);
    const offset = parseInt(filters.offset) || 0;
    const is_read = filters.is_read !== undefined ? filters.is_read === 'true' : undefined;

    return await Notification.list(userId, {
      type: filters.type,
      is_read,
      limit,
      offset
    });
  }

  static async markAsRead(userId, notificationId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const notification = await Notification.findByUserAndId(userId, notificationId);

    if (!notification) {
      throw new Error('Notification not found');
    }

    return await Notification.markAsRead(notificationId);
  }

  static async markAllAsRead(userId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const count = await Notification.markAllAsRead(userId);

    return {
      success: true,
      notifications_marked_read: count
    };
  }

  static async deleteNotification(userId, notificationId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const notification = await Notification.findByUserAndId(userId, notificationId);

    if (!notification) {
      throw new Error('Notification not found');
    }

    await Notification.softDelete(notificationId);

    return { success: true, message: 'Notification deleted successfully' };
  }

  static async getPreferences(userId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    let preferences = await NotificationPreference.findByUserId(userId);

    if (!preferences) {
      preferences = await NotificationPreference.create(userId);
    }

    return preferences;
  }

  static async updatePreferences(userId, data) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    // Validate boolean fields
    const booleanFields = [
      'email_on_expense',
      'email_on_income',
      'email_on_budget_alert',
      'email_on_goal_reached',
      'email_on_investment_update',
      'email_on_bank_sync',
      'push_on_expense',
      'push_on_income',
      'push_on_budget_alert',
      'push_on_goal_reached',
      'push_on_investment_update',
      'push_on_bank_sync',
      'in_app_notifications',
      'daily_digest',
      'weekly_report',
      'monthly_report',
      'quiet_hours_enabled'
    ];

    for (const field of booleanFields) {
      if (data[field] !== undefined && typeof data[field] !== 'boolean') {
        throw new Error(`${field} must be a boolean`);
      }
    }

    // Validate time fields if quiet hours are enabled
    if (data.quiet_hours_enabled || data.quiet_hours_start || data.quiet_hours_end) {
      const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;

      if (data.quiet_hours_start && !timeRegex.test(data.quiet_hours_start)) {
        throw new Error('Quiet hours start must be in HH:MM format');
      }

      if (data.quiet_hours_end && !timeRegex.test(data.quiet_hours_end)) {
        throw new Error('Quiet hours end must be in HH:MM format');
      }
    }

    let preferences = await NotificationPreference.findByUserId(userId);

    if (!preferences) {
      preferences = await NotificationPreference.create(userId);
    }

    return await NotificationPreference.update(userId, data);
  }

  static async getStats(userId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    return await Notification.getStats(userId);
  }
}

module.exports = NotificationService;
