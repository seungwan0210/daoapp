// lib/data/models/training_progress_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

/// DAO 트레이닝 누적 Progress (XP 게이지용)
///
/// - totalXp: 지금까지 모은 전체 XP (히스토리/통계용)
/// - xpSinceLastCheck: 마지막 레이팅 체크 이후 누적 XP (게이지용)
/// - cycleSize: 게이지 1바퀴에 필요한 XP (기본 100)
/// - ratingCheckCount: 지금까지 레이팅 체크를 몇 번 했는지
/// - lastUpdatedAt: 마지막으로 Progress가 갱신된 시각
/// - lastRatingCheckAt: 마지막 레이팅 체크 시각
class TrainingProgressModel {
  final String userId;
  final DaoTrainingTier tierAtThatTime;

  /// 지금까지 모은 전체 XP
  final int totalXp;

  /// 마지막 레이팅 체크 이후 누적 XP (게이지 대상)
  final int xpSinceLastCheck;

  /// 게이지 1바퀴에 필요한 XP
  final int cycleSize;

  /// 레이팅 체크를 수행한 횟수
  final int ratingCheckCount;

  /// 마지막 Progress 갱신 시각
  final DateTime lastUpdatedAt;

  /// 마지막 레이팅 체크 시각 (없을 수도 있음)
  final DateTime? lastRatingCheckAt;

  const TrainingProgressModel({
    required this.userId,
    required this.tierAtThatTime,
    required this.totalXp,
    required this.xpSinceLastCheck,
    required this.cycleSize,
    required this.ratingCheckCount,
    required this.lastUpdatedAt,
    this.lastRatingCheckAt,
  });

  /// 🔹 게이지 비율 0.0 ~ 1.0
  double get progressRatio {
    if (cycleSize <= 0) return 0.0;
    final ratio = xpSinceLastCheck / cycleSize;
    if (ratio < 0) return 0.0;
    if (ratio > 1.0) return 1.0;
    return ratio;
  }

  /// 🔹 이번 사이클이 꽉 찼는지 여부 (100% 이상)
  bool get isCycleComplete => xpSinceLastCheck >= cycleSize;

  /// 🔹 다음 레이팅 체크까지 남은 XP
  int get remainingXp {
    final remain = cycleSize - xpSinceLastCheck;
    if (remain < 0) return 0;
    return remain;
  }

  /// 🔹 한 번이라도 레이팅 체크를 한 적이 있는지
  bool get hasEverCheckedRating =>
      ratingCheckCount > 0 || lastRatingCheckAt != null;

  TrainingProgressModel copyWith({
    String? userId,
    DaoTrainingTier? tierAtThatTime,
    int? totalXp,
    int? xpSinceLastCheck,
    int? cycleSize,
    int? ratingCheckCount,
    DateTime? lastUpdatedAt,
    DateTime? lastRatingCheckAt,
  }) {
    return TrainingProgressModel(
      userId: userId ?? this.userId,
      tierAtThatTime: tierAtThatTime ?? this.tierAtThatTime,
      totalXp: totalXp ?? this.totalXp,
      xpSinceLastCheck: xpSinceLastCheck ?? this.xpSinceLastCheck,
      cycleSize: cycleSize ?? this.cycleSize,
      ratingCheckCount: ratingCheckCount ?? this.ratingCheckCount,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastRatingCheckAt: lastRatingCheckAt ?? this.lastRatingCheckAt,
    );
  }

  /// 🔹 XP 추가된 새 Progress 반환 (원본은 변경 X)
  ///
  /// - totalXp는 무조건 xp만큼 증가
  /// - xpSinceLastCheck도 xp만큼 증가 (게이지 대상)
  TrainingProgressModel withAddedXp(int xp, {DaoTrainingTier? tier}) {
    if (xp <= 0) {
      return copyWith(
        tierAtThatTime: tier ?? tierAtThatTime,
        lastUpdatedAt: DateTime.now(),
      );
    }

    final now = DateTime.now();

    return copyWith(
      tierAtThatTime: tier ?? tierAtThatTime,
      totalXp: totalXp + xp,
      xpSinceLastCheck: xpSinceLastCheck + xp,
      lastUpdatedAt: now,
    );
  }

  /// 🔹 레이팅/레벨 테스트를 “완료”했을 때 호출하는 헬퍼
  ///
  /// - xpSinceLastCheck: 0으로 리셋 (게이지 초기화)
  /// - ratingCheckCount: +1
  /// - lastRatingCheckAt / lastUpdatedAt: 지금 시각으로 갱신
  /// - tierAtThatTime: 새로 평가된 티어로 업데이트
  /// - newCycleSize가 주어지면, 다음 사이클 목표 XP도 조정
  TrainingProgressModel withRatingChecked({
    required DaoTrainingTier newTier,
    int? newCycleSize,
  }) {
    final now = DateTime.now();
    return copyWith(
      tierAtThatTime: newTier,
      xpSinceLastCheck: 0,
      cycleSize: newCycleSize ?? cycleSize,
      ratingCheckCount: ratingCheckCount + 1,
      lastUpdatedAt: now,
      lastRatingCheckAt: now,
    );
  }

  // -----------------------------
  // Firestore 변환
  // -----------------------------

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DaoTrainingTier _tierFromRaw(dynamic raw) {
    if (raw is String) {
      final index = DaoTrainingTier.values.indexWhere((e) => e.name == raw);
      if (index >= 0) return DaoTrainingTier.values[index];
    }
    if (raw is int) {
      if (raw >= 0 && raw < DaoTrainingTier.values.length) {
        return DaoTrainingTier.values[raw];
      }
    }
    return DaoTrainingTier.beginner;
  }

  factory TrainingProgressModel.fromJson(
      String userId,
      Map<String, dynamic> json,
      ) {
    return TrainingProgressModel(
      userId: userId,
      tierAtThatTime: _tierFromRaw(json['tierAtThatTime']),
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      xpSinceLastCheck: (json['xpSinceLastCheck'] as num?)?.toInt() ?? 0,
      cycleSize: (json['cycleSize'] as num?)?.toInt() ?? 100,
      ratingCheckCount: (json['ratingCheckCount'] as num?)?.toInt() ?? 0,
      lastUpdatedAt: _toDate(json['lastUpdatedAt']),
      lastRatingCheckAt: json['lastRatingCheckAt'] != null
          ? _toDate(json['lastRatingCheckAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tierAtThatTime': tierAtThatTime.name,
      'totalXp': totalXp,
      'xpSinceLastCheck': xpSinceLastCheck,
      'cycleSize': cycleSize,
      'ratingCheckCount': ratingCheckCount,
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      if (lastRatingCheckAt != null)
        'lastRatingCheckAt': Timestamp.fromDate(lastRatingCheckAt!),
    };
  }

  /// 🔹 새 유저용 기본 값
  factory TrainingProgressModel.initial({
    required String userId,
    required DaoTrainingTier tier,
    int cycleSize = 1000,
  }) {
    final now = DateTime.now();
    return TrainingProgressModel(
      userId: userId,
      tierAtThatTime: tier,
      totalXp: 0,
      xpSinceLastCheck: 0,
      cycleSize: cycleSize,
      ratingCheckCount: 0,
      lastUpdatedAt: now,
      lastRatingCheckAt: null,
    );
  }

  /// 🔹 tier 모를 때 사용하는 완전 기본값 (Beginner 기준)
  factory TrainingProgressModel.empty(String userId) {
    return TrainingProgressModel.initial(
      userId: userId,
      tier: DaoTrainingTier.beginner,
      cycleSize: 1000,
    );
  }
}
