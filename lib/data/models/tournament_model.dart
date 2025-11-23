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

    /// 대회 이름
    required String title,

    /// 장소 (샵명 / 경기장명 등)
    required String location,

    /// 최대 참가 인원 (무제한은 9999 등으로 처리)
    required int maxParticipants,

    /// 포스터 이미지 URL (없을 수 있음)
    String? posterUrl,

    /// 상세 설명 (규정, 상금, 진행 방식 등)
    required String description,

    /// 참가비 (원 단위, 0이면 무료)
    @Default(0) int entryFee,

    /// 대회 날짜/시간
    @TimestampConverter() required Timestamp eventDate,

    /// 엔트리 시작
    @TimestampConverter() required Timestamp entryStartDate,

    /// 엔트리 마감
    @TimestampConverter() required Timestamp entryEndDate,

    /// 대회 생성자 UID
    required String createdByUid,

    /// 공동주최자 이메일 리스트 (생성자 이메일 포함 가능)
    required List<String> organizerEmails,

    /// 담당자 이름 (문의용)
    @Default('') String hostName,

    /// 담당자 연락처 (문의용)
    @Default('') String hostPhone,

    /// 현재 엔트리 인원 수
    @Default(0) int entryCount,

    /// 엔트리 요약 메일 발송 여부
    @Default(false) bool entrySummarySent,

    /// 대회 취소 여부 (true면 취소된 대회)
    @Default(false) bool isCanceled,

    /// 생성 시각
    @TimestampConverter() required Timestamp createdAt,
  }) = _TournamentModel;

  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentModelFromJson(json);
}
