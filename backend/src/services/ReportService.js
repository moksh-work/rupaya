const Report = require('../models/Report');

class ReportService {
  static async getDashboard(userId, period) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const validPeriods = ['monthly', 'yearly', 'last30days'];
    if (period && !validPeriods.includes(period)) {
      throw new Error(`Invalid period. Must be one of: ${validPeriods.join(', ')}`);
    }

    return await Report.getDashboard(userId, period || 'monthly');
  }

  static async getTrends(userId, months) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const monthsNumber = parseInt(months) || 12;
    if (monthsNumber < 1 || monthsNumber > 60) {
      throw new Error('Months must be between 1 and 60');
    }

    return await Report.getTrends(userId, monthsNumber);
  }

  static async getCategorySpending(userId, startDate, endDate) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    if (!startDate || !endDate) {
      throw new Error('Start date and end date are required');
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    if (isNaN(start) || isNaN(end)) {
      throw new Error('Invalid date format');
    }

    if (start > end) {
      throw new Error('Start date must be before end date');
    }

    return await Report.getCategorySpending(userId, start, end);
  }

  static async getMonthlyReport(userId, year, month) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const yearNumber = parseInt(year);
    const monthNumber = parseInt(month);

    if (isNaN(yearNumber) || isNaN(monthNumber)) {
      throw new Error('Year and month must be numbers');
    }

    if (monthNumber < 1 || monthNumber > 12) {
      throw new Error('Month must be between 1 and 12');
    }

    const currentYear = new Date().getFullYear();
    if (yearNumber < 2000 || yearNumber > currentYear + 1) {
      throw new Error('Year must be between 2000 and next year');
    }

    return await Report.getMonthlyReport(userId, yearNumber, monthNumber);
  }

  static async getAnnualReport(userId, year) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const yearNumber = parseInt(year);

    if (isNaN(yearNumber)) {
      throw new Error('Year must be a number');
    }

    const currentYear = new Date().getFullYear();
    if (yearNumber < 2000 || yearNumber > currentYear + 1) {
      throw new Error('Year must be between 2000 and next year');
    }

    return await Report.getAnnualReport(userId, yearNumber);
  }

  static async getGoalsProgress(userId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    return await Report.getGoalsProgress(userId);
  }

  static async getIncomeVsExpense(userId, months) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const monthsNumber = parseInt(months) || 12;
    if (monthsNumber < 1 || monthsNumber > 60) {
      throw new Error('Months must be between 1 and 60');
    }

    return await Report.getIncomeVsExpense(userId, monthsNumber);
  }

  static async getComparison(userId, startDate1, endDate1, startDate2, endDate2) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    if (!startDate1 || !endDate1 || !startDate2 || !endDate2) {
      throw new Error('All four date parameters are required');
    }

    const s1 = new Date(startDate1);
    const e1 = new Date(endDate1);
    const s2 = new Date(startDate2);
    const e2 = new Date(endDate2);

    if (isNaN(s1) || isNaN(e1) || isNaN(s2) || isNaN(e2)) {
      throw new Error('Invalid date format');
    }

    if (s1 > e1 || s2 > e2) {
      throw new Error('Start date must be before end date');
    }

    return await Report.getComparison(userId, s1, e1, s2, e2);
  }
}

module.exports = ReportService;
