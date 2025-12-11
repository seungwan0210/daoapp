// lib/presentation/providers/training/training_history_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/repositories/training_repository.dart';
import 'package:daoapp/data/repositories/auth_repository.dart';
import 'package:daoapp/di/service_locator.dart';

/// 현재 로그인한 유저의 ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authRepo = sl<AuthRepository>();
  return authRepo.currentUser?.uid;
});

/// 최근 트레이닝 세션 (최대 100개로 늘림 ← 이거만 바꿔!)
/// 50개 → 100개로 늘리면 그래프가 훨씬 풍성해짐 (추천!)
final trainingRecentSessionsProvider =
StreamProvider.autoDispose<List<TrainingSessionModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final repo = sl<TrainingRepository>();
  return repo.watchRecentSessions(userId: userId, limit: 100); // ← 50 → 100
});

/// 특정 드릴의 모든 기록 (최대 100개)
final drillHistoryProvider =
FutureProvider.autoDispose.family<List<TrainingSessionModel>, String>(
        (ref, drillId) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return const <TrainingSessionModel>[];

      final repo = sl<TrainingRepository>();
      return await repo.fetchSessionsByDrill(
        userId: userId,
        drillId: drillId,
        limit: 100,
      );
    });

/// 오늘 한 특정 드릴 세션들 (오늘 날짜 기준 필터링)
final todayDrillSessionsProvider =
Provider.autoDispose.family<List<TrainingSessionModel>, String>(
        (ref, drillId) {
      final historyAsync = ref.watch(drillHistoryProvider(drillId));

      return historyAsync.when(
        data: (sessions) {
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = todayStart.add(const Duration(days: 1));

          return sessions.where((session) {
            final endedAt = session.endedAt;
            return endedAt.isAfter(todayStart) && endedAt.isBefore(todayEnd);
          }).toList();
        },
        loading: () => const <TrainingSessionModel>[],
        error: (_, __) => const <TrainingSessionModel>[],
      );
    });

/// 특정 드릴의 가장 최근 완료 세션
final lastSessionForDrillProvider =
FutureProvider.autoDispose.family<TrainingSessionModel?, String>(
        (ref, drillId) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return null;

      final repo = sl<TrainingRepository>();
      return await repo.fetchLastSessionForDrill(
        userId: userId,
        drillId: drillId,
      );
    });

/// =======================
/// 🔹 히스토리 사이클 필터
/// =======================

/// 선택된 사이클 ID (null 이면 "전체")
final selectedCycleIdProvider = StateProvider<String?>((ref) => null);

/// 선택된 사이클 기준으로 필터링된 히스토리
///
/// - trainingRecentSessionsProvider 에서 전체 세션을 가져오고
/// - selectedCycleIdProvider 에 따라 필터링한 AsyncValue를 제공
final filteredTrainingHistoryProvider =
Provider.autoDispose<AsyncValue<List<TrainingSessionModel>>>((ref) {
  final baseAsync = ref.watch(trainingRecentSessionsProvider);
  final selectedCycleId = ref.watch(selectedCycleIdProvider);

  return baseAsync.whenData((sessions) {
    if (selectedCycleId == null || selectedCycleId.isEmpty) {
      // 🔹 전체 보기
      return sessions;
    }

    // 🔹 해당 cycleId만 보기
    return sessions.where((s) => s.cycleId == selectedCycleId).toList();
  });
});