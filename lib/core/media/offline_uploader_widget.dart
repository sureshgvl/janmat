import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'media_file.dart';
import 'media_picker.dart';
import 'media_uploader_advanced.dart';

/// Offline-compatible uploader that queues uploads when offline
/// Automatically retries when connection is restored
class OfflineUploaderWidget extends StatefulWidget {
  final String userId;
  final String category;
  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final Function(List<String> urls)? onUploadComplete;
  final Function(String error)? onUploadError;

  const OfflineUploaderWidget({
    super.key,
    required this.userId,
    required this.category,
    this.allowMultiple = true,
    this.allowedExtensions,
    this.onUploadComplete,
    this.onUploadError,
  });

  @override
  State<OfflineUploaderWidget> createState() => _OfflineUploaderWidgetState();
}

class _OfflineUploaderWidgetState extends State<OfflineUploaderWidget> {
  List<MediaFile> selectedFiles = [];
  List<QueuedUpload> queuedUploads = [];
  bool isOnline = true;
  bool isUploading = false;
  bool isPicking = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final MediaUploaderAdvanced _uploader = MediaUploaderAdvanced();
  late Box<QueuedUpload> _queueBox;

  @override
  void initState() {
    super.initState();
    _initializeOfflineSupport();
    _checkConnectivity();
    _loadQueuedUploads();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeOfflineSupport() async {
    await Hive.initFlutter();
    Hive.registerAdapter(QueuedUploadAdapter());
    _queueBox = await Hive.openBox<QueuedUpload>('upload_queue');
  }

  Future<void> _checkConnectivity() async {
    final connectivity = Connectivity();
    final results = await connectivity.checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;

    setState(() {
      isOnline = result != ConnectivityResult.none;
    });

    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
        final wasOffline = !isOnline;
        final nowOnline = result != ConnectivityResult.none;

        setState(() {
          isOnline = nowOnline;
        });

        // If we just came back online, retry queued uploads
        if (wasOffline && nowOnline) {
          _retryQueuedUploads();
        }
      },
    );
  }

  Future<void> _loadQueuedUploads() async {
    final queued = _queueBox.values.toList();
    setState(() {
      queuedUploads = queued;
    });
  }

  Future<void> _pickFiles() async {
    if (isPicking) return;

    setState(() => isPicking = true);

    try {
      final files = await MediaPicker.pickFiles(
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: widget.allowMultiple,
      );

      if (files.isNotEmpty && mounted) {
        setState(() {
          selectedFiles = widget.allowMultiple ? [...selectedFiles, ...files] : files;
        });
      }
    } catch (e) {
      widget.onUploadError?.call('Failed to pick files: $e');
    } finally {
      if (mounted) {
        setState(() => isPicking = false);
      }
    }
  }

  Future<void> _startUpload() async {
    if (selectedFiles.isEmpty || isUploading) return;

    if (!isOnline) {
      // Queue for offline upload
      await _queueFilesForUpload(selectedFiles);
      setState(() {
        selectedFiles.clear();
      });
      return;
    }

    // Upload immediately
    await _uploadFiles(selectedFiles);
  }

  Future<void> _uploadFiles(List<MediaFile> files) async {
    setState(() => isUploading = true);

    try {
      final urls = await _uploader.uploadFiles(
        files,
        userId: widget.userId,
        category: widget.category,
        onProgress: (fileId, progress) {
          // Update progress in queued uploads if applicable
          final index = queuedUploads.indexWhere((q) => q.fileId == fileId);
          if (index != -1 && mounted) {
            setState(() {
              queuedUploads[index] = queuedUploads[index].copyWith(
                progress: progress.percent,
              );
            });
          }
        },
        onComplete: (fileId, url) {
          // Remove from queue if it was queued
          _removeFromQueue(fileId);
          debugPrint('Upload completed: $fileId -> $url');
        },
        onError: (fileId, error) {
          // Mark as failed in queue
          final index = queuedUploads.indexWhere((q) => q.fileId == fileId);
          if (index != -1 && mounted) {
            setState(() {
              queuedUploads[index] = queuedUploads[index].copyWith(
                status: UploadStatus.failed,
                error: error,
              );
            });
          }
          widget.onUploadError?.call('Upload failed for $fileId: $error');
        },
      );

      widget.onUploadComplete?.call(urls);

      if (mounted) {
        setState(() {
          selectedFiles.clear();
        });
      }
    } catch (e) {
      widget.onUploadError?.call('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  Future<void> _queueFilesForUpload(List<MediaFile> files) async {
    for (final file in files) {
      final queued = QueuedUpload(
        fileId: file.id,
        fileName: file.name,
        fileType: file.type,
        fileBytes: file.bytes,
        fileSize: file.size,
        userId: widget.userId,
        category: widget.category,
        timestamp: DateTime.now(),
        status: UploadStatus.queued,
      );

      await _queueBox.put(file.id, queued);
    }

    await _loadQueuedUploads();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Files queued for upload when online'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _retryQueuedUploads() async {
    final pendingUploads = queuedUploads
        .where((q) => q.status == UploadStatus.queued || q.status == UploadStatus.failed)
        .toList();

    if (pendingUploads.isEmpty) return;

    for (final queued in pendingUploads) {
      final mediaFile = MediaFile(
        id: queued.fileId,
        name: queued.fileName,
        type: queued.fileType,
        bytes: Uint8List.fromList(queued.fileBytes),
        size: queued.fileSize,
      );

      await _uploadFiles([mediaFile]);
    }
  }

  Future<void> _removeFromQueue(String fileId) async {
    await _queueBox.delete(fileId);
    await _loadQueuedUploads();
  }

  void _removeFile(int index) {
    if (!isUploading) {
      setState(() {
        selectedFiles.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            Row(
              children: [
                Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  color: isOnline ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline ? 'Online' : 'Offline - Files will be queued',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isOnline ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pick Files Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isPicking ? null : _pickFiles,
                icon: isPicking
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate),
                label: Text(isPicking ? 'Picking Files...' : 'Pick Files'),
              ),
            ),

            const SizedBox(height: 16),

            // Selected Files
            if (selectedFiles.isNotEmpty) ...[
              Text(
                'Ready to Upload (${selectedFiles.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Chip(
                    label: Text(file.name),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeFile(index),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Upload Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isUploading || selectedFiles.isEmpty ? null : _startUpload,
                  icon: isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Icon(isOnline ? Icons.cloud_upload : Icons.schedule),
                  label: Text(
                    isUploading
                        ? 'Uploading...'
                        : isOnline
                            ? 'Upload Now'
                            : 'Queue for Later',
                  ),
                ),
              ),
            ],

            // Queued Uploads
            if (queuedUploads.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Queued Uploads (${queuedUploads.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: queuedUploads.length,
                itemBuilder: (context, index) {
                  final queued = queuedUploads[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        queued.status == UploadStatus.completed
                            ? Icons.check_circle
                            : queued.status == UploadStatus.failed
                                ? Icons.error
                                : Icons.schedule,
                        color: queued.status == UploadStatus.completed
                            ? Colors.green
                            : queued.status == UploadStatus.failed
                                ? Colors.red
                                : Colors.orange,
                      ),
                      title: Text(queued.fileName),
                      subtitle: Text(
                        queued.status == UploadStatus.completed
                            ? 'Completed'
                            : queued.status == UploadStatus.failed
                                ? 'Failed: ${queued.error}'
                                : isOnline
                                    ? 'Uploading...'
                                    : 'Waiting for connection',
                      ),
                      trailing: queued.status == UploadStatus.failed
                          ? IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: isOnline ? () => _retryUpload(queued) : null,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _retryUpload(QueuedUpload queued) async {
    final mediaFile = MediaFile(
      id: queued.fileId,
      name: queued.fileName,
      type: queued.fileType,
      bytes: Uint8List.fromList(queued.fileBytes),
      size: queued.fileSize,
    );

    await _uploadFiles([mediaFile]);
  }
}

// Hive model for queued uploads
class QueuedUpload {
  final String fileId;
  final String fileName;
  final String fileType;
  final List<int> fileBytes;
  final int fileSize;
  final String userId;
  final String category;
  final DateTime timestamp;
  final UploadStatus status;
  final double progress;
  final String? error;

  QueuedUpload({
    required this.fileId,
    required this.fileName,
    required this.fileType,
    required this.fileBytes,
    required this.fileSize,
    required this.userId,
    required this.category,
    required this.timestamp,
    this.status = UploadStatus.queued,
    this.progress = 0.0,
    this.error,
  });

  QueuedUpload copyWith({
    String? fileId,
    String? fileName,
    String? fileType,
    List<int>? fileBytes,
    int? fileSize,
    String? userId,
    String? category,
    DateTime? timestamp,
    UploadStatus? status,
    double? progress,
    String? error,
  }) {
    return QueuedUpload(
      fileId: fileId ?? this.fileId,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileBytes: fileBytes ?? this.fileBytes,
      fileSize: fileSize ?? this.fileSize,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'fileName': fileName,
      'fileType': fileType,
      'fileBytes': base64Encode(fileBytes),
      'fileSize': fileSize,
      'userId': userId,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
      'progress': progress,
      'error': error,
    };
  }

  factory QueuedUpload.fromJson(Map<String, dynamic> json) {
    return QueuedUpload(
      fileId: json['fileId'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      fileBytes: base64Decode(json['fileBytes']),
      fileSize: json['fileSize'],
      userId: json['userId'],
      category: json['category'],
      timestamp: DateTime.parse(json['timestamp']),
      status: UploadStatus.values[json['status']],
      progress: json['progress'],
      error: json['error'],
    );
  }
}

enum UploadStatus { queued, uploading, completed, failed }

class QueuedUploadAdapter extends TypeAdapter<QueuedUpload> {
  @override
  final int typeId = 0;

  @override
  QueuedUpload read(BinaryReader reader) {
    final json = reader.readMap();
    return QueuedUpload.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  void write(BinaryWriter writer, QueuedUpload obj) {
    writer.writeMap(obj.toJson());
  }
}