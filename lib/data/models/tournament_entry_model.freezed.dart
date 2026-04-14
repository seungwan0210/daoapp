// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tournament_entry_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TournamentEntryModel _$TournamentEntryModelFromJson(Map<String, dynamic> json) {
  return _TournamentEntryModel.fromJson(json);
}

/// @nodoc
mixin _$TournamentEntryModel {
  /// Firestore document ID (doc.id)
  String? get id => throw _privateConstructorUsedError;

  /// 참가자 유저 UID (entries/{userUid} = userUid 정책이면 사실상 key)
  String get userUid => throw _privateConstructorUsedError;

  /// 한글 이름
  String get nameKo => throw _privateConstructorUsedError;

  /// 영문 이름
  String get nameEn => throw _privateConstructorUsedError;

  /// 연락처
  String get phone => throw _privateConstructorUsedError;

  /// 이메일 (로그인 이메일, 없을 수도 있음)
  String? get email => throw _privateConstructorUsedError;

  /// 레이팅 (선택)
  String? get rating => throw _privateConstructorUsedError;

  /// 홈샵 (선택)
  String? get homeShop => throw _privateConstructorUsedError;

  /// 신청 시간
  @TimestampConverter()
  Timestamp get createdAt => throw _privateConstructorUsedError;

  /// (권장) 수정 시간
  @TimestampConverter()
  Timestamp? get updatedAt => throw _privateConstructorUsedError;

  /// (권장) 운영 상태값 (지금 당장은 없어도 됨)
  String get status => throw _privateConstructorUsedError;

  /// Serializes this TournamentEntryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TournamentEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TournamentEntryModelCopyWith<TournamentEntryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TournamentEntryModelCopyWith<$Res> {
  factory $TournamentEntryModelCopyWith(TournamentEntryModel value,
          $Res Function(TournamentEntryModel) then) =
      _$TournamentEntryModelCopyWithImpl<$Res, TournamentEntryModel>;
  @useResult
  $Res call(
      {String? id,
      String userUid,
      String nameKo,
      String nameEn,
      String phone,
      String? email,
      String? rating,
      String? homeShop,
      @TimestampConverter() Timestamp createdAt,
      @TimestampConverter() Timestamp? updatedAt,
      String status});
}

/// @nodoc
class _$TournamentEntryModelCopyWithImpl<$Res,
        $Val extends TournamentEntryModel>
    implements $TournamentEntryModelCopyWith<$Res> {
  _$TournamentEntryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TournamentEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userUid = null,
    Object? nameKo = null,
    Object? nameEn = null,
    Object? phone = null,
    Object? email = freezed,
    Object? rating = freezed,
    Object? homeShop = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      userUid: null == userUid
          ? _value.userUid
          : userUid // ignore: cast_nullable_to_non_nullable
              as String,
      nameKo: null == nameKo
          ? _value.nameKo
          : nameKo // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as String?,
      homeShop: freezed == homeShop
          ? _value.homeShop
          : homeShop // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as Timestamp?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TournamentEntryModelImplCopyWith<$Res>
    implements $TournamentEntryModelCopyWith<$Res> {
  factory _$$TournamentEntryModelImplCopyWith(_$TournamentEntryModelImpl value,
          $Res Function(_$TournamentEntryModelImpl) then) =
      __$$TournamentEntryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String userUid,
      String nameKo,
      String nameEn,
      String phone,
      String? email,
      String? rating,
      String? homeShop,
      @TimestampConverter() Timestamp createdAt,
      @TimestampConverter() Timestamp? updatedAt,
      String status});
}

