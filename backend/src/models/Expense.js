const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class Expense {
  static async create(userId, data) {
    const record = {
      expense_id: uuidv4(),
      user_id: userId,
      account_id: data.account_id,
      amount: data.amount,
      currency: data.currency || 'INR',
      category_id: data.category_id,
      description: data.description,
      notes: data.notes || null,
      location: data.location || null,
      merchant: data.merchant || null,
      tags: Array.isArray(data.tags) ? JSON.stringify(data.tags) : null,
      receipt_url: data.receipt_url || null,
      expense_date: data.expense_date || new Date(),
      is_recurring: data.is_recurring || false,
      recurring_frequency: data.recurring_frequency || null,
      recurring_end_date: data.recurring_end_date || null,
      parent_expense_id: data.parent_expense_id || null,
      is_deleted: false,
      created_at: new Date(),
      updated_at: new Date()
    };

    const result = await db('expenses').insert(record).returning('*');
    return this._formatExpense(result[0]);
  }

  static async findById(expenseId, userId) {
    const expense = await db('expenses')
      .where({ expense_id: expenseId, user_id: userId, is_deleted: false })
      .leftJoin('categories', 'expenses.category_id', 'categories.category_id')
      .leftJoin('accounts', 'expenses.account_id', 'accounts.account_id')
      .select(
        'expenses.*',
        'categories.name as category_name',
        'accounts.name as account_name'
      )
      .first();
    
    return expense ? this._formatExpense(expense) : null;
  }

  static async list(userId, filters = {}) {
    let query = db('expenses')
      .where({ 'expenses.user_id': userId, 'expenses.is_deleted': false })
      .leftJoin('categories', 'expenses.category_id', 'categories.category_id')
      .leftJoin('accounts', 'expenses.account_id', 'accounts.account_id')
      .select(
        'expenses.*',
        'categories.name as category_name',
        'accounts.name as account_name'
      );

    if (filters.accountId) {
      query = query.andWhere('expenses.account_id', filters.accountId);
    }

    if (filters.categoryId) {
      query = query.andWhere('expenses.category_id', filters.categoryId);
    }

    if (filters.merchant) {
      query = query.andWhere('expenses.merchant', 'ilike', `%${filters.merchant}%`);
    }

    if (filters.startDate && filters.endDate) {
      query = query.whereBetween('expenses.expense_date', [filters.startDate, filters.endDate]);
    }

    if (filters.minAmount !== undefined && filters.maxAmount !== undefined) {
      query = query.whereBetween('expenses.amount', [filters.minAmount, filters.maxAmount]);
    }

    if (filters.tags && Array.isArray(filters.tags)) {
      query = query.andWhere(function() {
        filters.tags.forEach(tag => {
          this.orWhereRaw(`tags::jsonb @> ?`, [JSON.stringify([tag])]);
        });
      });
    }

    const limit = filters.limit || 20;
    const offset = filters.offset || 0;

    const results = await query
      .orderBy('expenses.expense_date', 'desc')
      .limit(limit)
      .offset(offset);

    const countQuery = db('expenses')
      .where({ 'expenses.user_id': userId, 'expenses.is_deleted': false });

    if (filters.accountId) countQuery.andWhere('expenses.account_id', filters.accountId);
    if (filters.categoryId) countQuery.andWhere('expenses.category_id', filters.categoryId);
    if (filters.merchant) countQuery.andWhere('expenses.merchant', 'ilike', `%${filters.merchant}%`);
    if (filters.startDate && filters.endDate) {
      countQuery.whereBetween('expenses.expense_date', [filters.startDate, filters.endDate]);
    }

    const [{ count }] = await countQuery.count('* as count');

    return {
      expenses: results.map(e => this._formatExpense(e)),
      total: parseInt(count),
      limit,
      offset
    };
  }

  static async update(expenseId, userId, data) {
    const updateData = {
      ...data,
      tags: Array.isArray(data.tags) ? JSON.stringify(data.tags) : data.tags,
      updated_at: new Date()
    };

    const result = await db('expenses')
      .where({ expense_id: expenseId, user_id: userId, is_deleted: false })
      .update(updateData)
      .returning('*');

    return result.length > 0 ? this._formatExpense(result[0]) : null;
  }

  static async softDelete(expenseId, userId) {
    return await db('expenses')
      .where({ expense_id: expenseId, user_id: userId })
      .update({ is_deleted: true, updated_at: new Date() });
  }

  static async bulkDelete(expenseIds, userId) {
    return await db('expenses')
      .where({ user_id: userId })
      .whereIn('expense_id', expenseIds)
      .update({ is_deleted: true, updated_at: new Date() });
  }

  static async getStatistics(userId, startDate, endDate) {
    const expenses = await db('expenses')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('expense_date', [startDate, endDate])
      .leftJoin('categories', 'expenses.category_id', 'categories.category_id')
      .select('expenses.amount', 'expenses.currency', 'categories.name as category_name', 'expenses.category_id');

    const totalByCategory = {};
    let grandTotal = 0;

    expenses.forEach(expense => {
      const category = expense.category_name || 'Uncategorized';
      if (!totalByCategory[category]) {
        totalByCategory[category] = 0;
      }
      totalByCategory[category] += parseFloat(expense.amount);
      grandTotal += parseFloat(expense.amount);
    });

    return {
      total: grandTotal,
      count: expenses.length,
      average: expenses.length > 0 ? grandTotal / expenses.length : 0,
      byCategory: totalByCategory,
      startDate,
      endDate
    };
  }

  static async duplicate(expenseId, userId) {
    const original = await this.findById(expenseId, userId);
    if (!original) return null;

    const newExpense = {
      ...original,
      expense_id: uuidv4(),
      created_at: new Date(),
      updated_at: new Date(),
      parent_expense_id: expenseId
    };

    delete newExpense.category_name;
    delete newExpense.account_name;

    const result = await db('expenses').insert(newExpense).returning('*');
    return this._formatExpense(result[0]);
  }

  static async attachReceipt(expenseId, userId, receiptUrl) {
    const result = await db('expenses')
      .where({ expense_id: expenseId, user_id: userId })
      .update({ receipt_url: receiptUrl, updated_at: new Date() })
      .returning('*');

    return result.length > 0 ? this._formatExpense(result[0]) : null;
  }

  static async createRecurring(userId, data) {
    const record = {
      expense_id: uuidv4(),
      user_id: userId,
      account_id: data.account_id,
      amount: data.amount,
      currency: data.currency || 'INR',
      category_id: data.category_id,
      description: data.description,
      notes: data.notes || null,
      merchant: data.merchant || null,
      tags: Array.isArray(data.tags) ? JSON.stringify(data.tags) : null,
      is_recurring: true,
      recurring_frequency: data.recurring_frequency,
      recurring_end_date: data.recurring_end_date || null,
      expense_date: data.start_date || new Date(),
      is_deleted: false,
      created_at: new Date(),
      updated_at: new Date()
    };

    const result = await db('expenses').insert(record).returning('*');
    return this._formatExpense(result[0]);
  }

  static _formatExpense(expense) {
    return {
      ...expense,
      tags: expense.tags ? JSON.parse(expense.tags) : []
    };
  }
}

module.exports = Expense;
