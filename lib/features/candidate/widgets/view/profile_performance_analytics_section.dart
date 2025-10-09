import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import '../../../../services/realtime_analytics_service.dart';

class ProfilePerformanceAnalyticsSection extends StatefulWidget {
  final Candidate candidateData;

  const ProfilePerformanceAnalyticsSection({
    super.key,
    required this.candidateData,
  });

  @override
  State<ProfilePerformanceAnalyticsSection> createState() => _ProfilePerformanceAnalyticsSectionState();
}

class _ProfilePerformanceAnalyticsSectionState extends State<ProfilePerformanceAnalyticsSection> {
  final RealtimeAnalyticsService _analyticsService = RealtimeAnalyticsService();

  // Real-time data streams
  late Stream<int> _profileViewsStream;
  late Stream<int> _manifestoViewsStream;
  late Stream<double> _engagementRateStream;

  // Current values
  int _profileViews = 0;
  int _manifestoViews = 0;
  double _engagementRate = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  @override
  void dispose() {
    // Cancel all subscriptions when widget is disposed
    _analyticsService.cancelSubscription('profile_views_${widget.candidateData.candidateId}');
    _analyticsService.cancelSubscription('manifesto_views_${widget.candidateData.candidateId}');
    _analyticsService.cancelSubscription('engagement_rate_${widget.candidateData.candidateId}');
    super.dispose();
  }

  void _initializeStreams() {
    final candidateId = widget.candidateData.candidateId;

    // Initialize streams
    _profileViewsStream = _analyticsService.getProfileViewsStream(candidateId);
    _manifestoViewsStream = _analyticsService.getManifestoViewsStream(candidateId);
    _engagementRateStream = _analyticsService.getEngagementRateStream(candidateId);

    // Listen to streams and update state
    _profileViewsStream.listen((value) {
      if (mounted) {
        setState(() => _profileViews = value);
      }
    });

    _manifestoViewsStream.listen((value) {
      if (mounted) {
        setState(() => _manifestoViews = value);
      }
    });

    _engagementRateStream.listen((value) {
      if (mounted) {
        setState(() => _engagementRate = value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analytics = widget.candidateData.extraInfo?.analytics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.visibility, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Profile Performance',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Key Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Profile Views',
                  value: '$_profileViews',
                  icon: Icons.visibility,
                  color: Colors.blue,
                  subtitle: 'Total profile visits',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Manifesto Views',
                  value: '$_manifestoViews',
                  icon: Icons.description,
                  color: Colors.green,
                  subtitle: 'Document views',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Engagement Rate',
                  value: '${_engagementRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                  subtitle: 'Interaction rate',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Unique Visitors',
                  value: _calculateUniqueVisitors(analytics),
                  icon: Icons.person_search,
                  color: Colors.purple,
                  subtitle: 'Distinct visitors',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Performance Insights
          _buildPerformanceInsights(),

          const SizedBox(height: 24),

          // Tips for Improvement
          _buildImprovementTips(),
        ],
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

  Widget _buildPerformanceInsights() {
    final analytics = widget.candidateData.extraInfo?.analytics;
    final profileViews = analytics?.profileViews ?? 0;
    final manifestoViews = analytics?.manifestoViews ?? 0;
    final engagementRate = analytics?.engagementRate ?? 0.0;

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Performance Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              'Profile Visibility',
              _getVisibilityLevel(profileViews),
              _getVisibilityColor(profileViews),
            ),
            _buildInsightItem(
              'Content Engagement',
              _getEngagementLevel(engagementRate),
              _getEngagementColor(engagementRate),
            ),
            _buildInsightItem(
              'Manifesto Reach',
              _getReachLevel(manifestoViews),
              _getReachColor(manifestoViews),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String metric, String level, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            metric,
            style: TextStyle(fontSize: 14, color: Colors.blue[800]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              level,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementTips() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Tips to Improve Performance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Complete your profile with detailed information'),
            _buildTipItem('Share your manifesto and campaign promises'),
            _buildTipItem('Post regular updates and engage with followers'),
            _buildTipItem('Create events to increase community engagement'),
            _buildTipItem('Use highlights to showcase your achievements'),
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
          Text('•', style: TextStyle(color: Colors.green[700])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(fontSize: 14, color: Colors.green[800]),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateUniqueVisitors(AnalyticsData? analytics) {
    // For now, estimate unique visitors as a percentage of total views
    // In a real implementation, this would be tracked separately
    final totalViews = (analytics?.profileViews ?? 0) + (analytics?.manifestoViews ?? 0);
    final estimatedUnique = (totalViews * 0.7).round(); // Assume 70% are unique
    return estimatedUnique.toString();
  }

  String _getVisibilityLevel(int views) {
    if (views >= 1000) return 'Excellent';
    if (views >= 500) return 'Good';
    if (views >= 100) return 'Fair';
    return 'Needs Improvement';
  }

  Color _getVisibilityColor(int views) {
    if (views >= 1000) return Colors.green;
    if (views >= 500) return Colors.blue;
    if (views >= 100) return Colors.orange;
    return Colors.red;
  }

  String _getEngagementLevel(double rate) {
    if (rate >= 5.0) return 'Excellent';
    if (rate >= 3.0) return 'Good';
    if (rate >= 1.0) return 'Fair';
    return 'Needs Improvement';
  }

  Color _getEngagementColor(double rate) {
    if (rate >= 5.0) return Colors.green;
    if (rate >= 3.0) return Colors.blue;
    if (rate >= 1.0) return Colors.orange;
    return Colors.red;
  }

  String _getReachLevel(int views) {
    if (views >= 500) return 'Excellent';
    if (views >= 200) return 'Good';
    if (views >= 50) return 'Fair';
    return 'Needs Improvement';
  }

  Color _getReachColor(int views) {
    if (views >= 500) return Colors.green;
    if (views >= 200) return Colors.blue;
    if (views >= 50) return Colors.orange;
    return Colors.red;
  }
}