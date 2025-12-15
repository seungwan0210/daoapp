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

    // 날짜는 반드시 있어야 하니까 non-null + 강한 컨버터
    @TimestampConverter() required DateTime date,

    String? content,

    // 여러 장 지원
    @Default([]) List<String> photoUrls,

    // 서클 공유 여부
    @Default(false) bool isSharedToCircle,

    // 생성일 (수정해도 변경되지 않음) - nullable
    @NullableTimestampConverter() DateTime? createdAt,
  }) = _MyLogModel;

  factory MyLogModel.fromJson(Map<String, dynamic> json) =>
      _$MyLogModelFromJson(json);
}

/// 🔹 non-null DateTime용 컨버터
class TimestampConverter implements JsonConverter<DateTime, Object?> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object? value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      // 예전 버전에서 String으로 저장됐던 경우 대비
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    // 혹시 이상한 타입이 오더라도 앱이 죽지 않게
    return DateTime.now();
  }

  @override
  Object? toJson(DateTime date) => Timestamp.fromDate(date);
}

/// 🔹 nullable DateTime용 컨버터 (createdAt 같이 null 허용 필드)
class NullableTimestampConverter
    implements JsonConverter<DateTime?, Object?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  @override
  Object? toJson(DateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(date);
  }
}
