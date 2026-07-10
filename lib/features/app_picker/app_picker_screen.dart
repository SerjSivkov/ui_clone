import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/installed_app.dart';
import '../capture/capture_controller.dart';
import 'app_picker_controller.dart';

class AppPickerScreen extends ConsumerWidget {
  const AppPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(filteredAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите приложение'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                hintText: 'Поиск по названию или package',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) {
                ref.read(appSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'После выбора откроется целевое приложение и начнётся '
                'запись экрана. Остановить можно из уведомления или '
                'плавающей кнопки.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.slate,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: appsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SelectableText.rich(
                    TextSpan(
                      text: error.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
              data: (apps) {
                if (apps.isEmpty) {
                  return const Center(child: Text('Приложения не найдены'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: apps.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return _AppTile(
                      app: app,
                      onTap: () async {
                        final repo = ref.read(captureRepositoryProvider);
                        final canTrack = await repo.hasUsageAccess();
                        if (!canTrack && context.mounted) {
                          final go = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Отслеживание приложения'),
                              content: const Text(
                                'Чтобы сохранять кадры только из выбранного '
                                'приложения, включите службу спец. '
                                'возможностей «UI Clone» (Accessibility). '
                                'Без этого сбор с привязкой к app не начнётся.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Отмена'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Открыть настройки'),
                                ),
                              ],
                            ),
                          );
                          if (go == true) {
                            await repo.requestAccessibilityAccess();
                          }
                          // Require tracking before starting with a target.
                          final ready = await repo.hasUsageAccess();
                          if (!ready) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Включите Accessibility для UI Clone и '
                                    'выберите приложение снова.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                        }
                        final hasOverlay = await repo.hasOverlayPermission();
                        if (!hasOverlay && context.mounted) {
                          final go = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Плавающая кнопка'),
                              content: const Text(
                                'Для кнопки «Стоп» поверх других приложений '
                                'нужно разрешение «Показ поверх других окон». '
                                'Можно пропустить и останавливать сбор из '
                                'панели уведомлений.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Пропустить'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Открыть настройки'),
                                ),
                              ],
                            ),
                          );
                          if (go == true) {
                            await repo.requestOverlayPermission();
                          }
                        }
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        await ref
                            .read(captureControllerProvider.notifier)
                            .start(target: app);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({
    required this.app,
    required this.onTap,
  });

  final InstalledApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget leading = CircleAvatar(
      backgroundColor: AppColors.mist,
      child: Text(
        app.label.isNotEmpty ? app.label[0].toUpperCase() : '?',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    final icon = app.iconBase64;
    if (icon != null && icon.isNotEmpty) {
      try {
        leading = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(icon),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => leading,
          ),
        );
      } catch (_) {}
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.slate,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}
