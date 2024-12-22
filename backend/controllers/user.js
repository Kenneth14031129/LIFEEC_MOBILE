const User = require('../models/user');

// Get all users based on userType filter
const getUsers = async (req, res) => {
  const { userType } = req.query; // Assume userType is passed as a query parameter

  try {
    // Initialize query condition
    let condition = {};

    // Add specific conditions based on userType
    if (userType === 'Family Member') {
      condition = { userType: { $in: ['Nurse', 'Admin'] } };
    } else if (userType === 'Nurse') {
      condition = { userType: { $in: ['Family Member', 'Nutritionist', 'Admin'] } };
    } else if (userType === 'Nutritionist') {
      condition = { userType: { $in: ['Nurse', 'Admin'] } };
    } else {
      condition = { userType: { $in: ['Admin'] } }; // Fallback for unspecified userType
    }

    // Fetch users matching the condition
    const users = await User.find({
      $or: [
        condition,
        { userType: 'Admin' } // Ensure Admin users are always included
      ],
    });

    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Failed to get users' });
  }
};

// Add new user
const addUser = async (req, res) => {
  const { name, subtitle, userType } = req.body;

  if (!name || !userType) {
    return res.status(400).json({ message: 'Name and userType are required' });
  }

  try {
    const newUser = new User({
      name,
      subtitle,
      userType,
    });
    await newUser.save();
    res.status(201).json(newUser);
  } catch (error) {
    res.status(500).json({ message: 'Failed to add user' });
  }
};

// Edit user
const editUser = async (req, res) => {
  const { id } = req.params;
  const { name, subtitle, userType } = req.body;

  try {
    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Update fields
    user.name = name || user.name;
    user.subtitle = subtitle || user.subtitle;
    user.userType = userType || user.userType;
    await user.save();

    res.status(200).json(user);
  } catch (error) {
    console.error('Failed to update user:', error);
    res.status(500).json({ message: 'Failed to edit user' });
  }
};

// Delete user
const deleteUser = async (req, res) => {
  const { id } = req.params;

  try {
    const user = await User.findByIdAndDelete(id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(204).send(); // Successfully deleted
  } catch (error) {
    console.error('Failed to delete user:', error);
    res.status(500).json({ message: 'Failed to delete user' });
  }
};

const updateProfile = async (req, res) => {
  const { id } = req.params;
  const { name, email, password } = req.body;

  console.log('[INFO] Received request to update profile');
  console.log(`[INFO] User ID: ${id}`);
  console.log(`[INFO] Update Data:`, { name, email, password: password ? '*****' : null });

  try {
    // Find the user by ID
    const user = await User.findById(id);
    if (!user) {
      console.log('[ERROR] User not found');
      return res.status(404).json({ message: 'User not found' });
    }

    // Log current user data
    console.log('[INFO] Current User Data:', user);

    // Update fields if provided
    if (name) user.name = name;
    if (email) user.email = email;
    if (password) {
      const bcrypt = require('bcryptjs');
      user.password = await bcrypt.hash(password, 10);
      console.log('[INFO] Password updated');
    }

    // Save the updated user
    const updatedUser = await user.save();

    // Log updated user data
    console.log('[INFO] Updated User Data:', updatedUser);

    res.status(200).json({ message: 'Profile updated successfully', user: updatedUser });
  } catch (error) {
    console.error('[ERROR] Failed to update profile:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

module.exports = { updateProfile };

module.exports = {
  getUsers,
  addUser,
  editUser,
  deleteUser,
  updateProfile,
};
