// lib/data/repositories/training_repository.dart

import 'package:daoapp/data/models/training_session_model.dart';

abstract class TrainingRepository {
  /// 세션 생성 (새로 시작)
  Future<String> createSession(TrainingSessionModel session);

  /// 세션 업데이트 (결과 수정, note 변경 등)
  Future<void> updateSession(TrainingSessionModel session);

  /// 최근 세션 목록 (히스토리 화면, 홈 요약 등에 사용)
  Stream<List<TrainingSessionModel>> watchRecentSessions({
    required String userId,
    int limit,
  });

  /// 특정 드릴에 대한 세션 히스토리
  Future<List<TrainingSessionModel>> fetchSessionsByDrill({
    required String userId,
    required String drillId,
    int limit,
  });

  /// 마지막 세션 (예: “지난번 D16 연습 이후 얼마나 좋아졌는지” 비교용)
  Future<TrainingSessionModel?> fetchLastSessionForDrill({
    required String userId,
    required String drillId,
  });
}
