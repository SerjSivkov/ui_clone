import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';
import '../ai_providers.dart';
import '../models/analysis_progress.dart';
import '../models/ui_clone_analysis.dart';
import '../prompt_templates.dart';
import 'analysis_response_parser.dart';
import 'jpeg_compress.dart';
import 'settings_service.dart';

typedef AnalysisProgressCallback = void Function(AnalysisProgress progress);

class AiAnalysisService {
  AiAnalysisService({
    required this.settings,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final SettingsService settings;
  final Dio _dio;

  Future<AnalysisResult> analyzeScreenshots({
    required List<String> imagePaths,
    String? targetLabel,
    String? targetPackage,
    CancelToken? cancelToken,
    AnalysisProgressCallback? onProgress,
  }) async {
    final startedAt = DateTime.now();
    void emit(AnalysisProgress progress) => onProgress?.call(progress);

    final apiKey = await settings.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      emit(
        AnalysisProgress(
          phase: AnalysisPhase.waiting,
          imagesDone: 0,
          imagesTotal: imagePaths.length.clamp(0, AppConstants.maxImagesForAnalysis),
          fraction: 1,
          etaSec: 0,
        ),
      );
      return AnalysisResponseParser.fromMarkdownOnly(
        _buildOfflinePrompt(
          imagePaths: imagePaths,
          targetLabel: targetLabel,
          targetPackage: targetPackage,
          reason: 'API-ключ не задан. Ниже — шаблон промпта по собранным '
              'скриншотам; укажите ключ в настройках для vision-анализа.',
        ),
      );
    }

    final selected = _pickRepresentative(imagePaths);
    if (selected.isEmpty) {
      throw StateError('Нет скриншотов для анализа');
    }

    final total = selected.length;
    emit(
      AnalysisProgress(
        phase: AnalysisPhase.preparing,
        imagesDone: 0,
        imagesTotal: total,
        fraction: 0.02,
        etaSec: total * 2,
      ),
    );

    final providerId = AiProviders.parseId(await settings.getAiProviderId());
    final baseUrl = (await settings.getBaseUrl()).replaceAll(RegExp(r'/$'), '');
    final model = await settings.getModel();
    final promptBody = await settings.getSystemPrompt();
    final appName = _resolveAppName(targetLabel, targetPackage);
    final instruction = PromptTemplates.apply(
      body: promptBody,
      app: appName,
      package: _nonEmpty(targetPackage),
      count: selected.length,
    );
    final textPrompt =
        '$instruction${AnalysisResponseParser.responseFormatInstruction}';

    _throwIfCancelled(cancelToken);

    final jpegQuality = await settings.getJpegQuality();
    final jpegMaxSide = await settings.getJpegMaxSide();
    final imagesB64 = <String>[];
    for (var i = 0; i < selected.length; i++) {
      _throwIfCancelled(cancelToken);
      final path = selected[i];
      final bytes = await File(path).readAsBytes();
      final compressed = await compute(
        compressJpegBytes,
        JpegCompressArgs(
          bytes: bytes,
          quality: jpegQuality,
          maxSide: jpegMaxSide,
        ),
      );
      imagesB64.add(base64Encode(compressed));

      final done = i + 1;
      final elapsedMs =
          DateTime.now().difference(startedAt).inMilliseconds.clamp(1, 1 << 30);
      final perImageMs = elapsedMs / done;
      final remainPrepare = ((total - done) * perImageMs / 1000).ceil();
      // Prepare is ~0..0.35 of overall progress.
      final fraction = 0.05 + 0.30 * (done / total);
      emit(
        AnalysisProgress(
          phase: AnalysisPhase.preparing,
          imagesDone: done,
          imagesTotal: total,
          fraction: fraction,
          etaSec: remainPrepare + _estimateUploadWaitSec(total),
        ),
      );
    }

    _throwIfCancelled(cancelToken);

    final uploadEta = _estimateUploadWaitSec(total);
    emit(
      AnalysisProgress(
        phase: AnalysisPhase.uploading,
        imagesDone: total,
        imagesTotal: total,
        fraction: 0.38,
        etaSec: uploadEta,
      ),
    );

    final waitStartedAt = DateTime.now();
    try {
      final text = switch (providerId) {
        AiProviderId.anthropic => await _callAnthropic(
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            textPrompt: textPrompt,
            imagesB64: imagesB64,
            cancelToken: cancelToken,
            onSendProgress: (sent, totalBytes) {
              _emitUploadProgress(
                emit: emit,
                imagesTotal: total,
                sent: sent,
                totalBytes: totalBytes,
                waitStartedAt: waitStartedAt,
              );
            },
          ),
        AiProviderId.gemini => await _callGemini(
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            textPrompt: textPrompt,
            imagesB64: imagesB64,
            cancelToken: cancelToken,
            onSendProgress: (sent, totalBytes) {
              _emitUploadProgress(
                emit: emit,
                imagesTotal: total,
                sent: sent,
                totalBytes: totalBytes,
                waitStartedAt: waitStartedAt,
              );
            },
          ),
        AiProviderId.openai || AiProviderId.openaiCompatible =>
          await _callOpenAiCompatible(
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: model,
            textPrompt: textPrompt,
            imagesB64: imagesB64,
            cancelToken: cancelToken,
            onSendProgress: (sent, totalBytes) {
              _emitUploadProgress(
                emit: emit,
                imagesTotal: total,
                sent: sent,
                totalBytes: totalBytes,
                waitStartedAt: waitStartedAt,
              );
            },
          ),
      };
      if (text.trim().isEmpty) {
        throw StateError('Пустой ответ модели');
      }
      emit(
        AnalysisProgress(
          phase: AnalysisPhase.waiting,
          imagesDone: total,
          imagesTotal: total,
          fraction: 1,
          etaSec: 0,
        ),
      );
      return AnalysisResponseParser.parse(text);
    } on DioException catch (e, st) {
      if (CancelToken.isCancel(e) || cancelToken?.isCancelled == true) {
        throw const AnalysisCancelledException();
      }
      log('AI analysis failed: ${e.message}', stackTrace: st);
      return AnalysisResponseParser.fromMarkdownOnly(
        _buildOfflinePrompt(
          imagePaths: imagePaths,
          targetLabel: targetLabel,
          targetPackage: targetPackage,
          reason: 'Vision API недоступен (${e.message}). '
              'Используйте шаблон ниже и приложите скриншоты вручную.',
        ),
      );
    }
  }

  void _emitUploadProgress({
    required AnalysisProgressCallback emit,
    required int imagesTotal,
    required int sent,
    required int totalBytes,
    required DateTime waitStartedAt,
  }) {
    if (totalBytes <= 0) {
      emit(
        AnalysisProgress(
          phase: AnalysisPhase.uploading,
          imagesDone: imagesTotal,
          imagesTotal: imagesTotal,
          fraction: 0.45,
          etaSec: _estimateUploadWaitSec(imagesTotal),
        ),
      );
      return;
    }
    final ratio = (sent / totalBytes).clamp(0.0, 1.0);
    final elapsed =
        DateTime.now().difference(waitStartedAt).inMilliseconds.clamp(1, 1 << 30);
    final remainUpload = ratio >= 0.99
        ? 0
        : (((1 - ratio) * elapsed / ratio) / 1000).ceil();
    if (ratio >= 0.98) {
      emit(
        AnalysisProgress(
          phase: AnalysisPhase.waiting,
          imagesDone: imagesTotal,
          imagesTotal: imagesTotal,
          fraction: 0.72,
          etaSec: _estimateModelWaitSec(imagesTotal),
        ),
      );
      return;
    }
    emit(
      AnalysisProgress(
        phase: AnalysisPhase.uploading,
        imagesDone: imagesTotal,
        imagesTotal: imagesTotal,
        fraction: 0.38 + 0.32 * ratio,
        etaSec: remainUpload + _estimateModelWaitSec(imagesTotal),
      ),
    );
  }

  static int _estimateUploadWaitSec(int imageCount) =>
      8 + imageCount * 3;

  static int _estimateModelWaitSec(int imageCount) =>
      20 + imageCount * 5;

  static void _throwIfCancelled(CancelToken? token) {
    if (token == null) return;
    if (token.isCancelled) {
      throw const AnalysisCancelledException();
    }
  }

  Future<String> _callOpenAiCompatible({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String textPrompt,
    required List<String> imagesB64,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final content = <Map<String, dynamic>>[
      {'type': 'text', 'text': textPrompt},
      for (final b64 in imagesB64)
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,$b64',
            'detail': 'low',
          },
        },
    ];

    final response = await _dio.post<Map<String, dynamic>>(
      '$baseUrl/chat/completions',
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 2),
      ),
      data: {
        'model': model,
        'temperature': 0.35,
        'messages': [
          {'role': 'user', 'content': content},
        ],
      },
    );

    final choices = response.data?['choices'] as List<dynamic>?;
    final message = choices?.firstOrNull as Map<String, dynamic>?;
    return (message?['message'] as Map<String, dynamic>?)?['content']
            as String? ??
        '';
  }

  Future<String> _callAnthropic({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String textPrompt,
    required List<String> imagesB64,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final content = <Map<String, dynamic>>[
      {'type': 'text', 'text': textPrompt},
      for (final b64 in imagesB64)
        {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': 'image/jpeg',
            'data': b64,
          },
        },
    ];

    final root = baseUrl.contains('/v1') ? baseUrl : '$baseUrl/v1';
    final response = await _dio.post<Map<String, dynamic>>(
      '$root/messages',
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      options: Options(
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 2),
      ),
      data: {
        'model': model,
        'max_tokens': 8192,
        'temperature': 0.35,
        'messages': [
          {'role': 'user', 'content': content},
        ],
      },
    );

    final blocks = response.data?['content'] as List<dynamic>?;
    if (blocks == null || blocks.isEmpty) return '';
    final texts = <String>[];
    for (final block in blocks) {
      if (block is Map<String, dynamic> && block['type'] == 'text') {
        final t = block['text'] as String?;
        if (t != null && t.isNotEmpty) texts.add(t);
      }
    }
    return texts.join('\n');
  }

  Future<String> _callGemini({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String textPrompt,
    required List<String> imagesB64,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final parts = <Map<String, dynamic>>[
      {'text': textPrompt},
      for (final b64 in imagesB64)
        {
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': b64,
          },
        },
    ];

    final url =
        '$baseUrl/models/$model:generateContent?key=${Uri.encodeQueryComponent(apiKey)}';
    final response = await _dio.post<Map<String, dynamic>>(
      url,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 2),
      ),
      data: {
        'contents': [
          {'role': 'user', 'parts': parts},
        ],
        'generationConfig': {
          'temperature': 0.35,
        },
      },
    );

    final candidates = response.data?['candidates'] as List<dynamic>?;
    final first = candidates?.firstOrNull as Map<String, dynamic>?;
    final content = first?['content'] as Map<String, dynamic>?;
    final outParts = content?['parts'] as List<dynamic>?;
    if (outParts == null || outParts.isEmpty) return '';
    final texts = <String>[];
    for (final part in outParts) {
      if (part is Map<String, dynamic>) {
        final t = part['text'] as String?;
        if (t != null && t.isNotEmpty) texts.add(t);
      }
    }
    return texts.join('\n');
  }

  List<String> _pickRepresentative(List<String> paths) {
    if (paths.length <= AppConstants.maxImagesForAnalysis) {
      return List<String>.from(paths);
    }
    final step = paths.length / AppConstants.maxImagesForAnalysis;
    final picked = <String>[];
    for (var i = 0; i < AppConstants.maxImagesForAnalysis; i++) {
      picked.add(paths[(i * step).floor()]);
    }
    return picked;
  }

  static String? _nonEmpty(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  static String _resolveAppName(String? targetLabel, String? targetPackage) {
    return _nonEmpty(targetLabel) ??
        _nonEmpty(targetPackage) ??
        'целевое приложение';
  }

  String _buildOfflinePrompt({
    required List<String> imagePaths,
    required String? targetLabel,
    required String? targetPackage,
    required String reason,
  }) {
    final names = imagePaths
        .map(p.basename)
        .take(AppConstants.maxImagesForAnalysis)
        .join(', ');
    final appName = _resolveAppName(targetLabel, targetPackage);
    final package = _nonEmpty(targetPackage);
    return '''
# Промпт для клонирования UI

> $reason

Склонируй мобильный интерфейс приложения
**$appName**
${package != null ? '(`$package`)' : ''}.

Собрано скриншотов: **${imagePaths.length}**.
Файлы (выборка): $names

## Задача
По скриншотам восстанови UI на Flutter:
- стиль (цвета, шрифты, отступы, радиусы, elevation);
- расположение кнопок, полей, списков и навигации;
- иерархию экранов и предполагаемые функции;
- адаптацию под телефон (touch targets ≥ 44pt).

## Ограничения
- Не копируй чужие логотипы, товарные знаки и пользовательский контент.
- Воспроизводи структуру и UX-паттерны, а не пиратскую копию бренда.
- Используй Material 3 + кастомную тему, чистые виджеты без лишних карточек
  в hero-зонах.

## Выход
1. Краткое описание визуального языка.
2. Список экранов и wireframe-описание layout.
3. Спека компонентов (кнопки, инпуты, списки).
4. Готовый план файлов `lib/features/...` для реализации.
''';
  }
}
