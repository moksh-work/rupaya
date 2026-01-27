const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class Account {
  static async create(userId, data) {
    const record = {
      account_id: uuidv4(),
      user_id: userId,
      name: data.name,
      account_type: data.account_type,
      currency: data.currency || 'INR',
      current_balance: data.current_balance ?? 0,
      is_default: data.is_default ?? false,
      icon: data.icon || null,
      color: data.color || null,
      created_at: new Date(),
      updated_at: new Date()
    };

    const [account] = await db('accounts').insert(record).returning('*');
    return account;
  }

  static async findById(accountId) {
    return db('accounts').where({ account_id: accountId }).first();
  }

  static async listByUser(userId) {
    return db('accounts')
      .where({ user_id: userId })
      .orderBy('created_at', 'desc');
  }

  static async update(accountId, userId, data) {
    const updates = {
      name: data.name,
      account_type: data.account_type,
      currency: data.currency,
      current_balance: data.current_balance,
      is_default: data.is_default,
      icon: data.icon,
      color: data.color,
      updated_at: new Date()
    };

    const [account] = await db('accounts')
      .where({ account_id: accountId, user_id: userId })
      .update(updates)
      .returning('*');

    return account;
  }

  static async remove(accountId, userId) {
    return db('accounts')
      .where({ account_id: accountId, user_id: userId })
      .del();
  }
}

module.exports = Account;
