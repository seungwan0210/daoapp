import 'package:daoapp/data/models/practice_session_model.dart';

abstract class PracticeRepository {
  /// 연습 시작
  Future<void> startPractice(PracticeSessionModel session);

  /// 세션 정보(장소, 머신 등) 수정
  Future<void> updateSession(String uid, Map<String, dynamic> updates);

  /// 연습 종료 (saveToMyLog: true일 경우 마이로그 컬렉션에 데이터 전송)
  /// ✅ feedback: 유저가 종료 시 입력한 결과/소감 텍스트
  Future<void> stopPractice(String uid, {
    bool saveToMyLog = false,
    String? feedback, // 👈 파라미터 추가
  });

  /// 일시 정지 및 재개 토글
  Future<void> togglePause(String uid, bool pause);
}