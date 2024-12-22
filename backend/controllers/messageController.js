const Message = require('../models/messageModel');
const mongoose = require('mongoose');

// Fetch all messages
const getAllMessages = async (req, res) => {
  try {
    const messages = await Message.find();
    res.status(200).json(messages);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching messages', error });
  }
};

// Create a new message
const createMessage = async (req, res) => {
  try {
    const { senderId, receiverId, text, time, isRead } = req.body;

    // Validate required fields
    if (!senderId || !receiverId || !text) {
      return res.status(400).json({
        message: "Validation failed",
        errors: {
          senderId: !senderId ? "Sender ID is required" : undefined,
          receiverId: !receiverId ? "Receiver ID is required" : undefined,
          text: !text ? "Text is required" : undefined,
        },
      });
    }

    // Create and save the new message
    const newMessage = new Message({
      senderId: new mongoose.Types.ObjectId(senderId),
      receiverId: new mongoose.Types.ObjectId(receiverId),
      text,
      time: time || Date.now(),
      isRead: isRead || false,
    });

    const savedMessage = await newMessage.save();
    res.status(201).json(savedMessage);
  } catch (error) {
    res.status(500).json({
      message: 'Failed to save message',
      error: error.message,
    });
  }
};

// Fetch messages between two users
const getMessagesByUsers = async (req, res) => {
  try {
    const { senderId, receiverId } = req.query;

    if (!senderId || !receiverId) {
      return res.status(400).json({
        message: "Validation failed",
        errors: {
          senderId: !senderId ? "Sender ID is required" : undefined,
          receiverId: !receiverId ? "Receiver ID is required" : undefined,
        },
      });
    }

    const messages = await Message.find({
      $or: [
        { senderId, receiverId },
        { senderId: receiverId, receiverId: senderId },
      ],
    }).sort({ time: 1 }); // Sort by time in ascending order

    res.status(200).json(messages);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching messages', error });
  }
};

module.exports = {
  getAllMessages,
  createMessage,
  getMessagesByUsers,
};
