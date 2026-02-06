const express = require('express');
const { body, query, param, validationResult } = require('express-validator');
const IncomeController = require('../controllers/IncomeController');

const router = express.Router();

const validationErrorHandler = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

// POST /api/v1/income - Create income
router.post('/', [
  body('amount').isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
  body('account_id').notEmpty().isString().withMessage('Account ID is required'),
  body('description').notEmpty().isString().isLength({ min: 1, max: 255 }).withMessage('Description is required and max 255 chars'),
  body('income_date').optional().isISO8601().withMessage('Income date must be valid ISO8601 date'),
  body('source').optional().isString().isLength({ max: 100 }),
  body('notes').optional().isString().isLength({ max: 500 }),
  body('tags').optional().isArray().withMessage('Tags must be an array'),
  body('category_id').optional().isString()
], validationErrorHandler, IncomeController.createIncome);

// GET /api/v1/income - List income
router.get('/', [
  query('accountId').optional().isString(),
  query('categoryId').optional().isString(),
  query('source').optional().isString(),
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601(),
  query('minAmount').optional().isFloat({ ge: 0 }),
  query('maxAmount').optional().isFloat({ ge: 0 }),
  query('tags').optional(),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 })
], validationErrorHandler, IncomeController.listIncome);

// GET /api/v1/income/statistics - Get statistics (must come before /{id})
router.get('/statistics', [
  query('startDate').notEmpty().isISO8601().withMessage('Start date is required'),
  query('endDate').notEmpty().isISO8601().withMessage('End date is required')
], validationErrorHandler, IncomeController.getStatistics);

// GET /api/v1/income/{id} - Get single income
router.get('/:id', [
  param('id').isString().withMessage('Income ID must be a string')
], validationErrorHandler, IncomeController.getIncome);

// PUT /api/v1/income/{id} - Update income
router.put('/:id', [
  param('id').isString().withMessage('Income ID must be a string'),
  body('amount').optional().isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
  body('description').optional().isString().isLength({ min: 1, max: 255 }),
  body('income_date').optional().isISO8601(),
  body('source').optional().isString().isLength({ max: 100 }),
  body('notes').optional().isString().isLength({ max: 500 }),
  body('tags').optional().isArray(),
  body('category_id').optional().isString()
], validationErrorHandler, IncomeController.updateIncome);

// DELETE /api/v1/income/{id} - Delete income
router.delete('/:id', [
  param('id').isString().withMessage('Income ID must be a string')
], validationErrorHandler, IncomeController.deleteIncome);

module.exports = router;
