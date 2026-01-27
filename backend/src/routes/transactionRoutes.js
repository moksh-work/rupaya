const express = require('express');
const { body, validationResult, query, param } = require('express-validator');
const TransactionController = require('../controllers/TransactionController');

const router = express.Router();

router.get('/', [
  query('accountId').optional().isUUID(),
  query('categoryId').optional().isUUID(),
  query('type').optional().isIn(['income', 'expense', 'transfer']),
  query('startDate').optional().isISO8601().toDate(),
  query('endDate').optional().isISO8601().toDate(),
  query('limit').optional().isInt({ min: 1, max: 500 }).toInt(),
  query('offset').optional().isInt({ min: 0 }).toInt()
], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, TransactionController.getTransactions);

router.post('/', [
  body('accountId').isUUID(),
  body('amount').isFloat({ gt: 0 }),
  body('type').isIn(['income', 'expense', 'transfer']),
  body('toAccountId').optional().isUUID(),
  body('categoryId').optional().isUUID(),
  body('currency').optional().isLength({ min: 3, max: 3 }),
  body('description').optional().isString(),
  body('date').optional().isISO8601()
], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, TransactionController.createTransaction);

router.delete('/:transactionId', [param('transactionId').isUUID()], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, TransactionController.deleteTransaction);

module.exports = router;
