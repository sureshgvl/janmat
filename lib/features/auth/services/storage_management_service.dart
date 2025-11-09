import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/painting.dart';
import '../../../utils/app_logger.dart';

class StorageManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Get current storage usage information
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appDir = await getApplicationDocumentsDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      final info = <String, dynamic>{
        'cache': <String, dynamic>{
          'files': 0,
          'size': 0,
          'path': cacheDir.path,
        },
        'appDocuments': <String, dynamic>{
          'files': 0,
          'size': 0,
          'path': appDir.path,
        },
        'appSupport': <String, dynamic>{
          'files': 0,
          'size': 0,
          'path': appSupportDir.path,
        },
        'total': <String, dynamic>{'files': 0, 'size': 0},
      };

      // Analyze cache directory
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        info['cache']!['files'] = files.length;
        for (final file in files) {
          if (file is File) {
            try {
              info['cache']!['size'] =
                  (info['cache']!['size'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Analyze app documents directory
      if (await appDir.exists()) {
        final files = appDir.listSync(recursive: true);
        info['appDocuments']!['files'] = files.length;
        for (final file in files) {
          if (file is File) {
            try {
              info['appDocuments']!['size'] =
                  (info['appDocuments']!['size'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Analyze app support directory
      if (await appSupportDir.exists()) {
        final files = appSupportDir.listSync(recursive: true);
        info['appSupport']!['files'] = files.length;
        for (final file in files) {
          if (file is File) {
            try {
              info['appSupport']!['size'] =
                  (info['appSupport']!['size'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Calculate totals
      info['total']!['files'] =
          (info['cache']!['files'] as int) +
          (info['appDocuments']!['files'] as int) +
          (info['appSupport']!['files'] as int);

      info['total']!['size'] =
          (info['cache']!['size'] as int) +
          (info['appDocuments']!['size'] as int) +
          (info['appSupport']!['size'] as int);

      return info;
    } catch (e) {
      AppLogger.auth('Could not get storage info: $e');
      return <String, dynamic>{
        'error': e.toString(),
        'cache': <String, dynamic>{'files': 0, 'size': 0},
        'appDocuments': <String, dynamic>{'files': 0, 'size': 0},
        'appSupport': <String, dynamic>{'files': 0, 'size': 0},
        'total': <String, dynamic>{'files': 0, 'size': 0},
      };
    }
  }

  // Manually trigger storage cleanup (for user-initiated cleanup)
  Future<Map<String, dynamic>> manualStorageCleanup() async {
    try {
      AppLogger.auth('🧹 Manual storage cleanup initiated...');

      final result = <String, dynamic>{
        'initialSize': 0,
        'finalSize': 0,
        'cleanedSize': 0,
        'deletedFiles': 0,
        'deletedDirs': 0,
      };

      // Get initial size
      final cacheDir = await getTemporaryDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              result['initialSize'] =
                  (result['initialSize'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      if (await appSupportDir.exists()) {
        final files = appSupportDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              result['initialSize'] =
                  (result['initialSize'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Perform cleanup
      await _clearLogoutCache();

      // Clear Firebase cache
      try {
        await _firestore.clearPersistence();
        AppLogger.auth('✅ Firebase cache cleared during manual cleanup');
      } catch (e) {
        AppLogger.auth('Warning: Could not clear Firebase cache: $e');
      }

      // Get final size
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              result['finalSize'] =
                  (result['finalSize'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      if (await appSupportDir.exists()) {
        final files = appSupportDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              result['finalSize'] =
                  (result['finalSize'] as int) + await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      result['cleanedSize'] =
          (result['initialSize'] as int) - (result['finalSize'] as int);

      AppLogger.auth('✅ Manual cleanup completed:');
      AppLogger.auth(
        '   Initial size: ${(result['initialSize'] as int) / 1024 / 1024} MB',
      );
      AppLogger.auth(
        '   Final size: ${(result['finalSize'] as int) / 1024 / 1024} MB',
      );
      AppLogger.auth(
        '   Cleaned: ${(result['cleanedSize'] as int) / 1024 / 1024} MB',
      );

      return result;
    } catch (e) {
      AppLogger.auth('Manual storage cleanup failed: $e');
      return <String, dynamic>{
        'error': e.toString(),
        'initialSize': 0,
        'finalSize': 0,
        'cleanedSize': 0,
        'deletedFiles': 0,
        'deletedDirs': 0,
      };
    }
  }

  // Analyze and clean up storage on app startup
  Future<void> analyzeAndCleanupStorage() async {
    try {
      AppLogger.auth('🔍 Analyzing app storage on startup...');

      // Log current storage state
      await _logStorageState('APP_STARTUP');

      // Check if this is first launch or if storage is excessive
      final cacheDir = await getTemporaryDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      int totalSize = 0;

      // Calculate cache size
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              totalSize += await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Calculate app support size
      if (await appSupportDir.exists()) {
        final files = appSupportDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            try {
              totalSize += await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // If storage is excessive (>50MB), clean it up
      if (totalSize > 50 * 1024 * 1024) {
        AppLogger.auth(
          '⚠️ Excessive storage detected (${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB), cleaning up...',
        );
        await _cleanupExcessiveStorage();
      } else {
        AppLogger.auth(
          '✅ Storage usage normal (${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB)',
        );
      }
    } catch (e) {
      AppLogger.auth('ℹ️ Could not analyze storage: $e');
    }
  }

  // Clean up excessive storage
  Future<void> _cleanupExcessiveStorage() async {
    try {
      AppLogger.auth('🧹 Cleaning up excessive storage...');

      final cacheDir = await getTemporaryDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      int cleanedSize = 0;
      int deletedFiles = 0;

      // Clean old cache files (older than 7 days)
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

        for (final file in files) {
          if (file is File) {
            try {
              final stat = await file.stat();
              if (stat.modified.isBefore(sevenDaysAgo)) {
                final size = await file.length();
                await file.delete();
                cleanedSize += size;
                deletedFiles++;
                AppLogger.auth(
                  '🗑️ Deleted old cache file: ${file.path} (${(size / 1024).round()} KB)',
                );
              }
            } catch (e) {
              AppLogger.auth(
                'Warning: Could not delete cache file ${file.path}: $e',
              );
            }
          }
        }
      }

      // Clean Firebase cache if it's too large
      final firebaseCacheDir = Directory('${appSupportDir.path}/firebase');
      if (await firebaseCacheDir.exists()) {
        final firebaseFiles = firebaseCacheDir.listSync(recursive: true);
        int firebaseSize = 0;

        for (final file in firebaseFiles) {
          if (file is File) {
            try {
              firebaseSize += await file.length();
            } catch (e) {
              // Skip
            }
          }
        }

        // If Firebase cache is >20MB, clear it
        if (firebaseSize > 20 * 1024 * 1024) {
          AppLogger.auth(
            '🔥 Firebase cache too large (${(firebaseSize / 1024 / 1024).toStringAsFixed(2)} MB), clearing...',
          );
          try {
            await _firestore.clearPersistence();
            cleanedSize += firebaseSize;
            AppLogger.auth('✅ Firebase cache cleared');
          } catch (e) {
            AppLogger.auth('Warning: Could not clear Firebase cache: $e');
          }
        }
      }

      if (cleanedSize > 0) {
        AppLogger.auth(
          '✅ Cleaned up ${(cleanedSize / 1024 / 1024).toStringAsFixed(2)} MB, deleted $deletedFiles files',
        );
      } else {
        AppLogger.auth('ℹ️ No excessive storage found to clean');
      }
    } catch (e) {
      AppLogger.auth('Warning: Could not cleanup excessive storage: $e');
    }
  }

  // Log storage state for debugging
  Future<void> _logStorageState(String context) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appDir = await getApplicationDocumentsDirectory();
      final appSupportDir = await getApplicationSupportDirectory();

      int cacheFiles = 0;
      int cacheSize = 0;
      int appTempFiles = 0;
      int appSupportFiles = 0;
      int appSupportSize = 0;

      // Count cache directory files
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync(recursive: true);
        cacheFiles = files.length;
        for (final file in files) {
          if (file is File) {
            try {
              cacheSize += await file.length();
            } catch (e) {
              // Skip files we can't read
            }
          }
        }
      }

      // Count app temp directory files
      final tempDirs = ['temp_photos', 'media_temp', 'cache', 'temp'];
      for (final dirName in tempDirs) {
        final tempDir = Directory('${appDir.path}/$dirName');
        if (await tempDir.exists()) {
          appTempFiles += tempDir.listSync(recursive: true).length;
        }
      }

      // Count app support directory files (Firebase, etc.)
      if (await appSupportDir.exists()) {
        final files = appSupportDir.listSync(recursive: true);
        appSupportFiles = files.length;
        for (final file in files) {
          if (file is File) {
            try {
              appSupportSize += await file.length();
            } catch (e) {
              // Skip files we can't read
            }
          }
        }
      }

      final totalSize = cacheSize + appSupportSize;

      AppLogger.auth('📊 Storage state $context:');
      AppLogger.auth(
        '   Cache directory: $cacheFiles files (${(cacheSize / 1024).round()} KB)',
      );
      AppLogger.auth('   App temp files: $appTempFiles items');
      AppLogger.auth(
        '   App support: $appSupportFiles files (${(appSupportSize / 1024).round()} KB)',
      );
      AppLogger.auth(
        '   📈 Total estimated: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Detailed breakdown if size is significant
      if (totalSize > 10 * 1024 * 1024) {
        // > 10MB
        await _analyzeLargeStorage(cacheDir, appDir, appSupportDir);
      }
    } catch (e) {
      AppLogger.auth('ℹ️ Could not log storage state: $e');
    }
  }

  // Analyze what's taking up large amounts of storage
  Future<void> _analyzeLargeStorage(
    Directory cacheDir,
    Directory appDir,
    Directory appSupportDir,
  ) async {
    try {
      AppLogger.auth('🔍 Analyzing large storage usage...');

      // Check cache directory breakdown
      if (await cacheDir.exists()) {
        final cacheContents = cacheDir.listSync(recursive: false);
        for (final item in cacheContents) {
          if (item is Directory) {
            final files = item.listSync(recursive: true);
            int dirSize = 0;
            for (final file in files) {
              if (file is File) {
                try {
                  dirSize += await file.length();
                } catch (e) {
                  // Skip
                }
              }
            }
            if (dirSize > 1024 * 1024) {
              // > 1MB
              AppLogger.auth(
                '   📁 Large cache dir: ${item.path} (${(dirSize / 1024 / 1024).toStringAsFixed(2)} MB, ${files.length} files)',
              );
            }
          } else if (item is File) {
            try {
              final size = await item.length();
              if (size > 1024 * 1024) {
                // > 1MB
                AppLogger.auth(
                  '   📄 Large cache file: ${item.path} (${(size / 1024 / 1024).toStringAsFixed(2)} MB)',
                );
              }
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Check app support directory (Firebase, etc.)
      if (await appSupportDir.exists()) {
        final supportContents = appSupportDir.listSync(recursive: false);
        for (final item in supportContents) {
          if (item is Directory) {
            final files = item.listSync(recursive: true);
            int dirSize = 0;
            for (final file in files) {
              if (file is File) {
                try {
                  dirSize += await file.length();
                } catch (e) {
                  // Skip
                }
              }
            }
            if (dirSize > 1024 * 1024) {
              // > 1MB
              AppLogger.auth(
                '   📁 Large support dir: ${item.path} (${(dirSize / 1024 / 1024).toStringAsFixed(2)} MB, ${files.length} files)',
              );
            }
          } else if (item is File) {
            try {
              final size = await item.length();
              if (size > 1024 * 1024) {
                // > 1MB
                AppLogger.auth(
                  '   📄 Large support file: ${item.path} (${(size / 1024 / 1024).toStringAsFixed(2)} MB)',
                );
              }
            } catch (e) {
              // Skip
            }
          }
        }
      }

      // Check for Firebase cache specifically
      final firebaseCacheDir = Directory('${appSupportDir.path}/firebase');
      if (await firebaseCacheDir.exists()) {
        final firebaseFiles = firebaseCacheDir.listSync(recursive: true);
        int firebaseSize = 0;
        for (final file in firebaseFiles) {
          if (file is File) {
            try {
              firebaseSize += await file.length();
            } catch (e) {
              // Skip
            }
          }
        }
        AppLogger.auth(
          '   🔥 Firebase cache: ${firebaseFiles.length} files (${(firebaseSize / 1024 / 1024).toStringAsFixed(2)} MB)',
        );
      }
    } catch (e) {
      AppLogger.auth('ℹ️ Could not analyze large storage: $e');
    }
  }

  // Clear image cache
  Future<void> _clearImageCache() async {
    try {
      // Clear Flutter's image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      AppLogger.auth('✅ Flutter image cache cleared');

      // Note: If using cached_network_image package, you would also clear its cache:
      // await DefaultCacheManager().emptyCache();
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear image cache: $e');
    }
  }

  // Clear HTTP cache
  Future<void> _clearHttpCache() async {
    try {
      // Note: Flutter doesn't have a built-in HTTP cache, but if you're using
      // packages like dio with cache interceptors, you would clear them here
      AppLogger.auth(
        'ℹ️ HTTP cache clearing not implemented (no HTTP caching detected)',
      );
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear HTTP cache: $e');
    }
  }

  // Clear temporary files
  Future<void> _clearTempFiles() async {
    try {
      // Clear system temp directory
      final systemTempDir = Directory.systemTemp;
      if (await systemTempDir.exists()) {
        final tempFiles = systemTempDir.listSync(recursive: false);
        int deletedCount = 0;

        for (final file in tempFiles) {
          try {
            if (file is File) {
              // Only delete files older than 1 hour to be safe
              final stat = await file.stat();
              final age = DateTime.now().difference(stat.modified);
              if (age.inHours > 1) {
                await file.delete();
                deletedCount++;
              }
            } else if (file is Directory) {
              // Only delete empty directories or those older than 1 hour
              final stat = await file.stat();
              final age = DateTime.now().difference(stat.modified);
              if (age.inHours > 1) {
                try {
                  await file.delete(recursive: true);
                  deletedCount++;
                } catch (e) {
                  // Directory not empty, skip
                }
              }
            }
          } catch (e) {
            AppLogger.auth('Warning: Failed to delete temp item ${file.path}: $e');
          }
        }

        if (deletedCount > 0) {
          AppLogger.auth('✅ Cleared $deletedCount temp files/directories');
        } else {
          AppLogger.auth('ℹ️ No old temp files to clear');
        }
      }
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear temp files: $e');
    }
  }

  // Clear file upload service temporary files
  Future<void> _clearFileUploadTempFiles() async {
    try {
      // Import the service dynamically to avoid circular dependencies
      // This is a simplified approach - in production, you'd inject the service

      // Clear temp photos directory
      try {
        final directory = await getApplicationDocumentsDirectory();
        final tempDir = Directory('${directory.path}/temp_photos');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
          AppLogger.auth('✅ File upload temp photos cleared');
        }
      } catch (e) {
        AppLogger.auth('Warning: Failed to clear temp photos: $e');
      }

      // Clear media temp directory
      try {
        final directory = await getApplicationDocumentsDirectory();
        final mediaTempDir = Directory('${directory.path}/media_temp');
        if (await mediaTempDir.exists()) {
          await mediaTempDir.delete(recursive: true);
          AppLogger.auth('✅ File upload media temp files cleared');
        }
      } catch (e) {
        AppLogger.auth('Warning: Failed to clear media temp files: $e');
      }
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear file upload temp files: $e');
    }
  }

  // Clear all app directories and cache
  Future<void> _clearAllAppDirectories() async {
    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      AppLogger.auth('📁 Clearing app directory: ${appDir.path}');

      // Clear all subdirectories except those we want to keep
      final subDirs = ['temp_photos', 'media_temp', 'cache', 'temp'];
      for (final subDirName in subDirs) {
        try {
          final subDir = Directory('${appDir.path}/$subDirName');
          if (await subDir.exists()) {
            await subDir.delete(recursive: true);
            AppLogger.auth('✅ Cleared directory: $subDirName');
          }
        } catch (e) {
          AppLogger.auth('Warning: Failed to clear $subDirName: $e');
        }
      }

      // Clear cache directory
      try {
        final cacheDir = await getTemporaryDirectory();
        if (await cacheDir.exists()) {
          // Clear all files in cache directory
          final files = cacheDir.listSync(recursive: true);
          for (final file in files) {
            if (file is File) {
              try {
                await file.delete();
              } catch (e) {
                AppLogger.auth(
                  'Warning: Failed to delete cache file ${file.path}: $e',
                );
              }
            }
          }
          AppLogger.auth('✅ Cache directory cleared');
        }
      } catch (e) {
        AppLogger.auth('Warning: Failed to clear cache directory: $e');
      }

      // Note: External storage cache clearing removed to avoid import complexity
      // In production, you might want to add this back with proper platform-specific imports
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear app directories: $e');
    }
  }

  // Clear cache for logout (lighter version that preserves user preferences)
  Future<void> _clearLogoutCache() async {
    try {
      AppLogger.auth('🧹 Starting logout cache cleanup...');

      // Log initial storage state
      await _logStorageState('BEFORE logout');

      // Clear Firebase local cache (but keep user data)
      try {
        await _firestore.clearPersistence();
        AppLogger.auth('✅ Firebase local cache cleared');
      } catch (cacheError) {
        // Handle specific cache clearing errors gracefully
        final errorMessage = cacheError.toString();
        if (errorMessage.contains('failed-precondition') ||
            errorMessage.contains('not in a state') ||
            errorMessage.contains('Operation was rejected')) {
          AppLogger.auth(
            'ℹ️ Firebase cache clearing skipped (normal after sign-out)',
          );
        } else {
          AppLogger.auth('Warning: Firebase cache clearing failed: $cacheError');
        }
      }

      // Clear image cache (session-specific images)
      await _clearImageCache();

      // Clear temporary files (now properly implemented)
      await _clearTempFiles();

      // Clear file upload service temp files (this actually works)
      await _clearFileUploadTempFiles();

      // Clear cache directory (but preserve user preferences in SharedPreferences)
      try {
        final cacheDir = await getTemporaryDirectory();
        AppLogger.auth('📁 Checking cache directory: ${cacheDir.path}');
        if (await cacheDir.exists()) {
          final files = cacheDir.listSync(recursive: true);
          AppLogger.auth('📊 Found ${files.length} items in cache directory');

          int deletedFiles = 0;
          int deletedDirs = 0;

          for (final file in files) {
            if (file is File) {
              try {
                final size = await file.length();
                await file.delete();
                deletedFiles++;
                AppLogger.auth(
                  '🗑️ Deleted cache file: ${file.path} ($size bytes)',
                );
              } catch (e) {
                AppLogger.auth(
                  'Warning: Failed to delete cache file ${file.path}: $e',
                );
              }
            } else if (file is Directory) {
              try {
                await file.delete(recursive: true);
                deletedDirs++;
                AppLogger.auth('🗑️ Deleted cache directory: ${file.path}');
              } catch (e) {
                AppLogger.auth(
                  'Warning: Failed to delete cache directory ${file.path}: $e',
                );
              }
            }
          }
          AppLogger.auth(
            '✅ Cache directory cleared - deleted $deletedFiles files and $deletedDirs directories',
          );
        } else {
          AppLogger.auth('ℹ️ Cache directory does not exist');
        }
      } catch (e) {
        AppLogger.auth('Warning: Failed to clear cache directory: $e');
      }

      // Clear application documents temp directories
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final tempDirs = ['temp_photos', 'media_temp', 'cache', 'temp'];

        for (final dirName in tempDirs) {
          try {
            final tempDir = Directory('${appDir.path}/$dirName');
            if (await tempDir.exists()) {
              await tempDir.delete(recursive: true);
              AppLogger.auth('✅ Cleared temp directory: $dirName');
            }
          } catch (e) {
            AppLogger.auth('Warning: Failed to clear $dirName: $e');
          }
        }
      } catch (e) {
        AppLogger.auth('Warning: Failed to clear app temp directories: $e');
      }

      AppLogger.auth('✅ Logout cache cleanup completed');

      // Log final storage state
      await _logStorageState('AFTER logout');

      // Log storage cleanup summary
      try {
        final cacheDir = await getTemporaryDirectory();
        final appDir = await getApplicationDocumentsDirectory();

        // Check remaining items
        int cacheItems = 0;
        int appTempItems = 0;

        if (await cacheDir.exists()) {
          cacheItems = cacheDir.listSync(recursive: true).length;
        }

        final tempDirs = ['temp_photos', 'media_temp', 'cache', 'temp'];
        for (final dirName in tempDirs) {
          final tempDir = Directory('${appDir.path}/$dirName');
          if (await tempDir.exists()) {
            appTempItems += tempDir.listSync(recursive: true).length;
          }
        }

        AppLogger.auth('📊 Storage cleanup summary:');
        AppLogger.auth('   Cache directory: $cacheItems items remaining');
        AppLogger.auth('   App temp dirs: $appTempItems items remaining');
        AppLogger.auth('   ✅ Session data cleared successfully');
      } catch (e) {
        AppLogger.auth('ℹ️ Could not generate cleanup summary: $e');
      }
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear some logout cache: $e');
    }
  }
}
