import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/chat_model.dart';
import '../../repositories/chat_repository.dart';

// Stateful widget for poll voting dialog
class PollVotingDialog extends StatefulWidget {
  final String pollId;
  final String question;
  final String currentUserId;

  const PollVotingDialog({
    super.key,
    required this.pollId,
    required this.question,
    required this.currentUserId,
  });

  @override
  PollVotingDialogState createState() => PollVotingDialogState();
}

class PollVotingDialogState extends State<PollVotingDialog> {
  Poll? _poll;
  bool _isLoading = true;
  String? _selectedOption;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _loadPollData();
  }

  Future<void> _loadPollData() async {
    try {
      print('🔍 Loading poll data for pollId: ${widget.pollId}');

      // Get poll data from repository
      final chatRepository = ChatRepository();

      // Get the specific poll by ID
      final poll = await chatRepository.getPollById(widget.pollId);

      if (poll != null) {
        print('✅ Poll found: ${poll.question}');

        setState(() {
          _poll = poll;
          _hasVoted = poll.userVotes.containsKey(widget.currentUserId);
          _selectedOption = poll.userVotes[widget.currentUserId];
          _isLoading = false;
        });

        print('📊 Poll loaded - Has voted: $_hasVoted, Selected: $_selectedOption');
      } else {
        print('❌ Poll not found with ID: ${widget.pollId}');
        setState(() {
          _isLoading = false;
        });
        Get.snackbar(
          'Poll Not Found',
          'This poll could not be loaded',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      print('❌ Error loading poll data: $e');
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load poll data: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<void> _voteOnPoll(String option) async {
    if (_poll == null || _hasVoted) return;

    try {
      final chatRepository = ChatRepository();
      await chatRepository.voteOnPoll(widget.pollId, widget.currentUserId, option);

      setState(() {
        _hasVoted = true;
        _selectedOption = option;
      });

      Get.snackbar(
        'Vote Recorded!',
        'Your vote has been recorded',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Vote Failed',
        'Failed to record your vote. Please try again.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  int _getTotalVotes() {
    if (_poll == null) return 0;
    return _poll!.votes.values.fold(0, (sum, count) => sum + count);
  }

  double _getVotePercentage(String option) {
    final totalVotes = _getTotalVotes();
    if (totalVotes == 0) return 0.0;
    return (_poll!.votes[option] ?? 0) / totalVotes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.poll, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading poll...'),
                  ],
                ),
              )
            : _poll == null
                ? const Center(
                    child: Text('Poll not found'),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getTotalVotes()} vote${_getTotalVotes() != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._poll!.options.map((option) {
                        final voteCount = _poll!.votes[option] ?? 0;
                        final percentage = _getVotePercentage(option);
                        final isSelected = _selectedOption == option;
                        final isUserChoice = _poll!.userVotes[widget.currentUserId] == option;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: (_hasVoted || _isLoading) ? null : () => _voteOnPoll(option),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isUserChoice
                                    ? Colors.blue.shade50
                                    : isSelected
                                        ? Colors.grey.shade50
                                        : Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (_hasVoted) ...[
                                        Text(
                                          '$voteCount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        if (isUserChoice)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green.shade600,
                                            size: 16,
                                          ),
                                      ],
                                    ],
                                  ),
                                  if (_hasVoted && _getTotalVotes() > 0) ...[
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: percentage,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isUserChoice ? Colors.green.shade400 : Colors.blue.shade400,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(percentage * 100).round()}%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      if (_hasVoted) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Thank you for voting!',
                                  style: TextStyle(
                                    color: const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w500,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Stateful widget for poll creation dialog
class CreatePollDialog extends StatefulWidget {
  final Function(String question, List<String> options) onPollCreated;

  const CreatePollDialog({super.key, required this.onPollCreated});

  @override
  CreatePollDialogState createState() => CreatePollDialogState();
}

class CreatePollDialogState extends State<CreatePollDialog> {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    questionController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (optionControllers.length < 10) { // Limit to 10 options max
      setState(() {
        optionControllers.add(TextEditingController());
      });
    } else {
      Get.snackbar(
        'Maximum Options',
        'You can add up to 10 options',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
    }
  }

  void _removeOption(int index) {
    if (optionControllers.length > 2) {
      setState(() {
        optionControllers[index].dispose();
        optionControllers.removeAt(index);
      });
    } else {
      Get.snackbar(
        'Minimum Options',
        'You need at least 2 options',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.poll, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('Create Poll'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Poll Question',
                  hintText: 'What would you like to ask?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              const Text(
                'Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (optionControllers.length > 2)
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle,
                            color: Colors.red.shade400,
                          ),
                          onPressed: () => _removeOption(index),
                          tooltip: 'Remove option',
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _addOption,
                  icon: Icon(
                    Icons.add_circle,
                    color: Colors.blue.shade600,
                  ),
                  label: Text(
                    'Add Option (${optionControllers.length}/10)',
                    style: TextStyle(color: Colors.blue.shade600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final question = questionController.text.trim();
            final options = optionControllers
                .map((c) => c.text.trim())
                .where((text) => text.isNotEmpty)
                .toList();

            if (question.isEmpty) {
              Get.snackbar(
                'Question Required',
                'Please enter a poll question',
                backgroundColor: Colors.orange.shade100,
                colorText: Colors.orange.shade800,
              );
              return;
            }

            if (options.length < 2) {
              Get.snackbar(
                'More Options Needed',
                'Please add at least 2 options',
                backgroundColor: Colors.orange.shade100,
                colorText: Colors.orange.shade800,
              );
              return;
            }

            widget.onPollCreated(question, options);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Create Poll'),
        ),
      ],
    );
  }
}