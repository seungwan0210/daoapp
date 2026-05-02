import 'package:cloud_firestore/cloud_firestore.dart';

class PracticeSessionModel {
  final String uid;           // 사용자 고유 ID
  final String nickname;      // 표시될 닉네임 (koreanName)
  final String? profileUrl;   // 프로필 이미지 URL
  final DateTime startTime;   // 현재 세션 연습 시작 시간
  final String machineType;   // 다트 머신 타입 (다트라이브, 피닉스, 스틸 등)
  final String? shopName;     // 연습 장소 이름
  final bool isActive;        // 현재 연습 진행 중 여부
  final bool isPaused;        // 일시 정지 여부 (UI 어둡게 처리용)

  // ✅ [수정/추가] 텍스트 기반 목표 및 피드백 필드
  final String? targetGoal;   // 오늘의 연습 목표 (예: "불 100발", "3시간 연습")
  final String? feedback;     // 연습 종료 후 결과/피드백 (예: "100발 완료!", "아쉽게 실패")
  final double? targetRating; // 기존의 숫자형 목표 레이팅 (필요시 유지)

  // 오늘 이 세션 이전에 완료된 연습 시간의 총합 (밀리초 단위)
  final int totalDurationBefore;

  PracticeSessionModel({
    required this.uid,
    required this.nickname,
    this.profileUrl,
    required this.startTime,
    required this.machineType,
    this.shopName,
    this.isActive = true,
    this.isPaused = false,
    this.targetGoal,          // ✅ 추가
    this.feedback,            // ✅ 추가
    this.targetRating,
    this.totalDurationBefore = 0,
  });

  // Firestore 데이터를 모델로 변환
  factory PracticeSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PracticeSessionModel(
      uid: doc.id,
      nickname: data['nickname'] ?? '이름 없음',
      profileUrl: data['profileUrl'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      machineType: data['machineType'] ?? '기타',
      shopName: data['shopName'],
      isActive: data['isActive'] ?? false,
      isPaused: data['isPaused'] ?? false,
      targetGoal: data['targetGoal'],   // ✅ 추가
      feedback: data['feedback'],       // ✅ 추가
      targetRating: (data['targetRating'] as num?)?.toDouble(),
      totalDurationBefore: data['totalDurationBefore'] ?? 0,
    );
  }

  // 모델을 Firestore 저장용 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'profileUrl': profileUrl,
      'startTime': Timestamp.fromDate(startTime),
      'machineType': machineType,
      'shopName': shopName,
      'isActive': isActive,
      'isPaused': isPaused,
      'targetGoal': targetGoal,         // ✅ 추가
      'feedback': feedback,             // ✅ 추가
      'targetRating': targetRating,
      'totalDurationBefore': totalDurationBefore,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // 정보 수정 및 상태 업데이트를 위한 copyWith
  PracticeSessionModel copyWith({
    String? nickname,
    String? profileUrl,
    DateTime? startTime,
    String? machineType,
    String? shopName,
    bool? isActive,
    bool? isPaused,
    String? targetGoal,     // ✅ 추가
    String? feedback,       // ✅ 추가
    double? targetRating,
    int? totalDurationBefore,
  }) {
    return PracticeSessionModel(
      uid: uid,
      nickname: nickname ?? this.nickname,
      profileUrl: profileUrl ?? this.profileUrl,
      startTime: startTime ?? this.startTime,
      machineType: machineType ?? this.machineType,
      shopName: shopName ?? this.shopName,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      targetGoal: targetGoal ?? this.targetGoal, // ✅ 추가
      feedback: feedback ?? this.feedback,     // ✅ 추가
      targetRating: targetRating ?? this.targetRating,
      totalDurationBefore: totalDurationBefore ?? this.totalDurationBefore,
    );
  }

  // 현재 세션 시간 + 이전 누적 시간을 더해 '오늘 전체 연습 시간'을 계산
  Duration getTodayTotalDuration() {
    if (!isActive) return Duration(milliseconds: totalDurationBefore);

    final currentSessionDuration = DateTime.now().difference(startTime);
    return currentSessionDuration + Duration(milliseconds: totalDurationBefore);
  }
}