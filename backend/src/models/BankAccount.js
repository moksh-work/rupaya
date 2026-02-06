const db = require('../config/database');

class BankAccount {
  static async create(userId, data) {
    const { bank_name, account_number, account_type, access_token, refresh_token, expires_at } = data;

    const [bankAccountId] = await db('bank_accounts').insert({
      user_id: userId,
      bank_name,
      account_number,
      account_type,
      access_token,
      refresh_token,
      expires_at,
      is_active: true,
      last_sync: null,
      created_at: new Date(),
      updated_at: new Date()
    });

    return this.findById(bankAccountId);
  }

  static async findById(id) {
    return await db('bank_accounts')
      .where({ bank_account_id: id, is_deleted: false })
      .first();
  }

  static async findByUserId(userId) {
    return await db('bank_accounts')
      .where({ user_id: userId, is_deleted: false })
      .orderBy('created_at', 'desc');
  }

  static async findByUserAndId(userId, id) {
    return await db('bank_accounts')
      .where({ user_id: userId, bank_account_id: id, is_deleted: false })
      .first();
  }

  static async updateToken(id, accessToken, refreshToken, expiresAt) {
    await db('bank_accounts')
      .where({ bank_account_id: id })
      .update({
        access_token: accessToken,
        refresh_token: refreshToken,
        expires_at: expiresAt,
        updated_at: new Date()
      });

    return this.findById(id);
  }

  static async updateLastSync(id) {
    await db('bank_accounts')
      .where({ bank_account_id: id })
      .update({
        last_sync: new Date(),
        updated_at: new Date()
      });
  }

  static async softDelete(id) {
    await db('bank_accounts')
      .where({ bank_account_id: id })
      .update({
        is_deleted: true,
        is_active: false,
        updated_at: new Date()
      });
  }

  static async getBalance(id) {
    const transactions = await db('bank_transactions')
      .where({ bank_account_id: id, is_deleted: false })
      .select(db.raw('sum(CASE WHEN transaction_type = ? THEN amount ELSE -amount END) as balance', ['credit']));

    return transactions[0]?.balance || 0;
  }
}

class BankTransaction {
  static async create(userId, bankAccountId, data) {
    const {
      transaction_id,
      amount,
      transaction_type,
      description,
      merchant_name,
      transaction_date,
      posted_date
    } = data;

    const [id] = await db('bank_transactions').insert({
      user_id: userId,
      bank_account_id: bankAccountId,
      transaction_id,
      amount,
      transaction_type,
      description,
      merchant_name,
      transaction_date,
      posted_date,
      category_id: null,
      is_categorized: false,
      is_deleted: false,
      created_at: new Date(),
      updated_at: new Date()
    });

    return this.findById(id);
  }

  static async findById(id) {
    return await db('bank_transactions')
      .where({ bank_transaction_id: id, is_deleted: false })
      .first();
  }

  static async findByBankAccountId(bankAccountId, limit = 50, offset = 0) {
    return await db('bank_transactions')
      .where({ bank_account_id: bankAccountId, is_deleted: false })
      .leftJoin('categories', 'bank_transactions.category_id', 'categories.category_id')
      .select('bank_transactions.*', 'categories.name as category_name')
      .orderBy('bank_transactions.posted_date', 'desc')
      .limit(limit)
      .offset(offset);
  }

  static async countByBankAccountId(bankAccountId) {
    const result = await db('bank_transactions')
      .where({ bank_account_id: bankAccountId, is_deleted: false })
      .count('* as total')
      .first();

    return result.total;
  }

  static async updateCategory(id, categoryId) {
    await db('bank_transactions')
      .where({ bank_transaction_id: id })
      .update({
        category_id: categoryId,
        is_categorized: categoryId !== null,
        updated_at: new Date()
      });

    return this.findById(id);
  }

  static async bulkCreate(userId, bankAccountId, transactions) {
    const rows = transactions.map(tx => ({
      user_id: userId,
      bank_account_id: bankAccountId,
      transaction_id: tx.id,
      amount: tx.amount,
      transaction_type: tx.type,
      description: tx.description,
      merchant_name: tx.merchant,
      transaction_date: tx.date,
      posted_date: tx.posted_date,
      category_id: null,
      is_categorized: false,
      is_deleted: false,
      created_at: new Date(),
      updated_at: new Date()
    }));

    const inserted = await db('bank_transactions').insert(rows);
    return inserted.length;
  }

  static async deleteByBankAccountId(bankAccountId) {
    await db('bank_transactions')
      .where({ bank_account_id: bankAccountId })
      .update({
        is_deleted: true,
        updated_at: new Date()
      });
  }
}

module.exports = { BankAccount, BankTransaction };
