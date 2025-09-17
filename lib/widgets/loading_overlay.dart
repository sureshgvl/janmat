import 'dart:async';
import 'package:flutter/material.dart';

class LoadingDialog extends StatefulWidget {
  final String initialMessage;
  final VoidCallback? onCancel;
  final Stream<String>? messageStream;
  final Stream<double>? progressStream;

  const LoadingDialog({
    super.key,
    this.initialMessage = 'Saving...',
    this.onCancel,
    this.messageStream,
    this.progressStream,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String initialMessage = 'Saving...',
    VoidCallback? onCancel,
    Stream<String>? messageStream,
    Stream<double>? progressStream,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => LoadingDialog(
        initialMessage: initialMessage,
        onCancel: onCancel,
        messageStream: messageStream,
        progressStream: progressStream,
      ),
    );
  }

  @override
  State<LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog> {
  String _currentMessage = '';
  double _currentProgress = 0.0;
  StreamSubscription<String>? _messageSubscription;
  StreamSubscription<double>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _currentMessage = widget.initialMessage;

    // Listen to message stream if provided
    if (widget.messageStream != null) {
      _messageSubscription = widget.messageStream!.listen((message) {
        if (mounted) {
          setState(() {
            _currentMessage = message;
          });
        }
      });
    }

    // Listen to progress stream if provided
    if (widget.progressStream != null) {
      _progressSubscription = widget.progressStream!.listen((progress) {
        if (mounted) {
          setState(() {
            _currentProgress = progress.clamp(0.0, 1.0);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _progressSubscription?.cancel();
    super.dispose();
  }

  void updateMessage(String message) {
    if (mounted) {
      setState(() {
        _currentMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from dismissing
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.progressStream != null && _currentProgress > 0) ...[
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: _currentProgress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_currentProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                _currentMessage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.onCancel != null) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
