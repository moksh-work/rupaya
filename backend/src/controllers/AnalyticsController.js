const AnalyticsService = require('../services/AnalyticsService');
const { asyncHandler, logger } = require('../utils/validators');

const getDashboard = asyncHandler(async (req, res) => {
  const stats = await AnalyticsService.getDashboardStats(req.user.userId, req.query.period || 'month');
  res.json(stats);
});

const getBudgetProgress = asyncHandler(async (req, res) => {
  const progress = await AnalyticsService.getBudgetProgress(req.user.userId);
  res.json(progress);
});

module.exports = {
  getDashboard,
  getBudgetProgress
};
