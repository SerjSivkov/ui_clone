import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../capture/capture_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  double _intervalSec = AppConstants.defaultCaptureIntervalMs / 1000;
  double _similarityPercent = AppConstants.defaultSimilarityPercent;
  String _captureMode = AppConstants.defaultCaptureMode;
  double _maxSessionMin = AppConstants.defaultMaxSessionSec / 60;
  bool _loading = true;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsServiceProvider);
    final key = await settings.getApiKey();
    final base = await settings.getBaseUrl();
    final model = await settings.getModel();
    final interval = await settings.getCaptureIntervalMs();
    final similarity = await settings.getSimilarityPercent();
    final captureMode = await settings.getCaptureMode();
    final maxSessionSec = await settings.getMaxSessionSec();
    if (!mounted) return;
    setState(() {
      _apiKeyCtrl.text = key ?? '';
      _baseUrlCtrl.text = base;
      _modelCtrl.text = model;
      _intervalSec = interval / 1000;
      _similarityPercent = similarity;
      _captureMode = captureMode;
      _maxSessionMin = maxSessionSec / 60;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final settings = ref.read(settingsServiceProvider);
    await settings.setApiKey(_apiKeyCtrl.text);
    await settings.setBaseUrl(_baseUrlCtrl.text);
    await settings.setModel(_modelCtrl.text);
    await settings.setCaptureIntervalMs((_intervalSec * 1000).round());
    await settings.setSimilarityPercent(_similarityPercent);
    await settings.setCaptureMode(_captureMode);
    await settings.setMaxSessionSec((_maxSessionMin * 60).round());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сохранено')),
    );
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  'Vision API',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'OpenAI-совместимый endpoint с vision-моделью. '
                  'Без ключа приложение всё равно соберёт шаблон промпта '
                  'по скриншотам.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _apiKeyCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'API key',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _baseUrlCtrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.openai.com/v1',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Модель',
                    hintText: 'gpt-4o-mini',
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Захват',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Режим сбора',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'timer',
                      label: Text('Таймер'),
                      icon: Icon(Icons.timer_outlined),
                    ),
                    ButtonSegment(
                      value: 'manual',
                      label: Text('Вручную'),
                      icon: Icon(Icons.touch_app_outlined),
                    ),
                    ButtonSegment(
                      value: 'both',
                      label: Text('Оба'),
                      icon: Icon(Icons.merge_type_outlined),
                    ),
                  ],
                  selected: {_captureMode},
                  onSelectionChanged: (set) {
                    setState(() => _captureMode = set.first);
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  switch (_captureMode) {
                    'manual' =>
                      'Кадры только по кнопке «+ кадр» в оверлее / уведомлении.',
                    'both' =>
                      'Таймер + ручные снимки «+ кадр» поверх таймера.',
                    _ => 'Автоматические скриншоты по интервалу.',
                  },
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
                if (_captureMode != 'manual') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Интервал скриншотов: ${_intervalSec.toStringAsFixed(1)} с',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: _intervalSec,
                    min: 0.8,
                    max: 5,
                    divisions: 21,
                    label: '${_intervalSec.toStringAsFixed(1)} с',
                    onChanged: (v) => setState(() => _intervalSec = v),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Порог дублей: ${_similarityPercent.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Кадры похожести ниже порога не сохраняются '
                  '(ручной «+ кадр» всегда сохраняется).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
                Slider(
                  value: _similarityPercent,
                  min: 0.5,
                  max: 10,
                  divisions: 19,
                  label: '${_similarityPercent.toStringAsFixed(1)}%',
                  onChanged: (v) => setState(() => _similarityPercent = v),
                ),
                const SizedBox(height: 8),
                Text(
                  'Лимит сессии: ${_maxSessionMin.round()} мин',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'За ${AppConstants.defaultWarnBeforeSec} с до конца — '
                  'предупреждение, затем автостоп. Пауза не тратит лимит.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
                Slider(
                  value: _maxSessionMin,
                  min: 1,
                  max: 15,
                  divisions: 14,
                  label: '${_maxSessionMin.round()} мин',
                  onChanged: (v) => setState(() => _maxSessionMin = v),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(captureRepositoryProvider)
                        .requestOverlayPermission();
                  },
                  icon: const Icon(Icons.picture_in_picture_alt_outlined),
                  label: const Text('Разрешение оверлея'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Сохранить'),
                ),
              ],
            ),
    );
  }
}
