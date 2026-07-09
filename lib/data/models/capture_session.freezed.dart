// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'capture_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CaptureSession {

 String get id; String? get targetPackage; String? get targetLabel; CaptureStatus get status; List<String> get screenshotPaths; String? get prompt; String? get errorMessage; DateTime? get startedAt; DateTime? get finishedAt;
/// Create a copy of CaptureSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CaptureSessionCopyWith<CaptureSession> get copyWith => _$CaptureSessionCopyWithImpl<CaptureSession>(this as CaptureSession, _$identity);

  /// Serializes this CaptureSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CaptureSession&&(identical(other.id, id) || other.id == id)&&(identical(other.targetPackage, targetPackage) || other.targetPackage == targetPackage)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.screenshotPaths, screenshotPaths)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetPackage,targetLabel,status,const DeepCollectionEquality().hash(screenshotPaths),prompt,errorMessage,startedAt,finishedAt);

@override
String toString() {
  return 'CaptureSession(id: $id, targetPackage: $targetPackage, targetLabel: $targetLabel, status: $status, screenshotPaths: $screenshotPaths, prompt: $prompt, errorMessage: $errorMessage, startedAt: $startedAt, finishedAt: $finishedAt)';
}


}

/// @nodoc
abstract mixin class $CaptureSessionCopyWith<$Res>  {
  factory $CaptureSessionCopyWith(CaptureSession value, $Res Function(CaptureSession) _then) = _$CaptureSessionCopyWithImpl;
@useResult
$Res call({
 String id, String? targetPackage, String? targetLabel, CaptureStatus status, List<String> screenshotPaths, String? prompt, String? errorMessage, DateTime? startedAt, DateTime? finishedAt
});




}
/// @nodoc
class _$CaptureSessionCopyWithImpl<$Res>
    implements $CaptureSessionCopyWith<$Res> {
  _$CaptureSessionCopyWithImpl(this._self, this._then);

  final CaptureSession _self;
  final $Res Function(CaptureSession) _then;

/// Create a copy of CaptureSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? targetPackage = freezed,Object? targetLabel = freezed,Object? status = null,Object? screenshotPaths = null,Object? prompt = freezed,Object? errorMessage = freezed,Object? startedAt = freezed,Object? finishedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,targetPackage: freezed == targetPackage ? _self.targetPackage : targetPackage // ignore: cast_nullable_to_non_nullable
as String?,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CaptureStatus,screenshotPaths: null == screenshotPaths ? _self.screenshotPaths : screenshotPaths // ignore: cast_nullable_to_non_nullable
as List<String>,prompt: freezed == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CaptureSession].
extension CaptureSessionPatterns on CaptureSession {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CaptureSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CaptureSession() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CaptureSession value)  $default,){
final _that = this;
switch (_that) {
case _CaptureSession():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CaptureSession value)?  $default,){
final _that = this;
switch (_that) {
case _CaptureSession() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? targetPackage,  String? targetLabel,  CaptureStatus status,  List<String> screenshotPaths,  String? prompt,  String? errorMessage,  DateTime? startedAt,  DateTime? finishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CaptureSession() when $default != null:
return $default(_that.id,_that.targetPackage,_that.targetLabel,_that.status,_that.screenshotPaths,_that.prompt,_that.errorMessage,_that.startedAt,_that.finishedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? targetPackage,  String? targetLabel,  CaptureStatus status,  List<String> screenshotPaths,  String? prompt,  String? errorMessage,  DateTime? startedAt,  DateTime? finishedAt)  $default,) {final _that = this;
switch (_that) {
case _CaptureSession():
return $default(_that.id,_that.targetPackage,_that.targetLabel,_that.status,_that.screenshotPaths,_that.prompt,_that.errorMessage,_that.startedAt,_that.finishedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? targetPackage,  String? targetLabel,  CaptureStatus status,  List<String> screenshotPaths,  String? prompt,  String? errorMessage,  DateTime? startedAt,  DateTime? finishedAt)?  $default,) {final _that = this;
switch (_that) {
case _CaptureSession() when $default != null:
return $default(_that.id,_that.targetPackage,_that.targetLabel,_that.status,_that.screenshotPaths,_that.prompt,_that.errorMessage,_that.startedAt,_that.finishedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CaptureSession implements CaptureSession {
  const _CaptureSession({required this.id, this.targetPackage, this.targetLabel, this.status = CaptureStatus.idle, final  List<String> screenshotPaths = const [], this.prompt, this.errorMessage, this.startedAt, this.finishedAt}): _screenshotPaths = screenshotPaths;
  factory _CaptureSession.fromJson(Map<String, dynamic> json) => _$CaptureSessionFromJson(json);

@override final  String id;
@override final  String? targetPackage;
@override final  String? targetLabel;
@override@JsonKey() final  CaptureStatus status;
 final  List<String> _screenshotPaths;
@override@JsonKey() List<String> get screenshotPaths {
  if (_screenshotPaths is EqualUnmodifiableListView) return _screenshotPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_screenshotPaths);
}

@override final  String? prompt;
@override final  String? errorMessage;
@override final  DateTime? startedAt;
@override final  DateTime? finishedAt;

/// Create a copy of CaptureSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CaptureSessionCopyWith<_CaptureSession> get copyWith => __$CaptureSessionCopyWithImpl<_CaptureSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CaptureSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CaptureSession&&(identical(other.id, id) || other.id == id)&&(identical(other.targetPackage, targetPackage) || other.targetPackage == targetPackage)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._screenshotPaths, _screenshotPaths)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,targetPackage,targetLabel,status,const DeepCollectionEquality().hash(_screenshotPaths),prompt,errorMessage,startedAt,finishedAt);

@override
String toString() {
  return 'CaptureSession(id: $id, targetPackage: $targetPackage, targetLabel: $targetLabel, status: $status, screenshotPaths: $screenshotPaths, prompt: $prompt, errorMessage: $errorMessage, startedAt: $startedAt, finishedAt: $finishedAt)';
}


}

/// @nodoc
abstract mixin class _$CaptureSessionCopyWith<$Res> implements $CaptureSessionCopyWith<$Res> {
  factory _$CaptureSessionCopyWith(_CaptureSession value, $Res Function(_CaptureSession) _then) = __$CaptureSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String? targetPackage, String? targetLabel, CaptureStatus status, List<String> screenshotPaths, String? prompt, String? errorMessage, DateTime? startedAt, DateTime? finishedAt
});




}
/// @nodoc
class __$CaptureSessionCopyWithImpl<$Res>
    implements _$CaptureSessionCopyWith<$Res> {
  __$CaptureSessionCopyWithImpl(this._self, this._then);

  final _CaptureSession _self;
  final $Res Function(_CaptureSession) _then;

/// Create a copy of CaptureSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? targetPackage = freezed,Object? targetLabel = freezed,Object? status = null,Object? screenshotPaths = null,Object? prompt = freezed,Object? errorMessage = freezed,Object? startedAt = freezed,Object? finishedAt = freezed,}) {
  return _then(_CaptureSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,targetPackage: freezed == targetPackage ? _self.targetPackage : targetPackage // ignore: cast_nullable_to_non_nullable
as String?,targetLabel: freezed == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CaptureStatus,screenshotPaths: null == screenshotPaths ? _self._screenshotPaths : screenshotPaths // ignore: cast_nullable_to_non_nullable
as List<String>,prompt: freezed == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
