// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'installed_app.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InstalledApp {

 String get packageName; String get label; String? get iconBase64; bool get isSystemApp;
/// Create a copy of InstalledApp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstalledAppCopyWith<InstalledApp> get copyWith => _$InstalledAppCopyWithImpl<InstalledApp>(this as InstalledApp, _$identity);

  /// Serializes this InstalledApp to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstalledApp&&(identical(other.packageName, packageName) || other.packageName == packageName)&&(identical(other.label, label) || other.label == label)&&(identical(other.iconBase64, iconBase64) || other.iconBase64 == iconBase64)&&(identical(other.isSystemApp, isSystemApp) || other.isSystemApp == isSystemApp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,packageName,label,iconBase64,isSystemApp);

@override
String toString() {
  return 'InstalledApp(packageName: $packageName, label: $label, iconBase64: $iconBase64, isSystemApp: $isSystemApp)';
}


}

/// @nodoc
abstract mixin class $InstalledAppCopyWith<$Res>  {
  factory $InstalledAppCopyWith(InstalledApp value, $Res Function(InstalledApp) _then) = _$InstalledAppCopyWithImpl;
@useResult
$Res call({
 String packageName, String label, String? iconBase64, bool isSystemApp
});




}
/// @nodoc
class _$InstalledAppCopyWithImpl<$Res>
    implements $InstalledAppCopyWith<$Res> {
  _$InstalledAppCopyWithImpl(this._self, this._then);

  final InstalledApp _self;
  final $Res Function(InstalledApp) _then;

/// Create a copy of InstalledApp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? packageName = null,Object? label = null,Object? iconBase64 = freezed,Object? isSystemApp = null,}) {
  return _then(_self.copyWith(
packageName: null == packageName ? _self.packageName : packageName // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,iconBase64: freezed == iconBase64 ? _self.iconBase64 : iconBase64 // ignore: cast_nullable_to_non_nullable
as String?,isSystemApp: null == isSystemApp ? _self.isSystemApp : isSystemApp // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [InstalledApp].
extension InstalledAppPatterns on InstalledApp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstalledApp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstalledApp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstalledApp value)  $default,){
final _that = this;
switch (_that) {
case _InstalledApp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstalledApp value)?  $default,){
final _that = this;
switch (_that) {
case _InstalledApp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String packageName,  String label,  String? iconBase64,  bool isSystemApp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstalledApp() when $default != null:
return $default(_that.packageName,_that.label,_that.iconBase64,_that.isSystemApp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String packageName,  String label,  String? iconBase64,  bool isSystemApp)  $default,) {final _that = this;
switch (_that) {
case _InstalledApp():
return $default(_that.packageName,_that.label,_that.iconBase64,_that.isSystemApp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String packageName,  String label,  String? iconBase64,  bool isSystemApp)?  $default,) {final _that = this;
switch (_that) {
case _InstalledApp() when $default != null:
return $default(_that.packageName,_that.label,_that.iconBase64,_that.isSystemApp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstalledApp implements InstalledApp {
  const _InstalledApp({required this.packageName, required this.label, this.iconBase64, this.isSystemApp = false});
  factory _InstalledApp.fromJson(Map<String, dynamic> json) => _$InstalledAppFromJson(json);

@override final  String packageName;
@override final  String label;
@override final  String? iconBase64;
@override@JsonKey() final  bool isSystemApp;

/// Create a copy of InstalledApp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstalledAppCopyWith<_InstalledApp> get copyWith => __$InstalledAppCopyWithImpl<_InstalledApp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstalledAppToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstalledApp&&(identical(other.packageName, packageName) || other.packageName == packageName)&&(identical(other.label, label) || other.label == label)&&(identical(other.iconBase64, iconBase64) || other.iconBase64 == iconBase64)&&(identical(other.isSystemApp, isSystemApp) || other.isSystemApp == isSystemApp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,packageName,label,iconBase64,isSystemApp);

@override
String toString() {
  return 'InstalledApp(packageName: $packageName, label: $label, iconBase64: $iconBase64, isSystemApp: $isSystemApp)';
}


}

/// @nodoc
abstract mixin class _$InstalledAppCopyWith<$Res> implements $InstalledAppCopyWith<$Res> {
  factory _$InstalledAppCopyWith(_InstalledApp value, $Res Function(_InstalledApp) _then) = __$InstalledAppCopyWithImpl;
@override @useResult
$Res call({
 String packageName, String label, String? iconBase64, bool isSystemApp
});




}
/// @nodoc
class __$InstalledAppCopyWithImpl<$Res>
    implements _$InstalledAppCopyWith<$Res> {
  __$InstalledAppCopyWithImpl(this._self, this._then);

  final _InstalledApp _self;
  final $Res Function(_InstalledApp) _then;

/// Create a copy of InstalledApp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? packageName = null,Object? label = null,Object? iconBase64 = freezed,Object? isSystemApp = null,}) {
  return _then(_InstalledApp(
packageName: null == packageName ? _self.packageName : packageName // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,iconBase64: freezed == iconBase64 ? _self.iconBase64 : iconBase64 // ignore: cast_nullable_to_non_nullable
as String?,isSystemApp: null == isSystemApp ? _self.isSystemApp : isSystemApp // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
