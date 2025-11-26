import 'package:flutter/material.dart';

// Loading dialog for delete operations
class MediaDeleteProgressDialog extends StatelessWidget {
  final String title;
  final String message;

  const MediaDeleteProgressDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: null, // No actions - user cannot dismiss
    );
  }
}

// Loading dialog for post operations
class PostProgressDialog extends StatelessWidget {
  final String title;
  final String message;
  final double? progress;

  const PostProgressDialog({
    super.key,
    required this.title,
    required this.message,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (progress != null) ...[
            CircularProgressIndicator(value: progress),
          ] else ...[
            const CircularProgressIndicator(),
          ],
          const SizedBox(width: 16),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: null, // No actions - user cannot dismiss
    );
  }
}