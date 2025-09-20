# JanMat - Election App

A comprehensive Flutter application for election candidate information and voter engagement, built with Firebase backend.

## 📱 **App Overview**

JanMat is a revolutionary election app designed to bridge the gap between voters and candidates. It provides transparent access to candidate information, real-time communication, and gamified engagement features to encourage voter participation in democratic processes.

## ✨ **Key Features**

### 🔐 **Authentication & User Management**
- **Phone OTP Verification**: Secure Firebase Authentication
- **User Profiles**: City and ward-based user registration
- **Multi-language Support**: English and Marathi localization

### 🏛️ **Ward & Candidate System**
- **Dynamic Ward Selection**: City-wise ward navigation
- **Comprehensive Candidate Profiles**:
  - Basic Info: Name, party affiliation, photo, manifesto
  - Premium Content: Contact details, social media links, campaign materials
  - Sponsored candidates with premium visibility

### 💬 **Real-time Communication**
- **Direct Candidate Chat**: One-on-one messaging with elected representatives
- **Rate Limiting System**: 1 free message per 5 minutes
- **XP-based Unlock**: Earn points to send additional messages
- **Message History**: Complete conversation tracking

### 🎮 **Gamification & Rewards**
- **XP Earning System**: Watch AdMob rewarded videos to gain XP
- **Premium Features Unlock**: Spend XP on enhanced messaging
- **Progress Tracking**: Visual XP and reward history
- **Achievement System**: Milestones and badges

### 📢 **Notifications & Updates**
- **Firebase Cloud Messaging**: Real-time push notifications
- **Candidate Updates**: Instant alerts for new information
- **Election Reminders**: Important date notifications

### 💰 **Monetization Features**
- **AdMob Integration**: Rewarded video ads for XP earning
- **Premium Subscriptions**: Enhanced features for power users
- **In-app Purchases**: Razorpay payment gateway integration

## 🏗️ **Technical Architecture**

### **Project Structure**
```
lib/
├── core/                    # Core application logic
│   ├── bindings/           # Dependency injection
│   └── utils/              # Utility functions
├── features/               # Feature-based modules
│   ├── auth/              # Authentication
│   ├── candidate/         # Candidate management
│   ├── chat/              # Messaging system
│   ├── home/              # Main dashboard
│   ├── monetization/      # Payment & rewards
│   ├── polls/             # Survey system
│   ├── profile/           # User profiles
│   └── settings/          # App settings
├── models/                # Data models
├── services/              # Business logic services
├── utils/                 # Helper utilities
└── widgets/               # Reusable UI components
```

### **State Management**
- **GetX Pattern**: Reactive state management
- **Clean Architecture**: Separation of concerns
- **Dependency Injection**: Modular service injection

### **Backend Services**
- **Firebase Authentication**: Phone number OTP
- **Cloud Firestore**: Real-time database
- **Firebase Cloud Messaging**: Push notifications
- **Firebase Storage**: Media file storage
- **Firebase Functions**: Server-side logic

## 🚀 **Setup & Installation**

### **Prerequisites**
- Flutter SDK (3.8.1+)
- Android Studio / VS Code
- Firebase CLI
- Java 11+
- Android SDK (API 23+)

### **1. Environment Setup**
```bash
# Clone the repository
git clone https://github.com/sureshgvl/janmat.git
cd janmat

# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n
```

### **2. Firebase Configuration**
1. Create Firebase project at https://console.firebase.google.com/
2. Enable required services:
   - Authentication (Phone provider)
   - Firestore Database
   - Cloud Messaging
   - Storage
   - Functions
3. Add Android app with package name: `com.sg.janmat`
4. Download `google-services.json` and place in `android/app/`

### **3. AdMob Setup**
1. Create AdMob account at https://admob.google.com/
2. Create Rewarded Video Ad Unit
3. Update Ad Unit IDs in `lib/services/admob_service.dart`

### **4. Razorpay Integration**
1. Create Razorpay account
2. Get API keys for test/production
3. Update keys in `lib/services/razorpay_service.dart`

### **5. Firestore Setup**
```bash
# Import data structure
firebase firestore:import firestore_data_structure.json

# Deploy security rules
firebase deploy --only firestore:rules

# Create indexes
firebase deploy --only firestore:indexes
```

### **6. Build & Run**
```bash
# Debug mode
flutter run

# Release build
flutter build apk --release
flutter build appbundle --release

# iOS build
flutter build ios --release
```

