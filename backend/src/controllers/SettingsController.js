const SettingsService = require('../services/SettingsService');
const asyncHandler = require('../utils/asyncHandler');

const getSettings = asyncHandler(async (req, res) => {
  const settings = await SettingsService.getSettings(req.user.id);

  res.status(200).json({
    success: true,
    message: 'Settings retrieved successfully',
    data: settings
  });
});

const updateSettings = asyncHandler(async (req, res) => {
  const settings = await SettingsService.updateSettings(req.user.id, req.body);

  res.status(200).json({
    success: true,
    message: 'Settings updated successfully',
    data: settings
  });
});

const getSecuritySettings = asyncHandler(async (req, res) => {
  const settings = await SettingsService.getSecuritySettings(req.user.id);

  res.status(200).json({
    success: true,
    message: 'Security settings retrieved successfully',
    data: settings
  });
});

const updateSecuritySettings = asyncHandler(async (req, res) => {
  const settings = await SettingsService.updateSecuritySettings(req.user.id, req.body);

  res.status(200).json({
    success: true,
    message: 'Security settings updated successfully',
    data: settings
  });
});

const exportData = asyncHandler(async (req, res) => {
  const { export_type } = req.body;

  const result = await SettingsService.exportData(req.user.id, export_type || 'full');

  res.status(202).json({
    success: true,
    message: result.message,
    data: result
  });
});

const getExportHistory = asyncHandler(async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 10, 50);
  const offset = parseInt(req.query.offset) || 0;

  const history = await SettingsService.getExportHistory(req.user.id, limit, offset);

  res.status(200).json({
    success: true,
    message: 'Export history retrieved successfully',
    data: history
  });
});

const requestDataAccess = asyncHandler(async (req, res) => {
  const { reason } = req.body;

  const result = await SettingsService.requestDataAccess(req.user.id, reason);

  res.status(202).json({
    success: true,
    message: result.message,
    data: result
  });
});

const getAccessRequests = asyncHandler(async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 10, 50);
  const offset = parseInt(req.query.offset) || 0;

  const requests = await SettingsService.getAccessRequests(req.user.id, limit, offset);

  res.status(200).json({
    success: true,
    message: 'Access requests retrieved successfully',
    data: requests
  });
});

module.exports = {
  getSettings,
  updateSettings,
  getSecuritySettings,
  updateSecuritySettings,
  exportData,
  getExportHistory,
  requestDataAccess,
  getAccessRequests
};
