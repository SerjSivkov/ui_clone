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

  Future<void> startCapture({
    required String sessionId,
    String? targetPackage,
    String? targetLabel,
    int intervalMs = AppConstants.defaultCaptureIntervalMs,
    double similarityPercent = AppConstants.defaultSimilarityPercent,
    String captureMode = AppConstants.defaultCaptureMode,
  }) async {
    await _method.invokeMethod<void>('startCapture', {
      'sessionId': sessionId,
      'targetPackage': targetPackage,
      'targetLabel': targetLabel,
      'intervalMs': intervalMs,
      'similarityPercent': similarityPercent,
      'captureMode': captureMode,
    });
  }

  Future<List<String>> stopCapture() async {
    final raw = await _method.invokeMethod<List<dynamic>>('stopCapture');
    if (raw == null) return const [];
    return raw.whereType<String>().toList(growable: false);
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
  }) = CaptureStarted;

  factory CaptureEvent.screenshot({
    required String path,
    required int count,
    required int skipped,
  }) = CaptureScreenshotTaken;

  factory CaptureEvent.skipped({
    required int skipped,
    required int count,
  }) = CaptureFrameSkipped;

  factory CaptureEvent.stopped({
    required List<String> paths,
  }) = CaptureStopped;

  factory CaptureEvent.error(String message) = CaptureError;

  static CaptureEvent? fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    switch (type) {
      case 'started':
        return CaptureStarted(
          sessionId: map['sessionId'] as String? ?? '',
          targetLabel: map['targetLabel'] as String?,
        );
      case 'screenshot':
        return CaptureScreenshotTaken(
          path: map['path'] as String? ?? '',
          count: (map['count'] as num?)?.toInt() ?? 0,
          skipped: (map['skipped'] as num?)?.toInt() ?? 0,
        );
      case 'skipped':
        return CaptureFrameSkipped(
          skipped: (map['skipped'] as num?)?.toInt() ?? 0,
          count: (map['count'] as num?)?.toInt() ?? 0,
        );
      case 'stopped':
        final paths = (map['paths'] as List<dynamic>?)
                ?.whereType<String>()
                .toList(growable: false) ??
            const <String>[];
        return CaptureStopped(paths: paths);
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
  });

  final String sessionId;
  final String? targetLabel;
}

final class CaptureScreenshotTaken extends CaptureEvent {
  const CaptureScreenshotTaken({
    required this.path,
    required this.count,
    this.skipped = 0,
  });

  final String path;
  final int count;
  final int skipped;
}

final class CaptureFrameSkipped extends CaptureEvent {
  const CaptureFrameSkipped({
    required this.skipped,
    required this.count,
  });

  final int skipped;
  final int count;
}

final class CaptureStopped extends CaptureEvent {
  const CaptureStopped({required this.paths});

  final List<String> paths;
}

final class CaptureError extends CaptureEvent {
  const CaptureError(this.message);

  final String message;
}
