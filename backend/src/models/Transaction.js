const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class Transaction {
  static async create(userId, data) {
    const record = {
      transaction_id: uuidv4(),
      user_id: userId,
      account_id: data.account_id,
      to_account_id: data.to_account_id || null,
      amount: data.amount,
      currency: data.currency || 'INR',
      transaction_type: data.transaction_type,
      category_id: data.category_id || null,
      description: data.description || null,
      notes: data.notes || null,
      location: data.location || null,
      merchant: data.merchant || null,
      tags: data.tags || null,
      attachment_url: data.attachment_url || null,
      transaction_date: data.transaction_date,
      created_at: new Date(),
      updated_at: new Date(),
      is_deleted: false
    };

    const [transaction] = await db('transactions').insert(record).returning('*');
    return transaction;
  }

  static async findById(transactionId, userId) {
    return db('transactions')
      .where({ transaction_id: transactionId, user_id: userId })
      .first();
  }

  static async softDelete(transactionId, userId) {
    return db('transactions')
      .where({ transaction_id: transactionId, user_id: userId })
      .update({ is_deleted: true, updated_at: new Date() });
  }

  static async list(userId, filters = {}) {
    let query = db('transactions')
      .where({ 'transactions.user_id': userId, 'transactions.is_deleted': false })
      .leftJoin('categories', 'transactions.category_id', 'categories.category_id')
      .leftJoin('accounts', 'transactions.account_id', 'accounts.account_id')
      .select(
        'transactions.*',
        'categories.name as category_name',
        'categories.category_type',
        'accounts.name as account_name'
      );

    if (filters.accountId) {
      query = query.andWhere('transactions.account_id', filters.accountId);
    }

    if (filters.categoryId) {
      query = query.andWhere('transactions.category_id', filters.categoryId);
    }

    if (filters.type) {
      query = query.andWhere('transactions.transaction_type', filters.type);
    }

    if (filters.startDate && filters.endDate) {
      query = query.whereBetween('transactions.transaction_date', [filters.startDate, filters.endDate]);
    }

    return query
      .orderBy('transactions.transaction_date', 'desc')
      .limit(filters.limit || 100)
      .offset(filters.offset || 0);
  }
}

module.exports = Transaction;
