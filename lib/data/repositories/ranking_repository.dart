import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ranking_game_model.dart';

class RankingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 📅 매달 고정된 이름의 하위 컬렉션을 반환하는 헬퍼 메소드
  /// 구조: free_rankings -> YYYY_MM (월별 문서) -> ranking_list (실제 데이터)
  CollectionReference<Map<String, dynamic>> get _currentRankingCol {
    final now = DateTime.now();
    final monthId = "${now.year}_${now.month.toString().padLeft(2, '0')}";

    return _db
        .collection('free_rankings')
        .doc(monthId)
        .collection('ranking_list');
  }

  /// 🏆 종목별 랭킹 스트림
  /// 실시간으로 TOP 30위까지의 데이터를 가져옵니다.
  Stream<List<RankingRecord>> getTopRankings(String primaryField, {int limit = 30}) {
    Query<Map<String, dynamic>> query = _currentRankingCol;

    if (primaryField == 'bestPpd') {
      query = query
          .orderBy('bestPpd', descending: true)
          .orderBy('bestMpr', descending: true)
          .orderBy('bestCountUp', descending: true);
    } else if (primaryField == 'bestMpr') {
      query = query
          .orderBy('bestMpr', descending: true)
          .orderBy('bestPpd', descending: true)
          .orderBy('bestCountUp', descending: true);
    } else if (primaryField == 'bestCountUp') {
      query = query
          .orderBy('bestCountUp', descending: true)
          .orderBy('bestPpd', descending: true)
          .orderBy('bestMpr', descending: true);
    }

    return query
        .limit(limit)
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => RankingRecord.fromFirestore(doc)).toList());
  }

  /// ✨ 유저 데이터 초기화/삭제 기능
  /// 본인 혹은 관리자가 특정 유저의 해당 월 기록을 삭제할 때 사용합니다.
  Future<void> resetMyRecord({
    required String uid,
    bool ppd = false,
    bool mpr = false,
    bool countUp = false,
  }) async {
    final ref = _currentRankingCol.doc(uid);
    try {
      await ref.delete();
    } catch (e) {
      print("랭킹 데이터 삭제 중 오류 발생: $e");
      rethrow;
    }
  }

  /// 🎯 최고 기록 갱신 및 유저 프로필(배지 반영용) 실시간 동기화
  /// 트랜잭션을 사용하여 기록 갱신의 원자성을 보장합니다.
  Future<void> updateBestRecord({
    required String uid,
    double? ppd,
    double? mpr,
    int? countUp,
  }) async {
    final userDocRef = _db.collection('users').doc(uid);
    final userDoc = await userDocRef.get();
    final userData = userDoc.data();
    final currentUser = FirebaseAuth.instance.currentUser;

    // 닉네임 및 프로필 URL 최신화
    String finalNickname = userData?['koreanName'] ?? currentUser?.displayName ?? "익명 유저";
    String? finalProfileUrl = userData?['profileImageUrl'] ?? currentUser?.photoURL;

    final rankingDocRef = _currentRankingCol.doc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(rankingDocRef);

      Map<String, dynamic> rankingUpdates = {
        'nickname': finalNickname,
        'profileImageUrl': finalProfileUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      Map<String, dynamic> userUpdates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!snap.exists) {
        // 첫 기록 등록 시 데이터 세팅
        final newData = {
          'userId': uid,
          'nickname': finalNickname,
          'profileImageUrl': finalProfileUrl,
          'bestPpd': ppd ?? 0.0,
          'bestMpr': mpr ?? 0.0,
          'bestCountUp': countUp ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        tx.set(rankingDocRef, newData);

        // 유저 문서에도 초기 기록 동기화
        tx.update(userDocRef, {
          'bestPpd': ppd ?? 0.0,
          'bestMpr': mpr ?? 0.0,
          'bestCountUp': countUp ?? 0,
        });
      } else {
        // 기존 기록 존재 시 비교 후 더 높은 점수일 때만 갱신
        final currentData = snap.data()!;
        final currentBestPpd = (currentData['bestPpd'] as num?)?.toDouble() ?? 0.0;
        final currentBestMpr = (currentData['bestMpr'] as num?)?.toDouble() ?? 0.0;
        final currentBestCountUp = (currentData['bestCountUp'] as num?)?.toInt() ?? 0;

        bool hasUpdate = false;

        if (ppd != null && ppd > currentBestPpd) {
          rankingUpdates['bestPpd'] = ppd;
          userUpdates['bestPpd'] = ppd;
          hasUpdate = true;
        }
        if (mpr != null && mpr > currentBestMpr) {
          rankingUpdates['bestMpr'] = mpr;
          userUpdates['bestMpr'] = mpr;
          hasUpdate = true;
        }
        if (countUp != null && countUp > currentBestCountUp) {
          rankingUpdates['bestCountUp'] = countUp;
          userUpdates['bestCountUp'] = countUp;
          hasUpdate = true;
        }

        // 공통 정보(닉네임 등) 업데이트
        tx.update(rankingDocRef, rankingUpdates);

        // 실제 점수 갱신이 일어난 경우에만 유저 문서 업데이트
        if (hasUpdate) {
          tx.update(userDocRef, userUpdates);
        }
      }
    });
  }
}