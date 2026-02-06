const db = require('../config/database');

class Investment {
  static async create(userId, data) {
    const {
      investment_type,
      symbol,
      name,
      quantity,
      purchase_price,
      current_price,
      purchase_date,
      notes
    } = data;

    const [investmentId] = await db('investments').insert({
      user_id: userId,
      investment_type,
      symbol,
      name,
      quantity,
      purchase_price,
      current_price,
      purchase_date,
      notes,
      is_deleted: false,
      created_at: new Date(),
      updated_at: new Date()
    });

    return this.findById(investmentId);
  }

  static async findById(id) {
    return await db('investments')
      .where({ investment_id: id, is_deleted: false })
      .first();
  }

  static async findByUserAndId(userId, id) {
    return await db('investments')
      .where({ user_id: userId, investment_id: id, is_deleted: false })
      .first();
  }

  static async list(userId, filters = {}) {
    const { investment_type, limit = 50, offset = 0 } = filters;

    let query = db('investments').where({ user_id: userId, is_deleted: false });

    if (investment_type) {
      query = query.where({ investment_type });
    }

    const investments = await query
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);

    const totalResult = await db('investments')
      .where({ user_id: userId, is_deleted: false })
      .count('* as total')
      .first();

    return {
      total: totalResult.total,
      limit,
      offset,
      investments
    };
  }

  static async update(id, data) {
    const {
      name,
      quantity,
      current_price,
      notes
    } = data;

    const updateData = {
      updated_at: new Date()
    };

    if (name !== undefined) updateData.name = name;
    if (quantity !== undefined) updateData.quantity = quantity;
    if (current_price !== undefined) updateData.current_price = current_price;
    if (notes !== undefined) updateData.notes = notes;

    await db('investments')
      .where({ investment_id: id })
      .update(updateData);

    return this.findById(id);
  }

  static async softDelete(id) {
    await db('investments')
      .where({ investment_id: id })
      .update({
        is_deleted: true,
        updated_at: new Date()
      });
  }

  static async getPortfolioSummary(userId) {
    const investments = await db('investments')
      .where({ user_id: userId, is_deleted: false })
      .select('*');

    let totalInvested = 0;
    let totalCurrentValue = 0;
    const byType = {};

    for (const investment of investments) {
      const invested = investment.quantity * investment.purchase_price;
      const currentValue = investment.quantity * investment.current_price;
      const gain = currentValue - invested;

      totalInvested += invested;
      totalCurrentValue += currentValue;

      if (!byType[investment.investment_type]) {
        byType[investment.investment_type] = {
          type: investment.investment_type,
          count: 0,
          invested: 0,
          current_value: 0,
          gain: 0
        };
      }

      byType[investment.investment_type].count += 1;
      byType[investment.investment_type].invested += invested;
      byType[investment.investment_type].current_value += currentValue;
      byType[investment.investment_type].gain += gain;
    }

    const totalGain = totalCurrentValue - totalInvested;
    const gainPercentage = totalInvested > 0 ? (totalGain / totalInvested) * 100 : 0;

    return {
      total_invested: totalInvested,
      total_current_value: totalCurrentValue,
      total_gain: totalGain,
      gain_percentage: Math.round(gainPercentage * 100) / 100,
      total_investments: investments.length,
      by_type: Object.values(byType),
      investments: investments.map(inv => ({
        ...inv,
        invested_value: inv.quantity * inv.purchase_price,
        current_value: inv.quantity * inv.current_price,
        gain: (inv.quantity * inv.current_price) - (inv.quantity * inv.purchase_price),
        gain_percentage: Math.round((((inv.quantity * inv.current_price) - (inv.quantity * inv.purchase_price)) / (inv.quantity * inv.purchase_price)) * 100 * 100) / 100
      }))
    };
  }

  static async getByType(userId, investmentType) {
    return await db('investments')
      .where({ user_id: userId, investment_type: investmentType, is_deleted: false })
      .orderBy('created_at', 'desc');
  }

  static async getTotalByType(userId) {
    const results = await db('investments')
      .where({ user_id: userId, is_deleted: false })
      .groupBy('investment_type')
      .select('investment_type', db.raw('count(*) as count'), db.raw('sum(quantity * current_price) as total_value'));

    return results;
  }
}

module.exports = Investment;
