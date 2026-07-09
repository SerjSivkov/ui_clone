import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../capture/capture_controller.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(captureControllerProvider);
    final prompt = session.prompt ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Промпт для клона'),
        actions: [
          IconButton(
            tooltip: 'Копировать',
            onPressed: prompt.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: prompt));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Промпт скопирован')),
                      );
                    }
                  },
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            tooltip: 'Поделиться',
            onPressed: prompt.isEmpty
                ? null
                : () {
                    Share.share(prompt, subject: 'UI Clone prompt');
                  },
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            session.targetLabel ?? 'Сессия захвата',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '${session.screenshotPaths.length} скриншотов · '
            'готово к вставке в Cursor / Claude / GPT',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.slate,
                ),
          ),
          const SizedBox(height: 16),
          if (session.screenshotPaths.isNotEmpty)
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: session.screenshotPaths.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final path = session.screenshotPaths[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.mist,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE1E7EF)),
            ),
            child: SelectableText(
              prompt.isEmpty ? 'Промпт пуст' : prompt,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              ref.read(captureControllerProvider.notifier).reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Новый обзор'),
          ),
        ],
      ),
    );
  }
}
