# 🚀 JANMAT Media Optimization & Offline Drafts - Testing Guide

## Overview

This comprehensive testing guide covers all the **enterprise-grade media optimization features** and **offline drafts functionality** implemented for the Janmat app. As the sole developer, use this guide to systematically test all features before deployment.

## 📋 Test Environment Setup

### Prerequisites
- ✅ Flutter 3.24+
- ✅ Android/iOS emulator or physical device
- ✅ Firebase project configured
- ✅ Storage rules deployed
- ✅ Test user account with data

### Test Data Preparation
1. **Create test candidate profile** with:
   - Basic info (name, photo, bio, location)
   - Manifesto content
   - Achievements with photos
   - Media gallery with images/videos
   - Event history

2. **Prepare test media files**:
   - High-resolution images (5MB+)
   - Videos (10MB+)
   - Low-quality photos
   - Various formats (JPG, PNG, MP4)

---

## 🎯 TEST SUITE A: MEDIA OPTIMIZATION FEATURES

### 1. **Image Compression (80% Reduction) Testing**

#### **Test Case 1.1: Smart Image Compression**
**Scenario**: Upload large image and verify automatic compression

**Steps**:
1. Navigate to `Candidate Dashboard → Media Tab → Add Image`
2. Select high-resolution image (5MB+ JPG)
3. Wait for compression progress dialog
4. Verify compression notification shows reduction %
5. Upload completes successfully

**Expected Results**:
- ✅ Compression dialog appears: "Optimizing Image... Compressing image for faster upload..."
- ✅ Success notification: "Image Compressed - 4.2MB → 800KB (81% reduction)"
- ✅ Upload completes within 30 seconds
- ✅ Image displays in gallery with same quality

#### **Test Case 1.2: Different Image Purposes - Quality Adaptation**
**Scenario**: Verify compression adapts to image purpose

**Steps**:
1. Upload achievement photo (user expects high quality)
2. Upload profile banner (can be compressed more)
3. Upload regular media image
4. Compare final file sizes and visual quality

**Expected Results**:
- ✅ Achievement photos: ~85% quality (2-3MB final)
- ✅ Banner images: ~70% quality (smaller files)
- ✅ Regular media: ~80% quality (balanced)

#### **Test Case 1.3: Video Compression**
**Scenario**: Video upload compression and optimization

**Steps**:
1. Add video to media gallery
2. Monitor upload progress
3. Check final file size after upload

**Expected Results**:
- ✅ Video is compressed to reasonable size (under 50MB for long videos)
- ✅ Quality remains acceptable
- ✅ Upload succeeds within 2 minutes

---

### 2. **Cache-First Loading Testing**

#### **Test Case 2.1: First Load → Caching**
**Scenario**: Verify images are cached after first load

**Steps**:
1. Open media gallery (first time - should load from network)
2. Note loading time for first image
3. Close and reopen gallery (should load from cache)
4. Compare loading speeds

**Expected Results**:
- ✅ First load: Network loading indicator appears
- ✅ Second load: Instant display from cache (no loading)
- ✅ Cache persists across app restarts

#### **Test Case 2.2: Cache Eviction**
**Scenario**: Verify old cached content is cleaned up

**Steps**:
1. Load 20+ high-resolution images in gallery
2. Check device storage usage
3. Navigate away and return after 1 hour
4. Monitor cache directory (should clean itself)

**Expected Results**:
- ✅ Old cached images automatically removed
- ✅ Only recently viewed images remain cached
- ✅ App performance unaffected

---

### 3. **Lazy Loading Galleries Testing**

#### **Test Case 3.1: Gallery Scroll Performance**
**Scenario**: Smooth scrolling through large galleries

**Steps**:
1. Populate media gallery with 50+ images
2. Scroll through gallery at normal speed
3. Monitor for stuttering or loading pauses
4. Test rapid scrolling

**Expected Results**:
- ✅ Smooth scrolling with no freezing
- ✅ Background preloading (300px ahead)
- ✅ Memory usage stays low (< 200MB)
- ✅ Scroll performance: 60+ FPS

