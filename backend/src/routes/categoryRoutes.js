const express = require('express');
const { body, query, param, validationResult } = require('express-validator');
const CategoryController = require('../controllers/CategoryController');

const router = express.Router();

const validationErrorHandler = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

// POST /api/v1/categories - Create category
router.post('/', [
  body('name').notEmpty().isString().isLength({ min: 1, max: 50 }).withMessage('Name is required and max 50 chars'),
  body('description').optional().isString().isLength({ max: 200 }),
  body('category_type').notEmpty().isIn(['expense', 'income']).withMessage('Category type must be expense or income'),
  body('color').optional().isString().matches(/^#[0-9A-Fa-f]{6}$/).withMessage('Color must be hex format'),
  body('icon').optional().isString().isLength({ max: 50 })
], validationErrorHandler, CategoryController.createCategory);

// GET /api/v1/categories - List categories
router.get('/', [
  query('type').optional().isIn(['expense', 'income']),
  query('isActive').optional().isIn(['true', 'false']),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 })
], validationErrorHandler, CategoryController.listCategories);

// GET /api/v1/categories/{id}/statistics - Get statistics (must come before /{id})
router.get('/:id/statistics', [
  param('id').isString().withMessage('Category ID must be a string'),
  query('startDate').notEmpty().isISO8601().withMessage('Start date is required'),
  query('endDate').notEmpty().isISO8601().withMessage('End date is required')
], validationErrorHandler, CategoryController.getStatistics);

// GET /api/v1/categories/{id} - Get single category
router.get('/:id', [
  param('id').isString().withMessage('Category ID must be a string')
], validationErrorHandler, CategoryController.getCategory);

// PUT /api/v1/categories/{id} - Update category
router.put('/:id', [
  param('id').isString().withMessage('Category ID must be a string'),
  body('name').optional().isString().isLength({ min: 1, max: 50 }),
  body('description').optional().isString().isLength({ max: 200 }),
  body('color').optional().isString().matches(/^#[0-9A-Fa-f]{6}$/),
  body('icon').optional().isString().isLength({ max: 50 }),
  body('is_active').optional().isBoolean()
], validationErrorHandler, CategoryController.updateCategory);

// DELETE /api/v1/categories/{id} - Delete category
router.delete('/:id', [
  param('id').isString().withMessage('Category ID must be a string')
], validationErrorHandler, CategoryController.deleteCategory);

module.exports = router;
