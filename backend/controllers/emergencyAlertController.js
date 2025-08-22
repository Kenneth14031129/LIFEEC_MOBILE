// controllers/emergencyAlertController.js
const EmergencyAlert = require('../models/EmergencyAlert');
const Resident = require('../models/Resident');
const User = require('../models/User');
const { sendEmergencyEmail } = require('../utils/emailService');

// Helper function to send email notifications
async function sendEmailNotification(recipient, residentName, message) {
  try {
    const result = await sendEmergencyEmail(recipient, residentName, message);
    if (result) {
      console.log(`Email notification sent to ${recipient}`);
      return true;
    } else {
      console.error(`Failed to send email to ${recipient}`);
      return false;
    }
  } catch (error) {
    console.error(`Error sending email to ${recipient}:`, error);
    return false;
  }
}

// Helper function to notify all relevant users
async function notifyRelevantUsers(resident, alert) {
  try {
    // Get all nurses, admins, and owners
    const staffUsers = await User.find({
      userType: { $in: ['nurse', 'admin', 'owner'] },
      isArchived: false,
      isVerified: true
    });

    // Get relative(s) associated with the resident
    const relatives = await User.find({
      userType: 'relative',
      isArchived: false,
      isVerified: true,
      associatedResident: resident._id
    });

    // Combine all users to notify
    const usersToNotify = [...staffUsers, ...relatives];

    // Send email notifications
    const emailPromises = usersToNotify.map(user => 
      sendEmailNotification(
        user.email,
        resident.fullName,
        alert.message
      )
    );

    // Wait for all emails to be sent
    const emailResults = await Promise.allSettled(emailPromises);
    const successfulEmails = emailResults.filter(result => result.status === 'fulfilled').length;

    return {
      notifiedUsers: usersToNotify.length,
      staffNotified: staffUsers.length,
      relativesNotified: relatives.length,
      emailsSent: successfulEmails
    };
  } catch (error) {
    console.error('Error in notifyRelevantUsers:', error);
    throw error;
  }
}

exports.getEmergencyAlerts = async (req, res) => {
  try {
    const { userType, email, userId } = req.query;
    let query = {};

    if (userType === 'relative') {
      // First find all residents where this relative is listed as emergency contact
      const associatedResidents = await Resident.find({
        'emergencyContact.email': email
      }).select('_id');

      if (associatedResidents.length === 0) {
        return res.status(200).json([]); // Return empty array if no associated residents
      }

      // Get alerts for all associated residents
      query = {
        residentId: {
          $in: associatedResidents.map(resident => resident._id)
        }
      };
    }

    const alerts = await EmergencyAlert.find(query)
      .sort({ timestamp: -1 })
      .populate('residentId', 'fullName')
      .lean();

    // Add additional processing for relative-specific information
    const processedAlerts = alerts.map(alert => ({
      ...alert,
      isRelevant: userType === 'relative' ? 
        alert.emergencyContact?.email === email : true
    }));

    res.status(200).json(processedAlerts);
  } catch (error) {
    console.error('Error fetching emergency alerts:', error);
    res.status(500).json({ 
      message: 'Error fetching emergency alerts',
      error: error.message 
    });
  }
};

// Update createEmergencyAlert to handle relative notifications better
exports.createEmergencyAlert = async (req, res) => {
  try {
    const { residentId } = req.body;

    // Find resident and their emergency contacts
    const resident = await Resident.findById(residentId)
      .populate({
        path: 'emergencyContact',
        select: 'email name phone relation'
      });

    if (!resident) {
      return res.status(404).json({ message: 'Resident not found' });
    }

    // Find relative users associated with this resident's emergency contact
    const relativeUsers = await User.find({
      userType: 'relative',
      email: resident.emergencyContact.email,
      isVerified: true,
      isArchived: false
    });

    // Create emergency alert
    const emergencyAlert = new EmergencyAlert({
      residentId: resident._id,
      residentName: resident.fullName,
      message: `Emergency alert triggered`,
      emergencyContact: {
        name: resident.emergencyContact.name,
        phone: resident.emergencyContact.phone,
        email: resident.emergencyContact.email,
        relation: resident.emergencyContact.relation
      }
    });

    await emergencyAlert.save();

    // Notify relevant users
    const notificationResults = await notifyRelevantUsers(resident, emergencyAlert, relativeUsers);

    res.status(201).json({ 
      message: 'Emergency alert created and notifications sent successfully',
      alert: emergencyAlert,
      notificationStats: notificationResults
    });
  } catch (error) {
    console.error('Error creating emergency alert:', error);
    res.status(500).json({ 
      message: 'Error creating emergency alert',
      error: error.message 
    });
  }
};

// Get emergency alerts for a specific resident
exports.getEmergencyAlertsByResident = async (req, res) => {
  try {
    const { residentId } = req.params;
    
    const alerts = await EmergencyAlert.find({ residentId })
      .sort({ timestamp: -1 })
      .populate('residentId', 'fullName');

    res.status(200).json(alerts);
  } catch (error) {
    console.error('Error fetching resident emergency alerts:', error);
    res.status(500).json({ 
      message: 'Error fetching resident emergency alerts',
      error: error.message 
    });
  }
};

// Mark alert as read
exports.markAlertAsRead = async (req, res) => {
  try {
    const { alertId } = req.params;
    
    const alert = await EmergencyAlert.findByIdAndUpdate(
      alertId,
      { read: true },
      { new: true }
    );
    
    if (!alert) {
      return res.status(404).json({ message: 'Alert not found' });
    }
    
    res.status(200).json({
      message: 'Alert marked as read',
      alert
    });
  } catch (error) {
    console.error('Error marking alert as read:', error);
    res.status(500).json({ 
      message: 'Error updating alert status',
      error: error.message 
    });
  }
};

// Delete alerts older than 24 hours
exports.deleteOldAlerts = async (req, res) => {
  try {
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    
    const result = await EmergencyAlert.deleteMany({
      timestamp: { $lt: twentyFourHoursAgo }
    });

    res.status(200).json({
      message: 'Old alerts deleted successfully',
      deletedCount: result.deletedCount
    });
  } catch (error) {
    console.error('Error deleting old alerts:', error);
    res.status(500).json({ 
      message: 'Error deleting old alerts',
      error: error.message 
    });
  }
};

// Get unread alerts count
exports.getUnreadAlertsCount = async (req, res) => {
  try {
    const count = await EmergencyAlert.countDocuments({ read: false });
    
    res.status(200).json({
      unreadCount: count
    });
  } catch (error) {
    console.error('Error getting unread alerts count:', error);
    res.status(500).json({ 
      message: 'Error getting unread alerts count',
      error: error.message 
    });
  }
};