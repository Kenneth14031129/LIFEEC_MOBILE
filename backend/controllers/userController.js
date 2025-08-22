// controllers/userController.js
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/User");
const Message = require("../models/Message");
const { sendOTP } = require('../utils/emailService');

// Generate OTP function
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Modify registerUser function
exports.registerUser = async (req, res) => {
  try {
    const { fullName, email, password, phone, userType } = req.body;

    // Validate user type
    const validUserTypes = ["nurse", "nutritionist", "relative", "admin", "owner"];
    if (!validUserTypes.includes(userType)) {
      return res.status(400).json({
        message: "Invalid user type. Must be nurse, nutritionist, relative, admin, or owner",
      });
    }

    // Check if user exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: "User already exists" });
    }

    // Generate OTP
    const otp = generateOTP();
    const otpExpiry = new Date();
    otpExpiry.setMinutes(otpExpiry.getMinutes() + 10); // OTP expires in 10 minutes

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create new user (with isVerified set to false by default)
    user = new User({
      fullName,
      email,
      password: hashedPassword,
      phone,
      userType,
      otp: {
        code: otp,
        expiry: otpExpiry,
        verified: false
      },
      isVerified: false // Explicitly set to false
    });

    await user.save();

    // Send OTP email
    const emailSent = await sendOTP(email, otp);
    if (!emailSent) {
      return res.status(500).json({ message: "Failed to send verification email" });
    }

    res.status(201).json({
      message: "Registration successful. Please verify your email with the OTP sent.",
      userId: user._id,
      isVerified: user.isVerified
    });
  } catch (error) {
    console.error("Registration error:", error);
    res.status(500).json({ message: "Server error during registration" });
  }
};

// Add verify OTP endpoint
exports.verifyOTP = async (req, res) => {
  try {
    const { userId, otp } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (user.otp.verified) {
      return res.status(400).json({ message: "Email already verified" });
    }

    if (user.otp.code !== otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    if (new Date() > user.otp.expiry) {
      return res.status(400).json({ message: "OTP expired" });
    }

    // Mark OTP as verified
    user.otp.verified = true;
    
    // Set isVerified to false by default
    user.isVerified = false;
    
    await user.save();

    res.json({
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        userType: user.userType,
        isVerified: user.isVerified
      },
      message: "Email verified successfully. Awaiting admin approval."
    });
  } catch (error) {
    console.error("OTP verification error:", error);
    res.status(500).json({ message: "Server error during verification" });
  }
};

// Add resend OTP endpoint
exports.resendOTP = async (req, res) => {
  try {
    const { userId } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (user.otp.verified) {
      return res.status(400).json({ message: "Email already verified" });
    }

    // Generate new OTP
    const newOTP = generateOTP();
    const otpExpiry = new Date();
    otpExpiry.setMinutes(otpExpiry.getMinutes() + 10);

    user.otp = {
      code: newOTP,
      expiry: otpExpiry,
      verified: false
    };

    await user.save();

    // Send new OTP
    const emailSent = await sendOTP(user.email, newOTP);
    if (!emailSent) {
      return res.status(500).json({ message: "Failed to send verification email" });
    }

    res.json({ message: "New OTP sent successfully" });
  } catch (error) {
    console.error("Resend OTP error:", error);
    res.status(500).json({ message: "Server error during OTP resend" });
  }
};

// Login user
exports.loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check if user exists
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    // Check if user is archived
    if (user.isArchived) {
      return res.status(403).json({
        message: "This account has been archived. Please contact your administrator.",
      });
    }

    // Check if user is verified
    if (!user.isVerified) {
      return res.status(403).json({
        message: "Account is pending verification. Please wait for admin approval.",
        needsVerification: true
      });
    }

    // Validate user type
    const validUserTypes = ["admin", "owner", "nurse", "nutritionist", "relative"];
    if (!validUserTypes.includes(user.userType)) {
      return res.status(400).json({
        message: "Invalid user type. Please contact administrator",
      });
    }

    // Validate password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    res.json({
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        userType: user.userType,
        isArchived: user.isArchived,
        isVerified: user.isVerified,
        archivedDate: user.archivedDate,
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ message: "Server error during login" });
  }
};

