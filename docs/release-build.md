# Локальная сборка релиза UI Clone

Пошаговая инструкция: версия и git-тег (`dart run release.dart`), подпись
Android, APK / split / AAB и сбор артефактов в `dist/android/`.

Связанные файлы:

| Файл | Назначение |
|------|------------|
| `release.dart` | Интерактивный релиз: версия в `pubspec.yaml`, commit, push, тег |
| `scripts/flutter_build_release.sh` | Release-сборка (`apk` / `android-split` / `appbundle` / `ios`) |
| `bin/ci/android_collect_artifacts.sh` | Переименование APK в `dist/android/` |
| `android/key.properties.example` | Шаблон подписи release |
| `CHANGELOG.md` | Описание изменений релиза |

Основная платформа — **Android** (MediaProjection). iOS-сборка возможна, но без
захвата чужих приложений.

---

## 0. Окружение

| Компонент | Версия / примечание |
|-----------|---------------------|
| Flutter | **3.44+** (stable), `flutter doctor` без критичных ошибок |
| JDK | **17** |
| Android SDK | как в `flutter doctor` |
| Подпись Android | `android/key.properties` + `android/app/keystore.jks` |

```bash
cd /Users/serjsivkov/mobile_development_way/ui_clone
flutter --version
flutter doctor
```

---

## 1. Changelog и формат версии

Формат в `pubspec.yaml`: `version: X.Y.Z+BUILD` (например `1.0.0+1`).

- **X.Y.Z** — версия для пользователя (и для git-тега)
- **+BUILD** — `versionCode` Android (увеличивается при каждом релизе)

Перед релизом добавьте секцию в `CHANGELOG.md` (скрипт `release.dart` закоммитит
его вместе с `pubspec.yaml`):

```markdown
## 1.0.1
- Feat: …
```

Номер `version:` обычно выставляет `dart run release.dart` (следующий раздел).
Вручную править `pubspec.yaml` нужно только если идёте по варианту B.

---

## 2. Версия и git-тег (`dart run release.dart`)

### Вариант A — интерактивный скрипт (рекомендуется)

```bash
cd /Users/serjsivkov/mobile_development_way/ui_clone
# CHANGELOG.md уже обновлён под новый релиз
dart run release.dart
```

Скрипт:

1. Предлагает тип: **Stable** / **Beta** / **Alpha**
2. Подсказывает следующую версию и build number по тегам и `pubspec.yaml`
3. По подтверждению обновляет `version:` в `pubspec.yaml`
4. Делает `git add pubspec.yaml CHANGELOG.md`, commit `release: <tag>`, push ветки
5. Создаёт тег на **текущей ветке** и пушит его (`git push <remote> <tag>`)

Если у ветки ещё нет upstream, выполнит `git push -u <remote> <ветка>`.

Форматы тегов:

| Тип | Пример тега |
|-----|-------------|
| Stable | `v1.0.1` |
| Beta | `v1.0.1-beta.1` |
| Alpha | `v1.0.1-alpha.1` |

**Важно:** версия в теге (`1.0.1`) должна совпадать с `version:` в `pubspec.yaml` до знака `+`.

После успешного тега соберите APK/AAB (разделы ниже) с
`APP_RELEASE_LABEL` равным тегу, например `v1.0.1`.

### Вариант B — вручную

```bash
# 1. Правка pubspec.yaml → version: 1.0.1+2
# 2. Commit
git add pubspec.yaml CHANGELOG.md
git commit -m "release: v1.0.1"
git push

# 3. Тег и push
git tag v1.0.1
git push origin v1.0.1
```

---

## 3. Подпись Android (release)

```bash
cp android/key.properties.example android/key.properties
# отредактировать пароли и alias
```

Создать keystore (один раз):

