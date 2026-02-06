const CategoryService = require('../services/CategoryService');
const asyncHandler = require('../middleware/asyncHandler');

const CategoryController = {
  createCategory: asyncHandler(async (req, res) => {
    const { name, description, category_type, color, icon } = req.body;

    const category = await CategoryService.createCategory(req.user.user_id, {
      name,
      description,
      category_type,
      color,
      icon
    });

    res.status(201).json({
      success: true,
      message: 'Category created successfully',
      data: category
    });
  }),

  listCategories: asyncHandler(async (req, res) => {
    const { type, isActive, limit = 100, offset = 0 } = req.query;

    const filters = {
      type,
      isActive: isActive === 'true' ? true : isActive === 'false' ? false : undefined,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };

    const result = await CategoryService.getCategories(req.user.user_id, filters);

    res.status(200).json({
      success: true,
      data: result
    });
  }),

  getCategory: asyncHandler(async (req, res) => {
    const { id } = req.params;

    const category = await CategoryService.getCategory(id, req.user.user_id);

    res.status(200).json({
      success: true,
      data: category
    });
  }),

  updateCategory: asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { name, description, color, icon, is_active } = req.body;

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (color !== undefined) updateData.color = color;
    if (icon !== undefined) updateData.icon = icon;
    if (is_active !== undefined) updateData.is_active = is_active;

    const category = await CategoryService.updateCategory(id, req.user.user_id, updateData);

    res.status(200).json({
      success: true,
      message: 'Category updated successfully',
      data: category
    });
  }),

  deleteCategory: asyncHandler(async (req, res) => {
    const { id } = req.params;

    const result = await CategoryService.deleteCategory(id, req.user.user_id);

    res.status(200).json(result);
  }),

  getStatistics: asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { startDate, endDate } = req.query;

    const statistics = await CategoryService.getStatistics(id, req.user.user_id, startDate, endDate);

    res.status(200).json({
      success: true,
      data: statistics
    });
  })
};

module.exports = CategoryController;
