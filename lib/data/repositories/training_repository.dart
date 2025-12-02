// lib/data/repositories/training_repository.dart

import 'package:daoapp/data/models/training_session_model.dart';

/// 트레이닝 세션 저장/조회용 Repository 인터페이스
///
/// - v2부터는 TrainingSessionModel 안에
///   - hitRate (명중률)
///   - mpr (크리켓 마크/라운드)
///   - ppd (점수/다트)
///   를 계산할 수 있는 원시 데이터(totalDarts, hitCount, totalMarks, totalScore)를
///   전부 저장하는 구조로 변경됨.
///
/// 구현체(Firestore 등)는 이 모델을 그대로 직렬화/역직렬화만 하면 된다.
abstract class TrainingRepository {
  /// 세션 생성 (새로 시작)
  ///
  /// 반환값: 생성된 document ID
  Future<String> createSession(TrainingSessionModel session);

  /// 세션 업데이트 (결과 저장, note 변경 등)
  Future<void> updateSession(TrainingSessionModel session);

  /// 최근 세션 목록 (히스토리 화면, 홈 요약 등에 사용)
  ///
  /// - 보통 userId 기준으로 최신 순 정렬 + limit 개수만 가져오기
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
}
