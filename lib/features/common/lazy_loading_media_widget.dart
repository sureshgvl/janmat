import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../candidate/services/media_cache_service.dart';
import '../../utils/app_logger.dart';

/// Configuration for lazy loading behavior
class LazyLoadingConfig {
  final Duration preloadThreshold;
  final Duration fadeInDuration;
  final bool enablePreloading;
  final bool enableCaching;
  final bool enableProgressiveLoading;

  const LazyLoadingConfig({
    this.preloadThreshold = const Duration(milliseconds: 300),
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.enablePreloading = true,
    this.enableCaching = true,
    this.enableProgressiveLoading = true,
  });
}

/// Progressive loading state
enum MediaLoadingState {
  idle,
  preloading,
  loading,
  loaded,
  error,
}

/// Simplified lazy loading media widget with caching capabilities
class LazyLoadingMediaWidget extends StatefulWidget {
  final String mediaUrl;
  final MediaType mediaType;
  final LazyLoadingConfig config;
  final double minHeight;
  final double maxHeight;
  final Color? borderColor;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableCache;
  final VoidCallback? onMediaLoaded;
  final VoidCallback? onMediaError;

  const LazyLoadingMediaWidget({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    this.config = const LazyLoadingConfig(),
    this.minHeight = 100,
    this.maxHeight = 300,
    this.borderColor,
    this.borderRadius = 8.0,
    this.placeholder,
    this.errorWidget,
    this.enableCache = true,
    this.onMediaLoaded,
    this.onMediaError,
  });

  @override
  State<LazyLoadingMediaWidget> createState() => _LazyLoadingMediaWidgetState();
}

class _LazyLoadingMediaWidgetState extends State<LazyLoadingMediaWidget> with AutomaticKeepAliveClientMixin {
  MediaLoadingState _loadingState = MediaLoadingState.idle;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  File? _cachedFile;
  Timer? _preloadTimer;
  bool _wasVisible = false;

