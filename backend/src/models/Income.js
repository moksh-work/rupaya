const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class Income {
  static async create(userId, data) {
    const record = {
      income_id: uuidv4(),
      user_id: userId,
      account_id: data.account_id,
      amount: data.amount,
      currency: data.currency || 'INR',
      category_id: data.category_id || null,
      description: data.description,
      notes: data.notes || null,
      source: data.source || null,
      tags: Array.isArray(data.tags) ? JSON.stringify(data.tags) : null,
      income_date: data.income_date || new Date(),
      is_recurring: data.is_recurring || false,
      recurring_frequency: data.recurring_frequency || null,
      recurring_end_date: data.recurring_end_date || null,
      parent_income_id: data.parent_income_id || null,
      is_deleted: false,
      created_at: new Date(),
      updated_at: new Date()
    };

    const result = await db('income').insert(record).returning('*');
    return this._formatIncome(result[0]);
  }

  static async findById(incomeId, userId) {
    const income = await db('income')
      .where({ income_id: incomeId, user_id: userId, is_deleted: false })
      .leftJoin('categories', 'income.category_id', 'categories.category_id')
      .leftJoin('accounts', 'income.account_id', 'accounts.account_id')
      .select(
        'income.*',
        'categories.name as category_name',
        'accounts.name as account_name'
      )
      .first();
    
    return income ? this._formatIncome(income) : null;
  }

  static async list(userId, filters = {}) {
    let query = db('income')
      .where({ 'income.user_id': userId, 'income.is_deleted': false })
      .leftJoin('categories', 'income.category_id', 'categories.category_id')
      .leftJoin('accounts', 'income.account_id', 'accounts.account_id')
      .select(
        'income.*',
        'categories.name as category_name',
        'accounts.name as account_name'
      );

    if (filters.accountId) {
      query = query.andWhere('income.account_id', filters.accountId);
    }

    if (filters.categoryId) {
      query = query.andWhere('income.category_id', filters.categoryId);
    }

    if (filters.source) {
      query = query.andWhere('income.source', 'ilike', `%${filters.source}%`);
    }

    if (filters.startDate && filters.endDate) {
      query = query.whereBetween('income.income_date', [filters.startDate, filters.endDate]);
    }

    if (filters.minAmount !== undefined && filters.maxAmount !== undefined) {
      query = query.whereBetween('income.amount', [filters.minAmount, filters.maxAmount]);
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
      .orderBy('income.income_date', 'desc')
      .limit(limit)
      .offset(offset);

    const countQuery = db('income')
      .where({ 'income.user_id': userId, 'income.is_deleted': false });

    if (filters.accountId) countQuery.andWhere('income.account_id', filters.accountId);
    if (filters.categoryId) countQuery.andWhere('income.category_id', filters.categoryId);
    if (filters.source) countQuery.andWhere('income.source', 'ilike', `%${filters.source}%`);
    if (filters.startDate && filters.endDate) {
      countQuery.whereBetween('income.income_date', [filters.startDate, filters.endDate]);
    }

    const [{ count }] = await countQuery.count('* as count');

    return {
      income: results.map(i => this._formatIncome(i)),
      total: parseInt(count),
      limit,
      offset
    };
  }

  static async update(incomeId, userId, data) {
    const updateData = {
      ...data,
      tags: Array.isArray(data.tags) ? JSON.stringify(data.tags) : data.tags,
      updated_at: new Date()
    };

    const result = await db('income')
      .where({ income_id: incomeId, user_id: userId, is_deleted: false })
      .update(updateData)
      .returning('*');

    return result.length > 0 ? this._formatIncome(result[0]) : null;
  }

  static async softDelete(incomeId, userId) {
    return await db('income')
      .where({ income_id: incomeId, user_id: userId })
      .update({ is_deleted: true, updated_at: new Date() });
  }

  static async getStatistics(userId, startDate, endDate) {
    const income = await db('income')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('income_date', [startDate, endDate])
      .leftJoin('categories', 'income.category_id', 'categories.category_id')
      .select('income.amount', 'income.currency', 'categories.name as category_name', 'income.category_id');

    const totalByCategory = {};
    let grandTotal = 0;

    income.forEach(inc => {
      const category = inc.category_name || 'Uncategorized';
      if (!totalByCategory[category]) {
        totalByCategory[category] = 0;
      }
      totalByCategory[category] += parseFloat(inc.amount);
      grandTotal += parseFloat(inc.amount);
    });

    return {
      total: grandTotal,
      count: income.length,
      average: income.length > 0 ? grandTotal / income.length : 0,
      byCategory: totalByCategory,
      startDate,
      endDate
    };
  }

  static _formatIncome(income) {
    return {
      ...income,
      tags: income.tags ? JSON.parse(income.tags) : []
    };
  }
}

module.exports = Income;
