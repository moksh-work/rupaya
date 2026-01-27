const logger = require('../utils/logger');

const errorHandler = (error, req, res, next) => {
  logger.error({
    message: error.message,
    stack: error.stack,
    url: req.originalUrl,
    method: req.method
  });

  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : undefined
  });
};

module.exports = errorHandler;
