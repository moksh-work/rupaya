const UserService = require('../services/UserService');
const { asyncHandler } = require('../utils/validators');

const getProfile = asyncHandler(async (req, res) => {
  const profile = await UserService.getProfile(req.user.userId);
  res.json(profile);
});

const updateProfile = asyncHandler(async (req, res) => {
  const profile = await UserService.updateProfile(req.user.userId, {
    name: req.body.name,
    phone_number: req.body.phoneNumber,
    country_code: req.body.countryCode,
    currency_preference: req.body.currencyPreference
  });
  res.json(profile);
});

const changePassword = asyncHandler(async (req, res) => {
  const result = await UserService.changePassword(
    req.user.userId,
    req.body.currentPassword,
    req.body.newPassword
  );
  res.json(result);
});

const uploadProfilePicture = asyncHandler(async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file provided' });
  }

  const result = await UserService.uploadProfilePicture(
    req.user.userId,
    req.file.buffer,
    req.file.originalname
  );
  res.json(result);
});

const deleteAccount = asyncHandler(async (req, res) => {
  const result = await UserService.deleteAccount(req.user.userId, req.body.password);
  res.json(result);
});

const getPreferences = asyncHandler(async (req, res) => {
  const preferences = await UserService.getPreferences(req.user.userId);
  res.json(preferences);
});

const updatePreferences = asyncHandler(async (req, res) => {
  const preferences = await UserService.updatePreferences(req.user.userId, req.body);
  res.json(preferences);
});

module.exports = {
  getProfile,
  updateProfile,
  changePassword,
  uploadProfilePicture,
  deleteAccount,
  getPreferences,
  updatePreferences
};
