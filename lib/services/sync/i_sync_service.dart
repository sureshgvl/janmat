import 'dart:io';
import 'package:flutter/foundation.dart';

// Enum for operation types
enum SyncOperationType {
  upload,
  update,
  delete,
}

// Model for sync operations
class SyncOperation {
  final String id;
  final SyncOperationType type;
  final String candidateId;
  final String target;
  final Map<String, dynamic> payload;
  final int retries;
  final String status; // 'pending', 'processing', 'completed', 'failed'

  SyncOperation({
    required this.id,
    required this.type,
    required this.candidateId,
    required this.target,
    required this.payload,
    this.retries = 0,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'candidateId': candidateId,
      'target': target,
      'payload': payload,
      'retries': retries,
      'status': status,
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'],
      type: SyncOperationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      candidateId: json['candidateId'],
      target: json['target'],
      payload: json['payload'],
      retries: json['retries'] ?? 0,
      status: json['status'] ?? 'pending',
    );
  }
}

// Platform-agnostic sync service interface
abstract class ISyncService {
  Future<void> start();

  Future<void> pause();

  Future<int> getPendingCount();

  Future<void> queueOperation(SyncOperation op);

  Future<void> queueUpload(
    String candidateId,
    String tempId,
    dynamic localFile,
    dynamic webFile,
    {
      required String fileType,
    }
  );

  Future<void> processQueue({int maxItems});

  Future<void> markSynced(String opId);
}
