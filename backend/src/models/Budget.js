const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class Budget {
  static async create(userId, data) {
    const record = {
      budget_id: uuidv4(),
      user_id: userId,
      category_id: data.category_id || null,
      account_id: data.account_id || null,
      name: data.name,
      amount: data.amount,
      currency: data.currency || 'INR',
      period: data.period,
      start_date: data.start_date,
      end_date: data.end_date || null,
      alert_threshold: data.alert_threshold || 80,
      notes: data.notes || null,
      is_active: data.is_active !== false,
      is_deleted: false,
      created_at: new Date(),
      updated_at: new Date()
    };

    const result = await db('budgets').insert(record).returning('*');
    return this._formatBudget(result[0]);
  }

  static async findById(budgetId, userId) {
    const budget = await db('budgets')
      .where({ budget_id: budgetId, user_id: userId, is_deleted: false })
      .leftJoin('categories', 'budgets.category_id', 'categories.category_id')
      .leftJoin('accounts', 'budgets.account_id', 'accounts.account_id')
      .select(
        'budgets.*',
        'categories.name as category_name',
        'accounts.name as account_name'
      )
      .first();
    
    return budget ? this._formatBudget(budget) : null;
  }

  static async list(userId, filters = {}) {
    let query = db('budgets')
      .where({ 'budgets.user_id': userId, 'budgets.is_deleted': false })
      .leftJoin('categories', 'budgets.category_id', 'categories.category_id')
      .leftJoin('accounts', 'budgets.account_id', 'accounts.account_id')
      .select(
        'budgets.*',
        'categories.name as category_name',
        'accounts.name as account_name'
      );

    if (filters.categoryId) {
      query = query.andWhere('budgets.category_id', filters.categoryId);
    }

    if (filters.accountId) {
      query = query.andWhere('budgets.account_id', filters.accountId);
    }

    if (filters.isActive !== undefined) {
      query = query.andWhere('budgets.is_active', filters.isActive);
    }

    if (filters.period) {
      query = query.andWhere('budgets.period', filters.period);
    }

    const limit = filters.limit || 20;
    const offset = filters.offset || 0;

    const results = await query
      .orderBy('budgets.created_at', 'desc')
      .limit(limit)
      .offset(offset);

    const countQuery = db('budgets')
      .where({ 'budgets.user_id': userId, 'budgets.is_deleted': false });

    if (filters.categoryId) countQuery.andWhere('budgets.category_id', filters.categoryId);
    if (filters.accountId) countQuery.andWhere('budgets.account_id', filters.accountId);
    if (filters.isActive !== undefined) countQuery.andWhere('budgets.is_active', filters.isActive);
    if (filters.period) countQuery.andWhere('budgets.period', filters.period);

    const [{ count }] = await countQuery.count('* as count');

    return {
      budgets: results.map(b => this._formatBudget(b)),
      total: parseInt(count),
      limit,
      offset
    };
  }

  static async update(budgetId, userId, data) {
    const updateData = {
      ...data,
      updated_at: new Date()
    };

    const result = await db('budgets')
      .where({ budget_id: budgetId, user_id: userId, is_deleted: false })
      .update(updateData)
      .returning('*');

    return result.length > 0 ? this._formatBudget(result[0]) : null;
  }

  static async softDelete(budgetId, userId) {
    return await db('budgets')
      .where({ budget_id: budgetId, user_id: userId })
      .update({ is_deleted: true, updated_at: new Date() });
  }

  static async getProgress(budgetId, userId) {
    const budget = await this.findById(budgetId, userId);
    if (!budget) return null;

    const spent = await db('expenses')
      .where({
        user_id: userId,
        category_id: budget.category_id,
        is_deleted: false
      })
      .whereBetween('expense_date', [budget.start_date, budget.end_date || new Date()])
      .sum('amount as total')
      .first();

    const spentAmount = parseFloat(spent.total) || 0;
    const budgetAmount = parseFloat(budget.amount);
    const percentageUsed = (spentAmount / budgetAmount) * 100;
    const remaining = budgetAmount - spentAmount;
    const isExceeded = spentAmount > budgetAmount;
    const alertTriggered = percentageUsed >= budget.alert_threshold;

    return {
      budget_id: budgetId,
      budget_amount: budgetAmount,
      spent_amount: spentAmount,
      remaining_amount: remaining,
      percentage_used: Math.round(percentageUsed * 100) / 100,
      alert_threshold: budget.alert_threshold,
      is_exceeded: isExceeded,
      alert_triggered: alertTriggered,
      period: budget.period,
      start_date: budget.start_date,
      end_date: budget.end_date
    };
  }

  static async comparison(userId, period) {
    const budgets = await db('budgets')
      .where({ user_id: userId, is_deleted: false, period })
      .select('*');

    const comparison = [];

    for (const budget of budgets) {
      const spent = await db('expenses')
        .where({
          user_id: userId,
          category_id: budget.category_id,
          is_deleted: false
        })
        .whereBetween('expense_date', [budget.start_date, budget.end_date || new Date()])
        .sum('amount as total')
        .first();

      const spentAmount = parseFloat(spent.total) || 0;
      const budgetAmount = parseFloat(budget.amount);
      const percentageUsed = (spentAmount / budgetAmount) * 100;

      comparison.push({
        budget_id: budget.budget_id,
        name: budget.name,
        budget_amount: budgetAmount,
        spent_amount: spentAmount,
        remaining_amount: budgetAmount - spentAmount,
        percentage_used: Math.round(percentageUsed * 100) / 100,
        is_exceeded: spentAmount > budgetAmount,
        period: budget.period
      });
    }

    return {
      period,
      budgets: comparison,
      total_budgeted: comparison.reduce((sum, b) => sum + b.budget_amount, 0),
      total_spent: comparison.reduce((sum, b) => sum + b.spent_amount, 0),
      exceeded_count: comparison.filter(b => b.is_exceeded).length
    };
  }

  static _formatBudget(budget) {
    return budget;
  }
}

module.exports = Budget;
