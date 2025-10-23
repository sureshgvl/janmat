import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class DemographicsAnalyticsSection extends StatelessWidget {
  final Candidate candidateData;

  const DemographicsAnalyticsSection({
    super.key,
    required this.candidateData,
  });

  @override
  Widget build(BuildContext context) {
    final analytics = candidateData.analytics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.people_alt, size: 28, color: Colors.teal),
              const SizedBox(width: 12),
              const Text(
                'Voter Demographics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (analytics?.demographics != null) ...[
            // Age Distribution
            _buildDemographicCard(
              title: 'Age Distribution',
              icon: Icons.cake,
              color: Colors.blue,
              data: _getAgeDistribution(analytics!.demographics!),
            ),
            const SizedBox(height: 16),

            // Gender Distribution
            _buildDemographicCard(
              title: 'Gender Distribution',
              icon: Icons.person,
              color: Colors.pink,
              data: _getGenderDistribution(analytics.demographics!),
            ),
            const SizedBox(height: 16),

            // Geographic Distribution
            _buildDemographicCard(
              title: 'Geographic Reach',
              icon: Icons.location_on,
              color: Colors.green,
              data: _getGeographicDistribution(analytics.demographics!),
            ),
          ] else ...[
            // Placeholder when no demographics data
            _buildEmptyState(),
          ],

          const SizedBox(height: 24),

          // Demographics Insights
          _buildDemographicsInsights(),

          const SizedBox(height: 24),

          // Data Collection Tips
          _buildDataCollectionTips(),
        ],
      ),
    );
  }

  Widget _buildDemographicCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, dynamic> data,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...data.entries.map((entry) => _buildDemographicBar(
              entry.key,
              entry.value as double,
              color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDemographicBar(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
              '${percentage.round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Demographics data will be available soon',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'As more voters interact with your profile, we\'ll collect and display demographic insights.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemographicsInsights() {
    return Card(
      color: Colors.teal[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.teal[700]),
                const SizedBox(width: 8),
                Text(
                  'Demographics Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInsightItem('Understanding your voter demographics helps tailor your campaign messaging'),
            _buildInsightItem('Age distribution shows which generations are most engaged'),
            _buildInsightItem('Geographic data reveals your reach and potential growth areas'),
            _buildInsightItem('Gender insights help ensure inclusive campaign strategies'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCollectionTips() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Building Demographics Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Encourage profile visits from diverse voter groups'),
            _buildTipItem('Share content that appeals to different demographics'),
            _buildTipItem('Engage with voters from various age groups and regions'),
            _buildTipItem('Run targeted campaigns to reach underrepresented groups'),
            _buildTipItem('Collect feedback through polls and surveys'),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String insight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: Colors.teal[700])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight,
              style: TextStyle(fontSize: 14, color: Colors.teal[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: Colors.blue[700])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(fontSize: 14, color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getAgeDistribution(Map<String, dynamic> demographics) {
    // Extract age distribution from demographics data
    final ageData = demographics['age_groups'] as Map<String, dynamic>? ?? {};
    final total = ageData.values.fold(0.0, (sum, value) => sum + (value as num).toDouble());

    if (total == 0) {
      return {
        '18-25': 0.0,
        '26-35': 0.0,
        '36-50': 0.0,
        '51+': 0.0,
      };
    }

    return {
      '18-25': ((ageData['18-25'] ?? 0.0) / total * 100),
      '26-35': ((ageData['26-35'] ?? 0.0) / total * 100),
      '36-50': ((ageData['36-50'] ?? 0.0) / total * 100),
      '51+': ((ageData['51+'] ?? 0.0) / total * 100),
    };
  }

  Map<String, dynamic> _getGenderDistribution(Map<String, dynamic> demographics) {
    // Extract gender distribution from demographics data
    final genderData = demographics['gender'] as Map<String, dynamic>? ?? {};
    final total = genderData.values.fold(0.0, (sum, value) => sum + (value as num).toDouble());

    if (total == 0) {
      return {
        'Male': 0.0,
        'Female': 0.0,
        'Other': 0.0,
      };
    }

    return {
      'Male': ((genderData['male'] ?? 0.0) / total * 100),
      'Female': ((genderData['female'] ?? 0.0) / total * 100),
      'Other': ((genderData['other'] ?? 0.0) / total * 100),
    };
  }

  Map<String, dynamic> _getGeographicDistribution(Map<String, dynamic> demographics) {
    // Extract geographic distribution from demographics data
    final geoData = demographics['locations'] as Map<String, dynamic>? ?? {};
    final total = geoData.values.fold(0.0, (sum, value) => sum + (value as num).toDouble());

    if (total == 0) {
      return {
        'Local': 0.0,
        'Regional': 0.0,
        'State': 0.0,
        'National': 0.0,
      };
    }

    return {
      'Local': ((geoData['local'] ?? 0.0) / total * 100),
      'Regional': ((geoData['regional'] ?? 0.0) / total * 100),
      'State': ((geoData['state'] ?? 0.0) / total * 100),
      'National': ((geoData['national'] ?? 0.0) / total * 100),
    };
  }
}
