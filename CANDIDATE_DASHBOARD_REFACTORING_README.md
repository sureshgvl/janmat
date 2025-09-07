# Candidate Dashboard Refactoring Documentation

## 📋 Overview

The candidate dashboard has been completely refactored from a single 736-line monolithic file into a modular, maintainable architecture. This refactoring improves code organization, reusability, and developer experience.

## 🎯 Key Changes

### Before vs After
- **Before**: Single file with 736 lines
- **After**: 297 lines in main file + 8 specialized components + 2 custom hooks
- **Reduction**: 60% reduction in main file size
- **Architecture**: Modular component-based structure

## 📁 New File Structure

```
src/
├── app/candidate/
│   └── page.tsx                    # Main orchestrator (297 lines)
├── components/candidate/
│   ├── BasicInfoSection.tsx        # Basic info display (58 lines)
│   ├── ProfileSection.tsx          # Photo upload & bio (118 lines)
│   ├── AchievementsSection.tsx     # Achievements management (75 lines)
│   ├── ManifestoSection.tsx        # Manifesto & PDF (89 lines)
│   ├── ContactSection.tsx          # Contact info (136 lines)
│   ├── MediaSection.tsx            # Images & videos (95 lines)
│   ├── EventsSection.tsx           # Events/announcements (82 lines)
│   └── HighlightSection.tsx        # Premium highlight (33 lines)
└── hooks/
    ├── usePhotoUpload.ts           # Photo upload logic (40 lines)
    └── useCandidateData.ts         # Data management (130 lines)
```

## 🧩 Component Breakdown

### 1. BasicInfoSection
**Purpose**: Displays candidate's basic information
**Props**:
```typescript
interface BasicInfoSectionProps {
  candidateData: CandidateData
  getPartySymbol: (partyName: string) => string
}
```
**Features**:
- Candidate photo (circular, 96px)
- Name and party information
- Party symbol display
- Ward and city information

### 2. ProfileSection
**Purpose**: Handles photo upload and bio editing
**Props**:
```typescript
interface ProfileSectionProps {
  candidateData: CandidateData
  editedData: CandidateData | null
  isEditing: boolean
  isUploading: boolean
  uploadError: string | null
  onPhotoUpload: (file: File) => Promise<void>
  onPhotoUrlChange: (url: string) => void
  onBioChange: (bio: string) => void
}
```
**Features**:
- File upload from device
- URL input fallback
- Upload progress indication
- Error handling
- Bio text editing

### 3. AchievementsSection
**Purpose**: Manages candidate achievements
**Props**:
```typescript
interface AchievementsSectionProps {
  candidateData: CandidateData
  editedData: CandidateData | null
  isEditing: boolean
  onAchievementsChange: (achievements: string[]) => void
}
```

### 4. ManifestoSection
**Purpose**: Handles manifesto content and PDF
**Props**:
```typescript
interface ManifestoSectionProps {
  candidateData: CandidateData
  editedData: CandidateData | null
  isEditing: boolean
  onManifestoChange: (manifesto: string) => void
  onManifestoPdfChange: (pdfUrl: string) => void
}
```

### 5. ContactSection
**Purpose**: Manages contact information and social media
**Props**:
```typescript
interface ContactSectionProps {
  candidateData: CandidateData
  editedData: CandidateData | null
  isEditing: boolean
  onContactChange: (field: string, value: string) => void
  onSocialChange: (field: string, value: string) => void
}
```

### 6. MediaSection
**Purpose**: Gallery for images and videos
**Props**:
```typescript
interface MediaSectionProps {
  candidateData: CandidateData
  editedData: CandidateData | null
  isEditing: boolean
  onImagesChange: (images: string[]) => void
  onVideosChange: (videos: string[]) => void
}
```

### 7. EventsSection
**Purpose**: Upcoming events and announcements
**Props**:
```typescript
interface EventsSectionProps {
  candidateData: CandidateData
  editedData: CandidateData | null
  isEditing: boolean
  onEventsChange: (events: any[]) => void
}
```

### 8. HighlightSection
**Purpose**: Premium highlight toggle
**Props**:
```typescript
interface HighlightSectionProps {
  candidateData: any
  editedData: any
  isEditing: boolean
  onHighlightChange: (highlight: boolean) => void
}
```

## 🎣 Custom Hooks

### usePhotoUpload Hook
**Purpose**: Handles photo upload functionality
**Returns**:
```typescript
{
  uploadPhoto: (file: File, userId: string) => Promise<string | null>
  isUploading: boolean
  uploadError: string | null
  setUploadError: (error: string | null) => void
}
```

### useCandidateData Hook
**Purpose**: Manages candidate data and API interactions
**Returns**:
```typescript
{
  candidateData: CandidateData | null
  editedData: CandidateData | null
  setEditedData: (data: CandidateData | null) => void
  isLoading: boolean
  isPaid: boolean
  updateExtraInfo: (field: string, value: unknown) => void
  updateContact: (field: string, value: string) => void
  updateSocial: (field: string, value: string) => void
  updatePhoto: (photoUrl: string) => void
  saveExtraInfo: () => Promise<boolean>
}
```

## 🚀 Usage Examples

