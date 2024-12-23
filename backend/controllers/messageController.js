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

const markMessagesAsRead = async (req, res) => {
  try {
      const { senderId, receiverId } = req.body;
      console.log('\n=== Mark Messages as Read ===');
      console.log('Request body:', req.body);
      console.log('Sender ID:', senderId);
      console.log('Receiver ID:', receiverId);

      if (!senderId || !receiverId) {
          console.log('❌ Validation failed - missing IDs');
          return res.status(400).json({
              message: "Both sender and receiver IDs are required"
          });
      }

      const result = await Message.updateMany(
          {
              senderId: new mongoose.Types.ObjectId(senderId),
              receiverId: new mongoose.Types.ObjectId(receiverId),
              read: false
          },
          { $set: { read: true } }
      );

      console.log('✅ Update result:', {
          acknowledged: result.acknowledged,
          modifiedCount: result.modifiedCount,
          matchedCount: result.matchedCount
      });

      res.status(200).json({
          message: "Messages marked as read",
          updatedCount: result.modifiedCount
      });
  } catch (error) {
      console.error('❌ Error in markMessagesAsRead:', error);
      res.status(500).json({
          message: 'Failed to mark messages as read',
          error: error.message
      });
  }
};

const getUnreadCounts = async (req, res) => {
  try {
      const { userId } = req.params;
      console.log('\n=== Get Unread Counts ===');
      console.log('User ID:', userId);

      if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
          console.log('❌ Invalid user ID');
          return res.status(400).json({ message: "Valid user ID is required" });
      }

      // Log the query we're about to execute
      console.log('Executing aggregate query for unread messages...');
      const unreadCounts = await Message.aggregate([
          {
              $match: {
                  receiverId: new mongoose.Types.ObjectId(userId),
                  read: false
              }
          },
          {
              $group: {
                  _id: "$senderId",
                  count: { $sum: 1 }
              }
          }
      ]);

      console.log('Raw unread counts result:', unreadCounts);

      const unreadCountsObj = unreadCounts.reduce((acc, curr) => {
          acc[curr._id.toString()] = curr.count;
          return acc;
      }, {});

      console.log('✅ Processed unread counts:', unreadCountsObj);

      res.status(200).json({ unreadCounts: unreadCountsObj });
  } catch (error) {
      console.error('❌ Error in getUnreadCounts:', error);
      res.status(500).json({ message: 'Error getting unread counts', error: error.message });
  }
};

module.exports = {
  getAllMessages,
  createMessage,
  getMessagesByUsers,
  markMessagesAsRead,
  getUnreadCounts
};
