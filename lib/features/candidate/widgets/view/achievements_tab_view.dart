import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class AchievementsTabView extends StatefulWidget {
  final Candidate candidate;
  final bool isOwnProfile;

  const AchievementsTabView({
    super.key,
    required this.candidate,
    this.isOwnProfile = false,
  });

  @override
  State<AchievementsTabView> createState() => _AchievementsTabViewState();
}

class _AchievementsTabViewState extends State<AchievementsTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Like and share state for each achievement
  final Map<int, bool> _likedAchievements = {};
  final Map<int, int> _achievementLikes = {};

  @override
  void initState() {
    super.initState();
    // Initialize with mock data - in real app this would come from server
    final achievements = widget.candidate.extraInfo?.achievements ?? [];
    for (int i = 0; i < achievements.length; i++) {
      _likedAchievements[i] = false;
      _achievementLikes[i] = (i + 1) * 3; // Mock data
    }
  }

  void _toggleAchievementLike(int index) {
    setState(() {
      _likedAchievements[index] = !_likedAchievements[index]!;
      _achievementLikes[index] =
          (_achievementLikes[index] ?? 0) +
          (_likedAchievements[index]! ? 1 : -1);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _likedAchievements[index]!
              ? 'Achievement liked!'
              : 'Achievement unliked',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareAchievement(int index) {
    final achievement = widget.candidate.extraInfo?.achievements?[index];
    final achievementText =
        '''
Check out this achievement by ${widget.candidate.name}!

"${achievement?.title ?? 'Achievement'}" (${achievement?.year ?? 'N/A'})

${achievement?.description ?? ''}

View their complete profile and achievements at: [Your App URL]
''';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would open native share dialog'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final achievements = widget.candidate.extraInfo?.achievements ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Achievements Header
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
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.amber.shade600,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Achievements',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${achievements.length} achievement${achievements.length != 1 ? 's' : ''} recorded',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Achievements List
          if (achievements.isNotEmpty) ...[
            ...achievements.map((achievement) {
              final index = achievements.indexOf(achievement);
              final colors = [
                Colors.blue,
                Colors.green,
                Colors.purple,
                Colors.orange,
                Colors.red,
                Colors.teal,
                Colors.pink,
                Colors.indigo,
              ];
              final color = colors[index % colors.length];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.shade200),
                          ),
                          child: Icon(
                            Icons.star_border,
                            color: color.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement.title ?? 'Achievement ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1f2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Year: ${achievement.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.shade200),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (achievement.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          achievement.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],

                    // Like and Share buttons
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Like Button
                        GestureDetector(
                          onTap: () => _toggleAchievementLike(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: (_likedAchievements[index] ?? false)
                                  ? Colors.red.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (_likedAchievements[index] ?? false)
                                    ? Colors.red.shade300
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: (_likedAchievements[index] ?? false)
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_achievementLikes[index] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Share Button
                        GestureDetector(
                          onTap: () => _shareAchievement(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.share, size: 16, color: Colors.blue),
                                SizedBox(width: 6),
                                Text(
                                  'Share',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            // No achievements placeholder
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.amber.shade400,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Achievements Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Achievements and accomplishments will be displayed here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

