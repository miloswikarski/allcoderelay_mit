import 'package:allcoderelay/app/providers/scanning_state_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../blocs/scanner/scanner_bloc.dart';
import '../blocs/settings/settings_bloc.dart';

class ScanButton extends StatefulWidget {
  const ScanButton({super.key});

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  MobileScannerController? _controller;
  bool _isScanning = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _playBeep() async {
    await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
  }

  void _toggleScanner() {
    final scanningState = context.read<ScanningStateProvider>();

    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _controller = MobileScannerController();
        scanningState.startScanning(ScanningMode.qr);
      } else {
        _controller?.dispose();
        _controller = null;
        scanningState.stopScanning();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isScanning) ...[
          Expanded(
            child: BlocBuilder<ScannerBloc, ScannerState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: state is ScannerLoading ? null : _toggleScanner,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: const Color.fromARGB(255, 243, 194, 174),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 32,
                          color:
                              CupertinoColors
                                  .label, // Change to use system color
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Scan Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                CupertinoColors
                                    .label, // Change to use system color
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ] else ...[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: MobileScanner(
                controller: _controller!,
                onDetect: (capture) async {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final code = barcodes.first.rawValue;
                    if (code != null) {
                      final settings = context.read<SettingsBloc>().state;
                      if (settings.beepEnabled) {
                        await _playBeep();
                      }

                      // Copy to clipboard before calling webhook
                      if (settings.copyToClipboard) {
                        await Clipboard.setData(ClipboardData(text: code));
                        // Show snackbar indicating copy success
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied: $code'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            width: MediaQuery.of(context).size.width * 0.9,
                            action: SnackBarAction(
                              label: 'Dismiss',
                              onPressed: () {
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                      }

                      if (code.startsWith('allcoderelay://setwebhookurl')) {
                        context.read<SettingsBloc>().add(
                          UpdateWebhookUrlFromQr(code),
                        );
                        _toggleScanner();
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            Future.delayed(const Duration(seconds: 2), () {
                              Navigator.of(context).pop();
                            });
                            return AlertDialog(
                              title: const Text('Webhook URL Updated'),
                              content: const Text(
                                'The webhook URL has been updated successfully.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                        return;
                      }

                      context.read<ScannerBloc>().add(ScanCode(code));

                      if (!settings.isContinuousScanning) {
                        _toggleScanner();
                      } else {
                        _controller?.stop();
                        await Future.delayed(
                          Duration(
                            milliseconds: (settings.scanDelay * 1000).round(),
                          ),
                        );
                        if (_isScanning) {
                          _controller?.start();
                        }
                      }
                    }
                  }
                },
              ),
            ),
          ),
          BlocBuilder<ScannerBloc, ScannerState>(
            builder: (context, state) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed:
                          state is ScannerLoading ? null : _toggleScanner,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Stop'),
                    ),
                  ),
                  if (state is ScannerLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircularProgressIndicator(),
                    )
                  else if (state is ScannerError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        state.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
