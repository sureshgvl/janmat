# 🚀 Highlight System Firebase Setup Instructions

## 📋 **Admin Setup Summary**

**Project:** Janmat App - Highlight System
**Firebase Project ID:** janmat-8e831
**Setup Time:** 30-45 minutes
**Priority:** High (Required for highlight feature)

---

## 🎯 **What You Need to Create**

### **1. Collections (5 required)**
```
✅ plans
✅ user_subscriptions
✅ highlights
✅ pushFeed
✅ payments
```

### **2. Composite Indexes (3 required)**
```
✅ highlights: (wardId, active, placement, priority, __name__)
✅ highlights: (wardId, active, lastShown, priority, __name__)
✅ pushFeed: (wardId, timestamp, __name__)
```

### **3. Security Rules (1 update)**
```
✅ Update Firestore security rules
```

---

## 📝 **Step-by-Step Instructions**

### **Step 1: Access Firebase Console**
```
URL: https://console.firebase.google.com/
Project: janmat-8e831
Go to: Firestore Database
```

### **Step 2: Create Collections**

**Create each collection with "+ Start collection":**

1. **Collection:** `plans`
   - **Purpose:** Stores subscription plan definitions
   - **Documents to add:** 4 plan documents (free_plan, basic_plan, gold_plan, platinum_plan)

2. **Collection:** `user_subscriptions`
   - **Purpose:** Tracks candidate subscriptions
   - **Documents:** Will be created automatically when users subscribe

3. **Collection:** `highlights`
   - **Purpose:** Stores highlight advertisements
   - **Documents:** Will be created by candidates purchasing highlights

4. **Collection:** `pushFeed`
   - **Purpose:** Stores sponsored push notifications
   - **Documents:** Will be created for sponsored content

5. **Collection:** `payments`
   - **Purpose:** Tracks payment transactions
   - **Documents:** Will be created during payment process

### **Step 3: Add Plan Documents**

**In `plans` collection, create these 4 documents:**

#### **Document 1: free_plan**
```json
{
  "planId": "free_plan",
  "name": "Free Plan",
  "type": "candidate",
  "price": 0,
  "limit": null,
  "isActive": true,
  "createdAt": "2025-01-01T00:00:00.000Z",
  "features": [
    {"name": "Basic Profile", "description": "Name, party, symbol, photo", "enabled": true},
    {"name": "Basic Info", "description": "Age, gender, education, profession", "enabled": true},
    {"name": "Basic Contact", "description": "Phone and email only", "enabled": true},
    {"name": "Short Bio", "description": "Short biography text", "enabled": true},
    {"name": "Limited Manifesto", "description": "3 promises text only", "enabled": true},
    {"name": "Limited Media", "description": "2 photos, no videos", "enabled": true},
    {"name": "Follower Count", "description": "Show followers/following", "enabled": true}
  ]
}
```

#### **Document 2: basic_plan**
```json
{
  "planId": "basic_plan",
  "name": "Basic Package",
  "type": "candidate",
  "price": 5000,
  "limit": 1000,
  "isActive": true,
  "createdAt": "2025-01-01T00:00:00.000Z",
  "features": [
    {"name": "All Free Features", "description": "Includes all free plan features", "enabled": true},
    {"name": "Full Manifesto", "description": "Title + 5 promises + PDF upload", "enabled": true},
    {"name": "Cover Photo", "description": "Premium cover photo", "enabled": true},
    {"name": "Enhanced Media", "description": "5 photos + 1 video", "enabled": true},
    {"name": "Limited Achievements", "description": "Up to 3 achievements", "enabled": true},
    {"name": "Extended Contact", "description": "Social links + office address", "enabled": true},
    {"name": "Limited Events", "description": "Up to 2 events, no RSVP", "enabled": true},
    {"name": "Basic Analytics", "description": "Profile views count", "enabled": true}
  ]
}
```

