// ActivityRecord.js
const mongoose = require('mongoose');

const activityRecordSchema = new mongoose.Schema({
  residentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Resident',
    required: true
  },
  name: {
    type: String,
    required: true
  },
  date: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['Scheduled', 'In Progress', 'Completed', 'Cancelled'],
    default: 'Not Started'
  },
  duration: {
    type: Number,
    required: true
  },
  location: {
    type: String,
    required: true
  },
  notes: {
    type: String,
    required: true
  }
}, {
  timestamps: true,
  collection: 'activitiesrecords' // Explicitly set collection name
});

const ActivityRecord = mongoose.model('ActivityRecord', activityRecordSchema);
module.exports = ActivityRecord;