/// @nodoc
class __$$TournamentEntryModelImplCopyWithImpl<$Res>
    extends _$TournamentEntryModelCopyWithImpl<$Res, _$TournamentEntryModelImpl>
    implements _$$TournamentEntryModelImplCopyWith<$Res> {
  __$$TournamentEntryModelImplCopyWithImpl(_$TournamentEntryModelImpl _value,
      $Res Function(_$TournamentEntryModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of TournamentEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userUid = null,
    Object? nameKo = null,
    Object? nameEn = null,
    Object? phone = null,
    Object? email = freezed,
    Object? rating = freezed,
    Object? homeShop = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? status = null,
  }) {
    return _then(_$TournamentEntryModelImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      userUid: null == userUid
          ? _value.userUid
          : userUid // ignore: cast_nullable_to_non_nullable
              as String,
      nameKo: null == nameKo
          ? _value.nameKo
          : nameKo // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as String?,
      homeShop: freezed == homeShop
          ? _value.homeShop
          : homeShop // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as Timestamp?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TournamentEntryModelImpl implements _TournamentEntryModel {
  const _$TournamentEntryModelImpl(
      {this.id,
      required this.userUid,
      required this.nameKo,
      required this.nameEn,
      required this.phone,
      this.email,
      this.rating,
      this.homeShop,
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() this.updatedAt,
      this.status = 'applied'});

  factory _$TournamentEntryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TournamentEntryModelImplFromJson(json);

  /// Firestore document ID (doc.id)
  @override
  final String? id;

  /// 참가자 유저 UID (entries/{userUid} = userUid 정책이면 사실상 key)
  @override
  final String userUid;

  /// 한글 이름
  @override
  final String nameKo;

  /// 영문 이름
  @override
  final String nameEn;

  /// 연락처
  @override
  final String phone;

  /// 이메일 (로그인 이메일, 없을 수도 있음)
  @override
  final String? email;

  /// 레이팅 (선택)
  @override
  final String? rating;

  /// 홈샵 (선택)
  @override
  final String? homeShop;

  /// 신청 시간
  @override
  @TimestampConverter()
  final Timestamp createdAt;

  /// (권장) 수정 시간
  @override
  @TimestampConverter()
  final Timestamp? updatedAt;

  /// (권장) 운영 상태값 (지금 당장은 없어도 됨)
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'TournamentEntryModel(id: $id, userUid: $userUid, nameKo: $nameKo, nameEn: $nameEn, phone: $phone, email: $email, rating: $rating, homeShop: $homeShop, createdAt: $createdAt, updatedAt: $updatedAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TournamentEntryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userUid, userUid) || other.userUid == userUid) &&
            (identical(other.nameKo, nameKo) || other.nameKo == nameKo) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.homeShop, homeShop) ||
                other.homeShop == homeShop) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userUid, nameKo, nameEn,
      phone, email, rating, homeShop, createdAt, updatedAt, status);

  /// Create a copy of TournamentEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TournamentEntryModelImplCopyWith<_$TournamentEntryModelImpl>
      get copyWith =>
          __$$TournamentEntryModelImplCopyWithImpl<_$TournamentEntryModelImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TournamentEntryModelImplToJson(
      this,
    );
  }
}

abstract class _TournamentEntryModel implements TournamentEntryModel {
  const factory _TournamentEntryModel(
      {final String? id,
      required final String userUid,
      required final String nameKo,
      required final String nameEn,
      required final String phone,
      final String? email,
      final String? rating,
      final String? homeShop,
      @TimestampConverter() required final Timestamp createdAt,
      @TimestampConverter() final Timestamp? updatedAt,
      final String status}) = _$TournamentEntryModelImpl;

  factory _TournamentEntryModel.fromJson(Map<String, dynamic> json) =
      _$TournamentEntryModelImpl.fromJson;

  /// Firestore document ID (doc.id)
  @override
  String? get id;

  /// 참가자 유저 UID (entries/{userUid} = userUid 정책이면 사실상 key)
  @override
  String get userUid;

  /// 한글 이름
  @override
  String get nameKo;

  /// 영문 이름
  @override
  String get nameEn;

  /// 연락처
  @override
  String get phone;

  /// 이메일 (로그인 이메일, 없을 수도 있음)
  @override
  String? get email;

  /// 레이팅 (선택)
  @override
  String? get rating;

  /// 홈샵 (선택)
  @override
  String? get homeShop;

  /// 신청 시간
  @override
  @TimestampConverter()
  Timestamp get createdAt;

  /// (권장) 수정 시간
  @override
  @TimestampConverter()
  Timestamp? get updatedAt;

  /// (권장) 운영 상태값 (지금 당장은 없어도 됨)
  @override
  String get status;

  /// Create a copy of TournamentEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TournamentEntryModelImplCopyWith<_$TournamentEntryModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
