# Firebase Collections Architecture Analysis

This document provides a comprehensive analysis of the Firebase Firestore collections used in the Janmat application, including their purposes, use cases, scalability considerations, and architectural recommendations.

## Overview

The Janmat application is a political candidate platform built with Flutter, utilizing Firebase Firestore for data storage. The database architecture includes 11 main collections that handle various aspects of the application including user management, content engagement, monetization, and analytics.

## Firebase Collections

### 1. `/comments/{manifestoId}/comments/{commentId}`

**Purpose**: Stores comments on manifesto content and community posts.

**Structure**:
```
comments/
├── {manifestoId}/
│   └── comments/
│       └── {commentId}
```

**Where Used**:
- Manifesto content viewers (`content_engagement_analytics_section.dart`)
- Community feed posts (`feed_widgets.dart`, `community_feed_service.dart`)
- Local SQLite database for offline caching (`local_database_service.dart`)

**Use Cases**:
- Users can comment on candidate manifestos
- Community engagement on feed posts
- Real-time comment counts in analytics

**Scalability with 1M Users**:
- ✅ Hierarchical structure prevents collection bloat
- ✅ Local SQLite caching for offline support
- ✅ Background sync service handles pending comments
- ✅ Should scale well with proper indexing on manifestoId

**Current Services**:
- `ManifestoCacheService`
- `LocalDatabaseService`

**Recommendations**:
- Extract to dedicated `CommentService` following SOLID principles
- Implement `CommentRepository` for data access layer

---

### 2. `/highlights` (Hierarchical Structure)

**Purpose**: Stores premium highlight banners for candidates (Platinum plan feature).

**Structure**:
```
states/maharashtra/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/highlights/{highlightId}
```

**Where Used**:
- Home screen highlight carousels and banners
- Candidate dashboard for managing highlights
- Monetization system (requires Platinum subscription)

**Use Cases**:
- Candidates can purchase and display highlight banners
- Location-based display (ward/district/body specific)
- Analytics tracking (views, clicks, expiry)

**Scalability with 1M Users**:
- ✅ Hierarchical structure for efficient querying
- ✅ Migration system exists (flat → hierarchical)
- ✅ Active highlights filtered by expiry and location
- ✅ Should handle 1M users well with proper sharding

**Current Services**:
- `HighlightService`
- `HighlightRepository`

**Recommendations**:
- ✅ Well-separated following repository pattern
- Consider implementing caching layer for frequently accessed highlights

---

### 3. `/likes/{likeId}`

**Purpose**: Tracks likes on manifesto content.

**Structure**:
```
likes/
├── {likeId} (contains userId, postId, timestamp)
```

**Where Used**:
- Manifesto content viewers
- Analytics dashboards
- Real-time like counters

**Use Cases**:
- Users can like/unlike manifestos
- Real-time like counts in UI
- Engagement analytics for candidates

**Scalability with 1M Users**:
- ⚠️ Flat collection structure
- ✅ Local SQLite caching for offline support
- ✅ Background sync for pending likes
- ⚠️ Could face performance issues without proper compound indexing on (userId, postId)

**Current Services**:
- `ManifestoLikesService`

**Recommendations**:
- Separate into `LikeService` and `LikeRepository`
- Implement compound indexes on (userId, postId)
- Consider aggregation for like counts to reduce read operations

---

### 4. `/manifesto_polls/{manifestoId}/polls/{pollId}`

**Purpose**: Stores polls within manifesto content for voter engagement.

**Structure**:
```
manifesto_polls/
├── {manifestoId}/
│   └── polls/
│       └── {pollId}
```

**Where Used**:
- Manifesto content viewers
- Analytics sections showing poll participation
- Real-time poll results

**Use Cases**:
- Candidates can create polls in their manifestos
- Voters can participate in polls
- Real-time results display

**Scalability with 1M Users**:
- ✅ Hierarchical structure
- ✅ Local caching with sync service
- ✅ Should scale well with proper indexing

**Current Services**:
- `ManifestoPollService`

