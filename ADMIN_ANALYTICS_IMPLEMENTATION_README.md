# Admin Analytics Implementation Guide

This comprehensive guide provides step-by-step instructions for implementing the analytics system that tracks total views and unique views across all 4 home screen sections (Platinum Banner, Highlight Carousel, Push Feed, and Normal Feed).

## 📊 **System Overview**

The analytics system tracks:
- **Total Views**: Every time a section is displayed
- **Unique Views**: Unique users who viewed the content
- **Click Tracking**: User interactions with content
- **Demographic Data**: Location and device information
- **Performance Metrics**: CTR, engagement rates, ROI calculations

## 🗄️ **Database Collections Structure**

### **1. Section Views Collection**
```javascript
// Collection: section_views
// Documents are auto-generated with unique IDs

{
  "viewId": "auto-generated", // Document ID
  "sectionType": "banner|carousel|push_feed|normal_feed",
  "contentId": "highlightId|updateId|postId",
  "userId": "viewer_user_id",
  "candidateId": "content_owner_id",
  "timestamp": "2024-12-20T10:00:00Z", // Firestore timestamp
  "deviceInfo": {
    "platform": "android|ios|web",
    "appVersion": "1.0.0"
  },
  "location": {
    "districtId": "Pune",
    "bodyId": "pune_city",
    "wardId": "ward_pune_1"
  }
}
```

### **2. Daily Analytics Aggregation**
```javascript
// Collection: analytics_daily
// Document ID format: YYYY-MM-DD (e.g., "2024-12-20")

{
  "date": "2024-12-20",
  "sections": {
    "banner": {
      "totalViews": 1250,
      "uniqueUsers": ["user1", "user2", "user3"], // Array of user IDs
      "contentIds": ["hl_123", "hl_456"] // Array of content IDs
    },
    "carousel": {
      "totalViews": 2100,
      "uniqueUsers": ["user4", "user5", "user6"],
      "contentIds": ["hl_789", "hl_101"]
    },
    "push_feed": {
      "totalViews": 800,
      "uniqueUsers": ["user7", "user8"],
      "contentIds": ["update_123", "update_456"]
    },
    "normal_feed": {
      "totalViews": 3200,
      "uniqueUsers": ["user9", "user10", "user11"],
      "contentIds": ["post_123", "post_456"]
    }
  },
  "totalViews": 7350, // Sum of all section views
  "totalUniqueUsers": 2800, // Unique users across all sections
  "processedAt": "2024-12-21T00:00:00Z" // When aggregation was run
}
```

### **3. Content Performance Collection**
```javascript
// Collection: content_performance
// Document ID: contentId (e.g., "hl_123", "update_456", "post_789")

{
  "contentId": "hl_123",
  "contentType": "highlight|update|post",
  "candidateId": "candidate_user_id",
  "sectionType": "banner|carousel|push_feed|normal_feed",
  "totalViews": 1250,
  "uniqueViews": 890,
  "clicks": 45,
  "clickThroughRate": 3.6, // (clicks/totalViews) * 100
  "dateRange": {
    "start": "2024-12-20T00:00:00Z",
    "end": "2024-12-31T23:59:59Z"
  },
  "demographics": {
    "districts": {
      "Pune": 450,
      "Mumbai": 320,
      "Delhi": 120
    },
    "platforms": {
      "android": 780,
      "ios": 110
    }
  },
  "lastUpdated": "2024-12-20T15:30:00Z"
}
```

## 🚀 **Implementation Steps**

### **Phase 1: Mobile App Tracking (Already Implemented)**

The mobile app has been updated with analytics tracking:

#### **✅ Banner Section Tracking**
- **File**: `lib/widgets/highlight_banner.dart`
- **Tracks**: Views when banner is tapped
- **Data**: User ID, candidate ID, location, device info

#### **✅ Carousel Section Tracking**
- **File**: `lib/widgets/highlight_card.dart`
- **Tracks**: Views when carousel item is displayed
- **Data**: User ID, highlight ID, candidate ID

#### **✅ Push Feed Tracking**
- **File**: `lib/features/home/screens/home_body.dart`
- **Tracks**: Views when sponsored updates are displayed
- **Data**: User ID, update IDs, location

#### **✅ Normal Feed Tracking**
- **File**: `lib/features/home/screens/home_body.dart`
- **Tracks**: Views when community posts are displayed
- **Data**: User ID, post IDs, location

