import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/nfc/nfc_bloc.dart';
import '../blocs/scanner/scanner_bloc.dart';
import '../blocs/settings/settings_bloc.dart';

class NfcButton extends StatefulWidget {
  const NfcButton({super.key});

  @override
  State<NfcButton> createState() => _NfcButtonState();
}

class _NfcButtonState extends State<NfcButton> {
  bool _isScanning = false;

  void _startNfcScan() {
    setState(() {
      _isScanning = true;
    });
    
    context.read<NfcBloc>().add(StartNfcScan());
    
    // Show a snackbar indicating NFC is waiting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Waiting for NFC tag...'),
        duration: const Duration(minutes: 1),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () {
            _stopNfcScan();
          },
        ),
      ),
    );
  }

  void _stopNfcScan() {
    setState(() {
      _isScanning = false;
    });
    context.read<NfcBloc>().add(StopNfcScan());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NfcBloc, NfcState>(
      listener: (context, state) {
        if (state is NfcSuccess) {
          final settings = context.read<SettingsBloc>().state;
          
          // Close the waiting snackbar
          ScaffoldMessenger.of(context).clearSnackBars();

          // Copy to clipboard before calling webhook
          if (settings.copyToClipboard) {
            Clipboard.setData(ClipboardData(text: state.data));
            // Show snackbar indicating copy success
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied: ${state.data}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          context.read<ScannerBloc>().add(ScanCode(state.data));
          _stopNfcScan();

          if (settings.beepEnabled) {
            // TODO: Play beep sound
          }
        } else if (state is NfcError) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          _stopNfcScan();
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 120,
            height: 120,
            child: ElevatedButton(
              onPressed:
                  _isScanning ? _stopNfcScan : () => _startNfcScan(),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                backgroundColor: isDark
                    ? const Color.fromARGB(255, 30, 120, 160)
                    : const Color.fromARGB(255, 70, 180, 220),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.nfc,
                    size: 40,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isScanning ? 'Reading...' : 'Read NFC',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
