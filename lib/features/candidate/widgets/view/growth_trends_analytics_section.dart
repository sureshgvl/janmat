import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class GrowthTrendsAnalyticsSection extends StatelessWidget {
  final Candidate candidateData;

  const GrowthTrendsAnalyticsSection({
    super.key,
    required this.candidateData,
  });

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.trending_up, size: 28, color: Colors.green),
              const SizedBox(width: 12),
              const Text(
                'Growth Trends',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Growth Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildGrowthMetricCard(
                  title: 'Weekly Growth',
                  value: _calculateWeeklyGrowth(),
                  icon: Icons.calendar_view_week,
                  color: Colors.blue,
                  subtitle: 'Followers this week',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGrowthMetricCard(
                  title: 'Monthly Growth',
                  value: _calculateMonthlyGrowth(),
                  icon: Icons.calendar_month,
                  color: Colors.green,
                  subtitle: 'Followers this month',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGrowthMetricCard(
                  title: 'Growth Rate',
                  value: '${_calculateGrowthRate().toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                  subtitle: 'Weekly growth rate',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGrowthMetricCard(
                  title: 'Engagement Trend',
                  value: _calculateEngagementTrend(),
                  icon: Icons.show_chart,
                  color: Colors.purple,
                  subtitle: 'vs last week',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Follower Growth Chart
          _buildGrowthChart(),

          const SizedBox(height: 24),

          // Trend Analysis
          _buildTrendAnalysis(),

          const SizedBox(height: 24),

          // Growth Strategies
          _buildGrowthStrategies(),
        ],
      ),
    );
  }

  Widget _buildGrowthMetricCard({
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

  Widget _buildGrowthChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    Icons.bar_chart,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Follower Growth Over Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Growth chart visualization',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Interactive chart will be implemented here',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegend('This Week', Colors.blue),
                const SizedBox(width: 16),
                _buildChartLegend('Last Week', Colors.grey),
                const SizedBox(width: 16),
                _buildChartLegend('Trend', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis() {
    final growthRate = _calculateGrowthRate();
    final trend = _getGrowthTrend(growthRate);

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Trend Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTrendItem(
              'Growth Trend',
              trend['description'] as String,
              trend['color'] as Color,
            ),
            _buildTrendItem(
              'Current Momentum',
              _getMomentumDescription(growthRate),
              _getMomentumColor(growthRate),
            ),
            _buildTrendItem(
              'Projected Growth',
              _getProjectionDescription(growthRate),
              _getProjectionColor(growthRate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(String metric, String value, Color color) {
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
              value,
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

  Widget _buildGrowthStrategies() {
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
                  'Growth Strategies',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStrategyItem('Post consistently to maintain momentum'),
            _buildStrategyItem('Engage with followers through polls and Q&A'),
            _buildStrategyItem('Share campaign updates and achievements'),
            _buildStrategyItem('Collaborate with local influencers and groups'),
            _buildStrategyItem('Run targeted campaigns during peak engagement times'),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyItem(String strategy) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: Colors.green[700])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strategy,
              style: TextStyle(fontSize: 14, color: Colors.green[800]),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateWeeklyGrowth() {
    // For now, return a placeholder calculation
    // In a real implementation, this would analyze follower growth over the past week
    final followers = candidateData.followersCount;
    // Assume 15% weekly growth for demonstration
    final weeklyGrowth = (followers * 0.15).round();
    return '+$weeklyGrowth';
  }

  String _calculateMonthlyGrowth() {
    // For now, return a placeholder calculation
    final followers = candidateData.followersCount;
    // Assume 45% monthly growth for demonstration
    final monthlyGrowth = (followers * 0.45).round();
    return '+$monthlyGrowth';
  }

  double _calculateGrowthRate() {
    // Calculate growth rate based on follower count
    // This is a simplified calculation - real implementation would use historical data
    final followers = candidateData.followersCount;
    if (followers < 10) return 5.0; // Low growth for new accounts
    if (followers < 50) return 15.0; // Moderate growth
    if (followers < 200) return 25.0; // Good growth
    return 35.0; // Excellent growth
  }

  String _calculateEngagementTrend() {
    // Placeholder for engagement trend calculation
    final growthRate = _calculateGrowthRate();
    if (growthRate > 20) return '+12%';
    if (growthRate > 10) return '+5%';
    return '+2%';
  }

  Map<String, dynamic> _getGrowthTrend(double growthRate) {
    if (growthRate >= 30) {
      return {
        'description': 'Excellent',
        'color': Colors.green,
      };
    } else if (growthRate >= 20) {
      return {
        'description': 'Good',
        'color': Colors.blue,
      };
    } else if (growthRate >= 10) {
      return {
        'description': 'Moderate',
        'color': Colors.orange,
      };
    } else {
      return {
        'description': 'Slow',
        'color': Colors.red,
      };
    }
  }

  String _getMomentumDescription(double growthRate) {
    if (growthRate >= 25) return 'Strong';
    if (growthRate >= 15) return 'Steady';
    if (growthRate >= 8) return 'Building';
    return 'Developing';
  }

  Color _getMomentumColor(double growthRate) {
    if (growthRate >= 25) return Colors.green;
    if (growthRate >= 15) return Colors.blue;
    if (growthRate >= 8) return Colors.orange;
    return Colors.grey;
  }

  String _getProjectionDescription(double growthRate) {
    if (growthRate >= 25) return 'Accelerating';
    if (growthRate >= 15) return 'Growing';
    if (growthRate >= 8) return 'Stable';
    return 'Needs Boost';
  }

  Color _getProjectionColor(double growthRate) {
    if (growthRate >= 25) return Colors.green;
    if (growthRate >= 15) return Colors.blue;
    if (growthRate >= 8) return Colors.orange;
    return Colors.red;
  }
}