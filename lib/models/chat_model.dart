// Compatibility layer for chat models
// This file provides backward compatibility while migrating to the new feature-based structure
// TODO: Remove this file after all screens are migrated to use the new models directly

// Re-export from new locations for backward compatibility
export '../features/chat/models/chat_message.dart';
export '../features/chat/models/chat_room.dart';
export '../features/chat/models/poll.dart';
export '../features/chat/models/user_quota.dart';
