# Firestore Schema Documentation - Manifesto Likes and Comments System

## Overview
This document outlines the Firestore database schema for the manifesto likes and comments system in the Janmat application. The system allows users to like manifestos and comment on them, with additional support for liking individual comments.

## Collections Structure

### 1. `likes` Collection
Stores likes for manifestos.

**Document Structure:**
```json
{
  "id": "string (Firestore auto-generated)",
  "userId": "string (User ID who liked)",
  "postId": "string (Manifesto ID being liked)",
  "createdAt": "timestamp (ISO 8601 string)"
}
```

**Field Definitions:**
- `id`: Auto-generated Firestore document ID
- `userId`: ID of the user who performed the like action
- `postId`: ID of the manifesto being liked
- `createdAt`: Timestamp when the like was created

**Indexes:**
- Composite index on `(userId, postId)` for efficient duplicate checking
- Index on `postId` for counting likes per manifesto

### 2. `comments` Collection
Stores comments on manifestos.

**Document Structure:**
```json
{
  "id": "string (Firestore auto-generated)",
  "userId": "string (User ID who commented)",
  "postId": "string (Manifesto ID being commented on)",
  "text": "string (Comment content)",
  "createdAt": "timestamp (ISO 8601 string)"
}
```

**Field Definitions:**
- `id`: Auto-generated Firestore document ID
- `userId`: ID of the user who wrote the comment
- `postId`: ID of the manifesto being commented on
- `text`: The actual comment text content
- `createdAt`: Timestamp when the comment was created

**Indexes:**
- Index on `postId` for querying comments by manifesto
- Composite index on `(postId, createdAt)` for ordered comment retrieval

### 3. `comment_likes` Collection
Stores likes for individual comments.

**Document Structure:**
```json
{
  "id": "string (Firestore auto-generated)",
  "userId": "string (User ID who liked the comment)",
  "postId": "string (Comment ID being liked)",
  "createdAt": "timestamp (ISO 8601 string)"
}
```

**Field Definitions:**
- `id`: Auto-generated Firestore document ID
- `userId`: ID of the user who liked the comment
- `postId`: ID of the comment being liked (note: here postId refers to comment ID)
- `createdAt`: Timestamp when the comment like was created

**Indexes:**
- Composite index on `(userId, postId)` for efficient duplicate checking
- Index on `postId` for counting likes per comment

## Data Relationships

```
Manifesto (external reference)
├── likes (collection)
│   └── {likeId} -> LikeModel
└── comments (collection)
    └── {commentId} -> CommentModel
        └── likes (comment_likes collection)
            └── {commentLikeId} -> LikeModel
```

## Security Rules

### Likes Collection (`likes/{likeId}`)
```javascript
match /likes/{likeId} {
  // Allow authenticated users to read all likes (for counting)
  allow read: if request.auth != null;

  // Allow users to create/delete their own likes
  allow create: if request.auth != null &&
    request.auth.uid == request.resource.data.userId;

  allow delete: if request.auth != null &&
    request.auth.uid == resource.data.userId;
}
```

### Comments Collection (`comments/{commentId}`)
```javascript
match /comments/{commentId} {
  // Allow authenticated users to read all comments
  allow read: if request.auth != null;

  // Allow users to create their own comments
  allow create: if request.auth != null &&
    request.auth.uid == request.resource.data.userId;

  // Allow users to update/delete their own comments
  allow update, delete: if request.auth != null &&
    request.auth.uid == resource.data.userId;
}
```

### Comment Likes Collection (`comment_likes/{likeId}`)
```javascript
match /comment_likes/{likeId} {
  // Allow authenticated users to read all comment likes (for counting)
  allow read: if request.auth != null;

  // Allow users to create/delete their own comment likes
  allow create: if request.auth != null &&
    request.auth.uid == request.resource.data.userId;

  allow delete: if request.auth != null &&
    request.auth.uid == resource.data.userId;
}
```

## Usage Patterns

### Liking a Manifesto
1. Check if user already liked: Query `likes` where `userId == currentUserId` and `postId == manifestoId`
2. If exists: Delete the document
3. If not exists: Create new document with userId, postId, createdAt

### Adding a Comment
1. Create new document in `comments` collection with userId, postId, text, createdAt
2. Firestore auto-generates the ID

### Liking a Comment
1. Check if user already liked: Query `comment_likes` where `userId == currentUserId` and `postId == commentId`
2. If exists: Delete the document
3. If not exists: Create new document with userId, postId (commentId), createdAt

### Getting Like Count
- Query count of documents in `likes` where `postId == manifestoId`

### Getting Comments
- Query `comments` where `postId == manifestoId`, ordered by `createdAt` descending

## Performance Considerations

- Use real-time listeners for like counts and comments to keep UI updated
- Implement pagination for comments if volume is high
- Consider composite indexes for efficient queries
- Monitor read/write operations for cost optimization

## Migration Notes

- Existing data should be migrated to use these collection structures
- Ensure all queries in the application use the correct field names
- Update any existing security rules to match the new patterns