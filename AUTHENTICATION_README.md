# JanMat Authentication System

## 🎯 Overview

JanMat implements a comprehensive multi-provider authentication system supporting **Phone OTP** and **Google Sign-In** with a guided onboarding flow. The system includes user role selection, Firebase integration, and robust error handling with detailed logging.

## 📁 System Architecture

```
lib/features/auth/
├── controllers/
│   └── auth_controller.dart          # Main auth logic with GetX
├── repositories/
│   └── auth_repository.dart          # Firebase integration & data management
└── screens/
    ├── language_selection_screen.dart # Language choice (en/mr)
    ├── login_screen.dart             # Phone OTP & Google login UI
    └── role_selection_screen.dart    # Voter/Candidate role selection
```

## 🚀 Authentication Flow

### **User Journey:**
```
1. Language Selection → 2. Login → 3. Home (with intelligent onboarding)
                                      ↓
                            Role ↙     ↓     ↘ Profile
                           Setup      Complete      Setup
```

### **Detailed Flow:**

| Step | Screen | Purpose | Result |
|------|---------|---------|--------|
| 1 | Language Selection | Choose app language | Stores preference, proceeds to login |
| 2 | Login Screen | Phone OTP or Google Sign-In | Firebase auth + user document creation |
| 3 | **Home Screen** | **Check completion status** | **Display onboarding prompts if needed** |
| 3a | **Role Selection** | **Choose role (voter/candidate)** | **Updates user role in Firestore** |
| 3b | **Profile Completion** | **Complete required fields** | **Full user profile ready** |

## 🏗️ Core Components

### 1. Auth Controller (`auth_controller.dart`)

#### **Key Features:**
- **Phone OTP Authentication** with Firebase
- **Google Sign-In Integration** with smart account management
- **Reactive UI State** using GetX observables
- **OTP Timer & Resend Logic**
- **Comprehensive Error Handling**

```dart
class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  // Reactive properties
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  RxBool isLoading = false.obs;
  RxBool isOTPScreen = false.obs;
  RxBool canResendOTP = false.obs;
  RxInt otpTimer = 60.obs;

  // Phone OTP Flow
  Future<void> sendOTP() async {
    isLoading.value = true;
    try {
      await _authRepository.verifyPhoneNumber(phoneController.text, (String vid) {
        verificationId.value = vid;
        isOTPScreen.value = true;
        _startOTPTimer();
        Get.snackbar('Success', 'OTP sent to +91${phoneController.text}');
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to send OTP: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Smart Google Sign-In
  Future<void> signInWithGoogle({bool forceAccountPicker = false}) async {
    isLoading.value = true;

    try {
      final userCredential = await _authRepository.signInWithGoogle(
        forceAccountPicker: forceAccountPicker
      );

      if (userCredential?.user != null) {
        await _authRepository.createOrUpdateUser(userCredential!.user!);
        Get.snackbar('Success', 'Google sign-in successful');
        Get.offAllNamed('/home'); // Navigate to home on success
      }
    } catch (e) {
      Get.snackbar('Error', 'Google sign-in failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
```

### 2. Auth Repository (`auth_repository.dart`)

#### **Comprehensive Firebase Integration:**

**🔐 Authentication Methods:**
- Phone number verification with reCAPTCHA
- OTP verification and sign-in
- Google Sign-In with account persistence
- Firebase Auth state management

**💾 Data Management:**
- User document creation/update in Firestore
- Account deletion with cascading cleanup
- Storage usage analysis
- Cache management

**🛠️ Background Operations:**
- FCM token updates
- Background sync initialization
- Storage cleanup
- Performance monitoring

