// lib/data/repositories/training_progress_repository.dart

import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_progress_model.dart';

/// 트레이닝 XP / 게이지 / 사이클 상태 관리용 Repository
///
/// - users/{userId}/trainingMeta/trainingProgress 문서를 읽고/쓰기
abstract class TrainingProgressRepository {
  /// 현재 유저의 Progress 한 번만 가져오기
  ///
  /// - 문서가 없으면 기본값으로 생성해서 반환해도 됨
  Future<TrainingProgressModel> getProgress(String userId);

  /// 현재 유저의 Progress 실시간 구독 (게이지 UI용)
  Stream<TrainingProgressModel> watchProgress(String userId);

  /// Progress 문서가 없으면 생성 후 반환
  ///
  /// - getProgress와 달리 "존재 보장" 용도로 사용
  Future<TrainingProgressModel> ensureProgress(String userId);

  /// XP 추가 (드릴 1세션 종료 시 호출)
  ///
  /// - totalXp, xpSinceLastCheck 둘 다 xpToAdd 만큼 증가
  /// - 문서가 없으면 자동으로 생성
  Future<TrainingProgressModel> addXp({
    required String userId,
    required int xpToAdd,
  });

  /// 레이팅 / 레벨 테스트를 "완료"한 뒤 게이지 초기화
  ///
  /// - xpSinceLastCheck = 0 (게이지 리셋)
  /// - ratingCheckCount += 1
  /// - lastRatingCheckAt = now
  /// - tierAtThatTime = newTier로 교체
  /// - tier에 따라 cycleSize도 재조정 (예: Beginner 80, Master 140 등)
  Future<TrainingProgressModel> markRatingChecked({
    required String userId,
    required DaoTrainingTier newTier,
  });

  /// 새 트레이닝 사이클 시작
  ///
  /// - lastCycleIndex += 1
  /// - currentCycleId = "cycle_XXX" (예: cycle_001, cycle_002 ...)
  /// - lastCycleStartedAt = now
  /// - 필요하다면 currentCycleSessionCount = 0 으로 리셋
  Future<TrainingProgressModel> startNewCycle({
    required String userId,
  });

  /// 현재 사이클 ID를 명시적으로 변경
  ///
  /// - 히스토리 화면에서 특정 cycleId로 강제로 맞추거나,
  ///   마이그레이션/복구용으로 사용할 수 있음
  Future<TrainingProgressModel> setCurrentCycle({
    required String userId,
    required String cycleId,
  });
}
