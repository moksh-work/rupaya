const ExpenseService = require('../services/ExpenseService');
const asyncHandler = require('../middleware/asyncHandler');

const ExpenseController = {
  // POST /api/v1/expenses - Create expense
  createExpense: asyncHandler(async (req, res) => {
    const { amount, account_id, category_id, description, expense_date, merchant, notes, tags, location } = req.body;

    const expense = await ExpenseService.createExpense(req.user.user_id, {
      amount: parseFloat(amount),
      account_id,
      category_id,
      description,
      expense_date: expense_date ? new Date(expense_date) : new Date(),
      merchant,
      notes,
      tags,
      location
    });

    res.status(201).json({
      success: true,
      message: 'Expense created successfully',
      data: expense
    });
  }),

  // GET /api/v1/expenses - List expenses
  listExpenses: asyncHandler(async (req, res) => {
    const {
      accountId,
      categoryId,
      merchant,
      startDate,
      endDate,
      minAmount,
      maxAmount,
      tags,
      limit = 20,
      offset = 0
    } = req.query;

    const filters = {
      accountId,
      categoryId,
      merchant,
      startDate: startDate ? new Date(startDate) : null,
      endDate: endDate ? new Date(endDate) : null,
      minAmount: minAmount ? parseFloat(minAmount) : undefined,
      maxAmount: maxAmount ? parseFloat(maxAmount) : undefined,
      tags: tags ? (Array.isArray(tags) ? tags : [tags]) : undefined,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };

    const result = await ExpenseService.listExpenses(req.user.user_id, filters);

    res.status(200).json({
      success: true,
      data: result
    });
  }),

  // GET /api/v1/expenses/{id} - Get single expense
  getExpense: asyncHandler(async (req, res) => {
    const { id } = req.params;

    const expense = await ExpenseService.getExpense(id, req.user.user_id);

    res.status(200).json({
      success: true,
      data: expense
    });
  }),

  // PUT /api/v1/expenses/{id} - Update expense
  updateExpense: asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { amount, description, merchant, notes, tags, category_id, expense_date, location } = req.body;

    const updateData = {};
    if (amount !== undefined) updateData.amount = parseFloat(amount);
    if (description !== undefined) updateData.description = description;
    if (merchant !== undefined) updateData.merchant = merchant;
    if (notes !== undefined) updateData.notes = notes;
    if (tags !== undefined) updateData.tags = tags;
    if (category_id !== undefined) updateData.category_id = category_id;
    if (expense_date !== undefined) updateData.expense_date = new Date(expense_date);
    if (location !== undefined) updateData.location = location;

    const expense = await ExpenseService.updateExpense(id, req.user.user_id, updateData);

    res.status(200).json({
      success: true,
      message: 'Expense updated successfully',
      data: expense
    });
  }),

  // DELETE /api/v1/expenses/{id} - Delete expense
  deleteExpense: asyncHandler(async (req, res) => {
    const { id } = req.params;

    const result = await ExpenseService.deleteExpense(id, req.user.user_id);

    res.status(200).json(result);
  }),

  // POST /api/v1/expenses/bulk-delete - Bulk delete
  bulkDeleteExpenses: asyncHandler(async (req, res) => {
    const { expense_ids } = req.body;

    const result = await ExpenseService.bulkDeleteExpenses(expense_ids, req.user.user_id);

    res.status(200).json(result);
  }),

  // GET /api/v1/expenses/statistics - Get statistics
  getStatistics: asyncHandler(async (req, res) => {
    const { startDate, endDate } = req.query;

    const statistics = await ExpenseService.getStatistics(req.user.user_id, startDate, endDate);

    res.status(200).json({
      success: true,
      data: statistics
    });
  }),

  // GET /api/v1/expenses/export - Export expenses
  exportExpenses: asyncHandler(async (req, res) => {
    const { format = 'csv', startDate, endDate, categoryId, merchantId } = req.query;

    const filters = {
      startDate: startDate ? new Date(startDate) : null,
      endDate: endDate ? new Date(endDate) : null,
      categoryId,
      merchantId
    };

    const csvData = await ExpenseService.exportExpenses(req.user.user_id, format, filters);

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="expenses.csv"');
    res.send(csvData);
  }),

  // GET /api/v1/expenses/filter - Filter expenses
  filterExpenses: asyncHandler(async (req, res) => {
    const {
      accountId,
      categoryId,
      merchant,
      startDate,
      endDate,
      minAmount,
      maxAmount,
      tags,
      limit = 20,
      offset = 0
    } = req.query;

    const filters = {
      accountId,
      categoryId,
      merchant,
      startDate: startDate ? new Date(startDate) : null,
      endDate: endDate ? new Date(endDate) : null,
      minAmount: minAmount ? parseFloat(minAmount) : undefined,
      maxAmount: maxAmount ? parseFloat(maxAmount) : undefined,
      tags: tags ? (Array.isArray(tags) ? tags : [tags]) : undefined,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };

    const result = await ExpenseService.filterExpenses(req.user.user_id, filters);

    res.status(200).json({
      success: true,
      data: result
    });
  }),

  // POST /api/v1/expenses/{id}/duplicate - Duplicate expense
  duplicateExpense: asyncHandler(async (req, res) => {
    const { id } = req.params;

    const expense = await ExpenseService.duplicateExpense(id, req.user.user_id);

    res.status(201).json({
      success: true,
      message: 'Expense duplicated successfully',
      data: expense
    });
  }),

  // POST /api/v1/expenses/{id}/receipt - Attach receipt
  attachReceipt: asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { receipt_url } = req.body;

    if (!receipt_url) {
      return res.status(400).json({
        error: 'Receipt URL is required'
      });
    }

    const expense = await ExpenseService.attachReceipt(id, req.user.user_id, receipt_url);

    res.status(200).json({
      success: true,
      message: 'Receipt attached successfully',
      data: expense
    });
  }),

  // POST /api/v1/expenses/recurring - Create recurring expense
  createRecurringExpense: asyncHandler(async (req, res) => {
    const {
      amount,
      account_id,
      category_id,
      description,
      recurring_frequency,
      recurring_end_date,
      merchant,
      notes,
      tags,
      start_date
    } = req.body;

    const expense = await ExpenseService.createRecurringExpense(req.user.user_id, {
      amount: parseFloat(amount),
      account_id,
      category_id,
      description,
      recurring_frequency,
      recurring_end_date: recurring_end_date ? new Date(recurring_end_date) : null,
      merchant,
      notes,
      tags,
      start_date: start_date ? new Date(start_date) : new Date()
    });

    res.status(201).json({
      success: true,
      message: 'Recurring expense created successfully',
      data: expense
    });
  })
};

module.exports = ExpenseController;
