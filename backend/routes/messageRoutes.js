const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');

router.get('/unread/:userId', messageController.getUnreadCounts);
// Define routes for messages
router.get('/', messageController.getAllMessages);
router.post('/', messageController.createMessage);
router.get('/between-users', messageController.getMessagesByUsers);
router.post('/mark-read', messageController.markMessagesAsRead);

module.exports = router;
