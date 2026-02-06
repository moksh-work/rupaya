const BudgetService = require('../services/BudgetService');
const asyncHandler = require('../middleware/asyncHandler');

const BudgetController = {
  createBudget: asyncHandler(async (req, res) => {
    const { name, amount, currency, period, start_date, end_date, category_id, account_id, alert_threshold, notes } = req.body;

    const budget = await BudgetService.createBudget(req.user.user_id, {
      name,
      amount: parseFloat(amount),
      currency,
      period,
      start_date: new Date(start_date),
      end_date: end_date ? new Date(end_date) : null,
      category_id,
      account_id,
      alert_threshold: alert_threshold ? parseInt(alert_threshold) : 80,
      notes
    });

    res.status(201).json({
      success: true,
      message: 'Budget created successfully',
      data: budget
    });
  }),

  listBudgets: asyncHandler(async (req, res) => {
    const { categoryId, accountId, isActive, period, limit = 20, offset = 0 } = req.query;

    const filters = {
      categoryId,
      accountId,
      isActive: isActive === 'true' ? true : isActive === 'false' ? false : undefined,
      period,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };

    const result = await BudgetService.listBudgets(req.user.user_id, filters);

    res.status(200).json({
      success: true,
      data: result
    });
  }),

  getBudget: asyncHandler(async (req, res) => {
    const { id } = req.params;

    const budget = await BudgetService.getBudget(id, req.user.user_id);

    res.status(200).json({
      success: true,
      data: budget
    });
  }),

  updateBudget: asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { name, amount, currency, period, start_date, end_date, category_id, account_id, alert_threshold, notes, is_active } = req.body;

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (amount !== undefined) updateData.amount = parseFloat(amount);
    if (currency !== undefined) updateData.currency = currency;
    if (period !== undefined) updateData.period = period;
    if (start_date !== undefined) updateData.start_date = new Date(start_date);
    if (end_date !== undefined) updateData.end_date = end_date ? new Date(end_date) : null;
    if (category_id !== undefined) updateData.category_id = category_id;
    if (account_id !== undefined) updateData.account_id = account_id;
    if (alert_threshold !== undefined) updateData.alert_threshold = parseInt(alert_threshold);
    if (notes !== undefined) updateData.notes = notes;
    if (is_active !== undefined) updateData.is_active = is_active;

    const budget = await BudgetService.updateBudget(id, req.user.user_id, updateData);

    res.status(200).json({
      success: true,
      message: 'Budget updated successfully',
      data: budget
    });
  }),

  deleteBudget: asyncHandler(async (req, res) => {
    const { id } = req.params;

    const result = await BudgetService.deleteBudget(id, req.user.user_id);

    res.status(200).json(result);
  }),

  getProgress: asyncHandler(async (req, res) => {
    const { id } = req.params;

    const progress = await BudgetService.getProgress(id, req.user.user_id);

    res.status(200).json({
      success: true,
      data: progress
    });
  }),

  getComparison: asyncHandler(async (req, res) => {
    const { period } = req.query;

    const comparison = await BudgetService.getComparison(req.user.user_id, period);

    res.status(200).json({
      success: true,
      data: comparison
    });
  })
};

module.exports = BudgetController;
