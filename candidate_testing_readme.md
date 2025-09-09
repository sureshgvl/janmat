# Candidate Functionality Testing Guide

## Overview
This guide provides comprehensive testing procedures for all candidate-related features in the JanMat application. It covers the complete candidate journey from registration to premium features.

## User Onboarding Flow

### Complete First-Time User Journey
Before testing candidate functionality, understand the full user onboarding process:

1. **Language Selection** (First time only)
   - App detects first-time user
   - User selects preferred language (English/Marathi)
   - Default language set to English

2. **Authentication**
   - User clicks "Login with Gmail"
   - Firebase Auth handles authentication
   - User profile created in database

3. **Role Selection**
   - User chooses between "Voter" or "Candidate"
   - Selection stored in user profile
   - Determines initial dashboard and features

4. **Profile Completion**
   - User fills personal information
   - **Critical**: City and ward selection required for candidate features
   - Profile completion flag set to true

5. **Role-Based Dashboard**
   - Voter: Standard home screen with basic features
   - Candidate: Enhanced dashboard with campaign tools

### Important Notes for Testing
- **City/Ward Information**: Essential for candidate registration and ward-based features
- **Role Selection**: Role is selected during onboarding and determines initial navigation path
- **Candidate Dashboard**: Only appears in drawer menu for users with candidate role
- **Profile Updates**: Users can modify profile information anytime
- **Data Persistence**: All selections saved to Firebase and persist across sessions

## Prerequisites

### Test Environment Setup
1. **Clean Test Account**: Create a new user account for testing
2. **Location Setup**: Ensure test user has city/ward information set
3. **Admin Access**: Have admin credentials ready for approval testing
4. **Test Data**: Prepare sample data for various test scenarios

### Required Test Accounts
- **Regular Voter Account**: For testing follow/unfollow features
- **Candidate Account**: For testing candidate-specific features
- **Premium Candidate Account**: For testing premium features
- **Admin Account**: For testing approval workflows

### Test Account Setup Flow
1. **Create New Account**: Use different Gmail accounts for each test scenario
2. **Complete Onboarding**: Follow the full flow for each account type
3. **Role Assignment**:
   - Voter: Select "Voter" during role selection → navigates to home screen
   - Candidate: Select "Candidate" during role selection → navigates to candidate setup
   - Admin: Requires special admin credentials and manual role assignment
4. **Profile Completion**: Ensure city/ward information is properly set during profile completion
5. **Premium Setup**: Purchase premium subscription for premium test accounts (available after candidate setup)

## Test Scenarios

## 1. Candidate Registration & Setup

### Test Case 1.1: Candidate Profile Creation
**Objective**: Verify candidate can successfully register and create profile

**Preconditions**:
- Fresh user account (first-time user)
- Complete initial onboarding up to role selection
- User is on RoleSelectionScreen

**Test Steps**:
1. On RoleSelectionScreen, select "Candidate" role
2. Click "Continue" button
3. System automatically navigates to CandidateSetupScreen
4. Fill candidate registration form:
   - Full Name: "Test Candidate Name" (pre-filled from auth)
   - Political Party: Select from dropdown (e.g., "Indian National Congress")
   - Manifesto: "Test manifesto content for testing purposes"
5. Click "Create Candidate Profile" button
6. Verify success message appears
7. Check user role updated to "candidate" in database
8. Verify navigation to home screen with candidate dashboard access

**Expected Results**:
- ✅ Form validation works for all required fields
- ✅ Success snackbar: "Your candidate profile has been created successfully!"
- ✅ User role changes from "voter" to "candidate"
- ✅ Navigation to home screen with candidate dashboard access
- ✅ Candidate profile appears in database under correct city/ward path

**Edge Cases to Test**:
- Empty form submission (should show validation errors)
- Invalid characters in name field
- Very long manifesto text
- Network disconnection during submission

### Test Case 1.2: Duplicate Registration Prevention
**Objective**: Ensure user cannot register as candidate twice

**Preconditions**:
- User has already completed candidate registration
- User is logged in with candidate role

**Test Steps**:
1. Login with existing candidate account (completes full onboarding flow)
2. Navigate to home screen
3. Open drawer menu
4. Look for "Become a Candidate" option
5. Verify option is not available or shows different state
6. Attempt to navigate to candidate setup screen directly (if possible)

**Expected Results**:
- ✅ "Become a Candidate" option not visible in drawer for existing candidates
- ✅ System prevents duplicate registration attempts
- ✅ Clear indication that user is already a candidate
- ✅ Direct navigation to candidate setup blocked or redirected

## 2. Candidate Profile Management

### Test Case 2.1: Profile Display
**Objective**: Verify candidate profile displays correctly

**Test Steps**:
1. Login as candidate
2. Navigate to Profile screen
3. View candidate information section
4. Check all profile fields display correctly

**Expected Results**:
- ✅ Name, party, and manifesto display correctly
- ✅ Profile photo (if uploaded) shows properly
- ✅ Contact information is visible
- ✅ Follower count displays accurately

