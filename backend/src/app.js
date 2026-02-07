const express = require('express');
const rateLimit = require('express-rate-limit');
const authRoutes = require('./routes/authRoutes');
const transactionRoutes = require('./routes/transactionRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const accountRoutes = require('./routes/accountRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const userRoutes = require('./routes/userRoutes');
const expenseRoutes = require('./routes/expenseRoutes');
const incomeRoutes = require('./routes/incomeRoutes');
const budgetRoutes = require('./routes/budgetRoutes');
const reportRoutes = require('./routes/reportRoutes');
const bankRoutes = require('./routes/bankRoutes');
const investmentRoutes = require('./routes/investmentRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const settingsRoutes = require('./routes/settingsRoutes');
const authMiddleware = require('./middleware/authMiddleware');
const securityHeaders = require('./middleware/securityHeaders');
const errorHandler = require('./middleware/errorHandler');
const logger = require('./utils/logger');
const AuthService = require('./services/AuthService');
require('dotenv').config();

const app = express();

// Security Middleware
app.disable('x-powered-by');
app.set('trust proxy', 1);
app.use(securityHeaders);

// Rate Limiting (skip in tests)
const limiter = process.env.NODE_ENV === 'test'
  ? (req, res, next) => next()
  : rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // limit each IP to 100 requests per windowMs
      message: 'Too many requests from this IP, please try again later.'
    });

const authLimiter = process.env.NODE_ENV === 'test'
  ? (req, res, next) => next()
  : rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 5, // 5 login attempts per 15 minutes
      skipSuccessfulRequests: true,
      message: 'Too many login attempts, please try again later.'
    });

app.use(limiter);

// Body Parser Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Request Logging Middleware
app.use((req, res, next) => {
  logger.info({
    method: req.method,
    path: req.path,
    timestamp: new Date().toISOString()
  });
  next();
});

// Routes
app.use('/api/v1/auth', authLimiter, authRoutes);
app.use('/api/v1/transactions', authMiddleware, transactionRoutes);
app.use('/api/v1/analytics', authMiddleware, analyticsRoutes);
app.use('/api/v1/accounts', authMiddleware, accountRoutes);
app.use('/api/v1/categories', authMiddleware, categoryRoutes);
app.use('/api/v1/users', authMiddleware, userRoutes);
app.use('/api/v1/expenses', authMiddleware, expenseRoutes);
app.use('/api/v1/income', authMiddleware, incomeRoutes);
app.use('/api/v1/budgets', authMiddleware, budgetRoutes);
app.use('/api/v1/reports', authMiddleware, reportRoutes);
app.use('/api/v1/banks', authMiddleware, bankRoutes);
app.use('/api/v1/investments', authMiddleware, investmentRoutes);
app.use('/api/v1/notifications', authMiddleware, notificationRoutes);
app.use('/api/v1/settings', authMiddleware, settingsRoutes);

// Backward-compatible /api routes
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/transactions', authMiddleware, transactionRoutes);
app.use('/api/analytics', authMiddleware, analyticsRoutes);
app.use('/api/accounts', authMiddleware, accountRoutes);
app.use('/api/categories', authMiddleware, categoryRoutes);
app.use('/api/users', authMiddleware, userRoutes);
app.use('/api/user', authMiddleware, userRoutes);
app.use('/api/expenses', authMiddleware, expenseRoutes);
app.use('/api/income', authMiddleware, incomeRoutes);
app.use('/api/budgets', authMiddleware, budgetRoutes);
app.use('/api/reports', authMiddleware, reportRoutes);
app.use('/api/banks', authMiddleware, bankRoutes);
app.use('/api/investments', authMiddleware, investmentRoutes);
app.use('/api/notifications', authMiddleware, notificationRoutes);
app.use('/api/settings', authMiddleware, settingsRoutes);

// Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error Handler
app.use(errorHandler);

// Scheduled cleanup for revoked refresh tokens
const revokedTokenCleanupIntervalMs = 24 * 60 * 60 * 1000; // 24 hours
const cleanupMetrics = {
  lastRun: null,
  lastSuccess: null,
  lastFailure: null,
  totalRuns: 0,
  successfulRuns: 0,
  failedRuns: 0,
  totalTokensDeleted: 0,
  averageCleanupMs: 0,
  lastErrorMessage: null
};

const runRevokedTokenCleanup = async () => {
  const startTime = Date.now();
  cleanupMetrics.totalRuns++;
  cleanupMetrics.lastRun = new Date().toISOString();

  try {
    const deleted = await AuthService.cleanupRevokedTokens();
    const durationMs = Date.now() - startTime;
    
    cleanupMetrics.successfulRuns++;
    cleanupMetrics.lastSuccess = new Date().toISOString();
    cleanupMetrics.totalTokensDeleted += deleted;
    cleanupMetrics.averageCleanupMs = 
      (cleanupMetrics.averageCleanupMs * (cleanupMetrics.successfulRuns - 1) + durationMs) / 
      cleanupMetrics.successfulRuns;
    cleanupMetrics.lastErrorMessage = null;

    logger.info({
      message: 'Revoked token cleanup completed successfully',
      deleted,
      durationMs,
      metrics: cleanupMetrics
    });

    // Alert if cleanup seems abnormal (0 tokens for 3+ consecutive runs)
    if (deleted === 0 && cleanupMetrics.successfulRuns > 3) {
      logger.warn({
        message: 'ALERT: No expired tokens found in cleanup',
        consecutiveZeroRuns: true,
        suggestedAction: 'Verify if tokens are being revoked properly or if system time is incorrect'
      });
    }
  } catch (error) {
    const durationMs = Date.now() - startTime;
    cleanupMetrics.failedRuns++;
    cleanupMetrics.lastFailure = new Date().toISOString();
    cleanupMetrics.lastErrorMessage = error.message;

    // CRITICAL: Cleanup failed - needs immediate attention
    logger.error({
      severity: 'CRITICAL',
      message: 'Revoked token cleanup FAILED',
      error: error.message,
      stack: error.stack,
      durationMs,
      failureCount: cleanupMetrics.failedRuns,
      metrics: cleanupMetrics
    });

    // Alert operations team if cleanup fails consecutively
    if (cleanupMetrics.failedRuns >= 2) {
      logger.error({
        severity: 'CRITICAL_ALERT',
        message: `Token cleanup has failed ${cleanupMetrics.failedRuns} consecutive times`,
        action: 'IMMEDIATE_ACTION_REQUIRED: Check database connection and revoked_tokens table integrity',
        contactOps: true
      });
    }
  }
};

// Endpoint to check cleanup metrics (admin only - add auth in production)
app.get('/admin/cleanup-metrics', (req, res) => {
  // TODO: Add proper admin authentication middleware
  res.json({
    metrics: cleanupMetrics,
    status: cleanupMetrics.failedRuns === 0 ? 'healthy' : 'degraded',
    nextScheduledRun: new Date(Date.now() + revokedTokenCleanupIntervalMs).toISOString()
  });
});

const shouldRunCleanup = process.env.NODE_ENV !== 'test' && process.env.DISABLE_TOKEN_CLEANUP !== 'true';

if (shouldRunCleanup) {
  // Run cleanup immediately on startup
  runRevokedTokenCleanup();
  // Schedule recurring cleanup every 24 hours
  setInterval(runRevokedTokenCleanup, revokedTokenCleanupIntervalMs);
}

module.exports = app;
