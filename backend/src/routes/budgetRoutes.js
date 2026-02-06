const express = require('express');
const { body, query, param, validationResult } = require('express-validator');
const BudgetController = require('../controllers/BudgetController');

const router = express.Router();

const validationErrorHandler = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

// POST /api/v1/budgets - Create budget
router.post('/', [
  body('name').notEmpty().isString().isLength({ min: 1, max: 100 }).withMessage('Name is required and max 100 chars'),
  body('amount').isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
  body('currency').optional().isLength({ min: 3, max: 3 }).withMessage('Currency must be 3 characters'),
  body('period').notEmpty().isIn(['monthly', 'quarterly', 'yearly', 'custom']).withMessage('Period must be monthly, quarterly, yearly, or custom'),
  body('start_date').notEmpty().isISO8601().withMessage('Start date is required and must be ISO8601'),
  body('end_date').optional().isISO8601().withMessage('End date must be ISO8601'),
  body('category_id').optional().isString(),
  body('account_id').optional().isString(),
  body('alert_threshold').optional().isInt({ min: 0, max: 100 }).withMessage('Alert threshold must be between 0 and 100'),
  body('notes').optional().isString().isLength({ max: 500 })
], validationErrorHandler, BudgetController.createBudget);

// GET /api/v1/budgets - List budgets
router.get('/', [
  query('categoryId').optional().isString(),
  query('accountId').optional().isString(),
  query('isActive').optional().isIn(['true', 'false']),
  query('period').optional().isIn(['monthly', 'quarterly', 'yearly', 'custom']),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 })
], validationErrorHandler, BudgetController.listBudgets);

// GET /api/v1/budgets/comparison - Compare budgets (must come before /{id})
router.get('/comparison', [
  query('period').notEmpty().isIn(['monthly', 'quarterly', 'yearly', 'custom']).withMessage('Period is required')
], validationErrorHandler, BudgetController.getComparison);

// GET /api/v1/budgets/{id} - Get single budget
router.get('/:id', [
  param('id').isString().withMessage('Budget ID must be a string')
], validationErrorHandler, BudgetController.getBudget);

// GET /api/v1/budgets/{id}/progress - Get progress (must come before PUT/DELETE)
router.get('/:id/progress', [
  param('id').isString().withMessage('Budget ID must be a string')
], validationErrorHandler, BudgetController.getProgress);

// PUT /api/v1/budgets/{id} - Update budget
router.put('/:id', [
  param('id').isString().withMessage('Budget ID must be a string'),
  body('name').optional().isString().isLength({ min: 1, max: 100 }),
  body('amount').optional().isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
  body('currency').optional().isLength({ min: 3, max: 3 }),
  body('period').optional().isIn(['monthly', 'quarterly', 'yearly', 'custom']),
  body('start_date').optional().isISO8601(),
  body('end_date').optional().isISO8601(),
  body('category_id').optional().isString(),
  body('account_id').optional().isString(),
  body('alert_threshold').optional().isInt({ min: 0, max: 100 }),
  body('notes').optional().isString().isLength({ max: 500 }),
  body('is_active').optional().isBoolean()
], validationErrorHandler, BudgetController.updateBudget);

// DELETE /api/v1/budgets/{id} - Delete budget
router.delete('/:id', [
  param('id').isString().withMessage('Budget ID must be a string')
], validationErrorHandler, BudgetController.deleteBudget);

module.exports = router;
