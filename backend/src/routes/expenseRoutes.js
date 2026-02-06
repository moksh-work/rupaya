const express = require('express');
const { body, query, param, validationResult } = require('express-validator');
const ExpenseController = require('../controllers/ExpenseController');

const router = express.Router();

const validationErrorHandler = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

// POST /api/v1/expenses - Create expense
router.post('/', [
  body('amount').isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
  body('account_id').notEmpty().isString().withMessage('Account ID is required'),
  body('category_id').notEmpty().isString().withMessage('Category ID is required'),
  body('description').notEmpty().isString().isLength({ min: 1, max: 255 }).withMessage('Description is required and max 255 chars'),
  body('expense_date').optional().isISO8601().withMessage('Expense date must be valid ISO8601 date'),
  body('merchant').optional().isString().isLength({ max: 100 }),
  body('notes').optional().isString().isLength({ max: 500 }),
  body('tags').optional().isArray().withMessage('Tags must be an array'),
  body('location').optional().isString().isLength({ max: 255 })
], validationErrorHandler, ExpenseController.createExpense);

// GET /api/v1/expenses - List expenses
router.get('/', [
  query('accountId').optional().isString(),
  query('categoryId').optional().isString(),
  query('merchant').optional().isString(),
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601(),
  query('minAmount').optional().isFloat({ ge: 0 }),
  query('maxAmount').optional().isFloat({ ge: 0 }),
  query('tags').optional(),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 })
], validationErrorHandler, ExpenseController.listExpenses);

// GET /api/v1/expenses/statistics - Get statistics (must come before /{id})
router.get('/statistics', [
  query('startDate').notEmpty().isISO8601().withMessage('Start date is required'),
  query('endDate').notEmpty().isISO8601().withMessage('End date is required')
], validationErrorHandler, ExpenseController.getStatistics);

// GET /api/v1/expenses/export - Export expenses (must come before /{id})
router.get('/export', [
  query('format').optional().isIn(['csv', 'pdf']).withMessage('Format must be csv or pdf'),
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601()
], validationErrorHandler, ExpenseController.exportExpenses);

// GET /api/v1/expenses/filter - Filter expenses (must come before /{id})
router.get('/filter', [
  query('accountId').optional().isString(),
  query('categoryId').optional().isString(),
  query('merchant').optional().isString(),
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601(),
  query('minAmount').optional().isFloat({ ge: 0 }),
  query('maxAmount').optional().isFloat({ ge: 0 }),
  query('tags').optional(),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 })
], validationErrorHandler, ExpenseController.filterExpenses);

// POST /api/v1/expenses/bulk-delete - Bulk delete
router.post('/bulk-delete', [
  body('expense_ids').isArray().withMessage('expense_ids must be an array'),
  body('expense_ids.*').isString().withMessage('Each expense ID must be a string')
], validationErrorHandler, ExpenseController.bulkDeleteExpenses);

// POST /api/v1/expenses/recurring - Create recurring expense
router.post('/recurring', [
  body('amount').isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
  body('account_id').notEmpty().isString().withMessage('Account ID is required'),
  body('category_id').notEmpty().isString().withMessage('Category ID is required'),
  body('description').notEmpty().isString().isLength({ min: 1, max: 255 }).withMessage('Description is required'),
  body('recurring_frequency').notEmpty().isIn(['daily', 'weekly', 'monthly', 'yearly']).withMessage('Recurring frequency is required (daily, weekly, monthly, yearly)'),
  body('recurring_end_date').optional().isISO8601().withMessage('End date must be valid ISO8601 date'),
  body('merchant').optional().isString().isLength({ max: 100 }),
  body('notes').optional().isString().isLength({ max: 500 }),
  body('tags').optional().isArray(),
  body('start_date').optional().isISO8601()
], validationErrorHandler, ExpenseController.createRecurringExpense);

// GET /api/v1/expenses/{id} - Get single expense
router.get('/:id', [
  param('id').isString().withMessage('Expense ID must be a string')
], validationErrorHandler, ExpenseController.getExpense);

// PUT /api/v1/expenses/{id} - Update expense
router.put('/:id', [
  param('id').isString().withMessage('Expense ID must be a string'),
  body('amount').optional().isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
  body('description').optional().isString().isLength({ min: 1, max: 255 }),
  body('expense_date').optional().isISO8601(),
  body('merchant').optional().isString().isLength({ max: 100 }),
  body('notes').optional().isString().isLength({ max: 500 }),
  body('tags').optional().isArray(),
  body('category_id').optional().isString(),
  body('location').optional().isString().isLength({ max: 255 })
], validationErrorHandler, ExpenseController.updateExpense);

// DELETE /api/v1/expenses/{id} - Delete expense
router.delete('/:id', [
  param('id').isString().withMessage('Expense ID must be a string')
], validationErrorHandler, ExpenseController.deleteExpense);

// POST /api/v1/expenses/{id}/duplicate - Duplicate expense
router.post('/:id/duplicate', [
  param('id').isString().withMessage('Expense ID must be a string')
], validationErrorHandler, ExpenseController.duplicateExpense);

// POST /api/v1/expenses/{id}/receipt - Attach receipt
router.post('/:id/receipt', [
  param('id').isString().withMessage('Expense ID must be a string'),
  body('receipt_url').notEmpty().isURL().withMessage('Receipt URL is required and must be valid URL')
], validationErrorHandler, ExpenseController.attachReceipt);

module.exports = router;
