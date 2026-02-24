import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import '../blocs/settings/settings_bloc.dart';
import '../models/webhook.dart';

class WebhookHistoryScreen extends StatelessWidget {
  const WebhookHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Webhook History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final webhooks = state.webhooks;

          if (webhooks.isEmpty) {
            return Center(
              child: Text(
                'No webhooks saved yet',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: webhooks.length,
            itemBuilder: (context, index) {
              final webhook = webhooks[index];
              final isActive = webhook.url == state.webhookUrl &&
                  webhook.title == state.webhookTitle;

              return _WebhookCard(
                webhook: webhook,
                isActive: isActive,
                onTap: () => _showWebhookOptions(context, webhook),
              );
            },
          );
        },
      ),
    );
  }

  void _showWebhookOptions(BuildContext context, Webhook webhook) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(webhook.title),
        message: Text(
          webhook.url,
          style: const TextStyle(fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteWebhook(context, webhook);
            },
            isDestructiveAction: true,
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _confirmDeleteWebhook(BuildContext context, Webhook webhook) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Delete Webhook'),
        content: Text('Are you sure you want to delete "${webhook.title}"?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              context.read<SettingsBloc>().add(DeleteWebhook(webhook.id!));
            },
            isDestructiveAction: true,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _WebhookCard extends StatelessWidget {
  final Webhook webhook;
  final bool isActive;
  final VoidCallback onTap;

  const _WebhookCard({
    required this.webhook,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryLabelColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tagBackgroundColor = isDark
        ? CupertinoColors.systemGrey5.resolveFrom(context).withValues(alpha: 0.3)
        : CupertinoColors.systemGrey5.resolveFrom(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark
          ? CupertinoColors.systemGrey6.resolveFrom(context)
          : null,
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark
            ? BorderSide(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          webhook.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.activeBlue.resolveFrom(
                                context,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.activeBlue.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      webhook.url,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryLabelColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ...webhook.headers.entries
                            .where((entry) => entry.key != 'Content-Type')
                            .take(2)
                            .map(
                              (entry) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: tagBackgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? CupertinoColors.white
                                        : secondaryLabelColor,
                                  ),
                                ),
                              ),
                            )
                            ,
                        if (webhook.headers.entries.where((entry) => entry.key != 'Content-Type').length > 2)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tagBackgroundColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${webhook.headers.entries.where((entry) => entry.key != 'Content-Type').length - 2}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? CupertinoColors.white
                                    : secondaryLabelColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isActive)
                IconButton(
                  icon: Icon(
                    Icons.radio_button_unchecked,
                    color: CupertinoColors.activeGreen.resolveFrom(context),
                  ),
                  onPressed: () => _activateWebhook(context),
                  tooltip: 'Set as active',
                ),
              if (isActive)
                IconButton(
                  icon:Icon(
                  Icons.check_circle,
                  color: CupertinoColors.activeGreen.resolveFrom(context),
                ),
                onPressed: () => _activateWebhook(context),
                  tooltip: 'Set as active',
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _activateWebhook(BuildContext context) {
    context.read<SettingsBloc>().add(SwitchWebhook(webhook));
  }
}
