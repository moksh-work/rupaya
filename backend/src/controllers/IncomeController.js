const IncomeService = require('../services/IncomeService');
const asyncHandler = require('../middleware/asyncHandler');

const IncomeController = {
  createIncome: asyncHandler(async (req, res) => {
    const { amount, account_id, category_id, description, income_date, source, notes, tags } = req.body;

    const income = await IncomeService.createIncome(req.user.user_id, {
      amount: parseFloat(amount),
      account_id,
      category_id,
      description,
      income_date: income_date ? new Date(income_date) : new Date(),
      source,
      notes,
      tags
    });

    res.status(201).json({
      success: true,
      message: 'Income created successfully',
      data: income
    });
  }),

  listIncome: asyncHandler(async (req, res) => {
    const {
      accountId,
      categoryId,
      source,
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
      source,
      startDate: startDate ? new Date(startDate) : null,
      endDate: endDate ? new Date(endDate) : null,
      minAmount: minAmount ? parseFloat(minAmount) : undefined,
      maxAmount: maxAmount ? parseFloat(maxAmount) : undefined,
      tags: tags ? (Array.isArray(tags) ? tags : [tags]) : undefined,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };

    const result = await IncomeService.listIncome(req.user.user_id, filters);

    res.status(200).json({
      success: true,
      data: result
    });
  }),

  getIncome: asyncHandler(async (req, res) => {
    const { id } = req.params;

    const income = await IncomeService.getIncome(id, req.user.user_id);

    res.status(200).json({
      success: true,
      data: income
    });
  }),

  updateIncome: asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { amount, description, source, notes, tags, category_id, income_date } = req.body;

    const updateData = {};
    if (amount !== undefined) updateData.amount = parseFloat(amount);
    if (description !== undefined) updateData.description = description;
    if (source !== undefined) updateData.source = source;
    if (notes !== undefined) updateData.notes = notes;
    if (tags !== undefined) updateData.tags = tags;
    if (category_id !== undefined) updateData.category_id = category_id;
    if (income_date !== undefined) updateData.income_date = new Date(income_date);

    const income = await IncomeService.updateIncome(id, req.user.user_id, updateData);

    res.status(200).json({
      success: true,
      message: 'Income updated successfully',
      data: income
    });
  }),

  deleteIncome: asyncHandler(async (req, res) => {
    const { id } = req.params;

    const result = await IncomeService.deleteIncome(id, req.user.user_id);

    res.status(200).json(result);
  }),

  getStatistics: asyncHandler(async (req, res) => {
    const { startDate, endDate } = req.query;

    const statistics = await IncomeService.getStatistics(req.user.user_id, startDate, endDate);

    res.status(200).json({
      success: true,
      data: statistics
    });
  })
};

module.exports = IncomeController;
