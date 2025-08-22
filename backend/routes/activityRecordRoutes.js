// activityRecordRoutes.js
const express = require('express');
const router = express.Router();
const activityRecordController = require('../controllers/activityRecordController');

// Get all activity records for a resident
router.get('/resident/:residentId', activityRecordController.getActivityRecords);

// Get latest activity record for a resident
router.get('/resident/:residentId/latest', activityRecordController.getLatestActivityRecord);

// Get specific activity record by ID
router.get('/:id', activityRecordController.getActivityRecordById);

// Create new activity record
router.post('/', activityRecordController.createActivityRecord);

// Update activity record
router.put('/:id', activityRecordController.updateActivityRecord);

// Delete activity record
router.delete('/:id', activityRecordController.deleteActivityRecord);

module.exports = router;