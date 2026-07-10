import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

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
    return prefs.getString(AppConstants.prefsBaseUrl) ??
        AppConstants.defaultOpenAiBaseUrl;
  }

  Future<void> setBaseUrl(String value) async {
    final prefs = await _prefsFuture;
    await prefs.setString(AppConstants.prefsBaseUrl, value.trim());
  }

  Future<String> getModel() async {
    final prefs = await _prefsFuture;
    return prefs.getString(AppConstants.prefsModel) ??
        AppConstants.defaultVisionModel;
  }

  Future<void> setModel(String value) async {
    final prefs = await _prefsFuture;
    await prefs.setString(AppConstants.prefsModel, value.trim());
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
}
