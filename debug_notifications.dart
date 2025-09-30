// Debug script to test Candidate Following Notifications
// Run this in debug console or as a temporary addition to your app

import 'package:flutter/material.dart';
import 'lib/services/notifications/candidate_following_notifications.dart';

class NotificationTester extends StatelessWidget {
  const NotificationTester({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Tester')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTestButton(
            'Test New Follower Notification',
            () => _testNewFollowerNotification(context),
          ),
          _buildTestButton(
            'Test Profile Update Notification',
            () => _testProfileUpdateNotification(context),
          ),
          _buildTestButton(
            'Test Profile View Spike Notification',
            () => _testProfileViewSpikeNotification(context),
          ),
          _buildTestButton(
            'Test Weekly Performance Notification',
            () => _testWeeklyPerformanceNotification(context),
          ),
          _buildTestButton(
            'Test Unfollow Notification',
            () => _testUnfollowNotification(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String title, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(title),
      ),
    );
  }

  Future<void> _testNewFollowerNotification(BuildContext context) async {
    try {
      final service = CandidateFollowingNotifications();

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending new follower notification...')),
      );

      await service.sendNewFollowerNotification(
        candidateId: 'test_candidate_123', // Replace with real candidate ID
        followerId: 'test_user_456', // Replace with real user ID
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ New follower notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _testProfileUpdateNotification(BuildContext context) async {
    try {
      final service = CandidateFollowingNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending profile update notification...')),
      );

      await service.sendProfileUpdateNotification(
        candidateId: 'test_candidate_123',
        updateType: 'bio',
        updateDescription: 'Updated campaign slogan for 2024 elections',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile update notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _testProfileViewSpikeNotification(BuildContext context) async {
    try {
      final service = CandidateFollowingNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending profile view spike notification...')),
      );

      await service.sendProfileViewSpikeNotification(
        candidateId: 'test_candidate_123',
        viewCount: 150,
        previousCount: 100,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile view spike notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _testWeeklyPerformanceNotification(BuildContext context) async {
    try {
      final service = CandidateFollowingNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending weekly performance notification...')),
      );

      await service.sendWeeklyContentPerformanceNotification('test_candidate_123');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Weekly performance notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _testUnfollowNotification(BuildContext context) async {
    try {
      final service = CandidateFollowingNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending unfollow notification...')),
      );

      await service.sendUnfollowNotification(
        candidateId: 'test_candidate_123',
        unfollowerId: 'test_user_456',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Unfollow notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }
}

// To use this tester, temporarily add this to your app's navigation:
// Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationTester()));

// Or add it as a debug menu option in your settings screen