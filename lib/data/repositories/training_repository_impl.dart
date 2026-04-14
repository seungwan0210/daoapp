// lib/data/repositories/training_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/repositories/training_repository.dart';

class TrainingRepositoryImpl implements TrainingRepository {
  final FirebaseFirestore _firestore;

  TrainingRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingSessions');
  }

  /// 🔹 진행 메타(게이지/티어/사이클) 문서
  DocumentReference<Map<String, dynamic>> _progressDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('trainingMeta')
        .doc('trainingProgress');
  }

  @override
  Future<String> createSession(TrainingSessionModel session) async {
    final ref = await _sessionCollection(session.userId).add(session.toJson());
    return ref.id;
  }

  @override
  Future<void> updateSession(TrainingSessionModel session) async {
    if (session.id == null || session.id!.isEmpty) {
      throw ArgumentError('Session id is required for update.');
    }
    await _sessionCollection(session.userId)
        .doc(session.id)
        .update(session.toJson());
  }

  @override
  Stream<List<TrainingSessionModel>> watchRecentSessions({
    required String userId,
    int limit = 50, // 🔹 인터페이스 기본값과 맞춤
  }) {
    return _sessionCollection(userId)
        .orderBy('endedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        return TrainingSessionModel.fromJson(doc.id, doc.data());
      }).toList();
    });
  }

  @override
  Future<List<TrainingSessionModel>> fetchSessionsByDrill({
    required String userId,
    required String drillId,
    int limit = 100, // 🔹 인터페이스 기본값과 맞춤
  }) async {
    final snap = await _sessionCollection(userId)
        .where('drillId', isEqualTo: drillId)
        .orderBy('endedAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((doc) => TrainingSessionModel.fromJson(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<TrainingSessionModel?> fetchLastSessionForDrill({
    required String userId,
    required String drillId,
  }) async {
    final snap = await _sessionCollection(userId)
        .where('drillId', isEqualTo: drillId)
        .orderBy('endedAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return TrainingSessionModel.fromJson(doc.id, doc.data());
  }

  // ===========================================================
  // 🔹 사이클 / 티어 / XP 게이지 관련 구현
  // ===========================================================

  /// 새 사이클 ID 만드는 간단한 헬퍼
  /// 예: cycle_challenger_20251211_231530
  String _buildCycleId(DaoTrainingTier tier, DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return 'cycle_${tier.name}_$y$m$d\_$hh$mm$ss';
  }

  DaoTrainingTier? _parseTierOrNull(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DaoTrainingTier.values
          .firstWhere((t) => t.name.toLowerCase() == raw.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> startNewCycleForTier({
    required String userId,
    required DaoTrainingTier tier,
  }) async {
    final ref = _progressDoc(userId);
    final now = DateTime.now();
    final newCycleId = _buildCycleId(tier, now);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (!snap.exists) {
        // 진행 문서가 아직 없으면 기본값으로 생성
        tx.set(ref, {
          'currentTier': tier.name,
          'cycleId': newCycleId,
          'totalXp': 0,
          'xpSinceLastCheck': 0,
          // 이미 필드가 있다면 그대로 쓰고, 없으면 기본 1000으로 봄
          'xpTargetPerCheck': 1000,
          'createdAt': now,
          'updatedAt': now,
          'lastCycleChangeAt': now,
        });
        return;
      }

      final data = snap.data() ?? <String, dynamic>{};
      final num xpTargetPerCheck = (data['xpTargetPerCheck'] ?? 1000) as num;

      tx.update(ref, {
        'currentTier': tier.name,
        'cycleId': newCycleId,
        'xpSinceLastCheck': 0,
        'xpTargetPerCheck': xpTargetPerCheck,
        'updatedAt': now,
        'lastCycleChangeAt': now,
      });
    });
  }

  @override
  Future<void> handleXpGaugeFull({
    required String userId,
    required DaoTrainingTier newTierAfterCheck,
  }) async {
    final ref = _progressDoc(userId);
    final now = DateTime.now();

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (!snap.exists) {
        // 만약 진행 문서가 없는데 호출됐다면,
        // 그냥 이 티어 기준 새 사이클로 초기화해 준다.
        final cycleId = _buildCycleId(newTierAfterCheck, now);
        tx.set(ref, {
          'currentTier': newTierAfterCheck.name,
          'cycleId': cycleId,
          'totalXp': 0,
          'xpSinceLastCheck': 0,
          'xpTargetPerCheck': 1000,
          'createdAt': now,
          'updatedAt': now,
          'lastTierCheckAt': now,
          'lastTierChangeAt': now,
        });
        return;
      }

      final data = snap.data() ?? <String, dynamic>{};

      final num totalXp = (data['totalXp'] ?? 0) as num;
      final num xpSinceLastCheck = (data['xpSinceLastCheck'] ?? 0) as num;
      final num xpTargetPerCheck = (data['xpTargetPerCheck'] ?? 1000) as num;

      final String? currentTierStr = data['currentTier'] as String?;
      final DaoTrainingTier? currentTier = _parseTierOrNull(currentTierStr);

      // 게이지 한 번 채운 만큼 totalXp에 반영
      final num newTotalXp = totalXp + xpSinceLastCheck;

      // 남은 XP(넘친 부분). 음수면 0으로
      final num overflow = xpSinceLastCheck - xpTargetPerCheck;
      final num newXpSinceLastCheck = overflow > 0 ? overflow : 0;

      final bool tierChanged =
          currentTier == null || currentTier != newTierAfterCheck;

      // 티어가 바뀌면 사이클도 새로 생성, 아니면 기존 cycleId 유지
      String? currentCycleId = data['cycleId'] as String?;
      if (currentCycleId == null || currentCycleId.isEmpty) {
        currentCycleId = _buildCycleId(
          currentTier ?? newTierAfterCheck,
          now,
        );
      }

      final String effectiveCycleId = tierChanged
          ? _buildCycleId(newTierAfterCheck, now)
          : currentCycleId;

      final update = <String, dynamic>{
        'totalXp': newTotalXp,
        'xpSinceLastCheck': newXpSinceLastCheck,
        'currentTier': newTierAfterCheck.name,
        'cycleId': effectiveCycleId,
        'updatedAt': now,
        'lastTierCheckAt': now,
      };

      if (tierChanged) {
        update['lastTierChangeAt'] = now;
      }

      tx.update(ref, update);
    });
  }
}
