const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const authMiddleware = require('../middleware/authMiddleware');
const BankController = require('../controllers/BankController');

const router = express.Router();

// Middleware: All routes require authentication
router.use(authMiddleware);

// Error handler for validation
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array()
    });
  }
  next();
};

// POST /api/v1/banks/connect
router.post(
  '/connect',
  [
    body('bank_provider')
      .notEmpty()
      .withMessage('Bank provider is required')
      .isIn(['plaid', 'yodlee', 'fintech-api', 'open-banking'])
      .withMessage('Bank provider must be plaid, yodlee, fintech-api, or open-banking'),
    body('redirect_uri')
      .notEmpty()
      .withMessage('Redirect URI is required')
      .isURL()
      .withMessage('Redirect URI must be a valid URL')
  ],
  handleValidationErrors,
  BankController.connectBank
);

// POST /api/v1/banks/callback
router.post(
  '/callback',
  [
    body('code')
      .notEmpty()
      .withMessage('Authorization code is required'),
    body('state')
      .notEmpty()
      .withMessage('State parameter is required'),
    body('bank_provider')
      .notEmpty()
      .withMessage('Bank provider is required')
      .isIn(['plaid', 'yodlee', 'fintech-api', 'open-banking'])
      .withMessage('Bank provider must be plaid, yodlee, fintech-api, or open-banking')
  ],
  handleValidationErrors,
  BankController.handleCallback
);

// GET /api/v1/banks/accounts
router.get(
  '/accounts',
  BankController.getConnectedAccounts
);

// POST /api/v1/banks/accounts/{id}/sync
router.post(
  '/accounts/:id/sync',
  [
    param('id')
      .isInt()
      .withMessage('Bank account ID must be an integer')
  ],
  handleValidationErrors,
  BankController.syncTransactions
);

// GET /api/v1/banks/accounts/{id}/transactions
router.get(
  '/accounts/:id/transactions',
  [
    param('id')
      .isInt()
      .withMessage('Bank account ID must be an integer'),
    query('limit')
      .optional()
      .isInt({ min: 1, max: 100 })
      .withMessage('Limit must be between 1 and 100'),
    query('offset')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Offset must be a non-negative integer')
  ],
  handleValidationErrors,
  BankController.getBankTransactions
);

// PUT /api/v1/banks/transactions/{id}/category
router.put(
  '/transactions/:id/category',
  [
    param('id')
      .isInt()
      .withMessage('Transaction ID must be an integer'),
    body('bank_account_id')
      .notEmpty()
      .withMessage('Bank account ID is required')
      .isInt()
      .withMessage('Bank account ID must be an integer'),
    body('category_id')
      .notEmpty()
      .withMessage('Category ID is required')
      .isInt()
      .withMessage('Category ID must be an integer')
  ],
  handleValidationErrors,
  BankController.categorizeTransaction
);

// DELETE /api/v1/banks/accounts/{id}
router.delete(
  '/accounts/:id',
  [
    param('id')
      .isInt()
      .withMessage('Bank account ID must be an integer')
  ],
  handleValidationErrors,
  BankController.disconnectBankAccount
);

// GET /api/v1/banks/accounts/{id}/balance
router.get(
  '/accounts/:id/balance',
  [
    param('id')
      .isInt()
      .withMessage('Bank account ID must be an integer')
  ],
  handleValidationErrors,
  BankController.getBalance
);

module.exports = router;
