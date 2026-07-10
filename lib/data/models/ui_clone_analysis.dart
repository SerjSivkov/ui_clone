import 'package:freezed_annotation/freezed_annotation.dart';

part 'ui_clone_analysis.freezed.dart';
part 'ui_clone_analysis.g.dart';

@freezed
abstract class UiCloneAnalysis with _$UiCloneAnalysis {
  const factory UiCloneAnalysis({
    @Default([]) List<UiCloneColorToken> palette,
    @Default([]) List<UiCloneScreenSpec> screens,
    @Default([]) List<UiCloneComponentSpec> components,
    /// Human-readable clone prompt (markdown).
    @Default('') String markdown,
  }) = _UiCloneAnalysis;

  factory UiCloneAnalysis.fromJson(Map<String, dynamic> json) =>
      _$UiCloneAnalysisFromJson(json);
}

@freezed
abstract class UiCloneColorToken with _$UiCloneColorToken {
  const factory UiCloneColorToken({
    @Default('') String name,
    @Default('') String hex,
  }) = _UiCloneColorToken;

  factory UiCloneColorToken.fromJson(Map<String, dynamic> json) =>
      _$UiCloneColorTokenFromJson(json);
}

@freezed
abstract class UiCloneScreenSpec with _$UiCloneScreenSpec {
  const factory UiCloneScreenSpec({
    @Default('') String name,
    @Default('') String layout,
    @Default([]) List<String> functions,
  }) = _UiCloneScreenSpec;

  factory UiCloneScreenSpec.fromJson(Map<String, dynamic> json) =>
      _$UiCloneScreenSpecFromJson(json);
}

@freezed
abstract class UiCloneComponentSpec with _$UiCloneComponentSpec {
  const factory UiCloneComponentSpec({
    @Default('') String name,
    @Default('') String description,
  }) = _UiCloneComponentSpec;

  factory UiCloneComponentSpec.fromJson(Map<String, dynamic> json) =>
      _$UiCloneComponentSpecFromJson(json);
}

/// Result of vision / offline analysis for the UI layer.
class AnalysisResult {
  const AnalysisResult({
    required this.markdown,
    this.structuredJson,
    this.structured,
  });

  /// Primary human-readable prompt (always set).
  final String markdown;

  /// Pretty-printed JSON when structured parse succeeded.
  final String? structuredJson;

  final UiCloneAnalysis? structured;

  bool get hasStructured =>
      structured != null && (structuredJson?.isNotEmpty ?? false);
}
