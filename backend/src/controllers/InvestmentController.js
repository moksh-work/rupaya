const InvestmentService = require('../services/InvestmentService');
const asyncHandler = require('../utils/asyncHandler');

const createInvestment = asyncHandler(async (req, res) => {
  const investment = await InvestmentService.createInvestment(req.user.id, req.body);

  res.status(201).json({
    success: true,
    message: 'Investment created successfully',
    data: investment
  });
});

const getInvestments = asyncHandler(async (req, res) => {
  const result = await InvestmentService.getInvestments(req.user.id, req.query);

  res.status(200).json({
    success: true,
    message: 'Investments retrieved successfully',
    data: result
  });
});

const getInvestment = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const investment = await InvestmentService.getInvestment(req.user.id, parseInt(id));

  res.status(200).json({
    success: true,
    message: 'Investment retrieved successfully',
    data: investment
  });
});

const getPortfolioSummary = asyncHandler(async (req, res) => {
  const summary = await InvestmentService.getPortfolioSummary(req.user.id);

  res.status(200).json({
    success: true,
    message: 'Portfolio summary retrieved successfully',
    data: summary
  });
});

const updateInvestment = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const investment = await InvestmentService.updateInvestment(req.user.id, parseInt(id), req.body);

  res.status(200).json({
    success: true,
    message: 'Investment updated successfully',
    data: investment
  });
});

const deleteInvestment = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const result = await InvestmentService.deleteInvestment(req.user.id, parseInt(id));

  res.status(200).json({
    success: true,
    message: result.message,
    data: result
  });
});

module.exports = {
  createInvestment,
  getInvestments,
  getInvestment,
  getPortfolioSummary,
  updateInvestment,
  deleteInvestment
};