### **Phase 2: Firebase Cloud Functions**

#### **1. Daily Analytics Aggregation Function**
```javascript
// functions/src/analytics/aggregateDailyAnalytics.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const aggregateDailyAnalytics = functions.pubsub
  .schedule('0 0 * * *') // Daily at midnight IST
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {

    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const dateString = yesterday.toISOString().split('T')[0];

    try {
      // Get all views from yesterday
      const viewsSnapshot = await admin.firestore()
        .collection('section_views')
        .where('timestamp', '>=', new Date(dateString + 'T00:00:00Z'))
        .where('timestamp', '<', new Date(dateString + 'T23:59:59Z'))
        .get();

      const analytics = {
        banner: { totalViews: 0, uniqueUsers: new Set(), contentIds: new Set() },
        carousel: { totalViews: 0, uniqueUsers: new Set(), contentIds: new Set() },
        push_feed: { totalViews: 0, uniqueUsers: new Set(), contentIds: new Set() },
        normal_feed: { totalViews: 0, uniqueUsers: new Set(), contentIds: new Set() }
      };

      viewsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const section = data.sectionType;

        if (analytics[section]) {
          analytics[section].totalViews++;
          analytics[section].uniqueUsers.add(data.userId);
          analytics[section].contentIds.add(data.contentId);
        }
      });

      // Convert Sets to arrays
      Object.keys(analytics).forEach(section => {
        analytics[section].uniqueUsers = Array.from(analytics[section].uniqueUsers);
        analytics[section].contentIds = Array.from(analytics[section].contentIds);
      });

      // Calculate totals
      const totalViews = Object.values(analytics).reduce((sum, section) =>
        sum + section.totalViews, 0);
      const allUniqueUsers = new Set();
      Object.values(analytics).forEach(section => {
        section.uniqueUsers.forEach(userId => allUniqueUsers.add(userId));
      });

      // Save daily analytics
      await admin.firestore()
        .collection('analytics_daily')
        .doc(dateString)
        .set({
          date: dateString,
          sections: analytics,
          totalViews,
          totalUniqueUsers: allUniqueUsers.size,
          processedAt: admin.firestore.FieldValue.serverTimestamp()
        });

      console.log(`✅ Daily analytics aggregated for ${dateString}`);
      return null;

    } catch (error) {
      console.error('❌ Error aggregating daily analytics:', error);
      throw error;
    }
  });
```

#### **2. Content Performance Function**
```javascript
// functions/src/analytics/updateContentPerformance.ts

export const updateContentPerformance = functions.firestore
  .document('section_views/{viewId}')
  .onCreate(async (snap, context) => {

    const viewData = snap.data();
    const { contentId, candidateId, sectionType } = viewData;

    if (!contentId || !candidateId) return;

    const performanceRef = admin.firestore()
      .collection('content_performance')
      .doc(contentId);

    try {
      // Update or create performance document
      await performanceRef.set({
        contentId,
        contentType: sectionType === 'banner' || sectionType === 'carousel' ? 'highlight' :
                    sectionType === 'push_feed' ? 'update' : 'post',
        candidateId,
        sectionType,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // Increment view counters
      await performanceRef.update({
        totalViews: admin.firestore.FieldValue.increment(1),
        [`uniqueViewers.${viewData.userId}`]: true // Use map for unique tracking
      });

    } catch (error) {
      console.error('❌ Error updating content performance:', error);
    }
  });
```

### **Phase 3: Admin Dashboard Implementation**