### Test Case 2.2: Profile Updates
**Objective**: Test candidate profile editing capabilities

**Test Steps**:
1. Access candidate profile edit mode
2. Update manifesto content
3. Upload/change profile photo
4. Save changes

**Expected Results**:
- ✅ Changes save successfully
- ✅ Updated information reflects immediately
- ✅ Photo uploads to Firebase Storage correctly
- ✅ Changes visible to other users

## 3. Candidate Dashboard

### Test Case 3.1: Dashboard Access
**Objective**: Verify candidate dashboard functionality

**Test Steps**:
1. Login as candidate
2. Navigate to Home screen
3. Access drawer menu
4. Click "Candidate Dashboard"

**Expected Results**:
- ✅ Dashboard loads with candidate-specific options
- ✅ Analytics section shows follower counts
- ✅ Campaign management tools are accessible
- ✅ Premium upgrade options are visible

### Test Case 3.2: Analytics Display
**Objective**: Test dashboard analytics functionality

**Test Steps**:
1. Access Candidate Dashboard
2. View follower analytics
3. Check engagement metrics
4. Review campaign performance data

**Expected Results**:
- ✅ Follower count displays accurately
- ✅ Engagement metrics update in real-time
- ✅ Charts and graphs render correctly
- ✅ Data refreshes automatically

## 4. Follow/Unfollow System

### Test Case 4.1: Follow Candidate
**Objective**: Test following functionality from voter perspective

**Preconditions**:
- Have both voter and candidate test accounts
- Candidate profile is approved and visible

**Test Steps**:
1. Login as voter
2. Navigate to Candidates tab
3. Find test candidate profile
4. Click "Follow" button
5. Confirm follow action

**Expected Results**:
- ✅ Follow button changes to "Following"
- ✅ Candidate's follower count increases by 1
- ✅ Follow relationship recorded in database
- ✅ Notification sent to candidate (if enabled)

### Test Case 4.2: Unfollow Candidate
**Objective**: Test unfollowing functionality

**Test Steps**:
1. From voter's account, access candidate profile
2. Click "Following" button to unfollow
3. Confirm unfollow action

**Expected Results**:
- ✅ Button changes back to "Follow"
- ✅ Candidate's follower count decreases by 1
- ✅ Follow relationship removed from database
- ✅ Voter removed from candidate's followers list

### Test Case 4.3: Follower List Display
**Objective**: Verify follower list functionality

**Test Steps**:
1. Login as candidate
2. Access followers list from dashboard
3. View list of users following the candidate
4. Check follower details and interaction history

**Expected Results**:
- ✅ Follower list loads correctly
- ✅ Shows accurate follower count
- ✅ Displays follower names and follow dates
- ✅ Allows interaction with followers

## 5. Candidate Discovery & Search

### Test Case 5.1: Browse Candidates
**Objective**: Test candidate browsing functionality

**Test Steps**:
1. Login as any user type
2. Navigate to Candidates tab
3. Browse candidate list
4. View candidate cards with basic information

**Expected Results**:
- ✅ Candidate list loads from database
- ✅ Shows candidate names, parties, and photos
- ✅ Displays follower counts
- ✅ Allows navigation to detailed profiles

### Test Case 5.2: Search by Ward
**Objective**: Test location-based candidate search

**Test Steps**:
1. Access "Search by Ward" feature
2. Select city and ward
3. View candidates specific to that ward
4. Test filtering and sorting options

**Expected Results**:
- ✅ Candidates filtered by selected ward
- ✅ Accurate location-based results
- ✅ Search results update in real-time
- ✅ Map integration (if available)

### Test Case 5.3: My Area Candidates
**Objective**: Test location-based candidate discovery

**Test Steps**:
1. Login with user having ward information
2. Access "My Area Candidates" from home screen
3. View candidates from user's ward
4. Test location accuracy

**Expected Results**:
- ✅ Shows candidates from user's ward only
- ✅ Location data matches user profile
- ✅ Updates when user location changes
- ✅ Local candidates prioritized

## 6. Premium Candidate Features

### Test Case 6.1: Premium Upgrade
**Objective**: Test candidate premium subscription purchase

**Preconditions**:
- Candidate account with basic profile
- Payment method configured

**Test Steps**:
1. Login as candidate
2. Navigate to Premium Features screen
3. Select "For Candidates" tab
4. Choose premium plan (₹1,999 or ₹5,000)
5. Complete purchase process

**Expected Results**:
- ✅ Payment processing works correctly
- ✅ User role updates to "candidate_premium"
- ✅ Premium features unlock immediately
- ✅ Subscription recorded in database

### Test Case 6.2: Premium Feature Access
**Objective**: Verify premium features work for upgraded candidates

**Test Steps**:
1. Login as premium candidate
2. Test manifesto editing capabilities
3. Upload media files (photos/videos)
4. Check sponsored visibility features
5. Access advanced analytics

**Expected Results**:
- ✅ Manifesto CRUD operations functional
- ✅ Media uploads work with Firebase Storage
- ✅ Profile shows premium indicators
- ✅ Advanced analytics available
- ✅ Sponsored tags appear in search results

