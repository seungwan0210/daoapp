// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tournament_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TournamentModel _$TournamentModelFromJson(Map<String, dynamic> json) {
  return _TournamentModel.fromJson(json);
}

/// @nodoc
mixin _$TournamentModel {
  String? get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  int get maxParticipants => throw _privateConstructorUsedError;
  String? get posterUrl => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get entryFee => throw _privateConstructorUsedError;
  @TimestampConverter()
  Timestamp get eventDate => throw _privateConstructorUsedError;
  @TimestampConverter()
  Timestamp get entryStartDate => throw _privateConstructorUsedError;
  @TimestampConverter()
  Timestamp get entryEndDate => throw _privateConstructorUsedError;
  String get createdByUid => throw _privateConstructorUsedError;
  List<String> get organizerEmails => throw _privateConstructorUsedError;
  String get hostName => throw _privateConstructorUsedError;
  String get hostPhone => throw _privateConstructorUsedError;
  int get entryCount => throw _privateConstructorUsedError;
  bool get entrySummarySent => throw _privateConstructorUsedError;
  bool get isCanceled => throw _privateConstructorUsedError;
  @TimestampConverter()
  Timestamp get createdAt => throw _privateConstructorUsedError; // ✅ 추가 권장
  @TimestampConverter()
  Timestamp? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TournamentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TournamentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TournamentModelCopyWith<TournamentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TournamentModelCopyWith<$Res> {
  factory $TournamentModelCopyWith(
          TournamentModel value, $Res Function(TournamentModel) then) =
      _$TournamentModelCopyWithImpl<$Res, TournamentModel>;
  @useResult
  $Res call(
      {String? id,
      String title,
      String location,
      int maxParticipants,
      String? posterUrl,
      String description,
      int entryFee,
      @TimestampConverter() Timestamp eventDate,
      @TimestampConverter() Timestamp entryStartDate,
      @TimestampConverter() Timestamp entryEndDate,
      String createdByUid,
      List<String> organizerEmails,
      String hostName,
      String hostPhone,
      int entryCount,
      bool entrySummarySent,
      bool isCanceled,
      @TimestampConverter() Timestamp createdAt,
      @TimestampConverter() Timestamp? updatedAt});
}

/// @nodoc
class _$TournamentModelCopyWithImpl<$Res, $Val extends TournamentModel>
    implements $TournamentModelCopyWith<$Res> {
  _$TournamentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TournamentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? location = null,
    Object? maxParticipants = null,
    Object? posterUrl = freezed,
    Object? description = null,
    Object? entryFee = null,
    Object? eventDate = null,
    Object? entryStartDate = null,
    Object? entryEndDate = null,
    Object? createdByUid = null,
    Object? organizerEmails = null,
    Object? hostName = null,
    Object? hostPhone = null,
    Object? entryCount = null,
    Object? entrySummarySent = null,
    Object? isCanceled = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      maxParticipants: null == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      posterUrl: freezed == posterUrl
          ? _value.posterUrl
          : posterUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      entryFee: null == entryFee
          ? _value.entryFee
          : entryFee // ignore: cast_nullable_to_non_nullable
              as int,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      entryStartDate: null == entryStartDate
          ? _value.entryStartDate
          : entryStartDate // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      entryEndDate: null == entryEndDate
          ? _value.entryEndDate
          : entryEndDate // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      createdByUid: null == createdByUid
          ? _value.createdByUid
          : createdByUid // ignore: cast_nullable_to_non_nullable
              as String,
      organizerEmails: null == organizerEmails
          ? _value.organizerEmails
          : organizerEmails // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hostName: null == hostName
          ? _value.hostName
          : hostName // ignore: cast_nullable_to_non_nullable
              as String,
      hostPhone: null == hostPhone
          ? _value.hostPhone
          : hostPhone // ignore: cast_nullable_to_non_nullable
              as String,
      entryCount: null == entryCount
          ? _value.entryCount
          : entryCount // ignore: cast_nullable_to_non_nullable
              as int,
      entrySummarySent: null == entrySummarySent
          ? _value.entrySummarySent
          : entrySummarySent // ignore: cast_nullable_to_non_nullable
              as bool,
      isCanceled: null == isCanceled
          ? _value.isCanceled
          : isCanceled // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as Timestamp?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TournamentModelImplCopyWith<$Res>
    implements $TournamentModelCopyWith<$Res> {
  factory _$$TournamentModelImplCopyWith(_$TournamentModelImpl value,
          $Res Function(_$TournamentModelImpl) then) =
      __$$TournamentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String title,
      String location,
      int maxParticipants,
      String? posterUrl,
      String description,
      int entryFee,
      @TimestampConverter() Timestamp eventDate,
      @TimestampConverter() Timestamp entryStartDate,
      @TimestampConverter() Timestamp entryEndDate,
      String createdByUid,
      List<String> organizerEmails,
      String hostName,
      String hostPhone,
      int entryCount,
      bool entrySummarySent,
      bool isCanceled,
      @TimestampConverter() Timestamp createdAt,
      @TimestampConverter() Timestamp? updatedAt});
}

