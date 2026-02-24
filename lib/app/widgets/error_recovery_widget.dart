import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// A widget that displays when an unhandled error occurs
/// Provides options to recover without restarting the app
class ErrorRecoveryWidget extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;
  final VoidCallback? onRetry;

  const ErrorRecoveryWidget({
    super.key,
    this.errorDetails,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The app encountered an unexpected error, but you can continue using it.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: onRetry ?? () {
                      // Default retry action - just dismiss this screen
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Continue'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (errorDetails != null) ...[
                    const SizedBox(height: 24),
                    ExpansionTile(
                      title: const Text(
                        'Error Details',
                        style: TextStyle(fontSize: 14),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey[200],
                          child: SingleChildScrollView(
                            child: Text(
                              errorDetails!.exception.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

