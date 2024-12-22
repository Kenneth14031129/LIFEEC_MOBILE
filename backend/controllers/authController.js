const User = require('../models/user');
const jwt = require('jsonwebtoken');
const crypto = require('crypto'); // For token generation and hashing
const nodemailer = require('nodemailer');
const bcrypt = require('bcryptjs'); // For password hashing

const sendResetEmail = async (email, token) => {
  const transporter = nodemailer.createTransport({
    service: 'Gmail', // Or any other email service
    auth: {
      user: process.env.EMAIL_USER, // Your email address
      pass: process.env.EMAIL_PASS, // Your email password
    },
  });

  const resetURL = `http://localhost:3000/reset-password/${token}`; // Adjust to your frontend URL

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Password Reset Request',
    text: `You requested a password reset. Please click the link below to reset your password:\n\n${resetURL}\n\nIf you did not request this, please ignore this email.`,
    html: `<p>You requested a password reset. Please click the link below to reset your password:</p>
           <a href="${resetURL}">${resetURL}</a>
           <p>If you did not request this, please ignore this email.</p>`,
  };

  await transporter.sendMail(mailOptions);
};

exports.signin = async (req, res) => {
  const { email, password } = req.body;

  // Validate input
  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  try {
    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      console.log('User not found for email:', email);
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Log the hashed password stored in the database
    console.log('Hashed password stored in database:', user.password);

    // Compare entered password with stored hash
    const isMatch = await user.comparePassword(password);

    // Log comparison result
    console.log('Password provided by user:', password);
    console.log('Result of bcrypt.compare():', isMatch);

    if (!isMatch) {
      console.log('Password mismatch for user:', user.email);
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, userType: user.userType },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    // Log successful sign-in
    console.log('User successfully signed in:', {
      id: user._id,
      name: user.name,
      userType: user.userType,
      residentId: user.residentId ? user.residentId.toString() : null,
    });

    // Send response with user data and token
    res.status(200).json({
      token,
      userType: user.userType,
      name: user.name,
      id: user._id,
      residentId: user.residentId ? user.residentId.toString() : null,
    });
  } catch (error) {
    console.error('Sign in error:', error);
    res.status(500).json({ error: 'An error occurred while processing your request' });
  }
};


// Forgot Password
exports.forgotPassword = async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: 'Email is required' });
  }

  try {
    // Look for user with the given email
    const user = await User.findOne({ email: email.trim() });

    if (!user) {
      console.log('[ERROR] Email not found:', email);
      return res.status(404).json({ message: 'Email not found' });
    }

    // Generate token and save it
    const resetToken = crypto.randomBytes(32).toString('hex');
    user.resetPasswordToken = crypto.createHash('sha256').update(resetToken).digest('hex');
    user.resetPasswordExpire = Date.now() + 10 * 60 * 1000; // Token valid for 10 minutes
    await user.save();

    // Send email (pseudo-function)
    console.log('[INFO] Sending reset email to:', user.email);
    await sendResetEmail(user.email, resetToken);

    res.status(200).json({ message: 'Password reset email sent' });
  } catch (error) {
    console.error('[ERROR] Forgot password process failed:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// Reset Password
exports.resetPassword = async (req, res) => {
  const { token } = req.params;
  const { password } = req.body;

  if (!password) {
    return res.status(400).json({ message: 'Password is required' });
  }

  // Hash the token to compare with the one in the database
  const hashedToken = crypto.createHash('sha256').update(token).digest('hex');

  try {
    // Find the user by the hashed token and ensure the token has not expired
    const user = await User.findOne({
      resetPasswordToken: hashedToken,
      resetPasswordExpire: { $gt: Date.now() },
    });

    if (!user) {
      console.error('[ERROR] Invalid or expired token:', token);
      return res.status(400).json({ message: 'Invalid or expired token' });
    }

    // Update the password and clear the reset token fields
    user.password = password; // Ensure to hash the password in your User model's pre-save hook
    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;

    await user.save();

    console.log('[INFO] Password reset successfully for user:', { id: user._id });

    res.status(200).json({ message: 'Password has been reset successfully' });
  } catch (error) {
    console.error('[ERROR] Password reset process failed:', error);
    res.status(500).json({ message: 'An error occurred while processing your request' });
  }
};