/// @nodoc
class __$$TournamentModelImplCopyWithImpl<$Res>
    extends _$TournamentModelCopyWithImpl<$Res, _$TournamentModelImpl>
    implements _$$TournamentModelImplCopyWith<$Res> {
  __$$TournamentModelImplCopyWithImpl(
      _$TournamentModelImpl _value, $Res Function(_$TournamentModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of TournamentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? location = null,
    Object? maxParticipants = null,
    Object? posterUrl = freezed,
    Object? description = null,
    Object? entryFee = null,
    Object? eventDate = null,
    Object? entryStartDate = null,
    Object? entryEndDate = null,
    Object? createdByUid = null,
    Object? organizerEmails = null,
    Object? hostName = null,
    Object? hostPhone = null,
    Object? entryCount = null,
    Object? entrySummarySent = null,
    Object? isCanceled = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$TournamentModelImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      maxParticipants: null == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      posterUrl: freezed == posterUrl
          ? _value.posterUrl
          : posterUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      entryFee: null == entryFee
          ? _value.entryFee
          : entryFee // ignore: cast_nullable_to_non_nullable
              as int,
      eventDate: null == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      entryStartDate: null == entryStartDate
          ? _value.entryStartDate
          : entryStartDate // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      entryEndDate: null == entryEndDate
          ? _value.entryEndDate
          : entryEndDate // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      createdByUid: null == createdByUid
          ? _value.createdByUid
          : createdByUid // ignore: cast_nullable_to_non_nullable
              as String,
      organizerEmails: null == organizerEmails
          ? _value._organizerEmails
          : organizerEmails // ignore: cast_nullable_to_non_nullable
              as List<String>,
      hostName: null == hostName
          ? _value.hostName
          : hostName // ignore: cast_nullable_to_non_nullable
              as String,
      hostPhone: null == hostPhone
          ? _value.hostPhone
          : hostPhone // ignore: cast_nullable_to_non_nullable
              as String,
      entryCount: null == entryCount
          ? _value.entryCount
          : entryCount // ignore: cast_nullable_to_non_nullable
              as int,
      entrySummarySent: null == entrySummarySent
          ? _value.entrySummarySent
          : entrySummarySent // ignore: cast_nullable_to_non_nullable
              as bool,
      isCanceled: null == isCanceled
          ? _value.isCanceled
          : isCanceled // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as Timestamp,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as Timestamp?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TournamentModelImpl implements _TournamentModel {
  const _$TournamentModelImpl(
      {this.id,
      required this.title,
      required this.location,
      required this.maxParticipants,
      this.posterUrl,
      required this.description,
      this.entryFee = 0,
      @TimestampConverter() required this.eventDate,
      @TimestampConverter() required this.entryStartDate,
      @TimestampConverter() required this.entryEndDate,
      required this.createdByUid,
      required final List<String> organizerEmails,
      this.hostName = '',
      this.hostPhone = '',
      this.entryCount = 0,
      this.entrySummarySent = false,
      this.isCanceled = false,
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() this.updatedAt})
      : _organizerEmails = organizerEmails;

  factory _$TournamentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TournamentModelImplFromJson(json);

  @override
  final String? id;
  @override
  final String title;
  @override
  final String location;
  @override
  final int maxParticipants;
  @override
  final String? posterUrl;
  @override
  final String description;
  @override
  @JsonKey()
  final int entryFee;
  @override
  @TimestampConverter()
  final Timestamp eventDate;
  @override
  @TimestampConverter()
  final Timestamp entryStartDate;
  @override
  @TimestampConverter()
  final Timestamp entryEndDate;
  @override
  final String createdByUid;
  final List<String> _organizerEmails;
  @override
  List<String> get organizerEmails {
    if (_organizerEmails is EqualUnmodifiableListView) return _organizerEmails;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_organizerEmails);
  }

  @override
  @JsonKey()
  final String hostName;
  @override
  @JsonKey()
  final String hostPhone;
  @override
  @JsonKey()
  final int entryCount;
  @override
  @JsonKey()
  final bool entrySummarySent;
  @override
  @JsonKey()
  final bool isCanceled;
  @override
  @TimestampConverter()
  final Timestamp createdAt;
// ✅ 추가 권장
  @override
  @TimestampConverter()
  final Timestamp? updatedAt;

  @override
  String toString() {
    return 'TournamentModel(id: $id, title: $title, location: $location, maxParticipants: $maxParticipants, posterUrl: $posterUrl, description: $description, entryFee: $entryFee, eventDate: $eventDate, entryStartDate: $entryStartDate, entryEndDate: $entryEndDate, createdByUid: $createdByUid, organizerEmails: $organizerEmails, hostName: $hostName, hostPhone: $hostPhone, entryCount: $entryCount, entrySummarySent: $entrySummarySent, isCanceled: $isCanceled, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TournamentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.maxParticipants, maxParticipants) ||
                other.maxParticipants == maxParticipants) &&
            (identical(other.posterUrl, posterUrl) ||
                other.posterUrl == posterUrl) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.entryFee, entryFee) ||
                other.entryFee == entryFee) &&
            (identical(other.eventDate, eventDate) ||
                other.eventDate == eventDate) &&
            (identical(other.entryStartDate, entryStartDate) ||
                other.entryStartDate == entryStartDate) &&
            (identical(other.entryEndDate, entryEndDate) ||
                other.entryEndDate == entryEndDate) &&
            (identical(other.createdByUid, createdByUid) ||
                other.createdByUid == createdByUid) &&
            const DeepCollectionEquality()
                .equals(other._organizerEmails, _organizerEmails) &&
            (identical(other.hostName, hostName) ||
                other.hostName == hostName) &&
            (identical(other.hostPhone, hostPhone) ||
                other.hostPhone == hostPhone) &&
            (identical(other.entryCount, entryCount) ||
                other.entryCount == entryCount) &&
            (identical(other.entrySummarySent, entrySummarySent) ||
                other.entrySummarySent == entrySummarySent) &&
            (identical(other.isCanceled, isCanceled) ||
                other.isCanceled == isCanceled) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        title,
        location,
        maxParticipants,
        posterUrl,
        description,
        entryFee,
        eventDate,
        entryStartDate,
        entryEndDate,
        createdByUid,
        const DeepCollectionEquality().hash(_organizerEmails),
        hostName,
        hostPhone,
        entryCount,
        entrySummarySent,
        isCanceled,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of TournamentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TournamentModelImplCopyWith<_$TournamentModelImpl> get copyWith =>
      __$$TournamentModelImplCopyWithImpl<_$TournamentModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TournamentModelImplToJson(
      this,
    );
  }
}

