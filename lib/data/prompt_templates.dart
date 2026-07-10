/// Built-in system prompt templates for vision analysis.
class PromptTemplate {
  const PromptTemplate({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;
}

abstract final class PromptTemplates {
  static const String flutter = 'flutter';
  static const String reactNative = 'react_native';
  static const String figma = 'figma';
  static const String generalUx = 'general_ux';

  static const List<PromptTemplate> all = [
    PromptTemplate(id: flutter, title: 'Flutter', body: _flutterBody),
    PromptTemplate(
      id: reactNative,
      title: 'React Native',
      body: _reactNativeBody,
    ),
    PromptTemplate(id: figma, title: 'Figma', body: _figmaBody),
    PromptTemplate(id: generalUx, title: 'Общий UX', body: _generalUxBody),
  ];

  static PromptTemplate byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static String defaultBody(String id) => byId(id).body;

  static bool isKnownId(String id) => all.any((t) => t.id == id);

  /// Replaces `{{app}}`, `{{package}}`, `{{count}}` in [body].
  static String apply({
    required String body,
    required String app,
    String? package,
    required int count,
  }) {
    final packageLine = package == null || package.isEmpty
        ? ''
        : '(package: $package)';
    return body
        .replaceAll('{{app}}', app)
        .replaceAll('{{package}}', packageLine)
        .replaceAll('{{count}}', '$count');
  }

  static const String _flutterBody = '''
Ты — senior product designer + Flutter UI engineer.
Проанализируй {{count}} скриншотов приложения "{{app}}"
{{package}}.

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
   виджетов, план файлов lib/features/..., что НЕ копировать
   (брендинг/логотипы/контент пользователя).

Формат ответа — только итоговый промпт, без преамбулы.
Используй markdown-заголовки и маркированные списки.
''';

  static const String _reactNativeBody = '''
Ты — senior product designer + React Native / Expo engineer.
Проанализируй {{count}} скриншотов приложения "{{app}}"
{{package}}.

Составь ОДИН готовый промпт на русском для генерации клона UI
(для Cursor / Claude / GPT / RN-агента). Промпт должен включать:

1. Общий стиль: палитра HEX, типографика, spacing, радиусы, тени, тема.
2. Навигация: React Navigation (tabs / stack / drawer), иерархия экранов.
3. По каждому заметному экрану: layout сверху вниз, ключевые блоки,
   позиции контролов, состояния empty/loading/error.
4. Компоненты: Pressable/Button, FlatList/SectionList, TextInput, карточки,
   чипы — размеры и поведение; предпочтение StyleSheet / NativeWind.
5. Функции, угадываемые по UI.
6. Технические указания для React Native / Expo: структура экранов и
   компонентов, навигация, что НЕ копировать (брендинг/логотипы/контент).

Формат ответа — только итоговый промпт, без преамбулы.
Используй markdown-заголовки и маркированные списки.
''';

  static const String _figmaBody = '''
Ты — senior product designer, работающий в Figma.
Проанализируй {{count}} скриншотов приложения "{{app}}"
{{package}}.

Составь ОДИН готовый промпт на русском для воссоздания UI в Figma
(дизайн-система + экраны). Промпт должен включать:

1. Визуальный язык: палитра HEX, типографика (размеры/веса), spacing-шкала,
   радиусы, elevation/тени, светлая/тёмная тема.
2. Токены: цвета, текст, отступы — как назвать и сгруппировать.
3. Компоненты: кнопки (варианты/состояния), инпуты, списки, таббар,
   карточки, чипы — Auto Layout, constraints, variants.
4. Экраны: структура фреймов сверху вниз, сетка, отступы, иерархия.
5. Навигация и flow между экранами (если видно).
6. Что НЕ копировать: чужие логотипы, товарные знаки, пользовательский
   контент — только UX-паттерны и визуальный язык.

Формат ответа — только итоговый промпт для дизайнера / Figma-агента,
без преамбулы. Markdown-заголовки и списки.
''';

  static const String _generalUxBody = '''
Ты — senior product designer + UX researcher.
Проанализируй {{count}} скриншотов приложения "{{app}}"
{{package}}.

Составь ОДИН готовый промпт на русском для клонирования UX/UI
(платформо-нейтрально: любой стек или дизайн-инструмент). Промпт должен
включать:

1. Общий стиль: палитра HEX, типографика, плотность, радиусы, тени, тема.
2. Информационная архитектура и навигация.
3. По каждому заметному экрану: layout, ключевые блоки, CTA, состояния.
4. Паттерны компонентов и взаимодействия (touch targets, feedback).
5. Функции, угадываемые по UI.
6. Ограничения: не копировать брендинг/логотипы/пользовательский контент;
   воспроизводить структуру и UX-паттерны.

Формат ответа — только итоговый промпт, без преамбулы.
Используй markdown-заголовки и маркированные списки.
''';
}
