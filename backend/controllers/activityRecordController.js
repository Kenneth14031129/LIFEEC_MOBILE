// activityRecordController.js
const ActivityRecord = require('../models/ActivityRecord');

const activityRecordController = {
  // Get all activity records for a resident
  getActivityRecords: async (req, res) => {
    try {
      const { residentId } = req.params;
      const activityRecords = await ActivityRecord.find({ residentId })
        .sort({ date: -1 }); // Sort by date descending
      res.json(activityRecords);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  },

  // Get a specific activity record by ID
  getActivityRecordById: async (req, res) => {
    try {
      const activityRecord = await ActivityRecord.findById(req.params.id);
      if (!activityRecord) {
        return res.status(404).json({ message: 'Activity record not found' });
      }
      res.json(activityRecord);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  },

  // Create a new activity record
  createActivityRecord: async (req, res) => {
    try {
      const newActivityRecord = new ActivityRecord({
        residentId: req.body.residentId,
        name: req.body.name,
        date: req.body.date,
        description: req.body.description,
        status: req.body.status,
        duration: req.body.duration,
        location: req.body.location,
        notes: req.body.notes
      });

      const savedActivityRecord = await newActivityRecord.save();
      res.status(201).json(savedActivityRecord);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  },

  // Update an activity record
  updateActivityRecord: async (req, res) => {
    try {
      const updatedActivityRecord = await ActivityRecord.findByIdAndUpdate(
        req.params.id,
        {
          name: req.body.name,
          date: req.body.date,
          description: req.body.description,
          status: req.body.status,
          duration: req.body.duration,
          location: req.body.location,
          notes: req.body.notes
        },
        { new: true } // Return updated document
      );

      if (!updatedActivityRecord) {
        return res.status(404).json({ message: 'Activity record not found' });
      }
      res.json(updatedActivityRecord);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  },

  // Delete an activity record
  deleteActivityRecord: async (req, res) => {
    try {
      const deletedActivityRecord = await ActivityRecord.findByIdAndDelete(req.params.id);
      if (!deletedActivityRecord) {
        return res.status(404).json({ message: 'Activity record not found' });
      }
      res.json({ message: 'Activity record deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  },

  // Get latest activity record for a resident
  getLatestActivityRecord: async (req, res) => {
    try {
      const { residentId } = req.params;
      const latestActivityRecord = await ActivityRecord.findOne({ residentId })
        .sort({ date: -1 }); // Sort by date descending and get the first record
      
      if (!latestActivityRecord) {
        return res.status(404).json({ message: 'No activity records found for this resident' });
      }
      res.json(latestActivityRecord);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }
};

module.exports = activityRecordController;