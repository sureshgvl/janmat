import 'dart:html' as html;
import 'dart:js' as js;

/// Web-specific configuration to center the app with mobile-like dimensions
class WebConfig {
  static void initialize() {
    // Only run on web platform
    if (!identical(0, 0.0)) return; // Skip if not web

    try {
      // Force mobile viewport on desktop browsers
      _setupMobileViewport();

      // Center the Flutter app container
      _centerFlutterApp();

      // Add CSS for mobile-like appearance
      _injectMobileStyles();

    } catch (e) {
      print('Web config error: $e');
    }
  }

  static void _setupMobileViewport() {
    // Set viewport meta tag for mobile-like behavior
    final viewport = html.querySelector('meta[name=viewport]');
    if (viewport != null) {
      viewport.setAttribute('content',
        'width=390, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
    }
  }

  static void _centerFlutterApp() {
    // Get the Flutter app container
    final flutterContainer = html.querySelector('flutter-app') ??
                           html.querySelector('#flutter-app') ??
                           html.document.body;

    if (flutterContainer != null) {
      flutterContainer.style
        ..width = '390px'
        ..minHeight = '844px'
        ..margin = '20px auto'
        ..boxShadow = '0 0 20px rgba(0,0,0,0.1)'
        ..borderRadius = '20px'
        ..overflow = 'hidden'
        ..backgroundColor = 'white';
    }
  }

  static void _injectMobileStyles() {
    final style = html.StyleElement();
    style.text = '''
      /* Mobile-like body styling */
      body {
        margin: 0 !important;
        padding: 20px !important;
        background: #f5f5f5 !important;
        display: flex !important;
        justify-content: center !important;
        align-items: flex-start !important;
        min-height: 100vh !important;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif !important;
      }

      /* Force Flutter canvas to fit container */
      canvas {
        max-width: 100% !important;
        height: auto !important;
      }

      /* Responsive for actual mobile devices */
      @media (max-width: 450px) {
        body {
          padding: 0 !important;
          align-items: stretch !important;
        }
        #flutter-app, flutter-app {
          width: 100vw !important;
          min-height: 100vh !important;
          margin: 0 !important;
          border-radius: 0 !important;
          box-shadow: none !important;
        }
      }

      /* Hide scrollbars for mobile-like experience */
      ::-webkit-scrollbar {
        display: none;
      }
      body {
        -ms-overflow-style: none;
        scrollbar-width: none;
      }
    ''';

    html.document.head?.append(style);
  }

  /// Force the browser window to center and resize for mobile testing
  static void forceMobileWindow() {
    try {
      // This will work in some browsers but is limited by security policies
      js.context.callMethod('eval', ['''
        if (window.innerWidth > 768) {
          window.resizeTo(390, 844);
          window.moveTo((screen.width - 390) / 2, (screen.height - 844) / 2);
        }
      ''']);
    } catch (e) {
      print('Window resize not supported: $e');
    }
  }

  /// Check if running on mobile device and adjust accordingly
  static bool isMobile() {
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('mobile') ||
             userAgent.contains('android') ||
             userAgent.contains('iphone') ||
             userAgent.contains('ipad');
    } catch (e) {
      return false;
    }
  }

  /// Parse URL parameters for public candidate profile access
  /// URL pattern: /#/candidate/{stateId}/{districtId}/{bodyId}/{wardId}/{candidateId}
  static PublicCandidateUrlParams? parsePublicCandidateUrl() {
    try {
      if (!identical(0, 0.0)) return null; // Only work on web

      final hash = html.window.location.hash;
      if (hash.isEmpty || !hash.startsWith('#/candidate/')) {
        return null;
      }

      // Remove the hash and split path
      final path = hash.substring(1); // Remove '#'
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();

      // Pattern: candidate/stateId/districtId/bodyId/wardId/candidateId
      if (segments.length < 6 || segments[0] != 'candidate') {
        return null;
      }

      final params = PublicCandidateUrlParams(
        stateId: segments[1],
        districtId: segments[2],
        bodyId: segments[3],
        wardId: segments[4],
        candidateId: segments[5],
      );

      print('✅ Parsed public candidate URL: ${params.toString()}');
      return params;
    } catch (e) {
      print('❌ Error parsing public candidate URL: $e');
      return null;
    }
  }

  /// Extract URL parameters from current location (generic utility)
  static Map<String, String> extractUrlParams() {
    try {
      if (!identical(0, 0.0)) return {}; // Only work on web

      final params = <String, String>{};
      final searchParams = html.window.location.search;

      if (searchParams != null && searchParams.isNotEmpty) {
        // Handle traditional query parameters: ?key1=value1&key2=value2
        final queryString = searchParams.substring(1);
        for (final param in queryString.split('&')) {
          if (param.contains('=')) {
            final keyValue = param.split('=');
            if (keyValue.length == 2) {
              params[keyValue[0]] = Uri.decodeComponent(keyValue[1]);
            }
          }
        }
      }
      return params;
    } catch (e) {
      print('❌ Error extracting URL params: $e');
      return {};
    }
  }
}

/// Data class for public candidate URL parameters
class PublicCandidateUrlParams {
  final String stateId;
  final String districtId;
  final String bodyId;
  final String wardId;
  final String candidateId;

  PublicCandidateUrlParams({
    required this.stateId,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
    required this.candidateId,
  });

  bool get isValid =>
      stateId.isNotEmpty &&
      districtId.isNotEmpty &&
      bodyId.isNotEmpty &&
      wardId.isNotEmpty &&
      candidateId.isNotEmpty;

  @override
  String toString() =>
      'state: $stateId, district: $districtId, body: $bodyId, ward: $wardId, candidate: $candidateId';
}
