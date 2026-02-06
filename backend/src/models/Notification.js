const db = require('../config/database');

class Notification {
  static async create(userId, data) {
    const {
      type,
      title,
      message,
      related_entity_type,
      related_entity_id,
      action_url
    } = data;

    const [notificationId] = await db('notifications').insert({
      user_id: userId,
      type,
      title,
      message,
      related_entity_type,
      related_entity_id,
      action_url,
      is_read: false,
      read_at: null,
      is_deleted: false,
      created_at: new Date(),
      updated_at: new Date()
    });

    return this.findById(notificationId);
  }

  static async findById(id) {
    return await db('notifications')
      .where({ notification_id: id, is_deleted: false })
      .first();
  }

  static async findByUserAndId(userId, id) {
    return await db('notifications')
      .where({ user_id: userId, notification_id: id, is_deleted: false })
      .first();
  }

  static async list(userId, filters = {}) {
    const { type, is_read, limit = 50, offset = 0 } = filters;

    let query = db('notifications').where({ user_id: userId, is_deleted: false });

    if (type) {
      query = query.where({ type });
    }

    if (is_read !== undefined) {
      query = query.where({ is_read });
    }

    const notifications = await query
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);

    const totalResult = await db('notifications')
      .where({ user_id: userId, is_deleted: false })
      .count('* as total')
      .first();

    const unreadCount = await db('notifications')
      .where({ user_id: userId, is_deleted: false, is_read: false })
      .count('* as total')
      .first();

    return {
      total: totalResult.total,
      unread_count: unreadCount.total,
      limit,
      offset,
      notifications
    };
  }

  static async markAsRead(id) {
    await db('notifications')
      .where({ notification_id: id })
      .update({
        is_read: true,
        read_at: new Date(),
        updated_at: new Date()
      });

    return this.findById(id);
  }

  static async markAllAsRead(userId) {
    const count = await db('notifications')
      .where({ user_id: userId, is_deleted: false, is_read: false })
      .count('* as total')
      .first();

    await db('notifications')
      .where({ user_id: userId, is_deleted: false, is_read: false })
      .update({
        is_read: true,
        read_at: new Date(),
        updated_at: new Date()
      });

    return count.total;
  }

  static async softDelete(id) {
    await db('notifications')
      .where({ notification_id: id })
      .update({
        is_deleted: true,
        updated_at: new Date()
      });
  }

  static async getUnreadCount(userId) {
    const result = await db('notifications')
      .where({ user_id: userId, is_deleted: false, is_read: false })
      .count('* as total')
      .first();

    return result.total;
  }

  static async getStats(userId) {
    const byType = await db('notifications')
      .where({ user_id: userId, is_deleted: false })
      .groupBy('type')
      .select('type', db.raw('count(*) as count'));

    const totalUnread = await this.getUnreadCount(userId);
    const total = await db('notifications')
      .where({ user_id: userId, is_deleted: false })
      .count('* as total')
      .first();

    return {
      total: total.total,
      unread: totalUnread,
      by_type: byType
    };
  }
}

class NotificationPreference {
  static async findByUserId(userId) {
    return await db('notification_preferences')
      .where({ user_id: userId })
      .first();
  }

  static async create(userId) {
    const [preferenceId] = await db('notification_preferences').insert({
      user_id: userId,
      email_on_expense: true,
      email_on_income: true,
      email_on_budget_alert: true,
      email_on_goal_reached: true,
      email_on_investment_update: true,
      email_on_bank_sync: true,
      push_on_expense: true,
      push_on_income: true,
      push_on_budget_alert: true,
      push_on_goal_reached: true,
      push_on_investment_update: true,
      push_on_bank_sync: true,
      in_app_notifications: true,
      daily_digest: false,
      weekly_report: false,
      monthly_report: true,
      quiet_hours_enabled: false,
      quiet_hours_start: '22:00',
      quiet_hours_end: '08:00',
      created_at: new Date(),
      updated_at: new Date()
    });

    return this.findByUserId(userId);
  }

  static async update(userId, data) {
    const {
      email_on_expense,
      email_on_income,
      email_on_budget_alert,
      email_on_goal_reached,
      email_on_investment_update,
      email_on_bank_sync,
      push_on_expense,
      push_on_income,
      push_on_budget_alert,
      push_on_goal_reached,
      push_on_investment_update,
      push_on_bank_sync,
      in_app_notifications,
      daily_digest,
      weekly_report,
      monthly_report,
      quiet_hours_enabled,
      quiet_hours_start,
      quiet_hours_end
    } = data;

    const updateData = { updated_at: new Date() };

    if (email_on_expense !== undefined) updateData.email_on_expense = email_on_expense;
    if (email_on_income !== undefined) updateData.email_on_income = email_on_income;
    if (email_on_budget_alert !== undefined) updateData.email_on_budget_alert = email_on_budget_alert;
    if (email_on_goal_reached !== undefined) updateData.email_on_goal_reached = email_on_goal_reached;
    if (email_on_investment_update !== undefined) updateData.email_on_investment_update = email_on_investment_update;
    if (email_on_bank_sync !== undefined) updateData.email_on_bank_sync = email_on_bank_sync;
    if (push_on_expense !== undefined) updateData.push_on_expense = push_on_expense;
    if (push_on_income !== undefined) updateData.push_on_income = push_on_income;
    if (push_on_budget_alert !== undefined) updateData.push_on_budget_alert = push_on_budget_alert;
    if (push_on_goal_reached !== undefined) updateData.push_on_goal_reached = push_on_goal_reached;
    if (push_on_investment_update !== undefined) updateData.push_on_investment_update = push_on_investment_update;
    if (push_on_bank_sync !== undefined) updateData.push_on_bank_sync = push_on_bank_sync;
    if (in_app_notifications !== undefined) updateData.in_app_notifications = in_app_notifications;
    if (daily_digest !== undefined) updateData.daily_digest = daily_digest;
    if (weekly_report !== undefined) updateData.weekly_report = weekly_report;
    if (monthly_report !== undefined) updateData.monthly_report = monthly_report;
    if (quiet_hours_enabled !== undefined) updateData.quiet_hours_enabled = quiet_hours_enabled;
    if (quiet_hours_start !== undefined) updateData.quiet_hours_start = quiet_hours_start;
    if (quiet_hours_end !== undefined) updateData.quiet_hours_end = quiet_hours_end;

    await db('notification_preferences')
      .where({ user_id: userId })
      .update(updateData);

    return this.findByUserId(userId);
  }
}

module.exports = { Notification, NotificationPreference };
