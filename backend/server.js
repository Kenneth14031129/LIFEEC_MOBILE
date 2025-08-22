// server.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const userRoutes = require('./routes/userRoutes');
const residentRoutes = require('./routes/residentRoutes');
const healthPlanRoutes = require('./routes/healthPlanRoutes');
const mealRecordRoutes = require('./routes/mealRecordRoutes');
const activityRecordRoutes = require('./routes/activityRecordRoutes');
const emergencyAlertRoutes = require('./routes/emergencyAlertRoutes');
const messageRoutes = require('./routes/messagesRoutes');

const app = express();

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE','PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));
app.use(express.json());

// MongoDB Connection with Enhanced Logging
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('Successfully connected to MongoDB Atlas');
    // Log available collections
    mongoose.connection.db.listCollections().toArray(function(err, collections) {
      if (err) {
        console.log('Error getting collections:', err);
      } else {
        console.log('Available collections:', collections.map(c => c.name));
      }
    });
  })
  .catch(err => console.error('MongoDB connection error:', err));

// Routes
app.use('/api/users', userRoutes);
app.use('/api/residents', residentRoutes);
app.use('/api/healthplans', healthPlanRoutes);
app.use('/api/meals', mealRecordRoutes);
app.use('/api/activities', activityRecordRoutes);
app.use('/api/emergency-alerts', emergencyAlertRoutes);
app.use('/api/messages', messageRoutes);

// Test Routes
app.get('/test', (req, res) => {
  res.json({ message: 'Backend is working!' });
});

app.get('/api/test/healthplans', async (req, res) => {
  try {
    const healthPlans = await require('./models/HealthPlan').find();
    res.json({ count: healthPlans.length, plans: healthPlans });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Log registered routes
app._router.stack.forEach(function(r){
  if (r.route && r.route.path){
    console.log('Registered route:', r.route.path, r.route.methods);
  }
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Test the server at: http://localhost:${PORT}/test`);
});