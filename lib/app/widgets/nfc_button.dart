import 'package:allcoderelay/app/providers/scanning_state_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for clipboard
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/nfc/nfc_bloc.dart';
import '../blocs/scanner/scanner_bloc.dart';
import '../blocs/settings/settings_bloc.dart';

class NfcButton extends StatelessWidget {
  const NfcButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NfcBloc, NfcState>(
      listener: (context, state) {
        if (state is NfcSuccess) {
          final settings = context.read<SettingsBloc>().state;

          // Copy to clipboard before calling webhook
          if (settings.copyToClipboard) {
            Clipboard.setData(ClipboardData(text: state.data));
            // Show snackbar indicating copy success
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied: ${state.data}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                width: MediaQuery.of(context).size.width * 0.9,
                action: SnackBarAction(
                  label: 'Dismiss',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }

          context.read<ScannerBloc>().add(ScanCode(state.data));
          context.read<ScanningStateProvider>().stopScanning();

          if (settings.beepEnabled) {
            // TODO: Play beep sound
          }
        } else if (state is NfcError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isScanning = state is NfcScanning;

        return Column(
          children: [
            if (isScanning)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Waiting for NFC tag...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  if (!isScanning)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            final scanningState =
                                context.read<ScanningStateProvider>();
                            context.read<NfcBloc>().add(StartNfcScan());
                            scanningState.startScanning(ScanningMode.nfc);
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            backgroundColor: const Color.fromARGB(
                              255,
                              174,
                              220,
                              243,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.nfc,
                                size: 32,
                                color: CupertinoColors.label.resolveFrom(
                                  context,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'NFC Reader',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.label.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          final scanningState =
                              context.read<ScanningStateProvider>();
                          context.read<NfcBloc>().add(StopNfcScan());
                          scanningState.stopScanning();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Stop'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
