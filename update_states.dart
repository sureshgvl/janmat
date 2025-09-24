import 'lib/utils/add_sample_states.dart';

void main() async {
  print('🚀 Updating existing states with Marathi names...');
  try {
    await SampleStatesManager.updateExistingStatesWithMarathiNames();
    print('✅ States updated successfully!');
  } catch (e) {
    print('❌ Error updating states: $e');
  }
}