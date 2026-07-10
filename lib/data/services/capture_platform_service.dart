import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../models/installed_app.dart';

class CapturePlatformService {
  CapturePlatformService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _method = methodChannel ??
            const MethodChannel(AppConstants.captureChannel),
        _events = eventChannel ??
            const EventChannel(AppConstants.captureEventsChannel);

  final MethodChannel _method;
  final EventChannel _events;

  StreamSubscription<dynamic>? _subscription;
  final _controller = StreamController<CaptureEvent>.broadcast();

  Stream<CaptureEvent> get events => _controller.stream;

  Future<void> initialize() async {
    await _subscription?.cancel();
    _subscription = _events.receiveBroadcastStream().listen(
      (raw) {
        if (raw is! Map) return;
        final map = Map<String, dynamic>.from(raw);
        final event = CaptureEvent.fromMap(map);
        if (event != null) {
          _controller.add(event);
        }
      },
      onError: (Object error, StackTrace stack) {
        log('Capture events error: $error', stackTrace: stack);
        _controller.add(CaptureEvent.error(error.toString()));
      },
    );
  }

  Future<bool> isSupported() async {
    try {
      final result = await _method.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on PlatformException catch (e) {
      log('isSupported failed: ${e.message}');
      return false;
    }
  }

  Future<List<InstalledApp>> listInstalledApps() async {
    final raw = await _method.invokeMethod<List<dynamic>>('listInstalledApps');
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .map((e) => InstalledApp.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<bool> hasOverlayPermission() async {
    final result = await _method.invokeMethod<bool>('hasOverlayPermission');
    return result ?? false;
  }

  Future<void> requestOverlayPermission() async {
    await _method.invokeMethod<void>('requestOverlayPermission');
  }

  Future<bool> hasUsageAccess() async {
    final result = await _method.invokeMethod<bool>('hasUsageAccess');
    return result ?? false;
  }

  Future<void> requestUsageAccess() async {
    await _method.invokeMethod<void>('requestUsageAccess');
  }

  Future<bool> hasAccessibilityAccess() async {
    final result = await _method.invokeMethod<bool>('hasAccessibilityAccess');
    return result ?? false;
  }

  Future<void> requestAccessibilityAccess() async {
    await _method.invokeMethod<void>('requestAccessibilityAccess');
  }

  Future<void> startCapture({
    required String sessionId,
    String? targetPackage,
    String? targetLabel,
    int intervalMs = AppConstants.defaultCaptureIntervalMs,
    double similarityPercent = AppConstants.defaultSimilarityPercent,
    String captureMode = AppConstants.defaultCaptureMode,
    int maxDurationMs = AppConstants.defaultMaxSessionSec * 1000,
    int warnBeforeMs = AppConstants.defaultWarnBeforeSec * 1000,
  }) async {
    await _method.invokeMethod<void>('startCapture', {
      'sessionId': sessionId,
      'targetPackage': targetPackage,
      'targetLabel': targetLabel,
      'intervalMs': intervalMs,
      'similarityPercent': similarityPercent,
      'captureMode': captureMode,
      'maxDurationMs': maxDurationMs,
      'warnBeforeMs': warnBeforeMs,
    });
  }

  Future<List<String>> stopCapture() async {
    final raw = await _method.invokeMethod<List<dynamic>>('stopCapture');
    if (raw == null) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  Future<void> pauseCapture() async {
    await _method.invokeMethod<void>('pauseCapture');
  }

  Future<void> resumeCapture() async {
    await _method.invokeMethod<void>('resumeCapture');
  }

  Future<void> togglePauseCapture() async {
    await _method.invokeMethod<void>('togglePauseCapture');
  }

  Future<void> openApp(String packageName) async {
    await _method.invokeMethod<void>('openApp', {'packageName': packageName});
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}

sealed class CaptureEvent {
  const CaptureEvent();

  factory CaptureEvent.started({
    required String sessionId,
    required String? targetLabel,
    String? targetPackage,
    int? remainingSec,
    bool? usageAccessGranted,
  }) = CaptureStarted;

  factory CaptureEvent.screenshot({
    required String path,
    required int count,
    required int skipped,
    String? foregroundPackage,
    String? foregroundLabel,
  }) = CaptureScreenshotTaken;

  factory CaptureEvent.skipped({
    required int skipped,
    required int count,
  }) = CaptureFrameSkipped;

  factory CaptureEvent.paused({
    required int count,
    required int skipped,
  }) = CapturePaused;

  factory CaptureEvent.resumed({
    required int count,
    required int skipped,
  }) = CaptureResumed;

  factory CaptureEvent.timeTick({
    required int remainingSec,
  }) = CaptureTimeTick;

  factory CaptureEvent.timeWarning({
    required int remainingSec,
  }) = CaptureTimeWarning;

  factory CaptureEvent.timeLimit() = CaptureTimeLimit;

  factory CaptureEvent.ownAppForeground({
    required bool active,
    required int ownAppSkipped,
  }) = CaptureOwnAppForeground;

  factory CaptureEvent.ownAppSkipped({
    required int ownAppSkipped,
  }) = CaptureOwnAppSkipped;

  factory CaptureEvent.targetMismatch({
    required String? currentPackage,
    required String? currentLabel,
    bool? trackingReady,
  }) = CaptureTargetMismatch;

  factory CaptureEvent.targetMatch() = CaptureTargetMatch;

  factory CaptureEvent.stopped({
    required List<String> paths,
    required String reason,
    String? targetPackage,
    String? targetLabel,
    String? foregroundPackage,
    String? foregroundLabel,
  }) = CaptureStopped;

  factory CaptureEvent.error(String message) = CaptureError;

  static CaptureEvent? fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    switch (type) {
      case 'started':
        return CaptureStarted(
          sessionId: map['sessionId'] as String? ?? '',
          targetLabel: map['targetLabel'] as String?,
          targetPackage: map['targetPackage'] as String?,
          remainingSec: (map['remainingSec'] as num?)?.toInt(),
          usageAccessGranted: map['usageAccessGranted'] as bool?,
        );
      case 'screenshot':
        return CaptureScreenshotTaken(
          path: map['path'] as String? ?? '',
          count: (map['count'] as num?)?.toInt() ?? 0,
          skipped: (map['skipped'] as num?)?.toInt() ?? 0,
          foregroundPackage: map['foregroundPackage'] as String?,
          foregroundLabel: map['foregroundLabel'] as String?,
        );
      case 'skipped':
        return CaptureFrameSkipped(
          skipped: (map['skipped'] as num?)?.toInt() ?? 0,
          count: (map['count'] as num?)?.toInt() ?? 0,
        );
      case 'paused':
        return CapturePaused(
          count: (map['count'] as num?)?.toInt() ?? 0,
          skipped: (map['skipped'] as num?)?.toInt() ?? 0,
        );
      case 'resumed':
        return CaptureResumed(
          count: (map['count'] as num?)?.toInt() ?? 0,
          skipped: (map['skipped'] as num?)?.toInt() ?? 0,
        );
      case 'time_tick':
        return CaptureTimeTick(
          remainingSec: (map['remainingSec'] as num?)?.toInt() ?? 0,
        );
      case 'time_warning':
        return CaptureTimeWarning(
          remainingSec: (map['remainingSec'] as num?)?.toInt() ?? 0,
        );
      case 'time_limit':
        return CaptureTimeLimit();
      case 'own_app_foreground':
        return CaptureOwnAppForeground(
          active: map['active'] as bool? ?? false,
          ownAppSkipped: (map['ownAppSkipped'] as num?)?.toInt() ?? 0,
        );
      case 'own_app_skipped':
        return CaptureOwnAppSkipped(
          ownAppSkipped: (map['ownAppSkipped'] as num?)?.toInt() ?? 0,
        );
      case 'target_mismatch':
        return CaptureTargetMismatch(
          currentPackage: map['currentPackage'] as String?,
          currentLabel: map['currentLabel'] as String?,
          trackingReady: map['usageAccessGranted'] as bool?,
        );
      case 'target_match':
        return CaptureTargetMatch();
      case 'stopped':
        final paths = (map['paths'] as List<dynamic>?)
                ?.whereType<String>()
                .toList(growable: false) ??
            const <String>[];
        return CaptureStopped(
          paths: paths,
          reason: map['reason'] as String? ?? 'user',
          targetPackage: map['targetPackage'] as String?,
          targetLabel: map['targetLabel'] as String?,
          foregroundPackage: map['foregroundPackage'] as String?,
          foregroundLabel: map['foregroundLabel'] as String?,
        );
      case 'error':
        return CaptureError(map['message'] as String? ?? 'Unknown error');
      default:
        log('Unknown capture event: ${jsonEncode(map)}');
        return null;
    }
  }
}

final class CaptureStarted extends CaptureEvent {
  const CaptureStarted({
    required this.sessionId,
    required this.targetLabel,
    this.targetPackage,
    this.remainingSec,
    this.usageAccessGranted,
  });

  final String sessionId;
  final String? targetLabel;
  final String? targetPackage;
  final int? remainingSec;
  final bool? usageAccessGranted;
}

final class CaptureScreenshotTaken extends CaptureEvent {
  const CaptureScreenshotTaken({
    required this.path,
    required this.count,
    this.skipped = 0,
    this.foregroundPackage,
    this.foregroundLabel,
  });

  final String path;
  final int count;
  final int skipped;
  final String? foregroundPackage;
  final String? foregroundLabel;
}

final class CaptureFrameSkipped extends CaptureEvent {
  const CaptureFrameSkipped({
    required this.skipped,
    required this.count,
  });

  final int skipped;
  final int count;
}

final class CapturePaused extends CaptureEvent {
  const CapturePaused({
    required this.count,
    required this.skipped,
  });

  final int count;
  final int skipped;
}

final class CaptureResumed extends CaptureEvent {
  const CaptureResumed({
    required this.count,
    required this.skipped,
  });

  final int count;
  final int skipped;
}

final class CaptureTimeTick extends CaptureEvent {
  const CaptureTimeTick({required this.remainingSec});

  final int remainingSec;
}

final class CaptureTimeWarning extends CaptureEvent {
  const CaptureTimeWarning({required this.remainingSec});

  final int remainingSec;
}

final class CaptureTimeLimit extends CaptureEvent {
  const CaptureTimeLimit();
}

final class CaptureOwnAppForeground extends CaptureEvent {
  const CaptureOwnAppForeground({
    required this.active,
    required this.ownAppSkipped,
  });

  final bool active;
  final int ownAppSkipped;
}

final class CaptureOwnAppSkipped extends CaptureEvent {
  const CaptureOwnAppSkipped({required this.ownAppSkipped});

  final int ownAppSkipped;
}

final class CaptureTargetMismatch extends CaptureEvent {
  const CaptureTargetMismatch({
    required this.currentPackage,
    required this.currentLabel,
    this.trackingReady,
  });

  final String? currentPackage;
  final String? currentLabel;
  final bool? trackingReady;
}

final class CaptureTargetMatch extends CaptureEvent {
  const CaptureTargetMatch();
}

final class CaptureStopped extends CaptureEvent {
  const CaptureStopped({
    required this.paths,
    this.reason = 'user',
    this.targetPackage,
    this.targetLabel,
    this.foregroundPackage,
    this.foregroundLabel,
  });

  final List<String> paths;
  final String reason;
  final String? targetPackage;
  final String? targetLabel;
  final String? foregroundPackage;
  final String? foregroundLabel;
}

final class CaptureError extends CaptureEvent {
  const CaptureError(this.message);

  final String message;
}
