abstract final class AppConstants {
  static const String appName = 'UI Clone';
  static const String captureChannel = 'com.mobileway.ui_clone/capture';
  static const String captureEventsChannel =
      'com.mobileway.ui_clone/capture_events';

  static const int defaultCaptureIntervalMs = 1500;
  /// Near-duplicate threshold (% MAD of 16×16 luma). Below → skip frame.
  static const double defaultSimilarityPercent = 2.5;
  /// timer | manual | both
  static const String defaultCaptureMode = 'timer';
  static const int maxScreenshotsPerSession = 40;
  static const int maxImagesForAnalysis = 8;

  static const String defaultOpenAiBaseUrl = 'https://api.openai.com/v1';
  static const String defaultVisionModel = 'gpt-4o-mini';

  static const String prefsApiKey = 'openai_api_key';
  static const String prefsBaseUrl = 'openai_base_url';
  static const String prefsModel = 'openai_model';
  static const String prefsIntervalMs = 'capture_interval_ms';
  static const String prefsSimilarityPercent = 'capture_similarity_percent';
  static const String prefsCaptureMode = 'capture_mode';
}