#### **Document 3: gold_plan**
```json
{
  "planId": "gold_plan",
  "name": "Gold Package",
  "type": "candidate",
  "price": 25000,
  "limit": null,
  "isActive": true,
  "createdAt": "2025-01-01T00:00:00.000Z",
  "features": [
    {"name": "All Basic Features", "description": "Includes all basic plan features", "enabled": true},
    {"name": "Carousel Highlight", "description": "Ward-level candidate carousel", "enabled": true},
    {"name": "Video Manifesto", "description": "Video upload for manifesto", "enabled": true},
    {"name": "Unlimited Media", "description": "50 photos + 10 videos", "enabled": true},
    {"name": "Unlimited Achievements", "description": "Unlimited achievement entries", "enabled": true},
    {"name": "Full Events", "description": "Events with RSVP functionality", "enabled": true},
    {"name": "Push Notifications", "description": "2 push notifications per week", "enabled": true},
    {"name": "Highlight Feature", "description": "1 active highlight", "enabled": true},
    {"name": "Advanced Analytics", "description": "Views, follower growth, top content", "enabled": true}
  ]
}
```

#### **Document 4: platinum_plan**
```json
{
  "planId": "platinum_plan",
  "name": "Platinum Package",
  "type": "candidate",
  "price": 100000,
  "limit": null,
  "isActive": true,
  "createdAt": "2025-01-01T00:00:00.000Z",
  "features": [
    {"name": "All Gold Features", "description": "Includes all gold plan features", "enabled": true},
    {"name": "Exclusive Banner", "description": "Home screen top banner", "enabled": true},
    {"name": "Unlimited Everything", "description": "All media, events, notifications", "enabled": true},
    {"name": "Multiple Highlights", "description": "Multiple highlights with priority", "enabled": true},
    {"name": "Full Analytics Dashboard", "description": "Complete analytics with demographics", "enabled": true},
    {"name": "Chat Priority", "description": "Priority messaging", "enabled": true},
    {"name": "Premium Badge", "description": "Verified candidate badge", "enabled": true},
    {"name": "Admin Support", "description": "Dedicated admin support", "enabled": true}
  ]
}
```

### **Step 4: Update Security Rules**

**Go to:** Firestore Database → Rules tab

