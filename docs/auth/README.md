# 🔐 Authentication Flow Documentation

## Overview

This document provides a comprehensive guide to the authentication flow in the JanMat app, covering everything from initial login to reaching the home screen. It includes detailed logging information to help debug authentication issues after app reinstallation.

## 📋 Authentication Flow Summary

```
Login Screen → OTP Verification → Role Selection → Profile Completion → Home Screen
     ↓              ↓              ↓              ↓              ↓
   Phone/Email   Firebase Auth   Voter/Candidate   Basic Info     Main App
   Input         + Firestore     Selection         Setup          Interface
```

## 🎯 Quick Setup for Testing

### 1. Enable Auth Logging
```dart
// In lib/main.dart
AppLogger.configure(
  auth: true,        // ✅ Show authentication logs
  network: true,     // ✅ Show Firebase operations
  cache: true,       // ✅ Show user data caching
  database: true,    // ✅ Show Firestore operations
  performance: true, // ✅ Show timing metrics
  chat: false,       // ❌ Disable chat logs for focus
  ui: false,         // ❌ Disable UI logs
);
```

### 2. Test Commands
```bash
flutter run --debug
```

### 3. Expected Log Flow
```
🔐 [AUTH_CONTROLLER] Starting Google Sign-In process
🌐 [GOOGLE_SIGNIN] Checking network connectivity
🔐 [AUTH_CONTROLLER] Google account selected
🔐 [AUTH_CONTROLLER] Firebase authentication successful
👤 [AUTH_CONTROLLER] Creating/updating user profile
📱 [AUTH_CONTROLLER] Device registered
🏠 [AUTH_CONTROLLER] Checking profile completion
🎭 [AUTH_CONTROLLER] Role not selected, navigating to role selection
📝 [AUTH_CONTROLLER] Profile not completed, navigating to profile completion
🏠 [AUTH_CONTROLLER] Profile complete, navigating to home
```

## 📱 Screen-by-Screen Flow

### 1. Login Screen (`/login`)

#### UI Components
- Phone number input (+91 prefix)
- OTP send button
- Google Sign-In button (smart account switching)
- Language selection (if not set)

#### User Actions
1. **Phone Login**: Enter 10-digit phone number → Send OTP
2. **Google Login**: Choose account → Automatic authentication
3. **Language**: Select preferred language (Marathi/English)

#### Code Flow
```dart
// Phone authentication
controller.sendOTP() → verifyPhoneNumber() → onCodeSent() → OTP Screen

// Google authentication
controller.signInWithGoogle() → Google Sign-In → Firebase Auth → Profile Check
```

#### Expected Logs
```
📞 [AUTH_CONTROLLER] Starting phone verification for: +919876543210
📞 [AUTH_CONTROLLER] Phone verification request completed
📱 [AUTH_CONTROLLER] OTP sent successfully, verification ID: ABC123...
🔐 [AUTH_CONTROLLER] Starting Google Sign-In process
✅ [AUTH_CONTROLLER] Google account selected: user@gmail.com
```

### 2. OTP Verification Screen

#### UI Components
- OTP input field (6 digits)
- Verify OTP button
- Resend OTP (60-second timer)
- Change phone number button

#### User Actions
1. Enter 6-digit OTP
2. Auto-submit on completion
3. Resend if timer expires
4. Change phone number if needed

#### Code Flow
```dart
controller.verifyOTP() → signInWithOTP() → Check Existing User → Navigate
```

#### Expected Logs
```
🔐 [OTP_VERIFY] Starting OTP verification...
📱 [OTP_VERIFY] Authenticating with Firebase Auth...
✅ [OTP_VERIFY] Firebase Auth successful for user: ABC123...
🔍 [OTP_VERIFY] Checking for existing user profile by phone number...
✅ [OTP_VERIFY] Found existing user profile: DEF456...
🔗 [OTP_VERIFY] Successfully linked to existing user: DEF456
```

### 3. Role Selection Screen (`/role-selection`)

#### UI Components
- Voter card (blue theme)
- Candidate card (green theme)
- Continue button
- Role description text

#### User Actions
1. Select role (Voter/Candidate)
2. Tap Continue
3. Automatic navigation to profile completion

