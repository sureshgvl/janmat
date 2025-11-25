import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Error Type Enum
enum ErrorType {
  network,
  notFound,
  server,
  permission,
  unknown,
}

/// Generic error state widget with retry functionality
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    this.errorType = ErrorType.unknown,
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    this.showRetry = true,
    this.customIcon,
    this.primaryAction,
    this.secondaryAction,
  });

  final ErrorType errorType;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final bool showRetry;
  final IconData? customIcon;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                customIcon ?? _getErrorIcon(),
                size: 40,
                color: _getIconColor(context),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title ?? _getTitle(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message ?? _getMessage(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Actions
            if (primaryAction != null) ...[
              primaryAction!,
              if (secondaryAction != null) ...[
                const SizedBox(height: 12),
                secondaryAction!,
              ],
            ] else if (showRetry && onRetry != null) ...[
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? 'Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                ),
              ),

              if (secondaryAction != null) ...[
                const SizedBox(height: 12),
                secondaryAction!,
              ],
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (errorType) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.server:
        return Icons.error_outline;
      case ErrorType.permission:
        return Icons.lock_outline;
      default:
        return Icons.error;
    }
  }

  String _getTitle() {
    switch (errorType) {
      case ErrorType.network:
        return 'No Internet Connection';
      case ErrorType.notFound:
        return 'Content Not Found';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.permission:
        return 'Access Denied';
      default:
        return 'Something Went Wrong';
    }
  }

  String _getMessage() {
    switch (errorType) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.notFound:
        return 'The content you\'re looking for is no longer available.';
      case ErrorType.server:
        return 'We\'re having trouble connecting to our servers. Please try again later.';
      case ErrorType.permission:
        return 'You don\'t have permission to access this content.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  Color _getIconBackgroundColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (errorType) {
      case ErrorType.network:
        return scheme.primaryContainer.withValues(alpha: 0.3);
      case ErrorType.notFound:
        return scheme.secondaryContainer.withValues(alpha: 0.3);
      case ErrorType.server:
        return scheme.errorContainer.withValues(alpha: 0.3);
      case ErrorType.permission:
        return scheme.errorContainer.withValues(alpha: 0.3);
      default:
        return scheme.surfaceVariant.withValues(alpha: 0.3);
    }
  }

  Color _getIconColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (errorType) {
      case ErrorType.network:
        return scheme.primary;
      case ErrorType.notFound:
        return scheme.secondary;
      case ErrorType.server:
        return scheme.error;
      case ErrorType.permission:
        return scheme.error;
      default:
        return scheme.onSurfaceVariant;
    }
  }
}

/// Candidate not found error widget
class CandidateNotFoundError extends StatelessWidget {
  const CandidateNotFoundError({
    super.key,
    this.isGuest = false,
    this.onRetry,
    this.onBrowseCandidates,
  });

  final bool isGuest;
  final VoidCallback? onRetry;
  final VoidCallback? onBrowseCandidates;

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      errorType: ErrorType.notFound,
      title: 'Candidate Not Found',
      message: isGuest
          ? 'The candidate profile you\'re looking for doesn\'t exist or may have been removed.'
          : 'This candidate profile may not be available right now.',
      onRetry: onRetry,
      showRetry: onRetry != null,
      secondaryAction: onBrowseCandidates != null
          ? TextButton.icon(
              onPressed: onBrowseCandidates,
              icon: const Icon(Icons.search),
              label: const Text('Browse Candidates'),
            )
          : null,
    );
  }
}

/// Network connection error widget
class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  final VoidCallback? onRetry;
  final String? customMessage;

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      errorType: ErrorType.network,
      message: customMessage ?? 'Please check your internet connection and try again.',
      onRetry: onRetry,
      showRetry: onRetry != null,
      secondaryAction: TextButton.icon(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Go Back'),
      ),
    );
  }
}

/// Generic retry widget for lists and cards
class RetryCard extends StatelessWidget {
  const RetryCard({
    super.key,
    required this.onRetry,
    this.title = 'Failed to Load',
    this.message = 'Tap to retry',
    this.height = 120.0,
  });

  final VoidCallback onRetry;
  final String title;
  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Offline indicator banner
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You\'re currently offline. Some features may be limited.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // Hide banner or show offline actions
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Connection status widget
class ConnectionStatus extends StatefulWidget {
  const ConnectionStatus({super.key});

  @override
  State<ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends State<ConnectionStatus>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Reconnecting...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
