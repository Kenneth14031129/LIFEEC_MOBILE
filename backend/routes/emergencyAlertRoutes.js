// routes/emergencyAlertRoutes.js
const express = require('express');
const router = express.Router();
const emergencyAlertController = require('../controllers/emergencyAlertController');

// Create new emergency alert
router.post('/', emergencyAlertController.createEmergencyAlert);

// Get all emergency alerts
router.get('/', emergencyAlertController.getEmergencyAlerts);

// Get emergency alerts for a specific resident
router.get('/resident/:residentId', emergencyAlertController.getEmergencyAlertsByResident);

// Mark alert as read
router.patch('/:alertId/read', emergencyAlertController.markAlertAsRead);

module.exports = router;