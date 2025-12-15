import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'tournament_model.freezed.dart';
part 'tournament_model.g.dart';

class TimestampConverter implements JsonConverter<Timestamp, Object> {
  const TimestampConverter();

  @override
  Timestamp fromJson(Object json) {
    if (json is Timestamp) return json;
    if (json is int) {
      return Timestamp.fromMillisecondsSinceEpoch(json);
    }
    if (json is double) {
      return Timestamp.fromMillisecondsSinceEpoch(json.toInt());
    }
    // 예상 밖 타입이 들어오면 일단 현재 시간으로 fallback
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
    required String location,
    required int maxParticipants,
    String? posterUrl,
    required String description,

    @Default(0) int entryFee,

    @TimestampConverter() required Timestamp eventDate,
    @TimestampConverter() required Timestamp entryStartDate,
    @TimestampConverter() required Timestamp entryEndDate,

    required String createdByUid,
    required List<String> organizerEmails,

    @Default('') String hostName,
    @Default('') String hostPhone,

    @Default(0) int entryCount,
    @Default(false) bool entrySummarySent,
    @Default(false) bool isCanceled,

    @TimestampConverter() required Timestamp createdAt,

    // ✅ 추가 권장
    @TimestampConverter() Timestamp? updatedAt,
  }) = _TournamentModel;

  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentModelFromJson(json);
}
