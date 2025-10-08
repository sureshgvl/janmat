# 🔐 Authentication Logging Guide

## Overview

This guide shows how to use the `AppLogger` utility to filter and control authentication logs, making it easier to debug login-to-home-screen flow issues after app reinstallation.

## 🚀 Quick Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Logger in main.dart
```dart
import 'utils/app_logger.dart';

void main() async {
  // ... existing code ...

  // Configure which logs to show
  AppLogger.configure(
    auth: true,        // ✅ Show authentication logs
    network: true,     // ✅ Show Firebase operations
    cache: true,       // ✅ Show user data caching
    database: true,    // ✅ Show Firestore operations
    performance: true, // ✅ Show timing metrics
    chat: false,       // ❌ Hide chat logs for focus
    ui: false,         // ❌ Hide UI logs
  );

  // Quick setup options (uncomment one):
  // AppLogger.enableAllLogs();      // Show all logs
  // AppLogger.enableAuthOnly();     // Show only auth logs
  // AppLogger.enableCoreOnly();     // Show core functionality logs
  // AppLogger.disableAllLogs();     // Disable all app logs

  runApp(const MyApp());
}
```

## 📱 Usage Examples

### Replace debugPrint with AppLogger

#### Before (old way):
```dart
debugPrint('📱 [AUTH_CONTROLLER] Starting Google Sign-In process...');
debugPrint('❌ [AUTH_CONTROLLER] Google sign-in failed');
```

#### After (new way):
```dart
AppLogger.auth('Starting Google Sign-In process', tag: 'AuthController');
AppLogger.authError('Google sign-in failed', tag: 'AuthController', error: e);
```

### Authentication-Related Logging

```dart
import 'package:janmat/utils/app_logger.dart';

// Phone authentication
AppLogger.auth('Starting phone verification for: +91$phoneNumber');
AppLogger.auth('OTP sent successfully, verification ID: $vid');
AppLogger.auth('OTP verification successful');
AppLogger.authError('OTP verification failed', error: e);

// Google authentication
AppLogger.auth('Starting Google Sign-In process');
AppLogger.auth('Google account selected: $email');
AppLogger.auth('Firebase authentication successful');
AppLogger.authError('Google sign-in failed', error: e);

// Profile operations
AppLogger.auth('Checking profile completion');
AppLogger.auth('Profile complete, navigating to home');
AppLogger.auth('Role not selected, navigating to role selection');
AppLogger.auth('Profile not completed, navigating to profile completion');
```

### Network Operations

```dart
// Firebase operations
AppLogger.network('Fetching user document from Firestore');
AppLogger.network('User document fetched successfully');
AppLogger.networkError('Failed to fetch user document', error: e);

// Authentication calls
AppLogger.network('Calling Firebase verifyPhoneNumber');
AppLogger.network('Phone verification completed');
AppLogger.networkError('Phone verification failed', error: e);
```

### Cache Operations

```dart
// User data caching
AppLogger.cache('Caching user profile data');
AppLogger.cache('User profile cached successfully');
AppLogger.cache('Clearing user cache on logout');

// Google account storage
AppLogger.cache('Storing last Google account: $email');
AppLogger.cache('Retrieved last Google account from cache');
AppLogger.cache('Cleared stored Google account');
```

### Database Operations

```dart
// Firestore operations
AppLogger.database('Creating new user document');
AppLogger.database('Updating user profile in Firestore');
AppLogger.database('User document updated successfully');
AppLogger.databaseError('Failed to update user document', error: e);

// User lookup
AppLogger.database('Searching for existing user by phone: $phone');
AppLogger.database('Found existing user: $userId');
AppLogger.database('No existing user found');
```

### Performance Monitoring

```dart
// Authentication timing
AppLogger.performance('Phone verification time: ${duration}ms');
AppLogger.performance('OTP verification time: ${duration}ms');
AppLogger.performance('Google sign-in time: ${duration}ms');
AppLogger.performance('Profile save time: ${duration}ms');

// Navigation timing
AppLogger.performance('Role selection navigation: ${duration}ms');
AppLogger.performance('Profile completion navigation: ${duration}ms');
AppLogger.performance('Home screen navigation: ${duration}ms');
```

## 🎯 Testing Authentication Flow

