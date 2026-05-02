import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/practice_session_model.dart';
import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/data/repositories/my_log_repository.dart';
import 'package:daoapp/data/repositories/practice_repository.dart';
import 'package:daoapp/core/services/practice_notification_service.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MyLogRepository _myLogRepository;

  PracticeRepositoryImpl({required MyLogRepository myLogRepository})
      : _myLogRepository = myLogRepository;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('practice_sessions');

  // ✅ 새벽 4시 기준점 계산 (어제 데이터와 오늘 데이터 분리용)
  DateTime _getTodayThreshold() {
    final now = DateTime.now();
    final threshold = DateTime(now.year, now.month, now.day, 4, 0, 0);
    return now.isBefore(threshold)
        ? threshold.subtract(const Duration(days: 1))
        : threshold;
  }

  @override
  Future<void> startPractice(PracticeSessionModel session) async {
    final doc = await _sessions.doc(session.uid).get();
    int totalPreviousMs = 0;

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final lastUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
      final threshold = _getTodayThreshold();

      // 마지막 활동이 오늘 새벽 4시 이후라면 누적 시간을 승계
      if (lastUpdatedAt != null && lastUpdatedAt.isAfter(threshold)) {
        totalPreviousMs = data['totalDurationBefore'] ?? 0;
      }
    }

    // 누적 시간을 포함하여 세션 데이터 생성
    final updatedSession = session.copyWith(totalDurationBefore: totalPreviousMs);

    // DB 저장 (기존 문서 덮어쓰기 및 서버 타임스탬프 갱신)
    await _sessions.doc(updatedSession.uid).set({
      ...updatedSession.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 알림 서비스 실행
    await PracticeNotificationService.showPracticeNotification(
      shopName: updatedSession.shopName ?? updatedSession.machineType,
      startTime: updatedSession.startTime,
    );
  }

  @override
  Future<void> stopPractice(String uid, {bool saveToMyLog = false, String? feedback}) async {
    final doc = await _sessions.doc(uid).get();
    if (!doc.exists) return;

    final session = PracticeSessionModel.fromFirestore(doc);

    // 종료 시점의 '오늘 전체 누적 시간' 계산
    final totalTodayMs = session.getTodayTotalDuration().inMilliseconds;

    if (saveToMyLog) {
      final totalDuration = Duration(milliseconds: totalTodayMs);
      final hours = totalDuration.inHours;
      final minutes = totalDuration.inMinutes.remainder(60);

      // ✅ 마이로그 내용 구성 (목표와 피드백 포함)
      String logContent = "🎯 라이브 연습 기록\n"
          "- 장소: ${session.shopName ?? '기타'}\n"
          "- 머신: ${session.machineType}\n"
          "- 시간: ${hours > 0 ? '$hours시간 ' : ''}$minutes분 (오늘 총합)";

      if (session.targetGoal != null && session.targetGoal!.isNotEmpty) {
        logContent += "\n- 설정 목표: ${session.targetGoal}";
      }

      if (feedback != null && feedback.isNotEmpty) {
        logContent += "\n- 연습 결과: $feedback";
      }

      final newLog = MyLogModel(
        userId: uid,
        date: DateTime.now(),
        content: logContent,
        photoUrls: [],
        isSharedToCircle: false,
        createdAt: DateTime.now(),
      );

      await _myLogRepository.saveLog(newLog);
    }

    // 연습 종료 상태 업데이트 (누적 시간 최종 합산치 저장)
    await _sessions.doc(uid).update({
      'isActive': false,
      'isPaused': false,
      'totalDurationBefore': totalTodayMs,
      'feedback': feedback, // 종료 시 남긴 답변도 세션 기록에 저장
      'endTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await PracticeNotificationService.cancelNotification();
  }

  @override
  Future<void> updateSession(String uid, Map<String, dynamic> updates) async {
    await _sessions.doc(uid).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> togglePause(String uid, bool pause) async {
    await _sessions.doc(uid).update({
      'isPaused': pause,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}