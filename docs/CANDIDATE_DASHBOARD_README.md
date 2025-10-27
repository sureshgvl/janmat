# Candidate Dashboard Functionality

## Overview

The Candidate Dashboard is a comprehensive management interface for political candidates in the Janmat application. It allows candidates to manage their profile information, manifesto, achievements, media content, events, and highlights based on their subscription plan. The dashboard features a tabbed interface with role-based access control, ensuring that candidates can only access features appropriate to their plan tier.

## Architecture

The dashboard is structured using the Model-View-Controller (MVC) pattern with additional service layers:

### Directory Structure
```
lib/features/candidate/
├── controllers/              # GetX controllers for state management
├── models/                   # Data models for candidate-related entities
├── repositories/             # Data access layer for Firebase operations
├── screens/                  # Main dashboard screen with tab navigation
├── services/                 # Business logic services
└── widgets/                  # UI components divided into edit/view subdirectories
    ├── edit/                 # Editable widgets for dashboard tabs
    └── view/                 # Read-only view widgets
```

### Key Controllers
- **CandidateUserController**: Main controller managing candidate data, edited state, and user permissions
- **ManifestoController**: Handles manifesto-specific operations and saving
- **AchievementsController**: Manages achievement data and persistence
- **EventsController**: Controls event management and synchronization
- **MediaController**: Handles media uploads and gallery management
- **HighlightsController**: Manages highlight profiles and carousel content

## Tab System and Features

### Core Navigation
The dashboard uses a `TabController` with dynamically loaded tabs based on the user's subscription plan. Available tabs are determined at initialization by checking the user's plan features.

### Basic Info Tab (Always Available)
- Displays core candidate information (name, party, position, etc.)
- Provides basic profile overview
- Always visible regardless of subscription plan

### Manifesto Tab (Always Visible, Edit Based on Plan)
**Features:**
- Title and description management
- PDF document upload and display
- Promise list with categorized commitments
- Image and video media integration
- Voter interaction preview

**Functionality:**
- Edit mode with rich text input
- File upload with progress tracking
- Promise management with add/remove operations
- Preview mode showing how voters see the manifesto

**Technical Implementation:**
- Uses `ManifestoTabEdit` and `ManifestoTabView` widgets
- File uploads handled via `FileUploadService`
- Persistence through `ManifestoController.saveManifestoTab()`

### Achievements Tab (Gold/Platinum Plans)
**Features:**
- Educational background and certifications
- Professional accomplishments
- Awards and honors
- Political career milestones

**Functionality:**
- Multi-entry achievement management
- Image attachments for certificates/awards
- Categorization and prioritization
- Timeline display

**Technical Implementation:**
- Uses `AchievementsModel` for data structure
- `AchievementsTabEdit` for editing interface
- `AchievementsController` for data persistence

### Media Tab (Gold/Platinum Plans)
**Features:**
- Photo gallery management
- Video content uploads
- Image carousel implementation
- Media categorization

**Functionality:**
- Batch upload capabilities
- Image compression and optimization
- Gallery preview and organization
- CDN integration for delivery

### Highlights Tab (Gold/Platinum or Highlight Plans)
**Features:**
- Highlight reel management
- Carousel content creation
- Featured achievement display
- Quick-access profiles

**Functionality:**
- Multiple highlight profiles
- Image/video rotation
- Homepage integration
- Voter engagement tracking

### Contact Tab (Always Available)
**Features:**
- Contact information display
- Social media links
- Office addresses and phone numbers
- Communication preferences

### Events Tab (Platinum Plan Only)
**Features:**
- Event scheduling and management
- Location and date tracking
- Event descriptions and media
- RSVP and participation metrics

**Functionality:**
- Calendar integration
- Location services
- Media attachments
- Analytics tracking

**Technical Implementation:**
- Uses `EventsModel` with `EventData` structures
- `EventsController` for CRUD operations
- Map integration for location display

### Analytics Tab (Platinum Plan Only)
**Features:**
- Voter engagement metrics
- Profile view statistics
- Content performance analytics
- Demographic insights

**Technical Implementation:**
- Real-time data aggregation
- Firebase Analytics integration
- Custom dashboard widgets
- Data visualization components

## Plan-Based Access Control

