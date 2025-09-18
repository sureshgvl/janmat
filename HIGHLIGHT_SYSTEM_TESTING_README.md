# 🎯 Highlight System Testing Guide

## 📋 **Overview**
This guide walks you through testing the complete highlight system step-by-step. No technical knowledge required!

**⏰ Time Required:** 30-45 minutes
**🎯 Goal:** Verify highlights work from creation to display

---

## ✅ **Prerequisites Checklist**

### **Firebase Setup (Required First)**
- [ ] Firebase Console access
- [ ] Firestore Database created
- [ ] Security rules updated (from previous guide)
- [ ] Composite indexes created (from previous guide)
- [ ] Collections created: `plans`, `user_subscriptions`, `highlights`, `pushFeed`, `payments`

### **App Setup**
- [ ] Flutter app installed on device/emulator
- [ ] Logged in as candidate user
- [ ] Home screen loads without errors

---

## 🧪 **Step 1: Create Test Highlight**

### **How to Access Test Tools:**
1. **Open your Flutter app**
2. **Log in as a candidate**
3. **Go to home screen**
4. **Look for test buttons in top-right corner:**
   - ➕ **Add icon** (blue circle) = Create Test Highlights
   - ⭐ **Star icon** (yellow) = View Existing Highlights

### **Create Your First Highlight:**
1. **Tap the ➕ Add icon**
2. **Fill in the form:**
   - Candidate ID: `test_candidate_123`
   - Ward ID: `ward_pune_1`
   - Candidate Name: `Test Candidate`
   - Party: `Test Party`
   - Package: Select `gold` or `platinum`
   - Placement: Check `carousel` (and `top_banner` for platinum)

3. **Tap "Create Gold/Platinum Highlight"**
4. **Expected Result:** ✅ Success message "Highlight created successfully!"

### **What Just Happened:**
- ✅ Highlight document created in Firebase `highlights` collection
- ✅ Analytics fields initialized (views: 0, clicks: 0)
- ✅ Active status set to true
- ✅ Package and placement configured

---

## 🧪 **Step 2: Verify Firebase Data**

### **Check Firebase Console:**
1. **Go to Firebase Console** → **Firestore Database**
2. **Open `highlights` collection**
3. **Find your new highlight document** (should have ID like `hl_175810...`)

### **Verify Document Fields:**
```json
{
  "highlightId": "hl_175810...",
  "candidateId": "test_candidate_123",
  "wardId": "ward_pune_1",
  "package": "gold", // or "platinum"
  "placement": ["carousel"], // or ["carousel", "top_banner"]
  "active": true,
  "views": 0,
  "clicks": 0,
  "candidateName": "Test Candidate",
  "party": "Test Party"
}
```

### **Expected Result:**
- ✅ Document exists with correct data
- ✅ All required fields present
- ✅ Active status is `true`

---

## 🧪 **Step 3: Test Home Screen Display**

### **View Highlights on Home Screen:**
1. **Return to Flutter app home screen**
2. **Look for highlight carousel** (below welcome section)
3. **Expected Result:**
   - ✅ **Carousel appears** with "Featured Candidates" header
   - ✅ **Your test highlight shows** as a card
   - ✅ **Auto-play works** (cards change every 5 seconds)
   - ✅ **Dots indicator** shows at bottom

### **Test Platinum Banner (If Created):**
1. **Create a platinum highlight** with `top_banner` placement
2. **Return to home screen**
3. **Expected Result:**
   - ✅ **Large banner appears** at top of screen
   - ✅ **Purple "PLATINUM" badge** visible
   - ✅ **"Sponsored" tag** in corner

---

## 🧪 **Step 4: Test User Interactions**

### **Test Card Tapping:**
1. **Tap on your highlight card**
2. **Expected Result:**
   - ✅ **Click count increases** in Firebase
   - ✅ **Navigation works** (opens candidate profile or shows message)

### **Test Impression Tracking:**
1. **Let carousel auto-play** for 30 seconds
2. **Check Firebase document**
3. **Expected Result:**
   - ✅ **Views count increases** automatically
   - ✅ **lastShown timestamp updates**

### **Test Multiple Highlights:**
1. **Create 2-3 more test highlights**
2. **Return to home screen**
3. **Expected Result:**
   - ✅ **All highlights appear** in carousel
   - ✅ **Fair rotation** (lastShown affects order)
   - ✅ **Smooth transitions** between cards

---

## 🧪 **Step 5: Test Different Packages**

### **Gold Package Test:**
1. **Create highlight with `gold` package**
2. **Expected Result:**
   - ✅ **Appears in carousel**
   - ✅ **Yellow star badge**
   - ✅ **"GOLD" package indicator**

