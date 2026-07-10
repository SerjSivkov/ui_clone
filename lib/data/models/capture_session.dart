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
    String? prompt,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) = _CaptureSession;

  factory CaptureSession.fromJson(Map<String, dynamic> json) =>
      _$CaptureSessionFromJson(json);
}
