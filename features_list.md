# JanMat App Features List

## Overview
JanMat is a Flutter-based mobile application designed for political engagement, allowing users to connect with local candidates, participate in discussions, and access premium features through a gamified monetization system.

## Core Features

### 1. Authentication & User Management
- Phone number-based authentication using Firebase Auth
- Multi-language support (English and Marathi)
- Role-based system (Voter, Candidate, Admin)
- Profile completion workflow
- Account deletion functionality
- Device management

### 2. User Roles & Permissions
- **Voters**: Browse candidates, participate in chat rooms, vote in polls, follow candidates
- **Candidates**: Register for elections, manage campaign profiles, create chat rooms, access analytics
- **Admins**: Moderate content, approve candidates, access admin panel, manage system

## Candidate Management System

### 3. Candidate Registration & Approval

#### Overview
A comprehensive workflow for candidate registration, admin review, and election finalization with proper validation and status tracking.

#### Step-by-Step Process

**Phase 1: User Registration & Role Selection**
1. User authenticates using phone number via Firebase Auth
2. Completes basic profile with location information
3. Selects "Candidate" role during role selection
4. System captures city and ward data from user location

**Phase 2: Candidate Profile Creation**
1. User accesses candidate setup form with required fields:
   - Full Name (minimum 2 characters)
   - Political Party (dropdown with 16+ parties: BJP, Congress, Shiv Sena, etc.)
   - Manifesto (optional text field)
2. Form validation ensures data integrity
3. System prevents duplicate registration by checking existing user-candidate mappings
4. Initial candidate status: `approved: false`, `status: 'pending_election'`

**Phase 3: Admin Review & Approval**
1. Admins access Admin Panel with 4 review tabs:
   - **Pending Approval**: Lists all self-declared candidates
   - **Approved**: Shows approved but unfinalized candidates
   - **Rejected**: Shows rejected applications
   - **Finalized**: Shows official election candidates
2. Admin reviews complete candidate details (name, party, ward, city, manifesto)
3. Approval options:
   - **Approve** (✓): Sets `approved: true`, `status: 'pending_election'`
   - **Reject** (✗): Sets `approved: false`, `status: 'rejected'`

**Phase 4: Election Finalization**
1. Admin finalizes approved candidates before election
2. Status changes from `'pending_election'` to `'finalized'`
3. Finalized candidates become official election participants
4. Prevents late candidate registrations

**Phase 5: Post-Approval Features**
1. Approved candidates access Candidate Dashboard
2. Can manage campaigns, view analytics, update profiles
3. Unlock premium subscription options
4. Create chat rooms and engage with voters

#### Technical Implementation
- **Data Structure**: Nested Firestore collections (cities/wards/candidates)
- **Validation**: Client-side and server-side validation
- **Security**: Firebase rules for authorized access
- **Real-time**: Instant updates across all devices
- **Audit Trail**: Timestamped status changes

### 4. Candidate Profiles
- Comprehensive profile information (name, party, contact details)
- Photo uploads and media management
- Manifesto creation and editing (premium feature)
- Contact information display
- Followers count and analytics

### 5. Candidate Discovery
- Browse candidates by city and ward
- Search functionality by name
- "My Area Candidates" feature
- Follow/unfollow system with notifications
- Followers list management

## Communication Features

### 6. Chat System

#### Overview
A comprehensive real-time messaging system with role-based access, quota management, and interactive features.

#### Step-by-Step Process

**Phase 1: Chat Room Access**
1. User navigates to Chat Rooms tab from main navigation
2. System fetches available chat rooms based on user role:
   - **Admins**: Access all chat rooms (public and private)
   - **Candidates**: Access rooms they created or public rooms
   - **Voters**: Access only public rooms
3. Chat rooms are displayed in WhatsApp-style list with:
   - Room icons (city, person, or group icons)
   - Room titles and descriptions
   - Creation timestamps
   - Private/Public badges