### **Platinum Package Test:**
1. **Create highlight with `platinum` package**
2. **Expected Result:**
   - ✅ **Banner appears at top** (if top_banner selected)
   - ✅ **Purple diamond badge**
   - ✅ **"PLATINUM" package indicator**
   - ✅ **Priority over gold highlights**

---

## 🧪 **Step 6: Test Admin Functions**

### **View All Highlights:**
1. **Tap ⭐ Star icon** on home screen
2. **Expected Result:**
   - ✅ **List of all highlights** with details
   - ✅ **View counts and click counts**
   - ✅ **Active/Inactive status**

### **Test Highlight Management:**
1. **In test screen, view highlight details**
2. **Expected Result:**
   - ✅ **All metadata visible**
   - ✅ **Creation timestamp**
   - ✅ **Package and placement info**

---

## 🔧 **Troubleshooting Guide**

### **Problem: "Permission Denied" Error**
**Solution:**
- ✅ Check Firebase security rules are updated
- ✅ Verify you're logged into the app
- ✅ Confirm user authentication status

### **Problem: "Index Required" Error**
**Solution:**
- ✅ Create the composite indexes from the error links
- ✅ Wait 2-5 minutes for indexes to build
- ✅ Check Firebase Console → Indexes tab

### **Problem: Highlights Don't Appear**
**Solution:**
- ✅ Verify `wardId` matches (`ward_pune_1`)
- ✅ Check `active` status is `true`
- ✅ Confirm package is `gold` or `platinum`
- ✅ Restart app to refresh data

### **Problem: Banner Not Showing**
**Solution:**
- ✅ Package must be `platinum`
- ✅ Placement must include `top_banner`
- ✅ Only one banner shows per ward (highest priority)

### **Problem: Carousel Empty**
**Solution:**
- ✅ Create at least one highlight
- ✅ Ward ID must match user's ward
- ✅ Package must be `gold` or `platinum`
- ✅ Active status must be `true`

---

## ✅ **Success Criteria**

### **All Tests Pass When:**
- ✅ **Highlight creation works** without errors
- ✅ **Firebase documents created** with correct data
- ✅ **Home screen shows carousel** with highlights
- ✅ **Platinum banner appears** when applicable
- ✅ **Click tracking works** (counts increase)
- ✅ **Impression tracking works** (views increase)
- ✅ **Multiple highlights rotate** fairly
- ✅ **Different packages display** correctly

---

## 📊 **Expected Performance**

### **Response Times:**
- ✅ **Highlight creation:** < 2 seconds
- ✅ **Home screen load:** < 3 seconds
- ✅ **Carousel transitions:** < 0.5 seconds
- ✅ **Firebase queries:** < 1 second

### **Data Accuracy:**
- ✅ **View counts increase** on each impression
- ✅ **Click counts increase** on each tap
- ✅ **Timestamps update** correctly
- ✅ **Rotation works** based on lastShown

---

## 🎯 **Quick Test Script**

### **5-Minute Complete Test:**
1. **Create highlight** (30 seconds)
2. **Check Firebase** (30 seconds)
3. **View on home screen** (30 seconds)
4. **Test interactions** (30 seconds)
5. **Verify analytics** (30 seconds)

### **Expected Results:**
- ✅ All steps complete successfully
- ✅ No error messages
- ✅ Smooth user experience
- ✅ Accurate data tracking

---

## 📞 **Need Help?**

### **If Tests Fail:**
1. **Check error messages** in Flutter console
2. **Verify Firebase setup** using console
3. **Confirm indexes are built** (Enabled status)
4. **Test with different ward IDs**

### **Common Issues:**
- **Wrong ward ID** → Use `ward_pune_1`
- **Missing indexes** → Create from error links
- **Permission issues** → Update security rules
- **Package mismatch** → Use `gold` or `platinum`

### **Support:**
- **Firebase Console Logs** → Check for detailed errors
- **Flutter Debug Console** → Look for specific error messages
- **Index Status** → Verify "Enabled" in Firebase Console

---

## 🎉 **Final Result**

### **When Everything Works:**
- ✅ **Highlight system fully functional**
- ✅ **Candidates can create paid highlights**
- ✅ **Voters see highlights on home screen**
- ✅ **Analytics track engagement**
- ✅ **Admin can manage content**
- ✅ **Revenue generation ready**

**Congratulations! Your highlight system is now live and working!** 🎯✨

---

## 📝 **Next Steps After Testing**

1. **Remove test buttons** from production app
2. **Create real highlights** for actual candidates
3. **Set up payment integration** for real transactions
4. **Monitor performance** and user engagement
5. **Scale to more wards** and districts

**The highlight system is now ready for production use!** 🚀