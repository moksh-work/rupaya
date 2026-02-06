const Category = require('../models/Category');

class CategoryService {
  async createCategory(userId, data) {
    if (!data.name) {
      throw new Error('Category name is required');
    }

    if (!data.category_type) {
      throw new Error('Category type is required (expense, income)');
    }

    const validTypes = ['expense', 'income'];
    if (!validTypes.includes(data.category_type)) {
      throw new Error(`Category type must be one of: ${validTypes.join(', ')}`);
    }

    return await Category.create(userId, data);
  }

  async getCategories(userId, filters) {
    return await Category.list(userId, filters);
  }

  async getCategory(categoryId, userId) {
    const category = await Category.findById(categoryId);
    if (!category) {
      throw new Error('Category not found');
    }

    if (category.user_id !== userId && !category.is_system) {
      throw new Error('Unauthorized');
    }

    return category;
  }

  async updateCategory(categoryId, userId, data) {
    const category = await Category.findById(categoryId);
    if (!category) {
      throw new Error('Category not found');
    }

    if (category.user_id !== userId && !category.is_system) {
      throw new Error('Unauthorized');
    }

    if (category.is_system && data.name !== undefined) {
      throw new Error('Cannot modify system category name');
    }

    const result = await Category.update(categoryId, userId, data);
    if (!result) {
      throw new Error('Failed to update category');
    }

    return result;
  }

  async deleteCategory(categoryId, userId) {
    const category = await Category.findById(categoryId);
    if (!category) {
      throw new Error('Category not found');
    }

    if (category.is_system) {
      throw new Error('Cannot delete system category');
    }

    if (category.user_id !== userId) {
      throw new Error('Unauthorized');
    }

    const result = await Category.softDelete(categoryId, userId);
    if (result === 0) {
      throw new Error('Failed to delete category');
    }

    return { success: true, message: 'Category deleted successfully' };
  }

  async getStatistics(categoryId, userId, startDate, endDate) {
    if (!startDate || !endDate) {
      throw new Error('Start date and end date are required');
    }

    const category = await Category.findById(categoryId);
    if (!category) {
      throw new Error('Category not found');
    }

    if (category.user_id !== userId && !category.is_system) {
      throw new Error('Unauthorized');
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    if (start > end) {
      throw new Error('Start date must be before end date');
    }

    return await Category.getStatistics(categoryId, userId, start, end);
  }
}

module.exports = new CategoryService();
