const express = require('express');
const { body, validationResult } = require('express-validator');
const multer = require('multer');
const UserController = require('../controllers/UserController');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

// GET /api/v1/users/profile
router.get('/profile', UserController.getProfile);

// PUT /api/v1/users/profile
router.put('/profile', [
  body('name').optional().isString().isLength({ min: 1, max: 100 }),
  body('phoneNumber').optional().matches(/^[0-9+\-]{8,15}$/),
  body('countryCode').optional().isLength({ min: 2, max: 2 }),
  body('currencyPreference').optional().isLength({ min: 3, max: 3 })
], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, UserController.updateProfile);

// PUT /api/v1/users/change-password
router.put('/change-password', [
  body('currentPassword').notEmpty().isString(),
  body('newPassword')
    .isLength({ min: 12 })
    .withMessage('Password must be at least 12 characters')
    .matches(/[A-Z]/)
    .withMessage('Password must contain uppercase letter')
    .matches(/[a-z]/)
    .withMessage('Password must contain lowercase letter')
    .matches(/[0-9]/)
    .withMessage('Password must contain number')
    .matches(/[!@#$%^&*]/)
    .withMessage('Password must contain special character')
], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, UserController.changePassword);

// POST /api/v1/users/profile-picture
router.post('/profile-picture', upload.single('profilePicture'), [
  (req, res, next) => {
    if (!req.file) {
      return res.status(400).json({ error: 'No profile picture provided' });
    }
    const validMimes = ['image/jpeg', 'image/png', 'image/webp'];
    if (!validMimes.includes(req.file.mimetype)) {
      return res.status(400).json({ error: 'Invalid file type. Only JPEG, PNG, WebP allowed' });
    }
    next();
  }
], UserController.uploadProfilePicture);

// DELETE /api/v1/users/delete-account
router.delete('/delete-account', [
  body('password').notEmpty().isString().withMessage('Password is required for account deletion')
], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, UserController.deleteAccount);

// GET /api/v1/users/preferences
router.get('/preferences', UserController.getPreferences);

// PUT /api/v1/users/preferences
router.put('/preferences', [
  body('currency').optional().isLength({ min: 3, max: 3 }),
  body('timezone').optional().isString(),
  body('language').optional().isString().isLength({ min: 2, max: 5 }),
  body('theme').optional().isIn(['light', 'dark', 'system'])
], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, UserController.updatePreferences);

module.exports = router;
