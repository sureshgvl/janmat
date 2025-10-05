# Admin Panel - Highlight Feature Implementation

## Overview
This document outlines the admin panel changes required to support the highlight feature with a **clean product strategy**:

### 🎯 **Product Strategy: Clear Separation**
```
Free → Highlight (₹199-499) → Basic (₹999+) → Gold → Platinum
     ↑ Pure Visibility        ↑ Content Creation
```

- **Highlight Plan**: **Visibility-only** - Max 4 auto-rotating highlights per ward
- **Basic/Gold/Platinum**: **Full platform** - Manifesto, media, events, analytics

### 💰 **Pricing Strategy**
- **Affordable entry**: ₹199-499 (30-day) makes highlights accessible
- **Clear upgrade path**: Users can upgrade to full plans for content creation
- **Higher conversion**: Lower price point attracts more visibility-seeking candidates

## Changes Made

### 1. Plan Management Updates (`ManagePlansTab.tsx`)

#### Single Highlight Plan
```typescript
// Single Highlight Plan - Max 4 highlights per ward
{
  planId: "highlight_plan",
  name: "Highlight Plan",
  type: "highlight",
  pricing: {
    municipal_corporation: { 30: 299, 90: 699 },
    municipal_council: { 30: 249, 90: 599 },
    nagar_panchayat: { 30: 199, 90: 499 },
    zilla_parishad: { 30: 249, 90: 649 },
    panchayat_samiti: { 30: 199, 90: 549 },
    parliamentary: { 30: 499, 90: 1299 },
    assembly: { 30: 399, 90: 999 }
  },
  highlightFeatures: {
    maxHighlights: 4,  // Maximum 4 highlights per ward
    priority: 'normal',
    realTimeAnalytics: true,
    exportReports: true,
    customBranding: true
  }
}
```

#### Updated Plan Interface
```typescript
type Plan = {
  // ... existing fields
  highlightFeatures?: {
    maxHighlights: number
    priority: 'normal' | 'high' | 'urgent'
    realTimeAnalytics: boolean
    exportReports: boolean
    customBranding: boolean
  }
}
```

#### Added UI Button
- "Create Highlight Plan" button (indigo)
- Updated `loadTemplate` function to accept single highlight plan type

### 2. Existing Highlight Management (`ManageHighlightsTab.tsx`)

The `ManageHighlightsTab.tsx` component already exists and supports:
- Creating highlights for candidates
- Admin approval workflow
- Location-based filtering
- Package management (gold/platinum)
- Analytics tracking

#### Key Features:
- **Candidate Selection**: Filter by district/body/ward
- **Package Types**: Gold and Platinum packages
- **Placement Options**: Top Banner, Carousel
- **Priority Levels**: 1-10 priority system
- **Date Management**: Start/end date configuration
- **Approval Workflow**: Admin approval required before activation

## Database Schema Requirements

