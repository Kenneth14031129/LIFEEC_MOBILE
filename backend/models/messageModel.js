const mongoose = require('mongoose');

// Define the Message schema
const messageSchema = new mongoose.Schema(
  {
    senderId: {
      type: mongoose.Schema.Types.ObjectId, // Use ObjectId for senderId
      required: true,
    },
    receiverId: {
      type: mongoose.Schema.Types.ObjectId, // Use ObjectId for receiverId
      required: true,
    },
    text: {
      type: String,
      required: true,
    },
    time: {
      type: Date,
      default: Date.now, // Automatically set to the current date and time
    },
    isRead: {
      type: Boolean,
      default: false, // Tracks if the message has been read
    },
  },
  { timestamps: true } // Adds createdAt and updatedAt fields automatically
);

// Create the Message model
const Message = mongoose.model('Message', messageSchema);

module.exports = Message;
