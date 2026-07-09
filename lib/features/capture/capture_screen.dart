import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/capture_session.dart';
import 'capture_controller.dart';

class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(captureControllerProvider);
    final count = session.screenshotPaths.length;
    final isBusy = session.status == CaptureStatus.analyzing ||
        session.status == CaptureStatus.stopping;

    ref.listen(captureControllerProvider, (prev, next) {
      if (next.status == CaptureStatus.completed ||
          next.status == CaptureStatus.failed ||
          next.status == CaptureStatus.idle) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    return PopScope(
      canPop: !isBusy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Сбор интерфейса'),
          automaticallyImplyLeading: !isBusy,
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE1E7EF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: session.status == CaptureStatus.capturing
                                ? AppColors.warn
                                : AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _statusLabel(session.status),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      session.targetLabel ??
                          'Текущий экран устройства (без привязки к app)',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (session.targetPackage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        session.targetPackage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.slate,
                            ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Скриншотов: $count',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Листайте экраны целевого приложения. '
                      'Остановить: кнопка ниже, уведомление или оверлей.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.slate,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: count == 0
                    ? Center(
                        child: Text(
                          isBusy
                              ? 'Обработка…'
                              : 'Ожидание первого скриншота…',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.slate),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: count,
                        itemBuilder: (context, index) {
                          final path = session.screenshotPaths[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.mist,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              if (session.status == CaptureStatus.analyzing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      LinearProgressIndicator(),
                      SizedBox(height: 10),
                      Text('AI анализирует скриншоты и собирает промпт…'),
                    ],
                  ),
                ),
              FilledButton.icon(
                onPressed: isBusy
                    ? null
                    : () {
                        ref
                            .read(captureControllerProvider.notifier)
                            .stopAndAnalyze();
                      },
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(
                  session.status == CaptureStatus.analyzing
                      ? 'Анализ…'
                      : 'Остановить сбор',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(CaptureStatus status) {
    return switch (status) {
      CaptureStatus.idle => 'Ожидание',
      CaptureStatus.requestingPermission => 'Запрос разрешения',
      CaptureStatus.capturing => 'Идёт запись',
      CaptureStatus.stopping => 'Остановка',
      CaptureStatus.analyzing => 'Анализ AI',
      CaptureStatus.completed => 'Готово',
      CaptureStatus.failed => 'Ошибка',
    };
  }
}
