import 'dart:io';
import 'universal_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Mobile-specific storage implementation using file system
class MobileStorage implements UniversalStorage {
  IOSink? _fileSink;
  static const String _logFileName = 'janmat_log.txt';

  @override
  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logPath = '${directory.path}/$_logFileName';

      final logFile = File(logPath);
      _fileSink = logFile.openWrite(mode: FileMode.append);

      // Write header to file
      final header = '\n\n=== JANMAT LOGS SESSION STARTED MOBILE ${DateTime.now()} ===\n';
      _fileSink?.write(header);
      _fileSink?.flush();
    } catch (e) {
      // File logging failed - this is non-critical
      _fileSink = null;
    }
  }

  @override
  Future<void> writeLog(String message) async {
    if (_fileSink == null) return;

    try {
      final timestamp = DateTime.now().toIso8601String();
      final formattedMessage = '[$timestamp] $message\n';
      _fileSink?.write(formattedMessage);
      _fileSink?.flush();
    } catch (e) {
      // Silent failure during file writing
      _fileSink = null;
    }
  }

  @override
  Future<void> close() async {
    if (_fileSink == null) return;

    try {
      _fileSink?.write('\n=== JANMAT LOGS SESSION ENDED MOBILE ${DateTime.now()} ===\n\n');
      await _fileSink?.flush();
      await _fileSink?.close();
      _fileSink = null;
    } catch (e) {
      // Silent failure when closing
    }
  }
}

UniversalStorage createUniversalStorage() {
  return MobileStorage();
}
