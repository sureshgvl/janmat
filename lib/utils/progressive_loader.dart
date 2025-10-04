import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'performance_monitor.dart';

/// Progressive loading states
enum LoadingState { idle, loading, loaded, error, noMoreData }

/// Progressive loader for large datasets
class ProgressiveLoader<T> {
  final Future<List<T>> Function(int offset, int limit) _loadFunction;
  final int _pageSize;
  final List<T> _items = [];
  LoadingState _state = LoadingState.idle;
  bool _hasMore = true;
  Object? _error;
  final StreamController<LoadingState> _stateController =
      StreamController<LoadingState>.broadcast();
  final StreamController<List<T>> _itemsController =
      StreamController<List<T>>.broadcast();

  ProgressiveLoader(this._loadFunction, {int pageSize = 20})
    : _pageSize = pageSize {
    _log('🚀 ProgressiveLoader initialized with page size: $_pageSize');
  }

  Stream<LoadingState> get stateStream => _stateController.stream;
  Stream<List<T>> get itemsStream => _itemsController.stream;
  LoadingState get state => _state;
  List<T> get items => List.unmodifiable(_items);
  bool get hasMore => _hasMore;
  bool get isLoading => _state == LoadingState.loading;
  Object? get error => _error;

  /// Load next page of data
  Future<void> loadMore() async {
    if (_state == LoadingState.loading || !_hasMore) {
      _log(
        '⚠️ Cannot load more: loading=${_state == LoadingState.loading}, hasMore=$_hasMore',
      );
      return;
    }

    _state = LoadingState.loading;
    _stateController.add(_state);
    _error = null;

    _log('📥 Loading page: offset=${_items.length}, limit=$_pageSize');

    try {
      final newItems = await _loadFunction(_items.length, _pageSize);

      if (newItems.length < _pageSize) {
        _hasMore = false;
        _log(
          '🏁 No more data available (received ${newItems.length}/$_pageSize items)',
        );
      }

      _items.addAll(newItems);
      _state = LoadingState.loaded;
      _stateController.add(_state);
      _itemsController.add(List.from(_items));

      _log('✅ Loaded ${newItems.length} items (total: ${_items.length})');
    } catch (e) {
      _error = e;
      _state = LoadingState.error;
      _stateController.add(_state);

      _log('❌ Loading failed: $e');
      rethrow;
    }
  }

  /// Refresh and reload all data
  Future<void> refresh() async {
    _log('🔄 Refreshing progressive loader');

    _items.clear();
    _hasMore = true;
    _error = null;
    _state = LoadingState.idle;

    await loadMore();
  }

  /// Reset loader to initial state
  void reset() {
    _log('🔄 Resetting progressive loader');

    _items.clear();
    _hasMore = true;
    _error = null;
    _state = LoadingState.idle;
    _stateController.add(_state);
    _itemsController.add(List.from(_items));
  }

  /// Get loading statistics
  Map<String, dynamic> getStats() {
    return {
      'totalItems': _items.length,
      'pageSize': _pageSize,
      'pagesLoaded': (_items.length / _pageSize).ceil(),
      'hasMore': _hasMore,
      'state': _state.toString(),
      'error': _error?.toString(),
    };
  }

  void dispose() {
    _stateController.close();
    _itemsController.close();
    _log('🗑️ ProgressiveLoader disposed');
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('📄 PROGRESSIVE: $message');
    }
  }
}

/// Virtual scroll manager for efficient large list rendering
class VirtualScrollManager {
  final ScrollController _scrollController;
  final VoidCallback _onLoadMore;
  final double _threshold;
  final double _velocityThreshold;
  bool _isLoading = false;
  final StreamController<ScrollEvent> _scrollEventController =
      StreamController<ScrollEvent>.broadcast();

  VirtualScrollManager(
    this._scrollController,
    this._onLoadMore, {
    double threshold = 0.8,
    double velocityThreshold = 1000.0,
  }) : _threshold = threshold,
       _velocityThreshold = velocityThreshold {
    _scrollController.addListener(_onScroll);
    _log(
      '🚀 VirtualScrollManager initialized (threshold: $_threshold, velocity: $_velocityThreshold)',
    );
  }

  Stream<ScrollEvent> get scrollEventStream => _scrollEventController.stream;

  void _onScroll() {
    if (_isLoading) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final velocity = _scrollController.position.activity?.velocity ?? 0.0;

    final thresholdScroll = maxScroll * _threshold;
    final progress = currentScroll / maxScroll;

    // Emit scroll event
    _scrollEventController.add(
      ScrollEvent(
        position: currentScroll,
        maxPosition: maxScroll,
        progress: progress,
        velocity: velocity,
      ),
    );

    // Check if we should load more
    if (currentScroll >= thresholdScroll) {
      // Additional velocity check for better UX
      if (velocity > _velocityThreshold) {
        _log('⚡ Fast scroll detected, loading more data');
      }

      _isLoading = true;
      _log(
        '🎯 Scroll threshold reached (${(progress * 100).toStringAsFixed(1)}%), loading more data',
      );

      Future<void>(() => _onLoadMore()).whenComplete(() {
        _isLoading = false;
        _log('✅ Load more operation completed');
      });
    }
  }

  /// Jump to specific item index
  void jumpToIndex(int index, {double alignment = 0.0}) {
    // Estimate position based on item height (you might want to customize this)
    const estimatedItemHeight = 80.0;
    final position = index * estimatedItemHeight;

    _scrollController.jumpTo(
      position.clamp(0.0, _scrollController.position.maxScrollExtent),
    );
    _log('🎯 Jumped to index $index (estimated position: $position)');
  }

