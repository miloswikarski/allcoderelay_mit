import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  // AppLinks instance
  final AppLinks _appLinks = AppLinks();

  // Stream subscription for app links
  StreamSubscription<String>? _linkSubscription;

  // Callback function to handle the deep link parameters
  final void Function(Map<String, String> params)? onDeepLinkReceived;

  DeepLinkService({this.onDeepLinkReceived});

  // Initialize and listen for deep links
  Future<void> initUniLinks() async {
    // Handle case where app was opened with a deep link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Handle links when app is already running
    _linkSubscription = _appLinks.stringLinkStream.listen(
      (String link) {
        _handleDeepLink(Uri.parse(link));
      },
      onError: (err) {
        debugPrint('Error in deep link stream: $err');
      },
    );
  }

  // Parse the deep link and extract parameters
  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: ${uri.toString()}');

    try {
      // Confirm it's the correct scheme
      if (uri.scheme == 'allcoderelay') {
        // Extract query parameters
        Map<String, String> params = uri.queryParameters;

        // Call the callback with parameters
        if (onDeepLinkReceived != null) {
          onDeepLinkReceived!(params);
        }
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }

  // Clean up resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}
