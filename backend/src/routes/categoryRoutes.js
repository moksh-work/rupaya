const express = require('express');
const { query, validationResult } = require('express-validator');
const CategoryController = require('../controllers/CategoryController');

const router = express.Router();

router.get('/', [query('type').optional().isIn(['income', 'expense', 'transfer'])], (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}, CategoryController.listCategories);

module.exports = router;
