import 'package:flutter/material.dart';

import 'lib/utils/add_sample_states.dart';

void main() async {
  debugPrint('🚀 Updating existing states with Marathi names...');
  try {
    await SampleStatesManager.updateExistingStatesWithMarathiNames();
    debugPrint('✅ States updated successfully!');
  } catch (e) {
    debugPrint('❌ Error updating states: $e');
  }
}
