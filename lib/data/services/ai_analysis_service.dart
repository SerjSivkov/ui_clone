import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';
import 'settings_service.dart';

class AiAnalysisService {
  AiAnalysisService({
    required this.settings,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final SettingsService settings;
  final Dio _dio;

  Future<String> analyzeScreenshots({
    required List<String> imagePaths,
    String? targetLabel,
    String? targetPackage,
  }) async {
    final apiKey = await settings.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return _buildOfflinePrompt(
        imagePaths: imagePaths,
        targetLabel: targetLabel,
        targetPackage: targetPackage,
        reason: 'API-ключ не задан. Ниже — шаблон промпта по собранным '
            'скриншотам; укажите ключ в настройках для vision-анализа.',
      );
    }

    final selected = _pickRepresentative(imagePaths);
    if (selected.isEmpty) {
      throw StateError('Нет скриншотов для анализа');
    }

    final baseUrl = await settings.getBaseUrl();
    final model = await settings.getModel();
    final content = <Map<String, dynamic>>[
      {
        'type': 'text',
        'text': _systemPrompt(
          targetLabel: targetLabel,
          targetPackage: targetPackage,
          count: selected.length,
        ),
      },
    ];

    for (final path in selected) {
      final bytes = await File(path).readAsBytes();
      final compressed = await compute(_compressJpegBytes, bytes);
      final b64 = base64Encode(compressed);
      content.add({
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/jpeg;base64,$b64',
          'detail': 'low',
        },
      });
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${baseUrl.replaceAll(RegExp(r'/$'), '')}/chat/completions',
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
            {
              'role': 'user',
              'content': content,
            },
          ],
        },
      );

      final choices = response.data?['choices'] as List<dynamic>?;
      final message = choices?.firstOrNull as Map<String, dynamic>?;
      final text = (message?['message'] as Map<String, dynamic>?)?['content']
          as String?;
      if (text == null || text.trim().isEmpty) {
        throw StateError('Пустой ответ модели');
      }
      return text.trim();
    } on DioException catch (e, st) {
      log('AI analysis failed: ${e.message}', stackTrace: st);
      return _buildOfflinePrompt(
        imagePaths: imagePaths,
        targetLabel: targetLabel,
        targetPackage: targetPackage,
        reason: 'Vision API недоступен (${e.message}). '
            'Используйте шаблон ниже и приложите скриншоты вручную.',
      );
    }
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

  String _systemPrompt({
    required String? targetLabel,
    required String? targetPackage,
    required int count,
  }) {
    final app = targetLabel ?? targetPackage ?? 'unknown app';
    return '''
Ты — senior product designer + Flutter UI engineer.
Проанализируй $count скриншотов приложения "$app"
${targetPackage != null ? '(package: $targetPackage)' : ''}.

Составь ОДИН готовый промпт на русском для генерации клона UI
(для Cursor / Claude / GPT / Flutter-агента). Промпт должен включать:

1. Общий стиль: цветовая палитра (HEX если видно), типографика, плотность,
   скругления, тени, светлая/тёмная тема, атмосфера.
2. Навигация: таббар / drawer / стек экранов, иерархия.
3. По каждому заметному экрану: layout (сверху вниз), ключевые блоки,
   расположение кнопок/полей (примерно: top/center/bottom, left/right),
   состояния (empty/loading/error если видно).
4. Компоненты: кнопки, карточки, списки, чипы, инпуты, иконки — размеры
   и поведение.
5. Функции, которые угадываются по UI (что делает экран).
6. Технические указания для Flutter: Material 3 / custom, структура
   виджетов, что НЕ копировать (брендинг/логотипы/контент пользователя).

Формат ответа — только итоговый промпт, без преамбулы.
Используй markdown-заголовки и маркированные списки.
''';
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
    return '''
# Промпт для клонирования UI

> $reason

Склонируй мобильный интерфейс приложения
**${targetLabel ?? 'целевое приложение'}**
${targetPackage != null ? '(`$targetPackage`)' : ''}.

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

Uint8List _compressJpegBytes(Uint8List bytes) {
  // Keep payload small for vision APIs; native capture already saves JPEG.
  // If the file is already modest, pass through.
  if (bytes.lengthInBytes <= 350 * 1024) {
    return bytes;
  }
  // Without image codec in isolate, truncate is unsafe — return original.
  // Compression is handled on Android capture side (JPEG quality).
  return bytes;
}
