// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_clone_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UiCloneAnalysis _$UiCloneAnalysisFromJson(
  Map<String, dynamic> json,
) => _UiCloneAnalysis(
  palette:
      (json['palette'] as List<dynamic>?)
          ?.map((e) => UiCloneColorToken.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  screens:
      (json['screens'] as List<dynamic>?)
          ?.map((e) => UiCloneScreenSpec.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  components:
      (json['components'] as List<dynamic>?)
          ?.map((e) => UiCloneComponentSpec.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  markdown: json['markdown'] as String? ?? '',
);

Map<String, dynamic> _$UiCloneAnalysisToJson(_UiCloneAnalysis instance) =>
    <String, dynamic>{
      'palette': instance.palette,
      'screens': instance.screens,
      'components': instance.components,
      'markdown': instance.markdown,
    };

_UiCloneColorToken _$UiCloneColorTokenFromJson(Map<String, dynamic> json) =>
    _UiCloneColorToken(
      name: json['name'] as String? ?? '',
      hex: json['hex'] as String? ?? '',
    );

Map<String, dynamic> _$UiCloneColorTokenToJson(_UiCloneColorToken instance) =>
    <String, dynamic>{'name': instance.name, 'hex': instance.hex};

_UiCloneScreenSpec _$UiCloneScreenSpecFromJson(Map<String, dynamic> json) =>
    _UiCloneScreenSpec(
      name: json['name'] as String? ?? '',
      layout: json['layout'] as String? ?? '',
      functions:
          (json['functions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$UiCloneScreenSpecToJson(_UiCloneScreenSpec instance) =>
    <String, dynamic>{
      'name': instance.name,
      'layout': instance.layout,
      'functions': instance.functions,
    };

_UiCloneComponentSpec _$UiCloneComponentSpecFromJson(
  Map<String, dynamic> json,
) => _UiCloneComponentSpec(
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
);

Map<String, dynamic> _$UiCloneComponentSpecToJson(
  _UiCloneComponentSpec instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
};
