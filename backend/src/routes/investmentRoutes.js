const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const authMiddleware = require('../middleware/authMiddleware');
const InvestmentController = require('../controllers/InvestmentController');

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

// POST /api/v1/investments
router.post(
  '/',
  [
    body('investment_type')
      .notEmpty()
      .withMessage('Investment type is required')
      .isIn(['stock', 'bond', 'mutual_fund', 'etf', 'crypto', 'real_estate', 'commodity', 'other'])
      .withMessage('Investment type must be stock, bond, mutual_fund, etf, crypto, real_estate, commodity, or other'),
    body('name')
      .notEmpty()
      .withMessage('Investment name is required')
      .isLength({ min: 1, max: 100 })
      .withMessage('Investment name must be between 1 and 100 characters'),
    body('symbol')
      .optional()
      .isLength({ max: 20 })
      .withMessage('Symbol must not exceed 20 characters'),
    body('quantity')
      .notEmpty()
      .withMessage('Quantity is required')
      .isFloat({ min: 0.00001 })
      .withMessage('Quantity must be a positive number'),
    body('purchase_price')
      .notEmpty()
      .withMessage('Purchase price is required')
      .isFloat({ min: 0.01 })
      .withMessage('Purchase price must be a positive number'),
    body('current_price')
      .notEmpty()
      .withMessage('Current price is required')
      .isFloat({ min: 0.01 })
      .withMessage('Current price must be a positive number'),
    body('purchase_date')
      .notEmpty()
      .withMessage('Purchase date is required')
      .isISO8601()
      .withMessage('Purchase date must be in ISO8601 format'),
    body('notes')
      .optional()
      .isLength({ max: 500 })
      .withMessage('Notes must not exceed 500 characters')
  ],
  handleValidationErrors,
  InvestmentController.createInvestment
);

// GET /api/v1/investments/portfolio - MUST come before /:id to avoid param collision
router.get(
  '/portfolio',
  InvestmentController.getPortfolioSummary
);

// GET /api/v1/investments
router.get(
  '/',
  [
    query('investment_type')
      .optional()
      .isIn(['stock', 'bond', 'mutual_fund', 'etf', 'crypto', 'real_estate', 'commodity', 'other'])
      .withMessage('Invalid investment type'),
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
  InvestmentController.getInvestments
);

// GET /api/v1/investments/{id}
router.get(
  '/:id',
  [
    param('id')
      .isInt()
      .withMessage('Investment ID must be an integer')
  ],
  handleValidationErrors,
  InvestmentController.getInvestment
);

// PUT /api/v1/investments/{id}
router.put(
  '/:id',
  [
    param('id')
      .isInt()
      .withMessage('Investment ID must be an integer'),
    body('name')
      .optional()
      .isLength({ min: 1, max: 100 })
      .withMessage('Investment name must be between 1 and 100 characters'),
    body('quantity')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('Quantity must be a non-negative number'),
    body('current_price')
      .optional()
      .isFloat({ min: 0.01 })
      .withMessage('Current price must be a positive number'),
    body('notes')
      .optional()
      .isLength({ max: 500 })
      .withMessage('Notes must not exceed 500 characters')
  ],
  handleValidationErrors,
  InvestmentController.updateInvestment
);

// DELETE /api/v1/investments/{id}
router.delete(
  '/:id',
  [
    param('id')
      .isInt()
      .withMessage('Investment ID must be an integer')
  ],
  handleValidationErrors,
  InvestmentController.deleteInvestment
);

module.exports = router;
