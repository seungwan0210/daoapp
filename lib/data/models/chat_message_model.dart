import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String uid,
    required String userName,
    String? userProfile,
    required String message,

    @Default('USER') String type, // USER, SYSTEM 등

    // ✅ 시스템 메시지 분류 및 에셋/이동을 위한 필드
    // null 방지를 위해 기본값을 빈 문자열로 두면 UI 작업 시 체크가 편합니다.
    @Default('') String category, // WELCOME, TOURNAMENT, RANKING 등
    @Default('') String targetId, // 대회 ID 혹은 배지 에셋 키(pro, diamond 등)

    @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _timestampFromDateTime)
    required DateTime timestamp,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

/// 🕒 Firestore Timestamp ↔ DateTime 변환 헬퍼 함수
DateTime _dateTimeFromTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  }
  // 서버 타임스탬프가 아직 찍히기 전(null)이거나 타입이 다를 경우 현재 시간 반환
  return DateTime.now();
}

dynamic _timestampFromDateTime(DateTime date) => Timestamp.fromDate(date);