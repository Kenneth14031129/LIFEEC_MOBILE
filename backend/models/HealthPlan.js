const mongoose = require("mongoose");

const medicationSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  dosage: String,
  quantity: String,
  medicationTime: String,
  isMedicationTaken: {
    type: Boolean,
    default: false,
  },
});

const healthRecordSchema = new mongoose.Schema(
  {
    residentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Resident",
      required: true,
    },
    date: {
      type: String,
      required: true,
    },
    status: {
      type: String,
      enum: ["Stable", "Critical"],
      default: "Stable",
    },
    allergies: [
      {
        type: String,
        trim: true,
      },
    ],
    medicalCondition: [
      {
        type: String,
        trim: true,
      },
    ],
    medications: [medicationSchema],
    assessment: String,
    instructions: String,
  },
  {
    timestamps: true,
    collection: "healthrecords",
  }
);

const HealthRecord = mongoose.model("HealthRecord", healthRecordSchema);
module.exports = HealthRecord;
