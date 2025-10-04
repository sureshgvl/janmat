import 'package:flutter/material.dart';

/// CustomFormFieldBuilder - Utility for building consistent form fields
/// Follows Single Responsibility Principle: Only handles form field creation
class CustomFormFieldBuilder {
  /// Builds a standard text form field
  static Widget buildTextInputField({
    required TextEditingController controller,
    required String labelText,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    int? maxLines,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}