import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../providers/scanning_state_provider.dart';
import '../blocs/scanner/scanner_bloc.dart';
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
    return ChangeNotifierProvider(
      create: (_) => ScanningStateProvider(),
      child: Scaffold(
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
                        SizedBox(
                          height: 260,
                          child: Consumer<ScanningStateProvider>(
                            builder: (context, scanningState, _) {
                              final currentMode = scanningState.currentMode;

                              return Row(
                                children: [
                                  if (currentMode == ScanningMode.none ||
                                      currentMode == ScanningMode.qr)
                                    Expanded(child: const ScanButton()),
                                  if (currentMode == ScanningMode.qr)
                                    const SizedBox.shrink()
                                  else if (currentMode == ScanningMode.none)
                                    const SizedBox(width: 16),
                                  if (currentMode == ScanningMode.none ||
                                      currentMode == ScanningMode.nfc)
                                    Expanded(child: const NfcButton()),
                                ],
                              );
                            },
                          ),
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
      ),
    );
  }
}
