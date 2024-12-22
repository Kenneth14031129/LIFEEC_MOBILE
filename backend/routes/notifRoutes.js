const express = require('express');
const {
  getNotifications,
  createNotification,
  markAsRead,
} = require('../controllers/notificationController'); // Adjust the path as needed

const router = express.Router();

// Route to get all notifications for a specific user
router.get('/notifications/:userId', getNotifications);

// Route to create a new notification
router.post('/notifications', createNotification);

// Route to mark a notification as read
router.patch('/notifications/:notificationId', markAsRead);

module.exports = router;
