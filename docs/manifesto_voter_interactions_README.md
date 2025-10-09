# Manifesto Voter Interactions - Implementation Guide

## Overview

The Manifesto Voter Interactions system enables citizens to engage with candidate manifestos through polls, comments, and likes. This feature promotes civic engagement by allowing voters to express opinions, participate in discussions, and show support for manifesto content.

## Architecture

### Core Components

#### Backend Services
- **ManifestoPollService**: Handles poll voting, results streaming, and vote validation
- **ManifestoCommentsService**: Manages comments, replies, and comment likes
- **ManifestoLikesService**: Handles manifesto likes and like counts
- **ManifestoCacheService**: Provides offline data caching and synchronization

#### UI Components
- **ManifestoPollSection**: Interactive poll voting interface
- **ManifestoCommentsSection**: Threaded comments with replies and likes
- **ManifestoContentBuilder**: Main container integrating all interactions

### Data Flow

```
User Interaction → UI Component → Service → Cache → Firestore
                                      ↓
                            Offline Queue (if offline)
```

## Features

### 🗳️ Poll System
- **Multiple Choice Options**: Development, Transparency, Youth Education, Women Safety
- **Real-time Results**: Live vote counting and percentage display
- **Vote Validation**: Prevents duplicate voting, requires authentication
- **Offline Support**: Votes cached locally and synced when online

### 💬 Comment System
- **Threaded Comments**: Support for replies and nested discussions
- **Comment Likes**: Users can like comments and replies
- **Anonymous Posting**: Comments posted as "Anonymous Voter"
- **Real-time Updates**: Live comment streaming
- **XP Rewards**: Users earn XP for commenting

### ❤️ Like System
- **Manifesto Likes**: Direct support for manifesto content
- **Comment Likes**: Like individual comments and replies
- **Real-time Counters**: Live like count updates
- **User State Tracking**: Shows user's like status

### 🔄 Offline Support
- **Local Caching**: All interactions work offline
- **Background Sync**: Automatic synchronization when online
- **Conflict Resolution**: Handles concurrent edits
- **Sync Indicators**: Visual feedback for sync status

## Implementation Status

### ✅ Completed
- Backend services with offline support
- Individual UI components (PollSection, CommentsSection)
- Data models and caching mechanisms
- Authentication integration
- XP and gamification integration

### 🚧 In Progress
- Integration into ManifestoContentBuilder
- Manifesto likes UI implementation
- Analytics tracking
- Notification system

### 📋 Planned
- Comment moderation tools
- Advanced analytics dashboard
- Bulk operations for admins
- Export functionality

## API Reference

### ManifestoPollService

```dart
// Vote on a poll
Future<void> voteOnPoll(String manifestoId, String userId, String option)

// Get poll results stream
Stream<Map<String, int>> getPollResultsStream(String manifestoId)

// Check if user voted
Future<bool> hasUserVoted(String manifestoId, String userId)

// Get user's vote
Future<String?> getUserVote(String manifestoId, String userId)
```

### ManifestoCommentsService

```dart
// Add comment
Future<void> addComment(String userId, String manifestoId, String text, {String? parentId})

// Get comments stream
Stream<List<CommentModel>> getComments(String manifestoId)

// Toggle comment like
Future<bool> toggleCommentLike(String userId, String commentId)
```

### ManifestoLikesService

```dart
// Toggle manifesto like
Future<bool> toggleLike(String userId, String manifestoId)

// Get like count stream
Stream<int> getLikeCountStream(String manifestoId)

// Check if user liked
Future<bool> hasUserLiked(String userId, String manifestoId)
```

## UI Components

### ManifestoPollSection

Displays interactive poll with options and real-time results.

**Props:**
- `manifestoId`: String (required)
- `currentUserId`: String? (optional)

**Features:**
- Radio button selection
- Vote count display
- Loading states
- Error handling

### ManifestoCommentsSection

Full-featured comment system with threading.

**Props:**
- `manifestoId`: String (required)
- `currentUserId`: String? (optional)

**Features:**
- Comment input with character limit
- Threaded replies
- Like/unlike functionality
- Expandable comment list
- Real-time updates

## Integration Guide

### Adding to Manifesto Tab

1. **Import Components**
```dart
import '../widgets/view/manifesto_poll_section.dart';
import '../widgets/view/manifesto_comments_section.dart';
```

