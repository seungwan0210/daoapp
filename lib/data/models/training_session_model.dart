// lib/data/models/training_session_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

/// 한 번의 연습 세션 기록
class TrainingSessionModel {
  final String? id;
  final String userId;

  /// 어떤 드릴인지 (definition id)
  final String drillId;
  final String drillTitle;

  /// 그때의 DAO 티어 (7단계)
  final DaoTrainingTier tierAtThatTime;

  final DateTime startedAt;
  final DateTime endedAt;

  /// 실제 진행 라운드 수
  final int totalRounds;

  /// 실제 던진 다트 수 (hitCount / score / cricket 공통)
  final int totalAttempts;

  /// hitCount 모드용 성공/실패 카운트
  final int successCount;
  final int failCount;

  /// 부가 정보 / 통계
  ///
  /// - inputMode: 'hitCount' / 'scoreOnly' / 'cricketMarks'
  /// - totalScore, totalMarks
  /// - hitRate, ppd, threeDartAvg, mpr 등
  /// - finishedEarly, plannedRounds, plannedDartsPerRound ...
  final Map<String, dynamic>? extra;

  const TrainingSessionModel({
    this.id,
    required this.userId,
    required this.drillId,
    required this.drillTitle,
    required this.tierAtThatTime,
    required this.startedAt,
    required this.endedAt,
    required this.totalRounds,
    required this.totalAttempts,
    required this.successCount,
    required this.failCount,
    this.extra,
  });

  TrainingSessionModel copyWith({
    String? id,
    String? userId,
    String? drillId,
    String? drillTitle,
    DaoTrainingTier? tierAtThatTime,
    DateTime? startedAt,
    DateTime? endedAt,
    int? totalRounds,
    int? totalAttempts,
    int? successCount,
    int? failCount,
    Map<String, dynamic>? extra,
  }) {
    return TrainingSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      drillId: drillId ?? this.drillId,
      drillTitle: drillTitle ?? this.drillTitle,
      tierAtThatTime: tierAtThatTime ?? this.tierAtThatTime,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      totalRounds: totalRounds ?? this.totalRounds,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      successCount: successCount ?? this.successCount,
      failCount: failCount ?? this.failCount,
      extra: extra ?? this.extra,
    );
  }

  // --------- 편의 getter (통계 화면용) ---------

  String? get inputModeString => extra?['inputMode'] as String?;
  int? get totalScoreExtra => extra?['totalScore'] as int?;
  int? get totalMarksExtra => extra?['totalMarks'] as int?;

  double? get hitRate =>
      (extra?['hitRate'] is num) ? (extra!['hitRate'] as num).toDouble() : null;

  double? get ppd =>
      (extra?['ppd'] is num) ? (extra!['ppd'] as num).toDouble() : null;

  double? get threeDartAvg => (extra?['threeDartAvg'] is num)
      ? (extra!['threeDartAvg'] as num).toDouble()
      : null;

  double? get mpr =>
      (extra?['mpr'] is num) ? (extra!['mpr'] as num).toDouble() : null;

  // --------- Firestore 변환 ---------

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DaoTrainingTier _tierFromRaw(dynamic raw) {
    if (raw is String) {
      final index =
      DaoTrainingTier.values.indexWhere((e) => e.name == raw);
      if (index >= 0) return DaoTrainingTier.values[index];
    }
    if (raw is int) {
      if (raw >= 0 && raw < DaoTrainingTier.values.length) {
        return DaoTrainingTier.values[raw];
      }
    }
    // 기본값: beginner
    return DaoTrainingTier.beginner;
  }

  factory TrainingSessionModel.fromJson(
      String id,
      Map<String, dynamic> json,
      ) {
    return TrainingSessionModel(
      id: id,
      userId: json['userId'] as String,
      drillId: json['drillId'] as String,
      drillTitle: json['drillTitle'] as String? ?? '',
      tierAtThatTime: _tierFromRaw(json['tierAtThatTime']),
      startedAt: _toDate(json['startedAt']),
      endedAt: _toDate(json['endedAt']),
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? 0,
      totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
      successCount: (json['successCount'] as num?)?.toInt() ?? 0,
      failCount: (json['failCount'] as num?)?.toInt() ?? 0,
      extra: (json['extra'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'drillId': drillId,
      'drillTitle': drillTitle,
      // 문자열로 저장 (나중에 name으로 복원)
      'tierAtThatTime': tierAtThatTime.name,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': Timestamp.fromDate(endedAt),
      'totalRounds': totalRounds,
      'totalAttempts': totalAttempts,
      'successCount': successCount,
      'failCount': failCount,
      'extra': extra ?? <String, dynamic>{},
    };
  }
}
