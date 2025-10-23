import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import '../../../../services/manifesto_likes_service.dart';
import '../../../../services/manifesto_poll_service.dart';

class ContentEngagementAnalyticsSection extends StatefulWidget {
  final Candidate candidateData;

  const ContentEngagementAnalyticsSection({
    super.key,
    required this.candidateData,
  });

  @override
  State<ContentEngagementAnalyticsSection> createState() =>
      _ContentEngagementAnalyticsSectionState();
}

class _ContentEngagementAnalyticsSectionState
    extends State<ContentEngagementAnalyticsSection> {
  // Real-time engagement metrics
  int _manifestoLikes = 0;
  int _pollParticipation = 0;
  int _manifestoComments = 0;

  // Stream subscriptions
  Stream<int>? _likesStream;
  Stream<Map<String, int>>? _pollStream;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  @override
  void dispose() {
    _likesStream = null;
    _pollStream = null;
    super.dispose();
  }

  void _initializeStreams() {
    final manifestoId = widget.candidateData.candidateId;

    // Likes stream
    _likesStream = ManifestoLikesService.getLikeCountStream(manifestoId);
    _likesStream?.listen((count) {
      if (mounted) {
        setState(() => _manifestoLikes = count);
      }
    });

    // Poll participation stream
    _pollStream = ManifestoPollService.getPollResultsStream(manifestoId);
    _pollStream?.listen((results) {
      if (mounted) {
        final totalVotes = results.values.fold(0, (sum, count) => sum + count);
        setState(() => _pollParticipation = totalVotes);
      }
    });

    // Get comments count from analytics data
    final analytics = widget.candidateData.analytics;
    _manifestoComments = analytics?.manifestoComments ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final analytics = widget.candidateData.analytics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.thumb_up, size: 28, color: Colors.red),
              const SizedBox(width: 12),
              const Text(
                'Content Engagement',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Real-time Engagement Cards
          Row(
            children: [
              Expanded(
                child: _buildRealtimeMetricCard(
                  title: 'Manifesto Likes',
                  value: '$_manifestoLikes',
                  icon: Icons.thumb_up,
                  color: Colors.red,
                  subtitle: 'Real-time likes',
                  isRealtime: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRealtimeMetricCard(
                  title: 'Poll Participation',
                  value: '$_pollParticipation',
                  icon: Icons.poll,
                  color: Colors.green,
                  subtitle: 'Total votes',
                  isRealtime: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Manifesto Comments',
                  value: '${analytics?.manifestoComments ?? 0}',
                  icon: Icons.comment,
                  color: Colors.blue,
                  subtitle: 'Total comments',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Content Rating',
                  value: _calculateContentRating(),
                  icon: Icons.star,
                  color: Colors.orange,
                  subtitle: 'Engagement score',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Engagement Breakdown
          _buildEngagementBreakdown(),

          const SizedBox(height: 24),

          // Engagement Tips
          _buildEngagementTips(),
        ],
      ),
    );
  }

  Widget _buildRealtimeMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required bool isRealtime,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: color),
                if (isRealtime) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementBreakdown() {
    final totalEngagement = _manifestoLikes + _pollParticipation + _manifestoComments;
    final likesPercentage = totalEngagement > 0 ? (_manifestoLikes / totalEngagement * 100).round() : 0;
    final pollsPercentage = totalEngagement > 0 ? (_pollParticipation / totalEngagement * 100).round() : 0;
    final commentsPercentage = totalEngagement > 0 ? (_manifestoComments / totalEngagement * 100).round() : 0;

    return Card(
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'Engagement Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (totalEngagement > 0) ...[
              _buildEngagementBar('Likes', likesPercentage, Colors.red),
              const SizedBox(height: 8),
              _buildEngagementBar('Polls', pollsPercentage, Colors.green),
              const SizedBox(height: 8),
              _buildEngagementBar('Comments', commentsPercentage, Colors.blue),
            ] else ...[
              Center(
                child: Text(
                  'No engagement data yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementBar(String label, int percentage, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.purple[800]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 35,
          child: Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementTips() {
    return Card(
      color: Colors.teal[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.teal[700]),
                const SizedBox(width: 8),
                Text(
                  'Engagement Tips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Create compelling manifesto content that resonates with voters'),
            _buildTipItem('Use polls to gather feedback and show you listen to voters'),
            _buildTipItem('Respond to comments to build personal connections'),
            _buildTipItem('Share success stories and community impact'),
            _buildTipItem('Post regularly to maintain voter interest'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: Colors.teal[700])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(fontSize: 14, color: Colors.teal[800]),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateContentRating() {
    final likes = _manifestoLikes;
    final comments = _manifestoComments;
    final polls = _pollParticipation;

    // Simple rating calculation based on engagement
    final score = (likes * 1) + (comments * 2) + (polls * 1.5);
    if (score >= 100) return 'Excellent';
    if (score >= 50) return 'Good';
    if (score >= 20) return 'Fair';
    if (score >= 5) return 'Basic';
    return 'Starting';
  }
}