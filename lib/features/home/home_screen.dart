import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/capture_session.dart';
import '../app_picker/app_picker_screen.dart';
import '../capture/capture_controller.dart';
import '../capture/capture_screen.dart';
import '../result/result_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(captureControllerProvider);

    ref.listen(captureControllerProvider, (prev, next) {
      if (next.status == CaptureStatus.capturing &&
          prev?.status != CaptureStatus.capturing) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CaptureScreen()),
        );
      }
      if (next.status == CaptureStatus.completed &&
          prev?.status != CaptureStatus.completed) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ResultScreen()),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'UI Clone',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Настройки',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Снимите UI целевого приложения — AI соберёт '
                'промпт для клонирования стиля, кнопок и экранов.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.slate,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F8B8D),
                        Color(0xFF134E5E),
                        Color(0xFF1A2A3A),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        bottom: -30,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Обзор интерфейса',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '1. Выберите приложение\n'
                              '2. Разрешите запись экрана\n'
                              '3. Листайте экраны цели\n'
                              '4. Остановите сбор в шторке или оверлее',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    height: 1.55,
                                  ),
                            ),
                            const Spacer(),
                            if (session.status == CaptureStatus.failed &&
                                session.errorMessage != null) ...[
                              SelectableText.rich(
                                TextSpan(
                                  text: session.errorMessage,
                                  style: const TextStyle(
                                    color: Color(0xFFFFB4A9),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.accentDeep,
                                ),
                                onPressed: () async {
                                  final supported = await ref
                                      .read(captureRepositoryProvider)
                                      .isSupported();
                                  if (!context.mounted) return;
                                  if (!supported) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Захват экрана доступен на Android 5+',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const AppPickerScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Начать обзор интерфейса'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                                onPressed: () {
                                  ref
                                      .read(captureControllerProvider.notifier)
                                      .start();
                                },
                                child: const Text(
                                  'Сбор без выбора приложения',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
