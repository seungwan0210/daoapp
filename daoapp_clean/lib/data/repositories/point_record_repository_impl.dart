// lib/data/repositories/point_record_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'point_record_repository.dart';
import '../models/point_record_model.dart';
import '../models/ranking_user.dart';

class PointRecordRepositoryImpl implements PointRecordRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> awardPoints(PointRecord record) async {
    final batch = _firestore.batch();

    final recordRef = _firestore.collection('point_records').doc();
    final newRecord = record.copyWith(id: recordRef.id);
    batch.set(recordRef, newRecord.toMap());

    final userRef = _firestore.collection('users').doc(record.userId);
    batch.update(userRef, {
      'totalPoints': FieldValue.increment(record.points),
    });

    await batch.commit();
  }

  @override
  Future<void> updatePointRecord(PointRecord record, int oldPoints) async {
    if (record.id == null || record.id!.isEmpty) {  // ← ?.isEmpty 대신 이렇게!
      throw Exception('포인트 기록 ID가 없습니다.');
    }

    final diff = record.points - oldPoints;
    final batch = _firestore.batch();

    // 1. 포인트 기록 업데이트
    final recordRef = _firestore.collection('point_records').doc(record.id);
    batch.update(recordRef, record.toMap());

    // 2. 유저 totalPoints 조정
    final userRef = _firestore.collection('users').doc(record.userId);
    batch.update(userRef, {
      'totalPoints': FieldValue.increment(diff),
    });

    await batch.commit();
  }

  @override
  Future<void> deletePointRecord(String recordId, String userId, int points) async {
    final batch = _firestore.batch();

    // 1. 포인트 기록 삭제
    final recordRef = _firestore.collection('point_records').doc(recordId);
    batch.delete(recordRef);

    // 2. 유저 totalPoints 감소
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'totalPoints': FieldValue.increment(-points),
    });

    await batch.commit();
  }

  @override
  Stream<List<PointRecord>> getUserPointHistory(String userId) async* {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    yield* _firestore
        .collection('point_records')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PointRecord.fromMap(doc.id, doc.data(), userData))
        .toList());
  }

  @override
  Stream<List<PointRecord>> getAllPointRecords() async* {
    final recordsSnapshot = _firestore
        .collection('point_records')
        .orderBy('date', descending: true)
        .snapshots();

    final userCache = <String, Map<String, dynamic>>{};

    yield* recordsSnapshot.asyncMap((snapshot) async {
      final List<PointRecord> records = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;

        if (!userCache.containsKey(userId)) {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          userCache[userId] = userDoc.data() ?? {};
        }

        records.add(PointRecord.fromMap(doc.id, data, userCache[userId]));
      }

      return records;
    });
  }

  @override
  Stream<List<RankingUser>> getRanking({
    required String seasonId,
    required String phase,
    required String gender,
    required bool top9Mode,
  }) {
    var query = _firestore
        .collection('point_records')
        .where('seasonId', isEqualTo: seasonId);

    if (phase != 'total') {
      query = query.where('phase', isEqualTo: phase);
    }

    return query.snapshots().asyncMap((snapshot) async {
      final userIds = <String>{};
      for (var doc in snapshot.docs) {
        userIds.add(doc['userId'] as String);
      }
      if (userIds.isEmpty) return [];

      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds.toList())
          .get();

      final userMap = <String, Map<String, dynamic>>{};
      for (var doc in usersSnapshot.docs) {
        userMap[doc.id] = doc.data();
      }

      final rankingMap = <String, RankingUser>{};
      final userPointsList = <String, List<int>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;
        final points = data['points'] as int;
        final userData = userMap[userId];

        // 성별 필터
        if (gender != 'all' && (userData == null || userData['gender'] != gender)) {
          continue;
        }

        userPointsList.putIfAbsent(userId, () => []).add(points);

        rankingMap.putIfAbsent(userId, () => RankingUser(
          userId: userId,
          koreanName: userData?['koreanName'] ?? 'Unknown',
          englishName: userData?['englishName'] ?? '',
          shopName: userData?['shopName'] ?? '',
          gender: userData?['gender'] ?? '',
          totalPoints: 0,
        ));

        rankingMap[userId]!.totalPoints += points;
      }

      if (top9Mode && phase != 'total') {
        for (var entry in userPointsList.entries) {
          final userId = entry.key;
          final pointsList = entry.value;
          if (pointsList.isNotEmpty) {
            pointsList.sort((a, b) => b.compareTo(a));
            final top9Sum = pointsList.length > 9
                ? pointsList.take(9).reduce((a, b) => a + b)
                : pointsList.reduce((a, b) => a + b);
            rankingMap[userId]!.top9Points = top9Sum;
          }
        }
      }

      final rankings = rankingMap.values.toList();
      rankings.sort((a, b) =>
          (b.top9Points ?? b.totalPoints).compareTo(a.top9Points ?? a.totalPoints));

      for (int i = 0; i < rankings.length; i++) {
        rankings[i].rank = i + 1;
      }
      return rankings;
    });
  }
}