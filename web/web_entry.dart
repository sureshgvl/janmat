//! This file is only included in web builds
/// Web-specific initialization
import 'web_config.dart';

void initializeWebApp() {
  try {
    WebConfig.initialize();
    print('✅ Web configuration initialized');
  } catch (e) {
    print('❌ Failed to initialize web config: $e');
  }
}
