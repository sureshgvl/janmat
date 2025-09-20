# Admin Highlights Management System

This README provides comprehensive guidance for administrators to manage candidate highlights that appear in the mobile app's home screen sections 1 and 2 (Platinum Banner and Highlight Carousel).

## Overview

The highlights system allows administrators to create and manage premium visibility for candidates through two main placements:

1. **Platinum Banner** - Top banner section with exclusive placement
2. **Highlight Carousel** - Rotating carousel of featured candidates

## UI Design Guidelines

### Visual Design Principles
- **Clear Hierarchy**: Use proper typography scales and spacing
- **Attractive Aesthetics**: Modern gradients, shadows, and rounded corners
- **Responsive Layout**: Adaptive sizing for different screen sizes
- **Profile Pictures**: Always display candidate profile images prominently
- **Consistent Branding**: Use app color scheme and typography

### Banner Section UI
- **Background**: Campaign image or gradient fallback
- **Profile Picture**: Circular avatar (60px) with white border
- **Content Layout**: Left-aligned text with right-aligned CTA button
- **Typography**: Bold candidate name, lighter party name
- **Responsive**: Scales from mobile to tablet sizes

### Carousel Section UI
- **Card Design**: 280px width with rounded corners and shadows
- **Profile Overlay**: 50px circular avatar in bottom-left
- **Background**: Campaign image with gradient overlay
- **Content**: Candidate name, party, and CTA button
- **Animation**: Smooth horizontal scrolling with scale effects

### Mobile Responsiveness
- **Breakpoint**: 320px - 768px for mobile/tablet
- **Scaling**: Images and text scale proportionally
- **Touch Targets**: Minimum 44px for buttons
- **Spacing**: Consistent 16px margins and padding

## Firebase Collections

### `highlights` Collection Structure

Each highlight document contains the following fields:

```json
{
  "highlightId": "string (auto-generated)",
  "candidateId": "string (candidate's user ID)",
  "wardId": "string",
  "districtId": "string",
  "bodyId": "string",
  "locationKey": "string (composite: district_body_ward)",
  "package": "string (gold/platinum)",
  "placement": "array (top_banner, carousel, or both)",
  "priority": "number (1-10, higher = more priority)",
  "startDate": "timestamp",
  "endDate": "timestamp",
  "active": "boolean",
  "exclusive": "boolean (true = no rotation, always shown)",
  "rotation": "boolean (true = rotates with others)",
  "lastShown": "timestamp (auto-updated)",
  "views": "number (auto-incremented)",
  "clicks": "number (auto-incremented)",
  "imageUrl": "string (optional)",
  "candidateName": "string",
  "party": "string",
  "createdAt": "timestamp (auto-generated)"
}
```

## Admin Interface Requirements

### 1. Highlights Management Dashboard

#### Main Features:
- List all existing highlights with filtering
- Create new highlights
- Edit existing highlights
- Activate/Deactivate highlights
- View analytics (views, clicks)

#### Required UI Components:

**Highlights List Table:**
- Columns: Candidate Name, Package, Placement, Priority, Status, Dates, Actions
- Filters: By district, status, package type
- Search: By candidate name or ID
- Pagination: 20 items per page

**Create/Edit Highlight Form:**
- Candidate selection dropdown (populated from users collection)
- Package selection (Gold/Platinum)
- Placement checkboxes (Banner, Carousel)
- Priority slider (1-10)
- Date range picker (Start Date, End Date)
- **Campaign Cover Photo Upload**: Background image for highlight (optional)
- **Profile Picture**: Auto-displayed from candidate's profile (required)
- **Profile Cover Photo**: Auto-fetched for reference (stored in candidates collection)
- Location fields (auto-populate from candidate data)
- Exclusive toggle
- Live preview with responsive layout

### 2. Candidate Selection Interface

#### Features:
- Search candidates by name, party, or location
- Filter by role (must be 'candidate')
- Display candidate profile info
- Show existing highlights for selected candidate

#### Required Data Fetch:
```javascript
// Get candidates for dropdown
const candidates = await db.collection('users')
  .where('role', '==', 'candidate')
  .orderBy('name')
  .get();
```

### 3. Location Management

#### Auto-population Logic:
```javascript
// When candidate selected, populate location fields
const candidateData = await db.collection('users')
  .doc(selectedCandidateId)
  .get();

const locationData = {
  districtId: candidateData.districtId,
  bodyId: candidateData.bodyId,
  wardId: candidateData.wardId
};
```

## Step-by-Step Admin Workflow

### Creating a New Highlight

1. **Access Admin Panel**
   - Navigate to Highlights Management section
   - Click "Create New Highlight"