#### Code Flow
```dart
_saveRole() → Update Firestore → Navigate to Profile Completion
```

#### Expected Logs
```
🎭 [ROLE_SELECTION] Saving role: candidate
✅ [ROLE_SELECTION] Role saved successfully
🏠 [ROLE_SELECTION] Navigating to profile completion
```

### 4. Profile Completion Screen (`/profile-completion`)

#### UI Components
- Basic info form (name, photo, party, location)
- Progress indicator
- Save/Update button
- Skip options (if applicable)

#### User Actions
1. Fill basic information
2. Upload profile photo
3. Select party affiliation
4. Choose location (district/body/ward)
5. Save profile

#### Code Flow
```dart
saveProfile() → Update Firestore → Navigate to Home
```

#### Expected Logs
```
👤 [PROFILE_COMPLETION] Starting profile save...
📝 [PROFILE_COMPLETION] Updating basic info: name, photo, party...
✅ [PROFILE_COMPLETION] Profile saved successfully
🏠 [PROFILE_COMPLETION] Navigating to home screen
```

### 5. Home Screen (`/home`)

#### UI Components
- Tab navigation (Home, Chat, Profile, etc.)
- Welcome message
- Quick actions
- Feed content

#### Code Flow
```dart
Initialize Controllers → Load User Data → Show Home Interface
```

#### Expected Logs
```
🏠 [HOME_SCREEN] Initializing home screen...
🔧 [HOME_SCREEN] Initializing ChatController...
🔧 [HOME_SCREEN] Initializing CandidateController...
✅ [HOME_SCREEN] Controllers initialized successfully
📱 [HOME_SCREEN] Home screen ready
```

## 🔍 Detailed Authentication Methods

### Phone Authentication

#### Process Flow
1. **Input Validation**: Check 10-digit phone number
2. **reCAPTCHA**: Firebase handles bot protection
3. **SMS Sending**: Firebase sends OTP to +91XXXXXXXXXX
4. **OTP Input**: User enters 6-digit code
5. **Verification**: Firebase verifies OTP
6. **User Creation**: Create/update Firestore user document
7. **Device Registration**: Register device for push notifications
8. **Navigation**: Route based on profile completion status

#### Error Handling
- Invalid phone number
- Network issues
- Too many requests
- Invalid OTP
- Timeout issues

#### Logs to Watch
```
📞 Phone verification for: +919876543210
📱 OTP sent successfully, verification ID: ABC123...
🔐 OTP verification successful
👤 User profile created/updated
📱 Device registered
🏠 Navigation decision made
```

### Google Authentication

#### Process Flow
1. **Account Selection**: Smart account picker or forced picker
2. **Google OAuth**: Authenticate with Google
3. **Firebase Auth**: Exchange Google token for Firebase token
4. **User Lookup**: Check if user exists by email
5. **Profile Creation**: Create/update Firestore document
6. **Device Registration**: Register for push notifications
7. **Navigation**: Route based on profile completion

#### Smart Account Switching
- **First Time**: Show account picker
- **Returning User**: Show "Continue as [Name]" button
- **Different Account**: Show "Sign in with different account" option

#### Logs to Watch
```
🚀 Starting Google Sign-In process
📱 Google account selected: user@gmail.com
🔐 Firebase authentication successful
🔍 Checking for existing user profile by email
👤 User profile created/updated
📱 Device registered
🏠 Navigation decision made
```

## 🗄️ Data Storage & Caching

### Firestore Collections
- `users`: User profiles and authentication data
- `user_mappings`: Firebase Auth UID to primary user ID mapping
- `user_quotas`: Message/daily limits
- `devices`: Device registration for notifications

### Local Caching
- `SharedPreferences`: Last Google account, temp user data
- `UserCacheService`: Complete user profile caching
- `BackgroundSyncManager`: Offline data synchronization

### Cache Invalidation
- **Profile Updates**: Clear user cache after basic info changes
- **Logout**: Clear all session data
- **App Restart**: Validate cache validity (24-hour expiry)

## 🔄 Navigation Logic

