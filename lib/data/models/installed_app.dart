import 'package:freezed_annotation/freezed_annotation.dart';

part 'installed_app.freezed.dart';
part 'installed_app.g.dart';

@freezed
abstract class InstalledApp with _$InstalledApp {
  const factory InstalledApp({
    required String packageName,
    required String label,
    String? iconBase64,
    @Default(false) bool isSystemApp,
  }) = _InstalledApp;

  factory InstalledApp.fromJson(Map<String, dynamic> json) =>
      _$InstalledAppFromJson(json);
}
