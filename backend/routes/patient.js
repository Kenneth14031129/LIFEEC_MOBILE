const express = require("express");
const router = express.Router();
const { getResidents, uploadInfo, getPatients, getResidentById } = require("../controllers/patient"); // Ensure 'getResidentById' is correctly imported

// Define routes
router.get("/list", getResidents); // For fetching residents
router.post("/add", uploadInfo); // For adding resident info
router.post("/patients-per-month", getPatients); // For getting patients per month
// Get patient by ID
router.get('/:id', async (req, res) => {
    try {
      const patient = await Patient.findById(req.params.id);
      if (!patient) {
        return res.status(404).json({ message: 'Patient not found' });
      }
      res.json(patient);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  });

module.exports = router;

