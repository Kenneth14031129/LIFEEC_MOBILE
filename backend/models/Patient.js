const mongoose = require('mongoose');

const patientSchema = new mongoose.Schema({
  medicalCondition: String,
  date: String,
  status: String,
  currentMedication: String,
  dosage: String,
  quantity: String,
  allergy: String,
  medication: String,
  time: String,
  taken: Boolean,
  healthAssessment: String,
  administrationInstruction: String,
});

module.exports = mongoose.model('Patient', patientSchema);
