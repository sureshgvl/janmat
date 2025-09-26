# JanMat - Election Engagement Platform

A comprehensive Flutter application designed to revolutionize voter-candidate interaction in Indian local body elections, built with Firebase backend and featuring real-time communication, gamification, and multilingual support.

## 📱 **App Overview**

JanMat empowers voters with transparent access to candidate information while enabling candidates to connect directly with constituents. The app bridges the democratic gap through technology, fostering informed voting decisions and active civic participation.

## 🔄 **Current App Flow**

### **1. First Launch Flow**
```
App Launch → Language Selection → Login → Role Selection → Profile Completion → Home Dashboard
```

### **2. Returning User Flow**
```
App Launch → Authentication Check → Profile Validation → Home Dashboard
```

### **3. Detailed User Journey**

#### **Language Selection** (`/language-selection`)
- **First-time users** are prompted to select language (English/Marathi)
- **Default**: English for new users
- **Persistent**: Language preference stored locally

#### **Authentication** (`/login`)
- **Phone OTP Verification** using Firebase Authentication
- **Secure login** with SMS-based verification
- **Automatic redirect** based on user state

#### **Role Selection** (`/role-selection`)
- **User Type Selection**: Voter or Candidate
- **Critical Decision Point**: Determines app functionality
- **Stored in Firebase**: Persists across sessions

#### **Profile Completion** (`/profile-completion`)
- **Location Setup**: State → District → Body → Ward selection
- **Dynamic Hierarchy**: Location options filtered based on previous selections
- **Validation Required**: Must complete before accessing main features

#### **Main Dashboard** (`/home`)
- **Bottom Navigation**: 4 main tabs (Home, Candidates, Chat, Polls)
- **Role-based Features**: Different capabilities for voters vs candidates

## ✨ **Core Features**

### 🏠 **Home Tab**
- **Feed System**: Community posts and election updates
- **Quick Actions**: Access to key features
- **Election Information**: Current election status and reminders
- **Gamification Elements**: XP display and achievement badges

### 👥 **Candidates Tab**
- **Ward-based Discovery**: Candidates filtered by user's ward
- **Comprehensive Profiles**:
  - Basic Info: Name, party, photo, manifesto
  - Contact Details: Phone, email, social media
  - Campaign Materials: Posters, videos, promises
- **Sponsored Candidates**: Premium visibility for paid candidates
- **Search & Filter**: Find candidates by name, party, or ward

### 💬 **Chat Tab**
- **Real-time Messaging**: Direct communication with candidates
- **Rate Limiting**: 1 free message per 5 minutes
- **XP-based Unlock**: Earn points to send additional messages
- **Message History**: Complete conversation tracking
- **Group Chats**: Ward-based community discussions

### 📊 **Polls Tab**
- **Survey System**: Election-related opinion polls
- **Real-time Results**: Live poll updates
- **Voter Engagement**: Participate in democratic discussions
- **Analytics**: Poll participation tracking

### 👤 **Profile & Settings**
- **User Profile**: Personal information and location details
- **Party Symbol**: Candidates can update party affiliation
- **Device Management**: Manage logged-in devices
- **Language Settings**: Switch between English/Marathi
- **Notification Preferences**: Customize push notifications

## 🎮 **Gamification System**

### **XP Earning Mechanisms**
- **Rewarded Video Ads**: Watch AdMob videos to earn XP
- **Message Unlock**: Spend XP for additional candidate messages
- **Achievement System**: Milestones and badges for engagement
- **Progress Tracking**: Visual XP meter and reward history

### **Premium Features**
- **Enhanced Messaging**: Unlimited candidate communication
- **Priority Visibility**: Higher placement in candidate lists
- **Advanced Analytics**: Detailed engagement metrics
- **Custom Branding**: Personalized app experience

## 💰 **Monetization Features**

### **AdMob Integration**
- **Rewarded Videos**: XP earning through video ads
- **Banner Ads**: Non-intrusive monetization
- **Interstitial Ads**: Optional engagement rewards

### **Subscription Model**
- **Premium Tiers**: Different access levels
- **Razorpay Integration**: Secure payment processing
- **Feature Unlocks**: Enhanced capabilities for subscribers

## 🌐 **Multilingual Support**

### **Supported Languages**
- **English** (en): Primary language
- **Marathi** (mr): Regional language support

### **Localization Coverage**
- **App UI**: All screens and components
- **Election Content**: Candidate information and election data
- **Notifications**: Push messages in user language
- **Error Messages**: Localized error handling

## 🏗️ **Technical Architecture**

### **State Management**
- **GetX Pattern**: Reactive state management
- **Clean Architecture**: Feature-based module organization
- **Dependency Injection**: Modular service management

### **Backend Services**
- **Firebase Authentication**: Phone OTP verification
- **Cloud Firestore**: Real-time NoSQL database
- **Firebase Cloud Messaging**: Push notifications
- **Firebase Storage**: Media file hosting
- **Firebase Functions**: Server-side business logic

### **Data Models**
- **State Model**: State information with multilingual names
- **District Model**: District data with state relationships
- **Body Model**: Local body information (Corporation/Council/Panchayat)
- **Ward Model**: Ward details with population and area data
- **Candidate Model**: Comprehensive candidate profiles
- **User Model**: User accounts with role and location data

