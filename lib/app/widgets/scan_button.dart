import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/scanner/scanner_bloc.dart';
import '../screens/scan_screen.dart';

class ScanButton extends StatelessWidget {
  const ScanButton({super.key});

  void _openScanScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerBloc, ScannerState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 120,
            height: 120,
            child: ElevatedButton(
              onPressed: state is ScannerLoading ? null : () => _openScanScreen(context),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                backgroundColor: isDark
                    ? const Color.fromARGB(255, 200, 100, 70)
                    : const Color.fromARGB(255, 243, 194, 174),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 40,
                    color: CupertinoColors.label,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan Code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
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