exports.approveUserVerification = async (req, res) => {
  try {
    const { userId } = req.params;
    const { currentAdminId } = req.body; // ID of the admin/owner approving

    // Validate that the current user is an admin or owner
    const adminUser = await User.findById(currentAdminId);
    if (!adminUser || !['admin', 'owner'].includes(adminUser.userType)) {
      return res.status(403).json({ message: "Unauthorized to verify users" });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Check if user is already verified
    if (user.isVerified) {
      return res.status(400).json({ message: "User is already verified" });
    }

    // Update user verification status
    user.isVerified = true;
    user.verifiedBy = currentAdminId;
    await user.save();

    res.json({ 
      message: "User verified successfully",
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        isVerified: user.isVerified
      }
    });
  } catch (error) {
    console.error("User verification error:", error);
    res.status(500).json({ message: "Server error during user verification" });
  }
};

// Get unverified users (for admin/owner)
exports.getUnverifiedUsers = async (req, res) => {
  try {
    const { currentAdminId } = req.query;

    // Validate that the current user is an admin or owner
    const adminUser = await User.findById(currentAdminId);
    if (!adminUser || !['admin', 'owner'].includes(adminUser.userType)) {
      return res.status(403).json({ message: "Unauthorized to view unverified users" });
    }

    // Find all unverified users
    const unverifiedUsers = await User.find({ 
      isVerified: false,
      isArchived: false
    }).select("fullName email userType createdAt");

    res.json({
      unverifiedUsers
    });
  } catch (error) {
    console.error("Get unverified users error:", error);
    res.status(500).json({ message: "Server error retrieving unverified users" });
  }
};

exports.archiveUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { isArchived } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    user.isArchived = isArchived;
    user.archivedDate = isArchived ? new Date() : null;
    await user.save();

    res.json({
      message: `User ${isArchived ? "archived" : "unarchived"} successfully`,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        userType: user.userType,
        isArchived: user.isArchived,
        archivedDate: user.archivedDate,
      },
    });
  } catch (error) {
    console.error("Archive user error:", error);
    res
      .status(500)
      .json({ message: "Server error during user archive operation" });
  }
};

// Get user profile
exports.getUserProfile = async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await User.findById(userId).select("-password");
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    res.json(user);
  } catch (error) {
    console.error("Get profile error:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Update user profile
exports.updateUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { fullName, email, phone } = req.body;

    // Check if email already exists for another user
    const existingUser = await User.findOne({
      email,
      _id: { $ne: userId },
    });

    if (existingUser) {
      return res.status(400).json({
        message: "Email already in use by another account",
      });
    }

    // Validate the data
    if (!fullName || !email) {
      return res.status(400).json({
        message: "Full name and email are required",
      });
    }

    // Email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        message: "Please provide a valid email address",
      });
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        fullName,
        email,
        phone,
        updatedAt: Date.now(),
      },
      {
        new: true,
        runValidators: true,
      }
    ).select("-password");

    if (!updatedUser) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({
      message: "Profile updated successfully",
      user: updatedUser,
    });
  } catch (error) {
    console.error("Update user error:", error);
    res.status(500).json({
      message: "Server error during profile update",
      error: error.message,
    });
  }
};

// Delete user
exports.deleteUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const deletedUser = await User.findByIdAndDelete(userId);

    if (!deletedUser) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({ message: "User deleted successfully" });
  } catch (error) {
    console.error("Delete user error:", error);
    res.status(500).json({ message: "Server error during deletion" });
  }
};

