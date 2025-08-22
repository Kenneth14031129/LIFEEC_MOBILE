// mealRecordRoutes.js
const express = require('express');
const router = express.Router();
const mealRecordController = require('../controllers/mealRecordController');

// Get all meal records for a resident
router.get('/resident/:residentId', mealRecordController.getMealRecords);

// Get latest meal record for a resident
router.get('/resident/:residentId/latest', mealRecordController.getLatestMealRecord);

// Get specific meal record by ID
router.get('/:id', mealRecordController.getMealRecordById);

// Create new meal record
router.post('/', mealRecordController.createMealRecord);

// Update meal record
router.put('/:id', mealRecordController.updateMealRecord);

// Delete meal record
router.delete('/:id', mealRecordController.deleteMealRecord);

module.exports = router;