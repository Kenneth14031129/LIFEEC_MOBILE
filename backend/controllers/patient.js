const BasicInformation = require("../models/Basicinformation");

const uploadInfo = async (req, res) => {
    try {
        const {
            name,
            age,
            gender,
            contact,
            emergencyContactName,
            emergencyContactPhone,
        } = req.body;
        //comment
        // Check if all required fields are present
        if (!name || !age || !gender || !contact || !emergencyContactName || !emergencyContactPhone) {
            return res.status(400).json({ message: "All fields are required" });
        }

        // Create a new entry based on the submitted data
        const newEntry = new BasicInformation({
            name,
            age,
            gender,
            contact,
            emergencyContact: {
                name: emergencyContactName,
                phone: emergencyContactPhone
            }
        });

        // Save the new entry to the database
        const savedEntry = await newEntry.save();

        // Send a success response
        res.status(201).json({ message: 'Document saved successfully', data: savedEntry });
    } catch (error) {
        console.error('Error saving document:', error);
        if (error.name === 'ValidationError') {
            // Handle Mongoose validation errors
            const validationErrors = Object.values(error.errors).map(err => err.message);
            return res.status(400).json({ message: 'Validation error', errors: validationErrors });
        }
        res.status(500).json({ message: 'Error saving document', error: error.message });
    }
};

const getResidents = async (req, res) => {
    try {
        const patients = await BasicInformation.find();
        res.status(200).json(patients);
    } catch (error) {
        res.status(500).json({ message: "Error fetching residents", error: error.message });
    }
};

const getPatients = async (req, res) => {
    try {
        const counts = await BasicInformation.aggregate([
            {
                $group: {
                    _id: "$month", // Group by month
                    count: { $sum: 1 }
                }
            },
            {
                $sort: { _id: 1 } // Sort by month
            }
        ]);

        res.json(counts);
    } catch (error) {
        console.error("Error fetching patient counts:", error);
        res.status(500).json({ message: 'Internal server error', error: error.message });
    }
};

// Retrieve data for a specific resident by ID
const getResidentById = async (req, res) => {
    try {
        const { id } = req.params; // Resident ID from URL params

        // Find the resident by ID
        const patient = await BasicInformation.findById(id);

        if (!patient) {
            return res.status(404).json({ message: "Resident not found" });
        }

        // Return the resident's data
        res.status(200).json(patient);
    } catch (error) {
        res.status(500).json({ message: "Error retrieving resident data", error: error.message });
    }
};

module.exports = { uploadInfo, getResidents, getPatients, getResidentById };