**Phase 2: Message Quota Management**
1. System displays remaining message quota in app bar
2. Color-coded indicator shows quota status:
   - **Green**: Messages available
   - **Red**: Quota exceeded
3. Daily quota reset at midnight
4. Premium users and candidates have unlimited messaging

**Phase 3: Sending Messages**
1. User selects chat room and enters message
2. System validates message quota before sending
3. If quota exceeded, user options:
   - **Watch Rewarded Ad**: Earns 3-5 XP and extra messages
   - **Purchase XP Pack**: Buy premium XP for unlimited messaging
   - **Cancel**: Cannot send message
4. Message sent with real-time delivery to all room participants

**Phase 4: Interactive Features**
1. **Message Reactions**: Users can add emoji reactions to messages
2. **Media Uploads**: Support for images and documents via Firebase Storage
3. **Read Receipts**: Track message read status by participants
4. **Message Reporting**: Users can report inappropriate content
5. **Polls**: Create and vote on polls within chat rooms

**Phase 5: Room Management**
1. **Room Creation** (Candidates/Admins only):
   - Set room title and description
   - Choose public or private type
   - Auto-generated unique room ID
2. **Room Moderation** (Admins only):
   - Delete inappropriate messages
   - Monitor reported content
   - Manage room access

**Phase 6: Advanced Features**
1. **Real-time Updates**: Instant message delivery using Firebase
2. **Offline Support**: Messages queue when offline
3. **Search Functionality**: Find specific messages or participants
4. **Notification System**: Push notifications for new messages

#### Technical Implementation
- **Real-time Sync**: Firebase Firestore real-time listeners
- **File Storage**: Firebase Storage for media uploads
- **Quota System**: Daily reset with XP-based extensions
- **Security**: Role-based access control and content moderation
- **Performance**: Efficient message pagination and caching

### 7. Polls & Engagement
- Create polls within chat rooms
- Real-time voting system
- Vote tracking and results display
- Anonymous voting options
- Poll analytics

## Monetization & Premium Features

### 8. Subscription System

#### Overview
A comprehensive monetization system with subscription plans, XP rewards, and ad integration for sustainable revenue generation.

#### Step-by-Step Process

**Phase 1: XP Earning through Ads**
1. User reaches daily message limit or wants bonus XP
2. System checks AdMob service for available rewarded ads
3. User watches 15-30 second video advertisement
4. Upon completion, user earns 3-5 XP points randomly
5. XP is credited to user's account instantly
6. User can continue messaging or access premium features

**Phase 2: Premium Subscription Purchase**
1. User navigates to Premium Features screen
2. System displays two tabs: "For Candidates" and "For Voters"
3. User selects appropriate tab based on their role
4. System loads available subscription plans from Firestore
5. User reviews plan features and pricing

**Phase 3: Candidate Premium Plans**
1. **Limited First 1000 Plan** (₹1,999):
   - Manifesto CRUD operations
   - Media upload capabilities
   - Contact information display
   - Followers analytics dashboard
   - Sponsored visibility tags
   - Progress bar shows remaining slots
2. **Regular Premium Plan** (₹5,000):
   - All features of first 1000 plan
   - Available after limit is reached

**Phase 4: Voter XP Plans**
1. **XP Pack (100 XP)** (₹299):
   - Unlock premium content access
   - Join premium chat rooms
   - Vote in exclusive polls
   - Reward other voters with XP
2. XP balance displayed prominently
3. Real-time balance updates after purchases

**Phase 5: Payment Processing**
1. User confirms purchase with dialog showing plan details
2. System validates user authentication
3. Payment processing through integrated payment gateway
4. Upon success, subscription is activated immediately
5. User role updated (candidate → candidate_premium)
6. Premium features unlocked instantly

**Phase 6: Premium Feature Access**
1. **For Premium Candidates**:
   - Enhanced profile visibility
   - Sponsored tags in search results
   - Advanced analytics dashboard
   - Media upload to Firebase Storage
   - Unlimited messaging in all rooms
