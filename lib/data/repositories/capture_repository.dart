import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../models/capture_session.dart';
import '../models/installed_app.dart';
import '../services/ai_analysis_service.dart';
import '../services/capture_platform_service.dart';
import '../services/settings_service.dart';

class CaptureRepository {
  CaptureRepository({
    required this.platform,
    required this.analysis,
    required this.settings,
  });

  final CapturePlatformService platform;
  final AiAnalysisService analysis;
  final SettingsService settings;
  final _uuid = const Uuid();

  StreamSubscription<CaptureEvent>? _eventsSub;

  Future<void> initialize() => platform.initialize();

  Stream<CaptureEvent> get events => platform.events;

  Future<bool> isSupported() => platform.isSupported();

  Future<List<InstalledApp>> listInstalledApps() =>
      platform.listInstalledApps();

  Future<bool> hasOverlayPermission() => platform.hasOverlayPermission();

  Future<void> requestOverlayPermission() =>
      platform.requestOverlayPermission();

  Future<CaptureSession> startSession({
    InstalledApp? target,
  }) async {
    final interval = await settings.getCaptureIntervalMs();
    final session = CaptureSession(
      id: _uuid.v4(),
      targetPackage: target?.packageName,
      targetLabel: target?.label,
      status: CaptureStatus.requestingPermission,
      startedAt: DateTime.now(),
    );

    await platform.startCapture(
      sessionId: session.id,
      targetPackage: target?.packageName,
      targetLabel: target?.label,
      intervalMs: interval,
    );

    if (target != null) {
      // Give MediaProjection a moment, then jump to the target app.
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 700), () {
          return platform.openApp(target.packageName);
        }),
      );
    }

    return session.copyWith(status: CaptureStatus.capturing);
  }

  Future<List<String>> stopCapture() => platform.stopCapture();

  Future<String> analyze({
    required List<String> paths,
    String? targetLabel,
    String? targetPackage,
  }) {
    final limited = paths.length > AppConstants.maxScreenshotsPerSession
        ? paths.sublist(0, AppConstants.maxScreenshotsPerSession)
        : paths;
    return analysis.analyzeScreenshots(
      imagePaths: limited,
      targetLabel: targetLabel,
      targetPackage: targetPackage,
    );
  }

  Future<void> dispose() async {
    await _eventsSub?.cancel();
  }
}
