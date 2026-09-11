import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Provider for deep link handler
final deepLinkHandlerProvider = Provider<DeepLinkHandler>((ref) {
  return DeepLinkHandler();
});

/// Handles deep links for OAuth callbacks and other app navigation
class DeepLinkHandler {
  StreamSubscription<Uri>? _linkSubscription;
  final _pendingOAuthCallback = Completer<Uri>();

  /// Initialize deep link listening
  void initialize(BuildContext context) {
    // Listen for initial link (when app is opened via deep link)
    _handleInitialLink(context);

    // Listen for links while app is running
    // Note: This requires a package like `uni_links` or `app_links`
    // For now, we'll handle it through GoRouter's initial location
  }

  /// Handle initial deep link when app is opened
  void _handleInitialLink(BuildContext context) {
    // This will be called when app is opened via deep link
    // The actual implementation depends on the deep link package used
  }

  /// Handle OAuth callback (for future OAuth integrations)
  Future<void> handleOAuthCallback(Uri uri) async {
    if (uri.scheme == 'swimtracker' && uri.host == 'oauth') {
      _pendingOAuthCallback.complete(uri);
    }
  }

  /// Wait for OAuth callback
  Future<Uri> waitForOAuthCallback() {
    return _pendingOAuthCallback.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => throw TimeoutException('OAuth callback timeout'),
    );
  }

  /// Reset OAuth callback completer
  void resetOAuthCallback() {
    if (!_pendingOAuthCallback.isCompleted) {
      _pendingOAuthCallback.completeError('Cancelled');
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}

/// Extension to handle deep links in GoRouter
extension DeepLinkExtension on GoRouter {
  /// Handle deep link URI
  Future<void> handleDeepLink(Uri uri) async {
    if (uri.scheme == 'swimtracker' && uri.host == 'oauth') {
      // Navigate to import screen with OAuth callback
      go('/training/teams/import?code=${uri.queryParameters['code']}');
    }
  }
}