  /// Animate to specific item index
  void animateToIndex(
    int index, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
  }) {
    const estimatedItemHeight = 80.0;
    final position = index * estimatedItemHeight;

    _scrollController.animateTo(
      position.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: duration,
      curve: curve,
    );

    _log('🎬 Animating to index $index (estimated position: $position)');
  }

  /// Get scroll statistics
  Map<String, dynamic> getScrollStats() {
    final position = _scrollController.position;
    return {
      'currentPosition': position.pixels,
      'maxPosition': position.maxScrollExtent,
      'minPosition': position.minScrollExtent,
      'progress': position.pixels / position.maxScrollExtent,
      'velocity': position.activity?.velocity ?? 0.0,
      'isScrolling': position.activity?.isScrolling ?? false,
      'threshold': _threshold,
      'isLoading': _isLoading,
    };
  }

  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollEventController.close();
    _log('🗑️ VirtualScrollManager disposed');
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('📜 VIRTUAL: $message');
    }
  }
}

/// Scroll event data
class ScrollEvent {
  final double position;
  final double maxPosition;
  final double progress;
  final double velocity;

  ScrollEvent({
    required this.position,
    required this.maxPosition,
    required this.progress,
    required this.velocity,
  });

  @override
  String toString() {
    return 'ScrollEvent(position: ${position.toStringAsFixed(1)}, '
        'progress: ${(progress * 100).toStringAsFixed(1)}%, '
        'velocity: ${velocity.toStringAsFixed(1)})';
  }
}

/// Smart list widget with progressive loading and virtual scrolling
class SmartListView<T> extends StatefulWidget {
  final ProgressiveLoader<T> loader;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final double scrollThreshold;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const SmartListView({
    super.key,
    required this.loader,
    required this.itemBuilder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.scrollThreshold = 0.8,
    this.padding,
    this.physics,
  });

  @override
  State<SmartListView<T>> createState() => _SmartListViewState<T>();
}

class _SmartListViewState<T> extends State<SmartListView<T>> {
  final ScrollController _scrollController = ScrollController();
  late VirtualScrollManager _scrollManager;
  late StreamSubscription<LoadingState> _stateSubscription;
  late StreamSubscription<List<T>> _itemsSubscription;
  late StreamSubscription<ScrollEvent> _scrollEventSubscription;

  @override
  void initState() {
    super.initState();

    _scrollManager = VirtualScrollManager(
      _scrollController,
      _loadMore,
      threshold: widget.scrollThreshold,
    );

    _stateSubscription = widget.loader.stateStream.listen((state) {
      if (mounted) setState(() {});
    });

    _itemsSubscription = widget.loader.itemsStream.listen((items) {
      if (mounted) setState(() {});
    });

    _scrollEventSubscription = _scrollManager.scrollEventStream.listen((event) {
      // Optional: Handle scroll events for analytics
      if (kDebugMode) {
        debugPrint(
          '📊 Scroll progress: ${(event.progress * 100).toStringAsFixed(1)}%',
        );
      }
    });

    // Initial load
    if (widget.loader.items.isEmpty) {
      widget.loader.loadMore();
    }
  }

  Future<void> _loadMore() async {
    await widget.loader.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.loader.items;

    if (widget.loader.state == LoadingState.error) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    if (items.isEmpty && widget.loader.state == LoadingState.idle) {
      return widget.emptyWidget ?? _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: widget.loader.refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics,
        itemCount: items.length + (widget.loader.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            // Loading indicator
            return widget.loadingWidget ?? _buildLoadingWidget();
          }

          return widget.itemBuilder(context, items[index], index);
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: ${widget.loader.error}'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadMore, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('No items found'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    _itemsSubscription.cancel();
    _scrollEventSubscription.cancel();
    _scrollManager.dispose();
    super.dispose();
  }
}

/// Firebase-specific progressive loader
class FirebaseProgressiveLoader<T> extends ProgressiveLoader<T> {
  FirebaseProgressiveLoader(super.loadFunction, {super.pageSize});

  /// Load with Firebase-specific optimizations
  @override
  Future<void> loadMore() async {
    if (state == LoadingState.loading || !hasMore) {
      return;
    }

    _log(
      '🔥 Firebase progressive load: offset=${items.length}, limit=$pageSize',
    );

    // Add Firebase-specific performance monitoring
    final monitor = PerformanceMonitor();
    monitor.startTimer('firebase_progressive_load');

    try {
      await super.loadMore();
      monitor.trackFirebaseRead('progressive_collection', _pageSize);
      monitor.stopTimer('firebase_progressive_load');
    } catch (e) {
      monitor.stopTimer('firebase_progressive_load');
      rethrow;
    }
  }

  int get pageSize => _pageSize;
}

/// Infinite scroll hook for easy integration
class InfiniteScrollHook {
  final ProgressiveLoader _loader;
  final ScrollController _scrollController;
  late VirtualScrollManager _scrollManager;

  InfiniteScrollHook(
    this._loader,
    this._scrollController, {
    double threshold = 0.8,
  }) {
    _scrollManager = VirtualScrollManager(
      _scrollController,
      () => _loader.loadMore(),
      threshold: threshold,
    );

    _log('🪝 InfiniteScrollHook initialized');
  }

  /// Get current scroll statistics
  Map<String, dynamic> getStats() {
    return {
      'loaderStats': _loader.getStats(),
      'scrollStats': _scrollManager.getScrollStats(),
    };
  }

  void dispose() {
    _scrollManager.dispose();
    _log('🗑️ InfiniteScrollHook disposed');
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('🪝 HOOK: $message');
    }
  }
}

