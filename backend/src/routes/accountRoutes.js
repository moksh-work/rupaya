const express = require('express');
const { body, validationResult, param } = require('express-validator');
const AccountController = require('../controllers/AccountController');

const router = express.Router();

router.get('/', AccountController.listAccounts);

router.post('/', [
  body('name').isString().isLength({ min: 1 }),
  body('account_type').isIn(['cash', 'bank', 'credit_card', 'investment', 'savings']),
  body('currency').optional().isLength({ min: 3, max: 3 }),
  body('current_balance').optional().isFloat({ min: 0 }),
  body('is_default').optional().isBoolean(),
  body('icon').optional().isString(),
  body('color').optional().isString()
], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, AccountController.createAccount);

router.put('/:accountId', [
  param('accountId').isUUID(),
  body('name').optional().isString(),
  body('account_type').optional().isIn(['cash', 'bank', 'credit_card', 'investment', 'savings']),
  body('currency').optional().isLength({ min: 3, max: 3 }),
  body('current_balance').optional().isFloat({ min: 0 }),
  body('is_default').optional().isBoolean(),
  body('icon').optional().isString(),
  body('color').optional().isString()
], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, AccountController.updateAccount);

router.delete('/:accountId', [param('accountId').isUUID()], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, AccountController.deleteAccount);

module.exports = router;