### Subscription Tiers

#### Free Plan
- Basic Info: View only
- Manifesto: Read-only view
- Other tabs: Not accessible

#### Gold Plan
- Basic Info: View only
- Manifesto: Full edit access
- Achievements: Full management
- Media: Full gallery management
- Highlights: Access to highlight features
- Contact: View only
- Events: No access
- Analytics: No access

#### Platinum Plan
- Full access to all tabs including:
  - Events management
  - Advanced analytics
  - Unlimited highlights
  - Premium media features

#### Highlight Plans
- Limited to highlight management only
- Access to Highlights tab
- Basic Info for highlight context
- No full dashboard access

### Permission Checking
Access control is implemented through:
- `PlanService` for feature flag checking
- Firebase subscription document verification
- Dynamic tab loading at runtime
- UI element visibility based on permissions

## Edit Mode System

### Common Edit Pattern
All editable tabs follow a consistent edit workflow:

1. **View Mode**: Read-only display with Edit FAB
2. **Edit Mode**: Interactive form with validation
3. **Save/Cancel**: Floating action buttons for actions
4. **Progress Loading**: Stream-based progress updates during save operations

### File Upload Integration
- Pre-upload validation
- Progress streaming during upload
- Automatic URL replacement in data models
- Rollback capabilities on failure

### Data Persistence
- Optimistic UI updates
- Transaction-based saves
- Error handling with user feedback
- Data synchronization across tabs

## Technical Implementation Details

### State Management
- GetX for reactive state management
- Stream controllers for progress updates
- Global form keys for validation access
- Edited data separation from live data

### File Upload System
- Firebase Storage integration
- Supports images, PDFs, videos
- Automatic compression and optimization
- CDN delivery URLs

### Error Handling
- Comprehensive try-catch blocks
- User-friendly error messages via Get.snackbar
- Logging via AppLogger
- Graceful degradation on failures

### Performance Optimization
- Lazy loading of tab content
- Image caching with multi-level cache
- Efficient data fetching with Firebase
- Memory management for large media files

## API Integration

### Services Used
- **PlanService**: Subscription and permission management
- **FileUploadService**: Media upload handling
- **CandidateRepository**: Data persistence layer
- **FirebaseAuth**: User authentication
- **CloudFirestore**: Data storage

### Data Flow
1. UI actions trigger controller methods
2. Controllers coordinate with services
3. Services handle Firebase operations
4. Results propagated back through reactive streams
5. UI updates based on new state

## Security Considerations

- User authentication required for dashboard access
- Permission checks on all sensitive operations
- File upload validation and sanitization
- Secure Firebase rules for data access
- Audit logging for modification operations

## Future Enhancements & Optimizations

### Performance Improvements
- Enhanced lazy loading with skeleton placeholders for heavy media content
- Advanced caching strategies for achievements, highlights, and analytics data
- Background file upload queues with resumable transfers
- Video compression and size limits for faster loading

### User Experience Enhancements
- Real-time form validation with contextual tooltips and guidance
- Retry mechanisms for failed network operations and file uploads
- Dynamic plan upgrade handling without app restart
- Improved loading states with progress indicators

### Analytics & Insights
- Integration with `syncfusion_flutter_charts` or `fl_chart` for analytics visualization
- Cached data aggregation to reduce Firestore load
- Advanced metrics including engagement rates and demographic breakdowns
- Predictive analytics for voter interaction trends

### Advanced Features
- Real-time collaboration for multi-member campaign teams
- AI-powered content suggestions and optimization recommendations
- Social media integration with automated posting capabilities
- Automated voter engagement features with personalized communication
- Mobile-responsive design optimizations with adaptive layouts

### Testing & Quality Assurance
- Comprehensive unit tests for all controllers and service methods
- Widget tests for tab components (Manifesto, Achievements, Media, Events)
- Integration tests for file upload workflows and plan-based access control
- End-to-end testing for critical user journeys

## Dependencies

Key packages used:
- `get` for state management
- `firebase_auth` for authentication
- `cloud_firestore` for data storage
- `firebase_storage` for file uploads
- Flutter core packages for UI components

This documentation provides a comprehensive overview of the candidate dashboard functionality. For specific implementation details, refer to the individual controller and widget files.
