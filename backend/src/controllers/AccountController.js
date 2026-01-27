const AccountService = require('../services/AccountService');
const { asyncHandler, logger } = require('../utils/validators');

const listAccounts = asyncHandler(async (req, res) => {
  const accounts = await AccountService.listAccounts(req.user.userId);
  res.json(accounts);
});

const createAccount = asyncHandler(async (req, res) => {
  const account = await AccountService.createAccount(req.user.userId, req.body);
  res.status(201).json(account);
});

const updateAccount = asyncHandler(async (req, res) => {
  const account = await AccountService.updateAccount(req.user.userId, req.params.accountId, req.body);
  res.json(account);
});

const deleteAccount = asyncHandler(async (req, res) => {
  await AccountService.deleteAccount(req.user.userId, req.params.accountId);
  res.json({ success: true });
});

module.exports = {
  listAccounts,
  createAccount,
  updateAccount,
  deleteAccount
};
