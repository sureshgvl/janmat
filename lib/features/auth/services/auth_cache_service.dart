import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/painting.dart';
import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../../../features/chat/controllers/chat_controller.dart';
import '../../../features/candidate/controllers/candidate_controller.dart';
import '../../../services/admob_service.dart';

class AuthCacheService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Clear all app cache and local storage
  Future<void> clearAppCache() async {
    try {
      AppLogger.auth('🧹 Starting comprehensive cache cleanup...');

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      AppLogger.auth('✅ SharedPreferences cleared');

      // Clear Firebase local cache (handle errors gracefully)
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
            'ℹ️ Firebase cache clearing skipped (normal after account deletion)',
          );
        } else {
          AppLogger.auth('Warning: Firebase cache clearing failed: $cacheError');
        }
      }

      // Clear image cache (if using cached_network_image or similar)
      await clearImageCache();

      // Clear HTTP cache
      await clearHttpCache();

      // Clear temporary files
      await clearTempFiles();

      // Clear file upload service temp files
      await clearFileUploadTempFiles();

      // Clear all app directories and cache
      await clearAllAppDirectories();

      AppLogger.auth('✅ Comprehensive cache cleanup completed');
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear some cache: $e');
      // Don't throw here as cache clearing failure shouldn't stop account deletion
    }
  }

  // Clear all GetX controllers (except LoginController which is needed for login screen)
  Future<void> clearAllControllers() async {
    try {
      // Delete all registered controllers except LoginController (needed for login screen)
      // Don't clear LoginController as it's required when navigating back to login
      if (Get.isRegistered<ChatController>()) {
        Get.delete<ChatController>(force: true);
      }
      if (Get.isRegistered<CandidateController>()) {
        Get.delete<CandidateController>(force: true);
      }
      if (Get.isRegistered<AdMobService>()) {
        Get.delete<AdMobService>(force: true);
      }

      AppLogger.auth(
        '✅ Controllers cleared (LoginController preserved for login screen)',
      );
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear some controllers: $e');
    }
  }

  // Clear cache for logout (lighter version that preserves user preferences)
  Future<void> clearLogoutCache() async {
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
      await clearImageCache();

      // Clear temporary files (now properly implemented)
      await clearTempFiles();

      // Clear file upload service temp files (this actually works)
      await clearFileUploadTempFiles();

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

  // Clear image cache
  Future<void> clearImageCache() async {
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
  Future<void> clearHttpCache() async {
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
  Future<void> clearTempFiles() async {
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
  Future<void> clearFileUploadTempFiles() async {
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
  Future<void> clearAllAppDirectories() async {
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

  // Clear app setup flags (for complete reset)
  Future<void> clearAppSetupFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_first_time');
      await prefs.remove('onboarding_completed');
      AppLogger.auth('✅ Cleared app setup flags (language selection and onboarding)');
    } catch (e) {
      AppLogger.auth('⚠️ Error clearing app setup flags: $e');
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
}
