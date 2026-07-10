import 'package:flutter_test/flutter_test.dart';
import 'package:ui_clone/data/services/analysis_response_parser.dart';

void main() {
  test('extracts human markdown from structured JSON', () {
    const raw = '''
{
  "palette": [{"name": "primary", "hex": "#0F8B8D"}],
  "screens": [{"name": "Home", "layout": "header", "functions": ["go"]}],
  "components": [{"name": "Btn", "description": "pill"}],
  "markdown": "# Промпт\\n\\nСклонируй UI"
}
''';
    final result = AnalysisResponseParser.parse(raw);
    expect(result.markdown, contains('# Промпт'));
    expect(result.markdown, isNot(contains('"palette"')));
    expect(result.structuredJson, isNotNull);
  });

  test('unwraps JSON stuffed into markdown field', () {
    const raw = r'''
{
  "palette": [{"name": "primary", "hex": "#ABC"}],
  "screens": [{"name": "Home", "layout": "list", "functions": []}],
  "components": [],
  "markdown": "{\"palette\":[],\"markdown\":\"# Real\\nHello\"}"
}
''';
    final result = AnalysisResponseParser.parse(raw);
    expect(result.markdown, contains('# Real'));
    expect(result.markdown, isNot(contains('"palette"')));
  });

  test('rebuilds markdown when field is raw JSON envelope', () {
    const raw = r'''
{
  "palette": [{"name": "primary", "hex": "#ABC"}],
  "screens": [{"name": "Home", "layout": "top bar", "functions": ["search"]}],
  "components": [{"name": "Chip", "description": "filter"}],
  "markdown": "{\"palette\":[{\"name\":\"primary\",\"hex\":\"#ABC\"}],\"screens\":[],\"components\":[],\"markdown\":\"\"}"
}
''';
    final result = AnalysisResponseParser.parse(raw);
    expect(result.markdown, contains('# Палитра'));
    expect(result.markdown, contains('# Экраны'));
    expect(result.markdown, isNot(contains('"markdown"')));
  });

  test('does not show raw JSON when markdown field is junk object', () {
    const raw = '{"palette":[],"screens":[],"components":[],"markdown":"{ bad"}';
    final result = AnalysisResponseParser.parse(raw);
    expect(result.markdown.trim().startsWith('{'), isFalse);
    expect(
      result.markdown.contains('JSON') ||
          result.markdown.contains('Не удалось'),
      isTrue,
    );
  });
}