### Decision Tree
```
User Authenticates
├── Has Existing Profile?
│   ├── Yes → Link to existing profile
│   └── No → Create new profile
├── Role Selected?
│   ├── Yes → Check profile completion
│   └── No → Navigate to role selection
├── Profile Complete?
│   ├── Yes → Navigate to home
│   └── No → Navigate to profile completion
```

### Route Mapping
- `/login` → LoginScreen
- `/role-selection` → RoleSelectionScreen
- `/profile-completion` → ProfileCompletionScreen
- `/home` → HomeScreen (main app)

## 🚨 Common Issues & Debugging

### Issue 1: "User not found after authentication"
**Symptoms**: User authenticates but gets stuck
**Logs to check**:
```
🔍 Checking for existing user profile
❌ No existing user found
```
**Solution**: Check Firestore `users` collection

### Issue 2: "Profile not saving"
**Symptoms**: Profile completion doesn't progress
**Logs to check**:
```
👤 Starting profile save...
❌ Error saving profile
```
**Solution**: Check Firestore permissions and network

### Issue 3: "Stuck on loading screen"
**Symptoms**: App shows loading indefinitely
**Logs to check**:
```
🏠 Checking profile completion
❌ Error during profile check
```
**Solution**: Check Firestore connectivity

### Issue 4: "Wrong navigation after login"
**Symptoms**: User goes to wrong screen
**Logs to check**:
```
🏠 Navigation decision: roleSelected=false
🎭 Navigating to role selection
```
**Solution**: Check user document fields

## 📊 Performance Metrics

### Expected Timings
- **Phone OTP Send**: 2-5 seconds
- **OTP Verification**: 1-3 seconds
- **Google Sign-In**: 3-8 seconds
- **Profile Creation**: 0.5-2 seconds
- **Device Registration**: 0.2-1 second
- **Navigation**: 0.1-0.5 seconds

### Performance Logs
```
⚡ [PERFORMANCE] Phone verification: 3200ms
⚡ [PERFORMANCE] OTP verification: 1500ms
⚡ [PERFORMANCE] Profile save: 800ms
⚡ [PERFORMANCE] Navigation: 200ms
```

## 🧪 Testing Checklist

### Phone Authentication
- [ ] Enter valid 10-digit number
- [ ] Receive OTP SMS
- [ ] Enter correct OTP
- [ ] Enter incorrect OTP
- [ ] Resend OTP after timer
- [ ] Change phone number
- [ ] Network interruption during OTP send
- [ ] Network interruption during verification

### Google Authentication
- [ ] First-time Google login
- [ ] Returning user (smart account switching)
- [ ] Different account selection
- [ ] Cancel during account picker
- [ ] Network interruption
- [ ] Invalid Google account

### Profile Flow
- [ ] Role selection (voter/candidate)
- [ ] Profile completion
- [ ] Photo upload
- [ ] Location selection
- [ ] Party selection
- [ ] Save and continue

### Navigation
- [ ] New user flow
- [ ] Existing user flow
- [ ] Incomplete profile recovery
- [ ] App restart after login

## 📝 Code References

### Key Controllers
- `AuthController`: Main authentication logic
- `ChatController`: User data caching
- `CandidateController`: Profile management

### Key Services
- `AuthRepository`: Firebase authentication
- `UserCacheService`: Local user data caching
- `DeviceService`: Device registration

### Key Screens
- `LoginScreen`: Phone/Google authentication
- `RoleSelectionScreen`: Voter/Candidate choice
- `ProfileCompletionScreen`: Basic info setup

## 🎯 Quick Debug Commands

### Enable Auth-Only Logging
```dart
AppLogger.enableAuthOnly();
```

### Check User State
```dart
final user = FirebaseAuth.instance.currentUser;
final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
print('User authenticated: ${user != null}');
print('Profile exists: ${userDoc.exists}');
print('Profile data: ${userDoc.data()}');
```

### Clear All Auth Data (Testing)
```dart
await FirebaseAuth.instance.signOut();
await SharedPreferences.getInstance().then((prefs) => prefs.clear());
Get.offAllNamed('/login');
```

This comprehensive authentication documentation will help you effectively test and debug the login-to-home-screen flow in your JanMat app.