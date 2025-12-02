// lib/data/models/training_session_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

class TrainingSessionModel {
  final String? id;
  final String userId;
  final String drillId;
  final String drillTitle;
  final DaoTrainingTier tierAtThatTime;
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalRounds;
  final int totalAttempts;
  final int successCount;
  final int failCount;
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

  double get hitRate {
    if (totalAttempts == 0) return 0.0;
    return successCount / totalAttempts;
  }

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

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'drillId': drillId,
      'drillTitle': drillTitle,
      // ✅ 7티어 enum의 name 저장 (beginner / learner / ...)
      'tierAtThatTime': tierAtThatTime.name,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': Timestamp.fromDate(endedAt),
      'totalRounds': totalRounds,
      'totalAttempts': totalAttempts,
      'successCount': successCount,
      'failCount': failCount,
      if (extra != null) 'extra': extra,
    };
  }

  factory TrainingSessionModel.fromJson(String id, Map<String, dynamic> json) {
    return TrainingSessionModel(
      id: id,
      userId: json['userId'] as String,
      drillId: json['drillId'] as String,
      drillTitle: (json['drillTitle'] ?? '') as String,
      tierAtThatTime: _tierFromString(json['tierAtThatTime'] as String?),
      startedAt: (json['startedAt'] as Timestamp).toDate(),
      endedAt: (json['endedAt'] as Timestamp).toDate(),
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? 0,
      totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
      successCount: (json['successCount'] as num?)?.toInt() ?? 0,
      failCount: (json['failCount'] as num?)?.toInt() ?? 0,
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }

  factory TrainingSessionModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data()!;
    return TrainingSessionModel.fromJson(doc.id, data);
  }

  /// 🔁 예전 5티어 문자열 → 새 7티어 매핑 포함
  ///
  /// old 5티어:
  ///  - rookie, basic, intermediate, advanced, expert
  ///
  /// 새 7티어:
  ///  - beginner, learner, competitor, challenger, elite, pro, master
  static DaoTrainingTier _tierFromString(String? name) {
    if (name == null) return DaoTrainingTier.beginner;

    switch (name) {
    // === 새 7티어 문자열 그대로 들어온 경우 ===
      case 'beginner':
        return DaoTrainingTier.beginner;
      case 'learner':
        return DaoTrainingTier.learner;
      case 'competitor':
        return DaoTrainingTier.competitor;
      case 'challenger':
        return DaoTrainingTier.challenger;
      case 'elite':
        return DaoTrainingTier.elite;
      case 'pro':
        return DaoTrainingTier.pro;
      case 'master':
        return DaoTrainingTier.master;

    // === 예전 5티어 데이터 마이그레이션용 매핑 ===
      case 'rookie':
        return DaoTrainingTier.beginner;      // 가장 아래
      case 'basic':
        return DaoTrainingTier.learner;       // 한 단계 위
      case 'intermediate':
        return DaoTrainingTier.competitor;    // 중간
      case 'advanced':
        return DaoTrainingTier.challenger;    // 상위
      case 'expert':
        return DaoTrainingTier.pro;           // 최상위 쪽

    // 혹시 이상한 값이면 최소 티어로
      default:
        return DaoTrainingTier.beginner;
    }
  }
}
