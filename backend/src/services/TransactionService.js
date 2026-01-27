const db = require('../config/database');
const Account = require('../models/Account');
const Transaction = require('../models/Transaction');

class TransactionService {
  static async createTransaction(userId, payload) {
    if (payload.amount <= 0) {
      throw new Error('Amount must be positive');
    }

    const account = await Account.findById(payload.accountId);
    if (!account || account.user_id !== userId) {
      throw new Error('Account not found');
    }

    let toAccount;
    if (payload.type === 'transfer') {
      if (!payload.toAccountId) {
        throw new Error('Destination account required for transfer');
      }
      toAccount = await Account.findById(payload.toAccountId);
      if (!toAccount || toAccount.user_id !== userId) {
        throw new Error('Destination account not found');
      }
    }

    if (payload.type === 'expense' && account.current_balance < payload.amount) {
      throw new Error('Insufficient balance');
    }

    const transactionDate = payload.date ? new Date(payload.date) : new Date();

    return db.transaction(async trx => {
      const txRecord = {
        account_id: account.account_id,
        to_account_id: toAccount ? toAccount.account_id : null,
        amount: payload.amount,
        currency: payload.currency || account.currency || 'INR',
        transaction_type: payload.type,
        category_id: payload.categoryId || null,
        description: payload.description || null,
        notes: payload.notes || null,
        tags: payload.tags || null,
        transaction_date: transactionDate
      };

      const [created] = await trx('transactions')
        .insert({ ...txRecord, user_id: userId, created_at: new Date(), updated_at: new Date(), is_deleted: false, transaction_id: trx.raw('gen_random_uuid()') })
        .returning('*');

      const now = new Date();
      if (payload.type === 'income') {
        await trx('accounts')
          .where({ account_id: account.account_id })
          .update({ current_balance: trx.raw('current_balance + ?', [payload.amount]), updated_at: now });
      } else if (payload.type === 'expense') {
        await trx('accounts')
          .where({ account_id: account.account_id })
          .update({ current_balance: trx.raw('current_balance - ?', [payload.amount]), updated_at: now });
      } else if (payload.type === 'transfer' && toAccount) {
        await trx('accounts')
          .where({ account_id: account.account_id })
          .update({ current_balance: trx.raw('current_balance - ?', [payload.amount]), updated_at: now });
        await trx('accounts')
          .where({ account_id: toAccount.account_id })
          .update({ current_balance: trx.raw('current_balance + ?', [payload.amount]), updated_at: now });
      }

      return created;
    });
  }

  static async getTransactions(userId, filters = {}) {
    return Transaction.list(userId, filters);
  }

  static async deleteTransaction(userId, transactionId) {
    const transaction = await Transaction.findById(transactionId, userId);
    if (!transaction || transaction.is_deleted) {
      throw new Error('Transaction not found');
    }

    const now = new Date();
    return db.transaction(async trx => {
      const account = await trx('accounts').where({ account_id: transaction.account_id }).first();
      if (!account || account.user_id !== userId) {
        throw new Error('Account not found for transaction');
      }

      // Revert balance
      if (transaction.transaction_type === 'income') {
        await trx('accounts')
          .where({ account_id: account.account_id })
          .update({ current_balance: trx.raw('current_balance - ?', [transaction.amount]), updated_at: now });
      } else if (transaction.transaction_type === 'expense') {
        await trx('accounts')
          .where({ account_id: account.account_id })
          .update({ current_balance: trx.raw('current_balance + ?', [transaction.amount]), updated_at: now });
      } else if (transaction.transaction_type === 'transfer' && transaction.to_account_id) {
        await trx('accounts')
          .where({ account_id: account.account_id })
          .update({ current_balance: trx.raw('current_balance + ?', [transaction.amount]), updated_at: now });
        await trx('accounts')
          .where({ account_id: transaction.to_account_id })
          .update({ current_balance: trx.raw('current_balance - ?', [transaction.amount]), updated_at: now });
      }

      await trx('transactions')
        .where({ transaction_id: transactionId, user_id: userId })
        .update({ is_deleted: true, updated_at: now });

      return true;
    });
  }
}

module.exports = TransactionService;
