# Media View Refactoring Plan

## Current Situation
The `media_view.dart` file is 2800+ lines and contains multiple responsibilities. Several components have already been extracted, but the main file still needs significant refactoring.

## Already Extracted Components
✅ `delete_operations.dart` - Delete functionality
✅ `empty_state.dart` - Empty state UI
✅ `engagement_section.dart` - Like/Comment engagement section
✅ `loading_dialog.dart` - Loading dialogs
✅ `media_content.dart` - Media display content
✅ `media_helpers.dart` - Helper utilities
✅ `post_card.dart` - Post card component
✅ `post_composer.dart` - Post composer
✅ `youtube_player.dart` - YouTube player

## Remaining Responsibilities to Extract

### 1. Media Data Processing (`media_data_processor.dart`)
**Current Location**: `_getMediaItems()` method and related parsing logic
**Responsibilities**:
- Parse media data from candidate object
- Handle both old and new media formats
- Sort media items by date
- MediaItem model conversions

### 2. Navigation Handler (`media_navigation_handler.dart`)
**Current Location**: Dialog and navigation methods
**Responsibilities**:
- Handle post creation navigation (`_showAddPostDialog`)
- Handle post editing navigation (`_showEditPostDialog`)
- Handle image gallery navigation (`_showImageGallery`)
- Dialog management

### 3. Engagement Controller (`engagement_controller.dart`)
**Current Location**: Like/comment methods in main class
**Responsibilities**:
- Like button state management
- Optimistic UI updates for likes
- Comment sheet management
- User interaction handling
- Loading states for engagement actions

### 4. Media Comments Manager (`media_comments_manager.dart`)
**Current Location**: Comment-related methods
**Responsibilities**:
- Comments display in bottom sheets
- Comment input handling
- Comments data retrieval
- Comments UI rendering

### 5. Storage Utilities (`media_storage_utils.dart`)
**Current Location**: `_extractStoragePath` method
**Responsibilities**:
- Extract storage paths from Firebase URLs
- File cleanup utilities
- Storage-related helper methods

### 6. UI Building Components (`media_ui_builders.dart`)
**Current Location**: Various UI building methods
**Responsibilities**:
- Header construction
- Button builders
- Layout helpers
- UI styling utilities

## SOLID Principles Applied

### Single Responsibility Principle (SRP)
- Each file will have one clear purpose
- Media data processing is separate from UI rendering
- Engagement logic is isolated from navigation

### Open/Closed Principle (OCP)
- Components can be extended without modifying existing code
- New media types can be added to processor without changing UI
- Engagement features can be enhanced independently

### Liskov Substitution Principle (LSP)
- All components will follow consistent interfaces
- Components can be replaced with implementations that follow same contracts

### Interface Segregation Principle (ISP)
- Small, focused interfaces for each responsibility
- No component is forced to depend on methods it doesn't use

### Dependency Inversion Principle (DIP)
- High-level modules don't depend on low-level modules
- Both depend on abstractions (interfaces)

## Implementation Order
1. Extract MediaDataProcessor
2. Extract MediaStorageUtils
3. Extract MediaNavigationHandler
4. Extract MediaCommentsManager
5. Extract EngagementController
6. Extract MediaUIBuilders
7. Clean up main MediaTabView class
8. Update imports and test functionality

## Expected Result
- Main `media_view.dart` reduced to ~500 lines
- Better maintainability and testability
- Clear separation of concerns
- Easier to add new features
