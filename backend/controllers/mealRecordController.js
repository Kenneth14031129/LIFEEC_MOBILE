// mealRecordController.js
const MealRecord = require('../models/MealRecord');

const mealRecordController = {
  // Get all meal records for a resident
  getMealRecords: async (req, res) => {
    try {
      const { residentId } = req.params;
      const mealRecords = await MealRecord.find({ residentId })
        .sort({ date: -1 }); // Sort by date descending
      res.json(mealRecords);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  },

  // Get a specific meal record by ID
  getMealRecordById: async (req, res) => {
    try {
      const mealRecord = await MealRecord.findById(req.params.id);
      if (!mealRecord) {
        return res.status(404).json({ message: 'Meal record not found' });
      }
      res.json(mealRecord);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  },

  // Create a new meal record
  createMealRecord: async (req, res) => {
    try {
      const newMealRecord = new MealRecord({
        residentId: req.body.residentId,
        dietaryNeeds: req.body.dietaryNeeds,
        nutritionalGoals: req.body.nutritionalGoals,
        date: req.body.date,
        breakfast: Array.isArray(req.body.breakfast) ? req.body.breakfast : [req.body.breakfast],
        lunch: Array.isArray(req.body.lunch) ? req.body.lunch : [req.body.lunch],
        snacks: Array.isArray(req.body.snacks) ? req.body.snacks : [req.body.snacks],
        dinner: Array.isArray(req.body.dinner) ? req.body.dinner : [req.body.dinner]
      });

      const savedMealRecord = await newMealRecord.save();
      res.status(201).json(savedMealRecord);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  },

  updateMealRecord: async (req, res) => {
    try {
      const updatedMealRecord = await MealRecord.findByIdAndUpdate(
        req.params.id,
        {
          dietaryNeeds: req.body.dietaryNeeds,
          nutritionalGoals: req.body.nutritionalGoals,
          date: req.body.date,
          breakfast: Array.isArray(req.body.breakfast) ? req.body.breakfast : [req.body.breakfast],
          lunch: Array.isArray(req.body.lunch) ? req.body.lunch : [req.body.lunch],
          snacks: Array.isArray(req.body.snacks) ? req.body.snacks : [req.body.snacks],
          dinner: Array.isArray(req.body.dinner) ? req.body.dinner : [req.body.dinner]
        },
        { new: true }
      );

      if (!updatedMealRecord) {
        return res.status(404).json({ message: 'Meal record not found' });
      }
      res.json(updatedMealRecord);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  },

  // Delete a meal record
  deleteMealRecord: async (req, res) => {
    try {
      const deletedMealRecord = await MealRecord.findByIdAndDelete(req.params.id);
      if (!deletedMealRecord) {
        return res.status(404).json({ message: 'Meal record not found' });
      }
      res.json({ message: 'Meal record deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  },

  // Get latest meal record for a resident
  getLatestMealRecord: async (req, res) => {
    try {
      const { residentId } = req.params;
      const latestMealRecord = await MealRecord.findOne({ residentId })
        .sort({ date: -1 }); // Sort by date descending and get the first record
      
      if (!latestMealRecord) {
        return res.status(404).json({ message: 'No meal records found for this resident' });
      }
      res.json(latestMealRecord);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }
};

module.exports = mealRecordController;