#### **Test Case 3.2: Lazy Loading Triggers**
**Scenario**: Verify images load as user scrolls

**Steps**:
1. Large gallery (20+ images) not fully visible
2. Scroll slowly and observe loading behavior
3. Note when each image starts loading

**Expected Results**:
- ✅ Images load 300px before becoming visible
- ✅ No bulk loading of all images at once
- ✅ Background preloading reduces delays

#### **Test Case 3.3: Memory Management**
**Scenario**: Test memory efficiency during scrolling

**Steps**:
1. Load gallery with many high-res images
2. Monitor memory usage while scrolling
3. Use Android Studio Profiler/iOS Instruments
4. Test for memory leaks

**Expected Results**:
- ✅ Memory spikes during preloading but returns to normal
- ✅ No memory leaks detected
- ✅ App remains responsive even with large galleries

---

## 📵 TEST SUITE B: OFFLINE DRAFTS FUNCTIONALITY

### 4. **Offline Draft Creation Testing**

#### **Test Case 4.1: Network Failure → Automatic Draft Save**
**Scenario**: Loss of internet during media save

**Steps**:
1. Create/edit media content (add images, text)
2. Disable device internet (WiFi + Mobile data OFF)
3. Press Save button
4. Verify draft creation and notification

**Expected Results**:
- ✅ Save operation fails (as expected)
- ✅ Orange notification: "No internet! Changes saved as draft. Auto-sync when online."
- ✅ "VIEW" button appears for draft management
- ✅ Draft appears in local storage

#### **Test Case 4.2: Offline Content Creation**
**Scenario**: Full offline media editing

**Steps**:
1. Go offline
2. Add new media items: images, videos, YouTube links
3. Edit existing content
4. Save changes
5. Verify all edits are saved as drafts

**Expected Results**:
- ✅ All operations work offline
- ✅ Images are compressed and stored locally
- ✅ Multiple changes consolidated into one draft
- ✅ Draft metadata includes timestamps and change summaries

#### **Test Case 4.3: Draft Recovery**
**Scenario**: App crash/restart with drafts

**Steps**:
1. Create draft offline
2. Force close app (or kill process)
3. Reopen app
4. Check if drafts persist and are recoverable

**Expected Results**:
- ✅ Drafts survive app crashes/restarts
- ✅ SQLite database preserves all draft data
- ✅ Draft timestamps correctly saved
- ✅ Auto-sync triggers when online

---

### 5. **Auto-Sync Functionality Testing**

#### **Test Case 5.1: Offline → Online Auto-Sync**
**Scenario**: Drafts automatically sync when back online

**Steps**:
1. Create draft when offline
2. Verify draft saved locally
3. Re-enable internet
4. Wait 2 minutes (auto-sync interval)
5. Verify draft uploaded successfully

**Expected Results**:
- ✅ Notification: "Syncing drafts..." (showProgress: false)
- ✅ Draft disappears from local storage after successful sync
- ✅ Server has the uploaded content
- ✅ Success notification appears

#### **Test Case 5.2: Manual Force Sync**
**Scenario**: User-initiated sync of all drafts

**Steps**:
1. Accumulate multiple drafts offline
2. Go Settings → Force Sync All Drafts
3. Monitor sync progress with proper feedback
4. Verify all drafts processed

**Expected Results**:
- ✅ Dialog: "Syncing X drafts..."
- ✅ Progress indicator for each draft
- ✅ Partial failures handled gracefully
- ✅ Final success/error summary

#### **Test Case 5.3: Sync Conflict Resolution**
**Scenario**: Conflicts between local drafts and server data

**Steps**:
1. Create draft offline
2. While offline, change same data on another device
3. Come back online and sync
4. Handle conflict resolution

**Expected Results**:
- ✅ Default: Server wins (configurable)
- ✅ Data integrity maintained
- ✅ User notified if manual resolution needed

---

