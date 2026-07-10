abstract final class AppConstants {
  static const String appName = 'UI Clone';
  static const String captureChannel = 'com.mobileway.ui_clone/capture';
  static const String captureEventsChannel =
      'com.mobileway.ui_clone/capture_events';

  static const String githubUrl = 'https://github.com/SerjSivkov/ui_clone';
  static const String donateUrl = 'https://pay.cloudtips.ru/p/9cabf23f';
  static const String licenseAsset = 'LICENSE';
  static const String termsAsset = 'assets/legal/terms_of_use.txt';

  static const int defaultCaptureIntervalMs = 1500;
  /// Near-duplicate threshold (% MAD of 16×16 luma). Below → skip frame.
  static const double defaultSimilarityPercent = 2.5;
  /// timer | manual | both
  static const String defaultCaptureMode = 'timer';
  /// Hard session limit (seconds). Auto-stop when reached.
  static const int defaultMaxSessionSec = 300;
  /// Warn this many seconds before auto-stop.
  static const int defaultWarnBeforeSec = 30;
  static const int maxScreenshotsPerSession = 40;
  static const int maxImagesForAnalysis = 8;

  static const String defaultOpenAiBaseUrl = 'https://api.openai.com/v1';
  static const String defaultVisionModel = 'gpt-4o-mini';
  static const String defaultPromptTemplateId = 'flutter';
  static const String defaultAiProviderId = 'openai';
  /// JPEG quality for vision upload (40–95).
  static const int defaultJpegQuality = 70;
  /// Longest side in px before upload (512–2048).
  static const int defaultJpegMaxSide = 1280;

  static const String prefsApiKey = 'openai_api_key';
  static const String prefsBaseUrl = 'openai_base_url';
  static const String prefsModel = 'openai_model';
  static const String prefsAiProviderId = 'ai_provider_id';
  static const String prefsIntervalMs = 'capture_interval_ms';
  static const String prefsSimilarityPercent = 'capture_similarity_percent';
  static const String prefsCaptureMode = 'capture_mode';
  static const String prefsMaxSessionSec = 'capture_max_session_sec';
  static const String prefsPromptTemplateId = 'prompt_template_id';
  static const String prefsSystemPrompt = 'system_prompt';
  static const String prefsJpegQuality = 'jpeg_upload_quality';
  static const String prefsJpegMaxSide = 'jpeg_upload_max_side';
}
