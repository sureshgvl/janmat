# Notification Services

This directory contains all notification services for the JanMat app, organized by feature category.

## 📁 Structure

```
lib/services/notifications/
├── candidate_following_notifications.dart  # Candidate & Following notifications
├── event_notifications.dart               # Event-related notifications (pending)
├── chat_notifications.dart                # Communication & Chat notifications (pending)
├── polling_notifications.dart             # Polling & Survey notifications (pending)
├── gamification_notifications.dart        # Achievement & Level notifications (pending)
├── content_notifications.dart             # Content & Feed notifications (pending)
├── location_notifications.dart            # Location & Community notifications (pending)
├── monetization_notifications.dart        # Premium & Payment notifications (pending)
├── system_notifications.dart              # System & Maintenance notifications (pending)
└── ai_notifications.dart                  # Personalization & AI notifications (pending)
```

## 🔧 Integration Guide

### Adding Notifications to Existing Flows

#### 1. Candidate Following/Unfollowing

**In `CandidateFollowManager.followCandidate()`:**

```dart
// After successful follow
await CandidateFollowingNotifications().sendNewFollowerNotification(
  candidateId: candidateId,
  followerId: userId,
);
```

**In `CandidateFollowManager.unfollowCandidate()`:**

```dart
// After successful unfollow
await CandidateFollowingNotifications().sendUnfollowNotification(
  candidateId: candidateId,
  unfollowerId: userId,
);
```

#### 2. Profile Updates

**When candidate updates profile:**

```dart
await CandidateFollowingNotifications().sendProfileUpdateNotification(
  candidateId: candidateId,
  updateType: 'bio', // 'photo', 'contact', 'manifesto', etc.
  updateDescription: 'Updated campaign slogan',
);
```

#### 3. Analytics Triggers

**Profile view spikes:**

```dart
await CandidateFollowingNotifications().sendProfileViewSpikeNotification(
  candidateId: candidateId,
  viewCount: currentViews,
  previousCount: previousViews,
);
```

**Weekly performance reports (via cloud function):**

```dart
await CandidateFollowingNotifications().sendWeeklyContentPerformanceNotification(
  candidateId,
);
```

## 🧪 Testing

### Debug Tester

Use `debug_notifications.dart` to test notifications in development:

1. Temporarily add `NotificationTester` to your app's navigation
2. Run the app and navigate to the tester
3. Click buttons to test different notification types
4. Check console logs and Firebase for notification delivery

### Manual Testing

```dart
// Test from debug console
import 'lib/services/notifications/candidate_following_notifications.dart';

final service = CandidateFollowingNotifications();
await service.sendNewFollowerNotification(
  candidateId: 'real_candidate_id',
  followerId: 'real_user_id',
);
```

## 📊 Notification Data Structure

All notifications are stored in Firestore:

```
users/{userId}/notifications/{notificationId}
├── title: string
├── body: string
├── data: {
│   ├── type: string (e.g., 'new_follower', 'profile_update')
│   ├── candidateId: string
│   ├── ... (type-specific data)
│   └── timestamp: serverTimestamp
│   }
├── read: boolean
└── createdAt: serverTimestamp
```

## 🔄 Push Notification Flow

1. **Trigger**: Action occurs (follow, update, etc.)
2. **Service Call**: Notification service method called
3. **Token Retrieval**: Get FCM token from user document
4. **Push Send**: Send to FCM (currently logged, implement backend)
5. **Database Store**: Save notification to user's collection
6. **Delivery**: User receives push notification
7. **In-App**: Notification appears in app's notification center

## ⚙️ Configuration

### Notification Preferences

Candidates can configure notification preferences:

```dart
// Stored in users/{candidateId}/preferences
{
  'notifications': {
    'newFollowers': true,
    'followerMilestones': true,
    'unfollowAlerts': false, // Opt-in
    'profileUpdates': true,
    'newPosts': true,
    'performanceReports': true,
  }
}
```

### FCM Setup

Ensure Firebase Cloud Messaging is properly configured:

1. Add `firebase_messaging` dependency
2. Configure FCM in `main.dart`
3. Store FCM tokens in user documents
4. Handle notification permissions

## 🚀 Next Steps

1. ✅ **Candidate & Following Notifications** - Completed
2. 🔄 **Event-Related Notifications** - Next priority
3. 📋 **Communication & Chat Notifications** - After events
4. 🎮 **Gamification & Achievement Notifications** - High engagement
5. 📊 **Polling & Survey Notifications** - Community building
6. 📍 **Location & Community Notifications** - Local relevance
7. 💰 **Monetization & Premium Notifications** - Business features
8. 🔧 **System & Maintenance Notifications** - User experience
9. 🤖 **Personalization & AI Notifications** - Advanced features

## 📈 Analytics & Monitoring

Track notification effectiveness:

- Delivery rates
- Open rates
- User engagement after notifications
- Opt-out rates
- A/B test different message formats

## 🔒 Security & Privacy

- Respect user notification preferences
- Don't send notifications to users who have disabled them
- Handle FCM token updates securely
- Comply with notification permission requirements