import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class XPUsageInfo extends StatelessWidget {
  const XPUsageInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.howToUseXpPoints,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _buildXPUsageItem(
              Icons.lock_open,
              'Unlock Premium Content',
              'Access exclusive candidate manifestos and media',
            ),

            _buildXPUsageItem(
              Icons.chat,
              'Join Premium Chat Rooms',
              'Participate in candidate-only discussions',
            ),

            _buildXPUsageItem(
              Icons.poll,
              'Vote in Exclusive Polls',
              'Influence decisions with premium voting rights',
            ),

            _buildXPUsageItem(
              Icons.favorite,
              'Reward Other Voters',
              'Give XP points to helpful community members',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPUsageItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

