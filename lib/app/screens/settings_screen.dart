import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Webhook Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Webhook Title',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: state.webhookTitle,
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Enter webhook title',
                          hintStyle: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                            UpdateWebhookTitle(value),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Webhook URL',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: state.webhookUrl,
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Enter webhook URL',
                          hintStyle: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                            UpdateWebhookUrl(value),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Custom Headers',
                            style: TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _showAddHeaderDialog(context),
                            child: const Text('Add Header'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...state.webhookHeaders.entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: CupertinoColors.destructiveRed
                                          .resolveFrom(context),
                                    ),
                                    onPressed: () {
                                      context.read<SettingsBloc>().add(
                                        RemoveWebhookHeader(entry.key),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  value: state.isDarkMode,
                  onChanged: (_) {
                    context.read<SettingsBloc>().add(ToggleDarkMode());
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continuous Scanning',
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                      if (state.isContinuousScanning)
                        Slider(
                          value: state.scanDelay.toDouble(),
                          min: 0.5,
                          max: 5.0,
                          divisions: 9,
                          label: '${state.scanDelay}s',
                          onChanged: (value) {
                            context.read<SettingsBloc>().add(
                              UpdateScanDelay(value.toDouble()),
                            );
                          },
                        ),
                    ],
                  ),
                  subtitle: Text(
                    'Keep scanner open after successful scan',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  value: state.isContinuousScanning,
                  onChanged: (_) {
                    context.read<SettingsBloc>().add(
                      ToggleContinuousScanning(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  title: Text(
                    'Beep on Scan',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  subtitle: Text(
                    'Play a sound when a code is scanned',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  value: state.beepEnabled,
                  onChanged: (_) {
                    context.read<SettingsBloc>().add(ToggleBeep());
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  title: Text(
                    'Copy to Clipboard',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  subtitle: Text(
                    'Automatically copy scanned codes to clipboard',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  value: state.copyToClipboard,
                  onChanged: (_) {
                    context.read<SettingsBloc>().add(ToggleClipboard());
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferred Scan Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose which scanning options to show on the home screen',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RadioListTile<PreferredScanMode>(
                        title: Text(
                          'NFC + Barcode',
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        subtitle: Text(
                          'Show both scanning options',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        value: PreferredScanMode.both,
                        groupValue: state.preferredScanMode,
                        onChanged: (value) {
                          if (value != null) {
                            context.read<SettingsBloc>().add(
                              UpdatePreferredScanMode(value),
                            );
                          }
                        },
                      ),
                      RadioListTile<PreferredScanMode>(
                        title: Text(
                          'Barcode Only',
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        subtitle: Text(
                          'Show only barcode/QR scanner',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        value: PreferredScanMode.barcodeOnly,
                        groupValue: state.preferredScanMode,
                        onChanged: (value) {
                          if (value != null) {
                            context.read<SettingsBloc>().add(
                              UpdatePreferredScanMode(value),
                            );
                          }
                        },
                      ),
                      RadioListTile<PreferredScanMode>(
                        title: Text(
                          'NFC Only',
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        subtitle: Text(
                          'Show only NFC scanner',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        value: PreferredScanMode.nfcOnly,
                        groupValue: state.preferredScanMode,
                        onChanged: (value) {
                          if (value != null) {
                            context.read<SettingsBloc>().add(
                              UpdatePreferredScanMode(value),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text(
                    'About',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                  onTap: () => context.go('/about'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddHeaderDialog(BuildContext context) {
    String headerKey = '';
    String headerValue = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Header'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Header Name',
                hintText: 'e.g. Authorization',
              ),
              onChanged: (value) => headerKey = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Header Value',
                hintText: 'e.g. Bearer token123',
              ),
              onChanged: (value) => headerValue = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (headerKey.isNotEmpty && headerValue.isNotEmpty) {
                context.read<SettingsBloc>().add(
                  AddWebhookHeader(headerKey, headerValue),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
