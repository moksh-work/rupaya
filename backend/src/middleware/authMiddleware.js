const jwt = require('jsonwebtoken');
const AuthService = require('../services/AuthService');

const authMiddleware = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = await AuthService.verifyToken(token);
    const normalizedUserId = decoded.userId || decoded.user_id || decoded.id || null;

    req.user = {
      ...decoded,
      id: normalizedUserId,
      userId: normalizedUserId,
      user_id: normalizedUserId
    };

    if (!req.user.userId) {
      return res.status(401).json({ error: 'Invalid token payload' });
    }

    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

module.exports = authMiddleware;
