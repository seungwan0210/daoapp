import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ChatUtils {
  /// 1. 신규 유저 환영 공지
  static Future<void> sendWelcomeNotice(String nickname) {
    return _send(
      msg: '👋 $nickname님이 DAO Darts에 합류했습니다. 모두 환영해주세요!',
      category: 'WELCOME',
    );
  }

  /// 2. 대회 관련 공지 (개설 및 마감 임박 공용)
  static Future<void> sendTournamentNotice(String shopName, String tournamentId, {String? customMsg}) {
    return _send(
      msg: customMsg ?? '🏆 [$shopName] 새로운 대회가 개설되었습니다! 지금 확인해보세요.',
      category: 'TOURNAMENT',
      targetId: tournamentId,
    );
  }

  /// 3. 🔥 랭킹 관련 공지 (통합 랭킹 획득 / 종목 순위 변동)
  /// [badgeKey]에 'pro', 'diamond' 등을 넣으면 채팅방에 해당 이미지가 뜹니다.
  /// [isTotalRanking]이 true면 '획득' 문구로, false면 '변동' 문구로 나갑니다.
  static Future<void> sendRankingNotice({
    required String nickname,
    required String badgeKey,
    required String rank,
    required bool isTotalRanking,
    String? gameType, // 501, 크리켓, 카운트업 등
  }) {
    String message;
    if (isTotalRanking) {
      // 🏆 통합 랭킹: 배지 획득 강조
      message = '🎊 $nickname님이 통합 랭킹 ${rank}위에 등극하며 배지를 획득했습니다!';
    } else {
      // 🎯 일반 종목: 순위 변동 강조
      message = '📊 $nickname님의 ${gameType ?? "게임"} 순위가 ${rank}위로 변동되었습니다.';
    }

    return _send(
      msg: message,
      category: 'RANKING',
      targetId: badgeKey, // 버블에서 이미지를 그리기 위한 키값 저장
    );
  }

  /// 4. 관리자용: 마감 1일 전 대회들 찾아 공지 쏘기
  static Future<int> sendClosingSoonTournaments() async {
    int count = 0;
    try {
      final now = DateTime.now();
      final tomorrowStart = DateTime(now.year, now.month, now.day + 1);
      final tomorrowEnd = DateTime(now.year, now.month, now.day + 1, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('tournaments')
          .where('entryEndDate', isGreaterThanOrEqualTo: Timestamp.fromDate(tomorrowStart))
          .where('entryEndDate', isLessThanOrEqualTo: Timestamp.fromDate(tomorrowEnd))
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title'] ?? 'DAO 대회';
        final tournamentId = doc.id;

        await sendTournamentNotice(
            title,
            tournamentId,
            customMsg: '⚠️ [마감임박] "$title" 대회의 신청 마감이 1일 남았습니다! 서둘러주세요!'
        );
        count++;
      }
    } catch (e) {
      debugPrint('❌ 마감 임박 공지 발송 중 오류 발생: $e');
    }
    return count;
  }

  /// [공통] 실제 Firestore 전송 로직 (내부용)
  static Future<void> _send({
    required String msg,
    required String category,
    String? targetId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('chats').add({
        'uid': 'system',
        'userName': 'DAO 시스템',
        'userProfile': '',
        'message': msg,
        'type': 'SYSTEM',
        'category': category,
        'targetId': targetId ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ 시스템 공지 발송 완료: [$category] $msg');
    } catch (e) {
      debugPrint('❌ 시스템 공지 전송 실패: $e');
    }
  }
}