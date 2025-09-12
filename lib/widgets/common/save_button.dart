import 'package:flutter/material.dart';

class SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;
  final String? tooltip;

  const SaveButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : const Icon(Icons.save),
      onPressed: isSaving ? null : onPressed,
      tooltip: tooltip ?? 'Save Changes',
    );
  }
}