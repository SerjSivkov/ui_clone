// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_app.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InstalledApp _$InstalledAppFromJson(Map<String, dynamic> json) =>
    _InstalledApp(
      packageName: json['packageName'] as String,
      label: json['label'] as String,
      iconBase64: json['iconBase64'] as String?,
      isSystemApp: json['isSystemApp'] as bool? ?? false,
    );

Map<String, dynamic> _$InstalledAppToJson(_InstalledApp instance) =>
    <String, dynamic>{
      'packageName': instance.packageName,
      'label': instance.label,
      'iconBase64': instance.iconBase64,
      'isSystemApp': instance.isSystemApp,
    };
