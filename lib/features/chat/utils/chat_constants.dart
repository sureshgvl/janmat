class ChatConstants {
  // Message limits
  static const int maxMessageLength = 4096;
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;

  // Cache settings
  static const Duration messageCacheValidity = Duration(minutes: 5);
  static const Duration repositoryCacheValidity = Duration(minutes: 15);
  static const int maxMessagesPerRoom = 1000;

  // Media settings
  static const int imageQuality = 80;
  static const int videoThumbnailQuality = 70;
  static const Duration mediaCacheAge = Duration(days: 30);

  // UI settings
  static const double messageBubbleMaxWidth = 0.75;
  static const double inputMaxHeight = 0.4;
  static const int inputMinLines = 1;
  static const int inputMaxLines = 4;

  // Recording settings
  static const Duration maxRecordingDuration = Duration(minutes: 5);
  static const int recordingSampleRate = 44100;

  // Poll settings
  static const int maxPollOptions = 10;
  static const Duration defaultPollDuration = Duration(days: 7);

  // Quota settings
  static const int defaultDailyLimit = 20;
  static const int premiumExtraQuota = 50;

  // Room types
  static const String roomTypePublic = 'public';
  static const String roomTypePrivate = 'private';

  // Message types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeAudio = 'audio';
  static const String messageTypePoll = 'poll';

  // File extensions
  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
  static const List<String> supportedVideoExtensions = [
    'mp4',
    'mov',
    'avi',
    'mkv',
  ];
  static const List<String> supportedAudioExtensions = [
    'mp3',
    'wav',
    'aac',
    'm4a',
  ];

  // Firebase collection names
  static const String collectionChats = 'chats';
  static const String collectionUsers = 'users';
  static const String collectionUserQuotas = 'user_quotas';
  static const String collectionReportedMessages = 'reported_messages';

  // Storage paths
  static const String storageChatMedia = 'chat_media';
  static const String storageUserPhotos = 'user_photos';

  // Error messages
  static const String errorMessageTooLong = 'Message is too long';
  static const String errorFileTooLarge = 'File is too large';
  static const String errorUnsupportedFileType = 'Unsupported file type';
  static const String errorNetworkError = 'Network error occurred';
  static const String errorQuotaExceeded = 'Message quota exceeded';
  static const String errorPermissionDenied = 'Permission denied';

  // Success messages
  static const String successMessageSent = 'Message sent successfully';
  static const String successFileUploaded = 'File uploaded successfully';
  static const String successPollCreated = 'Poll created successfully';
}