2. **For Premium Voters**:
   - Access to candidate-only content
   - Participation in premium chat rooms
   - Exclusive poll voting rights
   - Ability to reward other users

**Phase 7: Analytics & Reporting**
1. Admin dashboard tracks subscription metrics
2. Revenue analytics and user engagement reports
3. Premium user statistics and conversion rates
4. XP transaction history and usage patterns

#### Technical Implementation
- **AdMob Integration**: Rewarded video ads with random XP rewards (3-5 points)
- **Payment Gateway**: Secure payment processing with confirmation
- **Real-time Updates**: Instant feature unlocking after purchase
- **Subscription Management**: Plan-based feature access control
- **XP System**: Transaction logging and balance management
- **Analytics**: Revenue tracking and user behavior insights

### 9. XP Points & Gamification
- XP earning through ad watching
- XP transactions tracking
- XP-based premium feature access
- Daily message quotas for free users
- XP rewards system

### 10. Advertising Integration
- AdMob integration for revenue generation
- Rewarded video ads for XP earning
- Banner and interstitial ads
- Ad-based quota extensions

## Administrative Features

### 11. Admin Panel

#### Overview
A comprehensive administrative dashboard for managing the entire platform with role-based access control and real-time monitoring.

#### Step-by-Step Process

**Phase 1: Admin Authentication & Access**
1. Admin user logs in with special admin credentials
2. System validates admin role and permissions
3. Admin accesses Admin Panel through navigation menu
4. Dashboard loads with 4 main tabs for different management areas

**Phase 2: Candidate Management Workflow**
1. **Pending Approval Tab**:
   - Displays all candidates with `approved: false` status
   - Shows candidate details: name, party, ward, city, manifesto
   - Lists candidates in chronological order (newest first)
2. **Review Process**:
   - Admin clicks on candidate card to view full details
   - System displays contact information, manifesto, and creation date
   - Admin can approve or reject with single button click
3. **Approval Actions**:
   - **Approve**: Updates `approved: true`, `status: 'pending_election'`
   - **Reject**: Updates `approved: false`, `status: 'rejected'`
   - Changes reflect immediately in all tabs

**Phase 3: Election Management**
1. **Approved Tab**: Shows candidates ready for finalization
2. **Finalization Process**:
   - Admin reviews approved candidates before election
   - Click "Finalize" button for individual candidates
   - Status changes from `'pending_election'` to `'finalized'`
   - Finalized candidates become official election participants
3. **Rejected Tab**: Shows rejected candidates for record keeping

**Phase 4: Analytics & Reporting**
1. **Revenue Analytics**:
   - Total subscriptions and active subscriptions
   - Revenue tracking from all plans
   - Premium user conversion rates
2. **User Engagement Metrics**:
   - Total premium candidates count
   - XP transaction volumes
   - Chat room activity statistics
3. **System Health Monitoring**:
   - User registration trends
   - Feature usage patterns
   - Error rates and system performance

**Phase 5: Content Moderation**
1. **Message Moderation**:
   - Access to reported messages queue
   - Review reported content with context
   - Delete inappropriate messages permanently
   - Track moderation actions for audit trail
2. **User Management**:
   - View user activity and engagement
   - Manage user roles and permissions
   - Handle user reports and disputes

**Phase 6: System Administration**
1. **Data Management**:
   - Initialize sample data for testing
   - Refresh system caches and data
   - Export reports and analytics data
2. **Configuration Management**:
   - Update system settings and parameters
   - Manage subscription plans and pricing
   - Configure ad placements and rewards

#### Technical Implementation
- **Role-Based Security**: Strict admin-only access controls
- **Real-time Updates**: Live data synchronization across admin sessions
- **Audit Logging**: Complete action tracking for compliance
- **Performance Monitoring**: System health and usage analytics
- **Data Export**: CSV/PDF report generation capabilities

