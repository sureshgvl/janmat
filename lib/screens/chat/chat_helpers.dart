import 'package:flutter/material.dart';
import '../../models/chat_model.dart';

// Helper functions for chat room display logic
class ChatHelpers {
  // Get room color based on room type/id
  static Color getRoomColor(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      return Colors.blue.shade600; // Blue for ward chats
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return Colors.green.shade600; // Green for candidate chats
    } else {
      return Colors.purple.shade600; // Purple for other chats
    }
  }

  // Get room icon based on room type/id
  static IconData getRoomIcon(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      return Icons.location_city; // City icon for ward chats
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return Icons.person; // Person icon for candidate chats
    } else {
      return Icons.group; // Group icon for other chats
    }
  }

  // Get display title for room
  static String getRoomDisplayTitle(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      // For ward rooms, title is the city name
      return chatRoom.title ?? 'City Chat';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      // For candidate rooms, title is candidate name
      return chatRoom.title ?? 'Candidate Chat';
    } else {
      return chatRoom.title ?? chatRoom.roomId;
    }
  }

  // Get display subtitle for room
  static String getRoomDisplaySubtitle(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      // For ward rooms, subtitle is the ward name
      return chatRoom.description ?? 'Ward Discussion';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      // For candidate rooms, subtitle is description
      return chatRoom.description ?? 'Official Updates';
    } else {
      return chatRoom.description ?? 'Group Chat';
    }
  }

  // Get default room title (fallback)
  static String getDefaultRoomTitle(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      // Format: ward_cityId_wardId
      final parts = chatRoom.roomId.split('_');
      if (parts.length >= 3) {
        final cityId = parts[1];
        final wardId = parts[2];
        return 'Ward $wardId (${cityId.toUpperCase()}) Chat';
      }
      return 'Ward Chat';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return 'Candidate Discussion';
    } else {
      return chatRoom.roomId;
    }
  }

  // Check if user can create rooms
  static bool canCreateRooms(String? userRole) {
    return userRole != null && (userRole == 'candidate' || userRole == 'admin');
  }

  // Check if quota warning should be shown
  static bool shouldShowQuotaWarning(bool canSendMessage) {
    return !canSendMessage;
  }
}