**Replace with these rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Plans collection - public read, admin write
    match /plans/{planId} {
      allow read: if true; // Public read for all users
      allow write: if request.auth != null &&
        (request.auth.uid == '8BYU2by0IOOBVAodl5sFwuqOm4Z2' ||
         exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }

    // User subscriptions - users can read/write their own, admin can read/write all
    match /user_subscriptions/{subscriptionId} {
      allow read: if request.auth != null &&
        (request.auth.uid == resource.data.userId ||
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
      allow write: if request.auth != null &&
        (request.auth.uid == resource.data.userId ||
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
    }

    // HIGHLIGHTS COLLECTION - NEW!
    match /highlights/{highlightId} {
      allow read: if true; // Public read for voters to see highlights
      allow write: if request.auth != null; // Authenticated users can create
      allow update: if request.auth != null &&
        (request.auth.uid == resource.data.candidateId ||
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
    }

    // PUSH FEED COLLECTION - NEW!
    match /pushFeed/{feedId} {
      allow read: if true; // Public read for voters
      allow write: if request.auth != null; // Authenticated users can create
      allow update: if request.auth != null &&
        (request.auth.uid == resource.data.candidateId ||
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
    }

    // PAYMENTS COLLECTION - NEW!
    match /payments/{paymentId} {
      allow read: if request.auth != null &&
        (request.auth.uid == resource.data.candidateId ||
         (exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'));
      allow write: if request.auth != null &&
        request.auth.uid == resource.data.candidateId;
    }

    // Cities, wards, candidates - existing rules
    match /cities/{cityId} {
      allow read: if true; // Public read for voter visibility
      allow write: if request.auth != null;
    }

    match /cities/{cityId}/wards/{wardId} {
      allow read: if true;
      allow write: if request.auth != null;
    }

    match /cities/{cityId}/wards/{wardId}/candidates/{candidateId} {
      allow read: if true; // Public read for voter visibility
      allow write: if request.auth != null && request.auth.uid == candidateId;
    }

    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null &&
        (request.auth.token.admin == true || request.auth.token.role == 'admin');
    }

    // Chat functionality
    match /chats/{roomId} {
      allow read, write: if request.auth != null;
    }

    match /chats/{roomId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }

    // User quotas
    match /user_quotas/{userId} {
      allow read, write: if request.auth != null;
    }

    // Admin collections (districts, etc.)
    match /districts/{districtId} {
      allow read, write: if request.auth != null &&
        (request.auth.token.admin == true || request.auth.token.role == 'admin');
    }

    match /districts/{districtId}/bodies/{bodyId} {
      allow read, write: if request.auth != null &&
        (request.auth.token.admin == true || request.auth.token.role == 'admin');
    }

    match /districts/{districtId}/bodies/{bodyId}/wards/{wardId} {
      allow read, write: if request.auth != null &&
        (request.auth.token.admin == true || request.auth.token.role == 'admin');
    }
  }
}
```

### **Step 5: Create Composite Indexes**

**Important:** These will be created automatically when the app runs and encounters query errors. The error messages will provide direct links to create them.

**Expected indexes to create:**
1. `highlights` collection: `(wardId, active, placement, priority, __name__)`
2. `highlights` collection: `(wardId, active, lastShown, priority, __name__)`
3. `pushFeed` collection: `(wardId, timestamp, __name__)`

---

## ✅ **Verification Checklist**

### **After Setup, Verify:**
- [ ] All 5 collections exist
- [ ] All 4 plan documents created
- [ ] Security rules published
- [ ] Indexes created (may take 2-5 minutes)

### **Test in App:**
- [ ] Create a test highlight
- [ ] View highlights on home screen
- [ ] Check Firebase for data
- [ ] Verify no permission errors

---

## 📞 **Support Information**

### **If You Need Help:**
- **Error Messages:** Share exact error text
- **Screenshots:** Firebase Console screenshots
- **Step Stuck On:** Which step number
- **Contact:** Development team for technical issues

### **Expected Completion Time:**
- Collections: 10 minutes
- Plan Documents: 15 minutes
- Security Rules: 5 minutes
- Indexes: 5 minutes (automatic)
- **Total: 35 minutes**

---

## 🎯 **What This Enables**

✅ **Candidates can purchase highlights**
✅ **Highlights appear on voter home screens**
✅ **Analytics track impressions and clicks**
✅ **Admin can manage content and pricing**
✅ **Revenue generation system ready**

---

## 🎛️ **Admin Interface Requirements**

### **Phase 1: Immediate Operations (Firebase Console Only)**

**What you can do RIGHT NOW after setup:**

#### **📊 View & Monitor:**
- ✅ **View all highlights** in `highlights` collection
- ✅ **Monitor analytics** (views, clicks, impressions)
- ✅ **Check subscription data** in `user_subscriptions`
- ✅ **View payment records** in `payments` collection
- ✅ **Track system usage** in Firebase Analytics

#### **✏️ Manual Management:**
- ✅ **Create test highlights** using app test screens
- ✅ **Update highlight status** (active/inactive) manually
- ✅ **Delete inappropriate highlights** from collections
- ✅ **Modify plan pricing** in `plans` collection
- ✅ **Update plan features** by editing documents

#### **🔍 Troubleshooting:**
- ✅ **Check error logs** in Firebase Console
- ✅ **Verify data integrity** across collections
- ✅ **Monitor index performance** and usage
- ✅ **Review security rule violations**

### **Phase 2: Custom Admin Panel (Recommended)**

**What would improve with a custom web interface:**

#### **🎯 Highlight Management:**
- 🎯 **Bulk approve/reject** pending highlights
- 🎯 **Advanced filtering** by ward, party, package
- 🎯 **Content moderation** queue for review
- 🎯 **Priority management** for highlight ordering
- 🎯 **Automated expiration** handling

#### **💰 Plan Management:**
- 💰 **Dynamic pricing updates** with validation
- 💰 **Feature toggling** per plan
- 💰 **Subscription lifecycle** management
- 💰 **Revenue analytics** and reporting
- 💰 **Promotional pricing** setup

#### **📈 Analytics Dashboard:**
- 📈 **Real-time performance** monitoring
- 📈 **Conversion rate tracking** (Free → Paid)
- 📈 **Geographic analytics** by ward/district
- 📈 **Revenue forecasting** and trends
- 📈 **User engagement** metrics

#### **🔧 System Administration:**
- 🔧 **Automated cleanup** of expired highlights
- 🔧 **Bulk operations** for maintenance
- 🔧 **User management** and permissions
- 🔧 **System health monitoring**
- 🔧 **Backup and recovery** procedures

---

## 📋 **Admin Operations Comparison**

| Operation | Firebase Console | Custom Admin Panel | Priority |
|-----------|------------------|-------------------|----------|
| **View highlights** | ✅ Basic list | ✅ Advanced filtering | Medium |
| **Create highlights** | ✅ Manual entry | ✅ Bulk import | Low |
| **Update status** | ✅ Manual edit | ✅ Bulk operations | Medium |
| **Delete highlights** | ✅ Manual delete | ✅ With audit trail | Low |
| **Monitor analytics** | ✅ Basic metrics | ✅ Advanced dashboard | High |
| **Manage plans** | ✅ Manual edit | ✅ User-friendly forms | Medium |
| **Content moderation** | ❌ Not available | ✅ Review queue | High |
| **Bulk operations** | ❌ Not available | ✅ Efficient workflow | Medium |
| **Automated tasks** | ❌ Not available | ✅ Scheduled jobs | Low |
| **Advanced reporting** | ❌ Not available | ✅ Custom reports | Medium |

---

## 🚀 **Implementation Priority**

### **High Priority (Implement First):**
1. **Content Moderation Queue** - Review highlight content
2. **Analytics Dashboard** - Monitor system performance
3. **Bulk Status Updates** - Efficient highlight management

### **Medium Priority (Next Sprint):**
1. **Advanced Filtering** - Find highlights by criteria
2. **Plan Management UI** - Easy pricing updates
3. **User Management** - Admin role assignments

### **Low Priority (Future):**
1. **Automated Workflows** - Scheduled cleanup tasks
2. **Advanced Reporting** - Custom analytics
3. **Bulk Import/Export** - Data migration tools

---

## 💡 **Current Limitations & Workarounds**

### **Without Custom Admin Panel:**
- **Manual Operations:** Use Firebase Console for all management
- **Bulk Updates:** Edit multiple documents individually
- **Content Review:** Manually check highlights in collections
- **Analytics:** Use Firebase Analytics dashboard
- **Reporting:** Export data manually for analysis

### **Recommended Workarounds:**
1. **Use Firebase Console bookmarks** for quick access
2. **Create standard operating procedures** for manual tasks
3. **Set up email alerts** for important events
4. **Use Google Sheets** for bulk data analysis
5. **Schedule regular reviews** of highlight content

---

## 🔄 **Migration Path**

### **Phase 1: Firebase Console Only (Current)**
- ✅ Complete setup using this document
- ✅ Test all functionality manually
- ✅ Establish manual workflows
- ✅ Monitor system performance

### **Phase 2: Hybrid Approach (1-2 weeks)**
- 🔄 Add basic highlight management to existing admin panel
- 🔄 Implement content moderation queue
- 🔄 Create simple analytics dashboard
- 🔄 Maintain Firebase Console for complex operations

### **Phase 3: Full Admin Panel (2-4 weeks)**
- 🔄 Complete custom admin interface
- 🔄 Automated workflows and scheduling
- 🔄 Advanced analytics and reporting
- 🔄 Full system administration capabilities

---

## 📞 **Support & Questions**

### **For Firebase Console Operations:**
- **Documentation:** Firebase Console help center
- **Support:** Firebase technical support
- **Training:** Firebase Console tutorials

### **For Custom Admin Panel Development:**
- **Contact:** Development team for interface requirements
- **Timeline:** 2-4 weeks for full implementation
- **Priority:** High for content moderation and analytics

---

## ✅ **Ready to Start?**

**Immediate Next Steps:**
1. ✅ Complete Firebase setup using this document
2. ✅ Test highlight creation and display
3. ✅ Use Firebase Console for management
4. 🔄 Plan custom admin panel development

**The highlight system is fully functional with Firebase Console management!** 🎉

---

**Document Version:** 1.0
**Last Updated:** 2025-01-17
**Project:** Janmat Highlight System