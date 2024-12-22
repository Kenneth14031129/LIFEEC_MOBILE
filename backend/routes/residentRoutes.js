// routes/residentRoutes.js

const express = require('express');
const router = express.Router();
const Resident = require('../models/Activity'); // Assume you have a Mongoose model defined

// Create a new resident
router.post('/residents', async (req, res) => {
    const newResident = new Resident(req.body);
    try {
        await newResident.save();
        res.status(201).json(newResident);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Get all residents
router.get('/residents', async (req, res) => {
    try {
        const residents = await Resident.find();
        res.json(residents);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get a single resident by ID
router.get('/residents/:id', async (req, res) => {
    try {
        const resident = await Resident.findById(req.params.id);
        if (!resident) {
            return res.status(404).json({ error: 'Resident not found' });
        }
        res.json(resident);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Update a resident
router.put('/residents/:id', async (req, res) => {
    try {
        const updatedResident = await Resident.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!updatedResident) {
            return res.status(404).json({ error: 'Resident not found' });
        }
        res.json(updatedResident);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Delete a resident
router.delete('/residents/:id', async (req, res) => {
    try {
        const deletedResident = await Resident.findByIdAndDelete(req.params.id);
        if (!deletedResident) {
            return res.status(404).json({ error: 'Resident not found' });
        }
        res.json({ message: 'Resident deleted' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
