import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/capture_session.dart';
import '../result/result_screen.dart';
import 'capture_controller.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  /// Latches on first stop tap / external stop so the Stop CTA cannot
  /// reappear even if session status briefly flickers.
  bool _stopLatched = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(captureControllerProvider);
    final count = session.screenshotPaths.length;

    // Live controls while capturing or paused.
    final showLiveControls = !_stopLatched &&
        (session.status == CaptureStatus.capturing ||
            session.status == CaptureStatus.paused ||
            session.status == CaptureStatus.requestingPermission);
    final isPaused = session.status == CaptureStatus.paused;
    final isProcessing = !showLiveControls;

    ref.listen(captureControllerProvider, (prev, next) {
      if (!_stopLatched &&
          (next.status == CaptureStatus.stopping ||
              next.status == CaptureStatus.analyzing ||
              next.status == CaptureStatus.completed ||
              next.status == CaptureStatus.failed)) {
        setState(() => _stopLatched = true);
      }

      if (next.status == CaptureStatus.completed &&
          prev?.status != CaptureStatus.completed) {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const ResultScreen()),
        );
        return;
      }

      if (next.status == CaptureStatus.failed &&
          prev?.status != CaptureStatus.failed) {
        if (!context.mounted) return;
        final message = next.errorMessage ?? 'Ошибка сбора';
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });

    return PopScope(
      canPop: !isProcessing,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isProcessing ? 'Обработка' : 'Сбор интерфейса'),
          automaticallyImplyLeading: !isProcessing,
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
                            color: showLiveControls
                                ? (isPaused
                                    ? AppColors.slate
                                    : AppColors.warn)
                                : AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _statusLabel(
                            session.status,
                            showLiveControls: showLiveControls,
                          ),
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
                      'Скриншотов: $count'
                      '${session.skippedDuplicates > 0 ? ' · дублей пропущено: ${session.skippedDuplicates}' : ''}'
                      '${session.remainingSec != null ? ' · ${_formatRemaining(session.remainingSec!)}' : ''}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (session.timeLimitWarning && showLiveControls) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1E8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warn),
                        ),
                        child: Text(
                          'Скоро автостоп'
                          '${session.remainingSec != null ? ' через ${_formatRemaining(session.remainingSec!)}' : ''}. '
                          'Остановите сбор или дождитесь лимита.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.warn,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      isProcessing
                          ? 'Сбор остановлен. Готовим промпт…'
                          : isPaused
                              ? 'Пауза: таймер остановлен. «+ кадр» в оверлее '
                                  'всё ещё работает. Нажмите «Далее».'
                              : 'Листайте экраны цели. Пауза / Стоп — оверлей, '
                                  'уведомление или кнопки ниже. В режимах '
                                  '«Вручную» / «Оба» жмите «+ кадр».',
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
                          isProcessing
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
              if (isProcessing) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  switch (session.status) {
                    CaptureStatus.analyzing =>
                      'Собираем промпт по скриншотам…',
                    CaptureStatus.completed => 'Промпт готов…',
                    CaptureStatus.failed =>
                      session.errorMessage ?? 'Ошибка обработки',
                    _ => 'Останавливаем сбор…',
                  },
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: null,
                  icon: Icon(
                    switch (session.status) {
                      CaptureStatus.analyzing ||
                      CaptureStatus.completed =>
                        Icons.auto_awesome_rounded,
                      CaptureStatus.failed => Icons.error_outline_rounded,
                      _ => Icons.hourglass_top_rounded,
                    },
                  ),
                  label: Text(
                    switch (session.status) {
                      CaptureStatus.analyzing => 'Анализ…',
                      CaptureStatus.completed => 'Готово',
                      CaptureStatus.failed => 'Ошибка',
                      _ => 'Остановка…',
                    },
                  ),
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: AppColors.slate,
                    disabledForegroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(captureControllerProvider.notifier)
                        .togglePause();
                  },
                  icon: Icon(
                    isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  label: Text(isPaused ? 'Далее' : 'Пауза'),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () {
                    setState(() => _stopLatched = true);
                    ref
                        .read(captureControllerProvider.notifier)
                        .stopAndAnalyze();
                  },
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Остановить сбор'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(
    CaptureStatus status, {
    required bool showLiveControls,
  }) {
    if (!showLiveControls) {
      return switch (status) {
        CaptureStatus.analyzing => 'Анализ',
        CaptureStatus.completed => 'Готово',
        CaptureStatus.failed => 'Ошибка',
        _ => 'Остановка',
      };
    }
    return switch (status) {
      CaptureStatus.idle => 'Ожидание',
      CaptureStatus.requestingPermission => 'Запрос разрешения',
      CaptureStatus.capturing => 'Идёт запись',
      CaptureStatus.paused => 'Пауза',
      CaptureStatus.stopping => 'Остановка',
      CaptureStatus.analyzing => 'Анализ AI',
      CaptureStatus.completed => 'Готово',
      CaptureStatus.failed => 'Ошибка',
    };
  }

  String _formatRemaining(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
