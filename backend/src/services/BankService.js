const { BankAccount, BankTransaction } = require('../models/BankAccount');
const crypto = require('crypto');

class BankService {
  static generateState() {
    return crypto.randomBytes(16).toString('hex');
  }

  static generateAuthUrl(bankProvider, state, redirectUri) {
    // This is a mock implementation. In production, this would point to real bank APIs
    // Examples: Plaid, Open Banking APIs, etc.
    const validProviders = ['plaid', 'yodlee', 'fintech-api', 'open-banking'];

    if (!validProviders.includes(bankProvider.toLowerCase())) {
      throw new Error(`Invalid bank provider. Must be one of: ${validProviders.join(', ')}`);
    }

    const baseUrls = {
      'plaid': 'https://plaid.com/oauth',
      'yodlee': 'https://yodlee.com/oauth',
      'fintech-api': 'https://api.fintech.com/oauth',
      'open-banking': 'https://api.openbanking.com/oauth'
    };

    const params = new URLSearchParams({
      client_id: process.env.BANK_API_CLIENT_ID || 'mock-client-id',
      redirect_uri: redirectUri,
      state: state,
      response_type: 'code',
      scope: 'accounts transactions'
    });

    return `${baseUrls[bankProvider.toLowerCase()]}?${params.toString()}`;
  }

  static async handleCallback(userId, code, state, bankProvider) {
    if (!code || !state) {
      throw new Error('Missing authorization code or state');
    }

    // In production, exchange code for access token with bank API
    // This is a mock implementation
    const tokens = {
      access_token: crypto.randomBytes(32).toString('hex'),
      refresh_token: crypto.randomBytes(32).toString('hex'),
      expires_in: 3600
    };

    const expiresAt = new Date(Date.now() + tokens.expires_in * 1000);

    // Mock bank account details
    const mockAccounts = [
      {
        bank_name: bankProvider,
        account_number: 'XXXX-' + Math.random().toString(36).substring(2, 8).toUpperCase(),
        account_type: 'checking'
      }
    ];

    const account = mockAccounts[0];

    const bankAccount = await BankAccount.create(userId, {
      bank_name: account.bank_name,
      account_number: account.account_number,
      account_type: account.account_type,
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token,
      expires_at: expiresAt
    });

    return bankAccount;
  }

  static async getConnectedAccounts(userId) {
    const accounts = await BankAccount.findByUserId(userId);

    const result = [];
    for (const account of accounts) {
      const balance = await BankAccount.getBalance(account.bank_account_id);
      result.push({
        ...account,
        current_balance: balance
      });
    }

    return result;
  }

  static async syncTransactions(userId, bankAccountId) {
    const bankAccount = await BankAccount.findByUserAndId(userId, bankAccountId);

    if (!bankAccount) {
      throw new Error('Bank account not found');
    }

    // Check if token is expired
    if (new Date(bankAccount.expires_at) < new Date()) {
      throw new Error('Bank token expired. Please reconnect your bank account');
    }

    // Mock transaction fetch from bank API
    const mockTransactions = [
      {
        id: 'tx_' + crypto.randomBytes(8).toString('hex'),
        amount: Math.random() * 100 + 10,
        type: 'debit',
        description: 'Online Purchase',
        merchant: 'Amazon',
        date: new Date(),
        posted_date: new Date()
      },
      {
        id: 'tx_' + crypto.randomBytes(8).toString('hex'),
        amount: Math.random() * 1000 + 500,
        type: 'credit',
        description: 'Salary Deposit',
        merchant: 'Employer Inc',
        date: new Date(),
        posted_date: new Date()
      },
      {
        id: 'tx_' + crypto.randomBytes(8).toString('hex'),
        amount: Math.random() * 50 + 20,
        type: 'debit',
        description: 'Gas Station',
        merchant: 'Shell',
        date: new Date(),
        posted_date: new Date()
      }
    ];

    // In production, fetch real transactions from bank API
    // Save new transactions
    const transactionCount = await BankTransaction.bulkCreate(userId, bankAccountId, mockTransactions);

    // Update last sync time
    await BankAccount.updateLastSync(bankAccountId);

    return {
      synced_count: transactionCount,
      last_sync: new Date()
    };
  }

  static async getBankTransactions(userId, bankAccountId, limit, offset) {
    const bankAccount = await BankAccount.findByUserAndId(userId, bankAccountId);

    if (!bankAccount) {
      throw new Error('Bank account not found');
    }

    const transactions = await BankTransaction.findByBankAccountId(bankAccountId, limit, offset);
    const total = await BankTransaction.countByBankAccountId(bankAccountId);

    return {
      total,
      limit,
      offset,
      transactions
    };
  }

  static async categorizeTransaction(userId, bankAccountId, transactionId, categoryId) {
    // Verify user owns the transaction
    const transaction = await BankTransaction.findById(transactionId);

    if (!transaction || transaction.user_id !== userId || transaction.bank_account_id !== bankAccountId) {
      throw new Error('Transaction not found or unauthorized');
    }

    // Verify category exists and belongs to user or is system category
    const category = await db('categories')
      .where(function() {
        this.where({ user_id: userId }).orWhere({ is_system: true });
      })
      .andWhere({ category_id: categoryId })
      .first();

    if (!category) {
      throw new Error('Category not found or unauthorized');
    }

    return await BankTransaction.updateCategory(transactionId, categoryId);
  }

  static async disconnectBankAccount(userId, bankAccountId) {
    const bankAccount = await BankAccount.findByUserAndId(userId, bankAccountId);

    if (!bankAccount) {
      throw new Error('Bank account not found');
    }

    // Delete all associated transactions
    await BankTransaction.deleteByBankAccountId(bankAccountId);

    // Soft delete the bank account
    await BankAccount.softDelete(bankAccountId);

    return { success: true, message: 'Bank account disconnected successfully' };
  }

  static async getBalance(userId, bankAccountId) {
    const bankAccount = await BankAccount.findByUserAndId(userId, bankAccountId);

    if (!bankAccount) {
      throw new Error('Bank account not found');
    }

    const balance = await BankAccount.getBalance(bankAccountId);

    return {
      bank_account_id: bankAccountId,
      bank_name: bankAccount.bank_name,
      account_number: bankAccount.account_number,
      current_balance: balance,
      last_sync: bankAccount.last_sync
    };
  }
}

module.exports = BankService;
