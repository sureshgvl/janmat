import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import '../../../../services/manifesto_likes_service.dart';
import '../../../../services/manifesto_poll_service.dart';
import '../../../../services/analytics_export_service.dart';
import '../../../../widgets/charts/follower_growth_chart.dart';

class AnalyticsTabView extends StatefulWidget {
  final Candidate candidate;
  final bool isOwnProfile;

  const AnalyticsTabView({
    super.key,
    required this.candidate,
    this.isOwnProfile = false,
  });

  @override
  State<AnalyticsTabView> createState() => _AnalyticsTabViewState();
}

class _AnalyticsTabViewState extends State<AnalyticsTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Real-time engagement metrics
  int _manifestoLikes = 0;
  int _pollParticipation = 0;

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
    final manifestoId = widget.candidate.candidateId;

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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final analytics = widget.candidate.extraInfo?.analytics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analytics Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        color: Colors.blue.shade600,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analytics Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your campaign performance and voter engagement',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _exportAnalytics,
                      icon: const Icon(Icons.download, color: Colors.blue),
                      tooltip: 'Export Analytics Data',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Key Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Profile Views',
                  value: '${analytics?.profileViews ?? 0}',
                  icon: Icons.visibility,
                  color: Colors.blue,
                  subtitle: 'Total profile visits',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Manifesto Views',
                  value: '${analytics?.manifestoViews ?? 0}',
                  icon: Icons.description,
                  color: Colors.green,
                  subtitle: 'Manifesto document views',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Engagement Rate',
                  value:
                      '${analytics?.engagementRate?.toStringAsFixed(1) ?? '0.0'}%',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                  subtitle: 'Voter interaction rate',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Followers',
                  value: '${widget.candidate.followersCount}',
                  icon: Icons.people,
                  color: Colors.purple,
                  subtitle: 'Total followers',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Manifesto Likes',
                  value: '$_manifestoLikes',
                  icon: Icons.thumb_up,
                  color: Colors.red,
                  subtitle: 'Total likes on manifesto',
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // Empty space for balance
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Poll Participation',
                  value: '$_pollParticipation',
                  icon: Icons.poll,
                  color: Colors.green,
                  subtitle: 'Total poll votes',
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // Empty space for balance
            ],
          ),

          const SizedBox(height: 20),

          // Follower Growth Chart
          FollowerGrowthChart(
            growthData: analytics?.followerGrowth ?? [],
            isLoading: false,
          ),

          const SizedBox(height: 20),

          // Top Performing Content
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.star,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Top Performing Content',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (analytics?.topPerformingContent != null) ...[
                  // Display top performing content if available
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Text(
                      'Top performing content analysis will be displayed here',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1f2937)),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Content performance analytics will be available once you have published content and gathered engagement data.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Demographics
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.people_alt,
                        color: Colors.teal.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Voter Demographics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (analytics?.demographics != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: const Text(
                      'Demographic insights will be displayed here',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1f2937)),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Demographic data will be available as more voters interact with your profile.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _exportAnalytics() async {
    try {
      await AnalyticsExportService().shareAnalyticsData(widget.candidate, format: 'csv');
    } catch (e) {
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required MaterialColor color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