#### **1. Analytics Dashboard Component**
```javascript
// components/admin/AnalyticsDashboard.jsx

import React, { useState, useEffect } from 'react';
import { db } from '../../firebase/config';

const AnalyticsDashboard = () => {
  const [analytics, setAnalytics] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadAnalytics();
  }, []);

  const loadAnalytics = async () => {
    try {
      // Get last 30 days of analytics
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const snapshot = await db.collection('analytics_daily')
        .where('date', '>=', thirtyDaysAgo.toISOString().split('T')[0])
        .orderBy('date', 'desc')
        .get();

      const analyticsData = {};
      snapshot.docs.forEach(doc => {
        analyticsData[doc.id] = doc.data();
      });

      setAnalytics(analyticsData);
    } catch (error) {
      console.error('Error loading analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  const calculateTotals = () => {
    const totals = {
      totalViews: 0,
      totalUniqueUsers: 0,
      sections: {
        banner: { views: 0, unique: 0 },
        carousel: { views: 0, unique: 0 },
        push_feed: { views: 0, unique: 0 },
        normal_feed: { views: 0, unique: 0 }
      }
    };

    Object.values(analytics).forEach(day => {
      totals.totalViews += day.totalViews || 0;
      totals.totalUniqueUsers += day.totalUniqueUsers || 0;

      Object.keys(day.sections || {}).forEach(section => {
        totals.sections[section].views += day.sections[section].totalViews || 0;
        totals.sections[section].unique += day.sections[section].uniqueUsers?.length || 0;
      });
    });

    return totals;
  };

  if (loading) return <div>Loading analytics...</div>;

  const totals = calculateTotals();

  return (
    <div className="analytics-dashboard">
      <h1>Analytics Dashboard</h1>

      {/* Overall Metrics */}
      <div className="metrics-grid">
        <div className="metric-card">
          <h3>Total Views</h3>
          <span className="metric-value">{totals.totalViews.toLocaleString()}</span>
        </div>
        <div className="metric-card">
          <h3>Unique Users</h3>
          <span className="metric-value">{totals.totalUniqueUsers.toLocaleString()}</span>
        </div>
        <div className="metric-card">
          <h3>Avg Views/User</h3>
          <span className="metric-value">
            {totals.totalUniqueUsers > 0
              ? (totals.totalViews / totals.totalUniqueUsers).toFixed(1)
              : '0'
            }
          </span>
        </div>
      </div>

      {/* Section Breakdown */}
      <div className="section-breakdown">
        <h2>Section Performance</h2>
        {Object.entries(totals.sections).map(([section, data]) => (
          <div key={section} className="section-card">
            <h3>{section.replace('_', ' ').toUpperCase()}</h3>
            <div className="section-metrics">
              <span>Views: {data.views.toLocaleString()}</span>
              <span>Unique: {data.unique.toLocaleString()}</span>
              <span>CTR: {data.views > 0 ? ((data.unique / data.views) * 100).toFixed(1) : 0}%</span>
            </div>
          </div>
        ))}
      </div>

      {/* Charts would go here */}
      <div className="charts-container">
        {/* Implement charts using Chart.js or similar */}
      </div>
    </div>
  );
};

export default AnalyticsDashboard;
```

#### **2. Candidate Performance Report**
```javascript
// components/admin/CandidatePerformanceReport.jsx

const CandidatePerformanceReport = ({ candidateId }) => {
  const [performance, setPerformance] = useState({});

  useEffect(() => {
    loadCandidatePerformance();
  }, [candidateId]);

  const loadCandidatePerformance = async () => {
    try {
      const snapshot = await db.collection('content_performance')
        .where('candidateId', '==', candidateId)
        .get();

      const performanceData = {};
      snapshot.docs.forEach(doc => {
        const data = doc.data();
        performanceData[data.contentId] = data;
      });

      setPerformance(performanceData);
    } catch (error) {
      console.error('Error loading candidate performance:', error);
    }
  };

  const calculateROI = () => {
    const totalViews = Object.values(performance)
      .reduce((sum, item) => sum + (item.totalViews || 0), 0);

    const totalClicks = Object.values(performance)
      .reduce((sum, item) => sum + (item.clicks || 0), 0);

    // Assuming $0.001 per view value
    const estimatedValue = totalViews * 0.001;
    const ctr = totalViews > 0 ? (totalClicks / totalViews) * 100 : 0;

    return { totalViews, totalClicks, estimatedValue, ctr };
  };

  const roi = calculateROI();

  return (
    <div className="candidate-performance">
      <h2>Candidate Performance Report</h2>

      <div className="roi-summary">
        <div className="roi-card">
          <h3>Total Views</h3>
          <span>{roi.totalViews.toLocaleString()}</span>
        </div>
        <div className="roi-card">
          <h3>Clicks</h3>
          <span>{roi.totalClicks.toLocaleString()}</span>
        </div>
        <div className="roi-card">
          <h3>Click-through Rate</h3>
          <span>{roi.ctr.toFixed(2)}%</span>
        </div>
        <div className="roi-card">
          <h3>Estimated Value</h3>
          <span>${roi.estimatedValue.toFixed(2)}</span>
        </div>
      </div>

      {/* Content performance table */}
      <div className="content-table">
        <table>
          <thead>
            <tr>
              <th>Content ID</th>
              <th>Type</th>
              <th>Views</th>
              <th>Clicks</th>
              <th>CTR</th>
            </tr>
          </thead>
          <tbody>
            {Object.entries(performance).map(([contentId, data]) => (
              <tr key={contentId}>
                <td>{contentId}</td>
                <td>{data.contentType}</td>
                <td>{data.totalViews || 0}</td>
                <td>{data.clicks || 0}</td>
                <td>{data.totalViews > 0 ? ((data.clicks || 0) / data.totalViews * 100).toFixed(1) : 0}%</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
```