### Recommended Configuration for Testing
```dart
// In main.dart - for comprehensive auth testing
AppLogger.configure(
  auth: true,        // Show all authentication operations
  network: true,     // Show Firebase calls
  cache: true,       // Show user data caching
  database: true,    // Show Firestore operations
  performance: true, // Show timing metrics
  chat: false,       // Hide chat logs for focus
  ui: false,         // Hide UI noise
);
```

### What to Look For

#### 1. App Start:
```
🔧 AppLogger configured: auth=true, network=true, cache=true...
🔐 [AuthController] Initializing authentication controller
```

#### 2. Phone Authentication:
```
📞 [AuthController] Starting phone verification for: +919876543210
📞 [AuthController] Phone verification request completed
📱 [AuthController] OTP sent successfully, verification ID: ABC123...
🔐 [OTP_VERIFY] Starting OTP verification...
📱 [OTP_VERIFY] Authenticating with Firebase Auth...
✅ [OTP_VERIFY] Firebase Auth successful for user: DEF456...
```

#### 3. Google Authentication:
```
🚀 [AuthController] Starting Google Sign-In process
🌐 [GOOGLE_SIGNIN] Checking network connectivity
📱 [GOOGLE_SIGNIN] Google account selected: user@gmail.com
🔐 [GOOGLE_SIGNIN] Firebase authentication successful
👤 [GOOGLE_SIGNIN] User profile created/updated
📱 [GOOGLE_SIGNIN] Device registered
```

#### 4. Profile Flow:
```
🔍 [AuthController] Checking user profile completion
📋 [AuthController] Profile status - Role selected: false, Profile completed: false
🎭 [AuthController] Role not selected, navigating to role selection
📝 [AuthController] Profile not completed, navigating to profile completion
🏠 [AuthController] Profile complete, navigating to home
```

#### 5. Cache Operations:
```
🏗️ [Cache] Caching user profile data
🏗️ [Cache] User profile cached successfully
🏗️ [Cache] Storing last Google account: user@gmail.com
```

## 🔍 Log Categories & Emojis

| Category | Emoji | Description | Use Case |
|----------|-------|-------------|----------|
| Auth | 🔐 | Authentication operations | Login, signup, verification |
| Network | 🌐 | Network requests | Firebase, API calls, HTTP |
| Cache | 🏗️ | Cache operations | User data, Google accounts |
| Database | 💾 | Local/Remote storage | Firestore, SQLite, SharedPreferences |
| Performance | ⚡ | Performance metrics | Load times, operation timing |
| Error | ❌ | Error conditions | Failures, exceptions |
| Warning | ⚠️ | Warning conditions | Non-critical issues |
| Info | ℹ️ | General information | Status updates, milestones |

## 📊 Log Levels

The logger supports different levels (automatically managed):

- **Verbose**: All logs (development only)
- **Debug**: Debug information
- **Info**: General information
- **Warning**: Warnings and non-critical issues
- **Error**: Errors and exceptions
- **Nothing**: No logs (production)

## 🔧 Advanced Configuration

### Custom Log Filtering

```dart
// Create custom filter function
bool customAuthFilter(String message, String category) {
  // Only show logs containing "auth" or "login" or "profile"
  return message.toLowerCase().contains('auth') ||
         message.toLowerCase().contains('login') ||
         message.toLowerCase().contains('profile') ||
         message.toLowerCase().contains('google') ||
         message.toLowerCase().contains('otp');
}

// Apply custom filter (requires code modification)
AppLogger.setCustomFilter(customAuthFilter);
```

### Log to File (Future Enhancement)

```dart
// Save auth logs to file for detailed analysis
AppLogger.enableFileLogging('auth_debug_logs.txt');

// Limit file size
AppLogger.setMaxLogFileSize(10 * 1024 * 1024); // 10MB
```

### Remote Logging (Future Enhancement)

```dart
// Send auth logs to remote server for production monitoring
AppLogger.enableRemoteLogging(
  serverUrl: 'https://logs.janmat.com/api/auth-logs',
  apiKey: 'your-auth-logs-api-key'
);
```

## 🚨 Troubleshooting

### Common Issues

#### 1. No Auth Logs Appearing
```dart
// Check if auth logs are enabled
final config = AppLogger.getConfiguration();
print('Logger config: $config');

// Enable auth logs
AppLogger.configure(auth: true);
```

#### 2. Too Many Logs
```dart
// Reduce to essentials
AppLogger.configure(
  auth: true,
  network: false,
  cache: false,
  database: false,
  performance: false,
);
```

