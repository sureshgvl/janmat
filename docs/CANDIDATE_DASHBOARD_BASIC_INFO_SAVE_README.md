# Candidate Dashboard - Basic Info Saving Implementation

## Overview

This document provides a comprehensive guide to the basic info saving implementation in the candidate dashboard. The basic info tab serves as the reference implementation for save operations across all other dashboard tabs (manifesto, achievements, etc.). It demonstrates a robust pattern for handling file uploads, data persistence, progress tracking, and error handling.

## Architecture Overview

### Components Involved

1. **Screen**: `CandidateDashboardBasicInfo` - Main screen with edit/save logic
2. **Controller**: `BasicInfoController` - Handles save operations
3. **Edit Widget**: `BasicInfoEdit` - Form UI for editing
4. **View Widget**: `BasicInfoTabView` - Read-only display
5. **Model**: `BasicInfoModel` - Data structure
6. **Repository**: Managed through controller dependencies

### Data Flow

```
User Click Save → Loading Dialog → File Uploads → Data Validation → Save to Firebase → Update UI → Success Feedback
                                      ↓
                             Progress Updates via Stream
```

## Implementation Details

### Core Screen Structure

#### State Management
```dart
class _CandidateDashboardBasicInfoState extends State<CandidateDashboardBasicInfo> {
  final BasicInfoController basicInfoController = Get.put(BasicInfoController());
  final CandidateUserController candidateUserController = CandidateUserController.to;

  bool isEditing = false;
  bool isSaving = false;
}
```

#### Edit Mode Initialization
When entering edit mode, the system properly initializes the edited data:
```dart
onPressed: () {
  setState(() => isEditing = true);
  candidateUserController.editedData.value = candidateUserController.candidateData.value;
},
```
**Critical Note**: This initialization ensures that the controller has access to the data being edited. Without this, save operations will fail.

### Save Operation Implementation

#### Stream-Based Progress Tracking
The save operation uses a `StreamController` for real-time progress updates:

```dart
final messageController = StreamController<String>();
messageController.add('Preparing to save basic info...');

// Show loading dialog with message stream
LoadingDialog.show(
  context,
  initialMessage: 'Preparing to save basic info...',
  messageStream: messageController.stream,
);
```

#### Complete Save Workflow
```dart
try {
  // 1. Extract edited data (fallback to original if not edited)
  BasicInfoModel basicInfo = candidateUserController
      .editedData.value?.basicInfo ??
      candidateUserController.candidateData.value!.basicInfo!;

  // 2. Get candidate data (edited or original)
  final candidate = candidateUserController.editedData.value ??
      candidateUserController.candidateData.value!;

  // 3. Execute save operation
  final success = await basicInfoController.saveBasicInfoTabWithCandidate(
    candidateId: candidate.candidateId,
    basicInfo: basicInfo,
    candidate: candidate,
    onProgress: (message) => messageController.add(message),
  );

  // 4. Handle success
  if (success) {
    messageController.add('Basic info saved successfully!');
    await Future.delayed(const Duration(milliseconds: 800));

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      setState(() => isEditing = false);
      // Show success snackbar
    }
  } else {
    // Handle failure
  }

} catch (e) {
  // Handle exceptions
} finally {
  await messageController.close(); // Clean up stream
}
```

### Controller Implementation

#### Save Method Structure
```dart
Future<bool> saveBasicInfoTabWithCandidate({
  required String candidateId,
  required BasicInfoModel basicInfo,
  required Candidate candidate,
  Function(String)? onProgress,
}) async {
  try {
    onProgress?.call('Saving basic info...');

    // Implementation details...

    if (success) {
      onProgress?.call('Basic info saved successfully!');
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}
```

#### Repository Layer Path Consistency
The basic info controller ensures all data operations use the correct Firebase document path:
```
states/maharashtra/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/candidates/{candidateId}
```

This path structure is critical and must be consistent across all tabs (manifesto, achievements, events, etc.).

### Error Handling Pattern

#### Comprehensive Error Coverage
```dart
try {
  // Main save logic
} catch (e) {
  if (context.mounted) {
    Navigator.of(context).pop(); // Close loading dialog
    SnackbarUtils.showError('An error occurred: $e');
  }
} finally {
  await messageController.close(); // Always clean up stream
}
```

### Loading Dialog Integration

#### Stream-Based Progress Display
The `LoadingDialog.show()` method accepts:
- `context`: Build context for dialog display
- `initialMessage`: Starting message
- `messageStream`: Stream of progress updates

#### Usage Pattern
```dart
LoadingDialog.show(
  context,
  initialMessage: 'Initial message...',
  messageStream: messageController.stream,
);
```

### Data Model Handling

#### Edited vs Original Data
The implementation distinguishes between edited and original data:
- **Edited Data**: From `candidateUserController.editedData.value`
- **Original Data**: From `candidateUserController.candidateData.value`
- **Fallback Pattern**: Use edited data if available, otherwise use original

