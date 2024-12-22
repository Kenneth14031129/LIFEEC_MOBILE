const mongoose = require('mongoose');

// Define the Notification schema
const notificationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId, // Reference to the user receiving the notification
      required: true,
    },
    type: {
      type: String,
      enum: ['message', 'alert', 'reminder'], // Define different types of notifications
      required: true,
    },
    content: {
      type: String, // The actual notification content/message
      required: true,
    },
    isRead: {
      type: Boolean, // Tracks if the notification has been read
      default: false,
    },
    createdAt: {
      type: Date,
      default: Date.now, // Automatically set to current date and time
    },
  },
  { timestamps: true } // Adds createdAt and updatedAt fields automatically
);

// Create the Notification model
const Notification = mongoose.model('Notification', notificationSchema);

module.exports = Notification;
