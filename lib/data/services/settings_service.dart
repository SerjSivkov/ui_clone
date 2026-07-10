import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../ai_providers.dart';
import '../prompt_templates.dart';

class SettingsService {
  SettingsService({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? preferences,
  })  : _secure = secureStorage ?? const FlutterSecureStorage(),
        _prefsFuture = preferences != null
            ? Future.value(preferences)
            : SharedPreferences.getInstance();

  final FlutterSecureStorage _secure;
  final Future<SharedPreferences> _prefsFuture;

  Future<String?> getApiKey() => _secure.read(key: AppConstants.prefsApiKey);

  Future<void> setApiKey(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _secure.delete(key: AppConstants.prefsApiKey);
      return;
    }
    await _secure.write(key: AppConstants.prefsApiKey, value: value.trim());
  }

  Future<String> getBaseUrl() async {
    final prefs = await _prefsFuture;
    final stored = prefs.getString(AppConstants.prefsBaseUrl);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    final provider = await getAiProviderId();
    return AiProviders.byId(provider).defaultBaseUrl;
  }

  Future<void> setBaseUrl(String value) async {
    final prefs = await _prefsFuture;
    await prefs.setString(AppConstants.prefsBaseUrl, value.trim());
  }

  Future<String> getModel() async {
    final prefs = await _prefsFuture;
    final stored = prefs.getString(AppConstants.prefsModel);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    final provider = await getAiProviderId();
    return AiProviders.byId(provider).defaultModel;
  }

  Future<void> setModel(String value) async {
    final prefs = await _prefsFuture;
    await prefs.setString(AppConstants.prefsModel, value.trim());
  }

  Future<String> getAiProviderId() async {
    final prefs = await _prefsFuture;
    final value = prefs.getString(AppConstants.prefsAiProviderId);
    if (value != null && AiProviders.isKnownId(value)) {
      return value;
    }
    return AppConstants.defaultAiProviderId;
  }

  Future<void> setAiProviderId(String value) async {
    final prefs = await _prefsFuture;
    final id = AiProviders.isKnownId(value)
        ? value
        : AppConstants.defaultAiProviderId;
    await prefs.setString(AppConstants.prefsAiProviderId, id);
  }

  Future<int> getCaptureIntervalMs() async {
    final prefs = await _prefsFuture;
    return prefs.getInt(AppConstants.prefsIntervalMs) ??
        AppConstants.defaultCaptureIntervalMs;
  }

  Future<void> setCaptureIntervalMs(int value) async {
    final prefs = await _prefsFuture;
    await prefs.setInt(AppConstants.prefsIntervalMs, value);
  }

  Future<double> getSimilarityPercent() async {
    final prefs = await _prefsFuture;
    return prefs.getDouble(AppConstants.prefsSimilarityPercent) ??
        AppConstants.defaultSimilarityPercent;
  }

  Future<void> setSimilarityPercent(double value) async {
    final prefs = await _prefsFuture;
    await prefs.setDouble(AppConstants.prefsSimilarityPercent, value);
  }

  /// `timer` | `manual` | `both`
  Future<String> getCaptureMode() async {
    final prefs = await _prefsFuture;
    final value = prefs.getString(AppConstants.prefsCaptureMode);
    return switch (value) {
      'manual' || 'both' || 'timer' => value!,
      _ => AppConstants.defaultCaptureMode,
    };
  }

  Future<void> setCaptureMode(String value) async {
    final prefs = await _prefsFuture;
    final normalized = switch (value) {
      'manual' || 'both' => value,
      _ => 'timer',
    };
    await prefs.setString(AppConstants.prefsCaptureMode, normalized);
  }

  Future<int> getMaxSessionSec() async {
    final prefs = await _prefsFuture;
    return prefs.getInt(AppConstants.prefsMaxSessionSec) ??
        AppConstants.defaultMaxSessionSec;
  }

  Future<void> setMaxSessionSec(int value) async {
    final prefs = await _prefsFuture;
    await prefs.setInt(
      AppConstants.prefsMaxSessionSec,
      value.clamp(60, 900),
    );
  }

  Future<String> getPromptTemplateId() async {
    final prefs = await _prefsFuture;
    final value = prefs.getString(AppConstants.prefsPromptTemplateId);
    if (value != null && PromptTemplates.isKnownId(value)) {
      return value;
    }
    return AppConstants.defaultPromptTemplateId;
  }

  Future<void> setPromptTemplateId(String value) async {
    final prefs = await _prefsFuture;
    final id = PromptTemplates.isKnownId(value)
        ? value
        : AppConstants.defaultPromptTemplateId;
    await prefs.setString(AppConstants.prefsPromptTemplateId, id);
  }

  /// Custom system prompt body. Empty / missing → use template default.
  Future<String> getSystemPrompt() async {
    final prefs = await _prefsFuture;
    final stored = prefs.getString(AppConstants.prefsSystemPrompt);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored;
    }
    final id = await getPromptTemplateId();
    return PromptTemplates.defaultBody(id);
  }

  Future<void> setSystemPrompt(String value) async {
    final prefs = await _prefsFuture;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(AppConstants.prefsSystemPrompt);
      return;
    }
    await prefs.setString(AppConstants.prefsSystemPrompt, value);
  }

  Future<int> getJpegQuality() async {
    final prefs = await _prefsFuture;
    return (prefs.getInt(AppConstants.prefsJpegQuality) ??
            AppConstants.defaultJpegQuality)
        .clamp(40, 95);
  }

  Future<void> setJpegQuality(int value) async {
    final prefs = await _prefsFuture;
    await prefs.setInt(
      AppConstants.prefsJpegQuality,
      value.clamp(40, 95),
    );
  }

  Future<int> getJpegMaxSide() async {
    final prefs = await _prefsFuture;
    return (prefs.getInt(AppConstants.prefsJpegMaxSide) ??
            AppConstants.defaultJpegMaxSide)
        .clamp(512, 2048);
  }

  Future<void> setJpegMaxSide(int value) async {
    final prefs = await _prefsFuture;
    await prefs.setInt(
      AppConstants.prefsJpegMaxSide,
      value.clamp(512, 2048),
    );
  }
}
