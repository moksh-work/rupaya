const helmet = require('helmet');
const cors = require('cors');

const securityHeaders = (req, res, next) => {
  const corsOptions = {
    origin: process.env.FRONTEND_URL || 'http://localhost:3000',
    credentials: true,
    optionsSuccessStatus: 200
  };

  helmet()(req, res, (helmetErr) => {
    if (helmetErr) {
      return next(helmetErr);
    }
    return cors(corsOptions)(req, res, next);
  });
};

module.exports = securityHeaders;