```dart
class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // Phone Authentication - Optimized for Indian users (+91)
  Future<void> verifyPhoneNumber(String phoneNumber, Function(String) onCodeSent) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-sign in for verified Android devices
        await _firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw e;
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        onCodeSent(verificationId); // Use SMS OTP when auto-fails
      },
      timeout: const Duration(seconds: 30),
    );
  }

  // Optimized Google Sign-In with smart account management
  Future<UserCredential?> signInWithGoogle({bool forceAccountPicker = false}) async {
    // 1. Check network connectivity
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    // 2. Smart account selection
    GoogleSignInAccount? googleUser;
    if (!forceAccountPicker) {
      // Try silent sign-in first (for returning users)
      googleUser = await _googleSignIn.signInSilently().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    }

    if (googleUser == null) {
      // Show account picker for new/changed accounts
      googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 45),
      );
    }

    if (googleUser == null) return null;

    // 3. Store account for future smart login
    await _storeLastGoogleAccount(googleUser);

    // 4. Create Firebase credentials
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 5. Firebase authentication
    final userCredential = await _firebaseAuth.signInWithCredential(credential);

    // 6. Create/update user document
    await _createOrUpdateUserMinimal(userCredential.user!);

    // 7. Background setup (FCM, sync, cache)
    _performBackgroundSetup(userCredential.user!);

    return userCredential;
  }

  // Complete user data setup with role and profile information
  Future<void> createOrUpdateUser(User firebaseUser, {
    String? name,
    String? role,
  }) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);

    final userModel = UserModel(
      uid: firebaseUser.uid,
      name: name ?? firebaseUser.displayName ?? 'User',
      phone: firebaseUser.phoneNumber ?? '',
      email: firebaseUser.email,
      role: role ?? '',
      roleSelected: false, // Set during role selection
      profileCompleted: false, // Set during profile completion
      electionAreas: [],
      xpPoints: 0,
      premium: false,
      createdAt: DateTime.now(),
      photoURL: firebaseUser.photoURL,
    );

    await userDoc.set(userModel.toJson(), SetOptions(merge: true));

    // Create user quota limits
    await _createDefaultUserQuota(firebaseUser.uid);
  }

  // Account deletion with comprehensive cleanup
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    // Delete in batches to handle large datasets
    await _deleteUserDataInChunks(user.uid, /* isCandidate */ false);

    // Delete Firebase Auth account
    await user.delete();

    // Clear local data and controllers
    await _clearLogoutCache();
    await _clearAllControllers();
  }
}
```

### 3. Login Screen (`login_screen.dart`)

#### **Smart Authentication UI:**