**Recommendations**:
- ✅ Well-separated following service pattern
- Consider implementing real-time poll result aggregation

---

### 5. `/notification_settings/{userId}`

**Purpose**: Stores user notification preferences.

**Structure**:
```
notification_settings/
├── {userId} (document containing notification preferences)
```

**Where Used**:
- Notification preferences screen
- FCM notification services
- User settings management

**Use Cases**:
- Users can customize notification preferences
- Control push notifications, email alerts, etc.
- Per-user notification settings

**Scalability with 1M Users**:
- ✅ Simple document-per-user structure
- ✅ Real-time subscriptions for preference changes
- ✅ Scales well as it's read-heavy with infrequent writes

**Current Services**:
- `NotificationSettingsController`

**Recommendations**:
- Extract to `NotificationSettingsService`
- Implement default preference templates
- Consider caching frequently accessed preferences

---

### 6. `/pushFeed/{feedId}`

**Purpose**: Stores sponsored/push feed content for monetization.

**Structure**:
```
pushFeed/
├── {feedId} (sponsored post data)
```

**Where Used**:
- Home screen sponsored updates section
- Community feed integration
- Paid content creation

**Use Cases**:
- Candidates can create sponsored posts
- Premium content visibility
- Monetization through sponsored updates

**Scalability with 1M Users**:
- ✅ Ward-based filtering for targeted content
- ✅ Should scale well with location-based queries

**Current Services**:
- Inline in `PushFeedService` (feed widgets)

**Recommendations**:
- Extract to dedicated `PushFeedService`
- Implement `PushFeedRepository`
- Add content moderation and approval workflow

---

### 7. `/section_views/{viewId}`

**Purpose**: Tracks views on different UI sections (banners, carousels).

**Structure**:
```
section_views/
├── {viewId} (contains sectionType, userId, timestamp, etc.)
```

**Where Used**:
- Highlight banner/carousel components
- Analytics for content engagement
- Performance tracking

**Use Cases**:
- Track which sections users view
- Analytics for highlight effectiveness
- Content performance metrics

**Scalability with 1M Users**:
- ⚠️ Write-heavy collection (every view creates a document)
- ⚠️ Could become expensive at scale
- ⚠️ Consider aggregation or sampling for large user base

**Current Services**:
- Inline in repositories (`HighlightRepository`, etc.)

**Recommendations**:
- Extract to dedicated `AnalyticsService`
- Implement sampling (track 10% of views) or aggregation
- Use Firestore counters for high-frequency metrics
- Consider BigQuery for advanced analytics

---

### 8. `/subscriptions/{subscriptionId}`

**Purpose**: Manages user subscription plans and billing.

**Structure**:
```
subscriptions/
├── {subscriptionId} (contains userId, planId, status, dates, etc.)
```

**Where Used**:
- Monetization system
- Plan validation
- Feature access control

**Use Cases**:
- Track active subscriptions
- Validate plan features
- Billing and renewal management

**Scalability with 1M Users**:
- ✅ User-based queries (where userId = ...)
- ✅ Should scale well with proper indexing

**Current Services**:
- `MonetizationRepository`

**Recommendations**:
- ✅ Well-separated following repository pattern
- Implement subscription lifecycle management
- Add billing integration hooks

---

### 9. `/user_following/{userId}`

**Purpose**: Tracks which users follow which candidates.

**Structure**:
```
user_following/
├── {userId} (document containing followed candidate IDs)
```

**Where Used**:
- Following system
- Social features
- Candidate follower counts

**Use Cases**:
- Users can follow candidates
- Follower analytics
- Social engagement tracking

**Scalability with 1M Users**:
- ✅ Document-per-user structure
- ✅ Real-time follower counts
- ✅ Scales well for social features

**Current Services**:
- `FollowingController`

**Recommendations**:
- ✅ Well-separated following MVC pattern
- Implement follower recommendations
- Add follow/unfollow analytics

---

### 10. `/user_mappings/{firebaseUid}`

