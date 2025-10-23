Based on the app logs analysis:

## Issue Summary
**Candidate Data Issue**: The home screen is incorrectly showing voter mode for candidate "सुरेश गवळी" (UID: joJTrpvoMBZ8gnQ3EyFLzzGdQgP2).

**Root Cause**: The `HomeServices.getUserData()` method is returning user data with role 'voter' instead of 'candidate', causing the home screen to:
- Enter voter mode (👤 VOTER MODE - No candidate data needed)
- Show Google displayName instead of candidate name
- Not load CandidateUserController for candidate-specific functionality

**Evidence from logs**:
1. `✅ ENTERING VOTER MODE` - Wrong mode detection
2. `👤 User: सुरेश गवळी (candidate)` - CandidateUserController correctly loads candidate data later
3. Candidate model exists with name "सुरेश गवळी" but isn't being used for display

## Investigation Needed
- Check firestore user document role field for UID joJTrpvoMBZ8gnQ3EyFLzzGdQgP2
- Verify if cache is serving stale user data
- Fix role detection in HomeServices to properly identify candidates
- Ensure CandidateUserController data is used for display when available

## Expected Behavior
- Home screen should enter candidate mode
- Display candidate name "सुरेश गवळी" instead of Google displayName
- Show candidate-specific widgets and functionality

This appears to be a data loading/initialization timing/race condition where HomeServices cache has stale user role data while CandidateUserController correctly loads fresh candidate data.
