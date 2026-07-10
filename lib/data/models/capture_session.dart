import 'package:freezed_annotation/freezed_annotation.dart';

part 'capture_session.freezed.dart';
part 'capture_session.g.dart';

enum CaptureStatus {
  idle,
  requestingPermission,
  capturing,
  paused,
  stopping,
  analyzing,
  completed,
  failed,
}

@freezed
abstract class CaptureSession with _$CaptureSession {
  const factory CaptureSession({
    required String id,
    String? targetPackage,
    String? targetLabel,
    @Default(CaptureStatus.idle) CaptureStatus status,
    @Default([]) List<String> screenshotPaths,
    @Default(0) int skippedDuplicates,
    /// Seconds left before hard auto-stop; null until session starts.
    int? remainingSec,
    /// True after native time_warning (near limit).
    @Default(false) bool timeLimitWarning,
    /// True while UI Clone itself is in the foreground (frames skipped).
    @Default(false) bool ownAppInForeground,
    /// Usage access granted (needed to filter by target package).
    @Default(true) bool usageAccessGranted,
    /// True while another app (not the selected target) is in foreground.
    @Default(false) bool targetMismatch,
    /// Label of the app currently in foreground (UsageStats hint).
    String? currentForegroundLabel,
    /// Human-readable clone prompt (markdown).
    String? prompt,
    /// Pretty-printed structured JSON (palette / screens / components).
    String? structuredJson,
    /// 0..1 while [status] is analyzing; null otherwise.
    double? analysisProgress,
    /// preparing | uploading | waiting
    String? analysisPhase,
    @Default(0) int analysisImagesDone,
    @Default(0) int analysisImagesTotal,
    /// Rough ETA in seconds while analyzing.
    int? analysisEtaSec,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) = _CaptureSession;

  factory CaptureSession.fromJson(Map<String, dynamic> json) =>
      _$CaptureSessionFromJson(json);
}
