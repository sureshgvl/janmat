import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_database_service.dart';

class BackgroundLocationSyncService {
  static BackgroundLocationSyncService? _instance;
  Timer? _syncTimer;
  final LocalDatabaseService _locationDatabase = LocalDatabaseService();
  final Connectivity _connectivity = Connectivity();


  // Singleton pattern
  static BackgroundLocationSyncService get instance {
    _instance ??= BackgroundLocationSyncService._();
    return _instance!;
  }

  BackgroundLocationSyncService._();

  // Initialize the background sync service
  Future<void> initialize() async {
    try {
      // SQLite database initializes automatically when accessed
      developer.log('BackgroundLocationSyncService initialized');

      // Note: Main caching is now done during profile completion
      // This service mainly provides statistics and maintenance functions
      developer.log('Location data caching is handled during profile completion');
    } catch (e) {
      developer.log('Error initializing background location sync: $e');
    }
  }

  // Perform periodic sync (simplified - main caching is done during profile completion)
  Future<void> _performPeriodicSync() async {
    try {
      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        developer.log('No network connectivity, skipping location sync');
        return;
      }

      developer.log('Checking SQLite database health...');

      // Get database statistics to ensure it's working
      final stats = await _locationDatabase.getStatistics();
      developer.log('Database statistics: ${stats['districts']} districts, ${stats['bodies']} bodies, ${stats['wards']} wards');

      developer.log('Periodic location sync completed successfully');
    } catch (e) {
      developer.log('Error in periodic location sync: $e');
    }
  }

  // Manual sync trigger (can be called from settings or when needed)
  Future<void> syncNow() async {
    try {
      developer.log('Manual location sync triggered');

      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        developer.log('No network connectivity for manual sync');
        throw Exception('No network connectivity');
      }

      // Get current database statistics
      final stats = await _locationDatabase.getStatistics();
      developer.log('Current database statistics: ${stats['districts']} districts, ${stats['bodies']} bodies, ${stats['wards']} wards');
      developer.log('Manual location sync completed');
    } catch (e) {
      developer.log('Error in manual location sync: $e');
      throw Exception('Failed to sync location data: $e');
    }
  }

  // Get cache statistics
  Future<Map<String, int>> getCacheStatistics() async {
    try {
      return await _locationDatabase.getStatistics();
    } catch (e) {
      developer.log('Error getting cache statistics: $e');
      return {'districts': 0, 'bodies': 0, 'wards': 0};
    }
  }

  // Clear all cached data
  Future<void> clearCache() async {
    try {
      await _locationDatabase.clearAllData();
      developer.log('Location cache cleared');
    } catch (e) {
      developer.log('Error clearing location cache: $e');
    }
  }

  // Preload location data (for better initial performance)
  Future<void> preloadLocationData() async {
    try {
      // Get current statistics to ensure database is accessible
      final stats = await _locationDatabase.getStatistics();
      developer.log('Database preloaded - contains ${stats['districts']} districts, ${stats['bodies']} bodies, ${stats['wards']} wards');
    } catch (e) {
      developer.log('Error preloading location data: $e');
    }
  }

  // Stop the background sync (useful for testing or when app is backgrounded for long time)
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    developer.log('Background location sync stopped');
  }

  // Restart the background sync
  void restartSync() {
    stopSync();
    initialize();
    developer.log('Background location sync restarted');
  }

  // Check if sync is running
  bool get isRunning => _syncTimer?.isActive == true;

  // Get last sync time (you could store this in Hive for persistence)
  DateTime? get lastSyncTime {
    // This is a simple implementation
    // In production, you might want to store this in Hive
    return null;
  }
}

