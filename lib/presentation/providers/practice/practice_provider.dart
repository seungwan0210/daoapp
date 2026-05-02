import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/data/models/practice_session_model.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 1. 현재 로그인한 유저의 실시간 연습 세션을 감시
/// ✅ autoDispose를 추가하여 로그아웃이나 화면 전환 시 메모리에서 즉시 제거합니다.
final myPracticeSessionProvider = StreamProvider.autoDispose<PracticeSessionModel?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('practice_sessions')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return PracticeSessionModel.fromFirestore(doc);
  });
});

/// 2. 이동 중 시간 합산형 타이머
final practiceTimerProvider = StreamProvider.autoDispose<Duration>((ref) {
  final sessionAsync = ref.watch(myPracticeSessionProvider);

  return sessionAsync.when(
    data: (session) {
      if (session == null || !session.isActive || session.isPaused) {
        final initialDuration = session != null
            ? Duration(milliseconds: session.totalDurationBefore)
            : Duration.zero;
        return Stream.value(initialDuration);
      }

      return Stream.periodic(const Duration(seconds: 1), (_) {
        return session.getTodayTotalDuration();
      });
    },
    loading: () => Stream.value(Duration.zero),
    error: (_, __) => Stream.value(Duration.zero),
  );
});

/// 3. [수정] 전체 보기용 연습 유저 리스트 프로바이더
/// ✅ 그리드 제한(.take(9))을 제거하고 전체 목록을 반환하도록 변경했습니다.
final livePracticeUsersProvider = StreamProvider.autoDispose<List<PracticeSessionModel>>((ref) {
  final blockedIds = ref.watch(blockedUserIdsProvider).value ?? {};
  final currentUid = FirebaseAuth.instance.currentUser?.uid;

  final now = DateTime.now();
  final threshold = DateTime(now.year, now.month, now.day, 4, 0, 0);
  final finalThreshold = now.isBefore(threshold)
      ? threshold.subtract(const Duration(days: 1))
      : threshold;

  return FirebaseFirestore.instance
      .collection('practice_sessions')
      .where('isActive', isEqualTo: true)
      .where('updatedAt', isGreaterThan: Timestamp.fromDate(finalThreshold))
      .snapshots()
      .map((snapshot) {
    final list = snapshot.docs
        .map((doc) => PracticeSessionModel.fromFirestore(doc))
        .where((session) {
      if (blockedIds.contains(session.uid)) return false;
      if (session.uid == currentUid) return false;
      return true;
    }).toList();

    // 오늘 총 연습 시간 순 정렬
    list.sort((a, b) => b.getTodayTotalDuration().compareTo(a.getTodayTotalDuration()));

    return list; // ✅ 전체 목록 반환
  });
});

/// 4. 오늘 총 몇 명이 연습 중인지 카운트
/// ✅ 실시간 리스트와 싱크를 맞추기 위해 livePracticeUsersProvider를 활용할 수도 있지만,
/// 단순 카운트가 필요할 때를 위해 유지합니다.
final totalPracticingCountProvider = StreamProvider.autoDispose<int>((ref) {
  return FirebaseFirestore.instance
      .collection('practice_sessions')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs.length);
});