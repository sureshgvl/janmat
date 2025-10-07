import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';

// Helper functions for chat room display logic
class ChatHelpers {
  // Get room color based on room type/id
  static Color getRoomColor(ChatRoom chatRoom) {
    if (chatRoom.type == 'private') {
      return Colors.teal.shade600; // Teal for private chats
    } else if (chatRoom.roomId.startsWith('ward_')) {
      return Colors.blue.shade600; // Blue for ward chats
    } else if (chatRoom.roomId.startsWith('area_')) {
      return Colors.orange.shade600; // Orange for area chats
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return Colors.green.shade600; // Green for candidate chats
    } else {
      return Colors.purple.shade600; // Purple for other chats
    }
  }

  // Get room icon based on room type/id
  static IconData getRoomIcon(ChatRoom chatRoom) {
    if (chatRoom.type == 'private') {
      return Icons.person; // Person icon for private chats
    } else if (chatRoom.roomId.startsWith('ward_')) {
      return Icons.location_city; // City icon for ward chats
    } else if (chatRoom.roomId.startsWith('area_')) {
      return Icons.home; // Home icon for area chats
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return Icons.campaign; // Campaign icon for candidate chats
    } else {
      return Icons.group; // Group icon for other chats
    }
  }

  // Get display title for room
  static String getRoomDisplayTitle(ChatRoom chatRoom) {
    if (chatRoom.type == 'private') {
      // For private rooms, show generic title in list view
      // Individual chat screen will show the other user's name
      return 'Private Chat';
    } else if (chatRoom.roomId.startsWith('ward_')) {
      // For ward rooms, title is the city name
      return chatRoom.title ?? 'City Chat';
    } else if (chatRoom.roomId.startsWith('area_')) {
      // For area rooms, title is area name
      return chatRoom.title ?? 'Area Chat';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      // For candidate rooms, title is candidate name
      return chatRoom.title ?? 'Candidate Chat';
    } else {
      return chatRoom.title ?? chatRoom.roomId;
    }
  }

  // Get display subtitle for room
  static String getRoomDisplaySubtitle(ChatRoom chatRoom) {
    if (chatRoom.type == 'private') {
      // For private rooms, subtitle is "Private conversation"
      return chatRoom.description ?? 'Private conversation';
    } else if (chatRoom.roomId.startsWith('ward_')) {
      // For ward rooms, subtitle is the ward name
      return chatRoom.description ?? 'Ward Discussion';
    } else if (chatRoom.roomId.startsWith('area_')) {
      // For area rooms, subtitle is area discussion
      return chatRoom.description ?? 'Area Discussion';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      // For candidate rooms, subtitle is description
      return chatRoom.description ?? 'Official Updates';
    } else {
      return chatRoom.description ?? 'Group Chat';
    }
  }

  // Get default room title (fallback)
  static String getDefaultRoomTitle(ChatRoom chatRoom) {
    if (chatRoom.type == 'private') {
      return 'Private Chat';
    } else if (chatRoom.roomId.startsWith('ward_')) {
      // Format: ward_districtId_bodyId_wardId
      final parts = chatRoom.roomId.split('_');
      if (parts.length >= 4) {
        final districtId = parts[1];
        final bodyId = parts[2];
        final wardId = parts[3];
        return 'Ward $wardId (${bodyId.toUpperCase()}) Chat';
      }
      return 'Ward Chat';
    } else if (chatRoom.roomId.startsWith('area_')) {
      // Format: area_districtId_bodyId_wardId_areaId
      final parts = chatRoom.roomId.split('_');
      if (parts.length >= 5) {
        final districtId = parts[1];
        final bodyId = parts[2];
        final wardId = parts[3];
        final areaId = parts[4];
        return 'Area $areaId (Ward $wardId) Chat';
      }
      return 'Area Chat';
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

