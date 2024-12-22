const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const authRoutes = require('./routes/authRoutes'); // Authentication routes
const activityRoutes = require('./routes/activities');
const patientRouter = require("./routes/patient"); 
const healthProgressRouter = require('./routes/healthProgress');
const mealRouter = require("./routes/meal");
const contactRoutes = require('./routes/contactRoutes');
const messageRoutes = require('./routes/messageRoutes');
const userRoutes = require('./routes/userRoutes');
const notifRoutes = require('./routes/notifRoutes');
const emergencyAlertRoutes = require('./routes/emergencyAlertRoutes');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json()); // For parsing application/json
app.use(express.urlencoded({ extended: true })); // For parsing application/x-www-form-urlencoded

// MongoDB connection
mongoose.connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => console.log('MongoDB connected'))
    .catch(err => console.error('MongoDB connection error:', err));

// API Routes
app.use('/api/auth', authRoutes); // Authentication routes
app.use('/api/activities', activityRoutes);
app.use("/api/patient", patientRouter);
app.use('/api/health-progress', healthProgressRouter);
app.use("/api/v1/meal", mealRouter);
app.use('/api/contacts', contactRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/users', userRoutes);
app.use('/api/notifications', notifRoutes);
app.use('/api/emergency-alerts', emergencyAlertRoutes);

// Start the server
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});