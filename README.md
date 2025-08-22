# LifeEC Mobile - Professional Elderly Care System

A comprehensive mobile application built with Flutter for managing elderly care services, providing healthcare monitoring, activity tracking, and emergency alert systems.

## 🏥 Features

### For Caregivers
- **Resident Management**: Track and manage multiple residents
- **Health Monitoring**: Monitor vital signs, medications, and health plans
- **Activity Tracking**: Log daily activities and exercise routines
- **Meal Management**: Track nutrition and dietary requirements
- **Emergency Alerts**: Instant notifications for urgent situations
- **Communication**: Message system between caregivers and family members

### For Family Members
- **Real-time Updates**: Stay informed about loved ones' wellbeing
- **Health History**: Access detailed health records and trends
- **Activity Reports**: View daily activity summaries
- **Direct Communication**: Chat with caregivers and facility staff

## 🛠 Tech Stack

### Mobile App (Flutter)
- **Framework**: Flutter 3.5.3+
- **Language**: Dart
- **State Management**: Provider
- **HTTP Client**: http package
- **Secure Storage**: flutter_secure_storage
- **Charts**: fl_chart
- **UI**: Material Design with Google Fonts

### Backend (Node.js)
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT with bcryptjs
- **Email Service**: Nodemailer
- **Security**: CORS enabled

## 📱 Screenshots

*Screenshots coming soon*

## 🚀 Installation

### Prerequisites
- Flutter SDK (>=3.5.3)
- Node.js (>=16.0.0)
- MongoDB
- Android Studio / Xcode for device testing

### Mobile App Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd LIFEEC_MOBILE
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Create environment file**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Start the server**
   ```bash
   npm start
   ```

## 🔧 Configuration

### Environment Variables (Backend)
Create a `.env` file in the backend directory:

```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/lifeec
JWT_SECRET=your_jwt_secret_here
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password
```

### Flutter Configuration
Update API endpoints in the Flutter app to match your backend URL.

## 📁 Project Structure

```
├── lib/                    # Flutter source code
│   ├── main.dart          # App entry point
│   ├── dashboard.dart     # Main dashboard
│   ├── login_page.dart    # Authentication
│   └── ...               # Other screens and components
├── backend/               # Node.js backend
│   ├── controllers/       # Route controllers
│   ├── models/           # Database models
│   ├── routes/           # API routes
│   ├── utils/            # Utility functions
│   └── server.js         # Server entry point
├── assets/               # App assets
└── android/ios/web/      # Platform-specific files
```

## 🔐 API Endpoints

### Authentication
- `POST /api/users/login` - User login
- `POST /api/users/register` - User registration
- `POST /api/users/verify-otp` - OTP verification

### Residents
- `GET /api/residents` - Get all residents
- `POST /api/residents` - Create new resident
- `PUT /api/residents/:id` - Update resident
- `DELETE /api/residents/:id` - Delete resident

### Health Plans
- `GET /api/health-plans` - Get health plans
- `POST /api/health-plans` - Create health plan
- `PUT /api/health-plans/:id` - Update health plan

### Emergency Alerts
- `GET /api/emergency-alerts` - Get alerts
- `POST /api/emergency-alerts` - Create alert

## 🧪 Testing

### Flutter Tests
```bash
flutter test
```

### Backend Tests
```bash
cd backend
npm test
```

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

**Built with ❤️ for better elderly care**
