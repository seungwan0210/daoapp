// lib/data/models/tournament_model.dart

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
    String? posterUrl, // 🖼️ 완전 삭제 시 스토리지에서 이 URL을 참조해 지웁니다.
    required String description,
    @Default(0) int entryFee,
    @TimestampConverter() required Timestamp eventDate,
    @TimestampConverter() required Timestamp entryStartDate,
    @TimestampConverter() required Timestamp entryEndDate, // 🧹 이 날짜 기준으로 3개월 뒤 자동 청소합니다.
    required String createdByUid,
    required List<String> organizerEmails,
    @Default('') String hostName,
    @Default('') String hostPhone,
    @Default(0) int entryCount,
    @Default(false) bool entrySummarySent,
    @Default(false) bool isCanceled, // 🚫 사용자가 취소/삭제 시 상태값으로 활용 가능
    @TimestampConverter() required Timestamp createdAt,
    @TimestampConverter() Timestamp? updatedAt,

    // ✅ 팀전 여부 구분 ('single' 또는 'team')
    @Default('single') String type,
    // ✅ 팀전일 경우 팀당 인원수 (개인전은 1)
    @Default(1) int teamSize,

    // ✅ 주최자가 정의한 커스텀 질문 리스트 (예: ["상의 사이즈", "식사 여부"])
    @Default([]) List<String> customQuestions,
  }) = _TournamentModel;

  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentModelFromJson(json);
}