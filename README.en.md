# UI Clone

[Русский](README.md) · **English** · [中文](README.zh-CN.md)

A Flutter app for **UI cloning**: start a review session, pick a target app,
and it periodically captures the screen (screenshots via MediaProjection).
When you hit **Stop** (from the notification, overlay, or the app screen), a
vision model builds a prompt describing the style, buttons, layout, and
features.

## Stack

- **Flutter** 3.44+ / **Dart** 3.12+
- **Riverpod** — state management
- **freezed** + **json_serializable** — models
- **dio** — OpenAI-compatible Vision API
- **Android native** — MediaProjection, foreground service, overlay, app list

## Usage

1. Install the APK on Android 8+ (API 26).
2. (Optional) In **Settings**, set your API key and vision model
   (`gpt-4o-mini` or a compatible endpoint). Or pick the **Local (no cloud)**
   provider — screenshots never leave the device, and the HEX palette is
   computed on-device.
3. On the home screen, tap **Start interface review**.
4. Pick an app from the list (or "Capture without selecting").
5. Grant screen recording; optionally enable "draw over other apps" for the
   overlay.
6. Scroll through the target's screens. Stop via the notification button, the
   floating **Stop** button, or the UI Clone screen.
7. Wait for analysis, then copy or share the prompt.

Even without an API key, the app returns a structured prompt template from the
captured screenshots.

## Running

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <android-device>
# or
flutter build apk --debug
```

## Release

Full guide: **[docs/release-build.md](docs/release-build.md)**.

```bash
# 1) Changelog → interactive tag (version, commit, push, git tag)
#    Stable / Beta / Alpha; tag on the current branch
dart run release.dart

# 2) Build APK / AAB
chmod +x scripts/flutter_build_release.sh bin/ci/android_collect_artifacts.sh

# (one-time) signing: cp android/key.properties.example android/key.properties
# + android/app/keystore.jks

./scripts/flutter_build_release.sh apk
# or split: ./scripts/flutter_build_release.sh android-split
# or Play:  ./scripts/flutter_build_release.sh appbundle

# 3) Artifacts in dist/android/ (label = tag, e.g. v1.0.0)
export APP_RELEASE_LABEL="v1.0.0"
bin/ci/android_collect_artifacts.sh
# → dist/android/UIClone-android-v1.0.0-*.apk
```

## Architecture

```
lib/
  core/           theme, constants
  data/
    models/       InstalledApp, CaptureSession
    services/     platform channel, settings, AI
    repositories/ session orchestration
  features/
    home/         start a review
    app_picker/   list of installed apps
    capture/      capture status and preview
    result/       final prompt
    settings/     API / interval / overlay
    about/        version, license, terms, GitHub, donate
android/.../capture/   ScreenCaptureService (MediaProjection)
android/.../overlay/   floating "Stop" button
```

Feature details — see [FEATURES.md](FEATURES.md).
Roadmap — see [TODO.md](TODO.md).
How to contribute — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Limitations

- Full screen capture and the installed-app list are **Android** only.
  On iOS the UI and the offline prompt template are available, but system
  screen capture via MediaProjection is not.
- Do not copy third-party trademarks or user content — the prompt is aimed at
  reproducing UX patterns and visual language, not assets.
- `QUERY_ALL_PACKAGES` is needed for the full app list; publishing on Google
  Play may require a justification for it.

## License

[MIT](LICENSE) © Serj Sivkov
