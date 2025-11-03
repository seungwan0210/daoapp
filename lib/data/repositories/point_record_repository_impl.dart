// lib/data/repositories/point_record_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'point_record_repository.dart';
import '../models/point_record_model.dart';
import '../models/ranking_user.dart';

class PointRecordRepositoryImpl implements PointRecordRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> awardPoints(PointRecord record) async {
    await _firestore.collection('point_records').add(record.toMap());

    // users.totalPoints 업데이트
    final userRef = _firestore.collection('users').doc(record.userId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(userRef);
      if (snapshot.exists) {
        final current = snapshot.data()?['totalPoints'] ?? 0;
        tx.update(userRef, {'totalPoints': current + record.points});
      } else {
        tx.set(userRef, {'totalPoints': record.points}, SetOptions(merge: true));
      }
    });
  }

  @override
  Future<void> updatePointRecord(PointRecord record) async {
    // 기존 포인트 가져오기
    final oldDoc = await _firestore.collection('point_records').doc(record.id).get();
    final oldPoints = (oldDoc.data()?['points'] as int?) ?? 0;
    final diff = record.points - oldPoints;

    // 포인트 기록 업데이트
    await _firestore.collection('point_records').doc(record.id).update(record.toMap());

    // users.totalPoints 조정
    final userRef = _firestore.collection('users').doc(record.userId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(userRef);
      if (snapshot.exists) {
        final current = snapshot.data()?['totalPoints'] ?? 0;
        tx.update(userRef, {'totalPoints': current + diff});
      }
    });
  }

  @override
  Future<void> deletePointRecord(String recordId, String userId, int points) async {
    // 포인트 기록 삭제
    await _firestore.collection('point_records').doc(recordId).delete();

    // users.totalPoints 감소
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(userRef);
      if (snapshot.exists) {
        final current = snapshot.data()?['totalPoints'] ?? 0;
        tx.update(userRef, {'totalPoints': current - points});
      }
    });
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
    // 모든 point_records 가져오기
    final recordsSnapshot = _firestore
        .collection('point_records')
        .orderBy('date', descending: true)
        .snapshots();

    // 사용자 정보 캐시
    final userCache = <String, Map<String, dynamic>>{};

    yield* recordsSnapshot.asyncMap((snapshot) async {
      final List<PointRecord> records = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;

        // 캐시에서 사용자 정보 가져오기
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

        if (userData == null || userData['gender'] != gender) continue;

        userPointsList.putIfAbsent(userId, () => []).add(points);

        rankingMap.putIfAbsent(userId, () => RankingUser(
          userId: userId,
          koreanName: userData['koreanName'] ?? 'Unknown',
          englishName: userData['englishName'] ?? '',
          shopName: userData['shopName'] ?? '',
          gender: userData['gender'] ?? '',
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