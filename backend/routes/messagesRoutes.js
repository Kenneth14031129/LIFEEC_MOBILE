// routes/messagesRoutes.js
const express = require('express');
const router = express.Router();
const messagesController = require('../controllers/messagesController');

// Send a new message
router.post('/', messagesController.sendMessage);

// Get conversation between two users
router.get('/conversation/:userId/:otherUserId', messagesController.getConversation);

// Get recent conversations for a user
router.get('/recent/:userId', messagesController.getRecentConversations);

// Mark messages as read
router.put('/read', messagesController.markAsRead);

// Delete a message
router.delete('/:messageId', messagesController.deleteMessage);

module.exports = router;