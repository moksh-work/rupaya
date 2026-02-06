const NotificationService = require('../services/NotificationService');
const asyncHandler = require('../utils/asyncHandler');

const getNotifications = asyncHandler(async (req, res) => {
  const result = await NotificationService.getNotifications(req.user.id, req.query);

  res.status(200).json({
    success: true,
    message: 'Notifications retrieved successfully',
    data: result
  });
});

const markAsRead = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const notification = await NotificationService.markAsRead(req.user.id, parseInt(id));

  res.status(200).json({
    success: true,
    message: 'Notification marked as read',
    data: notification
  });
});

const markAllAsRead = asyncHandler(async (req, res) => {
  const result = await NotificationService.markAllAsRead(req.user.id);

  res.status(200).json({
    success: true,
    message: 'All notifications marked as read',
    data: result
  });
});

const deleteNotification = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const result = await NotificationService.deleteNotification(req.user.id, parseInt(id));

  res.status(200).json({
    success: true,
    message: result.message,
    data: result
  });
});

const getPreferences = asyncHandler(async (req, res) => {
  const preferences = await NotificationService.getPreferences(req.user.id);

  res.status(200).json({
    success: true,
    message: 'Notification preferences retrieved successfully',
    data: preferences
  });
});

const updatePreferences = asyncHandler(async (req, res) => {
  const preferences = await NotificationService.updatePreferences(req.user.id, req.body);

  res.status(200).json({
    success: true,
    message: 'Notification preferences updated successfully',
    data: preferences
  });
});

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getPreferences,
  updatePreferences
};
