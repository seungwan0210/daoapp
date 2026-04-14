// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_log_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MyLogModel _$MyLogModelFromJson(Map<String, dynamic> json) {
  return _MyLogModel.fromJson(json);
}

/// @nodoc
mixin _$MyLogModel {
  String? get id => throw _privateConstructorUsedError;
  String get userId =>
      throw _privateConstructorUsedError; // 날짜는 반드시 있어야 하니까 non-null + 강한 컨버터
  @TimestampConverter()
  DateTime get date => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError; // 여러 장 지원
  List<String> get photoUrls => throw _privateConstructorUsedError; // 서클 공유 여부
  bool get isSharedToCircle =>
      throw _privateConstructorUsedError; // 생성일 (수정해도 변경되지 않음) - nullable
  @NullableTimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this MyLogModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MyLogModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MyLogModelCopyWith<MyLogModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyLogModelCopyWith<$Res> {
  factory $MyLogModelCopyWith(
          MyLogModel value, $Res Function(MyLogModel) then) =
      _$MyLogModelCopyWithImpl<$Res, MyLogModel>;
  @useResult
  $Res call(
      {String? id,
      String userId,
      @TimestampConverter() DateTime date,
      String? content,
      List<String> photoUrls,
      bool isSharedToCircle,
      @NullableTimestampConverter() DateTime? createdAt});
}

/// @nodoc
class _$MyLogModelCopyWithImpl<$Res, $Val extends MyLogModel>
    implements $MyLogModelCopyWith<$Res> {
  _$MyLogModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyLogModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userId = null,
    Object? date = null,
    Object? content = freezed,
    Object? photoUrls = null,
    Object? isSharedToCircle = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrls: null == photoUrls
          ? _value.photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isSharedToCircle: null == isSharedToCircle
          ? _value.isSharedToCircle
          : isSharedToCircle // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MyLogModelImplCopyWith<$Res>
    implements $MyLogModelCopyWith<$Res> {
  factory _$$MyLogModelImplCopyWith(
          _$MyLogModelImpl value, $Res Function(_$MyLogModelImpl) then) =
      __$$MyLogModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String userId,
      @TimestampConverter() DateTime date,
      String? content,
      List<String> photoUrls,
      bool isSharedToCircle,
      @NullableTimestampConverter() DateTime? createdAt});
}

/// @nodoc
class __$$MyLogModelImplCopyWithImpl<$Res>
    extends _$MyLogModelCopyWithImpl<$Res, _$MyLogModelImpl>
    implements _$$MyLogModelImplCopyWith<$Res> {
  __$$MyLogModelImplCopyWithImpl(
      _$MyLogModelImpl _value, $Res Function(_$MyLogModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of MyLogModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userId = null,
    Object? date = null,
    Object? content = freezed,
    Object? photoUrls = null,
    Object? isSharedToCircle = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$MyLogModelImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrls: null == photoUrls
          ? _value._photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isSharedToCircle: null == isSharedToCircle
          ? _value.isSharedToCircle
          : isSharedToCircle // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MyLogModelImpl implements _MyLogModel {
  const _$MyLogModelImpl(
      {this.id,
      required this.userId,
      @TimestampConverter() required this.date,
      this.content,
      final List<String> photoUrls = const [],
      this.isSharedToCircle = false,
      @NullableTimestampConverter() this.createdAt})
      : _photoUrls = photoUrls;

  factory _$MyLogModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MyLogModelImplFromJson(json);

  @override
  final String? id;
  @override
  final String userId;
// 날짜는 반드시 있어야 하니까 non-null + 강한 컨버터
  @override
  @TimestampConverter()
  final DateTime date;
  @override
  final String? content;
// 여러 장 지원
  final List<String> _photoUrls;
// 여러 장 지원
  @override
  @JsonKey()
  List<String> get photoUrls {
    if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photoUrls);
  }

// 서클 공유 여부
  @override
  @JsonKey()
  final bool isSharedToCircle;
// 생성일 (수정해도 변경되지 않음) - nullable
  @override
  @NullableTimestampConverter()
  final DateTime? createdAt;

  @override
  String toString() {
    return 'MyLogModel(id: $id, userId: $userId, date: $date, content: $content, photoUrls: $photoUrls, isSharedToCircle: $isSharedToCircle, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyLogModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality()
                .equals(other._photoUrls, _photoUrls) &&
            (identical(other.isSharedToCircle, isSharedToCircle) ||
                other.isSharedToCircle == isSharedToCircle) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      date,
      content,
      const DeepCollectionEquality().hash(_photoUrls),
      isSharedToCircle,
      createdAt);

  /// Create a copy of MyLogModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MyLogModelImplCopyWith<_$MyLogModelImpl> get copyWith =>
      __$$MyLogModelImplCopyWithImpl<_$MyLogModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MyLogModelImplToJson(
      this,
    );
  }
}

abstract class _MyLogModel implements MyLogModel {
  const factory _MyLogModel(
          {final String? id,
          required final String userId,
          @TimestampConverter() required final DateTime date,
          final String? content,
          final List<String> photoUrls,
          final bool isSharedToCircle,
          @NullableTimestampConverter() final DateTime? createdAt}) =
      _$MyLogModelImpl;

  factory _MyLogModel.fromJson(Map<String, dynamic> json) =
      _$MyLogModelImpl.fromJson;

  @override
  String? get id;
  @override
  String get userId; // 날짜는 반드시 있어야 하니까 non-null + 강한 컨버터
  @override
  @TimestampConverter()
  DateTime get date;
  @override
  String? get content; // 여러 장 지원
  @override
  List<String> get photoUrls; // 서클 공유 여부
  @override
  bool get isSharedToCircle; // 생성일 (수정해도 변경되지 않음) - nullable
  @override
  @NullableTimestampConverter()
  DateTime? get createdAt;

  /// Create a copy of MyLogModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyLogModelImplCopyWith<_$MyLogModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
