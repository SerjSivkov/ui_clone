/// Vision API provider presets for UI Clone analysis.
enum AiProviderId {
  openai,
  anthropic,
  gemini,
  openaiCompatible,

  /// On-device heuristics only — screenshots never leave the device.
  local,
}

class AiProviderPreset {
  const AiProviderPreset({
    required this.id,
    required this.title,
    required this.defaultBaseUrl,
    required this.defaultModel,
    required this.baseUrlEditable,
    required this.hint,
    this.requiresApiKey = true,
    this.uploadsScreenshots = true,
  });

  final AiProviderId id;
  final String title;
  final String defaultBaseUrl;
  final String defaultModel;
  final bool baseUrlEditable;
  final String hint;

  /// When false, API key / Base URL / model fields are hidden in settings.
  final bool requiresApiKey;

  /// When false, analysis must not send images to any network endpoint.
  final bool uploadsScreenshots;
}

abstract final class AiProviders {
  static const String openai = 'openai';
  static const String anthropic = 'anthropic';
  static const String gemini = 'gemini';
  static const String openaiCompatible = 'openai_compatible';
  static const String local = 'local';

  static const String defaultId = openai;

  static const List<AiProviderPreset> all = [
    AiProviderPreset(
      id: AiProviderId.openai,
      title: 'OpenAI',
      defaultBaseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-4o-mini',
      baseUrlEditable: false,
      hint: 'Chat Completions + vision. Ключ с platform.openai.com.',
    ),
    AiProviderPreset(
      id: AiProviderId.anthropic,
      title: 'Anthropic',
      defaultBaseUrl: 'https://api.anthropic.com',
      defaultModel: 'claude-sonnet-4-20250514',
      baseUrlEditable: true,
      hint:
          'Messages API + изображения. Ключ с console.anthropic.com. '
          'Base URL можно заменить (прокси / совместимый endpoint).',
    ),
    AiProviderPreset(
      id: AiProviderId.gemini,
      title: 'Gemini',
      defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      defaultModel: 'gemini-2.0-flash',
      baseUrlEditable: false,
      hint: 'generateContent + inline images. Ключ из Google AI Studio.',
    ),
    AiProviderPreset(
      id: AiProviderId.openaiCompatible,
      title: 'OpenAI-compatible',
      defaultBaseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-4o-mini',
      baseUrlEditable: true,
      hint:
          'Любой endpoint с /chat/completions (OpenRouter, Ollama, '
          'LM Studio, локальный PocketForge-сервер…).',
    ),
    AiProviderPreset(
      id: AiProviderId.local,
      title: 'Локально (без облака)',
      defaultBaseUrl: '',
      defaultModel: 'on-device-palette',
      baseUrlEditable: false,
      requiresApiKey: false,
      uploadsScreenshots: false,
      hint:
          'Скриншоты не уходят в сеть. Палитра HEX и черновик промпта '
          'собираются на устройстве. Полноценный on-device LLM '
          '(Gemma / PocketForge в APK) — отдельный эпик.',
    ),
  ];

  static AiProviderPreset byId(String id) {
    final parsed = parseId(id);
    return all.firstWhere((p) => p.id == parsed);
  }

  static AiProviderId parseId(String? raw) {
    return switch (raw) {
      anthropic => AiProviderId.anthropic,
      gemini => AiProviderId.gemini,
      openaiCompatible => AiProviderId.openaiCompatible,
      local => AiProviderId.local,
      _ => AiProviderId.openai,
    };
  }

  static String idString(AiProviderId id) {
    return switch (id) {
      AiProviderId.openai => openai,
      AiProviderId.anthropic => anthropic,
      AiProviderId.gemini => gemini,
      AiProviderId.openaiCompatible => openaiCompatible,
      AiProviderId.local => local,
    };
  }

  static bool isKnownId(String id) =>
      id == openai ||
      id == anthropic ||
      id == gemini ||
      id == openaiCompatible ||
      id == local;
}
