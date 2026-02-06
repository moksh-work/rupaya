const BankService = require('../services/BankService');
const asyncHandler = require('../utils/asyncHandler');

const connectBank = asyncHandler(async (req, res) => {
  const { bank_provider, redirect_uri } = req.body;

  const state = BankService.generateState();
  const authUrl = BankService.generateAuthUrl(bank_provider, state, redirect_uri);

  res.status(200).json({
    success: true,
    message: 'Authorization URL generated successfully',
    data: {
      auth_url: authUrl,
      state: state
    }
  });
});

const handleCallback = asyncHandler(async (req, res) => {
  const { code, state, bank_provider } = req.body;

  const bankAccount = await BankService.handleCallback(req.user.id, code, state, bank_provider);

  res.status(201).json({
    success: true,
    message: 'Bank account connected successfully',
    data: bankAccount
  });
});

const getConnectedAccounts = asyncHandler(async (req, res) => {
  const accounts = await BankService.getConnectedAccounts(req.user.id);

  res.status(200).json({
    success: true,
    message: 'Connected bank accounts retrieved successfully',
    data: {
      total: accounts.length,
      accounts
    }
  });
});

const syncTransactions = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await BankService.syncTransactions(req.user.id, parseInt(id));

  res.status(200).json({
    success: true,
    message: 'Transactions synced successfully',
    data: result
  });
});

const getBankTransactions = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const limit = Math.min(parseInt(req.query.limit) || 50, 100);
  const offset = parseInt(req.query.offset) || 0;

  const result = await BankService.getBankTransactions(req.user.id, parseInt(id), limit, offset);

  res.status(200).json({
    success: true,
    message: 'Bank transactions retrieved successfully',
    data: result
  });
});

const categorizeTransaction = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { bank_account_id, category_id } = req.body;

  const transaction = await BankService.categorizeTransaction(
    req.user.id,
    bank_account_id,
    parseInt(id),
    category_id
  );

  res.status(200).json({
    success: true,
    message: 'Transaction categorized successfully',
    data: transaction
  });
});

const disconnectBankAccount = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await BankService.disconnectBankAccount(req.user.id, parseInt(id));

  res.status(200).json({
    success: true,
    message: result.message,
    data: result
  });
});

const getBalance = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const balance = await BankService.getBalance(req.user.id, parseInt(id));

  res.status(200).json({
    success: true,
    message: 'Bank account balance retrieved successfully',
    data: balance
  });
});

module.exports = {
  connectBank,
  handleCallback,
  getConnectedAccounts,
  syncTransactions,
  getBankTransactions,
  categorizeTransaction,
  disconnectBankAccount,
  getBalance
};
