const express = require('express');
const { query, validationResult } = require('express-validator');
const AnalyticsController = require('../controllers/AnalyticsController');

const router = express.Router();

router.get('/dashboard', [query('period').optional().isIn(['week', 'month', 'year'])], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, AnalyticsController.getDashboard);

router.get('/budget-progress', AnalyticsController.getBudgetProgress);

module.exports = router;
