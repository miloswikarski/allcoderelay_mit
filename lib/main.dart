import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handlers to prevent black screen crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // In release mode, log the error but don't crash
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    }
  };

  // Custom error widget builder for release mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      // In release mode, show a friendly error message instead of red screen
      return Material(
        child: Container(
          color: Colors.white,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.orange, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please try again',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    // In debug mode, show the default error widget
    return ErrorWidget(details.exception);
  };

  // Catch errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kReleaseMode) {
      debugPrint('Platform Error: $error');
      debugPrint('Stack trace: $stack');
    }
    return true; // Prevent crash
  };

  // Set system UI overlay style for edge-to-edge
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Set preferred orientations but allow flexibility for large screens
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Run app - don't use runZonedGuarded as it creates zone mismatch
  runApp(const AllCodeRelayApp());
}
