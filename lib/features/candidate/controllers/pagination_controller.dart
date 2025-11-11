import 'package:get/get.dart';
import '../models/candidate_model.dart';
import '../services/pagination_manager.dart';
import '../repositories/candidate_repository.dart';
import '../../../utils/app_logger.dart';

class PaginationController extends GetxController {
  final PaginationManager<Candidate> _paginationManager;

  PaginationController({
    required Future<List<Candidate>> Function(int offset, int limit) loadFunction,
    int pageSize = 20,
  }) : _paginationManager = PaginationManager<Candidate>(
         loadFunction: loadFunction,
         pageSize: pageSize,
         logTag: 'CandidatePagination',
       );

  // Reactive state
  final RxBool showRefreshIndicator = false.obs;

  @override
  void onClose() {
    showRefreshIndicator.close();
    super.onClose();
  }

  /// Load initial data
  Future<List<Candidate>> loadInitial() async {
    AppLogger.candidate('🔄 Loading initial candidates');
    return await _paginationManager.loadInitial();
  }

  /// Load more data
  Future<List<Candidate>> loadMore() async {
    AppLogger.candidate('🔄 Loading more candidates');
    return await _paginationManager.loadMore();
  }

  /// Refresh data
  Future<List<Candidate>> refresh() async {
    AppLogger.candidate('🔄 Refreshing candidates');
    return await _paginationManager.refresh();
  }

  /// Set items manually (for search results)
  void setItems(List<Candidate> items) {
    _paginationManager.setItems(items);
    AppLogger.candidate('📝 Set ${items.length} items manually');
  }

  /// Clear all items
  void clear() {
    _paginationManager.clear();
    AppLogger.candidate('🧹 Cleared all items');
  }

  /// Get current items
  List<Candidate> get items => _paginationManager.items;

  /// Check if currently loading more
  bool get isLoadingMore => _paginationManager.isLoadingMore;

  /// Check if there's more data to load
  bool get hasMoreData => _paginationManager.hasMoreData;

  /// Get current offset
  int get currentOffset => _paginationManager.currentOffset;

  /// Get pagination statistics
  Map<String, dynamic> getStats() => _paginationManager.getStats();

  /// Check if should load more based on scroll position
  bool shouldLoadMore(double pixels, double maxScrollExtent, {double threshold = 200.0}) {
    return _paginationManager.shouldLoadMore(pixels, maxScrollExtent, threshold: threshold);
  }

  /// Handle pull-to-refresh gesture
  void handlePullToRefresh(double dragDistance, double minSwipeDistance) {
    if (dragDistance < -minSwipeDistance) {
      showRefreshIndicator.value = true;
      AppLogger.candidate('🔄 Pull-to-refresh detected');
    } else if (dragDistance > -50) {
      showRefreshIndicator.value = false;
    }
  }

  /// Reset pull-to-refresh indicator
  void resetRefreshIndicator() {
    showRefreshIndicator.value = false;
  }

  /// Handle swipe up gesture for loading more
  void handleSwipeUp(double dragDistance, double minSwipeDistance) {
    if (dragDistance > minSwipeDistance && hasMoreData) {
      AppLogger.candidate('🔄 Swipe-up detected - loading more');
      loadMore();
    }
  }
}
