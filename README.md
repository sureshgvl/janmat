# JanMat - Election App

A comprehensive Flutter application for election candidate information and voter engagement, built with Firebase backend.

## Features

### ✅ **Implemented Features:**
- **User Authentication**: Phone number OTP login with Firebase Auth
- **Ward System**: City and ward selection with Firestore integration
- **Candidate Information**:
  - Free info: Name, party, photo, manifesto, promises
  - Paid info: Contact details, posters, videos, social links (sponsored candidates)
  - Sponsored candidates appear at top with premium badges
- **Chat System**:
  - Real-time messaging with candidates
  - Rate limiting: 1 free message every 5 minutes
  - XP system to unlock extra messages
- **XP/Reward System**:
  - Earn XP by watching AdMob rewarded videos
  - Spend XP to unlock extra chat messages
  - Transaction history tracking
- **Notifications**: Firebase Cloud Messaging setup
- **State Management**: Provider pattern for clean architecture

## Project Structure

```
lib/
├── models/          # Data models (User, Candidate, Ward, Chat, Reward)
├── providers/       # State management (Auth, Ward, Chat, Reward)
├── screens/         # UI screens (Login, Home, City/Ward selection, etc.)
├── services/        # Business logic (Firebase, Auth, Database, AdMob)
└── main.dart        # App entry point
```

## Setup Instructions

### 1. Firebase Configuration
1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Authentication with Phone provider
3. Enable Firestore Database
4. Enable Cloud Messaging
5. Add your Android app with package name `com.sg.janmat`
6. Download `google-services.json` and place it in `android/app/`

### 2. AdMob Setup
1. Create AdMob account at https://admob.google.com/
2. Create a Rewarded Video Ad Unit
3. Update the Ad Unit ID in `lib/services/ad_service.dart`

### 3. Firestore Data Structure
1. Import the data structure from `firestore_data_structure.json`
2. Upload `firestore.rules` to your Firebase project
3. Create the required indexes as specified in the JSON file

### 4. Dependencies
```bash
flutter pub get
```

### 5. Android Configuration
The app is configured for Android with:
- minSdkVersion: 23
- NDK Version: 27.0.12077973

### 6. Run the App
```bash
flutter run
```

## Firestore Collections

### Users Collection
```json
{
  "phoneNumber": "+919876543210",
  "name": "John Doe",
  "city": "Mumbai",
  "ward": "Ward 1 - Andheri",
  "xpPoints": 150,
  "lastMessageTime": "2025-01-15T10:30:00Z"
}
```

### Candidates Collection
```json
{
  "name": "Rajesh Kumar",
  "party": "BJP",
  "wardId": "mumbai_ward_1",
  "manifesto": "Building better infrastructure...",
  "isSponsored": true,
  "contactInfo": "Phone: +91-9876543210",
  "socialLinks": {
    "Facebook": "https://facebook.com/rajeshkumar"
  }
}
```

### Wards Collection
```json
{
  "name": "Andheri Ward",
  "city": "Mumbai",
  "wardNumber": 1,
  "description": "Residential and commercial area"
}
```

## Key Features Implementation

### Rate Limiting
- Users can send 1 message every 5 minutes
- Additional messages require 5 XP points each
- XP earned through AdMob rewarded videos

### Sponsored Content
- Sponsored candidates appear first in lists
- Premium badges indicate sponsored status
- Additional contact and media content for sponsored candidates

### Real-time Chat
- Firebase Firestore for message storage
- Real-time updates using Provider
- Message read status tracking

## Security Rules

The app includes comprehensive Firestore security rules ensuring:
- Users can only access their own data
- Public read access for wards and candidates
- Conversation access limited to participants
- XP transaction privacy

## Technologies Used

- **Flutter**: UI framework
- **Firebase**: Backend services
  - Authentication (Phone OTP)
  - Firestore (Database)
  - Cloud Messaging (Notifications)
- **AdMob**: Monetization
- **Provider**: State management
- **Cached Network Image**: Image loading

## Development Notes

- Clean architecture with separation of concerns
- Provider pattern for state management
- Comprehensive error handling
- Modular service layer
- Type-safe data models with JSON serialization

## Next Steps

1. **Testing**: Test all features with sample data
2. **UI Polish**: Enhance UI/UX design
3. **Additional Features**:
   - Push notifications for candidate updates
   - Message encryption
   - Offline message queuing
   - Analytics integration

## Contributing

1. Follow the established project structure
2. Use Provider for state management
3. Implement proper error handling
4. Add comprehensive comments
5. Test on multiple devices

---

**Built with ❤️ for transparent and engaged elections**
