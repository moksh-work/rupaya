const Investment = require('../models/Investment');

class InvestmentService {
  static async createInvestment(userId, data) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const {
      investment_type,
      symbol,
      name,
      quantity,
      purchase_price,
      current_price,
      purchase_date
    } = data;

    if (!investment_type || !name || !quantity || !purchase_price || !current_price || !purchase_date) {
      throw new Error('Investment type, name, quantity, purchase price, current price, and purchase date are required');
    }

    const validTypes = ['stock', 'bond', 'mutual_fund', 'etf', 'crypto', 'real_estate', 'commodity', 'other'];
    if (!validTypes.includes(investment_type)) {
      throw new Error(`Investment type must be one of: ${validTypes.join(', ')}`);
    }

    const quantityNum = parseFloat(quantity);
    const purchasePriceNum = parseFloat(purchase_price);
    const currentPriceNum = parseFloat(current_price);

    if (isNaN(quantityNum) || quantityNum <= 0) {
      throw new Error('Quantity must be a positive number');
    }

    if (isNaN(purchasePriceNum) || purchasePriceNum <= 0) {
      throw new Error('Purchase price must be a positive number');
    }

    if (isNaN(currentPriceNum) || currentPriceNum <= 0) {
      throw new Error('Current price must be a positive number');
    }

    const purchaseDate = new Date(purchase_date);
    if (isNaN(purchaseDate)) {
      throw new Error('Purchase date must be a valid date');
    }

    return await Investment.create(userId, {
      investment_type,
      symbol: symbol || null,
      name,
      quantity: quantityNum,
      purchase_price: purchasePriceNum,
      current_price: currentPriceNum,
      purchase_date: purchaseDate,
      notes: data.notes || null
    });
  }

  static async getInvestments(userId, filters) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const limit = Math.min(parseInt(filters.limit) || 50, 100);
    const offset = parseInt(filters.offset) || 0;

    return await Investment.list(userId, {
      investment_type: filters.investment_type,
      limit,
      offset
    });
  }

  static async getInvestment(userId, investmentId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const investment = await Investment.findByUserAndId(userId, investmentId);

    if (!investment) {
      throw new Error('Investment not found');
    }

    return investment;
  }

  static async updateInvestment(userId, investmentId, data) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const investment = await Investment.findByUserAndId(userId, investmentId);

    if (!investment) {
      throw new Error('Investment not found');
    }

    const { name, quantity, current_price, notes } = data;

    if (quantity !== undefined) {
      const quantityNum = parseFloat(quantity);
      if (isNaN(quantityNum) || quantityNum < 0) {
        throw new Error('Quantity must be a non-negative number');
      }
    }

    if (current_price !== undefined) {
      const priceNum = parseFloat(current_price);
      if (isNaN(priceNum) || priceNum <= 0) {
        throw new Error('Current price must be a positive number');
      }
    }

    return await Investment.update(investmentId, {
      name,
      quantity,
      current_price,
      notes
    });
  }

  static async deleteInvestment(userId, investmentId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    const investment = await Investment.findByUserAndId(userId, investmentId);

    if (!investment) {
      throw new Error('Investment not found');
    }

    await Investment.softDelete(investmentId);

    return { success: true, message: 'Investment deleted successfully' };
  }

  static async getPortfolioSummary(userId) {
    if (!userId) {
      throw new Error('User ID is required');
    }

    return await Investment.getPortfolioSummary(userId);
  }
}

module.exports = InvestmentService;
