const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  userType: { 
    type: String, 
    enum: ['Family Member', 'Nurse', 'Nutritionist'], // Add other user types if needed
    required: true 
  },
  residentId: { 
    type: mongoose.Schema.Types.ObjectId, // Referencing another collection (e.g., 'Resident')
    ref: 'BasicInformation', // Name of the referenced model
    required: function () {
      return this.userType === 'Family Member'; // residentId is required only for Family Member
    },
  }
});

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// Compare passwords
userSchema.methods.comparePassword = async function (password) {
  return await bcrypt.compare(password, this.password);
};

module.exports = mongoose.model('User', userSchema);
