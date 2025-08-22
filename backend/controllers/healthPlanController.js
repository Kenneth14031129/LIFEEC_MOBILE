const mongoose = require("mongoose");
const HealthPlan = require("../models/HealthPlan");

const healthPlanController = {
  // Get health plan by resident ID
  getHealthPlan: async (req, res) => {
    try {
      console.log(
        "Looking for health plan with residentId:",
        req.params.residentId
      );

      const healthPlan = await HealthPlan.findOne({
        residentId: new mongoose.Types.ObjectId(req.params.residentId),
      }).sort({ createdAt: -1 });

      if (!healthPlan) {
        console.log("No health plan found for resident");
        return res.status(404).json({ message: "Health plan not found" });
      }

      console.log("Found health plan:", healthPlan);
      res.json(healthPlan);
    } catch (error) {
      console.error("Error in getHealthPlan:", error);
      res.status(500).json({ message: error.message });
    }
  },

  // Get health history for a resident
  getHealthHistory: async (req, res) => {
    try {
      console.log(
        "Fetching health history for residentId:",
        req.params.residentId
      );

      const healthRecords = await HealthPlan.find({
        residentId: new mongoose.Types.ObjectId(req.params.residentId),
      }).sort({ createdAt: -1 }); // Sort by creation date, newest first

      if (!healthRecords || healthRecords.length === 0) {
        console.log("No health records found for resident");
        return res.status(404).json({ message: "No health records found" });
      }

      console.log(`Found ${healthRecords.length} health records`);
      res.json(healthRecords);
    } catch (error) {
      console.error("Error in getHealthHistory:", error);
      res.status(500).json({ message: error.message });
    }
  },

  // Get health plan by ID
  getHealthPlanById: async (req, res) => {
    try {
      const healthPlan = await HealthPlan.findById(req.params.id);

      if (!healthPlan) {
        return res.status(404).json({ message: "Health plan not found" });
      }

      res.json(healthPlan);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  },

  // Create new health plan
  createHealthPlan: async (req, res) => {
    try {
      const healthPlan = new HealthPlan({
        residentId: new mongoose.Types.ObjectId(req.body.residentId),
        date: req.body.date,
        status: req.body.status,
        allergies: req.body.allergies,
        medicalCondition: req.body.medicalCondition,
        medications: req.body.medications.map((med) => ({
          name: med.name,
          dosage: med.dosage,
          quantity: med.quantity,
          medicationTime: med.medicationTime,
          isMedicationTaken: med.isMedicationTaken,
        })),
        assessment: req.body.assessment,
        instructions: req.body.instructions,
      });

      const newHealthPlan = await healthPlan.save();
      res.status(201).json(newHealthPlan);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  },

  // Update health plan
  updateHealthPlan: async (req, res) => {
    try {
      console.log("Incoming update data:", req.body);
      const healthPlan = await HealthPlan.findById(req.params.id);

      if (!healthPlan) {
        return res.status(404).json({ message: "Health plan not found" });
      }

      const updateData = {
        ...req.body,
        allergies: Array.isArray(req.body.allergies)
          ? req.body.allergies
          : req.body.allergies?.split(",").map((item) => item.trim()),
        medicalCondition: Array.isArray(req.body.medicalCondition)
          ? req.body.medicalCondition
          : req.body.medicalCondition?.split(",").map((item) => item.trim()),
        medications: Array.isArray(req.body.medications)
          ? req.body.medications.map((med) => ({
              name: med.name,
              dosage: med.dosage,
              quantity: med.quantity,
              medicationTime: med.medicationTime,
              isMedicationTaken: med.isMedicationTaken,
            }))
          : [],
      };

      Object.assign(healthPlan, updateData);
      const updatedHealthPlan = await healthPlan.save();
      res.json(updatedHealthPlan);
    } catch (error) {
      console.error("Error updating health plan:", error);
      res.status(400).json({ message: error.message });
    }
  },
};

module.exports = healthPlanController;