2. **Select Candidate**
   - Search and select the candidate from dropdown
   - System auto-populates location data
   - Verify candidate information

3. **Configure Highlight Details**
   - Choose package type (Gold/Platinum)
   - Select placement(s):
     - Banner only
     - Carousel only
     - Both banner and carousel
   - Set priority (1-10)
   - Set start and end dates
   - **Upload campaign cover photo** (optional - for highlight background)
   - **Profile picture automatically displayed** from candidate's profile
   - **Profile cover photo available** for reference in candidates collection
   - Toggle exclusive mode if needed

4. **Review and Save**
   - Preview how highlight will appear
   - Validate all required fields
   - Save to Firebase

### Managing Existing Highlights

1. **View Highlights List**
   - Filter by status, package, location
   - Sort by priority, creation date, or expiry

2. **Edit Highlight**
   - Click edit button on highlight row
   - Modify any fields except highlightId
   - Update saves automatically

3. **Activate/Deactivate**
   - Toggle active status
   - System updates `active` field in Firebase

4. **Monitor Performance**
   - View views and clicks metrics
   - Track engagement over time

## Firebase Operations

### Creating Highlight Document

```javascript
const createHighlight = async (highlightData) => {
  const highlightId = `hl_${Date.now()}`;
  const locationKey = `${highlightData.districtId}_${highlightData.bodyId}_${highlightData.wardId}`;

  const highlightDoc = {
    highlightId,
    candidateId: highlightData.candidateId,
    wardId: highlightData.wardId,
    districtId: highlightData.districtId,
    bodyId: highlightData.bodyId,
    locationKey,
    package: highlightData.package,
    placement: highlightData.placement,
    priority: highlightData.priority,
    startDate: new Date(highlightData.startDate),
    endDate: new Date(highlightData.endDate),
    active: true,
    exclusive: highlightData.exclusive || false,
    rotation: !highlightData.exclusive,
    lastShown: null,
    views: 0,
    clicks: 0,
    imageUrl: highlightData.imageUrl,
    candidateName: highlightData.candidateName,
    party: highlightData.party,
    createdAt: new Date()
  };

  await db.collection('highlights').doc(highlightId).set(highlightDoc);
  return highlightId;
};
```

### Updating Highlight Status

```javascript
const updateHighlightStatus = async (highlightId, active) => {
  await db.collection('highlights')
    .doc(highlightId)
    .update({ active });
};
```

### Fetching Highlights for Admin

```javascript
const getHighlightsForAdmin = async (filters = {}) => {
  let query = db.collection('highlights');

  if (filters.districtId) {
    query = query.where('districtId', '==', filters.districtId);
  }

  if (filters.active !== undefined) {
    query = query.where('active', '==', filters.active);
  }

  if (filters.package) {
    query = query.where('package', '==', filters.package);
  }

  const snapshot = await query
    .orderBy('createdAt', 'desc')
    .limit(50)
    .get();

  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
};
```

## Validation Rules

### Required Fields:
- candidateId
- wardId, districtId, bodyId
- package
- placement (at least one)
- startDate, endDate
- candidateName

### Business Logic Validation:
- End date must be after start date
- Priority must be 1-10
- Package must be 'gold' or 'platinum'
- Location data must match candidate's location
- Platinum package gets higher default priority

### Date Validation:
- Start date cannot be in the past (unless reactivating)
- End date must be at least 1 day after start date
- System should warn about expiring highlights

## Analytics and Reporting

### Key Metrics to Track:
- Total active highlights
- Views per highlight
- Clicks per highlight
- Click-through rate (CTR)
- Highlights by package type
- Highlights by location

### Sample Analytics Query:

```javascript
const getHighlightAnalytics = async () => {
  const highlights = await db.collection('highlights')
    .where('active', '==', true)
    .get();

  const analytics = highlights.docs.map(doc => {
    const data = doc.data();
    return {
      highlightId: doc.id,
      candidateName: data.candidateName,
      package: data.package,
      views: data.views,
      clicks: data.clicks,
      ctr: data.views > 0 ? (data.clicks / data.views) * 100 : 0
    };
  });

  return analytics;
};
```

## Error Handling

### Common Error Scenarios:
1. **Candidate not found** - Validate candidate exists before creating
2. **Location mismatch** - Ensure candidate location matches highlight location
3. **Date conflicts** - Check for overlapping exclusive highlights
4. **Image upload failures** - Handle storage upload errors
5. **Permission errors** - Ensure admin has proper access

### Error Messages:
- "Candidate not found in database"
- "Location data mismatch with candidate profile"
- "End date must be after start date"
- "Maximum priority highlights reached for this location"
- "Image upload failed, please try again"

