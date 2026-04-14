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
    if (record.id == null || record.id!.isEmpty) {
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
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => PointRecord.fromMap(doc.id, doc.data(), userData))
          .toList(),
    );
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
          final userDoc =
          await _firestore.collection('users').doc(userId).get();
          userCache[userId] = userDoc.data() ?? {};
        }

        records.add(
          PointRecord.fromMap(doc.id, data, userCache[userId]),
        );
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
      // 1) 랭킹에 참여하는 userId 모으기
      final userIds = <String>{};
      for (var doc in snapshot.docs) {
        userIds.add(doc['userId'] as String);
      }
      if (userIds.isEmpty) return [];

      // 2) users 컬렉션에서 정보 가져오기 (whereIn 배치 처리)
      final userMap = <String, Map<String, dynamic>>{};
      const int batchSize = 10; // Firestore whereIn 최대 10개

      final ids = userIds.toList();
      for (int i = 0; i < ids.length; i += batchSize) {
        final end = (i + batchSize < ids.length) ? i + batchSize : ids.length;
        final batchIds = ids.sublist(i, end);

        final usersSnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (var doc in usersSnapshot.docs) {
          userMap[doc.id] = doc.data();
        }
      }

      // 3) 포인트 합산 + 성별 필터 + Top9 계산 준비
      final rankingMap = <String, RankingUser>{};
      final userPointsList = <String, List<int>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;
        final points = data['points'] as int;
        final userData = userMap[userId];

        // users 컬렉션에 문서가 없으면 스킵
        if (userData == null) continue;

        // 성별 필터
        if (gender != 'all' && userData['gender'] != gender) {
          continue;
        }

        userPointsList.putIfAbsent(userId, () => []).add(points);

        rankingMap.putIfAbsent(
          userId,
              () => RankingUser(
            userId: userId,
            koreanName: userData['koreanName'] ?? 'Unknown',
            englishName: userData['englishName'] ?? '',
            shopName: userData['shopName'] ?? '',
            gender: userData['gender'] ?? '',
            totalPoints: 0,
          ),
        );

        rankingMap[userId]!.totalPoints += points;
      }

      // 4) Top9 모드 처리 (통합은 항상 전체)
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

      // 5) 정렬 + rank 부여
      final rankings = rankingMap.values.toList();
      rankings.sort(
            (a, b) => (b.top9Points ?? b.totalPoints)
            .compareTo(a.top9Points ?? a.totalPoints),
      );

      for (int i = 0; i < rankings.length; i++) {
        rankings[i].rank = i + 1;
      }

      return rankings;
    });
  }
}
