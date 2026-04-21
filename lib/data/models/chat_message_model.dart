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
    @Default('USER') String type, // USER, SYSTEM
    // Firestore의 Timestamp를 처리하기 위해 DateTime으로 변환
    @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _timestampFromDateTime)
    required DateTime timestamp,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

// Firestore Timestamp 변환용 헬퍼 함수
DateTime _dateTimeFromTimestamp(dynamic timestamp) => (timestamp as Timestamp).toDate();
dynamic _timestampFromDateTime(DateTime date) => Timestamp.fromDate(date);