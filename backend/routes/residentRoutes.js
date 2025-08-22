// routes/residentRoutes.js
const express = require('express');
const router = express.Router();
const residentController = require('../controllers/residentController');

// Get all residents with optional search and filter
router.get('/search', residentController.searchResidents);

// CRUD routes
router.get('/', residentController.getResidents);
router.get('/:id', residentController.getResident);
router.post('/', residentController.createResident);
router.put('/:id', residentController.updateResident);
router.delete('/:id', residentController.deleteResident);

module.exports = router;