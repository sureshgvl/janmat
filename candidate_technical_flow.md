# Candidate Functionality Technical Flow Documentation

## Overview
This document provides a comprehensive technical analysis of the candidate functionality in the JanMat application, including all models, Firebase queries, data flows, and implementation details.

## 1. Core Models Used

### 1.1 Candidate Model (`lib/models/candidate_model.dart`)

```dart
class Candidate {
  final String candidateId;           // Unique identifier (e.g., "candidate_userId")
  final String? userId;              // Firebase Auth user ID
  final String name;                 // Full name
  final String party;                // Political party name
  final String? symbol;              // Party symbol path
  final String cityId;               // City identifier
  final String wardId;               // Ward identifier
  final String? manifesto;           // Campaign manifesto text
  final String? photo;               // Profile photo URL
  final Contact contact;             // Contact information
  final bool sponsored;              // Premium sponsored status
  final bool premium;                // Premium features access
  final DateTime createdAt;          // Registration timestamp
  final ExtraInfo? extraInfo;        // Extended profile data
  final int followersCount;          // Number of followers
  final int followingCount;          // Number following
  final bool? approved;              // Admin approval status
  final String? status;              // "pending_election", "finalized", "rejected"
}
```

### 1.2 Contact Model
```dart
class Contact {
  final String phone;                    // Phone number
  final String? email;                   // Email address
  final Map<String, String>? socialLinks; // Social media links
}
```

### 1.3 ExtraInfo Model
```dart
class ExtraInfo {
  final String? bio;                    // Biography text
  final List<String>? achievements;     // List of achievements
  final String? manifesto;              // Detailed manifesto
  final String? manifestoPdf;           // PDF manifesto URL
  final Contact? contact;               // Extended contact info
  final Map<String, dynamic>? media;    // Photos and videos
  final bool? highlight;                // Highlight status
  final List<Map<String, dynamic>>? events; // Upcoming events
}
```

### 1.4 User Model (`lib/models/user_model.dart`)
```dart
class UserModel {
  final String uid;                    // Firebase Auth UID
  final String name;                   // Display name
  final String phone;                  // Phone number
  final String? email;                 // Email address
  final String role;                   // "voter", "candidate", "admin"
  final bool roleSelected;             // Role selection completion
  final String wardId;                 // User's ward
  final String cityId;                 // User's city
  final int xpPoints;                  // Experience points
  final bool premium;                  // Premium status
  final String? subscriptionPlanId;    // Active subscription
  final DateTime? subscriptionExpiresAt; // Subscription expiry
  final DateTime createdAt;            // Account creation date
  final String? photoURL;              // Profile photo URL
  final int followingCount;            // Following count
}
```

## 2. Firebase Data Structure

### 2.1 Hierarchical Collection Structure
```
Firestore Database Structure:
├── users/{userId}/
│   ├── basic profile data
│   └── following/{candidateId}/ (follow relationships)
│
├── cities/{cityId}/
│   └── wards/{wardId}/
│       └── candidates/{candidateId}/
│           ├── candidate profile data
│           └── followers/{userId}/ (follower relationships)
│
├── subscriptions/{subscriptionId}/
│   └── subscription data
│
└── xp_transactions/{transactionId}/
    └── XP earning/spending records
```

### 2.2 Key Firebase Queries

#### 2.2.1 Candidate Registration Query
```dart
// Create new candidate
await FirebaseFirestore.instance
    .collection('cities')
    .doc(cityId)
    .collection('wards')
    .doc(wardId)
    .collection('candidates')
    .doc(candidateId)
    .set(candidate.toJson());
```

#### 2.2.2 Fetch Candidates by Ward
```dart
// Query: Get all candidates in a specific ward
final snapshot = await _firestore
    .collection('cities')
    .doc(cityId)
    .collection('wards')
    .doc(wardId)
    .collection('candidates')
    .get();

// Result: List of Candidate objects
return snapshot.docs.map((doc) {
  final data = doc.data()! as Map<String, dynamic>;
  final candidateData = Map<String, dynamic>.from(data);
  candidateData['candidateId'] = doc.id;
  return Candidate.fromJson(candidateData);
}).toList();
```

