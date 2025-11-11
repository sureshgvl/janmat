import '../models/candidate_model.dart';
import '../../../utils/app_logger.dart';

/// Service responsible for pagination logic and state management.
/// Handles loading more data, tracking pagination state, and progressive loading.
class PaginationManager<T> {
  final Future<List<T>> Function(int offset, int limit) loadFunction;
  final int pageSize;
  final String logTag;

  PaginationManager({
    required this.loadFunction,
    this.pageSize = 20,
    this.logTag = 'PaginationManager',
  });

  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentOffset = 0;
  final List<T> _items = [];

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  int get currentOffset => _currentOffset;
  List<T> get items => List.unmodifiable(_items);

  /// Load initial data (first page)
  Future<List<T>> loadInitial() async {
    AppLogger.common('🔄 [$logTag] Loading initial data (pageSize: $pageSize)');
    _reset();

    try {
      final newItems = await loadFunction(0, pageSize);
      _items.addAll(newItems);
      _currentOffset = newItems.length;
      _hasMoreData = newItems.length >= pageSize;

      AppLogger.common('✅ [$logTag] Loaded ${newItems.length} initial items, hasMore: $_hasMoreData');
      return List.from(_items);
    } catch (e) {
      AppLogger.common('❌ [$logTag] Error loading initial data: $e');
      _hasMoreData = false;
      return [];
    }
  }

  /// Load more data (next page)
  Future<List<T>> loadMore() async {
    if (_isLoadingMore || !_hasMoreData) {
      AppLogger.common('⚠️ [$logTag] Cannot load more: loading=$_isLoadingMore, hasMore=$_hasMoreData');
      return [];
    }

    _isLoadingMore = true;
    AppLogger.common('🔄 [$logTag] Loading more data (offset: $_currentOffset, limit: $pageSize)');

    try {
      final newItems = await loadFunction(_currentOffset, pageSize);

      // Filter out duplicates (in case of data changes)
      final existingIds = _getExistingIds();
      final uniqueNewItems = newItems.where((item) => !existingIds.contains(_getItemId(item))).toList();

      _items.addAll(uniqueNewItems);
      _currentOffset += newItems.length;
      _hasMoreData = newItems.length >= pageSize;

      AppLogger.common('✅ [$logTag] Loaded ${uniqueNewItems.length} more items (${newItems.length} total from API), hasMore: $_hasMoreData');
      return uniqueNewItems;
    } catch (e) {
      AppLogger.common('❌ [$logTag] Error loading more data: $e');
      _hasMoreData = false;
      return [];
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Refresh data (reload from beginning)
  Future<List<T>> refresh() async {
    AppLogger.common('🔄 [$logTag] Refreshing data');
    _reset();
    return await loadInitial();
  }

  /// Add items manually (useful for search results)
  void setItems(List<T> newItems) {
    _items.clear();
    _items.addAll(newItems);
    _currentOffset = newItems.length;
    _hasMoreData = false; // Assume search results don't have pagination
    AppLogger.common('📝 [$logTag] Set ${newItems.length} items manually');
  }

  /// Clear all items and reset state
  void clear() {
    _reset();
    AppLogger.common('🧹 [$logTag] Cleared all items');
  }

  /// Reset pagination state
  void _reset() {
    _isLoadingMore = false;
    _hasMoreData = true;
    _currentOffset = 0;
    _items.clear();
  }

  /// Get IDs of existing items (for duplicate filtering)
  Set<String> _getExistingIds() {
    return _items.map((item) => _getItemId(item)).toSet();
  }

  /// Extract ID from item (works for Candidate and other models)
  String _getItemId(T item) {
    if (item is Candidate) {
      return item.candidateId;
    }
    // For other types, use toString hash or implement specific logic
    return item.hashCode.toString();
  }

  /// Get pagination statistics
  Map<String, dynamic> getStats() {
    return {
      'total_items': _items.length,
      'current_offset': _currentOffset,
      'page_size': pageSize,
      'is_loading_more': _isLoadingMore,
      'has_more_data': _hasMoreData,
      'current_page': (_currentOffset / pageSize).ceil(),
    };
  }

  /// Check if should load more based on scroll position
  bool shouldLoadMore(double pixels, double maxScrollExtent, {double threshold = 200.0}) {
    return pixels >= (maxScrollExtent - threshold) && !_isLoadingMore && _hasMoreData;
  }
}

/// Progressive loader for complex pagination scenarios
class ProgressiveLoader<T> {
  final Future<List<T>> Function(int offset, int limit) loadFunction;
  final int pageSize;

  ProgressiveLoader({
    required this.loadFunction,
    this.pageSize = 20,
  });

  final List<T> items = [];
  bool hasMore = true;
  bool isLoading = false;

  /// Load more items progressively
  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    try {
      final newItems = await loadFunction(items.length, pageSize);
      items.addAll(newItems);
      hasMore = newItems.length >= pageSize;
    } finally {
      isLoading = false;
    }
  }

  /// Reset loader state
  void reset() {
    items.clear();
    hasMore = true;
    isLoading = false;
  }
}
