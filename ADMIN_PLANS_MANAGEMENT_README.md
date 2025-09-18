# 🎯 Admin Plans Management - Complete Firebase Setup Guide

## 📋 **Overview**
This guide walks you through setting up candidate subscription plans in Firebase for the Janmat app. You'll create 4 plan tiers (Free, Basic, Gold, Platinum) with different features and visibility levels.

**⏰ Time Required:** 2-3 hours
**⚠️ Prerequisites:** Firebase Console access, basic understanding of databases

---

## 🏗️ **Step 1: Access Firebase Console**

### **How to Access:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your Janmat project
3. Click on **"Firestore Database"** in the left sidebar
4. If no database exists, click **"Create database"**
5. Choose **"Start in test mode"** (you can change security later)
6. Select a location (choose the one closest to your users, e.g., `asia-south1` for India)

**📸 What you should see:**
- Empty database with "No documents" message
- Collections panel on the left
- Query panel on the right

---

## 📁 **Step 2: Create Collections**

### **2.1 Create "plans" Collection**

**Why:** This stores all subscription plan definitions

**Steps:**
1. Click **"+ Start collection"**
2. Collection ID: `plans`
3. Click **"Next"**

**Add First Document (Free Plan):**
1. Document ID: `free_plan` (auto-generated is fine too)
2. Add these fields:

| Field Name | Type | Value |
|------------|------|-------|
| `planId` | string | `free_plan` |
| `name` | string | `Free Plan` |
| `type` | string | `candidate` |
| `price` | number | `0` |
| `limit` | null | (leave empty) |
| `isActive` | boolean | `true` |
| `createdAt` | timestamp | Click calendar icon, select today's date |

**Add Features Array:**
1. Click **"+ Add field"** → Field name: `features`
2. Type: `array`
3. Click the array field to expand
4. Add these objects (click "+ Add" for each):

```json
// Copy and paste each object separately:
{"name": "Basic Profile", "description": "Name, party, symbol, photo", "enabled": true}
{"name": "Basic Info", "description": "Age, gender, education, profession", "enabled": true}
{"name": "Basic Contact", "description": "Phone and email only", "enabled": true}
{"name": "Short Bio", "description": "Short biography text", "enabled": true}
{"name": "Limited Manifesto", "description": "3 promises text only", "enabled": true}
{"name": "Limited Media", "description": "2 photos, no videos", "enabled": true}
{"name": "Follower Count", "description": "Show followers/following", "enabled": true}
```

5. Click **"Save"**

### **2.2 Create "user_subscriptions" Collection**

**Why:** Tracks which candidates have which plans

**Steps:**
1. Click **"+ Start collection"**
2. Collection ID: `user_subscriptions`
3. Click **"Next"**
4. Document ID: Leave auto-generated
5. **Don't add any fields yet** (this will be populated when users subscribe)
6. Click **"Save"**

---

## 📋 **Step 3: Add Remaining Plan Documents**

### **Basic Plan Document:**
1. In `plans` collection, click **"+ Add document"**
2. Document ID: `basic_plan`
3. Add fields:

| Field | Type | Value |
|-------|------|-------|
| `planId` | string | `basic_plan` |
| `name` | string | `Basic Package` |
| `type` | string | `candidate` |
| `price` | number | `5000` |
| `limit` | number | `1000` |
| `isActive` | boolean | `true` |
| `createdAt` | timestamp | Today's date |

**Features Array:**
```json
{"name": "All Free Features", "description": "Includes all free plan features", "enabled": true}
{"name": "Full Manifesto", "description": "Title + 5 promises + PDF upload", "enabled": true}
{"name": "Cover Photo", "description": "Premium cover photo", "enabled": true}
{"name": "Enhanced Media", "description": "5 photos + 1 video", "enabled": true}
{"name": "Limited Achievements", "description": "Up to 3 achievements", "enabled": true}
{"name": "Extended Contact", "description": "Social links + office address", "enabled": true}
{"name": "Limited Events", "description": "Up to 2 events, no RSVP", "enabled": true}
{"name": "Basic Analytics", "description": "Profile views count", "enabled": true}
```

### **Gold Plan Document:**
1. Click **"+ Add document"**
2. Document ID: `gold_plan`
3. Fields: Similar to above, price: `25000`, limit: null

**Features Array:**
```json
{"name": "All Basic Features", "description": "Includes all basic plan features", "enabled": true}
{"name": "Carousel Highlight", "description": "Ward-level candidate carousel", "enabled": true}
{"name": "Video Manifesto", "description": "Video upload for manifesto", "enabled": true}
{"name": "Unlimited Media", "description": "50 photos + 10 videos", "enabled": true}
{"name": "Unlimited Achievements", "description": "Unlimited achievement entries", "enabled": true}
{"name": "Full Events", "description": "Events with RSVP functionality", "enabled": true}
{"name": "Push Notifications", "description": "2 push notifications per week", "enabled": true}
{"name": "Highlight Feature", "description": "1 active highlight", "enabled": true}
{"name": "Advanced Analytics", "description": "Views, follower growth, top content", "enabled": true}
```

