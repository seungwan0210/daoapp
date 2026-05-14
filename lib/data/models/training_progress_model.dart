// lib/data/models/training_progress_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

/// DAO 트레이닝 누적 Progress (XP 게이지 및 사이클 관리 모델)
///
/// [필드 설명]
/// - totalXp: 지금까지 모은 전체 XP (누적 통계용)
/// - xpSinceLastCheck: 마지막 레이팅 체크 이후 누적 XP (현재 게이지 표시 대상)
/// - cycleSize: 게이지 1바퀴 완성에 필요한 XP (기본 1000)
/// - ratingCheckCount: 지금까지 레벨 테스트/레이팅 체크를 수행한 횟수
/// - lastUpdatedAt: 마지막 Progress 데이터 갱신 시각
/// - lastRatingCheckAt: 마지막 레이팅 체크 수행 시각
/// - currentCycleId: 현재 진행 중인 사이클 고유 ID (예: "cycle_001")
/// - cycleIndex: 현재 몇 번째 사이클인지 표시 (1부터 시작)
/// - cycleStartAt: 현재 사이클이 시작된 시각
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

  /// 현재 사이클 ID (예: "cycle_001")
  final String currentCycleId;

  /// 몇 번째 사이클인지 (1부터 시작)
  final int cycleIndex;

  /// 이 사이클이 시작된 시각
  final DateTime cycleStartAt;

  const TrainingProgressModel({
    required this.userId,
    required this.tierAtThatTime,
    required this.totalXp,
    required this.xpSinceLastCheck,
    required this.cycleSize,
    required this.ratingCheckCount,
    required this.lastUpdatedAt,
    this.lastRatingCheckAt,
    this.currentCycleId = 'cycle_001',
    this.cycleIndex = 1,
    DateTime? cycleStartAt,
  }) : cycleStartAt = cycleStartAt ?? lastUpdatedAt;

  /// 게이지 비율 0.0 ~ 1.0 (UI 표시용)
  double get progressRatio {
    if (cycleSize <= 0) return 0.0;
    final ratio = xpSinceLastCheck / cycleSize;
    if (ratio < 0) return 0.0;
    if (ratio > 1.0) return 1.0;
    return ratio;
  }

  /// 이번 사이클이 꽉 찼는지 여부 (100% 이상)
  bool get isCycleComplete => xpSinceLastCheck >= cycleSize;

  /// 다음 레이팅 체크까지 남은 XP
  int get remainingXp {
    final remain = cycleSize - xpSinceLastCheck;
    if (remain < 0) return 0;
    return remain;
  }

  /// 한 번이라도 레이팅 체크를 한 적이 있는지
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
    String? currentCycleId,
    int? cycleIndex,
    DateTime? cycleStartAt,
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
      currentCycleId: currentCycleId ?? this.currentCycleId,
      cycleIndex: cycleIndex ?? this.cycleIndex,
      cycleStartAt: cycleStartAt ?? this.cycleStartAt,
    );
  }

  /// XP 추가된 새 Progress 반환 (원본은 변경 X)
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

  /// 레이팅/레벨 테스트를 “완료”했을 때 호출하는 헬퍼
  /// 게이지를 0으로 리셋하고 다음 사이클을 시작함
  TrainingProgressModel withRatingChecked({
    required DaoTrainingTier newTier,
    int? newCycleSize,
  }) {
    final now = DateTime.now();
    final nextIndex = cycleIndex + 1;
    final nextCycleId = 'cycle_${nextIndex.toString().padLeft(3, '0')}';

    return copyWith(
      tierAtThatTime: newTier,
      xpSinceLastCheck: 0,
      cycleSize: newCycleSize ?? cycleSize,
      ratingCheckCount: ratingCheckCount + 1,
      lastUpdatedAt: now,
      lastRatingCheckAt: now,
      cycleIndex: nextIndex,
      currentCycleId: nextCycleId,
      cycleStartAt: now,
    );
  }

  // -----------------------------
  // Firestore 변환 로직
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
    final lastUpdated = _toDate(json['lastUpdatedAt']);
    final lastCheckRaw = json['lastRatingCheckAt'];
    final lastCheck = lastCheckRaw != null ? _toDate(lastCheckRaw) : null;

    final cycleIndex = (json['cycleIndex'] as num?)?.toInt() ?? 1;
    final currentCycleId = json['currentCycleId'] as String? ??
        'cycle_${cycleIndex.toString().padLeft(3, '0')}';

    final cycleStartAtRaw = json['cycleStartAt'];
    final cycleStartAt = cycleStartAtRaw != null
        ? _toDate(cycleStartAtRaw)
        : (lastCheck ?? lastUpdated);

    return TrainingProgressModel(
      userId: userId,
      tierAtThatTime: _tierFromRaw(json['tierAtThatTime']),
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      xpSinceLastCheck: (json['xpSinceLastCheck'] as num?)?.toInt() ?? 0,
      cycleSize: (json['cycleSize'] as num?)?.toInt() ?? 1000,
      ratingCheckCount: (json['ratingCheckCount'] as num?)?.toInt() ?? 0,
      lastUpdatedAt: lastUpdated,
      lastRatingCheckAt: lastCheck,
      currentCycleId: currentCycleId,
      cycleIndex: cycleIndex,
      cycleStartAt: cycleStartAt,
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
      'currentCycleId': currentCycleId,
      'cycleIndex': cycleIndex,
      'cycleStartAt': Timestamp.fromDate(cycleStartAt),
    };
  }

  /// 새 유저를 위한 초기 Progress 생성
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
      currentCycleId: 'cycle_001',
      cycleIndex: 1,
      cycleStartAt: now,
    );
  }

  /// 티어 정보가 없을 때 사용하는 빈 객체 생성 (비기너 기준)
  factory TrainingProgressModel.empty(String userId) {
    return TrainingProgressModel.initial(
      userId: userId,
      tier: DaoTrainingTier.beginner,
      cycleSize: 1000,
    );
  }
}