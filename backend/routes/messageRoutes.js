const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');

// Define routes for messages
router.get('/', messageController.getAllMessages);
router.post('/', messageController.createMessage);
router.get('/between-users', messageController.getMessagesByUsers);

module.exports = router;