abstract class _TournamentModel implements TournamentModel {
  const factory _TournamentModel(
          {final String? id,
          required final String title,
          required final String location,
          required final int maxParticipants,
          final String? posterUrl,
          required final String description,
          final int entryFee,
          @TimestampConverter() required final Timestamp eventDate,
          @TimestampConverter() required final Timestamp entryStartDate,
          @TimestampConverter() required final Timestamp entryEndDate,
          required final String createdByUid,
          required final List<String> organizerEmails,
          final String hostName,
          final String hostPhone,
          final int entryCount,
          final bool entrySummarySent,
          final bool isCanceled,
          @TimestampConverter() required final Timestamp createdAt,
          @TimestampConverter() final Timestamp? updatedAt}) =
      _$TournamentModelImpl;

  factory _TournamentModel.fromJson(Map<String, dynamic> json) =
      _$TournamentModelImpl.fromJson;

  @override
  String? get id;
  @override
  String get title;
  @override
  String get location;
  @override
  int get maxParticipants;
  @override
  String? get posterUrl;
  @override
  String get description;
  @override
  int get entryFee;
  @override
  @TimestampConverter()
  Timestamp get eventDate;
  @override
  @TimestampConverter()
  Timestamp get entryStartDate;
  @override
  @TimestampConverter()
  Timestamp get entryEndDate;
  @override
  String get createdByUid;
  @override
  List<String> get organizerEmails;
  @override
  String get hostName;
  @override
  String get hostPhone;
  @override
  int get entryCount;
  @override
  bool get entrySummarySent;
  @override
  bool get isCanceled;
  @override
  @TimestampConverter()
  Timestamp get createdAt; // ✅ 추가 권장
  @override
  @TimestampConverter()
  Timestamp? get updatedAt;

  /// Create a copy of TournamentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TournamentModelImplCopyWith<_$TournamentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
