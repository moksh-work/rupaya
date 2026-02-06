const ReportService = require('../services/ReportService');
const asyncHandler = require('../utils/asyncHandler');

const getDashboard = asyncHandler(async (req, res) => {
  const { period } = req.query;
  const data = await ReportService.getDashboard(req.user.id, period);

  res.status(200).json({
    success: true,
    message: 'Dashboard data retrieved successfully',
    data
  });
});

const getTrends = asyncHandler(async (req, res) => {
  const { months } = req.query;
  const data = await ReportService.getTrends(req.user.id, months);

  res.status(200).json({
    success: true,
    message: 'Trends data retrieved successfully',
    data
  });
});

const getCategorySpending = asyncHandler(async (req, res) => {
  const { startDate, endDate } = req.query;
  const data = await ReportService.getCategorySpending(req.user.id, startDate, endDate);

  res.status(200).json({
    success: true,
    message: 'Category spending data retrieved successfully',
    data
  });
});

const getMonthlyReport = asyncHandler(async (req, res) => {
  const { year, month } = req.query;
  const data = await ReportService.getMonthlyReport(req.user.id, year, month);

  res.status(200).json({
    success: true,
    message: 'Monthly report retrieved successfully',
    data
  });
});

const getAnnualReport = asyncHandler(async (req, res) => {
  const { year } = req.query;
  const data = await ReportService.getAnnualReport(req.user.id, year);

  res.status(200).json({
    success: true,
    message: 'Annual report retrieved successfully',
    data
  });
});

const getGoalsProgress = asyncHandler(async (req, res) => {
  const data = await ReportService.getGoalsProgress(req.user.id);

  res.status(200).json({
    success: true,
    message: 'Goals progress retrieved successfully',
    data
  });
});

const getIncomeVsExpense = asyncHandler(async (req, res) => {
  const { months } = req.query;
  const data = await ReportService.getIncomeVsExpense(req.user.id, months);

  res.status(200).json({
    success: true,
    message: 'Income vs Expense data retrieved successfully',
    data
  });
});

const getComparison = asyncHandler(async (req, res) => {
  const { startDate1, endDate1, startDate2, endDate2 } = req.query;
  const data = await ReportService.getComparison(req.user.id, startDate1, endDate1, startDate2, endDate2);

  res.status(200).json({
    success: true,
    message: 'Period comparison retrieved successfully',
    data
  });
});

module.exports = {
  getDashboard,
  getTrends,
  getCategorySpending,
  getMonthlyReport,
  getAnnualReport,
  getGoalsProgress,
  getIncomeVsExpense,
  getComparison
};
