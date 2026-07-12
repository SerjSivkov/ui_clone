# Contributing to UI Clone

Thanks for your interest in improving UI Clone! This guide covers how to set
up the project, the conventions we follow, and how to submit changes.

русскоязычным контрибьюторам: PR и issue можно писать на русском или
английском — как удобнее.

## Prerequisites

- **Flutter** 3.44+ / **Dart** 3.12+ (`flutter --version`)
- Android SDK + a device or emulator on **Android 8+ (API 26)** for the
  full capture flow (MediaProjection, overlay, app list).
- iOS builds compile, but system screen capture is Android-only.

## Setup

```bash
git clone https://github.com/SerjSivkov/ui_clone.git
cd ui_clone
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <android-device>
```

`build_runner` generates the `freezed`, `json_serializable`, and Riverpod
files. Re-run it after changing any annotated model or provider. For an
active loop use:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Before you open a PR

Run the same checks CI expects:

```bash
dart format .
flutter analyze
flutter test
```

- `flutter analyze` must be clean (lint rules live in `analysis_options.yaml`).
- Add or update tests for behavior changes. Existing tests live in `test/`
  (parser, local palette, widgets) — follow their style.
- Generated files (`*.freezed.dart`, `*.g.dart`) should be committed when you
  change their source, so a fresh checkout builds without a codegen step.

## Commit and PR conventions

- Keep commits focused; write clear messages. Prefixes like `feat:`, `fix:`,
  `docs:`, `refactor:` are appreciated and match the existing history and
  `CHANGELOG.md`.
- Branch off `master`; never push directly to it. Open a PR against `master`.
- In the PR description, note **what changed**, **how you tested it**, and any
  platform caveats (Android vs iOS).
- Add a line under the `## Unreleased` section of `CHANGELOG.md` for
  user-facing changes.

## Project layout

See the **Architecture** section in the [README](README.md) for a map of
`lib/` and the Android native code. Feature docs are in
[FEATURES.md](FEATURES.md); planned work is in [TODO.md](TODO.md).

## Reporting bugs and requesting features

Open an issue on
[GitHub](https://github.com/SerjSivkov/ui_clone/issues) with:

- Device / OS version and Flutter version (`flutter doctor -v`).
- Steps to reproduce, expected vs actual behavior.
- For capture issues: the vision provider used (or **Local**), and whether
  overlay / accessibility permissions were granted.

Please **do not** include API keys, personal data, or screenshots of other
people's private content.

## Scope and ethics

UI Clone is meant for learning from and reproducing **UX patterns and visual
language**. Do not use it to copy third-party trademarks, proprietary assets,
or private user content. Contributions that add such functionality won't be
merged.

## License

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).