#### 2.2.3 Follow/Unfollow Operations
```dart
// Follow a candidate (Batch write)
final batch = _firestore.batch();

// Add to candidate's followers
batch.set(candidateFollowersRef, {
  'followedAt': FieldValue.serverTimestamp(),
  'notificationsEnabled': notificationsEnabled,
});

// Add to user's following
batch.set(userFollowingRef, {
  'followedAt': FieldValue.serverTimestamp(),
  'notificationsEnabled': notificationsEnabled,
});

// Update follower counts
batch.update(candidateRef, {'followersCount': FieldValue.increment(1)});
batch.update(userRef, {'followingCount': FieldValue.increment(1)});

await batch.commit();
```

#### 2.2.4 Admin Approval Query
```dart
// Update candidate approval status
await _firestore
    .collection('cities')
    .doc(cityId)
    .collection('wards')
    .doc(wardId)
    .collection('candidates')
    .doc(candidateId)
    .update({
      'approved': approved,
      'status': approved ? 'pending_election' : 'rejected',
    });
```

#### 2.2.5 Search Candidates Query
```dart
// Search candidates by name (client-side filtering)
final candidates = await getCandidatesByWard(cityId, wardId);
return candidates.where((candidate) =>
    candidate.name.toLowerCase().contains(query.toLowerCase())
).toList();
```

## 3. Complete Data Flow Architecture

### 3.1 User Onboarding Flow

#### Phase 1: Authentication & Initial Setup
```
1. User opens app
2. App checks: Is first-time user?
   ├── Yes → Navigate to /language-selection
   └── No → Check authentication status

3. User selects language → Stored in SharedPreferences
4. Navigate to /login
5. User authenticates with Gmail → Firebase Auth
6. Check if user profile exists in Firestore
   ├── No → Create new user document
   └── Yes → Load existing profile

7. Check profile completion status
   ├── Incomplete → Navigate to /profile-completion
   └── Complete → Check role selection

8. Check role selection status
   ├── Not selected → Navigate to /role-selection
   └── Selected → Navigate to /home
```

#### Phase 2: Role-Based Dashboard
```
9. User reaches home screen
10. System determines dashboard based on role:
    ├── Voter → Standard home with basic features
    ├── Candidate → Enhanced dashboard with campaign tools
    └── Admin → Administrative controls
```

### 3.2 Candidate Registration Flow

#### Phase 1: Role Selection During Onboarding
```
1. New user completes authentication (Gmail login)
2. User reaches RoleSelectionScreen
3. User selects "Candidate" role from available options
4. System updates user role to 'candidate' in Firestore
5. User is automatically navigated to CandidateSetupScreen
6. System loads user's existing profile data (name from Firebase Auth)
```

#### Phase 2: Form Submission
```
6. User fills candidate registration form:
   ├── Full Name (pre-filled from auth)
   ├── Political Party (dropdown selection)
   ├── Manifesto (optional text field)

7. Form validation:
   ├── Required fields check
   ├── Data sanitization
   ├── Duplicate registration check

8. On successful validation:
   ├── Create Candidate object
   ├── Generate candidateId: "candidate_${userId}"
   ├── Set initial status: approved=false, status="pending_election"
```

#### Phase 3: Database Operations
```
9. Save candidate to Firestore:
   FirebaseFirestore.instance
   .collection('cities').doc(cityId)
   .collection('wards').doc(wardId)
   .collection('candidates').doc(candidateId)
   .set(candidate.toJson())

10. Update user profile:
    FirebaseFirestore.instance
    .collection('users').doc(userId)
    .update({'role': 'candidate'})

11. Success feedback to user
12. Navigate to home screen with candidate role
```