## 📊 **Database Schema**

### **Users Collection**
```json
{
  "id": "user_id",
  "phoneNumber": "+919876543210",
  "name": "John Doe",
  "city": "Mumbai",
  "wardId": "mumbai_ward_1",
  "xpPoints": 150,
  "subscriptionType": "free",
  "lastMessageTime": "2025-01-15T10:30:00Z",
  "createdAt": "2025-01-01T00:00:00Z"
}
```

### **Candidates Collection**
```json
{
  "id": "candidate_id",
  "name": "Rajesh Kumar",
  "party": "BJP",
  "partySymbol": "bjp.png",
  "wardId": "mumbai_ward_1",
  "manifesto": "Building better infrastructure...",
  "promises": ["Road development", "Clean water supply"],
  "isSponsored": true,
  "contactInfo": {
    "phone": "+91-9876543210",
    "email": "rajesh@bjp.org"
  },
  "socialLinks": {
    "Facebook": "https://facebook.com/rajeshkumar",
    "Twitter": "https://twitter.com/rajeshkumar"
  },
  "mediaUrls": {
    "photo": "https://storage.googleapis.com/...",
    "poster": "https://storage.googleapis.com/..."
  }
}
```

### **Wards Collection**
```json
{
  "id": "mumbai_ward_1",
  "name": "Andheri Ward",
  "city": "Mumbai",
  "wardNumber": 1,
  "description": "Residential and commercial area",
  "population": 50000,
  "coordinates": {
    "lat": 19.1136,
    "lng": 72.8697
  }
}
```

## 🔧 **Configuration Files**

### **Build Configuration**
- **Android**: `android/app/build.gradle.kts`
- **iOS**: `ios/Runner/Info.plist`
- **Web**: `web/index.html`

### **Environment Variables**
```dart
// lib/core/config.dart
class Config {
  static const String razorpayKeyId = 'rzp_test_...';
  static const String admobAppId = 'ca-app-pub-...';
  static const String firebaseProjectId = 'janmat-...';
}
```

## 🧪 **Testing**

### **Unit Tests**
```bash
flutter test
```

### **Integration Tests**
```bash
flutter drive --target=test_driver/app.dart
```

### **Build Tests**
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📱 **Deployment**

### **Google Play Console**
1. Create app in Play Console
2. Upload AAB file from `build/app/outputs/bundle/release/`
3. Configure store listing
4. Set up internal testing track
5. Add tester emails
6. Publish to internal test

### **App Store Connect**
1. Create app in App Store Connect
2. Archive build in Xcode
3. Upload using Transporter
4. Configure TestFlight
5. Add internal testers

## 🔒 **Security Features**

- **Firebase Security Rules**: Comprehensive database access control
- **Phone Authentication**: OTP-based secure login
- **Data Encryption**: Sensitive data protection
- **Rate Limiting**: API abuse prevention
- **Input Validation**: Client and server-side validation

## 📈 **Performance Optimization**

- **Tree Shaking**: Automatic unused code removal
- **Lazy Loading**: On-demand feature loading
- **Image Optimization**: Cached network images
- **Database Indexing**: Optimized Firestore queries
- **Memory Management**: Efficient state management

## 🐛 **Troubleshooting**

### **Common Issues**

**Build Failures:**
```bash
# Clean build cache
flutter clean
flutter pub cache repair

# Regenerate platform-specific files
flutter create --platforms=android,ios .
```

**Firebase Issues:**
```bash
# Check Firebase configuration
firebase projects:list
firebase use <project-id>
```

**AdMob Issues:**
- Verify Ad Unit IDs
- Check network permissions
- Test with test Ad Unit IDs

## 🤝 **Contributing**

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Submit Pull Request

### **Code Standards**
- Follow Flutter best practices
- Use GetX for state management
- Implement proper error handling
- Add comprehensive documentation
- Write unit tests for new features

## 📄 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 **Team**

- **Developer**: Suresh G V L
- **Project**: JanMat Election App
- **Contact**: sureshgvl@gmail.com

## 🙏 **Acknowledgments**

- Flutter Team for the amazing framework
- Firebase for robust backend services
- AdMob for monetization platform
- Razorpay for payment gateway
- Open source community for valuable packages

---

**Built with ❤️ for transparent and engaged elections in India**
