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
  "markdown": "# Промпт для клонирования UI\\n\\n1. Стиль…\\n2. Экраны…"
}
Поле "markdown" — ТОЛЬКО человекочитаемый промпт на русском (заголовки,
списки, текст). НЕ вставляй в "markdown" JSON, код-блоки json и не дублируй
схему ответа. Структурированные данные — только в palette/screens/components.
''';

  static AnalysisResult parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const AnalysisResult(markdown: '');
    }

    final jsonText = _extractJsonObject(trimmed);
    if (jsonText == null) {
      return AnalysisResult(markdown: _stripJsonFences(trimmed));
    }

    Map<String, dynamic>? decoded;
    try {
      final value = jsonDecode(jsonText);
      if (value is Map<String, dynamic>) {
        decoded = value;
      } else if (value is Map) {
        decoded = value.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {
      decoded = null;
    }

    if (decoded == null) {
      final looseMarkdown = _extractMarkdownFieldLoose(jsonText);
      if (looseMarkdown != null &&
          looseMarkdown.isNotEmpty &&
          !_shouldNotShowAsMarkdown(looseMarkdown)) {
        return AnalysisResult(markdown: _sanitizeMarkdownText(looseMarkdown));
      }
      return const AnalysisResult(
        markdown:
            'Не удалось извлечь текстовый промпт из ответа модели. '
            'Смотрите вкладку JSON или повторите анализ.',
      );
    }

    final analysis = _analysisFromMap(decoded);
    final pretty = const JsonEncoder.withIndent('  ').convert(
      _structuredMap(analysis),
    );
    final markdown = _resolveMarkdown(
      decoded: decoded,
      analysis: analysis,
      rawFallback: trimmed,
    );

    return AnalysisResult(
      markdown: markdown,
      structuredJson: pretty,
      structured: analysis,
    );
  }

  static UiCloneAnalysis _analysisFromMap(Map<String, dynamic> decoded) {
    return UiCloneAnalysis(
      palette: _parsePalette(decoded['palette']),
      screens: _parseScreens(decoded['screens']),
      components: _parseComponents(decoded['components']),
      markdown: _stringField(decoded, const [
        'markdown',
        'prompt',
        'clone_prompt',
        'text',
        'content',
      ]),
    );
  }

  static Map<String, dynamic> _structuredMap(UiCloneAnalysis analysis) {
    return {
      'palette': [
        for (final c in analysis.palette) {'name': c.name, 'hex': c.hex},
      ],
      'screens': [
        for (final s in analysis.screens)
          {
            'name': s.name,
            'layout': s.layout,
            'functions': s.functions,
          },
      ],
      'components': [
        for (final c in analysis.components)
          {'name': c.name, 'description': c.description},
      ],
      'markdown': analysis.markdown,
    };
  }

  static String _resolveMarkdown({
    required Map<String, dynamic> decoded,
    required UiCloneAnalysis analysis,
    required String rawFallback,
  }) {
    var markdown = _stringField(decoded, const [
      'markdown',
      'prompt',
      'clone_prompt',
      'text',
      'content',
    ]);

    markdown = _sanitizeMarkdownText(markdown);

    // Model sometimes puts a nested JSON object/string into markdown.
    if (_shouldNotShowAsMarkdown(markdown)) {
      final unwrapped = _unwrapNestedMarkdown(markdown);
      if (unwrapped != null &&
          unwrapped.isNotEmpty &&
          !_shouldNotShowAsMarkdown(unwrapped)) {
        return unwrapped;
      }
      final fromStructured = _markdownFromStructured(
        analysis,
        fallback: '',
      );
      if (fromStructured.isNotEmpty) return fromStructured;
      return 'Промпт в ответе модели пришёл как JSON. '
          'Откройте вкладку JSON или повторите анализ.';
    }

    if (markdown.isNotEmpty) return markdown;

    final fromStructured = _markdownFromStructured(
      analysis,
      fallback: '',
    );
    if (fromStructured.isNotEmpty) return fromStructured;

    // Last resort: never show raw JSON envelope on the Markdown tab.
    if (_shouldNotShowAsMarkdown(rawFallback)) {
      return 'Не удалось извлечь текстовый промпт из ответа модели. '
          'Смотрите вкладку JSON.';
    }
    return _stripJsonFences(rawFallback);
  }

  static String? _unwrapNestedMarkdown(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        final map = decoded.map((k, v) => MapEntry(k.toString(), v));
        final nested = _stringField(map, const [
          'markdown',
          'prompt',
          'clone_prompt',
          'text',
          'content',
        ]);
        if (nested.isNotEmpty) return _sanitizeMarkdownText(nested);
      }
      if (decoded is String && decoded.trim().isNotEmpty) {
        return _sanitizeMarkdownText(decoded);
      }
    } catch (_) {}
    return null;
  }

  static bool _shouldNotShowAsMarkdown(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    if (_looksLikeJsonDocument(t)) return true;
    // Partial / broken JSON fragments must not land on the Markdown tab.
    return t.startsWith('{') || t.startsWith('[');
  }

  static bool _looksLikeJsonDocument(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    if (t.startsWith('```')) {
      final body = _stripJsonFences(t).trim();
      return _looksLikeJsonDocument(body);
    }
    if (!t.startsWith('{') && !t.startsWith('[')) return false;
    final lower = t.toLowerCase();
    return lower.contains('"palette"') ||
        lower.contains('"screens"') ||
        lower.contains('"components"') ||
        lower.contains('"markdown"') ||
        (t.startsWith('{') && t.contains('":'));
  }

  static String _sanitizeMarkdownText(String text) {
    var md = text.trim();
    if (md.isEmpty) return '';
    // Drop accidental ```json ... ``` wrappers around prose.
    final fence = RegExp(
      r'^```(?:json|markdown|md)?\s*([\s\S]*?)```$',
      caseSensitive: false,
    );
    final match = fence.firstMatch(md);
    if (match != null) {
      md = match.group(1)!.trim();
    }
    return md;
  }

  static String _stripJsonFences(String text) {
    final fence = RegExp(
      r'```(?:json|markdown|md)?\s*([\s\S]*?)```',
      caseSensitive: false,
    );
    final match = fence.firstMatch(text.trim());
    if (match != null) return match.group(1)!.trim();
    return text.trim();
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

  /// Best-effort when jsonDecode fails (unescaped newlines, trailing commas).
  static String? _extractMarkdownFieldLoose(String jsonText) {
    final patterns = <RegExp>[
      RegExp(
        r'"(?:markdown|prompt|clone_prompt)"\s*:\s*"((?:[^"\\]|\\.)*)"',
        dotAll: true,
      ),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(jsonText);
      if (m == null) continue;
      final raw = m.group(1);
      if (raw == null || raw.isEmpty) continue;
      try {
        return jsonDecode('"$raw"') as String;
      } catch (_) {
        return raw
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\t', '\t')
            .replaceAll(r'\"', '"')
            .replaceAll(r'\\', r'\');
      }
    }
    return null;
  }

  static String _stringField(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is Map || value is List) {
        // Nested structured junk in markdown-like field — skip.
        continue;
      }
    }
    return '';
  }

  static List<UiCloneColorToken> _parsePalette(Object? raw) {
    if (raw is! List) return const [];
    final out = <UiCloneColorToken>[];
    for (final item in raw) {
      if (item is Map) {
        final m = item.map((k, v) => MapEntry(k.toString(), v));
        out.add(
          UiCloneColorToken(
            name: '${m['name'] ?? ''}',
            hex: '${m['hex'] ?? m['color'] ?? ''}',
          ),
        );
      } else if (item is String && item.trim().isNotEmpty) {
        out.add(UiCloneColorToken(name: 'color', hex: item.trim()));
      }
    }
    return out;
  }

  static List<UiCloneScreenSpec> _parseScreens(Object? raw) {
    if (raw is! List) return const [];
    final out = <UiCloneScreenSpec>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = item.map((k, v) => MapEntry(k.toString(), v));
      final functionsRaw = m['functions'];
      final functions = <String>[];
      if (functionsRaw is List) {
        for (final f in functionsRaw) {
          final s = '$f'.trim();
          if (s.isNotEmpty) functions.add(s);
        }
      }
      out.add(
        UiCloneScreenSpec(
          name: '${m['name'] ?? m['title'] ?? ''}',
          layout: '${m['layout'] ?? m['description'] ?? ''}',
          functions: functions,
        ),
      );
    }
    return out;
  }

  static List<UiCloneComponentSpec> _parseComponents(Object? raw) {
    if (raw is! List) return const [];
    final out = <UiCloneComponentSpec>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = item.map((k, v) => MapEntry(k.toString(), v));
      out.add(
        UiCloneComponentSpec(
          name: '${m['name'] ?? ''}',
          description: '${m['description'] ?? m['desc'] ?? ''}',
        ),
      );
    }
    return out;
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
    final clean = _sanitizeMarkdownText(markdown);
    final analysis = UiCloneAnalysis(markdown: clean);
    final pretty = const JsonEncoder.withIndent('  ').convert(
      _structuredMap(analysis),
    );
    return AnalysisResult(
      markdown: clean,
      structuredJson: pretty,
      structured: analysis,
    );
  }
}
