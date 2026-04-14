// lib/data/repositories/training_repository.dart

import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

/// 트레이닝 세션 저장/조회용 Repository 인터페이스
///
/// - V2/V3부터는 TrainingSessionModel 안에
///   - hitRate   (명중률)
///   - mpr       (크리켓 마크/라운드)
///   - ppd       (점수/다트)
///   를 계산할 수 있는 원시 데이터(totalDarts, hitCount, totalMarks, totalScore)를
///   전부 저장하는 구조로 변경됨.
/// - 또한 V3에서는
///   - xpEarned          (해당 세션에서 획득한 XP)
///   - tierAtThatTime    (당시 DAO 트레이닝 티어)
///   - cycleId           (해당 세션이 속한 사이클 ID)
///   등을 이용해
///   히스토리/사이클/게이지 UI를 구성한다.
///
/// 구현체(Firestore 등)는 이 모델을 그대로 직렬화/역직렬화만 하면 된다.
abstract class TrainingRepository {
  // ===========================================================
  // 🔹 세션 생성 / 업데이트
  // ===========================================================

  /// 세션 생성 (새로 시작)
  ///
  /// 반환값: 생성된 document ID
  Future<String> createSession(TrainingSessionModel session);

  /// 세션 업데이트 (결과 저장, note 변경 등)
  Future<void> updateSession(TrainingSessionModel session);

  // ===========================================================
  // 🔹 세션 조회 계열
  // ===========================================================

  /// 최근 세션 목록 (히스토리 화면, 홈 요약 등에 사용)
  ///
  /// - 보통 userId 기준으로 최신 순 정렬 + limit 개수만 가져오기
  /// - limit 기본값은 50이지만,
  ///   히스토리 그래프 등에서는 100개 정도까지 늘려서 쓰는 것을 추천.
  Stream<List<TrainingSessionModel>> watchRecentSessions({
    required String userId,
    int limit = 50,
  });

  /// 특정 드릴에 대한 세션 히스토리
  ///
  /// - 예: "D16 드릴만 모아서 최근 100개" 이런 용도
  Future<List<TrainingSessionModel>> fetchSessionsByDrill({
    required String userId,
    required String drillId,
    int limit = 100,
  });

  /// 특정 드릴의 "가장 최근" 세션 하나
  ///
  /// - 예: "지난번 D16 연습 이후 얼마나 좋아졌는지" 비교용
  Future<TrainingSessionModel?> fetchLastSessionForDrill({
    required String userId,
    required String drillId,
  });

  // ===========================================================
  // 🔹 사이클 / 티어 / XP 게이지 관련 (V3용 확장)
  // ===========================================================

  /// 현재 유저의 트레이닝 진행 정보에서
  /// "새 사이클을 시작"할 때 사용하는 메서드.
  ///
  /// - 보통:
  ///   - currentTier를 [tier]로 설정
  ///   - cycleId를 `buildCycleIdForTier(tier)` 형태로 새로 발급
  ///   - xpSinceLastCheck를 0으로 초기화
  ///   이런 로직을 구현체(Firestore)에서 처리한다.
  ///
  /// - 이 메서드는:
  ///   - 레이팅 재평가 결과 티어가 확정됐을 때
  ///   - 혹은 유저가 수동으로 "이번 시즌은 프로 기준으로 다시!" 같은 행동을 할 때
  ///   호출해서 사용하면 된다.
  Future<void> startNewCycleForTier({
    required String userId,
    required DaoTrainingTier tier,
  });

  /// XP 게이지가 100%를 넘었을 때의 처리 전용 메서드.
  ///
  /// - 호출 시점:
  ///   - 각 드릴 세션 저장 후, `xpSinceLastCheck / xpTargetPerCheck >= 1.0` 이 되었을 때
  ///   - 레이팅/티어 재평가를 끝내고 최종 [newTierAfterCheck] 를 결정한 뒤
  ///
  /// - 구현체에서는 보통:
  ///   1) trainingMeta/trainingProgress 문서에서
  ///      totalXp, xpSinceLastCheck, xpTargetPerCheck 등을 갱신하고
  ///   2) 티어가 실제로 바뀌었다면
  ///      [startNewCycleForTier] 를 내부에서 호출해서
  ///      새 cycleId를 발급 + 게이지 초기화
  ///   3) 필요하다면, "티어 변경 로그" 등을 별도 컬렉션에 기록
  ///      하는 등의 처리를 할 수 있다.
  Future<void> handleXpGaugeFull({
    required String userId,
    required DaoTrainingTier newTierAfterCheck,
  });
}
