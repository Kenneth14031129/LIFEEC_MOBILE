// routes/healthPlanRoutes.js
const express = require('express');
const router = express.Router();
const healthPlanController = require('../controllers/healthPlanController');

// Get health plan by resident ID
router.get('/resident/:residentId', healthPlanController.getHealthPlan);

// Get all health plans for a resident (history)
router.get('/history/:residentId', healthPlanController.getHealthHistory);

// Get health plan by ID
router.get('/:id', healthPlanController.getHealthPlanById);

// Create new health plan
router.post('/', healthPlanController.createHealthPlan);

// Update health plan
router.put('/:id', healthPlanController.updateHealthPlan);

module.exports = router;