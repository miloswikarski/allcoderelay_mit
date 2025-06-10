import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../blocs/scanner/scanner_bloc.dart';
import '../models/scan_result.dart';

class ScansList extends StatefulWidget {
  const ScansList({super.key});

  @override
  State<ScansList> createState() => _ScansListState();
}

class _ScansListState extends State<ScansList> {
  final Set<int> _selectedItems = {};

  bool _isValidUrl(String value) {
    try {
      final uri = Uri.parse(value);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        final launched = await launchUrl(
          url,
          mode:
              LaunchMode
                  .platformDefault, // Changed from externalApplication to platformDefault
        );

        if (!launched && context.mounted) {
          showCupertinoDialog(
            context: context,
            builder:
                (context) => CupertinoAlertDialog(
                  title: const Text('Error'),
                  content: const Text('Could not open the URL in browser'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
          );
        }
      } else {
        // Fallback attempt with https if the original URL fails
        final httpsUrl = Uri.parse(
          'https://${url.host}${url.path}${url.query.isEmpty ? '' : '?${url.query}'}',
        );
        if (await canLaunchUrl(httpsUrl)) {
          await launchUrl(
            httpsUrl,
            mode:
                LaunchMode
                    .platformDefault, // Changed from externalApplication to platformDefault
          );
        } else if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder:
                (context) => CupertinoAlertDialog(
                  title: const Text('Error'),
                  content: const Text('Could not launch URL'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text('Error launching URL: $e'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<ScannerBloc>().add(LoadScans());
  }

  void _editScan(ScanResult scan) {
    String newValue = scan.codeValue;
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => DefaultTextStyle(
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 17,
              color: CupertinoColors.label.resolveFrom(
                context,
              ), // This will adapt to dark mode
            ),
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                            width: 0.0,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          Text(
                            'Edit Value',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.label.resolveFrom(
                                context,
                              ), // Explicit color for the title
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              context.read<ScannerBloc>().add(
                                UpdateScan(scan.copyWith(codeValue: newValue)),
                              );
                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CupertinoTextField(
                        controller: TextEditingController(text: scan.codeValue),
                        onChanged: (value) => newValue = value,
                        placeholder: 'Code Value',
                        maxLines: null,
                        autofocus: true,
                        padding: const EdgeInsets.all(12.0),
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 16,
                          color: CupertinoColors.label.resolveFrom(
                            context,
                          ), // Adapt text input color
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _shareSelected(List<ScanResult> scans) {
    final selectedScans = scans
        .where((scan) => _selectedItems.contains(scan.id))
        .map(
          (scan) =>
              'Code: ${scan.code}\nValue: ${scan.codeValue}\nTime: ${scan.timestamp}',
        )
        .join('\n\n');
    Share.share(selectedScans);
  }

  void _deleteSelected() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Selected'),
            content: Text('Delete ${_selectedItems.length} selected items?'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                isDefaultAction: true,
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  for (final id in _selectedItems) {
                    context.read<ScannerBloc>().add(DeleteScan(id));
                  }
                  _selectedItems.clear();
                  Navigator.pop(context);
                },
                isDestructiveAction: true,
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScannerBloc, ScannerState>(
      builder: (context, state) {
        if (state is ScannerInitial) {
          return Center(
            child: Text(
              'Scan a code to get started',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 17,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          );
        }

        if (state is ScannerLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (state is ScannerError) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                // Force rebuild after delay
                // reload the data
                context.read<ScannerBloc>().add(LoadScans());
              });
            }
          });
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 17,
                color: CupertinoColors.destructiveRed.resolveFrom(context),
              ),
            ),
          );
        }

        if (state is ScannerSuccess && state.scans.isEmpty) {
          return Center(
            child: Text(
              'No scans yet',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 17,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          );
        }

        if (state is ScannerSuccess) {
          final scans = state.scans;

          return Column(
            children: [
              if (_selectedItems.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.0,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        onPressed: () => _shareSelected(scans),
                        child: const Row(
                          children: [
                            Icon(CupertinoIcons.share, size: 20),
                            SizedBox(width: 4),
                            Text('Share'),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        onPressed: _deleteSelected,
                        child: const Row(
                          children: [
                            Icon(CupertinoIcons.delete, size: 20),
                            SizedBox(width: 4),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (scans.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.0,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        onPressed: () {
                          setState(() {
                            _selectedItems.addAll(
                              scans.map((scan) => scan.id!),
                            );
                          });
                        },
                        child: const Row(
                          children: [
                            Icon(CupertinoIcons.checkmark_circle, size: 20),
                            SizedBox(width: 4),
                            Text('Select All'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: CupertinoScrollbar(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: scans.length,
                    separatorBuilder:
                        (context, index) => Container(
                          height: 1,
                          color: CupertinoColors.separator.resolveFrom(context),
                        ),
                    itemBuilder: (context, index) {
                      final scan = scans[index];
                      return Container(
                        decoration: BoxDecoration(
                          color:
                              _selectedItems.contains(scan.id)
                                  ? CupertinoColors.systemGrey6.resolveFrom(
                                    context,
                                  )
                                  : CupertinoColors.systemBackground
                                      .resolveFrom(context),
                        ),
                        child: CupertinoListTile(
                          leading: CupertinoCheckbox(
                            value: _selectedItems.contains(scan.id),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedItems.add(scan.id!);
                                } else {
                                  _selectedItems.remove(scan.id);
                                }
                              });
                            },
                          ),
                          title: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              showCupertinoModalPopup(
                                context: context,
                                builder:
                                    (context) => DefaultTextStyle(
                                      style: TextStyle(
                                        fontFamily: '.SF Pro Text',
                                        fontSize: 17,
                                        color: CupertinoColors.label
                                            .resolveFrom(
                                              context,
                                            ), // This will adapt to dark mode
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom,
                                        ),
                                        color: CupertinoColors.systemBackground
                                            .resolveFrom(context),
                                        child: SafeArea(
                                          top: false,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16.0,
                                                      vertical: 12.0,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: CupertinoColors
                                                          .separator
                                                          .resolveFrom(context),
                                                      width: 0.0,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Spacer(),
                                                    Text(
                                                      'Scan Details',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: CupertinoColors
                                                            .label
                                                            .resolveFrom(
                                                              context,
                                                            ), // Explicit color for the title
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    CupertinoButton(
                                                      padding: EdgeInsets.zero,
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text('Done'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Code',
                                                      style: TextStyle(
                                                        fontFamily:
                                                            '.SF Pro Text',
                                                        fontSize: 13,
                                                        color: CupertinoColors
                                                            .secondaryLabel
                                                            .resolveFrom(
                                                              context,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    _isValidUrl(scan.code)
                                                        ? CupertinoButton(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          onPressed:
                                                              () => _launchUrl(
                                                                scan.code,
                                                              ),
                                                          child: Text(
                                                            scan.code,
                                                            style: const TextStyle(
                                                              fontFamily:
                                                                  '.SF Pro Text',
                                                              fontSize: 17,
                                                              color:
                                                                  CupertinoColors
                                                                      .activeBlue,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                            ),
                                                          ),
                                                        )
                                                        : Text(
                                                          scan.code,
                                                          style: const TextStyle(
                                                            fontFamily:
                                                                '.SF Pro Text',
                                                            fontSize: 17,
                                                          ),
                                                        ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Value',
                                                      style: TextStyle(
                                                        fontFamily:
                                                            '.SF Pro Text',
                                                        fontSize: 13,
                                                        color: CupertinoColors
                                                            .secondaryLabel
                                                            .resolveFrom(
                                                              context,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    _isValidUrl(scan.codeValue)
                                                        ? CupertinoButton(
                                                          padding:
                                                              EdgeInsets.zero,
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          onPressed:
                                                              () => _launchUrl(
                                                                scan.codeValue,
                                                              ),
                                                          child: Text(
                                                            scan.codeValue,
                                                            style: const TextStyle(
                                                              fontFamily:
                                                                  '.SF Pro Text',
                                                              fontSize: 17,
                                                              color:
                                                                  CupertinoColors
                                                                      .activeBlue,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                            ),
                                                          ),
                                                        )
                                                        : Text(
                                                          scan.codeValue,
                                                          style: const TextStyle(
                                                            fontFamily:
                                                                '.SF Pro Text',
                                                            fontSize: 17,
                                                          ),
                                                        ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Timestamp',
                                                      style: TextStyle(
                                                        fontFamily:
                                                            '.SF Pro Text',
                                                        fontSize: 13,
                                                        color: CupertinoColors
                                                            .secondaryLabel
                                                            .resolveFrom(
                                                              context,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      scan.timestamp
                                                          .toString()
                                                          .split('.')[0],
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            '.SF Pro Text',
                                                        fontSize: 17,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scan.code,
                                    style: TextStyle(
                                      fontFamily: '.SF Pro Text',
                                      fontSize: 17,
                                      color: CupertinoColors.label.resolveFrom(
                                        context,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    scan.codeValue,
                                    style: TextStyle(
                                      fontFamily: '.SF Pro Text',
                                      fontSize: 15,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          trailing: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _editScan(scan),
                            child: const Icon(CupertinoIcons.pencil, size: 20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }

        return const Center(
          child: Text(
            'Unknown state',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 17,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        );
      },
    );
  }
}