### 12. Content Moderation

#### Overview
A comprehensive content moderation system ensuring platform safety with user reporting, automated monitoring, and administrative controls.

#### Step-by-Step Process

**Phase 1: User Reporting System**
1. User identifies inappropriate content in chat rooms
2. Tap and hold on message to access reporting options
3. Select reason for reporting:
   - Harassment or bullying
   - Spam or inappropriate content
   - Hate speech or discrimination
   - Misinformation
   - Other violations
4. System captures report with:
   - Reporter ID and timestamp
   - Message content and context
   - Room ID and message ID
   - Report reason and additional details

**Phase 2: Report Processing**
1. **Automated Initial Review**:
   - System flags reports for admin attention
   - Reports stored in `reported_messages` collection
   - Status set to 'pending' for review
2. **Admin Notification**:
   - Reports appear in Admin Panel
   - Real-time notifications for urgent reports
   - Priority queuing based on severity

**Phase 3: Admin Review & Action**
1. **Report Investigation**:
   - Admin accesses reported message with full context
   - Reviews message content, user history, and patterns
   - Checks for repeated violations by same user
2. **Moderation Actions**:
   - **Delete Message**: Permanently removes from chat room
   - **Warn User**: Issues warning with violation details
   - **Suspend User**: Temporary account suspension
   - **Ban User**: Permanent account restriction
   - **Dismiss Report**: Mark as false positive

**Phase 4: Message Deletion Process**
1. Admin selects message for deletion
2. System updates message with `isDeleted: true` flag
3. Message becomes invisible to all users
4. Original content preserved for audit purposes
5. Users see "Message deleted by moderator" placeholder

**Phase 5: User Quota Management**
1. **Quota Tracking**:
   - Daily message limits for free users (default: 10-20 messages)
   - Premium users have unlimited messaging
   - Real-time quota monitoring and updates
2. **Quota Extension Options**:
   - Watch rewarded ads for +10 messages
   - Purchase XP packs for unlimited access
   - Automatic daily reset at midnight
3. **Quota Violation Handling**:
   - Graceful blocking of message sending
   - Clear user notifications about quota limits
   - Alternative actions (watch ads, buy premium)

**Phase 6: Content Guidelines Enforcement**
1. **Automated Content Filtering**:
   - Keyword-based content scanning
   - Image and media content analysis
   - Link validation and spam detection
2. **Community Standards**:
   - Clear guidelines displayed to users
   - Educational content about acceptable behavior
   - Progressive warning system for violations
3. **Appeal Process**:
   - Users can appeal moderation decisions
   - Admin review of appeals with detailed reasoning
   - Reinstatement options for false positives

**Phase 7: Analytics & Prevention**
1. **Moderation Metrics**:
   - Report volume and resolution times
   - Common violation types and trends
   - User behavior patterns and risk scoring
2. **Preventive Measures**:
   - Risk-based user monitoring
   - Automated content filtering improvements
   - Community education campaigns

#### Technical Implementation
- **Report Storage**: Dedicated Firestore collection for audit trails
- **Real-time Monitoring**: Instant report notifications to admins
- **Content Analysis**: Automated scanning with AI/ML integration potential
- **Audit Logging**: Complete moderation action history
- **Performance**: Efficient query optimization for large datasets

## Technical Features

### 13. Data Architecture

#### Overview
A hierarchical Firebase Firestore data structure optimized for political engagement with real-time synchronization and efficient querying.

#### Step-by-Step Data Organization

**Phase 1: Core Data Structure Design**
1. **Root Collections**:
   - `users`: User profiles and authentication data
   - `cities`: Geographic organization (Mumbai, Pune, etc.)
   - `chats`: Chat rooms and messaging data
   - `plans`: Subscription plans and pricing
   - `subscriptions`: User subscription records
   - `xp_transactions`: XP earning and spending history

