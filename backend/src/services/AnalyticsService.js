const db = require('../config/database');

class AnalyticsService {
  static getStartDate(endDate, period) {
    const start = new Date(endDate);
    switch (period) {
      case 'week':
        start.setDate(start.getDate() - 7);
        break;
      case 'year':
        start.setFullYear(start.getFullYear() - 1);
        break;
      case 'month':
      default:
        start.setMonth(start.getMonth() - 1);
        break;
    }
    return start;
  }

  static async getDashboardStats(userId, period = 'month') {
    const endDate = new Date();
    const startDate = this.getStartDate(endDate, period);

    const transactions = await db('transactions')
      .where('user_id', userId)
      .where('is_deleted', false)
      .whereBetween('transaction_date', [startDate, endDate]);

    const income = transactions
      .filter(t => t.transaction_type === 'income')
      .reduce((sum, t) => sum + Number(t.amount), 0);

    const expenses = transactions
      .filter(t => t.transaction_type === 'expense')
      .reduce((sum, t) => sum + Number(t.amount), 0);

    const spendingByCategory = await db('transactions')
      .where('transactions.user_id', userId)
      .where('transactions.transaction_type', 'expense')
      .where('transactions.is_deleted', false)
      .whereBetween('transactions.transaction_date', [startDate, endDate])
      .join('categories', 'transactions.category_id', 'categories.category_id')
      .groupBy('categories.category_id', 'categories.name')
      .select('categories.name', db.raw('SUM(transactions.amount) as total'))
      .orderBy('total', 'desc');

    const savings = income - expenses;
    const savingsRate = income > 0 ? ((savings / income) * 100).toFixed(2) : '0.00';

    return {
      period,
      startDate,
      endDate,
      income,
      expenses,
      savings,
      savingsRate,
      spendingByCategory: spendingByCategory.map(row => ({
        category: row.name,
        amount: Number(row.total)
      }))
    };
  }

  static async getBudgetProgress(userId) {
    const budgets = await db('budgets')
      .where({ user_id: userId, is_active: true })
      .select('*');

    const progress = await Promise.all(budgets.map(async budget => {
      const spent = await db('transactions')
        .where({ user_id: userId, transaction_type: 'expense', category_id: budget.category_id })
        .andWhere('transaction_date', '>=', db.raw("DATE_TRUNC('month', NOW())"))
        .andWhere('is_deleted', false)
        .sum('amount as total')
        .first();

      const spentAmount = Number(spent.total) || 0;
      const remaining = Number(budget.amount) - spentAmount;
      const progressPercent = budget.amount > 0 ? ((spentAmount / budget.amount) * 100).toFixed(2) : '0.00';

      return {
        id: budget.budget_id,
        category: budget.category_id,
        limit: Number(budget.amount),
        spent: spentAmount,
        remaining,
        progress: progressPercent
      };
    }));

    return progress;
  }
}

module.exports = AnalyticsService;