### **Phase 4: Real-time Monitoring**

#### **1. Real-time Analytics Updates**
```javascript
// components/admin/RealTimeAnalytics.jsx

const RealTimeAnalytics = () => {
  const [realtimeData, setRealtimeData] = useState({});

  useEffect(() => {
    // Listen to real-time updates
    const unsubscribe = db.collection('section_views')
      .where('timestamp', '>', new Date(Date.now() - 3600000)) // Last hour
      .onSnapshot(snapshot => {
        const data = {};
        snapshot.docs.forEach(doc => {
          const view = doc.data();
          const section = view.sectionType;

          if (!data[section]) {
            data[section] = { views: 0, uniqueUsers: new Set() };
          }

          data[section].views++;
          data[section].uniqueUsers.add(view.userId);
        });

        // Convert Sets to counts
        Object.keys(data).forEach(section => {
          data[section].uniqueUsers = data[section].uniqueUsers.size;
        });

        setRealtimeData(data);
      });

    return () => unsubscribe();
  }, []);

  return (
    <div className="realtime-analytics">
      <h2>Real-time Analytics (Last Hour)</h2>
      {Object.entries(realtimeData).map(([section, data]) => (
        <div key={section} className="realtime-card">
          <h3>{section.replace('_', ' ').toUpperCase()}</h3>
          <div className="metrics">
            <span>Views: {data.views}</span>
            <span>Unique: {data.uniqueUsers}</span>
          </div>
        </div>
      ))}
    </div>
  );
};
```

## 📈 **Advanced Features**

### **A/B Testing Framework**
```javascript
// Test different highlight placements
const ABTestManager = {
  assignVariant: (userId, testName) => {
    const hash = simpleHash(userId + testName);
    return hash % 2 === 0 ? 'variant_a' : 'variant_b';
  },

  trackConversion: (userId, testName, variant, converted) => {
    // Track conversion in analytics
  }
};
```

### **Predictive Analytics**
```javascript
// Machine learning predictions for content performance
const PredictiveAnalytics = {
  predictViews: (contentFeatures) => {
    // Use historical data to predict future performance
    return predictedViews;
  },

  recommendPlacement: (contentId) => {
    // Recommend best placement based on content type
    return recommendedSection;
  }
};
```

## 🔧 **Deployment Checklist**

### **Mobile App:**
- [x] Analytics tracking implemented
- [x] Firebase imports added
- [x] Error handling in place
- [ ] Test analytics data flow

### **Firebase Functions:**
- [ ] Deploy aggregation function
- [ ] Deploy performance tracking function
- [ ] Set up scheduled triggers
- [ ] Test function execution

### **Admin Dashboard:**
- [ ] Create analytics components
- [ ] Implement data visualization
- [ ] Add real-time updates
- [ ] Test with sample data

### **Monitoring & Maintenance:**
- [ ] Set up error monitoring
- [ ] Configure alerts for anomalies
- [ ] Plan data retention policies
- [ ] Schedule regular backups

## 🎯 **Expected Outcomes**

### **Business Metrics:**
- **View Tracking Accuracy**: 95%+ of user interactions captured
- **Real-time Latency**: < 5 seconds for dashboard updates
- **Data Processing**: Daily aggregation completes within 1 hour
- **Storage Efficiency**: Optimized data structure for cost control

### **User Experience:**
- **Dashboard Load Time**: < 3 seconds
- **Real-time Updates**: Live data with < 10 second delay
- **Mobile Performance**: No impact on app responsiveness
- **Data Accuracy**: 99%+ accuracy in reporting

This comprehensive analytics system will provide candidates with clear visibility into their premium feature performance, enabling data-driven decisions and demonstrating the value of their investment.