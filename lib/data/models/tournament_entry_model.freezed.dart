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

TeamMember _$TeamMemberFromJson(Map<String, dynamic> json) {
  return _TeamMember.fromJson(json);
}

/// @nodoc
mixin _$TeamMember {
  String get name => throw _privateConstructorUsedError;
  String get rating =>
      throw _privateConstructorUsedError; // ✅ 각 팀원별 추가 질문에 대한 답변 (예: {"상의 사이즈": "L"})
  Map<String, String> get customAnswers => throw _privateConstructorUsedError;

  /// Serializes this TeamMember to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeamMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeamMemberCopyWith<TeamMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamMemberCopyWith<$Res> {
  factory $TeamMemberCopyWith(
          TeamMember value, $Res Function(TeamMember) then) =
      _$TeamMemberCopyWithImpl<$Res, TeamMember>;
  @useResult
  $Res call({String name, String rating, Map<String, String> customAnswers});
}

/// @nodoc
class _$TeamMemberCopyWithImpl<$Res, $Val extends TeamMember>
    implements $TeamMemberCopyWith<$Res> {
  _$TeamMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeamMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? rating = null,
    Object? customAnswers = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as String,
      customAnswers: null == customAnswers
          ? _value.customAnswers
          : customAnswers // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TeamMemberImplCopyWith<$Res>
    implements $TeamMemberCopyWith<$Res> {
  factory _$$TeamMemberImplCopyWith(
          _$TeamMemberImpl value, $Res Function(_$TeamMemberImpl) then) =
      __$$TeamMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String rating, Map<String, String> customAnswers});
}

/// @nodoc
class __$$TeamMemberImplCopyWithImpl<$Res>
    extends _$TeamMemberCopyWithImpl<$Res, _$TeamMemberImpl>
    implements _$$TeamMemberImplCopyWith<$Res> {
  __$$TeamMemberImplCopyWithImpl(
      _$TeamMemberImpl _value, $Res Function(_$TeamMemberImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? rating = null,
    Object? customAnswers = null,
  }) {
    return _then(_$TeamMemberImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as String,
      customAnswers: null == customAnswers
          ? _value._customAnswers
          : customAnswers // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TeamMemberImpl implements _TeamMember {
  const _$TeamMemberImpl(
      {required this.name,
      required this.rating,
      final Map<String, String> customAnswers = const {}})
      : _customAnswers = customAnswers;

  factory _$TeamMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamMemberImplFromJson(json);

  @override
  final String name;
  @override
  final String rating;
// ✅ 각 팀원별 추가 질문에 대한 답변 (예: {"상의 사이즈": "L"})
  final Map<String, String> _customAnswers;
// ✅ 각 팀원별 추가 질문에 대한 답변 (예: {"상의 사이즈": "L"})
  @override
  @JsonKey()
  Map<String, String> get customAnswers {
    if (_customAnswers is EqualUnmodifiableMapView) return _customAnswers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customAnswers);
  }

  @override
  String toString() {
    return 'TeamMember(name: $name, rating: $rating, customAnswers: $customAnswers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamMemberImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            const DeepCollectionEquality()
                .equals(other._customAnswers, _customAnswers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, rating,
      const DeepCollectionEquality().hash(_customAnswers));

  /// Create a copy of TeamMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamMemberImplCopyWith<_$TeamMemberImpl> get copyWith =>
      __$$TeamMemberImplCopyWithImpl<_$TeamMemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamMemberImplToJson(
      this,
    );
  }
}

abstract class _TeamMember implements TeamMember {
  const factory _TeamMember(
      {required final String name,
      required final String rating,
      final Map<String, String> customAnswers}) = _$TeamMemberImpl;

  factory _TeamMember.fromJson(Map<String, dynamic> json) =
      _$TeamMemberImpl.fromJson;

  @override
  String get name;
  @override
  String get rating; // ✅ 각 팀원별 추가 질문에 대한 답변 (예: {"상의 사이즈": "L"})
  @override
  Map<String, String> get customAnswers;

  /// Create a copy of TeamMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamMemberImplCopyWith<_$TeamMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TournamentEntryModel _$TournamentEntryModelFromJson(Map<String, dynamic> json) {
  return _TournamentEntryModel.fromJson(json);
}

/// @nodoc
mixin _$TournamentEntryModel {
  String? get id => throw _privateConstructorUsedError;
  String get userUid => throw _privateConstructorUsedError; // 신청자(팀장) 고유 UID
// --- 대표자(팀장) 정보 ---
  String get nameKo => throw _privateConstructorUsedError;
  String get nameEn => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get rating => throw _privateConstructorUsedError;
  String? get homeShop =>
      throw _privateConstructorUsedError; // --- 팀전 전용 정보 ---
  String? get teamName => throw _privateConstructorUsedError;
  List<TeamMember> get members => throw _privateConstructorUsedError; // 팀원 목록
  String? get totalRating =>
      throw _privateConstructorUsedError; // ✅ 팀장(본인)의 추가 질문에 대한 답변
  Map<String, String> get customAnswers => throw _privateConstructorUsedError;
  @TimestampConverter()
  Timestamp get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  Timestamp? get updatedAt => throw _privateConstructorUsedError;
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
      String? teamName,
      List<TeamMember> members,
      String? totalRating,
      Map<String, String> customAnswers,
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
    Object? teamName = freezed,
    Object? members = null,
    Object? totalRating = freezed,
    Object? customAnswers = null,
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
      teamName: freezed == teamName
          ? _value.teamName
          : teamName // ignore: cast_nullable_to_non_nullable
              as String?,
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<TeamMember>,
      totalRating: freezed == totalRating
          ? _value.totalRating
          : totalRating // ignore: cast_nullable_to_non_nullable
              as String?,
      customAnswers: null == customAnswers
          ? _value.customAnswers
          : customAnswers // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
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
      String? teamName,
      List<TeamMember> members,
      String? totalRating,
      Map<String, String> customAnswers,
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
    Object? teamName = freezed,
    Object? members = null,
    Object? totalRating = freezed,
    Object? customAnswers = null,
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
      teamName: freezed == teamName
          ? _value.teamName
          : teamName // ignore: cast_nullable_to_non_nullable
              as String?,
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<TeamMember>,
      totalRating: freezed == totalRating
          ? _value.totalRating
          : totalRating // ignore: cast_nullable_to_non_nullable
              as String?,
      customAnswers: null == customAnswers
          ? _value._customAnswers
          : customAnswers // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
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

@JsonSerializable(explicitToJson: true)
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
      this.teamName,
      final List<TeamMember> members = const [],
      this.totalRating,
      final Map<String, String> customAnswers = const {},
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() this.updatedAt,
      this.status = 'applied'})
      : _members = members,
        _customAnswers = customAnswers;

  factory _$TournamentEntryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TournamentEntryModelImplFromJson(json);

  @override
  final String? id;
  @override
  final String userUid;
