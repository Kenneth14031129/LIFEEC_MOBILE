// controllers/residentController.js
const Resident = require('../models/Resident');

// Get all residents
exports.getResidents = async (req, res) => {
  try {
    const residents = await Resident.find()
      .populate('createdBy', 'fullName email')
      .sort({ createdAt: -1 });
    res.json(residents);
  } catch (error) {
    console.error('Get residents error:', error);
    res.status(500).json({ message: 'Server error while fetching residents' });
  }
};

// Get single resident
exports.getResident = async (req, res) => {
  try {
    const resident = await Resident.findById(req.params.id)
      .populate('createdBy', 'fullName email');
    
    if (!resident) {
      return res.status(404).json({ message: 'Resident not found' });
    }
    
    res.json(resident);
  } catch (error) {
    console.error('Get resident error:', error);
    res.status(500).json({ message: 'Server error while fetching resident' });
  }
};

// Create new resident
exports.createResident = async (req, res) => {
  try {
    const {
      fullName,
      dateOfBirth,
      gender,
      contactNumber,
      address,
      emergencyContact,
      status
    } = req.body;

    const resident = new Resident({
      fullName,
      dateOfBirth,
      gender,
      contactNumber,
      address,
      emergencyContact,
      status,
      createdBy: req.body.userId // Since we removed auth, passing userId in body
    });

    const savedResident = await resident.save();
    res.status(201).json(savedResident);
  } catch (error) {
    console.error('Create resident error:', error);
    res.status(500).json({ message: 'Server error while creating resident' });
  }
};

// Update resident
exports.updateResident = async (req, res) => {
  try {
    const updatedResident = await Resident.findByIdAndUpdate(
      req.params.id,
      { $set: req.body },
      { new: true, runValidators: true }
    );

    if (!updatedResident) {
      return res.status(404).json({ message: 'Resident not found' });
    }

    res.json(updatedResident);
  } catch (error) {
    console.error('Update resident error:', error);
    res.status(500).json({ message: 'Server error while updating resident' });
  }
};

// Delete resident
exports.deleteResident = async (req, res) => {
  try {
    const resident = await Resident.findByIdAndDelete(req.params.id);
    
    if (!resident) {
      return res.status(404).json({ message: 'Resident not found' });
    }

    res.json({ message: 'Resident deleted successfully' });
  } catch (error) {
    console.error('Delete resident error:', error);
    res.status(500).json({ message: 'Server error while deleting resident' });
  }
};

// Search residents
exports.searchResidents = async (req, res) => {
  try {
    const { query, status } = req.query;
    let searchQuery = {};

    if (query) {
      searchQuery.fullName = { $regex: query, $options: 'i' };
    }

    if (status && status !== 'all') {
      searchQuery.status = status;
    }

    const residents = await Resident.find(searchQuery)
      .populate('createdBy', 'fullName email')
      .sort({ createdAt: -1 });

    res.json(residents);
  } catch (error) {
    console.error('Search residents error:', error);
    res.status(500).json({ message: 'Server error while searching residents' });
  }
};