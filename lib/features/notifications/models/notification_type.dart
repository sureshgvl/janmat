/// Enum representing different types of notifications in the app
enum NotificationType {
  // Chat & Communication
  newMessage,
  mention,
  groupChatUpdate,
  chatInvitation,

  // Candidate & Following
  newFollower,
  followerMilestone,
  candidateProfileUpdate,
  candidateProfileCreated,
  manifestoUpdate,
  manifestoShared,
  candidateNewPost,
  candidateOnline,

  // Campaign Milestones
  profileCompletionMilestone,
  manifestoCompletionMilestone,
  eventCreationMilestone,
  socialEngagementMilestone,
  campaignProgressMilestone,

  // Events & RSVPs
  eventReminder,
  newEvent,
  eventUpdate,
  rsvpConfirmation,

  // Polls & Voting
  newPoll,
  pollResult,
  pollDeadline,
  votingReminder,

  // Gamification & Achievements
  levelUp,
  badgeEarned,
  streakAchievement,
  pointsEarned,

  // System & Administrative
  appUpdate,
  securityAlert,
  profileReminder,
  electionReminder,

  // Social Interactions
  likeReceived,
  commentReceived,
  shareReceived,

  // Content & Feed
  contentUpdate,
  trendingTopic,
  personalizedRecommendation,
}

/// Extension to provide display names and descriptions for notification types
extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.newMessage:
        return 'New Message';
      case NotificationType.mention:
        return 'Mention';
      case NotificationType.groupChatUpdate:
        return 'Group Chat Update';
      case NotificationType.chatInvitation:
        return 'Chat Invitation';
      case NotificationType.newFollower:
        return 'New Follower';
      case NotificationType.followerMilestone:
        return 'Follower Milestone';
      case NotificationType.candidateProfileUpdate:
        return 'Profile Update';
      case NotificationType.candidateNewPost:
        return 'New Post';
      case NotificationType.candidateProfileCreated:
        return 'New Candidate';
      case NotificationType.manifestoUpdate:
        return 'Manifesto Update';
      case NotificationType.manifestoShared:
        return 'Manifesto Shared';
      case NotificationType.candidateOnline:
        return 'Candidate Online';
      case NotificationType.profileCompletionMilestone:
        return 'Profile Milestone';
      case NotificationType.manifestoCompletionMilestone:
        return 'Manifesto Milestone';
      case NotificationType.eventCreationMilestone:
        return 'Event Milestone';
      case NotificationType.socialEngagementMilestone:
        return 'Engagement Milestone';
      case NotificationType.campaignProgressMilestone:
        return 'Campaign Milestone';
      case NotificationType.eventReminder:
        return 'Event Reminder';
      case NotificationType.newEvent:
        return 'New Event';
      case NotificationType.eventUpdate:
        return 'Event Update';
      case NotificationType.rsvpConfirmation:
        return 'RSVP Confirmation';
      case NotificationType.newPoll:
        return 'New Poll';
      case NotificationType.pollResult:
        return 'Poll Result';
      case NotificationType.pollDeadline:
        return 'Poll Deadline';
      case NotificationType.votingReminder:
        return 'Voting Reminder';
      case NotificationType.levelUp:
        return 'Level Up';
      case NotificationType.badgeEarned:
        return 'Badge Earned';
      case NotificationType.streakAchievement:
        return 'Streak Achievement';
      case NotificationType.pointsEarned:
        return 'Points Earned';
      case NotificationType.appUpdate:
        return 'App Update';
      case NotificationType.securityAlert:
        return 'Security Alert';
      case NotificationType.profileReminder:
        return 'Profile Reminder';
      case NotificationType.electionReminder:
        return 'Election Reminder';
      case NotificationType.likeReceived:
        return 'Like Received';
      case NotificationType.commentReceived:
        return 'Comment Received';
      case NotificationType.shareReceived:
        return 'Share Received';
      case NotificationType.contentUpdate:
        return 'Content Update';
      case NotificationType.trendingTopic:
        return 'Trending Topic';
      case NotificationType.personalizedRecommendation:
        return 'Recommendation';
    }
  }

  String get category {
    switch (this) {
      case NotificationType.newMessage:
      case NotificationType.mention:
      case NotificationType.groupChatUpdate:
      case NotificationType.chatInvitation:
        return 'Chat';

      case NotificationType.newFollower:
      case NotificationType.followerMilestone:
      case NotificationType.candidateProfileUpdate:
      case NotificationType.candidateProfileCreated:
      case NotificationType.manifestoUpdate:
      case NotificationType.manifestoShared:
      case NotificationType.candidateNewPost:
      case NotificationType.candidateOnline:
        return 'Following';

      case NotificationType.eventReminder:
      case NotificationType.newEvent:
      case NotificationType.eventUpdate:
      case NotificationType.rsvpConfirmation:
        return 'Events';

      case NotificationType.newPoll:
      case NotificationType.pollResult:
      case NotificationType.pollDeadline:
      case NotificationType.votingReminder:
        return 'Polls';

      case NotificationType.levelUp:
      case NotificationType.badgeEarned:
      case NotificationType.streakAchievement:
      case NotificationType.pointsEarned:
      case NotificationType.profileCompletionMilestone:
      case NotificationType.manifestoCompletionMilestone:
      case NotificationType.eventCreationMilestone:
      case NotificationType.socialEngagementMilestone:
      case NotificationType.campaignProgressMilestone:
        return 'Achievements';

      case NotificationType.appUpdate:
      case NotificationType.securityAlert:
      case NotificationType.profileReminder:
      case NotificationType.electionReminder:
        return 'System';

      case NotificationType.likeReceived:
      case NotificationType.commentReceived:
      case NotificationType.shareReceived:
        return 'Social';

      case NotificationType.contentUpdate:
      case NotificationType.trendingTopic:
      case NotificationType.personalizedRecommendation:
        return 'Content';
    }
  }

  bool get isHighPriority {
    switch (this) {
      case NotificationType.securityAlert:
      case NotificationType.electionReminder:
      case NotificationType.eventReminder:
      case NotificationType.pollDeadline:
        return true;
      default:
        return false;
    }
  }
}