#### 3. Missing Firebase Logs
```dart
// Ensure network logging is enabled
AppLogger.configure(network: true);
```

#### 4. Cache Issues
```dart
// Check cache operations
AppLogger.configure(cache: true);

// Clear cache manually
final cacheService = UserCacheService();
await cacheService.clearUserCache();
```

## 🔄 Migration Guide

### Converting Existing debugPrint Calls

#### Step 1: Identify Files
```bash
# Find all debugPrint calls in auth-related files
grep -r "debugPrint" lib/features/auth/ --include="*.dart"
```

#### Step 2: Replace with AppLogger
```dart
// Old code
debugPrint('📱 [AUTH_CONTROLLER] Starting Google Sign-In...');

// New code
AppLogger.auth('Starting Google Sign-In', tag: 'AuthController');
```

#### Step 3: Choose Appropriate Category
- `AppLogger.auth()` - for authentication operations
- `AppLogger.network()` - for Firebase/API calls
- `AppLogger.cache()` - for user data caching
- `AppLogger.database()` - for Firestore operations
- `AppLogger.performance()` - for timing metrics

## 🎯 Best Practices

### 1. Use Descriptive Tags
```dart
// Good
AppLogger.auth('OTP verification successful', tag: 'AuthController');

// Bad
AppLogger.auth('OTP verification successful');
```

### 2. Include Context
```dart
// Good
AppLogger.auth('Starting phone verification for: +91$phoneNumber');

// Bad
AppLogger.auth('Starting phone verification');
```

### 3. Use Appropriate Log Levels
```dart
// Info for normal operations
AppLogger.auth('User authentication successful');

// Warning for potential issues
AppLogger.authWarning('Slow authentication response detected');

// Error for failures
AppLogger.authError('Authentication failed', error: e);
```

### 4. Avoid Sensitive Data
```dart
// Good
AppLogger.auth('OTP sent to phone ending in ***210');

// Bad (exposes sensitive data)
AppLogger.auth('OTP sent to +919876543210');
```

## 📝 Testing Scenarios

### Phone Authentication Testing
```dart
// Enable auth logging
AppLogger.enableAuthOnly();

// Test scenarios:
// 1. Valid phone number
// 2. Invalid phone number
// 3. Network failure during OTP send
// 4. Invalid OTP
// 5. OTP timeout
// 6. Resend OTP
```

### Google Authentication Testing
```dart
// Enable comprehensive logging
AppLogger.configure(auth: true, network: true, cache: true);

// Test scenarios:
// 1. First-time Google login
// 2. Returning user (smart account switching)
// 3. Account picker cancellation
// 4. Network interruption
// 5. Invalid Google account
```

### Profile Flow Testing
```dart
// Enable auth and database logging
AppLogger.configure(auth: true, database: true);

// Test scenarios:
// 1. New user registration
// 2. Existing user login
// 3. Role selection
// 4. Profile completion
// 5. Navigation flow
```

## 📊 Performance Impact

- **Memory**: Minimal (~1-2MB additional memory usage)
- **CPU**: Negligible performance impact
- **Storage**: Logs are not persisted by default
- **Network**: No network usage unless remote logging enabled

## 🎯 Quick Debug Commands

### In Flutter DevTools Console:
```dart
// Enable auth-only logging
AppLogger.enableAuthOnly();

// Check current user state
final user = FirebaseAuth.instance.currentUser;
print('Current user: ${user?.email ?? 'null'}');

// Check user document
FirebaseFirestore.instance.collection('users').doc(user?.uid).get().then((doc) {
  print('User document exists: ${doc.exists}');
  if (doc.exists) print('User data: ${doc.data()}');
});

// Clear all auth data (for testing)
FirebaseAuth.instance.signOut();
SharedPreferences.getInstance().then((prefs) => prefs.clear());
```

### In App Code (for testing):
```dart
// Add to any auth screen for quick debugging
void debugAuthState() {
  final user = FirebaseAuth.instance.currentUser;
  AppLogger.auth('Current auth state: ${user != null ? 'authenticated' : 'not authenticated'}');
  if (user != null) {
    AppLogger.auth('User ID: ${user.uid}');
    AppLogger.auth('User email: ${user.email}');
    AppLogger.auth('User phone: ${user.phoneNumber}');
  }
}
```

This authentication logging system will help you effectively test and debug the complete login-to-home-screen flow in your JanMat app! 🎉