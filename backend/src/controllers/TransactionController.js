const TransactionService = require('../services/TransactionService');
const { asyncHandler, logger } = require('../utils/validators');

const getTransactions = asyncHandler(async (req, res) => {
  const transactions = await TransactionService.getTransactions(req.user.userId, {
    accountId: req.query.accountId,
    categoryId: req.query.categoryId,
    type: req.query.type,
    startDate: req.query.startDate,
    endDate: req.query.endDate,
    limit: req.query.limit,
    offset: req.query.offset
  });

  res.json(transactions);
});

const createTransaction = asyncHandler(async (req, res) => {
  const transaction = await TransactionService.createTransaction(req.user.userId, {
    accountId: req.body.accountId,
    toAccountId: req.body.toAccountId,
    amount: Number(req.body.amount),
    type: req.body.type,
    categoryId: req.body.categoryId,
    currency: req.body.currency,
    description: req.body.description,
    notes: req.body.notes,
    tags: req.body.tags,
    date: req.body.date
  });

  res.status(201).json(transaction);
});

const deleteTransaction = asyncHandler(async (req, res) => {
  await TransactionService.deleteTransaction(req.user.userId, req.params.transactionId);
  res.json({ success: true });
});

module.exports = {
  getTransactions,
  createTransaction,
  deleteTransaction
};