### **Location Hierarchy**
```
State (Maharashtra) → District → Body → Ward
```
- **Dynamic Selection**: Options filtered based on hierarchy
- **Validation**: Ensures data consistency
- **Offline Support**: Cached location data

## 🔐 **Authentication Flow**

### **Phone Number Verification**
1. **Number Input**: User enters phone number
2. **OTP Request**: Firebase sends SMS code
3. **Code Verification**: User enters received OTP
4. **Profile Creation**: Automatic user document creation

### **Session Management**
- **Persistent Login**: Automatic authentication on app restart
- **Device Tracking**: Multiple device management
- **Security**: Firebase security rules enforcement

## 📱 **UI/UX Design**

### **Design System**
- **Colors**: Saffron (#FF9933) and Green (#138808) theme
- **Typography**: Consistent text styles across app
- **Components**: Reusable widgets and modals
- **Responsive**: Optimized for various screen sizes

### **Key Screens**
- **Splash Screen**: Animated loading with branding
- **Onboarding**: Language and role selection
- **Location Selection**: Hierarchical picker modals
- **Dashboard**: Tab-based navigation
- **Profile Views**: Detailed candidate and user profiles
- **Chat Interface**: Real-time messaging UI

## 🔧 **Development Setup**

### **Prerequisites**
- Flutter SDK 3.8.1+
- Firebase CLI
- Android Studio / VS Code
- Java 11+ and Android SDK

### **Quick Start**
```bash
# Clone repository
git clone <repository-url>
cd janmat

# Install dependencies
flutter pub get

# Configure Firebase
# 1. Create Firebase project
# 2. Enable Authentication, Firestore, Storage, Messaging
# 3. Add google-services.json to android/app/

# Generate localization
flutter gen-l10n

# Run app
flutter run
```

## 📊 **Database Schema**

### **Users Collection**
```json
{
  "id": "user_id",
  "phoneNumber": "+919876543210",
  "role": "voter|candidate",
  "districtId": "mumbai_city",
  "bodyId": "mumbai_corporation",
  "wardId": "ward_1",
  "xpPoints": 150,
  "profileCompleted": true,
  "language": "en|mr"
}
```

### **Candidates Collection**
```json
{
  "id": "candidate_id",
  "name": "Rajesh Kumar",
  "party": "BJP",
  "districtId": "mumbai_city",
  "bodyId": "mumbai_corporation",
  "wardId": "ward_1",
  "manifesto": "Infrastructure development...",
  "isSponsored": true,
  "contactInfo": {
    "phone": "+91-9876543210",
    "email": "rajesh@bjp.org"
  }
}
```

### **Election Types Collection**
```json
{
  "key": "municipal_corporation",
  "nameEn": "Municipal Corporation",
  "nameMr": "महानगरपालिका"
}
```

## 🚀 **Deployment & Distribution**

### **Build Process**
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

### **App Stores**
- **Google Play**: Internal testing → Beta → Production
- **App Store**: TestFlight → App Review → Release

## 🔒 **Security & Privacy**

### **Data Protection**
- **Firebase Security Rules**: Granular access control
- **Phone Authentication**: OTP-based verification
- **Data Encryption**: Sensitive information protection
- **Rate Limiting**: API abuse prevention

### **Privacy Features**
- **GDPR Compliance**: User data control
- **Consent Management**: Permission-based features
- **Data Minimization**: Only necessary data collection

## 📈 **Performance Optimizations**

### **App Performance**
- **Lazy Loading**: On-demand feature loading
- **Image Caching**: Efficient media handling
- **Background Sync**: Offline data synchronization
- **Memory Management**: Optimized state handling

### **Database Performance**
- **Firestore Indexing**: Optimized queries
- **Caching Layers**: Multi-level data caching
- **Compression**: Data size optimization

## 🧪 **Testing Strategy**

### **Test Coverage**
- **Unit Tests**: Individual function testing
- **Widget Tests**: UI component validation
- **Integration Tests**: End-to-end flow testing
- **Performance Tests**: App responsiveness validation

## 📞 **Support & Maintenance**

### **Error Handling**
- **Graceful Degradation**: App functions despite errors
- **User Feedback**: Error reporting system
- **Recovery Mechanisms**: Automatic error recovery

### **Monitoring**
- **Crash Reporting**: Firebase Crashlytics
- **Analytics**: User behavior tracking
- **Performance Metrics**: App performance monitoring

## 🎯 **Future Roadmap**

### **Planned Features**
- **Election Notifications**: Real-time election updates
- **Voting Guides**: Educational content for voters
- **Candidate Comparison**: Side-by-side candidate analysis
- **Offline Mode**: Full functionality without internet
- **Multi-state Support**: Expand beyond Maharashtra

### **Technical Improvements**
- **PWA Support**: Web app functionality
- **Advanced Analytics**: Detailed user insights
- **AI Features**: Smart candidate recommendations
- **Blockchain Integration**: Voting transparency

---

**Built with ❤️ to strengthen Indian democracy through technology**

**Developer**: Suresh G V L
**Contact**: sureshgvl@gmail.com
**Version**: 1.0.1+2
