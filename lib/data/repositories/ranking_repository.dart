import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/ranking_game_model.dart';
import 'package:daoapp/core/utils/chat_utils.dart';
import 'package:daoapp/core/constants/badge_constants.dart';

class RankingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 📅 월별 랭킹 루트 참조
  DocumentReference get _monthRootDoc {
    final now = DateTime.now();
    final monthId = "${now.year}_${now.month.toString().padLeft(2, '0')}";
    return _db.collection('free_rankings').doc(monthId);
  }

  /// 1️⃣ 기존 종목별 점수 컬렉션 (ranking_provider에서 이 곳을 참조합니다)
  CollectionReference<Map<String, dynamic>> get _currentRankingCol =>
      _monthRootDoc.collection('ranking_list');

  /// 2️⃣ 통합 순위/포인트 저장 컬렉션
  CollectionReference<Map<String, dynamic>> get _totalRankingCol =>
      _monthRootDoc.collection('total_rankings');

  // 🔥 [에러 해결 포인트] StreamProvider가 사용하는 핵심 함수 추가
  /// 🏆 종목별 랭킹 스트림 (정렬 로직 포함)
  Stream<List<RankingRecord>> getTopRankings(String primaryField, {int limit = 30}) {
    Query<Map<String, dynamic>> query = _currentRankingCol;

    if (primaryField == 'bestPpd') {
      query = query.orderBy('bestPpd', descending: true).orderBy('bestMpr', descending: true).orderBy('bestCountUp', descending: true);
    } else if (primaryField == 'bestMpr') {
      query = query.orderBy('bestMpr', descending: true).orderBy('bestPpd', descending: true).orderBy('bestCountUp', descending: true);
    } else if (primaryField == 'bestCountUp') {
      query = query.orderBy('bestCountUp', descending: true).orderBy('bestPpd', descending: true).orderBy('bestMpr', descending: true);
    }

    return query.limit(limit).snapshots().map((snap) =>
        snap.docs.map((doc) => RankingRecord.fromFirestore(doc)).toList());
  }

  /// 🏆 [종목별 개별 순위 계산]
  Future<int> _getCurrentRank(String field, double value) async {
    final snap = await _currentRankingCol.where(field, isGreaterThan: value).get();
    return snap.docs.length + 1;
  }

  /// 🏆 [통합 순위 계산 및 DB 저장]
  Future<int> _updateAndGetTotalRank(String targetUid, {double? newPpd, double? newMpr, int? newCountUp}) async {
    final snap = await _currentRankingCol.get();
    final docs = snap.docs;

    List<Map<String, dynamic>> ppdList = docs.map((e) => {'uid': e.id, 'val': (e.data()['bestPpd'] as num?)?.toDouble() ?? 0.0}).toList();
    List<Map<String, dynamic>> mprList = docs.map((e) => {'uid': e.id, 'val': (e.data()['bestMpr'] as num?)?.toDouble() ?? 0.0}).toList();
    List<Map<String, dynamic>> cuList = docs.map((e) => {'uid': e.id, 'val': (e.data()['bestCountUp'] as num?)?.toDouble() ?? 0.0}).toList();

    void updateList(List<Map<String, dynamic>> list, String uid, double val) {
      int idx = list.indexWhere((e) => e['uid'] == uid);
      if (idx != -1) { if (val > list[idx]['val']) list[idx]['val'] = val; }
      else { list.add({'uid': uid, 'val': val}); }
    }
    if (newPpd != null) updateList(ppdList, targetUid, newPpd);
    if (newMpr != null) updateList(mprList, targetUid, newMpr);
    if (newCountUp != null) updateList(cuList, targetUid, newCountUp.toDouble());

    ppdList.sort((a, b) => b['val'].compareTo(a['val']));
    mprList.sort((a, b) => b['val'].compareTo(a['val']));
    cuList.sort((a, b) => b['val'].compareTo(a['val']));

    Map<String, int> userPoints = {};
    void calculate(List<Map<String, dynamic>> list) {
      for (int i = 0; i < list.length && i < 10; i++) {
        String uid = list[i]['uid'];
        userPoints[uid] = (userPoints[uid] ?? 0) + (10 - i);
      }
    }
    calculate(ppdList); calculate(mprList); calculate(cuList);

    int myScore = userPoints[targetUid] ?? 0;
    if (myScore == 0) return 999;

    int myRank = 1;
    userPoints.forEach((uid, score) { if (score > myScore) myRank++; });

    // 통합 순위 컬렉션 업데이트
    await _totalRankingCol.doc(targetUid).set({
      'rank': myRank,
      'totalPoints': myScore,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return myRank;
  }

  /// ✨ 기록 삭제 기능
  Future<void> resetMyRecord({required String uid}) async {
    try {
      await _currentRankingCol.doc(uid).delete();
      await _totalRankingCol.doc(uid).delete();
    } catch (e) {
      debugPrint("❌ 랭킹 삭제 실패: $e");
      rethrow;
    }
  }

  /// 🎯 [핵심] 최고 기록 갱신 및 공지 실행
  Future<void> updateBestRecord({
    required String uid,
    double? ppd,
    double? mpr,
    int? countUp,
  }) async {
    final userDocRef = _db.collection('users').doc(uid);
    final rankingDocRef = _currentRankingCol.doc(uid);

    final userDoc = await userDocRef.get();
    final String finalNickname = userDoc.data()?['koreanName'] ?? "익명";

    final totalSnap = await _totalRankingCol.doc(uid).get();
    int oldTotalRank = totalSnap.exists ? (totalSnap.data()?['rank'] ?? 999) : 999;

    bool isScoreUpdated = false;
    String? gameType;
    double? updatedVal;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(rankingDocRef);
      Map<String, dynamic> up = {'nickname': finalNickname, 'updatedAt': FieldValue.serverTimestamp()};

      if (!snap.exists) {
        tx.set(rankingDocRef, {...up, 'userId': uid, 'bestPpd': ppd ?? 0.0, 'bestMpr': mpr ?? 0.0, 'bestCountUp': countUp ?? 0});
        isScoreUpdated = true;
        gameType = (ppd != null) ? '501' : (mpr != null ? '크리켓' : '카운트업');
        updatedVal = ppd ?? (mpr ?? countUp?.toDouble());
      } else {
        final d = snap.data()!;
        bool hasBetter = false;
        if (ppd != null && ppd > (d['bestPpd'] ?? 0.0)) { up['bestPpd'] = ppd; hasBetter = true; gameType = '501'; updatedVal = ppd; }
        if (mpr != null && mpr > (d['bestMpr'] ?? 0.0)) { up['bestMpr'] = mpr; hasBetter = true; gameType = '크리켓'; updatedVal = mpr; }
        if (countUp != null && countUp > (d['bestCountUp'] ?? 0)) { up['bestCountUp'] = countUp; hasBetter = true; gameType = '카운트업'; updatedVal = countUp.toDouble(); }

        if (hasBetter) { tx.update(rankingDocRef, up); tx.update(userDocRef, up); isScoreUpdated = true; }
      }
    });

    if (isScoreUpdated) {
      try {
        int currentRank = await _getCurrentRank(gameType == '501' ? 'bestPpd' : (gameType == '크리켓' ? 'bestMpr' : 'bestCountUp'), updatedVal ?? 0.0);
        await ChatUtils.sendRankingNotice(nickname: finalNickname, badgeKey: 'tro', rank: '$currentRank위', isTotalRanking: false, gameType: gameType);

        int newTotalRank = await _updateAndGetTotalRank(uid, newPpd: ppd, newMpr: mpr, newCountUp: countUp);

        debugPrint("📊 통합 순위 변동: $oldTotalRank위 -> $newTotalRank위");

        if (newTotalRank < oldTotalRank && newTotalRank <= 10) {
          await ChatUtils.sendRankingNotice(
            nickname: finalNickname,
            badgeKey: _getBadgeKey(newTotalRank),
            rank: '$newTotalRank',
            isTotalRanking: true,
          );
        }
      } catch (e) {
        debugPrint("❌ 공지 전송 에러: $e");
      }
    }
  }

  String _getBadgeKey(int rank) {
    switch (rank) {
      case 1: return 'pro'; case 2: return 'diamond'; case 3: return 'emerald';
      case 4: return 'platinum1'; case 5: return 'platinum2';
      case 6: return 'gold1'; case 7: return 'gold2';
      case 8: return 'silver1'; case 9: return 'silver2';
      case 10: return 'bronze1'; default: return 'pro';
    }
  }
}