### Using Components
```tsx
import BasicInfoSection from "@/components/candidate/BasicInfoSection"
import ProfileSection from "@/components/candidate/ProfileSection"

// In your component
<BasicInfoSection
  candidateData={candidateData}
  getPartySymbol={getPartySymbol}
/>

<ProfileSection
  candidateData={candidateData}
  editedData={editedData}
  isEditing={isEditing}
  isUploading={isUploading}
  uploadError={uploadError}
  onPhotoUpload={handlePhotoUpload}
  onPhotoUrlChange={updatePhoto}
  onBioChange={(bio) => updateExtraInfo("bio", bio)}
/>
```

### Using Hooks
```tsx
import { usePhotoUpload } from "@/hooks/usePhotoUpload"
import { useCandidateData } from "@/hooks/useCandidateData"

export default function MyComponent() {
  const { uploadPhoto, isUploading, uploadError } = usePhotoUpload()
  const { candidateData, updateExtraInfo, saveExtraInfo } = useCandidateData()

  const handleUpload = async (file: File) => {
    const photoUrl = await uploadPhoto(file, userId)
    if (photoUrl) {
      // Handle success
    }
  }

  return (
    // Your component JSX
  )
}
```

## 🔧 API Changes

### New API Endpoint
- **POST** `/api/upload-photo`
- **Purpose**: Upload candidate photos to Firebase Storage
- **Body**: FormData with `photo` (File) and `userId` (string)
- **Response**: `{ success: boolean, url: string, fileName: string }`

### Updated API Endpoints
- **POST** `/api/update-candidate-extra-info` - Now accepts `photo` field
- **POST** `/api/create-user` - Now accepts optional `photo` field

## 🎨 UI/UX Features

### Photo Upload
- **File Input**: Direct upload from device
- **URL Input**: Alternative URL input method
- **Progress**: Upload progress indication
- **Error Handling**: Clear error messages
- **Fallback**: Default image when photo unavailable

### Party Symbols
- **Dynamic Loading**: Symbols loaded from `parties.json`
- **Fallback**: Default symbol for unknown parties
- **Responsive**: Proper sizing and positioning

### Internationalization
- **Multi-language**: English and Marathi support
- **New Keys**: Added photo-related translations
- **Consistent**: All components use translation keys

## 🔒 Security & Permissions

### Firebase Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow all authenticated users to read/write (temporary)
    match /candidate-photos/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
    // Public read access for displaying images
    match /{allPaths=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

**Note**: Consider implementing more restrictive rules for production:
```javascript
match /candidate-photos/{userId}/{allPaths=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

## 🧪 Testing

### Component Testing
Each component can be tested independently:
```typescript
import { render } from '@testing-library/react'
import BasicInfoSection from '@/components/candidate/BasicInfoSection'

const mockData = { /* mock candidate data */ }
render(<BasicInfoSection candidateData={mockData} getPartySymbol={() => ''} />)
```

### Hook Testing
```typescript
import { renderHook } from '@testing-library/react-hooks'
import { usePhotoUpload } from '@/hooks/usePhotoUpload'

const { result } = renderHook(() => usePhotoUpload())
```

## 🚨 Important Notes

### Breaking Changes
1. **Component Structure**: Old monolithic component replaced with modular structure
2. **Prop Requirements**: New components require specific props
3. **Hook Dependencies**: Components now depend on custom hooks

### Migration Guide
1. **Update Imports**: Replace old component imports with new modular imports
2. **Add Props**: Ensure all required props are passed to components
3. **Hook Integration**: Use custom hooks for data management
4. **Styling**: Verify responsive design works across all screen sizes

### Performance Considerations
- **Code Splitting**: Components are automatically code-split
- **Bundle Size**: Smaller initial bundle due to modular structure
- **Re-rendering**: Optimized with proper prop drilling

## 📈 Benefits

### Developer Experience
- ✅ **60% reduction** in main file size
- ✅ **Modular architecture** for easy maintenance
- ✅ **Clear separation** of concerns
- ✅ **Reusable components** and hooks
- ✅ **Better testing** capabilities

### Code Quality
- ✅ **TypeScript support** with proper interfaces
- ✅ **Consistent patterns** across components
- ✅ **Error handling** and loading states
- ✅ **Internationalization** support
- ✅ **Responsive design** maintained

### Maintainability
- ✅ **Single responsibility** principle
- ✅ **Easy debugging** with focused components
- ✅ **Future-proof** architecture
- ✅ **Scalable** for new features

## 🆘 Troubleshooting

### Common Issues
1. **Missing Props**: Ensure all required props are passed
2. **Hook Dependencies**: Verify hooks are used within React components
3. **Type Errors**: Check TypeScript interfaces match component props
4. **Styling Issues**: Verify Tailwind classes are properly applied

### Debug Tips
1. **Console Logs**: Check browser console for error messages
2. **Network Tab**: Verify API calls are successful
3. **Component Props**: Use React DevTools to inspect component props
4. **Firebase Console**: Check storage uploads in Firebase console

## 📞 Support

For questions about this refactoring:
1. Refer to component documentation above
2. Check existing component implementations
3. Review custom hook usage examples
4. Test components individually

---

**Refactoring Completed**: September 7, 2025
**Maintained By**: Development Team
**Version**: 2.0.0