// Change password
exports.changePassword = async (req, res) => {
  try {
    const { userId } = req.params;
    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Verify current password
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Current password is incorrect" });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    // Update password
    user.password = hashedPassword;
    await user.save();

    res.json({ message: "Password updated successfully" });
  } catch (error) {
    console.error("Change password error:", error);
    res.status(500).json({ message: "Server error during password change" });
  }
};

// Helper function to capitalize first letter
function capitalizeFirstLetter(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}

exports.getContactsList = async (req, res) => {
  try {
    const currentUserId = req.query.currentUserId;

    if (!currentUserId) {
      return res.status(400).json({
        success: false,
        message: "currentUserId is required",
      });
    }

    // Get all non-archived users with specified roles
    const users = await User.find({
      userType: {
        $in: ["admin", "nurse", "nutritionist", "relative"],
      },
      isArchived: { $ne: true } // Exclude archived users
    }).select("fullName userType email phone createdAt isArchived");

    // Get last messages and unread counts for each conversation
    const conversationStats = await Message.aggregate([
      // First stage: Match messages involving current user
      {
        $match: {
          $or: [{ senderId: currentUserId }, { receiverId: currentUserId }],
        },
      },
      // Sort messages by timestamp descending to get latest first
      {
        $sort: { timestamp: -1 },
      },
      // Group by conversation partner and calculate stats
      {
        $group: {
          _id: {
            $cond: {
              if: { $eq: ["$senderId", currentUserId] },
              then: "$receiverId",
              else: "$senderId",
            },
          },
          lastMessage: { $first: "$$ROOT" },
          unreadCount: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ["$receiverId", currentUserId] },
                    { $eq: ["$isRead", false] },
                  ],
                },
                1,
                0,
              ],
            },
          },
        },
      },
      // Project the fields we need
      {
        $project: {
          _id: 1,
          lastMessage: 1,
          unreadCount: 1,
        },
      },
    ]);

    // Create a map of conversation stats for quick lookup
    const statsMap = new Map();
    conversationStats.forEach((item) => {
      statsMap.set(item._id.toString(), {
        lastMessage: item.lastMessage,
        unreadCount: item.unreadCount,
      });
    });

    // Transform the data to match the contact list format
    const contacts = users
      .filter((user) => 
        user._id.toString() !== currentUserId &&  // Exclude current user
        !user.isArchived  // Double-check to exclude archived users
      )
      .map((user) => {
        const stats = statsMap.get(user._id.toString()) || {};

        return {
          name: user.fullName,
          role: capitalizeFirstLetter(user.userType),
          lastMessage: stats.lastMessage
            ? stats.lastMessage.content
            : "No messages yet",
          lastMessageTime: stats.lastMessage
            ? stats.lastMessage.timestamp
            : user.createdAt,
          isOnline: false,
          email: user.email,
          phone: user.phone,
          userId: user._id,
          unreadCount: stats.unreadCount || 0,
          isArchived: user.isArchived || false
        };
      });

    // Group contacts by role
    const groupedContacts = contacts.reduce((acc, contact) => {
      if (!acc[contact.role]) {
        acc[contact.role] = [];
      }
      acc[contact.role].push(contact);
      return acc;
    }, {});

    // Send the response
    res.status(200).json({
      success: true,
      contacts: groupedContacts,
    });
  } catch (error) {
    console.error("Get contacts error:", error);
    res.status(500).json({
      success: false,
      message: "Error retrieving contacts",
      error: error.message,
    });
  }
};

// Add this new function to get a specific user's contact details
exports.getContactDetails = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId).select(
      "fullName userType email phone createdAt"
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "Contact not found",
      });
    }

    const contact = {
      name: user.fullName,
      role: capitalizeFirstLetter(user.userType),
      email: user.email,
      phone: user.phone,
      userId: user._id,
      isOnline: false,
    };

    res.status(200).json({
      success: true,
      contact,
    });
  } catch (error) {
    console.error("Get contact details error:", error);
    res.status(500).json({
      success: false,
      message: "Error retrieving contact details",
      error: error.message,
    });
  }
};
