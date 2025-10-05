# Candidate Analytics Implementation Guide

## Overview
This document outlines the complete implementation of comprehensive analytics for candidates to track performance across highlights, carousel, feed posts, and polls. Includes new plan types for highlights and carousel.

## Table of Contents
1. [Database Schema](#database-schema)
2. [Model Classes](#model-classes)
3. [Service Layer](#service-layer)
4. [Admin Panel Changes](#admin-panel-changes)
5. [Candidate Dashboard](#candidate-dashboard)
6. [Plan Modifications](#plan-modifications)
7. [Implementation Phases](#implementation-phases)

## Database Schema

### Collections Structure

#### 1. `highlights` Collection (Banner-style)
```javascript
{
  highlightId: "hl_123456789",
  candidateId: "cand_456",
  type: "highlight",
  placement: ["top_banner", "sidebar"],

  // Content
  title: "Campaign Message",
  message: "Vote for development",
  imageUrl: "https://...",
  callToAction: "Learn More",

  // Location
  districtId: "pune",
  bodyId: "pune_m_cop",
  wardId: "ward_17",
  locationKey: "pune_pune_m_cop_ward_17",

  // Campaign
  package: "gold",
  priority: 8,
  startDate: Timestamp,
  endDate: Timestamp,
  active: true,

  // Analytics
  totalViews: 0,
  totalClicks: 0,
  uniqueViews: 0,
  uniqueClicks: 0,
  shares: 0,
  engagementRate: 0,

  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### 2. `carousel` Collection (Carousel-style)
```javascript
{
  carouselId: "carousel_123456789",
  candidateId: "cand_456",
  type: "carousel",
  placement: ["carousel"],

  // Content
  title: "Election Campaign",
  imageUrl: "https://...",
  candidateName: "John Doe",
  party: "BJP",

  // Location (same as highlights)
  districtId: "pune",
  bodyId: "pune_m_cop",
  wardId: "ward_17",
  locationKey: "pune_pune_m_cop_ward_17",

  // Campaign (same as highlights)
  package: "platinum",
  priority: 10,
  startDate: Timestamp,
  endDate: Timestamp,
  active: true,

  // Analytics (same as highlights)
  totalViews: 0,
  totalClicks: 0,
  uniqueViews: 0,
  uniqueClicks: 0,
  shares: 0,
  engagementRate: 0,

  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### 3. `candidate_analytics` Collection
```javascript
// candidate_analytics/{candidateId}/content_analytics/{contentId}
{
  contentId: "hl_123", // or carousel_123, feed_123, poll_123
  contentType: "highlight", // highlight, carousel, feed, poll
  title: "Campaign Message",
  createdAt: Timestamp,

  location: {
    districtId: "pune",
    bodyId: "pune_m_cop",
    wardId: "ward_17"
  },

  // Metrics
  totalViews: 1250,
  uniqueViews: 980,
  totalClicks: 45,
  uniqueClicks: 38,
  shares: 12,
  engagementRate: 3.6,

  // Time series data
  dailyStats: {
    "2025-01-01": {views: 50, clicks: 5, shares: 1},
    "2025-01-02": {views: 75, clicks: 8, shares: 2}
  },

  // Demographics
  audience: {
    ageGroups: {"18-25": 120, "26-35": 200, "36-50": 180, "50+": 150},
    gender: {male: 320, female: 330},
    voterType: {firstTime: 150, regular: 500}
  },

  lastUpdated: Timestamp
}

// candidate_analytics/{candidateId}/summary
{
  candidateId: "cand_123",
  lastUpdated: Timestamp,

  // Overall metrics
  totalReach: 15420,
  totalEngagement: 892,
  averageEngagementRate: 5.8,

  // Content breakdown
  byType: {
    highlight: {views: 5200, clicks: 180, engagement: 3.5},
    carousel: {views: 3800, clicks: 120, engagement: 3.2},
    feed: {views: 4800, clicks: 95, engagement: 2.0},
    poll: {views: 1620, clicks: 497, engagement: 30.7}
  },

  // Geographic breakdown
  byLocation: {
    "pune_pune_m_cop_ward_17": {views: 2100, clicks: 75},
    "pune_pune_m_cop_ward_18": {views: 1800, clicks: 62}
  },

  // Trends
  weeklyGrowth: {
    reach: 12.5, // percentage
    engagement: 8.3
  }
}
```

#### 4. `user_interactions` Collection
```javascript
// user_interactions/{contentId}_{userId}
{
  contentId: "hl_123",
  userId: "user_456",
  contentType: "highlight",

  // Interaction history
  firstViewedAt: Timestamp,
  lastViewedAt: Timestamp,
  viewCount: 3,

  firstClickedAt: Timestamp,
  lastClickedAt: Timestamp,
  clickCount: 1,

  firstSharedAt: Timestamp,
  shareCount: 1,

  // Context
  deviceInfo: {
    platform: "android",
    appVersion: "1.0.0",
    deviceModel: "Samsung Galaxy"
  },

  location: {
    districtId: "pune",
    bodyId: "pune_m_cop",
    wardId: "ward_17"
  },

  userProfile: {
    age: 32,
    gender: "male",
    voterType: "regular"
  }
}
```

## Model Classes

### 1. Content Analytics Model
```dart
class ContentAnalytics {
  final String contentId;
  final String contentType;
  final String candidateId;
  final String title;
  final DateTime createdAt;
  final LocationData location;

  final int totalViews;
  final int uniqueViews;
  final int totalClicks;
  final int uniqueClicks;
  final int shares;
  final double engagementRate;

  final Map<String, DailyStats> dailyStats;
  final AudienceDemographics audience;

  ContentAnalytics({
    required this.contentId,
    required this.contentType,
    required this.candidateId,
    required this.title,
    required this.createdAt,
    required this.location,
    required this.totalViews,
    required this.uniqueViews,
    required this.totalClicks,
    required this.uniqueClicks,
    required this.shares,
    required this.engagementRate,
    required this.dailyStats,
    required this.audience,
  });

  factory ContentAnalytics.fromJson(Map<String, dynamic> json) {
    return ContentAnalytics(
      contentId: json['contentId'],
      contentType: json['contentType'],
      candidateId: json['candidateId'],
      title: json['title'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      location: LocationData.fromJson(json['location']),
      totalViews: json['totalViews'] ?? 0,
      uniqueViews: json['uniqueViews'] ?? 0,
      totalClicks: json['totalClicks'] ?? 0,
      uniqueClicks: json['uniqueClicks'] ?? 0,
      shares: json['shares'] ?? 0,
      engagementRate: (json['engagementRate'] ?? 0).toDouble(),
      dailyStats: _parseDailyStats(json['dailyStats']),
      audience: AudienceDemographics.fromJson(json['audience']),
    );
  }
}

class DailyStats {
  final int views;
  final int clicks;
  final int shares;

  DailyStats({
    required this.views,
    required this.clicks,
    required this.shares,
  });
}

class AudienceDemographics {
  final Map<String, int> ageGroups;
  final Map<String, int> gender;
  final Map<String, int> voterType;

  AudienceDemographics({
    required this.ageGroups,
    required this.gender,
    required this.voterType,
  });
}
```

### 2. Analytics Summary Model
```dart
class AnalyticsSummary {
  final String candidateId;
  final DateTime lastUpdated;

  final int totalReach;
  final int totalEngagement;
  final double averageEngagementRate;

  final Map<String, ContentTypeMetrics> byType;
  final Map<String, LocationMetrics> byLocation;
  final GrowthMetrics weeklyGrowth;

  AnalyticsSummary({
    required this.candidateId,
    required this.lastUpdated,
    required this.totalReach,
    required this.totalEngagement,
    required this.averageEngagementRate,
    required this.byType,
    required this.byLocation,
    required this.weeklyGrowth,
  });
}

class ContentTypeMetrics {
  final int views;
  final int clicks;
  final double engagement;

  ContentTypeMetrics({
    required this.views,
    required this.clicks,
    required this.engagement,
  });
}
```

## Service Layer

### 1. Analytics Service
```dart
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track view
  Future<void> trackView({
    required String contentId,
    required String contentType,
    required String candidateId,
    required String userId,
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> deviceInfo,
  }) async {
    final batch = _firestore.batch();

    // Update content analytics
    final contentRef = _firestore
        .collection('candidate_analytics')
        .doc(candidateId)
        .collection('content_analytics')
        .doc(contentId);

    batch.update(contentRef, {
      'totalViews': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Update user interaction
    final interactionRef = _firestore
        .collection('user_interactions')
        .doc('${contentId}_${userId}');

    final interactionData = {
      'contentId': contentId,
      'userId': userId,
      'contentType': contentType,
      'lastViewedAt': FieldValue.serverTimestamp(),
      'viewCount': FieldValue.increment(1),
      'deviceInfo': deviceInfo,
      'userProfile': userProfile,
    };

    batch.set(interactionRef, interactionData, SetOptions(merge: true));

    await batch.commit();

    // Update unique views count
    await _updateUniqueViews(contentId, candidateId);
  }

  // Track click
  Future<void> trackClick(String contentId, String candidateId, String userId) async {
    final batch = _firestore.batch();

    // Update content analytics
    final contentRef = _firestore
        .collection('candidate_analytics')
        .doc(candidateId)
        .collection('content_analytics')
        .doc(contentId);

    batch.update(contentRef, {
      'totalClicks': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Update user interaction
    final interactionRef = _firestore
        .collection('user_interactions')
        .doc('${contentId}_${userId}');

    batch.update(interactionRef, {
      'lastClickedAt': FieldValue.serverTimestamp(),
      'clickCount': FieldValue.increment(1),
    });

    await batch.commit();

    // Update unique clicks count
    await _updateUniqueClicks(contentId, candidateId);
  }

  // Get analytics for candidate
  Future<AnalyticsSummary> getCandidateAnalytics(String candidateId) async {
    final summaryDoc = await _firestore
        .collection('candidate_analytics')
        .doc(candidateId)
        .collection('summary')
        .doc('current')
        .get();

    if (!summaryDoc.exists) {
      return AnalyticsSummary.empty(candidateId);
    }

    return AnalyticsSummary.fromJson(summaryDoc.data()!);
  }

  // Get content analytics
  Future<List<ContentAnalytics>> getContentAnalytics(
    String candidateId,
    String contentType, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('candidate_analytics')
        .doc(candidateId)
        .collection('content_analytics')
        .where('contentType', isEqualTo: contentType)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ContentAnalytics.fromJson(doc.data()))
        .toList();
  }

  // Update unique counts (run as cloud function)
  Future<void> _updateUniqueViews(String contentId, String candidateId) async {
    final interactions = await _firestore
        .collection('user_interactions')
        .where('contentId', isEqualTo: contentId)
        .where('viewCount', isGreaterThan: 0)
        .get();

    final uniqueViews = interactions.docs.length;

    await _firestore
        .collection('candidate_analytics')
        .doc(candidateId)
        .collection('content_analytics')
        .doc(contentId)
        .update({'uniqueViews': uniqueViews});
  }
}
```

### 2. Highlight/Carousel Service Updates
```dart
class HighlightService {
  // Create highlight
  static Future<String?> createHighlight({
    required String candidateId,
    required String type, // 'highlight' or 'carousel'
    // ... other params
  }) async {
    final collection = type == 'highlight' ? 'highlights' : 'carousel';
    final id = '${type}_${DateTime.now().millisecondsSinceEpoch}';

    final data = {
      '${type}Id': id,
      'candidateId': candidateId,
      'type': type,
      // ... other fields
      'totalViews': 0,
      'totalClicks': 0,
      'uniqueViews': 0,
      'uniqueClicks': 0,
      'shares': 0,
      'engagementRate': 0,
    };

    await _firestore.collection(collection).doc(id).set(data);

    // Create analytics document
    await _createAnalyticsDocument(id, type, candidateId, data);

    return id;
  }

  static Future<void> _createAnalyticsDocument(
    String contentId,
    String contentType,
    String candidateId,
    Map<String, dynamic> contentData,
  ) async {
    final analyticsData = {
      'contentId': contentId,
      'contentType': contentType,
      'candidateId': candidateId,
      'title': contentData['title'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'location': {
        'districtId': contentData['districtId'],
        'bodyId': contentData['bodyId'],
        'wardId': contentData['wardId'],
      },
      'totalViews': 0,
      'uniqueViews': 0,
      'totalClicks': 0,
      'uniqueClicks': 0,
      'shares': 0,
      'engagementRate': 0,
      'dailyStats': {},
      'audience': {
        'ageGroups': {},
        'gender': {},
        'voterType': {},
      },
    };

    await _firestore
        .collection('candidate_analytics')
        .doc(candidateId)
        .collection('content_analytics')
        .doc(contentId)
        .set(analyticsData);
  }
}
```

## Admin Panel Changes

### 1. Plan Management
```dart
// Add new plan types
enum PlanType {
  voter,
  candidate,
  highlight,    // New
  carousel,     // New
}

// Update plan creation form
class PlanCreationForm extends StatefulWidget {
  @override
  _PlanCreationFormState createState() => _PlanCreationFormState();
}

class _PlanCreationFormState extends State<PlanCreationForm> {
  PlanType selectedType = PlanType.candidate;
  Map<String, Map<int, int>> pricing = {};

  // Add type-specific features
  Map<String, dynamic> features = {
    'maxHighlights': 0,
    'maxCarousels': 0,
    'analytics': true,
    'priority': 'normal',
  };

  void _addPricingTier() {
    // Add pricing based on plan type and election type
    switch (selectedType) {
      case PlanType.highlight:
        pricing['municipal_corporation'] = {30: 1000, 90: 2500};
        break;
      case PlanType.carousel:
        pricing['municipal_corporation'] = {30: 1500, 90: 3500};
        break;
      // ... other cases
    }
  }
}
```

### 2. Content Management
```dart
// Admin content approval interface
class ContentApprovalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Content Approval')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('highlights')
            .where('approved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: Image.network(data['imageUrl']),
                title: Text(data['title']),
                subtitle: Text('${data['candidateName']} - ${data['party']}'),
                trailing: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveContent(doc.id, 'highlights'),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectContent(doc.id, 'highlights'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

### 3. Analytics Dashboard (Admin)
```dart
class AdminAnalyticsDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Platform Analytics')),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          _metricCard('Total Highlights', '1,245'),
          _metricCard('Total Carousels', '892'),
          _metricCard('Active Campaigns', '156'),
          _metricCard('Total Revenue', '₹2,45,000'),
          _metricCard('Avg Engagement', '5.8%'),
          _metricCard('Top District', 'Pune'),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
```

## Candidate Dashboard

### 1. Analytics Screen Structure
```dart
class CandidateAnalyticsScreen extends StatefulWidget {
  @override
  _CandidateAnalyticsScreenState createState() => _CandidateAnalyticsScreenState();
}

class _CandidateAnalyticsScreenState extends State<CandidateAnalyticsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Campaign Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Highlights'),
            Tab(text: 'Carousel'),
            Tab(text: 'Feed'),
            Tab(text: 'Polls'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildHighlightsTab(),
          _buildCarouselTab(),
          _buildFeedTab(),
          _buildPollsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<AnalyticsSummary>(
      future: _analyticsService.getCandidateAnalytics(widget.candidateId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final summary = snapshot.data!;
        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Overview cards
            Row(
              children: [
                _metricCard('${summary.totalReach}', 'Total Reach'),
                _metricCard('${summary.totalEngagement}', 'Engagement'),
                _metricCard('${summary.averageEngagementRate}%', 'Avg Rate'),
              ],
            ),

            SizedBox(height: 24),

            // Content type breakdown
            Text('Performance by Content Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),

            ...summary.byType.entries.map((entry) {
              return _contentTypeCard(entry.key, entry.value);
            }),

            SizedBox(height: 24),

            // Geographic performance
            Text('Geographic Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),

            // Add map or chart here
          ],
        );
      },
    );
  }

  Widget _buildHighlightsTab() {
    return FutureBuilder<List<ContentAnalytics>>(
      future: _analyticsService.getContentAnalytics(
        widget.candidateId,
        'highlight',
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final analytics = snapshot.data![index];
            return _contentAnalyticsCard(analytics);
          },
        );
      },
    );
  }

  Widget _metricCard(String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contentTypeCard(String type, ContentTypeMetrics metrics) {
    return Card(
      child: ListTile(
        leading: _getContentTypeIcon(type),
        title: Text(_capitalize(type)),
        subtitle: Text('${metrics.views} views • ${metrics.clicks} clicks'),
        trailing: Text('${metrics.engagement}% engagement'),
      ),
    );
  }

  Widget _contentAnalyticsCard(ContentAnalytics analytics) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(analytics.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                _metricChip('${analytics.totalViews}', 'Views'),
                SizedBox(width: 8),
                _metricChip('${analytics.uniqueViews}', 'Unique'),
                SizedBox(width: 8),
                _metricChip('${analytics.totalClicks}', 'Clicks'),
                SizedBox(width: 8),
                _metricChip('${analytics.engagementRate}%', 'Engagement'),
              ],
            ),
            SizedBox(height: 16),
            // Add chart for daily stats
            Container(
              height: 100,
              child: LineChart(_buildDailyChart(analytics.dailyStats)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(String value, String label) {
    return Chip(
      label: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Icon _getContentTypeIcon(String type) {
    switch (type) {
      case 'highlight': return Icon(Icons.star, color: Colors.amber);
      case 'carousel': return Icon(Icons.view_carousel, color: Colors.blue);
      case 'feed': return Icon(Icons.article, color: Colors.green);
      case 'poll': return Icon(Icons.poll, color: Colors.purple);
      default: return Icon(Icons.help);
    }
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
```

### 2. Real-time Updates
```dart
class AnalyticsController extends GetxController {
  final AnalyticsService _analyticsService = AnalyticsService();

  var summary = Rxn<AnalyticsSummary>();
  var contentAnalytics = <ContentAnalytics>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadAnalytics();
    _setupRealTimeUpdates();
  }

  void loadAnalytics() async {
    isLoading.value = true;
    try {
      summary.value = await _analyticsService.getCandidateAnalytics(candidateId);
      contentAnalytics.value = await _analyticsService.getContentAnalytics(
        candidateId,
        'all',
        limit: 100,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _setupRealTimeUpdates() {
    // Listen to analytics changes
    FirebaseFirestore.instance
        .collection('candidate_analytics')
        .doc(candidateId)
        .collection('summary')
        .doc('current')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            summary.value = AnalyticsSummary.fromJson(snapshot.data()!);
          }
        });
  }
}
```

## Plan Modifications

### 1. New Plan Types
```dart
// Update plan model
class SubscriptionPlan {
  final String planId;
  final String name;
  final PlanType type; // voter, candidate, highlight, carousel
  final Map<String, Map<int, int>> pricing;
  final PlanFeatures features;

  // ... existing fields
}

// New plan features
class PlanFeatures {
  final int maxHighlights;
  final int maxCarousels;
  final bool analytics;
  final String priority;
  final bool realTimeUpdates;
  final bool demographicInsights;
  final bool exportReports;

  // ... existing features
}
```

### 2. Sample Plans
```javascript
// Highlight plans
{
  planId: "highlight_basic",
  name: "Highlight Basic",
  type: "highlight",
  pricing: {
    municipal_corporation: {30: 500, 90: 1200},
    municipal_council: {30: 300, 90: 800}
  },
  features: {
    maxHighlights: 1,
    analytics: true,
    priority: "normal",
    realTimeUpdates: false,
    demographicInsights: false,
    exportReports: false
  }
}

{
  planId: "highlight_premium",
  name: "Highlight Premium",
  type: "highlight",
  pricing: {
    municipal_corporation: {30: 1500, 90: 3500},
    municipal_council: {30: 1000, 90: 2500}
  },
  features: {
    maxHighlights: 5,
    analytics: true,
    priority: "high",
    realTimeUpdates: true,
    demographicInsights: true,
    exportReports: true
  }
}

// Carousel plans
{
  planId: "carousel_basic",
  name: "Carousel Basic",
  type: "carousel",
  pricing: {
    municipal_corporation: {30: 800, 90: 2000},
    municipal_council: {30: 500, 90: 1300}
  },
  features: {
    maxCarousels: 1,
    analytics: true,
    priority: "normal",
    realTimeUpdates: false,
    demographicInsights: false,
    exportReports: false
  }
}

{
  planId: "carousel_premium",
  name: "Carousel Premium",
  type: "carousel",
  pricing: {
    municipal_corporation: {30: 2000, 90: 5000},
    municipal_council: {30: 1500, 90: 3500}
  },
  features: {
    maxCarousels: 3,
    analytics: true,
    priority: "urgent",
    realTimeUpdates: true,
    demographicInsights: true,
    exportReports: true
  }
}
```

### 3. Plan Validation
```dart
class PlanValidationService {
  static Future<bool> canPurchasePlan(String userId, String planId) async {
    final plan = await PlanService.getPlanById(planId);
    if (plan == null) return false;

    switch (plan.type) {
      case PlanType.highlight:
        return await _canPurchaseHighlightPlan(userId, plan);
      case PlanType.carousel:
        return await _canPurchaseCarouselPlan(userId, plan);
      default:
        return true; // Other plans don't have limits
    }
  }

  static Future<bool> _canPurchaseHighlightPlan(String userId, SubscriptionPlan plan) async {
    final userHighlights = await HighlightService.getActiveHighlightsByCandidate(userId);
    return userHighlights.length < plan.features.maxHighlights;
  }

  static Future<bool> _canPurchaseCarouselPlan(String userId, SubscriptionPlan plan) async {
    final userCarousels = await CarouselService.getActiveCarouselsByCandidate(userId);
    return userCarousels.length < plan.features.maxCarousels;
  }
}
```

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
1. ✅ Create database collections and schemas
2. ✅ Implement basic analytics models
3. ✅ Create AnalyticsService with tracking methods
4. ✅ Update HighlightService for separate collections

### Phase 2: Core Analytics (Week 3-4)
1. ✅ Implement content analytics tracking
2. ✅ Create analytics summary aggregation
3. ✅ Build basic candidate analytics dashboard
4. ✅ Add real-time updates

### Phase 3: Advanced Features (Week 5-6)
1. ✅ Implement demographic tracking
2. ✅ Add geographic analytics
3. ✅ Create detailed content performance views
4. ✅ Implement export functionality

### Phase 4: Admin & Plans (Week 7-8)
1. ✅ Update admin panel for new plan types
2. ✅ Implement plan validation logic
3. ✅ Create content approval workflows
4. ✅ Add admin analytics dashboard

### Phase 5: Polish & Testing (Week 9-10)
1. ✅ Performance optimization
2. ✅ Comprehensive testing
3. ✅ User experience improvements
4. ✅ Documentation and training

## Migration Strategy

### Data Migration
```dart
class DataMigrationService {
  static Future<void> migrateExistingHighlights() async {
    // Migrate existing highlights to new collections
    final existingHighlights = await FirebaseFirestore.instance
        .collection('highlights')
        .get();

    for (final doc in existingHighlights.docs) {
      final data = doc.data();

      // Determine type based on placement
      final type = _determineContentType(data['placement']);

      // Create new document in appropriate collection
      final newCollection = type == 'highlight' ? 'highlights' : 'carousel';
      await FirebaseFirestore.instance
          .collection(newCollection)
          .doc(doc.id)
          .set(data);

      // Create analytics document
      await _createAnalyticsForMigratedContent(doc.id, type, data);
    }
  }

  static String _determineContentType(List<dynamic> placement) {
    if (placement.contains('carousel')) return 'carousel';
    return 'highlight';
  }
}
```

## Security Rules

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Analytics - candidates can only read their own analytics
    match /candidate_analytics/{candidateId}/{document=**} {
      allow read: if request.auth != null && request.auth.uid == candidateId;
      allow write: if false; // Only cloud functions can write
    }

    // User interactions - users can only see their own interactions
    match /user_interactions/{interactionId} {
      allow read, write: if request.auth != null &&
        interactionId.split('_')[1] == request.auth.uid;
    }

    // Highlights/Carousel - public read, restricted write
    match /highlights/{highlightId} {
      allow read: if true;
      allow write: if request.auth != null &&
        exists(/databases/$(database)/documents/candidates/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/candidates/$(request.auth.uid)).data.premium == true;
    }

    match /carousel/{carouselId} {
      allow read: if true;
      allow write: if request.auth != null &&
        exists(/databases/$(database)/documents/candidates/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/candidates/$(request.auth.uid)).data.premium == true;
    }
  }
}
```

## Cloud Functions

### Analytics Aggregation
```typescript
// functions/src/analytics.ts
export const aggregateAnalytics = functions.firestore
  .document('user_interactions/{interactionId}')
  .onWrite(async (change, context) => {
    const interaction = change.after.data();
    if (!interaction) return;

    const { contentId, candidateId, contentType } = interaction;

    // Update content analytics
    const contentRef = db
      .collection('candidate_analytics')
      .doc(candidateId)
      .collection('content_analytics')
      .doc(contentId);

    // Calculate unique metrics
    const uniqueViews = await calculateUniqueViews(contentId);
    const uniqueClicks = await calculateUniqueClicks(contentId);

    await contentRef.update({
      uniqueViews,
      uniqueClicks,
      engagementRate: (uniqueClicks / uniqueViews) * 100,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update summary
    await updateCandidateSummary(candidateId);
  });
```

This comprehensive implementation provides candidates with detailed analytics across all content types, with proper separation of highlights and carousel functionality, and new plan types to monetize these features.