**Purpose**: Maps phone numbers to Firebase UIDs for authentication.

**Structure**:
```
user_mappings/
├── {firebaseUid} (contains phone number, user data)
```

**Where Used**:
- Authentication system
- User lookup by phone number

**Use Cases**:
- Phone number based authentication
- User identification across devices

**Scalability with 1M Users**:
- ✅ Simple key-value mapping
- ✅ Critical for auth, must be highly available
- ✅ Scales well as read-heavy

**Current Services**:
- Handled in `AuthController`

**Recommendations**:
- Extract to `UserMappingService`
- Implement phone number validation
- Add user migration capabilities

---

### 11. `/user_quotas/{userId}`

**Purpose**: Tracks user usage quotas (chat messages, etc.).

**Structure**:
```
user_quotas/
├── {userId} (contains quota limits, current usage, reset dates)
```

**Where Used**:
- Chat system
- Usage limiting
- Plan enforcement

**Use Cases**:
- Limit chat messages based on plan
- Track user activity
- Prevent abuse

**Scalability with 1M Users**:
- ✅ Document-per-user structure
- ✅ Transaction-based updates for quota management
- ✅ Scales well with proper transaction handling

**Current Services**:
- Handled in `ChatRepository`

**Recommendations**:
- Extract to dedicated `QuotaService`
- Implement quota reset scheduling
- Add quota violation handling and notifications

## Architecture Assessment

### Current State
The codebase follows a reasonable service/repository pattern but could benefit from more consistent SOLID principle application. Some services are well-separated while others are inline or tightly coupled.

### Scalability Status

**Well-Scaled Collections**:
- ✅ `/comments` (hierarchical)
- ✅ `/highlights` (hierarchical)
- ✅ `/manifesto_polls` (hierarchical)
- ✅ `/notification_settings` (document-per-user)
- ✅ `/subscriptions` (indexed queries)
- ✅ `/user_following` (document-per-user)
- ✅ `/user_mappings` (key-value)
- ✅ `/user_quotas` (document-per-user)

**Collections Needing Attention**:
- ⚠️ `/likes` (needs compound indexing)
- ⚠️ `/pushFeed` (needs dedicated service)
- ⚠️ `/section_views` (write-heavy, consider aggregation)

### Recommended Service Separation

**High Priority**:
1. Extract `CommentService` and `CommentRepository`
2. Extract `LikeService` and `LikeRepository`
3. Extract `PushFeedService` and `PushFeedRepository`
4. Extract `AnalyticsService` for section views
5. Extract `QuotaService`

**Medium Priority**:
1. Extract `NotificationSettingsService`
2. Extract `UserMappingService`
3. Implement consistent repository pattern across all services

**Low Priority**:
1. Consider microservice architecture for high-traffic features
2. Implement caching layers for frequently accessed data
3. Add comprehensive monitoring and alerting

## Performance Optimization Recommendations

### For 1M Users

1. **Indexing Strategy**:
   - Compound indexes on frequently queried fields
   - Single field indexes for range queries
   - Partial indexes for filtered queries

2. **Caching Strategy**:
   - Redis for frequently accessed data
   - CDN for static content
   - Local caching for offline capabilities

3. **Data Aggregation**:
   - Pre-computed analytics data
   - Daily aggregation jobs for metrics
   - Sampling for high-frequency events

4. **Architecture Improvements**:
   - CQRS pattern for read/write separation
   - Event sourcing for audit trails
   - Microservices for independent scaling

## Monitoring and Maintenance

### Key Metrics to Monitor
- Query performance and latency
- Collection sizes and growth rates
- Index usage and efficiency
- Error rates and failed operations

### Backup and Recovery
- Regular automated backups
- Point-in-time recovery capabilities
- Data validation and integrity checks

### Migration Strategy
- Versioned migration scripts
- Backward compatibility during transitions
- Rollback procedures for failed migrations

---

*This analysis is based on the codebase as of October 2025. Regular reviews and updates are recommended as the application scales.*
