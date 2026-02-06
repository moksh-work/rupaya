const db = require('../config/database');

class Report {
  static async getDashboard(userId, period = 'monthly') {
    const now = new Date();
    let startDate, endDate;

    if (period === 'monthly') {
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    } else if (period === 'yearly') {
      startDate = new Date(now.getFullYear(), 0, 1);
      endDate = new Date(now.getFullYear(), 11, 31);
    } else {
      startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      endDate = now;
    }

    const expenses = await db('expenses')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('expense_date', [startDate, endDate])
      .sum('amount as total')
      .first();

    const income = await db('income')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('income_date', [startDate, endDate])
      .sum('amount as total')
      .first();

    const expensesByCategory = await db('expenses')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('expense_date', [startDate, endDate])
      .leftJoin('categories', 'expenses.category_id', 'categories.category_id')
      .groupBy('categories.category_id', 'categories.name')
      .select('categories.name', db.raw('sum(amount) as total'))
      .orderBy('total', 'desc')
      .limit(5);

    const totalExpenses = parseFloat(expenses.total) || 0;
    const totalIncome = parseFloat(income.total) || 0;

    return {
      period,
      startDate,
      endDate,
      summary: {
        total_income: totalIncome,
        total_expenses: totalExpenses,
        net_cash_flow: totalIncome - totalExpenses,
        savings_rate: totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome * 100) : 0
      },
      top_expense_categories: expensesByCategory.map(item => ({
        category: item.name,
        amount: parseFloat(item.total)
      }))
    };
  }

  static async getTrends(userId, months = 12) {
    const now = new Date();
    const trends = [];

    for (let i = months - 1; i >= 0; i--) {
      const monthStart = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0);

      const expenses = await db('expenses')
        .where({ user_id: userId, is_deleted: false })
        .whereBetween('expense_date', [monthStart, monthEnd])
        .sum('amount as total')
        .first();

      const income = await db('income')
        .where({ user_id: userId, is_deleted: false })
        .whereBetween('income_date', [monthStart, monthEnd])
        .sum('amount as total')
        .first();

      trends.push({
        month: monthStart.toISOString().substring(0, 7),
        income: parseFloat(income.total) || 0,
        expenses: parseFloat(expenses.total) || 0,
        net: (parseFloat(income.total) || 0) - (parseFloat(expenses.total) || 0)
      });
    }

    return {
      period: `${months} months`,
      trends
    };
  }

  static async getCategorySpending(userId, startDate, endDate) {
    const spending = await db('expenses')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('expense_date', [startDate, endDate])
      .leftJoin('categories', 'expenses.category_id', 'categories.category_id')
      .groupBy('categories.category_id', 'categories.name')
      .select('categories.name', db.raw('sum(amount) as total'), db.raw('count(*) as count'))
      .orderBy('total', 'desc');

    const total = spending.reduce((sum, item) => sum + parseFloat(item.total), 0);

    return {
      startDate,
      endDate,
      total,
      categories: spending.map(item => ({
        category: item.name,
        amount: parseFloat(item.total),
        count: parseInt(item.count),
        percentage: total > 0 ? (parseFloat(item.total) / total * 100) : 0
      }))
    };
  }

  static async getMonthlyReport(userId, year, month) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);

    const expenses = await db('expenses')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('expense_date', [startDate, endDate])
      .sum('amount as total')
      .first();

    const income = await db('income')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('income_date', [startDate, endDate])
      .sum('amount as total')
      .first();

    const expensesByCategory = await db('expenses')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('expense_date', [startDate, endDate])
      .leftJoin('categories', 'expenses.category_id', 'categories.category_id')
      .groupBy('categories.name')
      .select('categories.name', db.raw('sum(amount) as total'))
      .orderBy('total', 'desc');

    return {
      year,
      month,
      startDate,
      endDate,
      income: parseFloat(income.total) || 0,
      expenses: parseFloat(expenses.total) || 0,
      net: (parseFloat(income.total) || 0) - (parseFloat(expenses.total) || 0),
      expenses_by_category: expensesByCategory.map(item => ({
        category: item.name,
        amount: parseFloat(item.total)
      }))
    };
  }

  static async getAnnualReport(userId, year) {
    const startDate = new Date(year, 0, 1);
    const endDate = new Date(year, 11, 31);

    const totalExpenses = await db('expenses')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('expense_date', [startDate, endDate])
      .sum('amount as total')
      .first();

    const totalIncome = await db('income')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('income_date', [startDate, endDate])
      .sum('amount as total')
      .first();

    const monthlyData = [];
    for (let month = 1; month <= 12; month++) {
      const monthStart = new Date(year, month - 1, 1);
      const monthEnd = new Date(year, month, 0);

      const monthExp = await db('expenses')
        .where({ user_id: userId, is_deleted: false })
        .whereBetween('expense_date', [monthStart, monthEnd])
        .sum('amount as total')
        .first();

      const monthInc = await db('income')
        .where({ user_id: userId, is_deleted: false })
        .whereBetween('income_date', [monthStart, monthEnd])
        .sum('amount as total')
        .first();

      monthlyData.push({
        month,
        income: parseFloat(monthInc.total) || 0,
        expenses: parseFloat(monthExp.total) || 0
      });
    }

    return {
      year,
      startDate,
      endDate,
      total_income: parseFloat(totalIncome.total) || 0,
      total_expenses: parseFloat(totalExpenses.total) || 0,
      net: (parseFloat(totalIncome.total) || 0) - (parseFloat(totalExpenses.total) || 0),
      monthly_breakdown: monthlyData
    };
  }

  static async getGoalsProgress(userId) {
    const budgets = await db('budgets')
      .where({ user_id: userId, is_deleted: false, is_active: true })
      .select('*');

    const progress = [];

    for (const budget of budgets) {
      const spent = await db('expenses')
        .where({ user_id: userId, category_id: budget.category_id, is_deleted: false })
        .whereBetween('expense_date', [budget.start_date, budget.end_date || new Date()])
        .sum('amount as total')
        .first();

      const spentAmount = parseFloat(spent.total) || 0;
      const budgetAmount = parseFloat(budget.amount);
      const percentageUsed = (spentAmount / budgetAmount) * 100;

      progress.push({
        budget_id: budget.budget_id,
        name: budget.name,
        target_amount: budgetAmount,
        spent_amount: spentAmount,
        remaining_amount: budgetAmount - spentAmount,
        percentage_used: Math.round(percentageUsed * 100) / 100,
        is_on_track: spentAmount <= budgetAmount,
        period: budget.period
      });
    }

    return {
      total_budgets: progress.length,
      on_track: progress.filter(p => p.is_on_track).length,
      goals: progress
    };
  }

  static async getIncomeVsExpense(userId, months = 12) {
    const now = new Date();
    const data = [];

    for (let i = months - 1; i >= 0; i--) {
      const monthStart = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0);

      const expenses = await db('expenses')
        .where({ user_id: userId, is_deleted: false })
        .whereBetween('expense_date', [monthStart, monthEnd])
        .sum('amount as total')
        .first();

      const income = await db('income')
        .where({ user_id: userId, is_deleted: false })
        .whereBetween('income_date', [monthStart, monthEnd])
        .sum('amount as total')
        .first();

      data.push({
        period: monthStart.toISOString().substring(0, 7),
        income: parseFloat(income.total) || 0,
        expenses: parseFloat(expenses.total) || 0
      });
    }

    return {
      months,
      data
    };
  }

  static async getComparison(userId, startDate1, endDate1, startDate2, endDate2) {
    const period1Expenses = await db('expenses')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('expense_date', [startDate1, endDate1])
      .sum('amount as total')
      .first();

    const period1Income = await db('income')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('income_date', [startDate1, endDate1])
      .sum('amount as total')
      .first();

    const period2Expenses = await db('expenses')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('expense_date', [startDate2, endDate2])
      .sum('amount as total')
      .first();

    const period2Income = await db('income')
      .where({ user_id: userId, is_deleted: false })
      .whereBetween('income_date', [startDate2, endDate2])
      .sum('amount as total')
      .first();

    const p1Exp = parseFloat(period1Expenses.total) || 0;
    const p1Inc = parseFloat(period1Income.total) || 0;
    const p2Exp = parseFloat(period2Expenses.total) || 0;
    const p2Inc = parseFloat(period2Income.total) || 0;

    return {
      period1: {
        startDate: startDate1,
        endDate: endDate1,
        income: p1Inc,
        expenses: p1Exp,
        net: p1Inc - p1Exp
      },
      period2: {
        startDate: startDate2,
        endDate: endDate2,
        income: p2Inc,
        expenses: p2Exp,
        net: p2Inc - p2Exp
      },
      comparison: {
        income_change: p2Inc - p1Inc,
        income_change_percent: p1Inc > 0 ? ((p2Inc - p1Inc) / p1Inc * 100) : 0,
        expense_change: p2Exp - p1Exp,
        expense_change_percent: p1Exp > 0 ? ((p2Exp - p1Exp) / p1Exp * 100) : 0,
        net_change: (p2Inc - p2Exp) - (p1Inc - p1Exp)
      }
    };
  }
}

module.exports = Report;
