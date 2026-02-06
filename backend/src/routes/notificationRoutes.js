const express = require('express');
const { param, query, body, validationResult } = require('express-validator');
const authMiddleware = require('../middleware/authMiddleware');
const NotificationController = require('../controllers/NotificationController');

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

// GET /api/v1/notifications/preferences - MUST come before /{id}
router.get(
  '/preferences',
  NotificationController.getPreferences
);

// GET /api/v1/notifications
router.get(
  '/',
  [
    query('type')
      .optional()
      .isIn(['expense', 'income', 'budget_alert', 'goal_reached', 'investment_update', 'bank_sync', 'general'])
      .withMessage('Invalid notification type'),
    query('is_read')
      .optional()
      .isIn(['true', 'false'])
      .withMessage('is_read must be true or false'),
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
  NotificationController.getNotifications
);

// PUT /api/v1/notifications/mark-all-read - MUST come before /{id}
router.put(
  '/mark-all-read',
  NotificationController.markAllAsRead
);

// PUT /api/v1/notifications/{id}/read
router.put(
  '/:id/read',
  [
    param('id')
      .isInt()
      .withMessage('Notification ID must be an integer')
  ],
  handleValidationErrors,
  NotificationController.markAsRead
);

// DELETE /api/v1/notifications/{id}
router.delete(
  '/:id',
  [
    param('id')
      .isInt()
      .withMessage('Notification ID must be an integer')
  ],
  handleValidationErrors,
  NotificationController.deleteNotification
);

// PUT /api/v1/notifications/preferences
router.put(
  '/preferences',
  [
    body('email_on_expense')
      .optional()
      .isBoolean()
      .withMessage('email_on_expense must be a boolean'),
    body('email_on_income')
      .optional()
      .isBoolean()
      .withMessage('email_on_income must be a boolean'),
    body('email_on_budget_alert')
      .optional()
      .isBoolean()
      .withMessage('email_on_budget_alert must be a boolean'),
    body('email_on_goal_reached')
      .optional()
      .isBoolean()
      .withMessage('email_on_goal_reached must be a boolean'),
    body('email_on_investment_update')
      .optional()
      .isBoolean()
      .withMessage('email_on_investment_update must be a boolean'),
    body('email_on_bank_sync')
      .optional()
      .isBoolean()
      .withMessage('email_on_bank_sync must be a boolean'),
    body('push_on_expense')
      .optional()
      .isBoolean()
      .withMessage('push_on_expense must be a boolean'),
    body('push_on_income')
      .optional()
      .isBoolean()
      .withMessage('push_on_income must be a boolean'),
    body('push_on_budget_alert')
      .optional()
      .isBoolean()
      .withMessage('push_on_budget_alert must be a boolean'),
    body('push_on_goal_reached')
      .optional()
      .isBoolean()
      .withMessage('push_on_goal_reached must be a boolean'),
    body('push_on_investment_update')
      .optional()
      .isBoolean()
      .withMessage('push_on_investment_update must be a boolean'),
    body('push_on_bank_sync')
      .optional()
      .isBoolean()
      .withMessage('push_on_bank_sync must be a boolean'),
    body('in_app_notifications')
      .optional()
      .isBoolean()
      .withMessage('in_app_notifications must be a boolean'),
    body('daily_digest')
      .optional()
      .isBoolean()
      .withMessage('daily_digest must be a boolean'),
    body('weekly_report')
      .optional()
      .isBoolean()
      .withMessage('weekly_report must be a boolean'),
    body('monthly_report')
      .optional()
      .isBoolean()
      .withMessage('monthly_report must be a boolean'),
    body('quiet_hours_enabled')
      .optional()
      .isBoolean()
      .withMessage('quiet_hours_enabled must be a boolean'),
    body('quiet_hours_start')
      .optional()
      .matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/)
      .withMessage('quiet_hours_start must be in HH:MM format'),
    body('quiet_hours_end')
      .optional()
      .matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/)
      .withMessage('quiet_hours_end must be in HH:MM format')
  ],
  handleValidationErrors,
  NotificationController.updatePreferences
);

module.exports = router;
