const Budget = require('../models/Budget');

class BudgetService {
  async createBudget(userId, data) {
    if (!data.amount || data.amount <= 0) {
      throw new Error('Amount must be greater than 0');
    }

    if (!data.name) {
      throw new Error('Budget name is required');
    }

    if (!data.period) {
      throw new Error('Period is required (monthly, quarterly, yearly, custom)');
    }

    if (!data.start_date) {
      throw new Error('Start date is required');
    }

    const validPeriods = ['monthly', 'quarterly', 'yearly', 'custom'];
    if (!validPeriods.includes(data.period)) {
      throw new Error(`Period must be one of: ${validPeriods.join(', ')}`);
    }

    if (data.alert_threshold !== undefined && (data.alert_threshold < 0 || data.alert_threshold > 100)) {
      throw new Error('Alert threshold must be between 0 and 100');
    }

    return await Budget.create(userId, data);
  }

  async getBudget(budgetId, userId) {
    const budget = await Budget.findById(budgetId, userId);
    if (!budget) {
      throw new Error('Budget not found');
    }
    return budget;
  }

  async listBudgets(userId, filters) {
    return await Budget.list(userId, filters);
  }

  async updateBudget(budgetId, userId, data) {
    const existing = await Budget.findById(budgetId, userId);
    if (!existing) {
      throw new Error('Budget not found');
    }

    if (data.amount !== undefined && data.amount <= 0) {
      throw new Error('Amount must be greater than 0');
    }

    if (data.alert_threshold !== undefined && (data.alert_threshold < 0 || data.alert_threshold > 100)) {
      throw new Error('Alert threshold must be between 0 and 100');
    }

    return await Budget.update(budgetId, userId, data);
  }

  async deleteBudget(budgetId, userId) {
    const existing = await Budget.findById(budgetId, userId);
    if (!existing) {
      throw new Error('Budget not found');
    }

    const result = await Budget.softDelete(budgetId, userId);
    if (result === 0) {
      throw new Error('Failed to delete budget');
    }

    return { success: true, message: 'Budget deleted successfully' };
  }

  async getProgress(budgetId, userId) {
    const progress = await Budget.getProgress(budgetId, userId);
    if (!progress) {
      throw new Error('Budget not found');
    }
    return progress;
  }

  async getComparison(userId, period) {
    if (!period) {
      throw new Error('Period is required');
    }

    const validPeriods = ['monthly', 'quarterly', 'yearly', 'custom'];
    if (!validPeriods.includes(period)) {
      throw new Error(`Period must be one of: ${validPeriods.join(', ')}`);
    }

    return await Budget.comparison(userId, period);
  }
}

module.exports = new BudgetService();
