import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/update_checker.dart';

/// Dialog shown when a newer GitHub release is available.
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key, required this.update});

  final UpdateInfo update;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Доступна версия ${update.version}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Что нового:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SelectableText(
              update.body,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Позже'),
        ),
        FilledButton.icon(
          onPressed: () async {
            final uri = Uri.parse(update.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Открыть релиз'),
        ),
      ],
    );
  }
}