### **Platinum Plan Document:**
1. Click **"+ Add document"**
2. Document ID: `platinum_plan`
3. Fields: price: `100000`, limit: null

**Features Array:**
```json
{"name": "All Gold Features", "description": "Includes all gold plan features", "enabled": true}
{"name": "Exclusive Banner", "description": "Home screen top banner", "enabled": true}
{"name": "Unlimited Everything", "description": "All media, events, notifications", "enabled": true}
{"name": "Multiple Highlights", "description": "Multiple highlights with priority", "enabled": true}
{"name": "Full Analytics Dashboard", "description": "Complete analytics with demographics", "enabled": true}
{"name": "Chat Priority", "description": "Priority messaging", "enabled": true}
{"name": "Premium Badge", "description": "Verified candidate badge", "enabled": true}
{"name": "Admin Support", "description": "Dedicated admin support", "enabled": true}
```

---

## 🔒 **Step 4: Set Up Security Rules**

### **Why Security Rules Matter:**
They control who can read/write data and prevent unauthorized access.

### **How to Set Rules:**
1. In Firebase Console, go to **"Firestore Database"**
2. Click on **"Rules"** tab
3. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Plans collection - read-only for everyone, write for admin only
    match /plans/{planId} {
      allow read: if true;
      allow write: if request.auth != null &&
        request.auth.token.admin == true;
    }

    // User subscriptions - users can read their own, admin can read/write all
    match /user_subscriptions/{subscriptionId} {
      allow read: if request.auth != null &&
        (request.auth.uid == resource.data.userId ||
         request.auth.token.admin == true);
      allow write: if request.auth != null &&
        (request.auth.uid == resource.data.userId ||
         request.auth.token.admin == true);
    }

    // Candidates collection (existing) - keep existing rules
    match /candidates/{candidateId} {
      allow read: if true; // Public read for voter visibility
      allow write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
    }
  }
}
```

4. Click **"Publish"**

---

## 💰 **Step 5: Set Up Payment Integration**

### **Option 1: Razorpay (Recommended for India)**
1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Create account and verify
3. Get API Keys (Key ID and Key Secret)
4. In Firebase Console:
   - Go to **"Functions"** → **"Environment"**
   - Add variables: `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET`

### **Option 2: Manual Payment Tracking**
For initial testing, you can manually create subscription records:
1. When candidate pays, create document in `user_subscriptions`
2. Use the format shown in the JSON examples above

---

## 📊 **Step 6: Create Admin Panel (Optional)**

### **Simple Admin Panel Setup:**
1. Create a web page with Firebase authentication
2. Add admin role to your Firebase Auth user
3. Use Firebase SDK to manage plans and subscriptions

**Basic Admin Features:**
- View all plans and edit pricing
- See subscription analytics
- Manually activate/deactivate subscriptions
- Export data for reporting

---

## 🧪 **Step 7: Testing Your Setup**

### **Test Plan Creation:**
1. In Firestore, verify all 4 plan documents exist
2. Check that features arrays are properly formatted
3. Test reading plans from your app

### **Test Subscription Flow:**
1. Create a test subscription document manually
2. Verify the data structure matches the examples
3. Test that your app can read subscription status

### **Test Security:**
1. Try accessing data without authentication
2. Verify that only authorized users can modify subscriptions
3. Test plan reading permissions

---

## ⏰ **Step 8: Set Plan Validity Periods**

### **Why Validity Matters:**
Different plans can have different validity periods (1 month, 3 months, 1 year, etc.) that you control as admin.

### **How to Set Validity Periods:**

**Option 1: Fixed Validity in Plan Document**
1. In `plans` collection, add these fields to each plan:
   - `validityDays`: number (e.g., 30 for 1 month, 365 for 1 year)
   - `validityType`: string (e.g., "days", "months", "years")

**Example for Basic Plan:**
```json
{
  "planId": "basic_plan",
  "name": "Basic Package",
  "price": 5000,
  "validityDays": 365,
  "validityType": "days",
  // ... other fields
}
```

**Option 2: Flexible Validity (Recommended)**
Create multiple versions of the same plan:
- `basic_plan_1month` (₹3,000 for 30 days)
- `basic_plan_3month` (₹8,000 for 90 days)
- `basic_plan_1year` (₹25,000 for 365 days)

### **Subscription Expiry Management:**

**When a subscription is created:**
1. Calculate `expiresAt` = `purchasedAt` + `validityDays`
2. Store in `user_subscriptions` document

**Example subscription document:**
```json
{
  "subscriptionId": "sub_123",
  "userId": "candidate_456",
  "planId": "basic_plan",
  "purchasedAt": "2025-01-01T10:00:00Z",
  "expiresAt": "2026-01-01T10:00:00Z",  // 1 year later
  "isActive": true
}
```

---

## 📈 **Step 9: Monitor and Manage**

### **Daily Admin Tasks:**
1. **Check new subscriptions** in `user_subscriptions` collection
2. **Monitor payment failures** and contact candidates if needed
3. **Review plan usage** and adjust pricing/validity if necessary
4. **Handle support requests** from candidates
5. **Check expiring subscriptions** (send renewal reminders)

### **Weekly Admin Tasks:**
1. **Analyze conversion rates** (Free → Paid upgrades)
2. **Review popular validity periods** (1 month vs 1 year)
3. **Update pricing** based on market feedback
4. **Generate revenue reports**
5. **Monitor subscription churn** (early cancellations)

### **Monthly Admin Tasks:**
1. **Plan performance review** - which plans/validity periods are most popular?
2. **Feature usage analysis** - what features need improvement?
3. **Competitor pricing research** - adjust pricing and validity strategy
4. **User feedback review** - implement improvements
5. **Subscription lifecycle analysis** - when do users typically renew?

## 🔄 **Subscription Lifecycle Management**

### **Renewal Process:**
1. **Auto-renewal (if enabled):**
   - System automatically charges card on expiry
   - Creates new subscription document
   - Sends confirmation to candidate

2. **Manual Renewal:**
   - Candidate receives expiry notification (7 days, 3 days, 1 day before)
   - Can renew through app or contact admin
   - Admin can manually extend validity if needed

### **Admin Controls for Validity:**
1. **Extend Subscription:**
   ```javascript
   // In Firebase Console
   - Go to user_subscriptions collection
   - Find candidate's subscription
   - Update expiresAt field to new date
   ```

2. **Change Plan Validity:**
   ```javascript
   // Update plan document
   - Modify validityDays field
   - Affects all new subscriptions
   - Existing subscriptions keep original validity
   ```

3. **Handle Early Cancellations:**
   - Mark subscription as `isActive: false`
   - Calculate refund amount based on days used
   - Process refund through payment gateway

### **Validity Period Options to Consider:**

| Plan | Validity Options | Pricing Strategy |
|------|------------------|------------------|
| **Basic** | 1 month (₹3,000), 3 months (₹8,000), 1 year (₹25,000) | 15% discount for longer periods |
| **Gold** | 1 month (₹8,000), 3 months (₹22,000), 1 year (₹75,000) | 20% discount for annual |
| **Platinum** | 1 month (₹15,000), 3 months (₹40,000), 1 year (₹1,20,000) | 25% discount for annual |

### **Best Practices:**
- **Start with 1-month validity** for new customers to test
- **Offer annual discounts** (15-25% savings) to encourage long-term commitment
- **Monitor renewal rates** by validity period
- **Send renewal reminders** 7, 3, and 1 day before expiry
- **Allow plan upgrades** without losing remaining validity

---

## 🔧 **Troubleshooting Guide**

### **Problem: Cannot create collection**
**Solution:** Make sure you're in Firestore Database view, not Realtime Database

### **Problem: Security rules not working**
**Solution:** Check that you're using the correct Firebase project and that rules are published

### **Problem: App cannot read plans**
**Solution:** Verify collection name is exactly `plans` (case-sensitive)

### **Problem: Features array not saving**
**Solution:** Make sure each feature object has exactly these fields: `name`, `description`, `enabled`

### **Problem: Timestamp not saving**
**Solution:** Use the calendar picker in Firebase Console, don't type manually

---

## 📞 **Support & Next Steps**

### **If You Need Help:**
1. Check Firebase Console logs for errors
2. Verify all documents have correct field names
3. Test with Firebase emulator locally
4. Contact development team for app integration

### **After Firebase Setup:**
1. Share this document with your development team
2. They will integrate the plans into the Flutter app
3. Test the complete flow: Purchase → Firebase → App features
4. Launch and monitor user adoption

### **Key Contacts:**
- **Firebase Support:** [Firebase Help Center](https://firebase.google.com/support)
- **Payment Gateway:** Contact Razorpay support
- **Development Team:** For app integration questions

---

## ✅ **Checklist - Mark Complete**

- [ ] Firebase Console access confirmed
- [ ] Firestore Database created
- [ ] `plans` collection created with 4 documents
- [ ] `user_subscriptions` collection created
- [ ] All plan features arrays populated
- [ ] Security rules published
- [ ] Payment gateway configured (optional)
- [ ] Plan validity periods configured
- [ ] Test documents created and readable
- [ ] Admin monitoring process established
- [ ] Renewal notification system planned

**🎉 Congratulations!** Your Firebase backend is now ready for the subscription system. The development team can now integrate these plans into the Flutter app.