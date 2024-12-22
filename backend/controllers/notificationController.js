const Notification = require('../models/notificationModel');

// Fetch all notifications for a user
const getNotifications = async (req, res) => {
  const { userId } = req.params;

  try {
    const notifications = await Notification.find({ userId }).sort({ createdAt: -1 });
    res.status(200).json(notifications);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching notifications', error });
  }
};

// Create a new notification
const createNotification = async (req, res) => {
  const { userId, type, content } = req.body;

  try {
    if (!userId || !type || !content) {
      return res.status(400).json({
        message: "Validation failed",
        errors: {
          userId: !userId ? "User ID is required" : undefined,
          type: !type ? "Notification type is required" : undefined,
          content: !content ? "Content is required" : undefined,
        },
      });
    }

    const notification = new Notification({
      userId,
      type,
      content,
    });

    const savedNotification = await notification.save();
    res.status(201).json(savedNotification);
  } catch (error) {
    res.status(500).json({ message: 'Error creating notification', error });
  }
};

// Mark a notification as read
const markAsRead = async (req, res) => {
  const { notificationId } = req.params;

  try {
    const updatedNotification = await Notification.findByIdAndUpdate(
      notificationId,
      { isRead: true },
      { new: true } // Return the updated document
    );

    res.status(200).json(updatedNotification);
  } catch (error) {
    res.status(500).json({ message: 'Error updating notification', error });
  }
};

module.exports = {
  getNotifications,
  createNotification,
  markAsRead,
};
