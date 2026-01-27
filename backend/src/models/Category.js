const db = require('../config/database');

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
}

module.exports = Category;