  @override
  bool get wantKeepAlive => true; // Keep state alive during scrolls

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  @override
  void didUpdateWidget(LazyLoadingMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl) {
      _resetState();
      _initializeCache();
    }
  }

  @override
  void dispose() {
    _preloadTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCache() async {
    try {
      final cacheService = await MediaCacheService.getInstance();

      // Check if already cached
      if (widget.enableCache) {
        _cachedFile = cacheService.getFile(widget.mediaUrl);
        if (_cachedFile != null) {
          setState(() {
            _loadingState = MediaLoadingState.loaded;
          });
          widget.onMediaLoaded?.call();
        }
      }
    } catch (e) {
      AppLogger.common('⚠️ [LazyMedia] Cache initialization failed: $e', tag: 'LAZY_MEDIA');
    }
  }

  void _resetState() {
    _loadingState = MediaLoadingState.idle;
    _retryCount = 0;
    _preloadTimer?.cancel();
    _cachedFile = null;
    _wasVisible = false;
  }

  void _handleVisibilityChanged() {
    // Simplified visibility handling - trigger loading when mounted
    if (!_wasVisible && mounted) {
      _wasVisible = true;
      _startLoadingWithPreloading();
    }
  }

  void _startLoadingWithPreloading() {
    if (_loadingState != MediaLoadingState.idle) return;

    if (widget.config.enablePreloading) {
      setState(() {
        _loadingState = MediaLoadingState.preloading;
      });

      _preloadTimer?.cancel();
      _preloadTimer = Timer(widget.config.preloadThreshold, () {
        if (mounted && _loadingState == MediaLoadingState.preloading) {
          _startActualLoading();
        }
      });
    } else {
      _startActualLoading();
    }
  }

  void _startActualLoading() {
    if (!mounted) return;

    setState(() {
      _loadingState = MediaLoadingState.loading;
    });

    // For cached files, we're already done
    if (_cachedFile != null) {
      widget.onMediaLoaded?.call();
      return;
    }

    _loadMediaWithRetry();
  }

  Future<void> _loadMediaWithRetry() async {
    try {
      // Show cached file immediately if available
      if (_cachedFile != null) {
        setState(() {
          _loadingState = MediaLoadingState.loaded;
        });
        widget.onMediaLoaded?.call();
        return;
      }

      // Check if this is a network URL and if we should cache it
      if (widget.enableCache && widget.config.enableCaching && _isNetworkUrl(widget.mediaUrl)) {
        final cacheService = await MediaCacheService.getInstance();
        _cachedFile = cacheService.getFile(widget.mediaUrl);
      }

      if (!mounted) return;

      setState(() {
        _loadingState = MediaLoadingState.loaded;
      });

      // Reset retry count on success
      _retryCount = 0;
      widget.onMediaLoaded?.call();

      if (_cachedFile != null) {
        AppLogger.common('✅ [LazyMedia] Loaded from cache: ${widget.mediaUrl}', tag: 'LAZY_MEDIA');
      }

    } catch (e) {
      AppLogger.common('❌ [LazyMedia] Load failed: $e', tag: 'LAZY_MEDIA');

      if (_retryCount < _maxRetries && mounted) {
        _retryCount++;
        Future.delayed(Duration(seconds: _retryCount), () {
          if (mounted) {
            _loadMediaWithRetry();
          }
        });
        return;
      }

      if (mounted) {
        setState(() {
          _loadingState = MediaLoadingState.error;
        });
        widget.onMediaError?.call();
      }
    }
  }

  bool _isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  bool _isLocalPath(String path) {
    return path.startsWith('local:') || !path.contains('://');
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      height: widget.minHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: widget.borderColor ?? Colors.grey.shade300),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF374151)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: widget.minHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load media',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    final mediaUrl = _cachedFile?.path ?? widget.mediaUrl;
    final isLocal = _isLocalPath(mediaUrl) || _cachedFile != null;

    switch (widget.mediaType) {
      case MediaType.image:
        return AnimatedOpacity(
          opacity: _loadingState == MediaLoadingState.loaded ? 1.0 : 0.5,
          duration: widget.config.fadeInDuration,
          child: Container(
            constraints: BoxConstraints(
              minHeight: widget.minHeight,
              maxHeight: widget.maxHeight,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: widget.borderColor ?? Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: _buildImage(mediaUrl, isLocal),
            ),
          ),
        );

      case MediaType.video:
        return AnimatedOpacity(
          opacity: _loadingState == MediaLoadingState.loaded ? 1.0 : 0.5,
          duration: widget.config.fadeInDuration,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: widget.borderColor ?? Colors.grey.shade300),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Color(0xFF374151),
                size: 48,
              ),
            ),
          ),
        );

      case MediaType.audio:
        return AnimatedOpacity(
          opacity: _loadingState == MediaLoadingState.loaded ? 1.0 : 0.5,
          duration: widget.config.fadeInDuration,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: widget.borderColor ?? Colors.grey.shade300),
            ),
            child: const Center(
              child: Icon(
                Icons.audiotrack,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );

      default:
        return _buildErrorWidget();
    }
  }

  Widget _buildImage(String url, bool isLocal) {
    if (isLocal) {
      return Image.file(
        File(_isLocalPath(url) ? url.replaceFirst('local:', '') : url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageError(),
      );
    } else {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF374151)),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildImageError(),
      );
    }
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Trigger loading when first built (simplified visibility check)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleVisibilityChanged();
    });

    return _buildContent();
  }

  Widget _buildContent() {
    switch (_loadingState) {
      case MediaLoadingState.error:
        return widget.errorWidget ?? _buildErrorWidget();

      case MediaLoadingState.loaded:
        return _buildMediaContent();

      case MediaLoadingState.loading:
      case MediaLoadingState.preloading:
        return widget.placeholder ?? _buildLoadingPlaceholder();

      default:
        return widget.placeholder ?? _buildLoadingPlaceholder();
    }
  }
}

/// Media types supported by lazy loading
enum MediaType {
  image,
  video,
  audio,
}

/// Simplified preload manager for batch operations
class MediaPreloadManager {
  static final Map<String, Completer<void>> _preloadTasks = {};

  static Future<void> preloadMedia(List<String> urls, {MediaType mediaType = MediaType.image}) async {
    final futures = urls.map((url) => preloadSingleMedia(url, mediaType: mediaType));
    await Future.wait(futures);
  }

  static Future<void> preloadSingleMedia(String url, {MediaType mediaType = MediaType.image}) async {
    if (_preloadTasks.containsKey(url)) {
      return _preloadTasks[url]!.future;
    }

    final completer = Completer<void>();
    _preloadTasks[url] = completer;

    try {
      // Check if already in cache
      final cacheService = await MediaCacheService.getInstance();
      final cached = cacheService.getFile(url);

      if (cached == null) {
        AppLogger.common('🔮 [Preload] URL not cached (would prefetch): $url', tag: 'LAZY_MEDIA');
      }

      completer.complete();
    } catch (e) {
      completer.completeError(e);
    }
  }

  static void clearPreloadTasks() {
    _preloadTasks.clear();
  }
}