### 3.3 Admin Approval Flow

#### Phase 1: Admin Review
```
1. Admin logs in with admin credentials
2. Navigate to Admin Panel
3. Select "Pending Approval" tab
4. System fetches pending candidates:
   Query: candidates.where('approved', '==', false)
   Result: List of unapproved candidates
```

#### Phase 2: Approval Decision
```
5. Admin reviews candidate details:
   ├── Name, party, ward, city
   ├── Manifesto and contact info
   ├── Registration timestamp

6. Admin makes decision:
   ├── Approve → Update status to "pending_election"
   ├── Reject → Update status to "rejected"

7. Database update:
   await repository.updateCandidateApproval(cityId, wardId, candidateId, approved)
```

#### Phase 3: Finalization
```
8. For approved candidates nearing election:
9. Admin selects "Finalize" action
10. Update status to "finalized"
11. Candidate becomes official election participant
12. Prevents further candidate registrations
```

### 3.4 Follow/Unfollow Flow

#### Phase 1: Follow Action
```
1. Voter views candidate profile
2. Click "Follow" button
3. System validates user authentication
4. Check existing follow relationship
5. If not following:
   ├── Create batch write operation
   ├── Add to candidate's followers collection
   ├── Add to user's following collection
   ├── Update follower counts
   ├── Commit batch transaction
```

#### Phase 2: Real-time Updates
```
6. UI updates immediately:
   ├── Button changes to "Following"
   ├── Follower count increases
   ├── Follow status cached locally

7. Database consistency:
   ├── Candidate followers count updated
   ├── User following count updated
   ├── Relationship records created
```

### 3.5 Search & Discovery Flow

#### Phase 1: Location-Based Search
```
1. User navigates to Candidates tab
2. System loads available cities
3. User selects city → Loads wards for that city
4. User selects ward → Fetches candidates for ward
5. Display results in candidate list
```

#### Phase 2: Candidate Profile View
```
6. User taps candidate card
7. Navigate to CandidateProfileScreen
8. Load candidate data with arguments
9. Check user's follow status
10. Display profile with tabs:
    ├── Info, Manifesto, Media, Contact
```

## 4. Controller Architecture

### 4.1 CandidateController (`lib/controllers/candidate_controller.dart`)

#### Key Methods:
```dart
// Data fetching
Future<void> fetchCandidatesByWard(String cityId, String wardId)
Future<void> fetchCandidatesByCity(String cityId)
Future<void> fetchWardsByCity(String cityId)
Future<void> fetchAllCities()

// CRUD operations
Future<String?> createCandidate(Candidate candidate)
Future<void> updateCandidateApproval(String cityId, String wardId, String candidateId, bool approved)
Future<void> finalizeCandidates(String cityId, String wardId, List<String> candidateIds)

// Follow system
Future<void> followCandidate(String userId, String candidateId)
Future<void> unfollowCandidate(String userId, String candidateId)
Future<void> checkFollowStatus(String userId, String candidateId)

// Search & filtering
Future<void> searchCandidates(String query, {String? cityId, String? wardId})
Future<List<Map<String, dynamic>>> getCandidateFollowers(String candidateId)
```

#### State Management:
```dart
List<Candidate> candidates = [];           // Current candidate list
List<Ward> wards = [];                     // Available wards
List<City> cities = [];                    // Available cities
bool isLoading = false;                    // Loading state
String? errorMessage;                      // Error handling
Map<String, bool> followStatus = {};       // Follow relationship cache
Map<String, bool> followLoading = {};      // Follow operation loading states
```

### 4.2 CandidateDataController (`lib/controllers/candidate_data_controller.dart`)

#### Key Methods:
```dart
// Data management for dashboard
Future<void> loadCandidateData(String userId)
Future<void> saveExtraInfo()
void updateExtraInfo(String field, dynamic value)
void updateContact(String field, dynamic value)
void updatePhoto(String photoUrl)
void resetEditedData()

// Observable state
Rx<Candidate?> candidateData = Rx(null);
Rx<Map<String, dynamic>?> editedData = Rx(null);
RxBool isLoading = false.obs;
RxBool isPaid = false.obs;
```

