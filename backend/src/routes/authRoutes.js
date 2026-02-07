const express = require('express');
const { body, validationResult } = require('express-validator');
const AuthService = require('../services/AuthService');
const authMiddleware = require('../middleware/authMiddleware');
const logger = require('../utils/logger');

const router = express.Router();

// Signup
router.post('/signup', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 12 }),
  body('deviceId').notEmpty(),
  body('deviceName').notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, deviceId, deviceName } = req.body;

    const result = await AuthService.signup(email, password, deviceId, deviceName);

    res.status(201).json({
      userId: result.userId,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      token: result.accessToken,
      user: result.user
    });
  } catch (error) {
    logger.error({ error: error.message });
    const status = error.message && error.message.toLowerCase().includes('already exists') ? 409 : 400;
    res.status(status).json({ error: error.message });
  }
});

// Request OTP for phone-based auth
router.post('/otp/request', [
  body('phoneNumber').matches(/^[0-9+\-]{8,15}$/),
  body('purpose').optional().isIn(['signup', 'signin'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { phoneNumber, purpose = 'signup' } = req.body;
    const result = await AuthService.requestPhoneOtp(phoneNumber, purpose);
    res.json(result);
  } catch (error) {
    logger.error({ error: error.message });
    res.status(400).json({ error: error.message });
  }
});

// Signup with phone + OTP
router.post('/signup-phone', [
  body('email').isEmail().normalizeEmail(),
  body('phoneNumber').matches(/^[0-9+\-]{8,15}$/),
  body('otp').isLength({ min: 4, max: 6 }),
  body('deviceId').notEmpty(),
  body('deviceName').notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, phoneNumber, otp, deviceId, deviceName, name } = req.body;
    const result = await AuthService.signupWithPhone(email, phoneNumber, otp, deviceId, deviceName, name);
    res.json(result);
  } catch (error) {
    logger.error({ error: error.message });
    res.status(400).json({ error: error.message });
  }
});

// Signin
const signinHandler = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, deviceId } = req.body;

    const result = await AuthService.signin(email, password, deviceId);

    res.json({
      ...result,
      token: result.accessToken
    });
  } catch (error) {
    logger.error({ error: error.message });
    res.status(401).json({ error: error.message });
  }
};

router.post('/signin', [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
  body('deviceId').notEmpty()
], signinHandler);

// Backward-compatible login alias
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
  body('deviceId').notEmpty()
], signinHandler);

// Signin with phone + OTP
router.post('/signin-phone', [
  body('phoneNumber').matches(/^[0-9+\-]{8,15}$/),
  body('otp').isLength({ min: 4, max: 6 }),
  body('deviceId').notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { phoneNumber, otp, deviceId } = req.body;
    const result = await AuthService.signinWithPhone(phoneNumber, otp, deviceId);
    res.json(result);
  } catch (error) {
    logger.error({ error: error.message });
    res.status(401).json({ error: error.message });
  }
});

// Refresh Token
router.post('/refresh', [
  body('refreshToken').notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { refreshToken } = req.body;

    const newAccessToken = await AuthService.refreshAccessToken(refreshToken);

    res.json({
      accessToken: newAccessToken,
      refreshToken
    });
  } catch (error) {
    logger.error({ error: error.message });
    res.status(401).json({ error: error.message });
  }
});

// MFA Setup
router.post('/mfa/setup', async (req, res) => {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const mfaSetup = await AuthService.setupMFA(userId);

    res.json(mfaSetup);
  } catch (error) {
    logger.error({ error: error.message });
    res.status(400).json({ error: error.message });
  }
});

// MFA Verify
router.post('/mfa/verify', [
  body('token').isLength({ min: 6, max: 6 }),
  body('deviceId').notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = req.user?.userId;
    const { token, deviceId } = req.body;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    await AuthService.verifyMFA(userId, token);

    const accessToken = AuthService.generateAccessToken(userId, deviceId);
    const refreshToken = AuthService.generateRefreshToken(userId, deviceId);

    res.json({
      accessToken,
      refreshToken
    });
  } catch (error) {
    logger.error({ error: error.message });
    res.status(400).json({ error: error.message });
  }
});

// Logout
router.post('/logout', authMiddleware, [
  body('refreshToken').optional().notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { refreshToken } = req.body || {};
    if (refreshToken) {
      await AuthService.revokeRefreshToken(refreshToken);
    }

    res.json({ message: 'Logged out' });
  } catch (error) {
    logger.error({ error: error.message });
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