### Highlights Collection
```javascript
{
  highlightId: "hl_123456789",
  candidateId: "cand_456",
  type: "highlight",
  title: "Campaign Message",
  message: "Vote for development",
  imageUrl: "https://...",
  callToAction: "Learn More",
  districtId: "pune",
  bodyId: "pune_m_cop",
  wardId: "ward_17",
  locationKey: "pune_pune_m_cop_ward_17",
  package: "gold",
  priority: 8,
  startDate: Timestamp,
  endDate: Timestamp,
  active: false,
  approved: false,
  approvedBy: "admin_123",
  approvedAt: Timestamp,
  totalViews: 0,
  totalClicks: 0,
  uniqueViews: 0,
  uniqueClicks: 0,
  shares: 0,
  engagementRate: 0,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Plans Collection Updates
```javascript
{
  planId: "highlight_plan",
  name: "Highlight Plan",
  type: "highlight",
  pricing: {
    municipal_corporation: { 30: 299, 90: 699 },
    municipal_council: { 30: 249, 90: 599 },
    nagar_panchayat: { 30: 199, 90: 499 },
    zilla_parishad: { 30: 249, 90: 649 },
    panchayat_samiti: { 30: 199, 90: 549 },
    parliamentary: { 30: 499, 90: 1299 },
    assembly: { 30: 399, 90: 999 }
  },
  highlightFeatures: {
    maxHighlights: 4,  // Maximum 4 highlights per ward
    priority: "normal",
    realTimeAnalytics: true,
    exportReports: true,
    customBranding: true
  },
  isActive: true
}
```

## API Endpoints Required

### Existing Endpoints (Already Implemented)
- `GET /api/admin/highlights` - List highlights with filters
- `POST /api/admin/highlights` - Create highlight
- `PUT /api/admin/highlights/[id]` - Update highlight
- `DELETE /api/admin/highlights/[id]` - Delete highlight
- `GET /api/admin/candidates` - List candidates for selection

### Plan Endpoints (Already Implemented)
- `GET /api/plans` - List all plans
- `POST /api/admin/plans` - Create plan
- `PUT /api/admin/plans/[id]` - Update plan
- `DELETE /api/admin/plans/[id]` - Delete plan

## Admin Workflow

### 1. Plan Creation
1. Admin clicks "Create Highlight Plan"
2. Fills pricing for different election types (30-day and 90-day options)
3. Plan automatically configured with:
   - Max 4 highlights per ward
   - Normal priority placement
   - Real-time analytics and export reports
   - Custom branding support
4. Saves plan

### 2. Highlight Management
1. Admin navigates to Highlights tab
2. Filters highlights by status, package, location
3. Reviews pending highlights (max 4 per ward)
4. Approves or rejects highlights
5. Monitors performance metrics and auto-rotation

### 3. Candidate Subscription
1. Candidates purchase **affordable highlight plan** through mobile app (₹199-₹499)
2. Plans provide **pure visibility** - no content creation features
3. Candidates can create up to **4 highlights per ward**
4. Highlights **auto-rotate** in home screen carousel (4-second intervals)
5. **Clear upgrade path** to full Basic/Gold/Platinum plans for content creation

## Security Considerations

### Firestore Rules
```javascript
// Highlights - admin controlled
match /highlights/{highlightId} {
  allow read: if true;
  allow write: if request.auth != null &&
    exists(/databases/$(database)/documents/admins/$(request.auth.uid));
}

// Plans - admin controlled
match /plans/{planId} {
  allow read: if true;
  allow write: if request.auth != null &&
    exists(/databases/$(database)/documents/admins/$(request.auth.uid));
}
```

## Testing Checklist

### Plan Management
- [ ] Create Highlight Basic plan
- [ ] Create Highlight Premium plan
- [ ] Verify pricing for all election types
- [ ] Test plan activation/deactivation

### Highlight Management
- [ ] Create highlight for candidate
- [ ] Test location filtering
- [ ] Verify approval workflow
- [ ] Test package assignment
- [ ] Check analytics tracking

### Integration Testing
- [ ] Candidate purchases highlight plan (mobile app)
- [ ] Candidate creates highlight (mobile app)
- [ ] Admin approves highlight
- [ ] Highlight appears in carousel (mobile app)
- [ ] Analytics data flows correctly

## Deployment Steps

1. **Deploy Admin Panel Changes**
   - Update `ManagePlansTab.tsx` with new plan templates
   - Test plan creation functionality

2. **Deploy Mobile App Changes**
   - Update plan validation logic
   - Implement highlight creation UI
   - Update carousel to show highlights

3. **Database Migration**
   - Add highlight plans to plans collection
   - Ensure proper indexing on highlights collection

4. **Testing**
   - End-to-end testing of highlight workflow
   - Performance testing with multiple highlights
   - Analytics accuracy verification

## Monitoring & Analytics

### Admin Dashboard Metrics
- Total highlights created
- Approval rate
- Popular packages by election type
- Revenue from highlight plans
- Highlight performance analytics

### Key Metrics to Track
- Highlight creation rate
- Approval time
- Click-through rates
- Revenue per highlight
- Plan upgrade rates

This implementation provides a complete highlight management system for admins, with proper plan management, approval workflows, and analytics tracking.