#### Local State Synchronization
After successful save, the local controller data is updated:
```dart
controller.candidateData.value = candidate.copyWith(
  basicInfo: basicInfo, // Update specific field
);
```

## File Upload Integration

While basic info doesn't handle file uploads directly (unlike manifesto tab), the pattern is established for extension:

### Upload Pattern Reference
```dart
// From manifesto implementation - reference pattern
final uploadSuccess = await _manifestoSectionKey.currentState!.uploadPendingFiles();
if (!uploadSuccess) {
  // Handle upload failure
  return;
}
// Proceed with save after successful uploads
```

### Validation Integration
File uploads include pre-upload and post-upload validation:
- File size limits (configurable)
- File type restrictions
- Size warnings for large files
- Automatic compression optimization

## Debugging and Logging

### Comprehensive Logging
```dart
AppLogger.candidate(
  '🔄 [BASIC_INFO_SAVE] Starting basic info save operation',
  tag: 'DASHBOARD_SAVE',
);
```

### Log Patterns
- `🔄` - Operation start
- `📝` - Data processing
- `📤` - File uploads
- `✅` - Success
- `❌` - Errors
- `🎉` - Completion

### Firebase Document Verification
After save operations, verify data in Firebase at:
```
states/maharashtra/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/candidates/{candidateId}
```

## Common Issues and Solutions

### Issue 1: "editedData.value is null"
```
Error: ❌ editedData.value is null - cannot update basic info
Solution: Ensure editedData is initialized when entering edit mode
```

### Issue 2: Path Inconsistencies
```
Problem: Wrong Firebase document path (districts/... vs states/maharashtra/...)
Solution: Always use states/maharashtra/... path for consistency
```

### Issue 3: Loading Dialog Persistence
```
Problem: Loading dialog remains open after save
Solution: Always call Navigator.pop() and close stream controller
```

### Issue 4: Data Not Persisting
```
Problem: Firebase writes succeed but UI doesn't update
Solution: Update controller.candidateData.value after successful save
```

## Implementation Template for Other Tabs

Based on this pattern, here's the template for implementing save functionality in other dashboard tabs:

### Screen Level Implementation
```dart
// 1. Add stream controller and loading dialog
final messageController = StreamController<String>();
LoadingDialog.show(context, messageStream: messageController.stream);

// 2. Handle file uploads first (if applicable)
final uploadSuccess = await _tabKey.currentState!.uploadPendingFiles();
if (!uploadSuccess) return;

// 3. Get data and save
final data = _tabKey.currentState!.getData();
final success = await tabController.saveMethod(data, messageController.add);

// 4. Handle result and cleanup
if (success) {
  controller.candidateData.update((val) => val?.copyWith(field: data));
  setState(() => isEditing = false);
}
await messageController.close();
```

### Controller Level Implementation
```dart
Future<bool> saveTabMethod(data, Function(String) onProgress) async {
  try {
    onProgress('Saving...');

    // Save logic here using repository

    if (success) {
      onProgress('Saved successfully!');
      return true;
    }
  } catch (e) {
    Logger.error('Save failed', error: e);
    return false;
  }
}
```

## Testing Guidelines

### Unit Tests
- Controller save methods
- Repository data operations
- Stream controller lifecycle

### Integration Tests
- Full save workflow from UI to Firebase
- File upload scenarios
- Error condition handling

### Manual Testing Checklist
- [ ] Enter edit mode (editedData initialized)
- [ ] Save with valid data
- [ ] Save with invalid data
- [ ] Cancel operation
- [ ] File uploads (if applicable)
- [ ] Network failure scenarios
- [ ] Firebase data verification

## Performance Considerations

### Stream Management
- Always close `StreamController` in finally blocks
- Avoid memory leaks from unclosed streams
- Proper cleanup in widget dispose methods

### Firebase Operations
- Use batch operations for multiple document updates
- Implement retry logic for network failures
- Cache frequently accessed data

### Memory Management
- Clean up temporary files after uploads
- Dispose image widgets with caching
- Monitor memory usage for large file operations

## Future Enhancements

### Advanced Progress Tracking
- File upload progress percentages
- Step-by-step operation progress
- Estimated completion time

### Offline Support
- Queue operations for offline execution
- Conflict resolution on reconnection
- Local caching with sync

### Analytics Integration
- Save operation metrics
- User behavior tracking
- Performance monitoring

## Dependencies

Required packages for this implementation:
- `get: ^4.6.5` - State management
- `cloud_firestore: ^4.8.4` - Firebase integration
- `firebase_auth: ^4.6.3` - User authentication

Local dependencies:
- `LoadingDialog` from widgets/loading_overlay.dart
- `AppLogger` from utils/app_logger.dart
- Various controller and model classes

## Conclusion

The basic info saving implementation provides a robust, scalable pattern for dashboard save operations. It emphasizes proper state management, comprehensive error handling, user feedback, and data consistency. This pattern should be followed exactly for all new dashboard tab implementations to ensure reliability and maintainability.

For troubleshooting specific issues, always check the logs with tags `DASHBOARD_SAVE` and verify Firebase document paths and data structure.
