const EmergencyAlert = require('../models/emergencyAlertModel');
const Resident = require('../models/Basicinformation'); // Assuming you have a Resident model

// Fetch emergency alerts by residentId and within the last 24 hours
exports.getEmergencyAlertsByResident = async (req, res) => {
  const { residentId } = req.query;

  if (!residentId) {
    return res.status(400).json({ message: 'Resident ID is required' });
  }

  try {
    console.log('[INFO] Fetching emergency alerts for resident:', residentId);

    // Calculate the timestamp for 24 hours ago
    const twentyFourHoursAgo = new Date();
    twentyFourHoursAgo.setHours(twentyFourHoursAgo.getHours() - 24);

    // Fetch alerts for the resident within the last 24 hours
    const alerts = await EmergencyAlert.find({
      residentId,
      timestamp: { $gte: twentyFourHoursAgo },
    });

    console.log('[INFO] Found emergency alerts:', alerts);
    return res.status(200).json(alerts);
  } catch (error) {
    console.error('[ERROR] Error fetching emergency alerts:', error);
    return res.status(500).json({ message: 'Internal server error' });
  }
};


// Create a new emergency alert
exports.createEmergencyAlert = async (req, res) => {
  const { residentId, residentName, message } = req.body;

  if (!residentId || !residentName || !message) {
    console.warn('[WARN] Missing fields in createEmergencyAlert:', {
      residentId,
      residentName,
      message,
    });
    return res.status(400).json({ message: 'All fields are required' });
  }

  try {
    console.log('[INFO] Creating new emergency alert:', {
      residentId,
      residentName,
      message,
    });
    const newAlert = new EmergencyAlert({
      residentId,
      residentName,
      message,
      timestamp: new Date(),
    });

    await newAlert.save();

    console.log('[INFO] Emergency alert created successfully:', newAlert);
    return res.status(201).json({ message: 'Emergency alert created successfully' });
  } catch (error) {
    console.error('[ERROR] Failed to create emergency alert:', error);
    return res.status(500).json({ message: 'Failed to create emergency alert' });
  }
};

// Delete an emergency alert
exports.deleteEmergencyAlert = async (req, res) => {
  const { id } = req.params;

  try {
    console.log('[INFO] Deleting emergency alert with ID:', id);
    await EmergencyAlert.findByIdAndDelete(id);
    console.log('[INFO] Emergency alert deleted successfully:', id);
    return res.status(200).json({ message: 'Emergency alert deleted successfully' });
  } catch (error) {
    console.error('[ERROR] Error deleting emergency alert:', error);
    return res.status(500).json({ message: 'Failed to delete emergency alert' });
  }
};

// Get alert count grouped by month for a specified year
exports.getAlertsCountByMonth = async (req, res) => {
  const { year } = req.query;

  try {
    const selectedYear = year ? parseInt(year) : new Date().getFullYear();
    console.log('[INFO] Fetching alert counts for year:', selectedYear);

    const alertsByMonth = await EmergencyAlert.aggregate([
      {
        $match: {
          timestamp: {
            $gte: new Date(`${selectedYear}-01-01T00:00:00Z`),
            $lte: new Date(`${selectedYear}-12-31T23:59:59Z`),
          },
        },
      },
      {
        $group: {
          _id: { $month: '$timestamp' },
          count: { $sum: 1 },
        },
      },
      {
        $sort: { '_id': 1 },
      },
    ]);

    console.log('[INFO] Alert counts grouped by month:', alertsByMonth);

    const monthlyCounts = Array(12).fill(0);
    alertsByMonth.forEach(({ _id, count }) => {
      monthlyCounts[_id - 1] = count; // MongoDB months are 1-indexed
    });

    console.log('[INFO] Monthly alert counts:', monthlyCounts);
    return res.status(200).json(monthlyCounts);
  } catch (error) {
    console.error('[ERROR] Error fetching alerts count by month:', error);
    return res.status(500).json({ message: 'Failed to fetch alerts count by month' });
  }
};

// Fetch dashboard summary metrics
exports.getDashboardSummary = async (req, res) => {
  try {
    console.log('[INFO] Fetching dashboard summary metrics');
    const totalResidents = await Resident.countDocuments();
    const totalAlerts = await EmergencyAlert.countDocuments();
    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

    console.log('[INFO] Fetching active residents');
    const activeResidents = await EmergencyAlert.distinct('residentId', {
      timestamp: { $gte: oneMonthAgo },
    });

    const summary = {
      totalResidents,
      totalAlerts,
      activeResidents: activeResidents.length,
    };

    console.log('[INFO] Dashboard summary metrics:', summary);
    return res.status(200).json(summary);
  } catch (error) {
    console.error('[ERROR] Error fetching dashboard summary:', error);
    return res.status(500).json({ message: 'Failed to fetch dashboard summary' });
  }
};
