const express = require('express');
const { query } = require('express-validator');
const authMiddleware = require('../middleware/authMiddleware');
const ReportController = require('../controllers/ReportController');

const router = express.Router();

// Middleware: All routes require authentication
router.use(authMiddleware);

// GET /api/v1/reports/dashboard
router.get(
  '/dashboard',
  [
    query('period')
      .optional()
      .isIn(['monthly', 'yearly', 'last30days'])
      .withMessage('Period must be monthly, yearly, or last30days')
  ],
  ReportController.getDashboard
);

// GET /api/v1/reports/trends
router.get(
  '/trends',
  [
    query('months')
      .optional()
      .isInt({ min: 1, max: 60 })
      .withMessage('Months must be between 1 and 60')
  ],
  ReportController.getTrends
);

// GET /api/v1/reports/category-spending
router.get(
  '/category-spending',
  [
    query('startDate')
      .notEmpty()
      .withMessage('Start date is required')
      .isISO8601()
      .withMessage('Start date must be in ISO8601 format'),
    query('endDate')
      .notEmpty()
      .withMessage('End date is required')
      .isISO8601()
      .withMessage('End date must be in ISO8601 format')
  ],
  ReportController.getCategorySpending
);

// GET /api/v1/reports/monthly
router.get(
  '/monthly',
  [
    query('year')
      .notEmpty()
      .withMessage('Year is required')
      .isInt({ min: 2000, max: 2100 })
      .withMessage('Year must be valid'),
    query('month')
      .notEmpty()
      .withMessage('Month is required')
      .isInt({ min: 1, max: 12 })
      .withMessage('Month must be between 1 and 12')
  ],
  ReportController.getMonthlyReport
);

// GET /api/v1/reports/annual
router.get(
  '/annual',
  [
    query('year')
      .notEmpty()
      .withMessage('Year is required')
      .isInt({ min: 2000, max: 2100 })
      .withMessage('Year must be valid')
  ],
  ReportController.getAnnualReport
);

// GET /api/v1/reports/goals-progress
router.get(
  '/goals-progress',
  ReportController.getGoalsProgress
);

// GET /api/v1/reports/income-vs-expense
router.get(
  '/income-vs-expense',
  [
    query('months')
      .optional()
      .isInt({ min: 1, max: 60 })
      .withMessage('Months must be between 1 and 60')
  ],
  ReportController.getIncomeVsExpense
);

// GET /api/v1/reports/comparison
router.get(
  '/comparison',
  [
    query('startDate1')
      .notEmpty()
      .withMessage('Start date 1 is required')
      .isISO8601()
      .withMessage('Start date 1 must be in ISO8601 format'),
    query('endDate1')
      .notEmpty()
      .withMessage('End date 1 is required')
      .isISO8601()
      .withMessage('End date 1 must be in ISO8601 format'),
    query('startDate2')
      .notEmpty()
      .withMessage('Start date 2 is required')
      .isISO8601()
      .withMessage('Start date 2 must be in ISO8601 format'),
    query('endDate2')
      .notEmpty()
      .withMessage('End date 2 is required')
      .isISO8601()
      .withMessage('End date 2 must be in ISO8601 format')
  ],
  ReportController.getComparison
);

module.exports = router;
