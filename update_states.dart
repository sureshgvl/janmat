import 'package:flutter/material.dart';

import 'lib/utils/add_sample_states.dart';
import 'lib/utils/app_logger.dart';

void main() async {
  AppLogger.core('Updating existing states with Marathi names...');
  try {
    await SampleStatesManager.updateExistingStatesWithMarathiNames();
    AppLogger.core('States updated successfully!');
  } catch (e) {
    AppLogger.coreError('Error updating states: $e');
  }
}
