const mongoose = require('mongoose');

const EmergencyAlertSchema = new mongoose.Schema({
  residentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient', // Reference to Resident/Patient model
    required: true,
  },
  residentName: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  timestamp: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('EmergencyAlert', EmergencyAlertSchema);
