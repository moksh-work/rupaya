const db = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class Category {
  static async listForUser(userId, type) {
    let query = db('categories').where(builder => {
      builder.where({ is_system: true });
      if (userId) {
        builder.orWhere({ user_id: userId });
      }
    });

    if (type) {
      query = query.andWhere({ category_type: type });
    }

    return query.orderBy('name', 'asc');
  }

  static async findById(categoryId) {
    return db('categories').where({ category_id: categoryId }).first();
  }

  static async create(userId, data) {
    const record = {
      category_id: uuidv4(),
      user_id: userId,
      name: data.name,
      description: data.description || null,
      category_type: data.category_type,
      color: data.color || '#808080',
      icon: data.icon || 'tag',
      is_system: false,
      is_active: data.is_active !== false,
      is_deleted: false,
      created_at: new Date(),
      updated_at: new Date()
    };

    const result = await db('categories').insert(record).returning('*');
    return result[0];
  }

  static async list(userId, filters = {}) {
    let query = db('categories')
      .where(builder => {
        builder.where({ is_system: true, is_deleted: false });
        builder.orWhere({ user_id: userId, is_deleted: false });
      });

    if (filters.type) {
      query = query.andWhere({ category_type: filters.type });
    }

    if (filters.isActive !== undefined) {
      query = query.andWhere({ is_active: filters.isActive });
    }

    const limit = filters.limit || 100;
    const offset = filters.offset || 0;

    const results = await query
      .orderBy('name', 'asc')
      .limit(limit)
      .offset(offset);

    const countQuery = db('categories')
      .where(builder => {
        builder.where({ is_system: true, is_deleted: false });
        builder.orWhere({ user_id: userId, is_deleted: false });
      });

    if (filters.type) countQuery.andWhere({ category_type: filters.type });
    if (filters.isActive !== undefined) countQuery.andWhere({ is_active: filters.isActive });

    const [{ count }] = await countQuery.count('* as count');

    return {
      categories: results,
      total: parseInt(count),
      limit,
      offset
    };
  }

  static async update(categoryId, userId, data) {
    const category = await this.findById(categoryId);
    if (!category || (category.user_id !== userId && !category.is_system)) {
      return null;
    }

    const updateData = {
      ...data,
      updated_at: new Date()
    };

    const result = await db('categories')
      .where({ category_id: categoryId })
      .update(updateData)
      .returning('*');

    return result.length > 0 ? result[0] : null;
  }

  static async softDelete(categoryId, userId) {
    const category = await this.findById(categoryId);
    if (!category || (category.user_id !== userId && !category.is_system)) {
      return 0;
    }

    return await db('categories')
      .where({ category_id: categoryId })
      .update({ is_deleted: true, updated_at: new Date() });
  }

  static async getStatistics(categoryId, userId, startDate, endDate) {
    const expenseTotal = await db('expenses')
      .where({ category_id: categoryId, user_id: userId, is_deleted: false })
      .whereBetween('expense_date', [startDate, endDate])
      .sum('amount as total')
      .first();

    const incomeTotal = await db('income')
      .where({ category_id: categoryId, user_id: userId, is_deleted: false })
      .whereBetween('income_date', [startDate, endDate])
      .sum('amount as total')
      .first();

    const expenseCount = await db('expenses')
      .where({ category_id: categoryId, user_id: userId, is_deleted: false })
      .whereBetween('expense_date', [startDate, endDate])
      .count('* as count')
      .first();

    const incomeCount = await db('income')
      .where({ category_id: categoryId, user_id: userId, is_deleted: false })
      .whereBetween('income_date', [startDate, endDate])
      .count('* as count')
      .first();

    return {
      category_id: categoryId,
      expenses: {
        total: parseFloat(expenseTotal.total) || 0,
        count: parseInt(expenseCount.count) || 0,
        average: expenseCount.count > 0 ? (parseFloat(expenseTotal.total) || 0) / parseInt(expenseCount.count) : 0
      },
      income: {
        total: parseFloat(incomeTotal.total) || 0,
        count: parseInt(incomeCount.count) || 0,
        average: incomeCount.count > 0 ? (parseFloat(incomeTotal.total) || 0) / parseInt(incomeCount.count) : 0
      },
      net: (parseFloat(incomeTotal.total) || 0) - (parseFloat(expenseTotal.total) || 0),
      startDate,
      endDate
    };
  }
}

module.exports = Category;
