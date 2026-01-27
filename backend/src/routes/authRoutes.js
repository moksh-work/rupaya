const express = require('express');
const { body, validationResult } = require('express-validator');
const AuthService = require('../services/AuthService');
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

    res.json({
      userId: result.userId,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      user: result.user
    });
  } catch (error) {
    logger.error({ error: error.message });
    res.status(400).json({ error: error.message });
  }
});

// Signin
router.post('/signin', [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
  body('deviceId').notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, deviceId } = req.body;

    const result = await AuthService.signin(email, password, deviceId);

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

module.exports = router;
