const express = require('express');
const authController = require('../controllers/authController');

const router = express.Router();

// User authentication routes
router.post('/signin', authController.signin);  // Log in an existing user

// Password recovery routes
router.post('/forgot-password', authController.forgotPassword);  // Request password reset
router.post('/reset-password/:token', authController.resetPassword);  // Reset password using token

module.exports = router;
