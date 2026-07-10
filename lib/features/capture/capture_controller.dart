import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/analysis_progress.dart';
import '../../data/models/capture_session.dart';
import '../../data/models/installed_app.dart';
import '../../data/repositories/capture_repository.dart';
import '../../data/services/ai_analysis_service.dart';
import '../../data/services/capture_platform_service.dart';
import '../../data/services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final capturePlatformProvider = Provider<CapturePlatformService>((ref) {
  final service = CapturePlatformService();
  ref.onDispose(service.dispose);
  return service;
});

final aiAnalysisProvider = Provider<AiAnalysisService>((ref) {
  return AiAnalysisService(settings: ref.watch(settingsServiceProvider));
});

final captureRepositoryProvider = Provider<CaptureRepository>((ref) {
  final repo = CaptureRepository(
    platform: ref.watch(capturePlatformProvider),
    analysis: ref.watch(aiAnalysisProvider),
    settings: ref.watch(settingsServiceProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final captureControllerProvider =
    StateNotifierProvider<CaptureController, CaptureSession>((ref) {
  return CaptureController(ref.watch(captureRepositoryProvider));
});

class CaptureController extends StateNotifier<CaptureSession> {
  CaptureController(this._repo)
      : super(
          const CaptureSession(
            id: '',
            status: CaptureStatus.idle,
          ),
        ) {
    _init();
  }

  final CaptureRepository _repo;
  StreamSubscription<CaptureEvent>? _sub;
  bool _disposed = false;

  /// Bumped on every start/stop. Native events from an older generation
  /// are ignored so they cannot flip status back to [CaptureStatus.capturing].
  int _generation = 0;
  int _activeGeneration = 0;

  /// Locked at [start] so analyze still has app name if state flickers.
  String? _sessionTargetPackage;
  String? _sessionTargetLabel;

  /// Inferred from frames when capture started without an explicit target.
  String? _inferredPackage;
  String? _inferredLabel;

  CancelToken? _analyzeCancel;
  Timer? _etaTicker;

  static String? _nonEmpty(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  Future<void> _init() async {
    await _repo.initialize();
    if (_disposed) return;
    _sub = _repo.events.listen(_onEvent);
  }

  bool get _captureClosed =>
      state.status == CaptureStatus.stopping ||
      state.status == CaptureStatus.analyzing ||
      state.status == CaptureStatus.completed ||
      state.status == CaptureStatus.failed;

  void _onEvent(CaptureEvent event) {
    if (_disposed) return;
    switch (event) {
      case CaptureStarted(
          :final sessionId,
          :final targetLabel,
          :final targetPackage,
          :final remainingSec,
          :final usageAccessGranted,
        ):
        if (_captureClosed || _activeGeneration != _generation) return;
        if (state.status != CaptureStatus.requestingPermission &&
            state.status != CaptureStatus.capturing) {
          return;
        }
        final pkg = _nonEmpty(targetPackage) ?? _sessionTargetPackage;
        final label = _nonEmpty(targetLabel) ?? _sessionTargetLabel;
        if (pkg != null) _sessionTargetPackage = pkg;
        if (label != null) _sessionTargetLabel = label;
        state = state.copyWith(
          id: sessionId.isNotEmpty ? sessionId : state.id,
          targetPackage: pkg ?? state.targetPackage,
          targetLabel: label ?? state.targetLabel,
          status: CaptureStatus.capturing,
          remainingSec: remainingSec ?? state.remainingSec,
          timeLimitWarning: false,
          ownAppInForeground: false,
          usageAccessGranted: usageAccessGranted ?? state.usageAccessGranted,
          targetMismatch: false,
          currentForegroundLabel: null,
        );
      case CaptureScreenshotTaken(
          :final path,
          :final count,
          :final skipped,
          :final foregroundPackage,
          :final foregroundLabel,
        ):
        if (_activeGeneration != _generation) return;
        _rememberForeground(foregroundPackage, foregroundLabel);
        if (_captureClosed) {
          // Still accept late paths while finishing, never reopen capture.
          if (path.isNotEmpty && !state.screenshotPaths.contains(path)) {
            state = state.copyWith(
              screenshotPaths: [...state.screenshotPaths, path],
              skippedDuplicates: skipped,
              targetPackage: state.targetPackage ?? _resolvedPackage(),
              targetLabel: state.targetLabel ?? _resolvedLabel(),
            );
          }
          return;
        }
        if (state.status != CaptureStatus.capturing &&
            state.status != CaptureStatus.paused) {
          return;
        }
        final paths = [...state.screenshotPaths];
        if (path.isNotEmpty && !paths.contains(path)) {
          paths.add(path);
        }
        state = state.copyWith(
          screenshotPaths: paths,
          skippedDuplicates: skipped,
          targetMismatch: false,
          currentForegroundLabel: null,
          targetPackage: state.targetPackage ?? _resolvedPackage(),
          targetLabel: state.targetLabel ?? _resolvedLabel(),
        );
        log('Screenshot #$count → $path (skipped=$skipped)');
      case CaptureFrameSkipped(:final skipped):
        if (_activeGeneration != _generation) return;
        if (_captureClosed) return;
        if (state.status != CaptureStatus.capturing &&
            state.status != CaptureStatus.paused) {
          return;
        }
        state = state.copyWith(skippedDuplicates: skipped);
      case CapturePaused(:final skipped):
        if (_activeGeneration != _generation) return;
        if (_captureClosed) return;
        if (state.status != CaptureStatus.capturing &&
            state.status != CaptureStatus.paused) {
          return;
        }
        state = state.copyWith(
          status: CaptureStatus.paused,
          skippedDuplicates: skipped,
        );
      case CaptureResumed(:final skipped):
        if (_activeGeneration != _generation) return;
        if (_captureClosed) return;
        if (state.status != CaptureStatus.paused &&
            state.status != CaptureStatus.capturing) {
          return;
        }
        state = state.copyWith(
          status: CaptureStatus.capturing,
          skippedDuplicates: skipped,
        );
      case CaptureTimeTick(:final remainingSec):
        if (_activeGeneration != _generation) return;
        if (_captureClosed) return;
        if (state.status != CaptureStatus.capturing &&
            state.status != CaptureStatus.paused) {
          return;
        }
        state = state.copyWith(remainingSec: remainingSec);
      case CaptureTimeWarning(:final remainingSec):
        if (_activeGeneration != _generation) return;
        if (_captureClosed) return;
        state = state.copyWith(
          remainingSec: remainingSec,
          timeLimitWarning: true,
        );
      case CaptureTimeLimit():
        // Native will also emit stopped; mark warning so UI shows reason.
        if (_activeGeneration != _generation) return;
        state = state.copyWith(
          remainingSec: 0,
          timeLimitWarning: true,
        );
      case CaptureOwnAppForeground(:final active):
        if (_activeGeneration != _generation) return;
        if (_captureClosed) return;
        state = state.copyWith(ownAppInForeground: active);
      case CaptureOwnAppSkipped():
        if (_activeGeneration != _generation) return;
        if (_captureClosed) return;
        state = state.copyWith(ownAppInForeground: true);
      case CaptureTargetMismatch(:final currentLabel, :final trackingReady):
        if (_activeGeneration != _generation) return;
        if (_captureClosed) return;
        state = state.copyWith(
          targetMismatch: true,
          currentForegroundLabel: currentLabel,
          ownAppInForeground: false,
          usageAccessGranted: trackingReady ?? state.usageAccessGranted,
        );
      case CaptureTargetMatch():
        if (_activeGeneration != _generation) return;
        if (_captureClosed) return;
        state = state.copyWith(
          targetMismatch: false,
          currentForegroundLabel: null,
        );
      case CaptureStopped(
          :final paths,
          :final targetPackage,
          :final targetLabel,
          :final foregroundPackage,
          :final foregroundLabel,
        ):
        if (_activeGeneration != _generation) return;
        if (_captureClosed) return;
        _rememberForeground(foregroundPackage, foregroundLabel);
        final pkg = _nonEmpty(targetPackage);
        final label = _nonEmpty(targetLabel);
        if (pkg != null) _sessionTargetPackage ??= pkg;
        if (label != null) _sessionTargetLabel ??= label;
        if (state.targetPackage == null || state.targetLabel == null) {
          state = state.copyWith(
            targetPackage: state.targetPackage ?? _resolvedPackage(),
            targetLabel: state.targetLabel ?? _resolvedLabel(),
          );
        }
        // External stop (notification / overlay / time limit).
        _generation++;
        _activeGeneration = _generation;
        unawaited(_finishWithPaths(paths, generation: _generation));
      case CaptureError(:final message):
        if (_activeGeneration != _generation) return;
        if (_captureClosed && state.status != CaptureStatus.stopping) {
          return;
        }
        _generation++;
        _activeGeneration = _generation;
        state = state.copyWith(
          status: CaptureStatus.failed,
          errorMessage: message,
        );
    }
  }

  Future<void> start({InstalledApp? target}) async {
    _generation++;
    final generation = _generation;
    _activeGeneration = generation;

    _sessionTargetPackage = _nonEmpty(target?.packageName);
    _sessionTargetLabel = _nonEmpty(target?.label);
    _inferredPackage = null;
    _inferredLabel = null;

    state = CaptureSession(
      id: '',
      status: CaptureStatus.requestingPermission,
      targetPackage: _sessionTargetPackage,
      targetLabel: _sessionTargetLabel,
      startedAt: DateTime.now(),
      skippedDuplicates: 0,
      remainingSec: null,
      timeLimitWarning: false,
      ownAppInForeground: false,
      usageAccessGranted: true,
      targetMismatch: false,
    );

    try {
      final session = await _repo.startSession(target: target);
      // User may have stopped (or a new start begun) while the system
      // MediaProjection dialog was open.
      if (generation != _generation) return;
      if (state.status != CaptureStatus.requestingPermission &&
          state.status != CaptureStatus.capturing) {
        return;
      }
      state = session.copyWith(
        targetPackage: _sessionTargetPackage ?? session.targetPackage,
        targetLabel: _sessionTargetLabel ?? session.targetLabel,
      );
    } catch (e, st) {
      log('startCapture failed', error: e, stackTrace: st);
      if (generation != _generation) return;
      state = state.copyWith(
        status: CaptureStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> stopAndAnalyze() async {
    if (_captureClosed) return;
    if (state.status != CaptureStatus.capturing &&
        state.status != CaptureStatus.paused &&
        state.status != CaptureStatus.requestingPermission) {
      return;
    }

    // Invalidate live capture generation so late native events cannot
    // restore [CaptureStatus.capturing].
    _generation++;
    final generation = _generation;
    _activeGeneration = generation;

    state = state.copyWith(status: CaptureStatus.stopping);
    await Future<void>.delayed(Duration.zero);

    try {
      final paths = await _repo.stopCapture();
      if (generation != _generation) return;
      await _finishWithPaths(paths, generation: generation);
    } catch (e, st) {
      log('stopCapture failed', error: e, stackTrace: st);
      if (generation != _generation) return;
      state = state.copyWith(
        status: CaptureStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> togglePause() async {
    if (_captureClosed) return;
    if (state.status != CaptureStatus.capturing &&
        state.status != CaptureStatus.paused) {
      return;
    }
    try {
      await _repo.togglePauseCapture();
    } catch (e, st) {
      log('togglePause failed', error: e, stackTrace: st);
    }
  }

  Future<void> requestUsageAccess() async {
    try {
      await _repo.requestUsageAccess();
    } catch (e, st) {
      log('requestUsageAccess failed', error: e, stackTrace: st);
    }
  }

  Future<void> requestAccessibilityAccess() async {
    try {
      await _repo.requestAccessibilityAccess();
    } catch (e, st) {
      log('requestAccessibilityAccess failed', error: e, stackTrace: st);
    }
  }

  Future<void> _finishWithPaths(
    List<String> paths, {
    required int generation,
  }) async {
    if (generation != _generation) return;

    // Close capture UI immediately — before any await — so the Stop
    // button cannot come back from a status flicker.
    final merged = <String>{
      ...state.screenshotPaths,
      ...paths,
    }.toList(growable: false);

    state = state.copyWith(
      screenshotPaths: merged,
      status: CaptureStatus.stopping,
      targetPackage: state.targetPackage ?? _resolvedPackage(),
      targetLabel: state.targetLabel ?? _resolvedLabel(),
    );
    await Future<void>.delayed(Duration.zero);
    if (generation != _generation) return;

    if (merged.isEmpty) {
      state = state.copyWith(
        status: CaptureStatus.failed,
        errorMessage:
            'Скриншоты не собраны. Проверьте разрешение записи экрана.',
        finishedAt: DateTime.now(),
      );
      return;
    }

    state = state.copyWith(
      status: CaptureStatus.analyzing,
      analysisProgress: 0.02,
      analysisPhase: AnalysisPhase.preparing.name,
      analysisImagesDone: 0,
      analysisImagesTotal: 0,
      analysisEtaSec: null,
    );
    _startEtaTicker();
    await Future<void>.delayed(Duration.zero);
    if (generation != _generation) return;

    final label = _resolvedLabel();
    final package = _resolvedPackage();
    final cancel = CancelToken();
    _analyzeCancel = cancel;

    try {
      final result = await _repo.analyze(
        paths: merged,
        targetLabel: label,
        targetPackage: package,
        cancelToken: cancel,
        onProgress: (progress) {
          if (generation != _generation || _disposed) return;
          if (state.status != CaptureStatus.analyzing) return;
          state = state.copyWith(
            analysisProgress: progress.fraction,
            analysisPhase: progress.phase.name,
            analysisImagesDone: progress.imagesDone,
            analysisImagesTotal: progress.imagesTotal,
            analysisEtaSec: progress.etaSec,
          );
        },
      );
      if (generation != _generation || _disposed) return;
      _stopEtaTicker();
      state = state.copyWith(
        prompt: result.markdown,
        structuredJson: result.structuredJson,
        status: CaptureStatus.completed,
        finishedAt: DateTime.now(),
        targetLabel: label ?? state.targetLabel,
        targetPackage: package ?? state.targetPackage,
        analysisProgress: 1,
        analysisEtaSec: 0,
      );
    } on AnalysisCancelledException {
      if (generation != _generation || _disposed) return;
      _stopEtaTicker();
      state = state.copyWith(
        status: CaptureStatus.failed,
        errorMessage: 'Анализ отменён',
        finishedAt: DateTime.now(),
        analysisProgress: null,
        analysisPhase: null,
        analysisEtaSec: null,
      );
    } catch (e, st) {
      log('analyze failed', error: e, stackTrace: st);
      if (generation != _generation || _disposed) return;
      _stopEtaTicker();
      state = state.copyWith(
        status: CaptureStatus.failed,
        errorMessage: e.toString(),
        finishedAt: DateTime.now(),
        analysisProgress: null,
        analysisPhase: null,
        analysisEtaSec: null,
      );
    } finally {
      _stopEtaTicker();
      if (identical(_analyzeCancel, cancel)) {
        _analyzeCancel = null;
      }
    }
  }

  void cancelAnalysis() {
    final token = _analyzeCancel;
    if (token == null || token.isCancelled) return;
    token.cancel('user');
  }

  void _startEtaTicker() {
    _etaTicker?.cancel();
    _etaTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || state.status != CaptureStatus.analyzing) return;
      final eta = state.analysisEtaSec;
      if (eta == null || eta <= 0) return;
      state = state.copyWith(analysisEtaSec: eta - 1);
    });
  }

  void _stopEtaTicker() {
    _etaTicker?.cancel();
    _etaTicker = null;
  }

  void _rememberForeground(String? package, String? label) {
    final pkg = _nonEmpty(package);
    final name = _nonEmpty(label);
    if (pkg != null) _inferredPackage = pkg;
    if (name != null) _inferredLabel = name;
  }

  String? _resolvedPackage() =>
      _nonEmpty(_sessionTargetPackage) ??
      _nonEmpty(state.targetPackage) ??
      _nonEmpty(_inferredPackage);

  String? _resolvedLabel() =>
      _nonEmpty(_sessionTargetLabel) ??
      _nonEmpty(state.targetLabel) ??
      _nonEmpty(_inferredLabel) ??
      _resolvedPackage();

  void reset() {
    _stopEtaTicker();
    _analyzeCancel?.cancel('reset');
    _analyzeCancel = null;
    _generation++;
    _activeGeneration = _generation;
    _sessionTargetPackage = null;
    _sessionTargetLabel = null;
    _inferredPackage = null;
    _inferredLabel = null;
    state = const CaptureSession(id: '', status: CaptureStatus.idle);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _stopEtaTicker();
    _analyzeCancel?.cancel('dispose');
    _analyzeCancel = null;
    _generation++;
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
