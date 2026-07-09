// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CaptureSession _$CaptureSessionFromJson(Map<String, dynamic> json) =>
    _CaptureSession(
      id: json['id'] as String,
      targetPackage: json['targetPackage'] as String?,
      targetLabel: json['targetLabel'] as String?,
      status:
          $enumDecodeNullable(_$CaptureStatusEnumMap, json['status']) ??
          CaptureStatus.idle,
      screenshotPaths:
          (json['screenshotPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      skippedDuplicates: (json['skippedDuplicates'] as num?)?.toInt() ?? 0,
      prompt: json['prompt'] as String?,
      errorMessage: json['errorMessage'] as String?,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      finishedAt: json['finishedAt'] == null
          ? null
          : DateTime.parse(json['finishedAt'] as String),
    );

Map<String, dynamic> _$CaptureSessionToJson(_CaptureSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'targetPackage': instance.targetPackage,
      'targetLabel': instance.targetLabel,
      'status': _$CaptureStatusEnumMap[instance.status]!,
      'screenshotPaths': instance.screenshotPaths,
      'skippedDuplicates': instance.skippedDuplicates,
      'prompt': instance.prompt,
      'errorMessage': instance.errorMessage,
      'startedAt': instance.startedAt?.toIso8601String(),
      'finishedAt': instance.finishedAt?.toIso8601String(),
    };

const _$CaptureStatusEnumMap = {
  CaptureStatus.idle: 'idle',
  CaptureStatus.requestingPermission: 'requestingPermission',
  CaptureStatus.capturing: 'capturing',
  CaptureStatus.stopping: 'stopping',
  CaptureStatus.analyzing: 'analyzing',
  CaptureStatus.completed: 'completed',
  CaptureStatus.failed: 'failed',
};
