import 'package:flutter/material.dart';

/// GenderSelector - Handles gender selection dialog
/// Follows Single Responsibility Principle: Only handles gender selection
class GenderSelector {
  /// Shows gender selection dialog and returns selected gender
  Future<String?> selectGender(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Male'),
                onTap: () => Navigator.of(context).pop('Male'),
              ),
              ListTile(
                title: const Text('Female'),
                onTap: () => Navigator.of(context).pop('Female'),
              ),
              ListTile(
                title: const Text('Other'),
                onTap: () => Navigator.of(context).pop('Other'),
              ),
            ],
          ),
        );
      },
    );

    return result;
  }
}

