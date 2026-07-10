// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ui_clone_analysis.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UiCloneAnalysis {

 List<UiCloneColorToken> get palette; List<UiCloneScreenSpec> get screens; List<UiCloneComponentSpec> get components;/// Human-readable clone prompt (markdown).
 String get markdown;
/// Create a copy of UiCloneAnalysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UiCloneAnalysisCopyWith<UiCloneAnalysis> get copyWith => _$UiCloneAnalysisCopyWithImpl<UiCloneAnalysis>(this as UiCloneAnalysis, _$identity);

  /// Serializes this UiCloneAnalysis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UiCloneAnalysis&&const DeepCollectionEquality().equals(other.palette, palette)&&const DeepCollectionEquality().equals(other.screens, screens)&&const DeepCollectionEquality().equals(other.components, components)&&(identical(other.markdown, markdown) || other.markdown == markdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(palette),const DeepCollectionEquality().hash(screens),const DeepCollectionEquality().hash(components),markdown);

@override
String toString() {
  return 'UiCloneAnalysis(palette: $palette, screens: $screens, components: $components, markdown: $markdown)';
}


}

/// @nodoc
abstract mixin class $UiCloneAnalysisCopyWith<$Res>  {
  factory $UiCloneAnalysisCopyWith(UiCloneAnalysis value, $Res Function(UiCloneAnalysis) _then) = _$UiCloneAnalysisCopyWithImpl;
@useResult
$Res call({
 List<UiCloneColorToken> palette, List<UiCloneScreenSpec> screens, List<UiCloneComponentSpec> components, String markdown
});




}
/// @nodoc
class _$UiCloneAnalysisCopyWithImpl<$Res>
    implements $UiCloneAnalysisCopyWith<$Res> {
  _$UiCloneAnalysisCopyWithImpl(this._self, this._then);

  final UiCloneAnalysis _self;
  final $Res Function(UiCloneAnalysis) _then;

/// Create a copy of UiCloneAnalysis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? palette = null,Object? screens = null,Object? components = null,Object? markdown = null,}) {
  return _then(_self.copyWith(
palette: null == palette ? _self.palette : palette // ignore: cast_nullable_to_non_nullable
as List<UiCloneColorToken>,screens: null == screens ? _self.screens : screens // ignore: cast_nullable_to_non_nullable
as List<UiCloneScreenSpec>,components: null == components ? _self.components : components // ignore: cast_nullable_to_non_nullable
as List<UiCloneComponentSpec>,markdown: null == markdown ? _self.markdown : markdown // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UiCloneAnalysis].
extension UiCloneAnalysisPatterns on UiCloneAnalysis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UiCloneAnalysis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UiCloneAnalysis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UiCloneAnalysis value)  $default,){
final _that = this;
switch (_that) {
case _UiCloneAnalysis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UiCloneAnalysis value)?  $default,){
final _that = this;
switch (_that) {
case _UiCloneAnalysis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<UiCloneColorToken> palette,  List<UiCloneScreenSpec> screens,  List<UiCloneComponentSpec> components,  String markdown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UiCloneAnalysis() when $default != null:
return $default(_that.palette,_that.screens,_that.components,_that.markdown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<UiCloneColorToken> palette,  List<UiCloneScreenSpec> screens,  List<UiCloneComponentSpec> components,  String markdown)  $default,) {final _that = this;
switch (_that) {
case _UiCloneAnalysis():
return $default(_that.palette,_that.screens,_that.components,_that.markdown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<UiCloneColorToken> palette,  List<UiCloneScreenSpec> screens,  List<UiCloneComponentSpec> components,  String markdown)?  $default,) {final _that = this;
switch (_that) {
case _UiCloneAnalysis() when $default != null:
return $default(_that.palette,_that.screens,_that.components,_that.markdown);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UiCloneAnalysis implements UiCloneAnalysis {
  const _UiCloneAnalysis({final  List<UiCloneColorToken> palette = const [], final  List<UiCloneScreenSpec> screens = const [], final  List<UiCloneComponentSpec> components = const [], this.markdown = ''}): _palette = palette,_screens = screens,_components = components;
  factory _UiCloneAnalysis.fromJson(Map<String, dynamic> json) => _$UiCloneAnalysisFromJson(json);

 final  List<UiCloneColorToken> _palette;
@override@JsonKey() List<UiCloneColorToken> get palette {
  if (_palette is EqualUnmodifiableListView) return _palette;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_palette);
}

 final  List<UiCloneScreenSpec> _screens;
@override@JsonKey() List<UiCloneScreenSpec> get screens {
  if (_screens is EqualUnmodifiableListView) return _screens;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_screens);
}

 final  List<UiCloneComponentSpec> _components;
@override@JsonKey() List<UiCloneComponentSpec> get components {
  if (_components is EqualUnmodifiableListView) return _components;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_components);
}

/// Human-readable clone prompt (markdown).
@override@JsonKey() final  String markdown;

/// Create a copy of UiCloneAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UiCloneAnalysisCopyWith<_UiCloneAnalysis> get copyWith => __$UiCloneAnalysisCopyWithImpl<_UiCloneAnalysis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UiCloneAnalysisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UiCloneAnalysis&&const DeepCollectionEquality().equals(other._palette, _palette)&&const DeepCollectionEquality().equals(other._screens, _screens)&&const DeepCollectionEquality().equals(other._components, _components)&&(identical(other.markdown, markdown) || other.markdown == markdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_palette),const DeepCollectionEquality().hash(_screens),const DeepCollectionEquality().hash(_components),markdown);

@override
String toString() {
  return 'UiCloneAnalysis(palette: $palette, screens: $screens, components: $components, markdown: $markdown)';
}


}

/// @nodoc
abstract mixin class _$UiCloneAnalysisCopyWith<$Res> implements $UiCloneAnalysisCopyWith<$Res> {
  factory _$UiCloneAnalysisCopyWith(_UiCloneAnalysis value, $Res Function(_UiCloneAnalysis) _then) = __$UiCloneAnalysisCopyWithImpl;
@override @useResult
$Res call({
 List<UiCloneColorToken> palette, List<UiCloneScreenSpec> screens, List<UiCloneComponentSpec> components, String markdown
});




}
/// @nodoc
class __$UiCloneAnalysisCopyWithImpl<$Res>
    implements _$UiCloneAnalysisCopyWith<$Res> {
  __$UiCloneAnalysisCopyWithImpl(this._self, this._then);

  final _UiCloneAnalysis _self;
  final $Res Function(_UiCloneAnalysis) _then;

/// Create a copy of UiCloneAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? palette = null,Object? screens = null,Object? components = null,Object? markdown = null,}) {
  return _then(_UiCloneAnalysis(
palette: null == palette ? _self._palette : palette // ignore: cast_nullable_to_non_nullable
as List<UiCloneColorToken>,screens: null == screens ? _self._screens : screens // ignore: cast_nullable_to_non_nullable
as List<UiCloneScreenSpec>,components: null == components ? _self._components : components // ignore: cast_nullable_to_non_nullable
as List<UiCloneComponentSpec>,markdown: null == markdown ? _self.markdown : markdown // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$UiCloneColorToken {

 String get name; String get hex;
/// Create a copy of UiCloneColorToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UiCloneColorTokenCopyWith<UiCloneColorToken> get copyWith => _$UiCloneColorTokenCopyWithImpl<UiCloneColorToken>(this as UiCloneColorToken, _$identity);

  /// Serializes this UiCloneColorToken to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UiCloneColorToken&&(identical(other.name, name) || other.name == name)&&(identical(other.hex, hex) || other.hex == hex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,hex);

@override
String toString() {
  return 'UiCloneColorToken(name: $name, hex: $hex)';
}


}

/// @nodoc
abstract mixin class $UiCloneColorTokenCopyWith<$Res>  {
  factory $UiCloneColorTokenCopyWith(UiCloneColorToken value, $Res Function(UiCloneColorToken) _then) = _$UiCloneColorTokenCopyWithImpl;
@useResult
$Res call({
 String name, String hex
});




}
/// @nodoc
class _$UiCloneColorTokenCopyWithImpl<$Res>
    implements $UiCloneColorTokenCopyWith<$Res> {
  _$UiCloneColorTokenCopyWithImpl(this._self, this._then);

  final UiCloneColorToken _self;
  final $Res Function(UiCloneColorToken) _then;

/// Create a copy of UiCloneColorToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? hex = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hex: null == hex ? _self.hex : hex // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UiCloneColorToken].
extension UiCloneColorTokenPatterns on UiCloneColorToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UiCloneColorToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UiCloneColorToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UiCloneColorToken value)  $default,){
final _that = this;
switch (_that) {
case _UiCloneColorToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UiCloneColorToken value)?  $default,){
final _that = this;
switch (_that) {
case _UiCloneColorToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String hex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UiCloneColorToken() when $default != null:
return $default(_that.name,_that.hex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String hex)  $default,) {final _that = this;
switch (_that) {
case _UiCloneColorToken():
return $default(_that.name,_that.hex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String hex)?  $default,) {final _that = this;
switch (_that) {
case _UiCloneColorToken() when $default != null:
return $default(_that.name,_that.hex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UiCloneColorToken implements UiCloneColorToken {
  const _UiCloneColorToken({this.name = '', this.hex = ''});
  factory _UiCloneColorToken.fromJson(Map<String, dynamic> json) => _$UiCloneColorTokenFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String hex;

/// Create a copy of UiCloneColorToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UiCloneColorTokenCopyWith<_UiCloneColorToken> get copyWith => __$UiCloneColorTokenCopyWithImpl<_UiCloneColorToken>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UiCloneColorTokenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UiCloneColorToken&&(identical(other.name, name) || other.name == name)&&(identical(other.hex, hex) || other.hex == hex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,hex);

@override
String toString() {
  return 'UiCloneColorToken(name: $name, hex: $hex)';
}


}

/// @nodoc
abstract mixin class _$UiCloneColorTokenCopyWith<$Res> implements $UiCloneColorTokenCopyWith<$Res> {
  factory _$UiCloneColorTokenCopyWith(_UiCloneColorToken value, $Res Function(_UiCloneColorToken) _then) = __$UiCloneColorTokenCopyWithImpl;
@override @useResult
$Res call({
 String name, String hex
});




}
/// @nodoc
class __$UiCloneColorTokenCopyWithImpl<$Res>
    implements _$UiCloneColorTokenCopyWith<$Res> {
  __$UiCloneColorTokenCopyWithImpl(this._self, this._then);

  final _UiCloneColorToken _self;
  final $Res Function(_UiCloneColorToken) _then;

/// Create a copy of UiCloneColorToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? hex = null,}) {
  return _then(_UiCloneColorToken(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hex: null == hex ? _self.hex : hex // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$UiCloneScreenSpec {

 String get name; String get layout; List<String> get functions;
/// Create a copy of UiCloneScreenSpec
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UiCloneScreenSpecCopyWith<UiCloneScreenSpec> get copyWith => _$UiCloneScreenSpecCopyWithImpl<UiCloneScreenSpec>(this as UiCloneScreenSpec, _$identity);

  /// Serializes this UiCloneScreenSpec to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UiCloneScreenSpec&&(identical(other.name, name) || other.name == name)&&(identical(other.layout, layout) || other.layout == layout)&&const DeepCollectionEquality().equals(other.functions, functions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,layout,const DeepCollectionEquality().hash(functions));

@override
String toString() {
  return 'UiCloneScreenSpec(name: $name, layout: $layout, functions: $functions)';
}


}

/// @nodoc
abstract mixin class $UiCloneScreenSpecCopyWith<$Res>  {
  factory $UiCloneScreenSpecCopyWith(UiCloneScreenSpec value, $Res Function(UiCloneScreenSpec) _then) = _$UiCloneScreenSpecCopyWithImpl;
@useResult
$Res call({
 String name, String layout, List<String> functions
});




}
/// @nodoc
class _$UiCloneScreenSpecCopyWithImpl<$Res>
    implements $UiCloneScreenSpecCopyWith<$Res> {
  _$UiCloneScreenSpecCopyWithImpl(this._self, this._then);

  final UiCloneScreenSpec _self;
  final $Res Function(UiCloneScreenSpec) _then;

/// Create a copy of UiCloneScreenSpec
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? layout = null,Object? functions = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as String,functions: null == functions ? _self.functions : functions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [UiCloneScreenSpec].
extension UiCloneScreenSpecPatterns on UiCloneScreenSpec {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UiCloneScreenSpec value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UiCloneScreenSpec() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UiCloneScreenSpec value)  $default,){
final _that = this;
switch (_that) {
case _UiCloneScreenSpec():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UiCloneScreenSpec value)?  $default,){
final _that = this;
switch (_that) {
case _UiCloneScreenSpec() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String layout,  List<String> functions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UiCloneScreenSpec() when $default != null:
return $default(_that.name,_that.layout,_that.functions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String layout,  List<String> functions)  $default,) {final _that = this;
switch (_that) {
case _UiCloneScreenSpec():
return $default(_that.name,_that.layout,_that.functions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String layout,  List<String> functions)?  $default,) {final _that = this;
switch (_that) {
case _UiCloneScreenSpec() when $default != null:
return $default(_that.name,_that.layout,_that.functions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UiCloneScreenSpec implements UiCloneScreenSpec {
  const _UiCloneScreenSpec({this.name = '', this.layout = '', final  List<String> functions = const []}): _functions = functions;
  factory _UiCloneScreenSpec.fromJson(Map<String, dynamic> json) => _$UiCloneScreenSpecFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String layout;
 final  List<String> _functions;
@override@JsonKey() List<String> get functions {
  if (_functions is EqualUnmodifiableListView) return _functions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_functions);
}


/// Create a copy of UiCloneScreenSpec
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UiCloneScreenSpecCopyWith<_UiCloneScreenSpec> get copyWith => __$UiCloneScreenSpecCopyWithImpl<_UiCloneScreenSpec>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UiCloneScreenSpecToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UiCloneScreenSpec&&(identical(other.name, name) || other.name == name)&&(identical(other.layout, layout) || other.layout == layout)&&const DeepCollectionEquality().equals(other._functions, _functions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,layout,const DeepCollectionEquality().hash(_functions));

@override
String toString() {
  return 'UiCloneScreenSpec(name: $name, layout: $layout, functions: $functions)';
}


}

/// @nodoc
abstract mixin class _$UiCloneScreenSpecCopyWith<$Res> implements $UiCloneScreenSpecCopyWith<$Res> {
  factory _$UiCloneScreenSpecCopyWith(_UiCloneScreenSpec value, $Res Function(_UiCloneScreenSpec) _then) = __$UiCloneScreenSpecCopyWithImpl;
@override @useResult
$Res call({
 String name, String layout, List<String> functions
});




}
/// @nodoc
class __$UiCloneScreenSpecCopyWithImpl<$Res>
    implements _$UiCloneScreenSpecCopyWith<$Res> {
  __$UiCloneScreenSpecCopyWithImpl(this._self, this._then);

  final _UiCloneScreenSpec _self;
  final $Res Function(_UiCloneScreenSpec) _then;

/// Create a copy of UiCloneScreenSpec
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? layout = null,Object? functions = null,}) {
  return _then(_UiCloneScreenSpec(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as String,functions: null == functions ? _self._functions : functions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$UiCloneComponentSpec {

 String get name; String get description;
/// Create a copy of UiCloneComponentSpec
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UiCloneComponentSpecCopyWith<UiCloneComponentSpec> get copyWith => _$UiCloneComponentSpecCopyWithImpl<UiCloneComponentSpec>(this as UiCloneComponentSpec, _$identity);

  /// Serializes this UiCloneComponentSpec to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UiCloneComponentSpec&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description);

@override
String toString() {
  return 'UiCloneComponentSpec(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class $UiCloneComponentSpecCopyWith<$Res>  {
  factory $UiCloneComponentSpecCopyWith(UiCloneComponentSpec value, $Res Function(UiCloneComponentSpec) _then) = _$UiCloneComponentSpecCopyWithImpl;
@useResult
$Res call({
 String name, String description
});




}
/// @nodoc
class _$UiCloneComponentSpecCopyWithImpl<$Res>
    implements $UiCloneComponentSpecCopyWith<$Res> {
  _$UiCloneComponentSpecCopyWithImpl(this._self, this._then);

  final UiCloneComponentSpec _self;
  final $Res Function(UiCloneComponentSpec) _then;

/// Create a copy of UiCloneComponentSpec
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UiCloneComponentSpec].
extension UiCloneComponentSpecPatterns on UiCloneComponentSpec {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UiCloneComponentSpec value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UiCloneComponentSpec() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UiCloneComponentSpec value)  $default,){
final _that = this;
switch (_that) {
case _UiCloneComponentSpec():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UiCloneComponentSpec value)?  $default,){
final _that = this;
switch (_that) {
case _UiCloneComponentSpec() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UiCloneComponentSpec() when $default != null:
return $default(_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description)  $default,) {final _that = this;
switch (_that) {
case _UiCloneComponentSpec():
return $default(_that.name,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description)?  $default,) {final _that = this;
switch (_that) {
case _UiCloneComponentSpec() when $default != null:
return $default(_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UiCloneComponentSpec implements UiCloneComponentSpec {
  const _UiCloneComponentSpec({this.name = '', this.description = ''});
  factory _UiCloneComponentSpec.fromJson(Map<String, dynamic> json) => _$UiCloneComponentSpecFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String description;

/// Create a copy of UiCloneComponentSpec
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UiCloneComponentSpecCopyWith<_UiCloneComponentSpec> get copyWith => __$UiCloneComponentSpecCopyWithImpl<_UiCloneComponentSpec>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UiCloneComponentSpecToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UiCloneComponentSpec&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description);

@override
String toString() {
  return 'UiCloneComponentSpec(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$UiCloneComponentSpecCopyWith<$Res> implements $UiCloneComponentSpecCopyWith<$Res> {
  factory _$UiCloneComponentSpecCopyWith(_UiCloneComponentSpec value, $Res Function(_UiCloneComponentSpec) _then) = __$UiCloneComponentSpecCopyWithImpl;
@override @useResult
$Res call({
 String name, String description
});




}
/// @nodoc
class __$UiCloneComponentSpecCopyWithImpl<$Res>
    implements _$UiCloneComponentSpecCopyWith<$Res> {
  __$UiCloneComponentSpecCopyWithImpl(this._self, this._then);

  final _UiCloneComponentSpec _self;
  final $Res Function(_UiCloneComponentSpec) _then;

/// Create a copy of UiCloneComponentSpec
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,}) {
  return _then(_UiCloneComponentSpec(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
