# UI Clone

[Русский](README.md) · [English](README.en.md) · **中文**

用于 **UI 克隆** 的 Flutter 应用：启动一次审查会话，选择目标应用，应用会
定期捕获屏幕（通过 MediaProjection 截图）。当你点击 **停止**（通知栏 /
悬浮窗 / 应用内界面）时，视觉模型会生成一段描述样式、按钮、布局和功能的
提示词（prompt）。

## 技术栈

- **Flutter** 3.44+ / **Dart** 3.12+
- **Riverpod** — 状态管理
- **freezed** + **json_serializable** — 数据模型
- **dio** — 兼容 OpenAI 的 Vision API
- **Android 原生** — MediaProjection、前台服务、悬浮窗、应用列表

## 使用方法

1. 在 Android 8+（API 26）上安装 APK。
2. （可选）在 **设置** 中填入 API key 和视觉模型
   （`gpt-4o-mini` 或兼容的 endpoint）。或选择 **本地（无云端）** 提供方
   —— 截图不会离开设备，HEX 调色板在设备上本地生成。
3. 在主界面点击 **开始界面审查**。
4. 从列表中选择应用（或选择「不指定应用直接采集」）。
5. 授予屏幕录制权限；如需悬浮窗，可选择开启「显示在其他应用上层」。
6. 浏览目标应用的各个界面。停止方式：通知栏按钮、悬浮的 **停止** 按钮，
   或 UI Clone 界面。
7. 等待分析完成，然后复制或分享提示词。

即使没有 API key，应用也会根据已采集的截图返回一份结构化的提示词模板。

## 运行

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <android-device>
# 或
flutter build apk --debug
```

## 发布

完整指南：**[docs/release-build.md](docs/release-build.md)**。

```bash
# 1) Changelog → 交互式打标签（版本、commit、push、git tag）
#    Stable / Beta / Alpha；在当前分支上打标签
dart run release.dart

# 2) 构建 APK / AAB
chmod +x scripts/flutter_build_release.sh bin/ci/android_collect_artifacts.sh

# （一次性）签名：cp android/key.properties.example android/key.properties
# + android/app/keystore.jks

./scripts/flutter_build_release.sh apk
# 或 split： ./scripts/flutter_build_release.sh android-split
# 或 Play：  ./scripts/flutter_build_release.sh appbundle

# 3) 产物位于 dist/android/（标签 = tag，例如 v1.0.0）
export APP_RELEASE_LABEL="v1.0.0"
bin/ci/android_collect_artifacts.sh
# → dist/android/UIClone-android-v1.0.0-*.apk
```

## 架构

```
lib/
  core/           主题、常量
  data/
    models/       InstalledApp、CaptureSession
    services/     platform channel、设置、AI
    repositories/ 会话编排
  features/
    home/         开始审查
    app_picker/   已安装应用列表
    capture/      采集状态与预览
    result/       最终提示词
    settings/     API / 间隔 / 悬浮窗
    about/        版本、许可证、条款、GitHub、捐赠
android/.../capture/   ScreenCaptureService（MediaProjection）
android/.../overlay/   悬浮「停止」按钮
```

功能详情见 [FEATURES.md](FEATURES.md)。
改进计划见 [TODO.md](TODO.md)。
如何参与贡献见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 限制

- 完整的屏幕捕获和已安装应用列表 **仅支持 Android**。
  在 iOS 上可使用 UI 和离线提示词模板，但无法通过 MediaProjection
  进行系统级屏幕捕获。
- 请勿复制第三方商标和用户内容 —— 提示词旨在复现 UX 模式和视觉语言，
  而非素材本身。
- `QUERY_ALL_PACKAGES` 用于获取完整的应用列表；在 Google Play 上架时
  可能需要为此提供说明。

## 许可证

[MIT](LICENSE) © Serj Sivkov
