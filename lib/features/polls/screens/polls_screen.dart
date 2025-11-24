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
      body: const Center(
        child: Text('Coming soon ...'),
      ),
    );
  }

}
