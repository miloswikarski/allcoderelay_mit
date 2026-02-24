import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../blocs/scanner/scanner_bloc.dart';
import '../blocs/settings/settings_bloc.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late MobileScannerController _controller;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _playBeep() async {
    await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      debugPrint('Error toggling torch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Flash not available on this device'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _setZoomLevel(double zoom) async {
    try {
      await _controller.setZoomScale(zoom);
      setState(() {
        _zoomLevel = zoom;
      });
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _controller.switchCamera();
    } catch (e) {
      debugPrint('Error switching camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera switch not available'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing || !mounted) return;
    _isProcessing = true;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null) {
        final settings = context.read<SettingsBloc>().state;
        final settingsBloc = context.read<SettingsBloc>();
        final scannerBloc = context.read<ScannerBloc>();
        final messenger = ScaffoldMessenger.of(context);

        if (settings.beepEnabled) {
          await _playBeep();
        }

        // Copy to clipboard before calling webhook
        if (settings.copyToClipboard) {
          await Clipboard.setData(
            ClipboardData(text: code),
          );

          if (mounted) {
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text('Copied: $code'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

        if (code.startsWith('allcoderelay://setwebhookurl')) {
          settingsBloc.add(UpdateWebhookUrlFromQr(code));

          if (mounted) {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext innerDialogContext) {
                return AlertDialog(
                  title: const Text('Webhook URL Updated'),
                  content: const Text(
                    'The webhook URL has been updated successfully.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(innerDialogContext);
                        // Close the scan screen after dialog is closed
                        if (mounted) {
                          Future.microtask(() {
                            if (mounted) {
                              Navigator.of(context, rootNavigator: false).maybePop();
                            }
                          });
                        }
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
          _isProcessing = false;
          return;
        }

        scannerBloc.add(ScanCode(code));

        if (!settings.isContinuousScanning) {
          // Defer navigation to avoid navigator lock
          Future.microtask(() {
            if (mounted) {
              Navigator.of(context, rootNavigator: false).maybePop();
            }
          });
          _isProcessing = false;
        } else {
          // Show what was scanned in continuous mode
          if (mounted) {
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scanned',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code.length > 50 ? '${code.substring(0, 47)}...' : code,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                duration: Duration(
                  milliseconds: (settings.scanDelay * 1000).round() >
                          1500
                      ? (settings.scanDelay * 1000).round() - 500
                      : 1500,
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.orange.withValues(alpha: 0.9),
              ),
            );
          }

          // Stop the scanner
          await _controller.stop();

          // Wait for the configured delay
          await Future.delayed(
            Duration(
              milliseconds: (settings.scanDelay * 1000).round(),
            ),
          );

          // Restart only if still mounted and widget is still active
          if (mounted) {
            try {
              await _controller.start();
              _isProcessing = false;
            } catch (e) {
              debugPrint('Error restarting scanner: $e');
              _isProcessing = false;
            }
          } else {
            _isProcessing = false;
          }
        }
      }
    } else {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Code'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera scanner with gesture zoom support
          GestureDetector(
            onScaleUpdate: (ScaleUpdateDetails details) {
              final newZoom = (_zoomLevel * details.scale).clamp(1.0, 5.0);
              _setZoomLevel(newZoom);
            },
            child: MobileScanner(
              controller: _controller,
              onDetect: _handleDetection,
            ),
          ),

          // Scan guide overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ScanGuideOverlayPainter(),
              ),
            ),
          ),

          // Top controls - Camera switch and help text
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _switchCamera,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.flip_camera_android,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: const Text(
                    'Pinch to zoom',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom controls - Flash and zoom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom slider
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.zoom_out,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Slider(
                              value: _zoomLevel,
                              min: 1.0,
                              max: 5.0,
                              divisions: 8,
                              onChanged: _setZoomLevel,
                              activeColor: Colors.orange,
                              inactiveColor: Colors.white30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(_zoomLevel * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Flashlight button
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: FloatingActionButton.extended(
                      heroTag: null,
                      onPressed: _toggleTorch,
                      backgroundColor: _isTorchOn
                          ? Colors.amber
                          : Colors.grey[800],
                      icon: Icon(
                        _isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
                        size: 28,
                        color: _isTorchOn ? Colors.black : Colors.white,
                      ),
                      label: Text(
                        _isTorchOn ? 'On' : 'Off',
                        style: TextStyle(
                          color: _isTorchOn ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for scan guide overlay
class ScanGuideOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerRadius = 16.0;
    const scanFrameSize = 300.0;

    // Center position of the scan frame
    final frameLeft = (size.width - scanFrameSize) / 2;
    final frameTop = (size.height - scanFrameSize) / 2;
    final frameRight = frameLeft + scanFrameSize;
    final frameBottom = frameTop + scanFrameSize;

    // Semi-transparent dark background for areas outside scan frame
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.4);

    // Draw dimmed areas
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, frameTop),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, frameBottom, size.width, size.height - frameBottom),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, frameTop, frameLeft, scanFrameSize),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(frameRight, frameTop, size.width - frameRight, scanFrameSize),
      paint,
    );

    // Draw rounded rectangle border around scan area
    final borderPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(frameLeft, frameTop, frameRight, frameBottom),
      const Radius.circular(cornerRadius),
    );
    canvas.drawRRect(frameRect, borderPaint);

    // Draw corner brackets
    const cornerLength = 30.0;
    const cornerThickness = 4.0;
    final cornerPaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = cornerThickness
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(
      Offset(frameLeft, frameTop + cornerLength),
      Offset(frameLeft, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameTop),
      Offset(frameLeft + cornerLength, frameTop),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(frameRight - cornerLength, frameTop),
      Offset(frameRight, frameTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRight, frameTop),
      Offset(frameRight, frameTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(frameLeft, frameBottom - cornerLength),
      Offset(frameLeft, frameBottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameLeft, frameBottom),
      Offset(frameLeft + cornerLength, frameBottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(frameRight, frameBottom - cornerLength),
      Offset(frameRight, frameBottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRight - cornerLength, frameBottom),
      Offset(frameRight, frameBottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(ScanGuideOverlayPainter oldDelegate) => false;
}