2. **Nested Hierarchical Structure**:
   ```
   cities/{cityId}/
   ├── wards/{wardId}/
   │   └── candidates/{candidateId}/
   │       ├── followers/{userId}
   │       └── analytics/{metricId}
   ```

**Phase 2: User Data Management**
1. **User Profile Storage**:
   - Basic info: name, phone, email, role
   - Location data: cityId, wardId for regional features
   - Gamification: xpPoints, premium status
   - Subscription: planId, expiration dates
2. **User Relationships**:
   - Following/followers collections
   - Chat room memberships
   - Subscription history

**Phase 3: Geographic Data Hierarchy**
1. **City Level**:
   - City metadata (name, population, districts)
   - Ward count and administrative divisions
   - Regional election data and timelines
2. **Ward Level**:
   - Ward boundaries and demographics
   - Local candidate listings
   - Community-specific chat rooms
3. **Candidate Level**:
   - Profile data and campaign information
   - Follower relationships and engagement metrics
   - Media uploads and manifesto storage

**Phase 4: Real-time Synchronization**
1. **Live Data Updates**:
   - Firestore real-time listeners on all collections
   - Instant UI updates across all user devices
   - Conflict resolution for concurrent edits
2. **Offline Support**:
   - Local caching for offline access
   - Sync queues for offline actions
   - Conflict resolution on reconnection

**Phase 5: Chat & Messaging Architecture**
1. **Room Structure**:
   ```
   chats/{roomId}/
   ├── messages/{messageId}
   ├── polls/{pollId}
   └── participants/{userId}
   ```
2. **Message Storage**:
   - Text content and metadata
   - Media file references (Firebase Storage URLs)
   - Read receipts and reaction data
   - Moderation flags and deletion status

**Phase 6: Monetization Data Flow**
1. **Subscription Management**:
   - Plan definitions with feature matrices
   - User subscription records with payment history
   - Feature access control based on subscription status
2. **XP Transaction System**:
   - Earning transactions (ads, engagement)
   - Spending transactions (premium features)
   - Balance calculations and validation
3. **Payment Processing**:
   - Transaction records and confirmations
   - Refund handling and dispute management
   - Revenue analytics and reporting

**Phase 7: Security & Access Control**
1. **Firebase Security Rules**:
   - Role-based read/write permissions
   - Geographic access restrictions
   - Premium content gating
2. **Data Validation**:
   - Client-side and server-side validation
   - Data sanitization and type checking
   - Rate limiting and abuse prevention

**Phase 8: Performance Optimization**
1. **Query Optimization**:
   - Composite indexes for complex queries
   - Pagination for large datasets
   - Efficient geographic queries
2. **Caching Strategy**:
   - User session data caching
   - Frequently accessed data in memory
   - CDN integration for media files

#### Technical Implementation
- **Firestore Indexes**: Optimized for location-based and role-based queries
- **Data Migration**: Versioned schema updates with backward compatibility
- **Backup & Recovery**: Automated daily backups with disaster recovery
- **Monitoring**: Real-time performance metrics and query analysis

### 14. User Experience
- Bottom navigation bar (Home, Candidates, Chat, Polls, Profile)
- Drawer navigation with quick actions
- Responsive design for mobile devices
- Loading states and error handling
- Offline data persistence (implied)

### 15. Analytics & Reporting
- User engagement metrics
- Subscription statistics
- Revenue tracking
- Candidate performance analytics
- System usage reports

## Additional Features

### 16. Settings & Preferences
- Language selection
- Notification preferences
- Privacy settings
- Account management

### 17. Security Features
- Firebase Authentication integration
- User data validation
- Secure file uploads
- Account verification processes

### 18. Localization
- English and Marathi language support
- RTL support preparation
- Localized UI elements and messages

## Future Enhancement Areas
- Video calling integration
- Advanced analytics dashboard
- Push notification system
- Offline message queuing
- Advanced search and filtering
- Social media integration
- Election result tracking
- Voting system integration