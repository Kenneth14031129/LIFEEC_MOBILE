// models/User.js
const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: String,
  userType: {
    type: String,
    enum: ["admin", "owner", "nurse", "nutritionist", "relative"],
    required: true,
  },
  isArchived: { type: Boolean, default: false },
  archivedDate: { type: Date, default: null },
  createdAt: { type: Date, default: Date.now },
  otp: {
    code: String,
    expiry: Date,
    verified: { type: Boolean, default: false }
  },
  isVerified: {
    type: Boolean, 
    default: false
  },
  verifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
});

module.exports = mongoose.model("User", userSchema);