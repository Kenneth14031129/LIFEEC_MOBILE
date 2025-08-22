// MealRecord.js
const mongoose = require('mongoose');

const mealRecordSchema = new mongoose.Schema({
  residentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Resident',
    required: true
  },
  dietaryNeeds: {
    type: String,
    required: true
  },
  nutritionalGoals: {
    type: String,
    required: true
  },
  date: {
    type: String,
    required: true
  },
  breakfast: [{
    type: String,
    required: true
  }],
  lunch: [{
    type: String,
    required: true
  }],
  snacks: [{
    type: String,
    required: true
  }],
  dinner: [{
    type: String,
    required: true
  }]
}, {
  timestamps: true,
  collection: 'mealrecords'
});

const MealRecord = mongoose.model('MealRecord', mealRecordSchema);
module.exports = MealRecord;