// 신청자(팀장) 고유 UID
// --- 대표자(팀장) 정보 ---
  @override
  final String nameKo;
  @override
  final String nameEn;
  @override
  final String phone;
  @override
  final String? email;
  @override
  final String? rating;
  @override
  final String? homeShop;
// --- 팀전 전용 정보 ---
  @override
  final String? teamName;
  final List<TeamMember> _members;
  @override
  @JsonKey()
  List<TeamMember> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

// 팀원 목록
  @override
  final String? totalRating;
// ✅ 팀장(본인)의 추가 질문에 대한 답변
  final Map<String, String> _customAnswers;
// ✅ 팀장(본인)의 추가 질문에 대한 답변
  @override
  @JsonKey()
  Map<String, String> get customAnswers {
    if (_customAnswers is EqualUnmodifiableMapView) return _customAnswers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customAnswers);
  }

  @override
  @TimestampConverter()
  final Timestamp createdAt;
  @override
  @TimestampConverter()
  final Timestamp? updatedAt;
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'TournamentEntryModel(id: $id, userUid: $userUid, nameKo: $nameKo, nameEn: $nameEn, phone: $phone, email: $email, rating: $rating, homeShop: $homeShop, teamName: $teamName, members: $members, totalRating: $totalRating, customAnswers: $customAnswers, createdAt: $createdAt, updatedAt: $updatedAt, status: $status)';
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
            (identical(other.teamName, teamName) ||
                other.teamName == teamName) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.totalRating, totalRating) ||
                other.totalRating == totalRating) &&
            const DeepCollectionEquality()
                .equals(other._customAnswers, _customAnswers) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userUid,
      nameKo,
      nameEn,
      phone,
      email,
      rating,
      homeShop,
      teamName,
      const DeepCollectionEquality().hash(_members),
      totalRating,
      const DeepCollectionEquality().hash(_customAnswers),
      createdAt,
      updatedAt,
      status);

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
      final String? teamName,
      final List<TeamMember> members,
      final String? totalRating,
      final Map<String, String> customAnswers,
      @TimestampConverter() required final Timestamp createdAt,
      @TimestampConverter() final Timestamp? updatedAt,
      final String status}) = _$TournamentEntryModelImpl;

  factory _TournamentEntryModel.fromJson(Map<String, dynamic> json) =
      _$TournamentEntryModelImpl.fromJson;

  @override
  String? get id;
  @override
  String get userUid; // 신청자(팀장) 고유 UID
// --- 대표자(팀장) 정보 ---
  @override
  String get nameKo;
  @override
  String get nameEn;
  @override
  String get phone;
  @override
  String? get email;
  @override
  String? get rating;
  @override
  String? get homeShop; // --- 팀전 전용 정보 ---
  @override
  String? get teamName;
  @override
  List<TeamMember> get members; // 팀원 목록
  @override
  String? get totalRating; // ✅ 팀장(본인)의 추가 질문에 대한 답변
  @override
  Map<String, String> get customAnswers;
  @override
  @TimestampConverter()
  Timestamp get createdAt;
  @override
  @TimestampConverter()
  Timestamp? get updatedAt;
  @override
  String get status;

  /// Create a copy of TournamentEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TournamentEntryModelImplCopyWith<_$TournamentEntryModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
