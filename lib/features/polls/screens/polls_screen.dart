import 'package:flutter/material.dart';
import '../../../l10n/features/polls/polls_localizations.dart';

class PollsScreen extends StatelessWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(PollsLocalizations.of(context)?.translate('polls') ?? 'Polls'),
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
            PollsLocalizations.of(context)?.translate('wardDevelopmentSurvey') ?? 'Ward Development Survey',
            PollsLocalizations.of(context)?.translate('howShouldWePrioritizeWardDevelopment') ?? 'How should we prioritize ward development?',
            [
              PollsLocalizations.of(context)?.translate('roadsAndInfrastructure') ?? 'Roads & Infrastructure',
              PollsLocalizations.of(context)?.translate('education') ?? 'Education',
              PollsLocalizations.of(context)?.translate('healthcare') ?? 'Healthcare',
              PollsLocalizations.of(context)?.translate('environment') ?? 'Environment',
            ],
            [35, 25, 20, 20],
            120,
          ),
          const SizedBox(height: 16),
          _buildPollCard(
            context,
            PollsLocalizations.of(context)?.translate('candidatePreference') ?? 'Candidate Preference',
            PollsLocalizations.of(context)?.translate('whichCandidateDoYouSupport') ?? 'Which candidate do you support?',
            [
              PollsLocalizations.of(context)?.translate('candidateA') ?? 'Candidate A',
              PollsLocalizations.of(context)?.translate('candidateB') ?? 'Candidate B',
              PollsLocalizations.of(context)?.translate('candidateC') ?? 'Candidate C',
              PollsLocalizations.of(context)?.translate('undecided') ?? 'Undecided'
            ],
            [40, 30, 15, 15],
            85,
          ),
          const SizedBox(height: 16),
          _buildPollCard(
            context,
            PollsLocalizations.of(context)?.translate('budgetAllocation') ?? 'Budget Allocation',
            PollsLocalizations.of(context)?.translate('whereShouldWeAllocateMoreFunds') ?? 'Where should we allocate more funds?',
            [
              PollsLocalizations.of(context)?.translate('publicTransport') ?? 'Public Transport',
              PollsLocalizations.of(context)?.translate('parksAndRecreation') ?? 'Parks & Recreation',
              PollsLocalizations.of(context)?.translate('publicSafety') ?? 'Public Safety',
              PollsLocalizations.of(context)?.translate('education') ?? 'Education',
            ],
            [28, 22, 30, 20],
            95,
          ),
        ],
      ),
    );
  }

  Widget _buildPollCard(
    BuildContext context,
    String title,
    String question,
    List<String> options,
    List<int> votes,
    int totalVotes,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(question, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              '$totalVotes ${PollsLocalizations.of(context)?.translate('votes') ?? 'votes'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...List.generate(options.length, (index) {
              final percentage = totalVotes > 0
                  ? (votes[index] / totalVotes * 100).round()
                  : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(options[index])),
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
