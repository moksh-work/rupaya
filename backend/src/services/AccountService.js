const Account = require('../models/Account');

class AccountService {
  static async listAccounts(userId) {
    return Account.listByUser(userId);
  }

  static async createAccount(userId, payload) {
    return Account.create(userId, payload);
  }

  static async updateAccount(userId, accountId, payload) {
    const account = await Account.findById(accountId);
    if (!account || account.user_id !== userId) {
      throw new Error('Account not found');
    }

    return Account.update(accountId, userId, payload);
  }

  static async deleteAccount(userId, accountId) {
    const account = await Account.findById(accountId);
    if (!account || account.user_id !== userId) {
      throw new Error('Account not found');
    }

    return Account.remove(accountId, userId);
  }
}

module.exports = AccountService;