**🎯 Features:**
- **Phone OTP Input** with real-time validation
- **Google Sign-In** with smart account management
- **Dynamic UI States** (Phone ↔ OTP screens)
- **OTP Timer & Auto-resend**
- **Remembered Google Accounts** for quick login

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Obx(
            () => controller.isOTPScreen.value
                ? _buildOTPScreen(context, controller)
                : _buildPhoneInputScreen(context, controller),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, AuthController controller) {
    return FutureBuilder<Map<String, dynamic>?>( // Smart account detection
      future: controller.getLastGoogleAccount(),
      builder: (context, snapshot) {
        final hasStoredAccount = snapshot.hasData && snapshot.data != null;

        return Obx(() => Column(
          children: [
            // Show "Continue as [Name]" for returning users
            if (hasStoredAccount && !controller.isLoading.value) ...[
              ElevatedButton(
                onPressed: () => controller.signInWithGoogle(forceAccountPicker: false),
                child: Row(children: [
                  Image.asset('assets/images/google_logo.png', height: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Continue as ${snapshot.data?['displayName']}'),
                      Text(snapshot.data?['email'] ?? '',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ]),
              ),

              // Option to sign in with different account
              ElevatedButton.icon(
                onPressed: () => controller.signInWithGoogle(forceAccountPicker: true),
                icon: Image.asset('assets/images/google_logo.png', height: 24),
                label: Text('Sign in with different account'),
              ),
            ] else ...[
              // Standard Google Sign-In button for new users
              ElevatedButton.icon(
                onPressed: () => controller.signInWithGoogle(),
                icon: Image.asset('assets/images/google_logo.png', height: 24),
                label: Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ],
        ));
      },
    );
  }
}
```

## 🔐 Authentication Methods

### **Phone OTP Authentication**

| Feature | Implementation | Benefit |
|---------|----------------|---------|
| **Firebase Phone Auth** | `verifyPhoneNumber()` | Secure, server-side OTP |
| **Indian Numbers** | `+91${phoneNumber}` | No manual country code |
| **Auto-Verification** | Android auto-retrieval | Seamless UX for verified devices |
| **OTP Timer** | 60-second countdown | Prevents spam, shows resend option |
| **SMS Fallback** | Manual OTP entry | Works on all devices/sim cards |

### **Google Sign-In Integration**

| Feature | Implementation | Benefit |
|---------|----------------|---------|
| **Smart Account Detection** | Silent sign-in first | Quick login for returning users |
| **Account Persistence** | SharedPreferences storage | Remembers last used account |
| **Force Account Switch** | Account picker option | Login with different accounts |
| **Network Checks** | Connectivity verification | Prevents failed attempts |
| **Background Setup** | Async initialization | Fast UI response |

## 🗂️ User Data Management

### **Firestore User Document Structure:**

```json
{
  "uid": "firebase_user_id",
  "name": "Display Name",
  "phone": "+91xxxxxxxxxx" | "",
  "email": "user@example.com" | null,
  "role": "voter" | "candidate" | "",
  "roleSelected": true | false,
  "profileCompleted": true | false,
  "electionAreas": ["district/ward/area"],
  "xpPoints": 100,
  "premium": false,
  "photoURL": "firebase_storage_url" | null,
  "createdAt": "2024-01-01T00:00:00.000Z",
  "lastLogin": "2024-01-01T00:00:00.000Z"
}
```

### **User Creation Flow:**

1. **Minimal Document** (fast) - Basic auth info on login
2. **Home Screen Context** - User sees you the app is about immediately
3. **Dynamic Onboarding** - Role/profile prompts appear based on completion status
4. **Background Sync** - FCM tokens, caching, data loading continues in background

### **Why This Approach vs Traditional Forced Flow:**

**❌ Traditional Approach (what ChatGPT suggested):**
```dart
// After login: Check and redirect to onboarding
if (!user.roleSelected) {
  Get.offAllNamed('/role-selection');
} else if (!user.profileCompleted) {
  Get.offAllNamed('/profile-setup');
} else {
  Get.offAllNamed('/home');
}
```
**Problems:** Pre-maturely forces setup, blocks app access, poor UX.

**✅ Current Smart Approach:**
```dart
// After login: Always go home, check status there
Get.offAllNamed('/home');
// Home screen shows contextual prompts for incomplete profiles
```
**Benefits:** Immediate app access, contextual guidance, no forced flow.

**Result:** Users see app content first → get motivated → complete setup willingly.

## 🎨 UI/UX Design Patterns

### **Authentication Screens:**

#### Language Selection Screen
- **Gradient Background** with flag icons
- **Radio-style Selection** for language choice
- **Smooth Continue Animation**

#### Login Screen
- **OTP Flow Toggle** - Phone input → OTP verification
- **Smart Google Buttons** - Account-aware login options
- **Loading States** with progress dialogs
- **Error Handling** with user-friendly messages

#### Role Selection Screen
- **Card-based UI** for role comparison
- **Visual Selection** with check indicators
- **Role Descriptions** explaining benefits
- **Mandatory Selection** before continuing

### **Error Handling:**

```dart
// Categorized error messages
final errorMessages = {
  'network': 'Network error. Check connection and retry.',
  'user_cancelled': 'Sign-in was cancelled.',
  'auth_failed': 'Authentication failed. Please try again.',
  'account_issue': 'Account selection failed. Try different account.',
  'firebase_timeout': 'Sign-in taking too long. Please wait and retry.'
};
```

## 🚀 Performance Optimizations

### **Background Operations:**
- **Lazy Loading** - User document created after login success
- **Minimal Initial Data** - Only essential fields on first login
- **Async Setup** - FCM, caching, sync happen in background
- **Timeout Handling** - Prevents hanging on network issues

### **Caching Strategy:**
- **Last Google Account** - SharedPreferences for quick subsequent logins
- **User Data Caching** - Local storage for offline profile access
- **Image Caching** - Profile pictures cached for fast loading

### **Network Optimization:**
- **Connectivity Checks** - Prevents failed auth attempts
- **Timeout Management** - Appropriate timeouts for different operations
- **Retry Logic** - Smart retries for transient failures

## 🛠️ Setup & Configuration

### **Firebase Configuration:**

```yaml
# pubspec.yaml
dependencies:
  firebase_auth: ^4.15.0
  google_sign_in: ^6.1.0
  cloud_firestore: ^4.13.0
  firebase_app_check: ^0.2.1+7
```

### **Android Configuration:**

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Add to application section -->
<meta-data
    android:name="flutterEmbedding"
    android:value="2" />
```

### **Google Sign-In Setup:**
1. **Firebase Console** → Authentication → Sign-In Methods → Google (Enable)
2. **Google Cloud Console** → OAuth consent screen & credentials
3. **SHA-256 fingerprints** from Play Store/app signing
4. **Android Client ID** in Firebase console

### **App Initialization:**

```dart
void main() async {
  // Initialize controllers early for reactive auth
  Get.put<AuthController>(AuthController());

  await Firebase.initializeApp();

  // Enable app check for production
  if (kReleaseMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
  }

  runApp(const MyApp());
}
```

## 🔍 Debug Information

### **Logging Categories:**

```dart
AppLogger.configure(
  auth: true,          // Authentication flow logs
  network: true,       // Connectivity & API calls
  firebase: true,      // Firestore operations
  performance: true,   // Slow operation tracking
);
```

### **Common Debug Output:**

```
🔄 [GOOGLE_SIGNIN] Starting Google Sign-In
📱 [GOOGLE_SIGNIN] Checking network connectivity
✅ [GOOGLE_SIGNIN] Silent sign-in successful: user@domain.com
🔑 [GOOGLE_SIGNIN] Authentication tokens retrieved
🔐 [GOOGLE_SIGNIN] Firebase authentication successful
👤 [GOOGLE_SIGNIN] User document created
✅ [GOOGLE_SIGNIN] Login completed in 2.3s
```

## 🐛 Troubleshooting Common Issues

### **Firebase Phone Auth Issues:**

1. **"reCAPTCHA verification failed"**
   - Check SHA-256 fingerprints in Firebase console
   - Verify app package name matches Firebase config

2. **"SMS not received"**
   - Test with different phone numbers
   - Check Firebase Phone Auth quota limits
   - Verify device/sim card compatibility

3. **"Invalid OTP"**
   - Check verificationId matches the one from codeSent callback
   - Ensure OTP entered matches SMS exactly
   - Test with automatic verification on Android

### **Google Sign-In Problems:**

1. **"PlatformException(sign_in_failed)"**
   - Verify SHA-256 fingerprints are correct
   - Check Google Play Services on device
   - Ensure OAuth client IDs match

2. **"Silent sign-in not working"**
   - Clear app data/cache
   - Test on different devices
   - Check if previous sign-out was complete

3. **Network timeouts**
   - Increase timeout values for slow connections
   - Add retry logic for failed attempts
   - Test connectivity before sign-in

### **Data Synchronization Issues:**

1. **User document not created**
   - Check Firestore security rules
   - Verify authentication state
   - Check Firebase project permissions

2. **Role not updating**
   - Ensure user is authenticated
   - Check Firestore write permissions
   - Verify document path correctness

## 📋 Security Best Practices

### **Authentication:**
- **Firebase App Check** enabled in production
- **SHA-256 fingerprint verification** for Google Sign-In
- **Phone number validation** before OTP requests
- **Session management** with automatic logout

### **Data Protection:**
- **Firestore Security Rules** for user data access control
- **Encryption** for sensitive user information
- **Account deletion** with complete data cleanup
- **GDPR compliance** for data deletion requests

### **Privacy:**
- **Minimal data collection** on initial login
- **User consent** for optional profile information
- **Transparent data usage** explanations
- **Clean account deletion** functionality

## 🚀 Future Expansion Roadmap

### **Q1 2025 - Enhanced Auth Features:**
- **Apple Sign-In** integration for iOS users
- **Multi-device session sync** across mobile/web
- **Advanced biometric authentication** (FaceID/TouchID)
- **OTP-less password reset** via magic links

### **Q2 2025 - Social & Analytics:**
- **Social login expansion** (GitHub, Twitter for candidates)
- **Advanced user analytics** and engagement tracking
- **AI-powered voter preference matching**
- **Premium subscription integration**

### **Q3 2025 - Enterprise Features:**
- **Organizational authentication** for political parties
- **Bulk user management** for administrators
- **Advanced permission systems** (moderator roles)
- **Audit logging** for compliance

### **Q4 2025 - Global Expansion:**
- **Multi-region Firestore deployment**
- **International phone number support** (+1, +44, +65, etc.)
- **Advanced localization** (RTL support, date formats)
- **Cross-platform consistency** (web, mobile, desktop)

## 🧪 Testing & Development

### **Unit Testing:**
```yaml
# pubspec.yaml - dev_dependencies
mocktail: ^1.0.3
firebase_auth_mocks: ^1.2.0
cloud_firestore_mocks: ^2.0.0
```

```dart
// Example: AuthController testing
void main() {
  late AuthController controller;
  late AuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    controller = AuthController(repository: mockRepo);
  });

  test('should send OTP successfully', () async {
    when(() => mockRepo.verifyPhoneNumber(any(), any()))
        .thenAnswer((_) => Future.value());

    await controller.sendOTP();

    verify(() => mockRepo.verifyPhoneNumber('+919876543210', any())).called(1);
    expect(controller.isOTPScreen.value, true);
  });
}
```

### **Integration Testing:**
```dart
// Example: End-to-end auth flow test
testWidgets('complete phone authentication flow', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());

  // Navigate to login screen
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();

  // Enter phone number
  await tester.enterText(find.byType(TextField).first, '9876543210');
  await tester.tap(find.text('Send OTP'));
  await tester.pumpAndSettle();

  // Enter OTP
  await tester.enterText(find.byType(TextField).last, '123456');
  await tester.tap(find.text('Verify OTP'));
  await tester.pumpAndSettle();

  // Verify navigation to home
  expect(find.text('Home'), findsOneWidget);
});
```

### **Performance Monitoring:**
```dart
// In AuthController methods
Future<void> signInWithGoogle() async {
  final stopwatch = Stopwatch()..start();

  try {
    // ... auth logic ...

    AppLogger.auth('Google Sign-In completed in ${stopwatch.elapsedMilliseconds}ms');
  } catch (e) {
    AppLogger.auth('Google Sign-In failed after ${stopwatch.elapsedMilliseconds}ms');
    rethrow;
  }
}
```

## 🔒 Firestore Security Rules Example

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // User documents - only owners can access
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Allow reading other users' basic info
    }

    // User subcollections
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Chat rooms - complex access control
    match /chats/{chatId} {
      allow read, write: if request.auth != null &&
        (resource.data.createdBy == request.auth.uid ||
         exists(/databases/$(database)/documents/users/$(request.auth.uid)/following/$(chatId)));
    }

    // Polls and messages - room membership required
    match /chats/{chatId}/{document=**} {
      allow read, write: if request.auth != null &&
        exists(/databases/$(database)/documents/chats/$(chatId)/members/$(request.auth.uid));
    }

    // User quotas - admin/moderator access
    match /user_quotas/{userId} {
      allow read, write: if request.auth != null &&
        (request.auth.uid == userId ||
         exists(/databases/$(database)/documents/users/$(request.auth.uid)/role) &&
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

## 🎉 Summary

JanMat's authentication system provides:

- ✅ **Multi-provider support** (Phone OTP + Google Sign-In)
- ✅ **Smart UX features** (account persistence, auto-verification)
- ✅ **Comprehensive onboarding** (language → login → role → profile)
- ✅ **Robust error handling** with user-friendly messages
- ✅ **Performance optimization** with background operations
- ✅ **Security compliance** with Firebase best practices
- ✅ **Scalable architecture** with clean separation of concerns

The authentication flow ensures a **smooth, secure, and delightful user experience** from first app launch through ongoing engagement.
