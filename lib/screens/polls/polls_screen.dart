import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class PollsScreen extends StatelessWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.polls ?? 'Polls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to create poll screen
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPollCard(
            context,
            'Ward Development Survey',
            'How should we prioritize ward development?',
            ['Roads & Infrastructure', 'Education', 'Healthcare', 'Environment'],
            [35, 25, 20, 20],
            120,
          ),
          const SizedBox(height: 16),
          _buildPollCard(
            context,
            'Candidate Preference',
            'Which candidate do you support?',
            ['Candidate A', 'Candidate B', 'Candidate C', 'Undecided'],
            [40, 30, 15, 15],
            85,
          ),
          const SizedBox(height: 16),
          _buildPollCard(
            context,
            'Budget Allocation',
            'Where should we allocate more funds?',
            ['Public Transport', 'Parks & Recreation', 'Public Safety', 'Education'],
            [28, 22, 30, 20],
            95,
          ),
        ],
      ),
    );
  }

  Widget _buildPollCard(BuildContext context, String title, String question,
      List<String> options, List<int> votes, int totalVotes) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '$totalVotes ${AppLocalizations.of(context)?.votes ?? 'votes'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(options.length, (index) {
              final percentage = totalVotes > 0 ? (votes[index] / totalVotes * 100).round() : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(options[index]),
                        ),
                        Text('$percentage%'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}