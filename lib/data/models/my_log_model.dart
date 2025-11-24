// lib/data/models/my_log_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'my_log_model.freezed.dart';
part 'my_log_model.g.dart';

@freezed
class MyLogModel with _$MyLogModel {
  const factory MyLogModel({
    String? id,

    required String userId,

    // 날짜는 Timestamp로 저장/불러오기
    @TimestampConverter() required DateTime date,

    String? content,

    // 여러 장 지원
    @Default([]) List<String> photoUrls,

    // 서클 공유 여부
    @Default(false) bool isSharedToCircle,

    // 생성일 (수정해도 변경되지 않음)
    @TimestampConverter() DateTime? createdAt,
  }) = _MyLogModel;

  factory MyLogModel.fromJson(Map<String, dynamic> json) =>
      _$MyLogModelFromJson(json);
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp?> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp? timestamp) =>
      timestamp?.toDate() ?? DateTime.now();

  @override
  Timestamp? toJson(DateTime date) =>
      Timestamp.fromDate(date);
}
