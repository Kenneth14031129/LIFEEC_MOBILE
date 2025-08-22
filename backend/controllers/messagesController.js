// controllers/messagesController.js
const Message = require('../models/Message');
const User = require('../models/User');

const messagesController = {
  // Send a new message
  sendMessage: async (req, res) => {
    try {
      const { senderId, receiverId, content } = req.body;

      const message = new Message({
        senderId,
        receiverId,
        content
      });

      await message.save();

      res.status(201).json({
        success: true,
        message
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  },

  // Get conversation between two users
  getConversation: async (req, res) => {
    try {
      const { userId, otherUserId } = req.params;

      const messages = await Message.find({
        $or: [
          { senderId: userId, receiverId: otherUserId },
          { senderId: otherUserId, receiverId: userId }
        ]
      }).sort({ timestamp: 1 });

      // Mark messages as read
      await Message.updateMany(
        {
          senderId: otherUserId,
          receiverId: userId,
          isRead: false
        },
        { isRead: true }
      );

      res.json({
        success: true,
        messages
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  },

  // Get recent conversations for a user
  getRecentConversations: async (req, res) => {
    try {
      const { userId } = req.params;

      // Get the last message from each conversation
      const lastMessages = await Message.aggregate([
        {
          $match: {
            $or: [
              { senderId: userId },
              { receiverId: userId }
            ]
          }
        },
        {
          $sort: { timestamp: -1 }
        },
        {
          $group: {
            _id: {
              $cond: [
                { $eq: ['$senderId', userId] },
                '$receiverId',
                '$senderId'
              ]
            },
            lastMessage: { $first: '$$ROOT' }
          }
        }
      ]);

      // Get user details for each conversation
      const conversations = await Promise.all(
        lastMessages.map(async (msg) => {
          const otherUserId = msg._id;
          const otherUser = await User.findOne({ userId: otherUserId })
            .select('fullName role email userId');
          
          return {
            contact: otherUser,
            lastMessage: msg.lastMessage.content,
            timestamp: msg.lastMessage.timestamp,
            unreadCount: await Message.countDocuments({
              senderId: otherUserId,
              receiverId: userId,
              isRead: false
            })
          };
        })
      );

      res.json({
        success: true,
        conversations
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  },

  // Mark messages as read
  markAsRead: async (req, res) => {
    try {
      const { messageIds } = req.body;

      await Message.updateMany(
        {
          _id: { $in: messageIds }
        },
        { isRead: true }
      );

      res.json({
        success: true,
        message: 'Messages marked as read'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  },

  // Delete a message
  deleteMessage: async (req, res) => {
    try {
      const { messageId } = req.params;

      const message = await Message.findByIdAndDelete(messageId);

      if (!message) {
        return res.status(404).json({
          success: false,
          error: 'Message not found'
        });
      }

      res.json({
        success: true,
        message: 'Message deleted successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
};

module.exports = messagesController;