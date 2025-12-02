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

/// 최근 트레이닝 세션 히스토리 (최대 50개)
final trainingRecentSessionsProvider =
StreamProvider.autoDispose<List<TrainingSessionModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value(const <TrainingSessionModel>[]);
  }

  final repo = sl<TrainingRepository>();
  return repo.watchRecentSessions(userId: userId, limit: 50);
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
            final endedAt = session.endedAt; // ✅ 새 모델 필드 사용
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