2. **Replace Placeholder Section**
```dart
// In ManifestoContentBuilder, replace the placeholder buttons with:
if (widget.showVoterInteractions) ...[
  const SizedBox(height: 24),
  ManifestoPollSection(
    manifestoId: _getManifestoId(widget.candidate),
    currentUserId: widget.currentUserId,
  ),
  const SizedBox(height: 24),
  ManifestoCommentsSection(
    manifestoId: _getManifestoId(widget.candidate),
    currentUserId: widget.currentUserId,
  ),
],
```

3. **Add Manifesto ID Helper**
```dart
String _getManifestoId(Candidate candidate) {
  return candidate.candidateId ?? candidate.userId ?? 'unknown';
}
```

### Adding Manifesto Likes

1. **Import Service**
```dart
import '../../../../services/manifesto_likes_service.dart';
```

2. **Add Like Button to Title Section**
```dart
// Near the share button in manifesto title
StreamBuilder<int>(
  stream: ManifestoLikesService.getLikeCountStream(manifestoId),
  builder: (context, likeSnapshot) {
    final likeCount = likeSnapshot.data ?? 0;
    return StreamBuilder<bool>(
      stream: Stream.fromFuture(
        widget.currentUserId != null
            ? ManifestoLikesService.hasUserLiked(widget.currentUserId!, manifestoId)
            : Future.value(false)
      ),
      builder: (context, userLikeSnapshot) {
        final isLiked = userLikeSnapshot.data ?? false;
        return IconButton(
          onPressed: () => _toggleManifestoLike(),
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.grey,
          ),
          tooltip: isLiked ? 'Unlike Manifesto' : 'Like Manifesto',
        );
      },
    );
  },
),
```

## Configuration

### Poll Options

Currently configured with 4 options:
- `development`: Development & Infrastructure
- `transparency`: Transparency & Governance
- `youth_education`: Youth Education
- `women_safety`: Women Safety

Options can be modified in `ManifestoPollSection._buildPollOption()`.

### Comment Settings

- **Max Length**: 500 characters
- **Anonymous Display**: All comments show as "Anonymous Voter"
- **Threading**: Supports 1 level of replies
- **XP Reward**: 5 XP per comment

## Analytics & Monitoring

### Events Tracked
- Poll votes
- Comment creation
- Comment likes
- Manifesto likes
- User engagement time

### Performance Metrics
- Response time for interactions
- Offline sync success rate
- Cache hit rates
- Error rates

## Security Considerations

### Authentication
- All interactions require authenticated users
- Firebase Auth integration
- User ID validation

### Data Validation
- Input sanitization for comments
- Vote validation to prevent duplicates
- Rate limiting for spam prevention

### Privacy
- Anonymous comment display
- No personal data in public interactions
- Secure data transmission

## Testing Strategy

### Unit Tests
- Service method testing
- Component rendering tests
- State management tests

### Integration Tests
- End-to-end interaction flows
- Offline/online transitions
- Multi-user scenarios

### Performance Tests
- Load testing with multiple users
- Offline functionality testing
- Memory usage monitoring

## Deployment Checklist

- [ ] Backend services deployed
- [ ] UI components integrated
- [ ] Offline caching tested
- [ ] Authentication flows verified
- [ ] Analytics tracking enabled
- [ ] Performance benchmarks met
- [ ] Security review completed
- [ ] User acceptance testing passed

## Future Enhancements

### Phase 2 Features
- Comment moderation dashboard
- Advanced poll types (multiple choice, ranking)
- Comment threading beyond 1 level
- Rich text comments with formatting
- Image/video attachments

### Phase 3 Features
- AI-powered content moderation
- Sentiment analysis on comments
- Trend analysis for poll results
- Integration with social media sharing
- Push notifications for interactions

## Troubleshooting

### Common Issues

**Poll votes not updating**
- Check internet connection
- Verify user authentication
- Check Firebase permissions

**Comments not loading**
- Verify manifesto ID format
- Check Firestore security rules
- Test cache clearing

**Likes not syncing**
- Check offline queue
- Verify sync service status
- Test manual sync

### Debug Tools

Enable debug logging:
```dart
AppLogger.common('Debug: Manifesto interaction');
```

Check cache status:
```dart
final cacheStats = await ManifestoCacheService.getCacheStats();
```

## Support

For technical support or questions:
- Check existing issues in the repository
- Review service documentation
- Contact the development team

---

*Last updated: October 2025*
*Version: 1.0.0*