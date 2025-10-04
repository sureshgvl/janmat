import 'package:flutter/material.dart';

/// Demo templates for manifesto content
class DemoTemplates {
  /// Get demo manifesto items for different categories
  static List<Map<String, dynamic>> getDemoManifestoItems() {
    return [
      {
        'id': 'demo_education',
        'title': 'Education for All',
        'description':
            'Free quality education from kindergarten to university level. Increased funding for schools and teacher training programs.',
        'category': 'Education',
        'priority': 1,
        'isCompleted': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 30)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 30)),
      },
      {
        'id': 'demo_healthcare',
        'title': 'Universal Healthcare',
        'description':
            'Comprehensive healthcare coverage for all citizens. Building new hospitals and upgrading existing medical facilities.',
        'category': 'Healthcare',
        'priority': 2,
        'isCompleted': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 25)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 25)),
      },
      {
        'id': 'demo_economy',
        'title': 'Economic Growth',
        'description':
            'Creating jobs through infrastructure development and supporting local businesses. Focus on sustainable economic policies.',
        'category': 'Economy',
        'priority': 3,
        'isCompleted': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 20)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 20)),
      },
      {
        'id': 'demo_environment',
        'title': 'Green Environment',
        'description':
            'Protecting our environment through renewable energy initiatives and sustainable development practices.',
        'category': 'Environment',
        'priority': 4,
        'isCompleted': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 15)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 15)),
      },
      {
        'id': 'demo_infrastructure',
        'title': 'Modern Infrastructure',
        'description':
            'Building world-class roads, bridges, and public transportation systems to improve connectivity and quality of life.',
        'category': 'Infrastructure',
        'priority': 5,
        'isCompleted': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 10)),
      },
    ];
  }

  /// Get demo file URLs for different file types
  static Map<String, String> getDemoFileUrls() {
    return {
      'pdf': 'https://example.com/sample_manifesto.pdf',
      'image': 'https://example.com/sample_manifesto_image.jpg',
      'video': 'https://example.com/sample_manifesto_video.mp4',
    };
  }

  /// Get demo file names
  static Map<String, String> getDemoFileNames() {
    return {
      'pdf': 'sample_manifesto.pdf',
      'image': 'sample_manifesto_image.jpg',
      'video': 'sample_manifesto_video.mp4',
    };
  }

  /// Get demo file sizes (in MB)
  static Map<String, double> getDemoFileSizes() {
    return {'pdf': 2.5, 'image': 1.8, 'video': 15.3};
  }

  /// Get sample manifesto text content
  static String getSampleManifestoText() {
    return '''
Dear Fellow Citizens,

I stand before you today with a vision for a brighter future for our community. My commitment is to serve you with dedication, transparency, and unwavering focus on the issues that matter most to you.

**Education for All**
- Free quality education from kindergarten to university
- Increased funding for schools and teacher training
- Modern digital learning facilities in every school

**Healthcare Access**
- Universal healthcare coverage for all citizens
- New hospitals and upgraded medical facilities
- Focus on preventive care and wellness programs

**Economic Development**
- Job creation through infrastructure projects
- Support for local businesses and entrepreneurs
- Sustainable economic policies for long-term growth

**Environmental Protection**
- Renewable energy initiatives
- Clean water and air quality improvements
- Green spaces and sustainable development

**Infrastructure Modernization**
- World-class roads and bridges
- Efficient public transportation systems
- Smart city technologies for better living

Together, we can build a prosperous future for our community. Your support and participation are crucial for this journey.

Thank you for your trust and confidence.

Sincerely,
[Your Name]
''';
  }

  /// Get sample manifesto categories
  static List<String> getManifestoCategories() {
    return [
      'Education',
      'Healthcare',
      'Economy',
      'Environment',
      'Infrastructure',
      'Social Welfare',
      'Technology',
      'Agriculture',
      'Security',
      'Culture & Arts',
    ];
  }

  /// Get sample priority levels
  static List<String> getPriorityLevels() {
    return ['High Priority', 'Medium Priority', 'Low Priority'];
  }

  /// Get sample timeline options
  static List<String> getTimelineOptions() {
    return [
      'Immediate (0-6 months)',
      'Short-term (6-12 months)',
      'Medium-term (1-2 years)',
      'Long-term (2-5 years)',
    ];
  }

  /// Get sample budget allocation suggestions
  static Map<String, double> getSampleBudgetAllocation() {
    return {
      'Education': 25.0,
      'Healthcare': 20.0,
      'Infrastructure': 18.0,
      'Economy': 15.0,
      'Environment': 10.0,
      'Social Welfare': 8.0,
      'Security': 4.0,
    };
  }

  /// Get sample achievement metrics
  static List<Map<String, dynamic>> getSampleAchievements() {
    return [
      {
        'title': 'Education Reform',
        'description': 'Increased school enrollment by 15%',
        'date': DateTime.now().subtract(const Duration(days: 365)),
        'category': 'Education',
      },
      {
        'title': 'Healthcare Initiative',
        'description': 'Built 3 new community health centers',
        'date': DateTime.now().subtract(const Duration(days: 300)),
        'category': 'Healthcare',
      },
      {
        'title': 'Economic Growth',
        'description': 'Created 500 new jobs in local industries',
        'date': DateTime.now().subtract(const Duration(days: 200)),
        'category': 'Economy',
      },
    ];
  }

  /// Get sample voter engagement statistics
  static Map<String, dynamic> getSampleVoterStats() {
    return {
      'totalVoters': 50000,
      'engagedVoters': 12500,
      'engagementRate': 25.0,
      'socialMediaFollowers': 8500,
      'eventAttendees': 3200,
      'surveyResponses': 1800,
    };
  }

  /// Get sample policy positions
  static Map<String, String> getSamplePolicyPositions() {
    return {
      'Education': 'Support free public education with modern facilities',
      'Healthcare': 'Universal healthcare access for all citizens',
      'Economy': 'Balanced approach to growth and sustainability',
      'Environment': 'Strong commitment to renewable energy and conservation',
      'Social Issues': 'Inclusive policies for all community members',
      'Technology': 'Digital transformation for government services',
    };
  }

  /// Get sample campaign promises
  static List<Map<String, dynamic>> getSamplePromises() {
    return [
      {
        'promise': 'Reduce unemployment by 20% within 2 years',
        'category': 'Economy',
        'timeline': '2 years',
        'status': 'In Progress',
      },
      {
        'promise': 'Build 5 new schools in underserved areas',
        'category': 'Education',
        'timeline': '18 months',
        'status': 'Completed',
      },
      {
        'promise': 'Implement renewable energy in 50% of public buildings',
        'category': 'Environment',
        'timeline': '3 years',
        'status': 'Planning',
      },
    ];
  }
}

/// Helper class for demo data management
class DemoDataManager {
  /// Check if the app is in demo mode
  static bool isDemoMode = false;

  /// Toggle demo mode
  static void toggleDemoMode() {
    isDemoMode = !isDemoMode;
  }

  /// Get appropriate data based on demo mode
  static T getData<T>(T demoData, T realData) {
    return isDemoMode ? demoData : realData;
  }

  /// Show demo mode indicator
  static Widget buildDemoModeIndicator() {
    if (!isDemoMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
          const SizedBox(width: 6),
          Text(
            'Demo Mode',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

