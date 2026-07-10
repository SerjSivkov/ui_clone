import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/ai_providers.dart';
import '../../data/prompt_templates.dart';
import '../capture/capture_controller.dart';
import '../settings/settings_screen.dart';

/// Bottom sheet: pick provider / model / prompt template, then re-run analysis.
Future<bool> showReanalyzeSheet(BuildContext context, WidgetRef ref) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _ReanalyzeSheet(),
  );
  return result == true;
}

class _ReanalyzeSheet extends ConsumerStatefulWidget {
  const _ReanalyzeSheet();

  @override
  ConsumerState<_ReanalyzeSheet> createState() => _ReanalyzeSheetState();
}

class _ReanalyzeSheetState extends ConsumerState<_ReanalyzeSheet> {
  final _modelCtrl = TextEditingController();
  String _aiProviderId = AppConstants.defaultAiProviderId;
  String _promptTemplateId = AppConstants.defaultPromptTemplateId;
  bool _loading = true;
  bool _saving = false;

  AiProviderPreset get _provider => AiProviders.byId(_aiProviderId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = ref.read(settingsServiceProvider);
    final providerId = await settings.getAiProviderId();
    final model = await settings.getModel();
    final templateId = await settings.getPromptTemplateId();
    if (!mounted) return;
    setState(() {
      _aiProviderId = providerId;
      _modelCtrl.text = model;
      _promptTemplateId = templateId;
      _loading = false;
    });
  }

  void _onProviderChanged(String? id) {
    if (id == null || id == _aiProviderId) return;
    final preset = AiProviders.byId(id);
    setState(() {
      _aiProviderId = id;
      _modelCtrl.text = preset.defaultModel;
    });
  }

  Future<void> _onTemplateChanged(String? id) async {
    if (id == null || id == _promptTemplateId) return;
    setState(() => _promptTemplateId = id);
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final settings = ref.read(settingsServiceProvider);
    final previousProvider = await settings.getAiProviderId();
    final previousTemplate = await settings.getPromptTemplateId();

    await settings.setAiProviderId(_aiProviderId);
    if (previousProvider != _aiProviderId) {
      await settings.setBaseUrl(_provider.defaultBaseUrl);
    }
    await settings.setModel(_modelCtrl.text.trim());
    await settings.setPromptTemplateId(_promptTemplateId);
    if (previousTemplate != _promptTemplateId) {
      await settings.setSystemPrompt(
        PromptTemplates.defaultBody(_promptTemplateId),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: _loading
          ? const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Повторный анализ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Те же скриншоты, другие настройки vision. '
                    'Предыдущий промпт сохранится, если анализ отменить '
                    'или он завершится ошибкой.',
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
                    onChanged: _saving ? null : _onProviderChanged,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _modelCtrl,
                    enabled: !_saving,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Модель',
                      hintText: _provider.defaultModel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _promptTemplateId,
                    decoration: const InputDecoration(
                      labelText: 'Шаблон промпта',
                    ),
                    items: [
                      for (final t in PromptTemplates.all)
                        DropdownMenuItem(
                          value: t.id,
                          child: Text(t.title),
                        ),
                    ],
                    onChanged: _saving ? null : _onTemplateChanged,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _saving
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                      child: const Text('Полные настройки / свой промпт'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _confirm,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(
                      _saving ? 'Сохранение…' : 'Запустить анализ',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}
