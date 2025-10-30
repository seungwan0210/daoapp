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

    // users.totalPoints 업데이트 (통합용)
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
  Stream<List<RankingUser>> getRanking({
    required String seasonId,
    required String phase,
    required String gender,
    required bool top9Mode,
  }) {
    // 쿼리 시작
    var query = _firestore
        .collection('point_records')
        .where('seasonId', isEqualTo: seasonId);

    // 통합: 모든 시즌 합산 (phase 필터 X)
    if (phase != 'total') {
      query = query.where('phase', isEqualTo: phase);
    }

    return query.snapshots().asyncMap((snapshot) async {
      final userIds = <String>{};
      for (var doc in snapshot.docs) {
        userIds.add(doc['userId'] as String);
      }
      if (userIds.isEmpty) return [];

      // 사용자 정보 가져오기
      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds.toList())
          .get();

      final userMap = <String, Map<String, dynamic>>{};
      for (var doc in usersSnapshot.docs) {
        userMap[doc.id] = doc.data();
      }

      final rankingMap = <String, RankingUser>{};
      final userPointsList = <String, List<int>>{}; // 각 사용자별 포인트 리스트

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;
        final points = data['points'] as int;
        final userData = userMap[userId];

        if (userData == null || userData['gender'] != gender) continue;

        // 사용자별 포인트 기록 수집
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

      // 상위 9개 계산: 통합이면 무조건 전체, 시즌이면 top9Mode에 따라
      if (top9Mode && phase != 'total') {
        for (var entry in userPointsList.entries) {
          final userId = entry.key;
          final pointsList = entry.value;
          if (pointsList.isNotEmpty) {
            pointsList.sort((a, b) => b.compareTo(a)); // 내림차순
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