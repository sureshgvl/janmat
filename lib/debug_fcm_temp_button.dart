// TEMPORARY DEBUG BUTTON - Add this to any screen temporarily
// This will add a debug button to test FCM

import 'package:flutter/material.dart';
import 'debug_fcm_token.dart';

class FCMDebugButton extends StatelessWidget {
  const FCMDebugButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _runFCMDebug(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      child: const Text('🔧 DEBUG FCM'),
    );
  }

  Future<void> _runFCMDebug(BuildContext context) async {
    final debugger = FCMTokenDebugger();
    String output = '';

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running FCM Debug...'),
          ],
        ),
      ),
    );

    try {
      // 1. Check FCM status
      output += '=== CHECKING FCM STATUS ===\n';
      await debugger.checkFCMStatus();
      output += 'Current user checked\n';

      // 2. Request permissions
      output += '\n=== REQUESTING PERMISSIONS ===\n';
      await debugger.requestPermissions();
      output += 'Permissions requested\n';

      // 3. Update token
      output += '\n=== UPDATING FCM TOKEN ===\n';
      await debugger.forceUpdateFCMToken();
      output += 'Token updated\n';

      // 4. Final check
      output += '\n=== FINAL CHECK ===\n';
      await debugger.checkFCMStatus();
      output += 'Final check complete\n';

      output += '\n✅ FCM DEBUG COMPLETE!\n';
      output += 'Now test follow notifications from another device.';

    } catch (e) {
      output += '\n❌ ERROR: $e\n';
    }

    // Close loading dialog and show results
    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('FCM Debug Results'),
          content: SingleChildScrollView(
            child: Text(
              output,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    // Also print to console
    print(output);
  }
}

// HOW TO ADD THIS TEMPORARILY:
//
// 1. Import this file in any screen (e.g., main_tab_navigation.dart)
//    import 'debug_fcm_temp_button.dart';
//
// 2. Add the button anywhere in the UI, for example in the app bar:
//    appBar: AppBar(
//      title: const Text('JanMat'),
//      actions: const [
//        FCMDebugButton(),  // TEMPORARY - REMOVE AFTER DEBUGGING
//      ],
//    ),
//
// 3. Run the app and tap the red "🔧 DEBUG FCM" button
//
// 4. The button will:
//    - Check FCM permissions and token
//    - Request permissions if needed
//    - Force update the FCM token
//    - Show results in a dialog
//
// 5. After debugging, remove the import and button

// ALTERNATIVE: Add to any screen's body temporarily
/*
body: Column(
  children: [
    const FCMDebugButton(),  // TEMPORARY DEBUG BUTTON
    // ... rest of your content
  ],
),
*/