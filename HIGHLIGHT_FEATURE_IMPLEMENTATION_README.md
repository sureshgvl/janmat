# Highlight Feature Implementation Guide

## Overview
This document outlines the implementation of the Highlight feature for candidates, including analytics, plan management, and candidate dashboard. This is Phase 1 of the comprehensive analytics system.

## Table of Contents
1. [Database Schema](#database-schema)
2. [Model Classes](#model-classes)
3. [Service Layer](#service-layer)
4. [Admin Panel Changes](#admin-panel-changes)
5. [Candidate Dashboard](#candidate-dashboard)
6. [Highlight Plans](#highlight-plans)
7. [Implementation Phases](#implementation-phases)

## Database Schema

### Collections Structure

#### 1. `highlights` Collection
```javascript
{
  highlightId: "hl_123456789",
  candidateId: "cand_456",
  type: "highlight",

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

  // Admin
  approved: false,
  approvedBy: "admin_123",
  approvedAt: Timestamp,

  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### 2. `candidate_analytics` Collection
```javascript
// candidate_analytics/{candidateId}/highlights/summary
{
  candidateId: "cand_123",
  lastUpdated: Timestamp,

  // Overall highlight metrics
  totalHighlights: 5,
  activeHighlights: 3,
  totalViews: 15420,
  totalClicks: 892,
  averageEngagementRate: 5.8,

  // Performance by time
  weeklyGrowth: {
    views: 12.5, // percentage
    clicks: 8.3
  }
}

// candidate_analytics/{candidateId}/highlights/{highlightId}
{
  highlightId: "hl_123",
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

  lastUpdated: Timestamp
}
```

#### 3. `user_interactions` Collection
```javascript
// user_interactions/{highlightId}_{userId}
{
  highlightId: "hl_123",
  userId: "user_456",

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
    appVersion: "1.0.0"
  },

  location: {
    districtId: "pune",
    bodyId: "pune_m_cop",
    wardId: "ward_17"
  }
}
```

## Model Classes

### 1. Highlight Model
```dart
class Highlight {
  final String highlightId;
  final String candidateId;
  final String type;

  // Content
  final String? title;
  final String? message;
  final String? imageUrl;
  final String? callToAction;

  // Location
  final String districtId;
  final String bodyId;
  final String wardId;
  final String locationKey;

  // Campaign
  final String package;
  final int priority;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;

  // Analytics
  final int totalViews;
  final int totalClicks;
  final int uniqueViews;
  final int uniqueClicks;
  final int shares;
  final double engagementRate;

  // Admin
  final bool approved;
  final String? approvedBy;
  final DateTime? approvedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  Highlight({
    required this.highlightId,
    required this.candidateId,
    required this.type,
    this.title,
    this.message,
    this.imageUrl,
    this.callToAction,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
    required this.locationKey,
    required this.package,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.active,
    required this.totalViews,
    required this.totalClicks,
    required this.uniqueViews,
    required this.uniqueClicks,
    required this.shares,
    required this.engagementRate,
    required this.approved,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      highlightId: json['highlightId'] ?? '',
      candidateId: json['candidateId'] ?? '',
      type: json['type'] ?? 'highlight',
      title: json['title'],
      message: json['message'],
      imageUrl: json['imageUrl'],
      callToAction: json['callToAction'],
      districtId: json['districtId'] ?? '',
      bodyId: json['bodyId'] ?? '',
      wardId: json['wardId'] ?? '',
      locationKey: json['locationKey'] ?? '',
      package: json['package'] ?? '',
      priority: json['priority'] ?? 1,
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: json['active'] ?? false,
      totalViews: json['totalViews'] ?? 0,
      totalClicks: json['totalClicks'] ?? 0,
      uniqueViews: json['uniqueViews'] ?? 0,
      uniqueClicks: json['uniqueClicks'] ?? 0,
      shares: json['shares'] ?? 0,
      engagementRate: (json['engagementRate'] ?? 0).toDouble(),
      approved: json['approved'] ?? false,
      approvedBy: json['approvedBy'],
      approvedAt: (json['approvedAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highlightId': highlightId,
      'candidateId': candidateId,
      'type': type,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'callToAction': callToAction,
      'districtId': districtId,
      'bodyId': bodyId,
      'wardId': wardId,
      'locationKey': locationKey,
      'package': package,
      'priority': priority,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'active': active,
      'totalViews': totalViews,
      'totalClicks': totalClicks,
      'uniqueViews': uniqueViews,
      'uniqueClicks': uniqueClicks,
      'shares': shares,
      'engagementRate': engagementRate,
      'approved': approved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
```

### 2. Highlight Analytics Model
```dart
class HighlightAnalytics {
  final String highlightId;
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
  final DateTime lastUpdated;

  HighlightAnalytics({
    required this.highlightId,
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
    required this.lastUpdated,
  });

  factory HighlightAnalytics.fromJson(Map<String, dynamic> json) {
    return HighlightAnalytics(
      highlightId: json['highlightId'],
      title: json['title'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      location: LocationData.fromJson(json['location']),
      totalViews: json['totalViews'] ?? 0,
      uniqueViews: json['uniqueViews'] ?? 0,
      totalClicks: json['totalClicks'] ?? 0,
      uniqueClicks: json['uniqueClicks'] ?? 0,
      shares: json['shares'] ?? 0,
      engagementRate: (json['engagementRate'] ?? 0).toDouble(),
      dailyStats: _parseDailyStats(json['dailyStats'] ?? {}),
      lastUpdated: (json['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
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

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      views: json['views'] ?? 0,
      clicks: json['clicks'] ?? 0,
      shares: json['shares'] ?? 0,
    );
  }
}

class LocationData {
  final String districtId;
  final String bodyId;
  final String wardId;

  LocationData({
    required this.districtId,
    required this.bodyId,
    required this.wardId,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      districtId: json['districtId'] ?? '',
      bodyId: json['bodyId'] ?? '',
      wardId: json['wardId'] ?? '',
    );
  }
}
```

## Service Layer

### 1. Highlight Service
```dart
class HighlightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create highlight
  static Future<String?> createHighlight({
    required String candidateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required String package,
    required String title,
    required String message,
    required String imageUrl,
    String? callToAction,
    int priority = 1,
  }) async {
    try {
      final highlightId = 'hl_${DateTime.now().millisecondsSinceEpoch}';
      final locationKey = '${districtId}_${bodyId}_$wardId';

      final highlight = Highlight(
        highlightId: highlightId,
        candidateId: candidateId,
        type: 'highlight',
        title: title,
        message: message,
        imageUrl: imageUrl,
        callToAction: callToAction,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
        locationKey: locationKey,
        package: package,
        priority: priority,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 30)),
        active: false, // Not active until approved
        totalViews: 0,
        totalClicks: 0,
        uniqueViews: 0,
        uniqueClicks: 0,
        shares: 0,
        engagementRate: 0,
        approved: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('highlights').doc(highlightId).set(highlight.toJson());

      // Create analytics document
      await _createAnalyticsDocument(highlight);

      return highlightId;
    } catch (e) {
      debugPrint('Error creating highlight: $e');
      return null;
    }
  }

  // Get active highlights for location
  static Future<List<Highlight>> getActiveHighlights(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      final locationKey = '${districtId}_${bodyId}_$wardId';

      final snapshot = await _firestore
          .collection('highlights')
          .where('locationKey', isEqualTo: locationKey)
          .where('active', isEqualTo: true)
          .where('approved', isEqualTo: true)
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => Highlight.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching highlights: $e');
      return [];
    }
  }

  // Get highlights by candidate
  static Future<List<Highlight>> getHighlightsByCandidate(String candidateId) async {
    try {
      final snapshot = await _firestore
          .collection('highlights')
          .where('candidateId', isEqualTo: candidateId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Highlight.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching candidate highlights: $e');
      return [];
    }
  }

  // Track view
  static Future<void> trackView(String highlightId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Update highlight metrics
      final highlightRef = _firestore.collection('highlights').doc(highlightId);
      batch.update(highlightRef, {
        'totalViews': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user interaction
      final interactionRef = _firestore.collection('user_interactions').doc('${highlightId}_${userId}');
      batch.set(interactionRef, {
        'highlightId': highlightId,
        'userId': userId,
        'lastViewedAt': FieldValue.serverTimestamp(),
        'viewCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await batch.commit();

      // Update analytics
      await _updateHighlightAnalytics(highlightId);
    } catch (e) {
      debugPrint('Error tracking view: $e');
    }
  }

  // Track click
  static Future<void> trackClick(String highlightId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Update highlight metrics
      final highlightRef = _firestore.collection('highlights').doc(highlightId);
      batch.update(highlightRef, {
        'totalClicks': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user interaction
      final interactionRef = _firestore.collection('user_interactions').doc('${highlightId}_${userId}');
      batch.set(interactionRef, {
        'highlightId': highlightId,
        'userId': userId,
        'lastClickedAt': FieldValue.serverTimestamp(),
        'clickCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await batch.commit();

      // Update analytics
      await _updateHighlightAnalytics(highlightId);
    } catch (e) {
      debugPrint('Error tracking click: $e');
    }
  }

  // Admin approve highlight
  static Future<bool> approveHighlight(String highlightId, String adminId) async {
    try {
      await _firestore.collection('highlights').doc(highlightId).update({
        'approved': true,
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error approving highlight: $e');
      return false;
    }
  }

  // Get pending highlights for admin
  static Future<List<Highlight>> getPendingHighlights() async {
    try {
      final snapshot = await _firestore
          .collection('highlights')
          .where('approved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Highlight.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching pending highlights: $e');
      return [];
    }
  }

  // Create analytics document
  static Future<void> _createAnalyticsDocument(Highlight highlight) async {
    final analyticsData = {
      'highlightId': highlight.highlightId,
      'title': highlight.title ?? '',
      'createdAt': Timestamp.fromDate(highlight.createdAt),
      'location': {
        'districtId': highlight.districtId,
        'bodyId': highlight.bodyId,
        'wardId': highlight.wardId,
      },
      'totalViews': 0,
      'uniqueViews': 0,
      'totalClicks': 0,
      'uniqueClicks': 0,
      'shares': 0,
      'engagementRate': 0,
      'dailyStats': {},
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('candidate_analytics')
        .doc(highlight.candidateId)
        .collection('highlights')
        .doc(highlight.highlightId)
        .set(analyticsData);
  }

  // Update analytics
  static Future<void> _updateHighlightAnalytics(String highlightId) async {
    try {
      // Get highlight data
      final highlightDoc = await _firestore.collection('highlights').doc(highlightId).get();
      if (!highlightDoc.exists) return;

      final highlight = Highlight.fromJson(highlightDoc.data()!);

      // Calculate unique metrics
      final interactions = await _firestore
          .collection('user_interactions')
          .where('highlightId', isEqualTo: highlightId)
          .get();

      final uniqueViews = interactions.docs.where((doc) => doc.data()['viewCount'] > 0).length;
      final uniqueClicks = interactions.docs.where((doc) => doc.data()['clickCount'] > 0).length;

      final engagementRate = uniqueViews > 0 ? (uniqueClicks / uniqueViews) * 100 : 0;

      // Update analytics document
      await _firestore
          .collection('candidate_analytics')
          .doc(highlight.candidateId)
          .collection('highlights')
          .doc(highlightId)
          .update({
            'totalViews': highlight.totalViews,
            'uniqueViews': uniqueViews,
            'totalClicks': highlight.totalClicks,
            'uniqueClicks': uniqueClicks,
            'engagementRate': engagementRate,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error updating highlight analytics: $e');
    }
  }
}
```

## Admin Panel Changes

### 1. Highlight Management
```dart
class HighlightManagementScreen extends StatefulWidget {
  @override
  _HighlightManagementScreenState createState() => _HighlightManagementScreenState();
}

class _HighlightManagementScreenState extends State<HighlightManagementScreen> {
  List<Highlight> pendingHighlights = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPendingHighlights();
  }

  Future<void> loadPendingHighlights() async {
    setState(() => isLoading = true);
    try {
      pendingHighlights = await HighlightService.getPendingHighlights();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading highlights: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Highlight Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadPendingHighlights,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: pendingHighlights.length,
              itemBuilder: (context, index) {
                final highlight = pendingHighlights[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(highlight.imageUrl ?? ''),
                              radius: 30,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    highlight.title ?? 'No Title',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(highlight.candidateId),
                                  Text('${highlight.districtId} - ${highlight.wardId}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(highlight.message ?? ''),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _rejectHighlight(highlight.highlightId),
                              child: Text('Reject'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _approveHighlight(highlight.highlightId),
                              child: Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _approveHighlight(String highlightId) async {
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) return;

      final success = await HighlightService.approveHighlight(highlightId, adminId);
      if (success) {
        setState(() {
          pendingHighlights.removeWhere((h) => h.highlightId == highlightId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Highlight approved successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving highlight: $e')),
      );
    }
  }

  Future<void> _rejectHighlight(String highlightId) async {
    try {
      await FirebaseFirestore.instance.collection('highlights').doc(highlightId).delete();
      setState(() {
        pendingHighlights.removeWhere((h) => h.highlightId == highlightId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Highlight rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting highlight: $e')),
      );
    }
  }
}
```

### 2. Plan Management Updates
```dart
// Update plan model to include highlight features
class SubscriptionPlan {
  // ... existing fields

  // Highlight features
  final int maxHighlights;
  final bool highlightAnalytics;
  final String highlightPriority;

  SubscriptionPlan({
    // ... existing params
    required this.maxHighlights,
    required this.highlightAnalytics,
    required this.highlightPriority,
  });
}

// Add highlight plans
final highlightBasicPlan = SubscriptionPlan(
  planId: 'highlight_basic',
  name: 'Highlight Basic',
  type: PlanType.highlight,
  pricing: {
    'municipal_corporation': {30: 500, 90: 1200},
    'municipal_council': {30: 300, 90: 800},
  },
  maxHighlights: 1,
  highlightAnalytics: true,
  highlightPriority: 'normal',
);

final highlightPremiumPlan = SubscriptionPlan(
  planId: 'highlight_premium',
  name: 'Highlight Premium',
  type: PlanType.highlight,
  pricing: {
    'municipal_corporation': {30: 1500, 90: 3500},
    'municipal_council': {30: 1000, 90: 2500},
  },
  maxHighlights: 5,
  highlightAnalytics: true,
  highlightPriority: 'high',
);
```

## Candidate Dashboard

### 1. Highlight Analytics Screen
```dart
class HighlightAnalyticsScreen extends StatefulWidget {
  final String candidateId;

  const HighlightAnalyticsScreen({Key? key, required this.candidateId}) : super(key: key);

  @override
  _HighlightAnalyticsScreenState createState() => _HighlightAnalyticsScreenState();
}

class _HighlightAnalyticsScreenState extends State<HighlightAnalyticsScreen> {
  List<Highlight> highlights = [];
  Map<String, HighlightAnalytics> analytics = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHighlights();
  }

  Future<void> loadHighlights() async {
    setState(() => isLoading = true);
    try {
      highlights = await HighlightService.getHighlightsByCandidate(widget.candidateId);

      // Load analytics for each highlight
      for (final highlight in highlights) {
        final analyticDoc = await FirebaseFirestore.instance
            .collection('candidate_analytics')
            .doc(widget.candidateId)
            .collection('highlights')
            .doc(highlight.highlightId)
            .get();

        if (analyticDoc.exists) {
          analytics[highlight.highlightId] = HighlightAnalytics.fromJson(analyticDoc.data()!);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading highlights: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Highlights'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _createNewHighlight(context),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : highlights.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: highlights.length,
                  itemBuilder: (context, index) {
                    final highlight = highlights[index];
                    final analytic = analytics[highlight.highlightId];

                    return Card(
                      margin: EdgeInsets.all(8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(highlight.imageUrl ?? ''),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        highlight.title ?? 'Untitled',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        highlight.approved ? 'Approved' : 'Pending Approval',
                                        style: TextStyle(
                                          color: highlight.approved ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                      if (analytic != null) ...[
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _metricChip('${analytic.totalViews}', 'Views'),
                                            SizedBox(width: 8),
                                            _metricChip('${analytic.totalClicks}', 'Clicks'),
                                            SizedBox(width: 8),
                                            _metricChip('${analytic.engagementRate.toStringAsFixed(1)}%', 'Engagement'),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(highlight.message ?? ''),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _viewDetails(highlight),
                                  child: Text('View Details'),
                                ),
                                if (highlight.approved) ...[
                                  SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => _extendHighlight(highlight),
                                    child: Text('Extend'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No highlights yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Create your first highlight to get started'),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _createNewHighlight(context),
            child: Text('Create Highlight'),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String value, String label) {
    return Chip(
      label: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(label, style: TextStyle(fontSize: 10)),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void _createNewHighlight(BuildContext context) {
    // Navigate to highlight creation screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateHighlightScreen()),
    ).then((_) => loadHighlights());
  }

  void _viewDetails(Highlight highlight) {
    // Navigate to detailed analytics view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HighlightDetailScreen(
          highlight: highlight,
          analytics: analytics[highlight.highlightId],
        ),
      ),
    );
  }

  void _extendHighlight(Highlight highlight) {
    // Show extension options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Extend Highlight'),
        content: Text('Choose extension period:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _extendHighlightPeriod(highlight, 30),
            child: Text('30 Days'),
          ),
          ElevatedButton(
            onPressed: () => _extendHighlightPeriod(highlight, 90),
            child: Text('90 Days'),
          ),
        ],
      ),
    );
  }

  Future<void> _extendHighlightPeriod(Highlight highlight, int days) async {
    try {
      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlight.highlightId)
          .update({
            'endDate': Timestamp.fromDate(highlight.endDate.add(Duration(days: days))),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Highlight extended successfully')),
      );
      loadHighlights();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error extending highlight: $e')),
      );
    }
  }
}
```

### 2. Create Highlight Screen
```dart
class CreateHighlightScreen extends StatefulWidget {
  @override
  _CreateHighlightScreenState createState() => _CreateHighlightScreenState();
}

class _CreateHighlightScreenState extends State<CreateHighlightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String? _imageUrl;
  String? _callToAction;
  String _selectedPackage = 'basic';
  int _selectedValidityDays = 30;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Highlight')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Enter highlight title',
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Enter your campaign message',
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Message is required' : null,
            ),
            SizedBox(height: 16),
            // Image picker would go here
            ElevatedButton(
              onPressed: _pickImage,
              child: Text(_imageUrl != null ? 'Change Image' : 'Select Image'),
            ),
            if (_imageUrl != null) ...[
              SizedBox(height: 16),
              Image.network(_imageUrl!, height: 200, fit: BoxFit.cover),
            ],
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPackage,
              decoration: InputDecoration(labelText: 'Package'),
              items: [
                DropdownMenuItem(value: 'basic', child: Text('Basic')),
                DropdownMenuItem(value: 'premium', child: Text('Premium')),
              ],
              onChanged: (value) => setState(() => _selectedPackage = value!),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedValidityDays,
              decoration: InputDecoration(labelText: 'Validity Period'),
              items: [
                DropdownMenuItem(value: 30, child: Text('30 Days')),
                DropdownMenuItem(value: 90, child: Text('90 Days')),
              ],
              onChanged: (value) => setState(() => _selectedValidityDays = value!),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _createHighlight,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Create Highlight'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    // Implement image picker
    // For now, just set a placeholder
    setState(() => _imageUrl = 'https://via.placeholder.com/400x200');
  }

  Future<void> _createHighlight() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get candidate location from user data
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data()!;
      final electionAreas = userData['electionAreas'] as List<dynamic>;
      final primaryArea = electionAreas.first as Map<String, dynamic>;

      final highlightId = await HighlightService.createHighlight(
        candidateId: user.uid,
        districtId: userData['districtId'],
        bodyId: primaryArea['bodyId'],
        wardId: primaryArea['wardId'],
        package: _selectedPackage,
        title: _titleController.text,
        message: _messageController.text,
        imageUrl: _imageUrl!,
        callToAction: _callToAction,
      );

      if (highlightId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Highlight created successfully! Waiting for approval.')),
        );
        Navigator.pop(context);
      } else {
        throw 'Failed to create highlight';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating highlight: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
```

## Highlight Plans

### Plan Structure
```javascript
// Highlight Basic Plan
{
  planId: "highlight_basic",
  name: "Highlight Basic",
  type: "highlight",
  pricing: {
    municipal_corporation: {30: 500, 90: 1200},
    municipal_council: {30: 300, 90: 800},
    nagar_panchayat: {30: 200, 90: 500},
    zilla_parishad: {30: 400, 90: 1000},
    panchayat_samiti: {30: 250, 90: 600}
  },
  features: {
    maxHighlights: 1,
    analytics: true,
    priority: "normal",
    realTimeUpdates: false,
    exportReports: false
  }
}

// Highlight Premium Plan
{
  planId: "highlight_premium",
  name: "Highlight Premium",
  type: "highlight",
  pricing: {
    municipal_corporation: {30: 1500, 90: 3500},
    municipal_council: {30: 1000, 90: 2500},
    nagar_panchayat: {30: 600, 90: 1500},
    zilla_parishad: {30: 1200, 90: 3000},
    panchayat_samiti: {30: 750, 90: 1800}
  },
  features: {
    maxHighlights: 5,
    analytics: true,
    priority: "high",
    realTimeUpdates: true,
    exportReports: true,
    customBranding: true
  }
}
```

### Plan Validation
```dart
class HighlightPlanService {
  static Future<bool> canCreateHighlight(String candidateId) async {
    try {
      // Get user's active highlight subscription
      final subscription = await _getActiveHighlightSubscription(candidateId);
      if (subscription == null) return false;

      // Check current highlight count
      final currentHighlights = await HighlightService.getHighlightsByCandidate(candidateId);
      final activeHighlights = currentHighlights.where((h) => h.active).length;

      final plan = await PlanService.getPlanById(subscription.planId);
      return activeHighlights < (plan?.features['maxHighlights'] ?? 0);
    } catch (e) {
      debugPrint('Error checking highlight creation eligibility: $e');
      return false;
    }
  }

  static Future<UserSubscription?> _getActiveHighlightSubscription(String userId) async {
    final subscriptions = await MonetizationRepository().getUserSubscriptions(userId);
    return subscriptions.firstWhereOrNull(
      (sub) => sub.isActive && sub.planType == 'highlight',
    );
  }
}
```

## Implementation Phases

### Phase 1: Foundation (Week 1)
- ✅ Create `highlights` collection schema
- ✅ Implement `Highlight` and `HighlightAnalytics` models
- ✅ Create basic `HighlightService` with CRUD operations
- ✅ Add highlight approval workflow for admin

### Phase 2: Analytics (Week 2)
- ✅ Implement view/click tracking
- ✅ Create analytics aggregation
- ✅ Add real-time metrics updates
- ✅ Build basic analytics dashboard for candidates

### Phase 3: Plans & Monetization (Week 3)
- ✅ Create highlight plan types (Basic/Premium)
- ✅ Implement plan validation logic
- ✅ Add plan-based feature restrictions
- ✅ Update admin panel for plan management

### Phase 4: UI/UX Polish (Week 4)
- ✅ Complete candidate highlight creation flow
- ✅ Enhance analytics visualizations
- ✅ Add export functionality
- ✅ Implement push notifications for approvals

### Phase 5: Testing & Launch (Week 5)
- ✅ Comprehensive testing
- ✅ Performance optimization
- ✅ User acceptance testing
- ✅ Production deployment

## Key Features Delivered

1. **Highlight Creation**: Candidates can create highlights with images, titles, and messages
2. **Admin Approval**: All highlights require admin approval before going live
3. **Analytics Tracking**: Real-time tracking of views, clicks, and engagement
4. **Plan-Based Access**: Different limits and features based on subscription plans
5. **Candidate Dashboard**: Complete interface for managing highlights and viewing analytics
6. **Location Targeting**: Highlights are targeted to specific electoral areas

This focused implementation provides a solid foundation for the highlight feature, which can later be extended to include carousel and other content types.