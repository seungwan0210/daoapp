import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/ranking_game_model.dart';
import 'package:daoapp/core/utils/chat_utils.dart';
import 'package:daoapp/core/constants/badge_constants.dart';

class RankingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 📅 월별 랭킹 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _currentRankingCol {
    final now = DateTime.now();
    final monthId = "${now.year}_${now.month.toString().padLeft(2, '0')}";
    return _db.collection('free_rankings').doc(monthId).collection('ranking_list');
  }

  /// 🏆 [순위 계산] 특정 필드 기준 현재 순위 산출
  Future<int> _getCurrentRank(String field, double value) async {
    final snap = await _currentRankingCol.where(field, isGreaterThan: value).get();
    return snap.docs.length + 1;
  }

  /// 🏆 [통합 순위 계산] 합산 점수 기준 전체 순위 산출
  Future<int> _getTotalRank(double totalScore) async {
    final snap = await _currentRankingCol.get();
    int rank = 1;
    for (var doc in snap.docs) {
      final d = doc.data();
      // 통합 점수 공식: PPD + (MPR * 10) + (CountUp / 10)
      double score = (d['bestPpd'] ?? 0.0) + ((d['bestMpr'] ?? 0.0) * 10) + ((d['bestCountUp'] ?? 0) / 10);
      if (score > totalScore) rank++;
    }
    return rank;
  }

  /// 🏆 종목별 랭킹 스트림 (Top 30)
  Stream<List<RankingRecord>> getTopRankings(String primaryField, {int limit = 30}) {
    Query<Map<String, dynamic>> query = _currentRankingCol;

    if (primaryField == 'bestPpd') {
      query = query.orderBy('bestPpd', descending: true).orderBy('bestMpr', descending: true).orderBy('bestCountUp', descending: true);
    } else if (primaryField == 'bestMpr') {
      query = query.orderBy('bestMpr', descending: true).orderBy('bestPpd', descending: true).orderBy('bestCountUp', descending: true);
    } else if (primaryField == 'bestCountUp') {
      query = query.orderBy('bestCountUp', descending: true).orderBy('bestPpd', descending: true).orderBy('bestMpr', descending: true);
    }

    return query.limit(limit).snapshots().map((snap) => snap.docs.map((doc) => RankingRecord.fromFirestore(doc)).toList());
  }

  /// ✨ 기록 삭제 기능
  Future<void> resetMyRecord({required String uid}) async {
    try {
      await _currentRankingCol.doc(uid).delete();
    } catch (e) {
      debugPrint("❌ 랭킹 삭제 실패: $e");
      rethrow;
    }
  }

  /// 🎯 [핵심] 최고 기록 갱신 및 조건부 통합 공지 로직
  Future<void> updateBestRecord({
    required String uid,
    double? ppd,
    double? mpr,
    int? countUp,
  }) async {
    final userDocRef = _db.collection('users').doc(uid);
    final rankingDocRef = _currentRankingCol.doc(uid);

    final userDoc = await userDocRef.get();
    final userData = userDoc.data();
    final currentUser = FirebaseAuth.instance.currentUser;
    final String finalNickname = userData?['koreanName'] ?? currentUser?.displayName ?? "익명";

    // 1. 업데이트 전 통합 순위 미리 파악 (순위 상승 비교용)
    int oldTotalRank = 999;
    if (userDoc.exists) {
      double oldScore = (userData?['bestPpd'] ?? 0.0) + ((userData?['bestMpr'] ?? 0.0) * 10) + ((userData?['bestCountUp'] ?? 0) / 10);
      oldTotalRank = await _getTotalRank(oldScore);
    }

    bool isScoreUpdated = false;
    String? gameTypeForNotice;
    double? updatedValue;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(rankingDocRef);
      Map<String, dynamic> up = {
        'nickname': finalNickname,
        'profileImageUrl': userData?['profileImageUrl'] ?? currentUser?.photoURL,
        'updatedAt': FieldValue.serverTimestamp()
      };

      if (!snap.exists) {
        // 첫 등록 상황
        tx.set(rankingDocRef, {
          ...up,
          'userId': uid,
          'bestPpd': ppd ?? 0.0,
          'bestMpr': mpr ?? 0.0,
          'bestCountUp': countUp ?? 0,
        });
        isScoreUpdated = true;
        gameTypeForNotice = (ppd != null) ? '501' : (mpr != null ? '크리켓' : '카운트업');
        updatedValue = ppd ?? (mpr ?? (countUp?.toDouble()));
      } else {
        // 기존 기록 비교
        final d = snap.data()!;
        bool hasBetter = false;

        if (ppd != null && ppd > (d['bestPpd'] ?? 0.0)) {
          up['bestPpd'] = ppd; hasBetter = true; gameTypeForNotice = '501'; updatedValue = ppd;
        }
        if (mpr != null && mpr > (d['bestMpr'] ?? 0.0)) {
          up['bestMpr'] = mpr; hasBetter = true; gameTypeForNotice = '크리켓'; updatedValue = mpr;
        }
        if (countUp != null && countUp > (d['bestCountUp'] ?? 0)) {
          up['bestCountUp'] = countUp; hasBetter = true; gameTypeForNotice = '카운트업'; updatedValue = countUp.toDouble();
        }

        tx.update(rankingDocRef, up);
        if (hasBetter) {
          tx.update(userDocRef, up);
          isScoreUpdated = true;
        }
      }
    });

    // 🔥 2. 공지 발송
    if (isScoreUpdated) {
      try {
        // [A] 종목별 공지: 순위와 상관없이 기록 갱신 시 항상 발송
        String field = gameTypeForNotice == '501' ? 'bestPpd' : (gameTypeForNotice == '크리켓' ? 'bestMpr' : 'bestCountUp');
        int currentRank = await _getCurrentRank(field, updatedValue ?? 0.0);

        await ChatUtils.sendRankingNotice(
          nickname: finalNickname,
          badgeKey: 'tro',
          rank: '$currentRank위',
          isTotalRanking: false,
          gameType: gameTypeForNotice,
        );

        // [B] 통합 순위 공지: 순위가 올랐고 + 결과가 10위 이내일 때만 발송
        double newTotalScore = (ppd ?? (userData?['bestPpd'] ?? 0.0)) +
            ((mpr ?? (userData?['bestMpr'] ?? 0.0)) * 10) +
            ((countUp ?? (userData?['bestCountUp'] ?? 0)) / 10);
        int newTotalRank = await _getTotalRank(newTotalScore);

        if (newTotalRank < oldTotalRank && newTotalRank <= 10) {
          await ChatUtils.sendRankingNotice(
            nickname: finalNickname,
            // 순위에 맞는 배지(금/은/동 등) 자동 매칭
            badgeKey: BadgeConstants.badgeKeyForRank(newTotalRank) ?? 'pro',
            rank: '$newTotalRank위',
            isTotalRanking: true,
          );
        }
        debugPrint("✅ [$finalNickname] 랭킹 공지 프로세스 완료");
      } catch (e) {
        debugPrint("❌ 공지 전송 중 에러: $e");
      }
    }
  }
}