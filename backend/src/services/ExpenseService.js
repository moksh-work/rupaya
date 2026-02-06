const Expense = require('../models/Expense');
const { parse } = require('json2csv');

class ExpenseService {
  async createExpense(userId, data) {
    if (!data.amount || data.amount <= 0) {
      throw new Error('Amount must be greater than 0');
    }

    if (!data.account_id || !data.category_id) {
      throw new Error('Account ID and Category ID are required');
    }

    return await Expense.create(userId, data);
  }

  async getExpense(expenseId, userId) {
    const expense = await Expense.findById(expenseId, userId);
    if (!expense) {
      throw new Error('Expense not found');
    }
    return expense;
  }

  async listExpenses(userId, filters) {
    return await Expense.list(userId, filters);
  }

  async updateExpense(expenseId, userId, data) {
    const existing = await Expense.findById(expenseId, userId);
    if (!existing) {
      throw new Error('Expense not found');
    }

    if (data.amount !== undefined && data.amount <= 0) {
      throw new Error('Amount must be greater than 0');
    }

    return await Expense.update(expenseId, userId, data);
  }

  async deleteExpense(expenseId, userId) {
    const existing = await Expense.findById(expenseId, userId);
    if (!existing) {
      throw new Error('Expense not found');
    }

    const result = await Expense.softDelete(expenseId, userId);
    if (result === 0) {
      throw new Error('Failed to delete expense');
    }

    return { success: true, message: 'Expense deleted successfully' };
  }

  async bulkDeleteExpenses(expenseIds, userId) {
    if (!Array.isArray(expenseIds) || expenseIds.length === 0) {
      throw new Error('Expense IDs array is required and must not be empty');
    }

    const result = await Expense.bulkDelete(expenseIds, userId);
    return {
      success: true,
      message: `${result} expenses deleted successfully`,
      deletedCount: result
    };
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

    return await Expense.getStatistics(userId, start, end);
  }

  async exportExpenses(userId, format = 'csv', filters) {
    const { expenses } = await Expense.list(userId, { ...filters, limit: 10000 });

    if (format === 'csv') {
      const fields = [
        'expense_id',
        'description',
        'amount',
        'currency',
        'category_name',
        'merchant',
        'expense_date',
        'notes'
      ];

      const data = expenses.map(e => ({
        expense_id: e.expense_id,
        description: e.description,
        amount: e.amount,
        currency: e.currency,
        category_name: e.category_name || 'Uncategorized',
        merchant: e.merchant || 'N/A',
        expense_date: new Date(e.expense_date).toISOString().split('T')[0],
        notes: e.notes || ''
      }));

      return parse(data, { fields });
    }

    throw new Error('Unsupported export format');
  }

  async filterExpenses(userId, filters) {
    return await Expense.list(userId, filters);
  }

  async duplicateExpense(expenseId, userId) {
    const existing = await Expense.findById(expenseId, userId);
    if (!existing) {
      throw new Error('Expense not found');
    }

    return await Expense.duplicate(expenseId, userId);
  }

  async attachReceipt(expenseId, userId, receiptUrl) {
    const existing = await Expense.findById(expenseId, userId);
    if (!existing) {
      throw new Error('Expense not found');
    }

    return await Expense.attachReceipt(expenseId, userId, receiptUrl);
  }

  async createRecurringExpense(userId, data) {
    if (!data.amount || data.amount <= 0) {
      throw new Error('Amount must be greater than 0');
    }

    if (!data.account_id || !data.category_id) {
      throw new Error('Account ID and Category ID are required');
    }

    if (!data.recurring_frequency) {
      throw new Error('Recurring frequency is required (daily, weekly, monthly, yearly)');
    }

    const validFrequencies = ['daily', 'weekly', 'monthly', 'yearly'];
    if (!validFrequencies.includes(data.recurring_frequency)) {
      throw new Error(`Recurring frequency must be one of: ${validFrequencies.join(', ')}`);
    }

    return await Expense.createRecurring(userId, data);
  }
}

module.exports = new ExpenseService();