## 7. Admin Approval Workflow

### Test Case 7.1: Candidate Approval Process
**Objective**: Test admin candidate approval functionality

**Preconditions**:
- Admin account access
- Pending candidate applications

**Test Steps**:
1. Login as admin
2. Navigate to Admin Panel
3. Access "Pending Approval" tab
4. Review candidate details
5. Click "Approve" or "Reject" button

**Expected Results**:
- ✅ Candidate status updates correctly
- ✅ Approved candidates move to "Approved" tab
- ✅ Rejected candidates move to "Rejected" tab
- ✅ Status changes reflect in candidate profile

### Test Case 7.2: Candidate Finalization
**Objective**: Test election finalization process

**Test Steps**:
1. Login as admin
2. Access Admin Panel
3. Go to "Approved" tab
4. Click "Finalize" on approved candidates

**Expected Results**:
- ✅ Candidate status changes to "finalized"
- ✅ Candidates move to "Finalized" tab
- ✅ Finalized candidates become official election participants
- ✅ Prevents further candidate registrations

## 8. Integration Testing

### Test Case 8.1: Cross-Feature Integration
**Objective**: Test interaction between different candidate features

**Test Steps**:
1. Create candidate profile
2. Get approved by admin
3. Upgrade to premium
4. Create chat room
5. Post updates and engage with followers
6. Monitor analytics

**Expected Results**:
- ✅ All features work together seamlessly
- ✅ Data consistency across features
- ✅ Real-time updates work correctly
- ✅ User experience is smooth

### Test Case 8.2: Performance Testing
**Objective**: Test candidate features under load

**Test Steps**:
1. Create multiple candidate accounts
2. Test simultaneous profile updates
3. Check database performance with many followers
4. Test search functionality with large candidate database

**Expected Results**:
- ✅ System handles multiple users efficiently
- ✅ Database queries perform well
- ✅ UI remains responsive
- ✅ No data corruption or conflicts

## 9. Error Handling & Edge Cases

### Test Case 9.1: Network Issues
**Objective**: Test behavior during network problems

**Test Steps**:
1. Start candidate profile creation
2. Disconnect network during submission
3. Reconnect and check data integrity
4. Test offline functionality

**Expected Results**:
- ✅ Graceful error handling
- ✅ Data preservation during network issues
- ✅ Clear error messages to users
- ✅ Automatic retry mechanisms

### Test Case 9.2: Data Validation
**Objective**: Test input validation and data integrity

**Test Steps**:
1. Try submitting forms with invalid data
2. Test special characters and long inputs
3. Attempt SQL injection or XSS attacks
4. Check file upload restrictions

**Expected Results**:
- ✅ All inputs properly validated
- ✅ Malicious input rejected
- ✅ File types and sizes restricted
- ✅ Database integrity maintained

## 10. Mobile Responsiveness

### Test Case 10.1: Different Screen Sizes
**Objective**: Test candidate features on various devices

**Test Steps**:
1. Test on different phone sizes
2. Test on tablets
3. Check landscape/portrait orientations
4. Verify touch interactions

**Expected Results**:
- ✅ UI adapts to different screen sizes
- ✅ All features accessible on mobile
- ✅ Touch interactions work properly
- ✅ Text and images scale correctly

## Testing Checklist

### Pre-Release Checklist
- [ ] All test cases pass successfully
- [ ] No critical bugs found
- [ ] Performance meets requirements
- [ ] Security vulnerabilities addressed
- [ ] User experience is smooth
- [ ] Data integrity maintained
- [ ] Error handling works properly

### Post-Release Monitoring
- [ ] Monitor crash reports
- [ ] Track user engagement metrics
- [ ] Monitor database performance
- [ ] Check for user feedback
- [ ] Plan for feature enhancements

## Troubleshooting

### Common Issues & Solutions

**Issue**: Candidate profile not saving
**Solution**: Check network connection, verify form validation, check Firebase permissions

**Issue**: Follower count not updating
**Solution**: Verify database write permissions, check transaction completion

**Issue**: Premium features not unlocking
**Solution**: Confirm payment processing, check subscription status, verify user role update

**Issue**: Search not returning results
**Solution**: Check index configuration, verify query parameters, test database connectivity

## Test Data Preparation

### Sample Test Data
```json
{
  "test_candidate_1": {
    "name": "Rajesh Kumar",
    "party": "Indian National Congress",
    "city": "Mumbai",
    "ward": "Ward 1",
    "manifesto": "Education and healthcare for all"
  },
  "test_candidate_2": {
    "name": "Priya Sharma",
    "party": "Bharatiya Janata Party",
    "city": "Pune",
    "ward": "Ward 2",
    "manifesto": "Digital transformation and smart cities"
  }
}
```

### Test User Accounts
- **Admin**: admin@janmat.com
- **Test Candidate**: candidate@test.com
- **Test Voter**: voter@test.com
- **Premium Candidate**: premium@test.com

This comprehensive testing guide ensures all candidate functionality works correctly and provides a smooth user experience.