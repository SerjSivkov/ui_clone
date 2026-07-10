import 'dart:convert';

import '../models/ui_clone_analysis.dart';

/// Parses model output that should be a JSON object (optionally fenced).
abstract final class AnalysisResponseParser {
  static const responseFormatInstruction = '''

---
ФОРМАТ ОТВЕТА (обязательно):
Верни СТРОГО один JSON-объект. Без преамбулы, без markdown-ограждений ```.
Схема:
{
  "palette": [{"name": "primary", "hex": "#0F8B8D"}],
  "screens": [{"name": "Home", "layout": "сверху вниз…", "functions": ["…"]}],
  "components": [{"name": "PrimaryButton", "description": "…"}],
  "markdown": "# Промпт…\\nполный человекочитаемый промпт для клонирования UI"
}
Поле "markdown" — полный промпт на русском (заголовки, списки).
Палитра: реальные HEX с экранов, если видно. Экраны и компоненты — по скриншотам.
''';

  static AnalysisResult parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const AnalysisResult(markdown: '');
    }

    final jsonText = _extractJsonObject(trimmed);
    if (jsonText == null) {
      return AnalysisResult(markdown: trimmed);
    }

    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        return AnalysisResult(markdown: trimmed);
      }
      final analysis = UiCloneAnalysis.fromJson(decoded);
      final markdown = analysis.markdown.trim().isNotEmpty
          ? analysis.markdown.trim()
          : _markdownFromStructured(analysis, fallback: trimmed);
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      return AnalysisResult(
        markdown: markdown,
        structuredJson: pretty,
        structured: analysis,
      );
    } catch (_) {
      return AnalysisResult(markdown: trimmed);
    }
  }

  static String? _extractJsonObject(String text) {
    var candidate = text;
    final fence = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    );
    final fenceMatch = fence.firstMatch(text);
    if (fenceMatch != null) {
      candidate = fenceMatch.group(1)!.trim();
    }

    final start = candidate.indexOf('{');
    final end = candidate.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return candidate.substring(start, end + 1);
  }

  static String _markdownFromStructured(
    UiCloneAnalysis analysis, {
    required String fallback,
  }) {
    final buf = StringBuffer();
    if (analysis.palette.isNotEmpty) {
      buf.writeln('# Палитра');
      for (final c in analysis.palette) {
        final label = c.name.isEmpty ? 'color' : c.name;
        final hex = c.hex.isEmpty ? '—' : c.hex;
        buf.writeln('- **$label**: `$hex`');
      }
      buf.writeln();
    }
    if (analysis.screens.isNotEmpty) {
      buf.writeln('# Экраны');
      for (final s in analysis.screens) {
        buf.writeln('## ${s.name.isEmpty ? 'Экран' : s.name}');
        if (s.layout.isNotEmpty) buf.writeln(s.layout);
        if (s.functions.isNotEmpty) {
          buf.writeln('Функции:');
          for (final f in s.functions) {
            buf.writeln('- $f');
          }
        }
        buf.writeln();
      }
    }
    if (analysis.components.isNotEmpty) {
      buf.writeln('# Компоненты');
      for (final c in analysis.components) {
        final name = c.name.isEmpty ? 'Component' : c.name;
        buf.writeln('- **$name**: ${c.description}');
      }
      buf.writeln();
    }
    final built = buf.toString().trim();
    return built.isEmpty ? fallback : built;
  }

  /// Offline / fallback: markdown only, plus minimal structured shell.
  static AnalysisResult fromMarkdownOnly(String markdown) {
    final analysis = UiCloneAnalysis(markdown: markdown);
    final map = analysis.toJson();
    final pretty = const JsonEncoder.withIndent('  ').convert(map);
    return AnalysisResult(
      markdown: markdown,
      structuredJson: pretty,
      structured: analysis,
    );
  }
}
