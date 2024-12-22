const express = require('express');
const router = express.Router();
const emergencyAlertController = require('../controllers/emergencyAlertController');

router.get('/', emergencyAlertController.getEmergencyAlertsByResident);
router.post('/', emergencyAlertController.createEmergencyAlert);
router.delete('/alerts/:id', emergencyAlertController.deleteEmergencyAlert);
router.get('/alerts/countByMonth', emergencyAlertController.getAlertsCountByMonth);
router.get('/dashboard/summary', emergencyAlertController.getDashboardSummary); // New route

module.exports = router;
