# UI Clone

Flutter-приложение для **клонирования UI**: запускаете обзор, выбираете
целевое приложение, идёт периодический захват экрана (скриншоты через
MediaProjection), по кнопке «Стоп» (уведомление / оверлей / экран приложения)
vision-модель собирает промпт со стилем, кнопками, layout и функциями.

Путь: `/Users/serjsivkov/mobile_development_way/ui_clone`

## Стек

- **Flutter** 3.44+ / **Dart** 3.12+
- **Riverpod** — состояние
- **freezed** + **json_serializable** — модели
- **dio** — OpenAI-совместимый Vision API
- **Android native** — MediaProjection, foreground service, overlay, app list

## Как пользоваться

1. Установите APK на Android 8+ (API 26).
2. (Опционально) в **Настройки** укажите API key и vision-модель
   (`gpt-4o-mini` или совместимый endpoint).
3. На главном экране — **Начать обзор интерфейса**.
4. Выберите приложение из списка (или «Сбор без выбора»).
5. Разрешите запись экрана; при желании — «поверх других окон» для оверлея.
6. Листайте экраны цели. Остановить: кнопка в шторке, плавающий «Стоп» или
   экран UI Clone.
7. Дождитесь анализа — скопируйте / поделитесь промптом.

Без API-ключа приложение всё равно отдаёт структурированный шаблон промпта
по собранным скриншотам.

## Запуск

```bash
cd /Users/serjsivkov/mobile_development_way/ui_clone
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <android-device>
# или
flutter build apk --debug
```

## Архитектура

```
lib/
  core/           тема, константы
  data/
    models/       InstalledApp, CaptureSession
    services/     platform channel, settings, AI
    repositories/ оркестрация сессии
  features/
    home/         старт обзора
    app_picker/   список установленных приложений
    capture/      статус сбора и превью
    result/       готовый промпт
    settings/     API / интервал / оверлей
android/.../capture/   ScreenCaptureService (MediaProjection)
android/.../overlay/   плавающая кнопка «Стоп»
```

Подробности возможностей — в [FEATURES.md](FEATURES.md).
План улучшений — в [TODO.md](TODO.md).

## Ограничения

- Полноценный захват экрана и список приложений — **Android**.
  На iOS UI и офлайн-шаблон промпта доступны, системный screen capture
  через MediaProjection недоступен.
- Не копируйте чужие товарные знаки и пользовательский контент — промпт
  ориентирован на воспроизведение UX-паттернов и визуального языка.
- `QUERY_ALL_PACKAGES` нужен для полного списка приложений; в Google Play
  для публикации может потребоваться обоснование.
