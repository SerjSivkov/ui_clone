import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/ai_providers.dart';
import '../../data/prompt_templates.dart';
import '../about/about_screen.dart';
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
  final _promptCtrl = TextEditingController();
  double _intervalSec = AppConstants.defaultCaptureIntervalMs / 1000;
  double _similarityPercent = AppConstants.defaultSimilarityPercent;
  String _captureMode = AppConstants.defaultCaptureMode;
  double _maxSessionMin = AppConstants.defaultMaxSessionSec / 60;
  String _promptTemplateId = AppConstants.defaultPromptTemplateId;
  String _aiProviderId = AppConstants.defaultAiProviderId;
  bool _loading = true;
  bool _obscure = true;

  AiProviderPreset get _provider => AiProviders.byId(_aiProviderId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsServiceProvider);
    final key = await settings.getApiKey();
    final providerId = await settings.getAiProviderId();
    final base = await settings.getBaseUrl();
    final model = await settings.getModel();
    final interval = await settings.getCaptureIntervalMs();
    final similarity = await settings.getSimilarityPercent();
    final captureMode = await settings.getCaptureMode();
    final maxSessionSec = await settings.getMaxSessionSec();
    final templateId = await settings.getPromptTemplateId();
    final systemPrompt = await settings.getSystemPrompt();
    if (!mounted) return;
    setState(() {
      _apiKeyCtrl.text = key ?? '';
      _aiProviderId = providerId;
      _baseUrlCtrl.text = base;
      _modelCtrl.text = model;
      _intervalSec = interval / 1000;
      _similarityPercent = similarity;
      _captureMode = captureMode;
      _maxSessionMin = maxSessionSec / 60;
      _promptTemplateId = templateId;
      _promptCtrl.text = systemPrompt;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final settings = ref.read(settingsServiceProvider);
    await settings.setApiKey(_apiKeyCtrl.text);
    await settings.setAiProviderId(_aiProviderId);
    await settings.setBaseUrl(_baseUrlCtrl.text);
    await settings.setModel(_modelCtrl.text);
    await settings.setCaptureIntervalMs((_intervalSec * 1000).round());
    await settings.setSimilarityPercent(_similarityPercent);
    await settings.setCaptureMode(_captureMode);
    await settings.setMaxSessionSec((_maxSessionMin * 60).round());
    await settings.setPromptTemplateId(_promptTemplateId);
    await settings.setSystemPrompt(_promptCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сохранено')),
    );
  }

  void _onProviderChanged(String? id) {
    if (id == null || id == _aiProviderId) return;
    final preset = AiProviders.byId(id);
    setState(() {
      _aiProviderId = id;
      _baseUrlCtrl.text = preset.defaultBaseUrl;
      _modelCtrl.text = preset.defaultModel;
    });
  }

  bool get _promptDirty {
    final current = _promptCtrl.text.trim();
    final defaults = PromptTemplates.defaultBody(_promptTemplateId).trim();
    return current != defaults;
  }

  Future<void> _onTemplateChanged(String? id) async {
    if (id == null || id == _promptTemplateId) return;
    if (_promptDirty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Сменить шаблон?'),
          content: const Text(
            'Текущий текст промпта будет заменён текстом выбранного шаблона.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Заменить'),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }
    setState(() {
      _promptTemplateId = id;
      _promptCtrl.text = PromptTemplates.defaultBody(id);
    });
  }

  void _resetPromptToTemplate() {
    setState(() {
      _promptCtrl.text = PromptTemplates.defaultBody(_promptTemplateId);
    });
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _modelCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
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
                  'Выберите провайдера vision-модели. Без ключа приложение '
                  'соберёт офлайн-шаблон промпта по скриншотам.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _aiProviderId,
                  decoration: const InputDecoration(
                    labelText: 'Провайдер',
                  ),
                  items: [
                    for (final p in AiProviders.all)
                      DropdownMenuItem(
                        value: AiProviders.idString(p.id),
                        child: Text(p.title),
                      ),
                  ],
                  onChanged: _onProviderChanged,
                ),
                const SizedBox(height: 6),
                Text(
                  provider.hint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  enabled: provider.baseUrlEditable,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Base URL',
                    hintText: provider.defaultBaseUrl,
                    helperText: provider.baseUrlEditable
                        ? (provider.id == AiProviderId.anthropic
                            ? 'По умолчанию api.anthropic.com; можно указать прокси'
                            : 'Для OpenAI-compatible / Anthropic можно указать свой endpoint')
                        : 'URL задаётся провайдером',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Модель',
                    hintText: provider.defaultModel,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Промпт',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Системный промпт для vision-анализа. Плейсхолдеры '
                  '{{app}}, {{package}}, {{count}} подставляются при анализе.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _promptTemplateId,
                  decoration: const InputDecoration(
                    labelText: 'Шаблон',
                  ),
                  items: [
                    for (final t in PromptTemplates.all)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(t.title),
                      ),
                  ],
                  onChanged: _onTemplateChanged,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _promptCtrl,
                  minLines: 8,
                  maxLines: 16,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Системный промпт',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _resetPromptToTemplate,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Сбросить к шаблону'),
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
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(captureRepositoryProvider)
                        .requestAccessibilityAccess();
                  },
                  icon: const Icon(Icons.accessibility_new_outlined),
                  label: const Text('Accessibility (фильтр по app)'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(captureRepositoryProvider)
                        .requestUsageAccess();
                  },
                  icon: const Icon(Icons.query_stats_outlined),
                  label: const Text('Статистика использования (запасной)'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('О приложении'),
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