```bash
keytool -genkey -v \
  -keystore android/app/keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

`android/key.properties`:

```properties
storePassword=***
keyPassword=***
keyAlias=upload
storeFile=app/keystore.jks
```

Файлы `key.properties` и `*.jks` в git **не коммитятся** (`android/.gitignore`).

Без keystore скрипт всё равно соберёт `--release`, но APK будет с **debug**-подписью
(предупреждение в логе). Для раздачи / Play нужен release keystore.

---

## 4. Сборка

```bash
chmod +x scripts/flutter_build_release.sh bin/ci/android_collect_artifacts.sh
```

Скрипт сам делает `flutter pub get` и `build_runner` (codegen). Чтобы пропустить
codegen: `SKIP_CODEGEN=1 ./scripts/flutter_build_release.sh apk`.

### 4.1. Универсальный APK

```bash
./scripts/flutter_build_release.sh apk
```

Результат: `build/app/outputs/flutter-apk/app-release.apk`

### 4.2. Split APK по архитектурам

```bash
./scripts/flutter_build_release.sh android-split \
  --target-platform android-arm,android-arm64,android-x64
```

| Файл | Архитектура |
|------|-------------|
| `app-armeabi-v7a-release.apk` | armeabi-v7a |
| `app-arm64-v8a-release.apk` | arm64-v8a |
| `app-x86_64-release.apk` | x86_64 |

### 4.3. App Bundle (Google Play)

```bash
./scripts/flutter_build_release.sh appbundle
```

Результат: `build/app/outputs/bundle/release/app-release.aab`

### 4.4. iOS (unsigned, без codesign)

```bash
./scripts/flutter_build_release.sh ios
```

Только UI / офлайн-промпт; захват чужих app на iOS недоступен.

---

## 5. Сбор артефактов в dist/

```bash
export APP_RELEASE_LABEL="v1.0.0"

./scripts/flutter_build_release.sh apk
./scripts/flutter_build_release.sh android-split \
  --target-platform android-arm,android-arm64,android-x64

bin/ci/android_collect_artifacts.sh
ls -la dist/android/
```

Примеры имён:

| Файл |
|------|
| `UIClone-android-v1.0.0-universal.apk` |
| `UIClone-android-v1.0.0-arm64-v8a.apk` |
| `UIClone-android-v1.0.0-armeabi-v7a.apk` |
| `UIClone-android-v1.0.0-x86_64.apk` |

Опции окружения:

| Переменная | По умолчанию | Смысл |
|------------|--------------|--------|
| `APP_RELEASE_LABEL` | — (обязателен) | Метка в имени файла, напр. `v1.0.0` |
| `ANDROID_CI_ABIS` | `arm64-v8a,armeabi-v7a,x86_64` | Какие ABI копировать |
| `ANDROID_CI_INCLUDE_UNIVERSAL` | `true` | Копировать universal APK |
| `ARTIFACT_PREFIX` | `UIClone` | Префикс имени файла |

---

## 6. Установка на устройство

```bash
adb install -r dist/android/UIClone-android-v1.0.0-arm64-v8a.apk
# или
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

После установки: разрешения записи экрана, уведомлений и (опционально) оверлея.

---

## 7. Чеклист релиза

1. Обновить `CHANGELOG.md`
2. `dart run release.dart` (версия, commit, push, тег) — или вручную по варианту B
3. Настроить `android/key.properties` + keystore
4. `./scripts/flutter_build_release.sh apk` (+ при необходимости `android-split` / `appbundle`)
5. `APP_RELEASE_LABEL=vX.Y.Z bin/ci/android_collect_artifacts.sh`
6. Проверить установку APK на реальном Android 8+
7. Smoke: старт обзора → стоп → экран промпта

---

## Troubleshooting

| Симптом | Что проверить |
|---------|----------------|
| WARNING про debug keystore | Нет `android/key.properties` или путь `storeFile` неверный |
| `No *-release*.apk` | Сборка ушла в debug — не передавайте `--debug` |
| Ошибка codegen | `dart run build_runner build --delete-conflicting-outputs` вручную |
| APK не ставится | `adb uninstall com.mobileway.ui_clone` и поставить снова (другая подпись) |
| `release.dart` не находит version | В `pubspec.yaml` должна быть строка `version: X.Y.Z+N` |