## 5. Repository Layer Implementation

### 5.1 CandidateRepository (`lib/repositories/candidate_repository.dart`)

#### Core Firebase Operations:
```dart
// Data retrieval
Future<List<Candidate>> getCandidatesByWard(String cityId, String wardId)
Future<List<Candidate>> getCandidatesByCity(String cityId)
Future<List<Ward>> getWardsByCity(String cityId)
Future<List<City>> getAllCities()

// CRUD operations
Future<String> createCandidate(Candidate candidate)
Future<void> updateCandidateApproval(String cityId, String wardId, String candidateId, bool approved)
Future<void> finalizeCandidates(String cityId, String wardId, List<String> candidateIds)

// Follow system
Future<void> followCandidate(String userId, String candidateId, bool notificationsEnabled)
Future<void> unfollowCandidate(String userId, String candidateId)
Future<bool> isUserFollowingCandidate(String userId, String candidateId)
Future<List<Map<String, dynamic>>> getCandidateFollowers(String candidateId)
Future<List<String>> getUserFollowing(String userId)

// Utility methods
Future<Candidate?> getCandidateData(String userId)
Future<bool> hasUserRegisteredAsCandidate(String userId)
Future<void> updateFollowNotificationSettings(String userId, String candidateId, bool notificationsEnabled)
```

## 6. UI Component Flow

### 6.1 Screen Navigation Flow
```
HomeScreen
├── Drawer Menu
│   └── "Become a Candidate" → CandidateSetupScreen
│       └── Success → HomeScreen (with candidate role)
│
├── Candidates Tab → CandidateListScreen
│   ├── City Selection → Ward Selection
│   ├── Candidate List → Candidate Card Tap
│   └── CandidateProfileScreen
│       ├── Info Tab
│       ├── Manifesto Tab
│       ├── Media Tab
│       └── Contact Tab
│
├── Admin Access → AdminPanelScreen
│   ├── Pending Approval Tab
│   ├── Approved Tab
│   ├── Rejected Tab
│   └── Finalized Tab
│
└── Candidate Dashboard → CandidateDashboardScreen
    ├── Basic Info Tab
    ├── Profile Tab
    ├── Achievements Tab
    ├── Manifesto Tab
    ├── Contact Tab
    ├── Media Tab
    ├── Events Tab
    ├── Highlight Tab
    └── Analytics Tab
```

### 6.2 Widget Data Flow
```
CandidateListScreen
├── CandidateController (data source)
├── ModalSelector<City> (city selection)
├── ModalSelector<Ward> (ward selection)
└── ListView.builder → _buildCandidateCard()
    └── GestureDetector → CandidateProfileScreen

CandidateProfileScreen
├── Candidate argument (passed data)
├── ProfileHeader widget
├── TabBarView with 4 tabs
└── Follow button → CandidateController.followCandidate()

CandidateDashboardScreen
├── CandidateDataController
├── TabController (8 tabs)
└── Various section widgets (BasicInfoSection, etc.)
```

## 7. Error Handling & Validation

### 7.1 Client-Side Validation
```dart
// Form validation in CandidateSetupScreen
final isValid = _formKey.currentState!.validate();
if (!isValid) return;

// Required field validation
String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter your name';
  }
  if (value.trim().length < 2) {
    return 'Name must be at least 2 characters';
  }
  return null;
}

// Party selection validation
String? validateParty(String? value) {
  if (value == null) {
    return 'Please select your political party';
  }
  return null;
}
```

