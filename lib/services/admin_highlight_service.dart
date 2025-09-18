import 'package:cloud_firestore/cloud_firestore.dart';
import 'highlight_service.dart';

class AdminHighlightService {
  // Get pending highlights for approval
  static Future<List<Highlight>> getPendingHighlights() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('highlights')
          .where('active', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching pending highlights: $e');
      return [];
    }
  }

  // Get all active highlights
  static Future<List<Highlight>> getAllActiveHighlights() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('highlights')
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching active highlights: $e');
      return [];
    }
  }

  // Approve highlight
  static Future<bool> approveHighlight(String highlightId) async {
    try {
      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .update({
            'active': true,
            'approvedAt': FieldValue.serverTimestamp(),
            'approvedBy': 'admin_user_id', // Replace with actual admin ID
          });
      return true;
    } catch (e) {
      print('Error approving highlight: $e');
      return false;
    }
  }

  // Reject highlight
  static Future<bool> rejectHighlight(String highlightId, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .update({
            'active': false,
            'rejected': true,
            'rejectionReason': reason,
            'rejectedAt': FieldValue.serverTimestamp(),
            'rejectedBy': 'admin_user_id', // Replace with actual admin ID
          });
      return true;
    } catch (e) {
      print('Error rejecting highlight: $e');
      return false;
    }
  }

  // Deactivate highlight
  static Future<bool> deactivateHighlight(String highlightId) async {
    try {
      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .update({
            'active': false,
            'deactivatedAt': FieldValue.serverTimestamp(),
            'deactivatedBy': 'admin_user_id', // Replace with actual admin ID
          });
      return true;
    } catch (e) {
      print('Error deactivating highlight: $e');
      return false;
    }
  }

  // Update highlight priority
  static Future<bool> updateHighlightPriority(String highlightId, int priority) async {
    try {
      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .update({
            'priority': priority,
            'priorityUpdatedAt': FieldValue.serverTimestamp(),
            'priorityUpdatedBy': 'admin_user_id',
          });
      return true;
    } catch (e) {
      print('Error updating priority: $e');
      return false;
    }
  }

  // Update highlight placement
  static Future<bool> updateHighlightPlacement(String highlightId, List<String> placement) async {
    try {
      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .update({
            'placement': placement,
            'placementUpdatedAt': FieldValue.serverTimestamp(),
            'placementUpdatedBy': 'admin_user_id',
          });
      return true;
    } catch (e) {
      print('Error updating placement: $e');
      return false;
    }
  }

  // Get highlight analytics
  static Future<Map<String, dynamic>> getHighlightAnalytics(String highlightId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'views': data['views'] ?? 0,
          'clicks': data['clicks'] ?? 0,
          'ctr': data['clicks'] != null && data['views'] != null && data['views'] > 0
              ? ((data['clicks'] / data['views']) * 100).round()
              : 0,
          'lastShown': data['lastShown'],
          'createdAt': data['createdAt'],
          'startDate': data['startDate'],
          'endDate': data['endDate'],
        };
      }
      return {};
    } catch (e) {
      print('Error fetching analytics: $e');
      return {};
    }
  }

  // Bulk approve highlights
  static Future<int> bulkApproveHighlights(List<String> highlightIds) async {
    int successCount = 0;
    for (String id in highlightIds) {
      if (await approveHighlight(id)) {
        successCount++;
      }
    }
    return successCount;
  }

  // Bulk deactivate highlights
  static Future<int> bulkDeactivateHighlights(List<String> highlightIds) async {
    int successCount = 0;
    for (String id in highlightIds) {
      if (await deactivateHighlight(id)) {
        successCount++;
      }
    }
    return successCount;
  }

  // Get highlights by status
  static Future<List<Highlight>> getHighlightsByStatus(bool active) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('highlights')
          .where('active', isEqualTo: active)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching highlights by status: $e');
      return [];
    }
  }

  // Get highlights by ward
  static Future<List<Highlight>> getHighlightsByWard(String wardId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('highlights')
          .where('wardId', isEqualTo: wardId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching highlights by ward: $e');
      return [];
    }
  }

  // Get highlights by package
  static Future<List<Highlight>> getHighlightsByPackage(String package) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('highlights')
          .where('package', isEqualTo: package)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching highlights by package: $e');
      return [];
    }
  }

  // Search highlights
  static Future<List<Highlight>> searchHighlights(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation - you might want to use Algolia or ElasticSearch for production
      final snapshot = await FirebaseFirestore.instance
          .collection('highlights')
          .get();

      final allHighlights = snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();

      return allHighlights.where((highlight) {
        final candidateName = highlight.candidateName?.toLowerCase() ?? '';
        final party = highlight.party?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return candidateName.contains(searchQuery) || party.contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Error searching highlights: $e');
      return [];
    }
  }
}