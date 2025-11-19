// lib/data/models/tournament_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'tournament_model.freezed.dart';
part 'tournament_model.g.dart';

/// Timestamp 변환을 위한 Converter (class 밖으로 빼야 함!!)
class TimestampConverter implements JsonConverter<Timestamp, Object> {
  const TimestampConverter();

  @override
  Timestamp fromJson(Object json) {
    if (json is Timestamp) return json;
    if (json is int) return Timestamp.fromMillisecondsSinceEpoch(json);
    return Timestamp.now();
  }

  @override
  Object toJson(Timestamp object) => object;
}

@freezed
class TournamentModel with _$TournamentModel {
  const factory TournamentModel({
    String? id,
    required String title,
    required String description,
    String? imageUrl,
    @Default(0) int entryFee,
    @TimestampConverter() required Timestamp eventDate,
    @TimestampConverter() required Timestamp entryStartDate,
    @TimestampConverter() required Timestamp entryEndDate,
    required String createdByUid,
    required List<String> organizerEmails,
    @Default(0) int entryCount,
    @Default(false) bool entrySummarySent,
    @TimestampConverter() required Timestamp createdAt,
  }) = _TournamentModel;

  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentModelFromJson(json);
}