### 7.2 Server-Side Validation
```dart
// Duplicate registration check
Future<bool> hasUserRegisteredAsCandidate(String userId) async {
  final citiesSnapshot = await _firestore.collection('cities').get();

  for (var cityDoc in citiesSnapshot.docs) {
    final wardsSnapshot = await cityDoc.reference.collection('wards').get();

    for (var wardDoc in wardsSnapshot.docs) {
      final candidateSnapshot = await wardDoc.reference
          .collection('candidates')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (candidateSnapshot.docs.isNotEmpty) {
        return true;
      }
    }
  }
  return false;
}
```

### 7.3 Error Handling Patterns
```dart
// Controller error handling
try {
  candidates = await _repository.getCandidatesByWard(cityId, wardId);
} catch (e) {
  errorMessage = e.toString();
  candidates = [];
} finally {
  isLoading = false;
  update();
}

// UI error display
if (controller.errorMessage != null) {
  return Center(
    child: Column(
      children: [
        const Icon(Icons.error, color: Colors.red),
        Text(controller.errorMessage!),
        ElevatedButton(
          onPressed: () => controller.clearError(),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}
```

## 8. Performance Optimization

### 8.1 Query Optimization
```dart
// Efficient ward-based queries
_firestore
    .collection('cities')
    .doc(cityId)
    .collection('wards')
    .doc(wardId)
    .collection('candidates')
    .get()

// Indexed queries for admin operations
_firestore
    .collection('cities')
    .doc(cityId)
    .collection('wards')
    .doc(wardId)
    .collection('candidates')
    .where('approved', isEqualTo: false)
    .get()
```

### 8.2 Caching Strategy
```dart
// Local state caching in controllers
Map<String, bool> followStatus = {};  // Cache follow relationships
List<Candidate> candidates = [];       // Cache candidate lists
List<Ward> wards = [];                 // Cache ward data
List<City> cities = [];                // Cache city data
```

### 8.3 Batch Operations
```dart
// Batch writes for follow operations
final batch = _firestore.batch();
batch.set(followerRef, followData);
batch.set(followingRef, followingData);
batch.update(candidateRef, {'followersCount': FieldValue.increment(1)});
batch.update(userRef, {'followingCount': FieldValue.increment(1)});
await batch.commit();
```

## 9. Security Considerations

### 9.1 Firebase Security Rules
```javascript
// Candidate data access rules
match /cities/{cityId}/wards/{wardId}/candidates/{candidateId} {
  allow read: if true;  // Public read access
  allow write: if request.auth != null &&
               (request.auth.uid == resource.data.userId ||
                exists(/databases/$(database)/documents/users/$(request.auth.uid)/role) &&
                get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
}

// Follow relationship rules
match /cities/{cityId}/wards/{wardId}/candidates/{candidateId}/followers/{userId} {
  allow read: if true;
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

### 9.2 Data Validation
```dart
// Input sanitization
String sanitizeInput(String input) {
  return input.trim().replaceAll(RegExp(r'[<>]'), '');
}

// File upload validation
bool isValidImageFile(String fileName) {
  final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
  final extension = fileName.split('.').last.toLowerCase();
  return allowedExtensions.contains(extension);
}
```

## 10. Testing Strategy

### 10.1 Unit Testing
```dart
// Repository testing
void testCandidateRepository() {
  test('should create candidate successfully', () async {
    final candidate = Candidate(...);
    final result = await repository.createCandidate(candidate);
    expect(result, isNotNull);
  });

  test('should fetch candidates by ward', () async {
    final candidates = await repository.getCandidatesByWard(cityId, wardId);
    expect(candidates, isA<List<Candidate>>());
  });
}
```

### 10.2 Integration Testing
```dart
// End-to-end candidate flow testing
void testCandidateFlow() {
  testWidgets('complete candidate registration flow', (tester) async {
    // 1. Setup user authentication
    // 2. Navigate to candidate setup
    // 3. Fill form and submit
    // 4. Verify database updates
    // 5. Check role changes
  });
}
```

This comprehensive technical documentation covers the complete candidate functionality flow, from initial user registration through admin approval to premium features, with detailed Firebase queries, data models, and implementation patterns.