## 🎯 TEST SUITE C: STATE MANAGEMENT & SAVE ORCHESTRATION

### 6. **Two-Stage Save All Testing**

#### **Test Case 6.1: Media Upload + Metadata Commit**
**Scenario**: Complete end-to-end save orchestration

**Steps**:
1. Edit multiple dashboard tabs simultaneously
2. Add media content across different sections
3. Trigger Save All
4. Monitor two-stage process: media → metadata

**Expected Results**:
- ✅ Stage 1: Media files uploaded first
- ✅ Stage 2: Metadata commits after all media done
- ✅ Progress bar shows both stages
- ✅ Partial failure rollback works

#### **Test Case 6.2: Partial Failure Handling**
**Scenario**: Some media fails, others succeed

**Steps**:
1. Save content with mix of good/bad network conditions
2. Some uploads succeed, others fail
3. Observe rollback behavior

**Expected Results**:
- ✅ Successful uploads are not rolled back
- ✅ Failed items clearly marked
- ✅ User can retry individual failed items
- ✅ Atomicity maintained for each section

---

## 🔧 TEST SUITE D: PERFORMANCE & RELIABILITY

### 7. **Performance Benchmarks**

#### **Test Case 7.1: Large Media Upload**
**Test Data**: 10MB+ video file

**Steps**:
1. Upload large video offline
2. Compress and cache locally
3. Go online and sync
4. Measure total time and data usage

**Expected Results**:
- ✅ Compression: 10MB → ~3MB (70% reduction)
- ✅ Cache storage: Instant local access
- ✅ Network sync: Smooth background upload
- ✅ Total time < 5 minutes

#### **Test Case 7.2: Gallery Loading Stress Test**
**Test Data**: 100+ images in gallery

**Steps**:
1. Scroll through 100-image gallery
2. Monitor memory, CPU, network usage
3. Test on lower-end devices

**Expected Results**:
- ✅ Memory usage peaks at <300MB
- ✅ CPU usage stays under 80%
- ✅ Battery impact minimal

### 8. **Error Scenarios Testing**

#### **Test Case 8.1: Storage Full**
**Scenario**: Device storage exhaustion

**Steps**:
1. Fill device storage to near capacity
2. Attempt large media upload
3. Monitor error handling

**Expected Results**:
- ✅ Clear error message: "Insufficient storage space"
- ✅ Graceful cleanup of temporary files
- ✅ Recommendations provided

#### **Test Case 8.2: Corrupted Files**
**Scenario**: Upload corrupted media files

**Steps**:
1. Attempt to upload corrupted image/video
2. Verify validation catches issues
3. Error messages are helpful

**Expected Results**:
- ✅ File validation before upload
- ✅ Clear error: "File appears corrupted"
- ✅ No server calls for invalid files

#### **Test Case 8.3: Network Intermittent**
**Scenario**: Unstable internet connection

**Steps**:
1. Upload content with intermittent connectivity
2. Verify retry logic and draft fallback
3. Multiple attempts handled gracefully

**Expected Results**:
- ✅ Automatic retries with exponential backoff
- ✅ Draft saved if retries exhaust
- ✅ Progress preserved through reconnections

---

## 📱 TEST SUITE E: USER EXPERIENCE

### 9. **UI/UX Feedback Testing**

#### **Test Case 9.1: Progress Indicators**
**Scenario**: Visual feedback during operations

**Steps**:
1. Upload multiple images simultaneously
2. Observe all progress indicators
3. Verify status messages are clear

**Expected Results**:
- ✅ Compression progress: "Optimizing Image..."
- ✅ Upload progress: "Uploading 2/5 images..."
- ✅ Save progress: "Saving to server..."
- ✅ All feedback is user-friendly

#### **Test Case 9.2: Error Messaging**
**Scenario**: User-friendly error communications

**Steps**:
1. Trigger various error scenarios
2. Evaluate error message clarity
3. Test action buttons in error states

**Expected Results**:
- ✅ No technical jargon in user messages
- ✅ Actionable error solutions
- ✅ Appropriate message priorities

