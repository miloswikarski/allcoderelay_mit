import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../widgets/scan_button.dart';
import '../widgets/nfc_button.dart';
import '../widgets/scans_list.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Image(
                  image: AssetImage('assets/images/logo.png'),
                  width: 40,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    state.webhookTitle.isNotEmpty
                        ? state.webhookTitle
                        : 'AllCodeRelay',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_right,
                          ),
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                        ),
                        Text(
                          'Scan Mode',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                      ],
                    ),
                    if (_isExpanded)
                      BlocBuilder<SettingsBloc, SettingsState>(
                        builder: (context, settingsState) {
                          final preferredMode = settingsState.preferredScanMode;

                          // Determine which buttons to show based on preferred mode
                          final showBarcode =
                              preferredMode == PreferredScanMode.both ||
                                  preferredMode ==
                                      PreferredScanMode.barcodeOnly;
                          final showNfc = preferredMode ==
                                  PreferredScanMode.both ||
                              preferredMode == PreferredScanMode.nfcOnly;

                          return SizedBox(
                            height: 140.0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showBarcode) const ScanButton(),
                                if (showBarcode && showNfc)
                                  const SizedBox(width: 16),
                                if (showNfc) const NfcButton(),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Expanded(child: ScansList()),
        ],
      ),
    );
  }
}
