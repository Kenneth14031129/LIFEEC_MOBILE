// models/Resident.js
const mongoose = require('mongoose');

const emergencyContactSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, required: true },
  email: { type: String, required: true },
  relationship: String
});

const residentSchema = new mongoose.Schema({
  fullName: { 
    type: String, 
    required: true 
  },
  dateOfBirth: { 
    type: Date, 
    required: true 
  },
  gender: { 
    type: String, 
    enum: ['male', 'female', 'other'],
    required: true 
  },
  contactNumber: { 
    type: String, 
    required: true 
  },
  address: { 
    type: String, 
    required: true 
  },
  emergencyContact: emergencyContactSchema,
  status: { 
    type: String, 
    enum: ['active', 'inactive', 'critical'],
    default: 'active'
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Resident', residentSchema);