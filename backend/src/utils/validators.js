const logger = require('../utils/logger');

const sanitizeInput = (input) => {
  if (typeof input === 'string') {
    return input.trim().replace(/[<>\"']/g, '');
  }
  return input;
};

const validateEmail = (email) => {
  const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$/;
  return emailRegex.test(email);
};

const validatePassword = (password) => {
  // At least 12 characters, 1 uppercase, 1 lowercase, 1 number, 1 special char
  const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).{12,}$/;
  return passwordRegex.test(password);
};

const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = {
  sanitizeInput,
  validateEmail,
  validatePassword,
  asyncHandler,
  logger
};
