import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          CaptureSession(
            id: '',
            status: CaptureStatus.idle,
          ),
        ) {
    _init();
  }

  final CaptureRepository _repo;
  StreamSubscription<CaptureEvent>? _sub;
  bool _disposed = false;

  Future<void> _init() async {
    await _repo.initialize();
    if (_disposed) return;
    _sub = _repo.events.listen(_onEvent);
  }

  void _onEvent(CaptureEvent event) {
    if (_disposed) return;
    switch (event) {
      case CaptureStarted(:final sessionId, :final targetLabel):
        state = state.copyWith(
          id: sessionId.isNotEmpty ? sessionId : state.id,
          targetLabel: targetLabel ?? state.targetLabel,
          status: CaptureStatus.capturing,
        );
      case CaptureScreenshotTaken(:final path, :final count):
        final paths = [...state.screenshotPaths];
        if (path.isNotEmpty && !paths.contains(path)) {
          paths.add(path);
        }
        state = state.copyWith(
          screenshotPaths: paths,
          status: CaptureStatus.capturing,
        );
        log('Screenshot #$count → $path');
      case CaptureStopped(:final paths):
        unawaited(_finishWithPaths(paths));
      case CaptureError(:final message):
        state = state.copyWith(
          status: CaptureStatus.failed,
          errorMessage: message,
        );
    }
  }

  Future<void> start({InstalledApp? target}) async {
    state = state.copyWith(
      status: CaptureStatus.requestingPermission,
      errorMessage: null,
      prompt: null,
      screenshotPaths: const [],
      finishedAt: null,
      targetPackage: target?.packageName,
      targetLabel: target?.label,
    );
    try {
      final session = await _repo.startSession(target: target);
      state = session;
    } catch (e, st) {
      log('startCapture failed', error: e, stackTrace: st);
      state = state.copyWith(
        status: CaptureStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> stopAndAnalyze() async {
    if (state.status != CaptureStatus.capturing &&
        state.status != CaptureStatus.requestingPermission) {
      return;
    }
    state = state.copyWith(status: CaptureStatus.stopping);
    try {
      final paths = await _repo.stopCapture();
      await _finishWithPaths(paths);
    } catch (e, st) {
      log('stopCapture failed', error: e, stackTrace: st);
      state = state.copyWith(
        status: CaptureStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _finishWithPaths(List<String> paths) async {
    final merged = <String>{
      ...state.screenshotPaths,
      ...paths,
    }.toList(growable: false);

    if (merged.isEmpty) {
      state = state.copyWith(
        status: CaptureStatus.failed,
        errorMessage: 'Скриншоты не собраны. Проверьте разрешение записи экрана.',
        finishedAt: DateTime.now(),
      );
      return;
    }

    state = state.copyWith(
      screenshotPaths: merged,
      status: CaptureStatus.analyzing,
    );

    try {
      final prompt = await _repo.analyze(
        paths: merged,
        targetLabel: state.targetLabel,
        targetPackage: state.targetPackage,
      );
      state = state.copyWith(
        prompt: prompt,
        status: CaptureStatus.completed,
        finishedAt: DateTime.now(),
      );
    } catch (e, st) {
      log('analyze failed', error: e, stackTrace: st);
      state = state.copyWith(
        status: CaptureStatus.failed,
        errorMessage: e.toString(),
        finishedAt: DateTime.now(),
      );
    }
  }

  void reset() {
    state = CaptureSession(id: '', status: CaptureStatus.idle);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_sub?.cancel());
    super.dispose();
  }
}