### 10. **Cross-Platform Testing**

#### **Test Case 10.1: Android Performance**
**Device**: Android device with varying specs

**Steps**:
1. Test all features on Android 8+ devices
2. Monitor resource usage patterns
3. Test with different OEM skins

#### **Test Case 10.2: iOS Compatibility**
**Device**: iOS device/simulator

**Steps**:
1. Verify all features work on iOS 12+
2. Test iOS-specific media handling
3. Verify Dark Mode compatibility

---

## 🧪 AUTOMATED TESTING RECOMMENDATIONS

### Integration Test Template

```dart
// test/integration/media_optimization_test.dart
void main() {
  test('Media compression reduces file size by 80%', () async {
    // Test compression logic
    final originalSize = await getFileSize(testImage);
    final compressed = await FileUploadService().optimizeImageSmartly(testImage);
    final finalSize = await getFileSize(compressed);

    expect(finalSize / originalSize, lessThan(0.20)); // 80% reduction
  });
}
```

### Recommended Test Commands
```bash
# Run specific test suites
flutter test test/unit/media_optimization_test.dart
flutter test test/integration/offline_drafts_test.dart

# Run with coverage
flutter test --coverage

# Device testing
flutter test integration_test/media_upload_flow_test.dart
```

---

## 📊 EXPECTED PERFORMANCE METRICS

### Target Benchmarks
- **Image Upload Speed**: < 30 seconds for 5MB→0.8MB compression
- **Gallery Load Time**: < 2 seconds for 50 images (cached)
- **Memory Usage**: Peak <300MB during batch operations
- **Offline Draft Access**: <100ms local SQLite queries
- **Auto-sync Speed**: < 5 minutes for typical draft queue

### Quality Assurance Standards
- **Crashes**: Zero unhandled exceptions in tested scenarios
- **Data Loss**: Zero data loss during network interruptions
- **User Experience**: All operations feel instant/snappy
- **Battery Impact**: < 15% battery drain during 1-hour heavy usage

---

## 🚀 DEPLOYMENT CHECKLIST

### Pre-Production Verification
- [ ] All test cases pass on target devices
- [ ] Performance metrics meet targets
- [ ] Error scenarios handled gracefully
- [ ] Offline functionality verified
- [ ] Media compression working as expected

### Production Monitoring
- [ ] Firebase Crashlytics monitoring active
- [ ] Performance monitoring dashboards set up
- [ ] Error tracking for media operations
- [ ] User feedback collection for optimization features

---

## 🔍 DEBUGGING TIPS

### Common Issues & Solutions

**Issue**: Images not compressing adequately
```
Solution: Check ImagePurpose enum usage in optimizeImageSmartly()
Network: Verify Firebase Storage quotas aren't exceeded
```

**Issue**: Drafts not auto-syncing
```
Solution: Check connectivity monitoring in OfflineDraftsService
Cause: Android/iOS battery optimization blocking background tasks
```

**Issue**: Gallery stuttering/slow scrolling
```
Solution: Verify LazyLoadingMediaWidget configuration
Cause: Preload distance too small or cache eviction too aggressive
```

---

## 📝 TESTING LOG TEMPLATE

**Test Session Report**

**Date**: ________________

**Device**: ________________

**App Version**: ________________

**Network Conditions**: ________________

**Test Results Summary**:
- ✅ Passed: ___
- ⚠️ Issues: ___
- ❌ Failed: ___

**Issues Found**:
1. [Description] [Severity: High/Med/Low] [Reproduction Steps]

**Performance Metrics**:
- Compression Rate: ____%
- Loading Speed: ____sec
- Memory Usage: ____MB

**Recommendations**: ________________

---

**🎯 MISSION CRITICAL**: Complete all test cases before production deployment. This comprehensive test suite ensures your enterprise-grade media optimization meets professional standards!

**💡 Pro Tip**: Run tests on both high-end and low-end devices to ensure consistent experience across all user devices.