## Image Management System

The app uses three types of images for candidates:

### 1. Profile Picture (Small Avatar)
**Collection**: `users`
**Field**: `profileImageUrl`
**Usage**: Displayed in highlights, posts, and profile sections

```json
{
  "userId": "candidate_user_id",
  "name": "Candidate Name",
  "profileImageUrl": "https://storage.example.com/profile.jpg",
  "role": "candidate"
}
```

### 2. Profile Cover Photo (Large Banner)
**Collection**: `candidates`
**Field**: `coverPhoto`
**Usage**: Facebook-style cover photo for candidate profile page

```json
{
  "candidateId": "candidate_id",
  "name": "Candidate Name",
  "coverPhoto": "https://storage.example.com/cover-banner.jpg",
  "photo": "https://storage.example.com/profile.jpg"
}
```

### 3. Campaign Cover Photo (Highlight Background)
**Collection**: `highlights`
**Field**: `imageUrl`
**Usage**: Background image for banner and carousel highlights

```json
{
  "highlightId": "hl_123",
  "candidateId": "candidate_id",
  "imageUrl": "https://storage.example.com/campaign-poster.jpg",
  "package": "platinum"
}
```

## Image Requirements & Best Practices

### Profile Pictures:
- **Field**: `profileImageUrl` (users collection)
- **Size**: 200x200px minimum, 400x400px recommended
- **Format**: Square aspect ratio, JPG/PNG/WebP
- **Usage**: Highlights, posts, comments, profile avatars

### Profile Cover Photos:
- **Field**: `coverPhoto` (candidates collection)
- **Size**: 1200x400px recommended (3:1 aspect ratio)
- **Format**: Wide banner format, JPG/PNG/WebP
- **Usage**: Candidate profile page header

### Campaign Cover Photos:
- **Field**: `imageUrl` (highlights collection)
- **Size**: 800x600px minimum for banner, 400x300px for carousel
- **Format**: Landscape orientation, JPG/PNG/WebP
- **Usage**: Highlight backgrounds, campaign visuals

## Admin Image Management Checklist

### Profile Pictures:
- [ ] Ensure all candidates have `profileImageUrl` in users collection
- [ ] Verify URLs are accessible and images load properly
- [ ] Implement fallback person icon for missing images
- [ ] Test image display in highlights and posts

### Profile Cover Photos:
- [ ] Upload cover photos to candidates collection (`coverPhoto` field)
- [ ] Ensure 3:1 aspect ratio for best display
- [ ] Test display on candidate profile pages
- [ ] Provide upload interface in candidate profile management

### Campaign Cover Photos:
- [ ] Upload campaign images when creating highlights
- [ ] Use high-quality, relevant campaign visuals
- [ ] Ensure images are optimized for mobile display
- [ ] Test display in both banner and carousel placements

## Firebase Storage Recommendations

### File Organization:
```
firebase-storage/
├── profiles/
│   ├── {userId}_profile.jpg
│   └── {userId}_cover.jpg
└── campaigns/
    └── {highlightId}_campaign.jpg
```

### Upload Process:
1. **Profile Pictures**: Upload to `profiles/` folder
2. **Cover Photos**: Upload to `profiles/` folder with `_cover` suffix
3. **Campaign Images**: Upload to `campaigns/` folder
4. **Generate URLs**: Get download URLs and store in respective collection fields

### Image Optimization:
- [ ] Compress images for web (80-90% quality)
- [ ] Resize to recommended dimensions before upload
- [ ] Use WebP format for better compression
- [ ] Implement lazy loading for better performance

## Security Considerations

### Access Control:
- Only admin users can create/edit highlights
- Validate admin permissions before operations
- Log all highlight creation/modification activities

### Data Validation:
- Sanitize all input data
- Validate image URLs and file types
- Prevent XSS in candidate names and party names

## API Integration (Optional)

If building a REST API for the admin panel:

### Endpoints:
- `GET /api/highlights` - List highlights with filters
- `POST /api/highlights` - Create new highlight
- `PUT /api/highlights/:id` - Update highlight
- `DELETE /api/highlights/:id` - Delete highlight
- `GET /api/highlights/analytics` - Get analytics data

### Request/Response Examples:

**Create Highlight:**
```json
POST /api/highlights
{
  "candidateId": "user123",
  "package": "platinum",
  "placement": ["top_banner", "carousel"],
  "priority": 10,
  "startDate": "2024-12-20T00:00:00Z",
  "endDate": "2024-12-31T23:59:59Z",
  "imageUrl": "https://storage.example.com/image.jpg"
}
```

This comprehensive system will allow administrators to effectively manage candidate visibility in the mobile app through an intuitive web interface.