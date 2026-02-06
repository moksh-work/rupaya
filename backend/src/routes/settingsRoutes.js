const express = require('express');
const { body, query, validationResult } = require('express-validator');
const authMiddleware = require('../middleware/authMiddleware');
const SettingsController = require('../controllers/SettingsController');

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

// GET /api/v1/settings/security - MUST come before main /settings routes to avoid conflicts
router.get(
  '/security',
  SettingsController.getSecuritySettings
);

// GET /api/v1/settings
router.get(
  '/',
  SettingsController.getSettings
);

// PUT /api/v1/settings
router.put(
  '/',
  [
    body('theme')
      .optional()
      .isIn(['light', 'dark'])
      .withMessage('Theme must be light or dark'),
    body('language')
      .optional()
      .isIn(['en', 'es', 'fr', 'de', 'pt', 'ja', 'zh'])
      .withMessage('Invalid language'),
    body('currency')
      .optional()
      .isIn(['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'INR'])
      .withMessage('Invalid currency'),
    body('date_format')
      .optional()
      .isIn(['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'])
      .withMessage('Invalid date format'),
    body('timezone')
      .optional()
      .isLength({ min: 1, max: 50 })
      .withMessage('Invalid timezone'),
    body('notifications_enabled')
      .optional()
      .isBoolean()
      .withMessage('notifications_enabled must be a boolean'),
    body('auto_logout_minutes')
      .optional()
      .isInt({ min: 5, max: 1440 })
      .withMessage('Auto logout minutes must be between 5 and 1440'),
    body('data_retention_days')
      .optional()
      .isInt({ min: 30, max: 2555 })
      .withMessage('Data retention days must be between 30 and 2555'),
    body('privacy_level')
      .optional()
      .isIn(['private', 'friends', 'public'])
      .withMessage('Privacy level must be private, friends, or public'),
    body('allow_analytics')
      .optional()
      .isBoolean()
      .withMessage('allow_analytics must be a boolean')
  ],
  handleValidationErrors,
  SettingsController.updateSettings
);

// PUT /api/v1/settings/security
router.put(
  '/security',
  [
    body('two_factor_enabled')
      .optional()
      .isBoolean()
      .withMessage('two_factor_enabled must be a boolean'),
    body('two_factor_method')
      .optional()
      .isIn(['email', 'sms', 'authenticator'])
      .withMessage('Two-factor method must be email, sms, or authenticator'),
    body('biometric_enabled')
      .optional()
      .isBoolean()
      .withMessage('biometric_enabled must be a boolean'),
    body('login_alerts_enabled')
      .optional()
      .isBoolean()
      .withMessage('login_alerts_enabled must be a boolean'),
    body('session_timeout_minutes')
      .optional()
      .isInt({ min: 5, max: 480 })
      .withMessage('Session timeout must be between 5 and 480 minutes'),
    body('allow_remember_device')
      .optional()
      .isBoolean()
      .withMessage('allow_remember_device must be a boolean'),
    body('ip_whitelist_enabled')
      .optional()
      .isBoolean()
      .withMessage('ip_whitelist_enabled must be a boolean')
  ],
  handleValidationErrors,
  SettingsController.updateSecuritySettings
);

// POST /api/v1/settings/export-data
router.post(
  '/export-data',
  [
    body('export_type')
      .optional()
      .isIn(['full', 'expenses', 'income', 'budgets', 'transactions'])
      .withMessage('Invalid export type')
  ],
  handleValidationErrors,
  SettingsController.exportData
);

// GET /api/v1/settings/export-data - Get export history
router.get(
  '/export-data',
  [
    query('limit')
      .optional()
      .isInt({ min: 1, max: 50 })
      .withMessage('Limit must be between 1 and 50'),
    query('offset')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Offset must be a non-negative integer')
  ],
  handleValidationErrors,
  SettingsController.getExportHistory
);

// POST /api/v1/settings/request-data-access
router.post(
  '/request-data-access',
  [
    body('reason')
      .notEmpty()
      .withMessage('Reason is required')
      .isLength({ min: 10, max: 500 })
      .withMessage('Reason must be between 10 and 500 characters')
  ],
  handleValidationErrors,
  SettingsController.requestDataAccess
);

// GET /api/v1/settings/data-access-requests - Get access requests
router.get(
  '/data-access-requests',
  [
    query('limit')
      .optional()
      .isInt({ min: 1, max: 50 })
      .withMessage('Limit must be between 1 and 50'),
    query('offset')
      .optional()
      .isInt({ min: 0 })
      .withMessage('Offset must be a non-negative integer')
  ],
  handleValidationErrors,
  SettingsController.getAccessRequests
);

module.exports = router;
