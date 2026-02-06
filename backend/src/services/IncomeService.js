const Income = require('../models/Income');

class IncomeService {
  async createIncome(userId, data) {
    if (!data.amount || data.amount <= 0) {
      throw new Error('Amount must be greater than 0');
    }

    if (!data.account_id) {
      throw new Error('Account ID is required');
    }

    if (!data.description) {
      throw new Error('Description is required');
    }

    return await Income.create(userId, data);
  }

  async getIncome(incomeId, userId) {
    const income = await Income.findById(incomeId, userId);
    if (!income) {
      throw new Error('Income not found');
    }
    return income;
  }

  async listIncome(userId, filters) {
    return await Income.list(userId, filters);
  }

  async updateIncome(incomeId, userId, data) {
    const existing = await Income.findById(incomeId, userId);
    if (!existing) {
      throw new Error('Income not found');
    }

    if (data.amount !== undefined && data.amount <= 0) {
      throw new Error('Amount must be greater than 0');
    }

    return await Income.update(incomeId, userId, data);
  }

  async deleteIncome(incomeId, userId) {
    const existing = await Income.findById(incomeId, userId);
    if (!existing) {
      throw new Error('Income not found');
    }

    const result = await Income.softDelete(incomeId, userId);
    if (result === 0) {
      throw new Error('Failed to delete income');
    }

    return { success: true, message: 'Income deleted successfully' };
  }

  async getStatistics(userId, startDate, endDate) {
    if (!startDate || !endDate) {
      throw new Error('Start date and end date are required');
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    if (start > end) {
      throw new Error('Start date must be before end date');
    }

    return await Income.getStatistics(userId, start, end);
  }
}

module.exports = new IncomeService();
