import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/repositories/ranking_repository.dart';
import 'package:daoapp/data/models/ranking_game_model.dart';

// 1. 레포지토리 주입 (중앙 저장소 연결)
final rankingRepositoryProvider = Provider((ref) => RankingRepository());

// -----------------------------------------------------------------
// 🎯 [종목별 StreamProviders] - Firestore 실시간 감시
// -----------------------------------------------------------------

/// 501 PPD 랭킹 (Top 30)
final ppdRankingProvider = StreamProvider<List<RankingRecord>>((ref) {
  return ref.watch(rankingRepositoryProvider).getTopRankings('bestPpd', limit: 30);
});

/// 크리켓 MPR 랭킹 (Top 30)
final mprRankingProvider = StreamProvider<List<RankingRecord>>((ref) {
  return ref.watch(rankingRepositoryProvider).getTopRankings('bestMpr', limit: 30);
});

/// 카운트업 점수 랭킹 (Top 30)
final countUpRankingProvider = StreamProvider<List<RankingRecord>>((ref) {
  return ref.watch(rankingRepositoryProvider).getTopRankings('bestCountUp', limit: 30);
});

// -----------------------------------------------------------------
// 🏆 [통합 Ranking Provider] - 배지 및 전역 프로필 배지의 근거 데이터
// -----------------------------------------------------------------

/// [핵심 로직]
/// 1. 종목별 랭킹 데이터를 모아 포인트를 합산(10~1점)합니다.
/// 2. 앱 전반(프로필, 채팅 등)에서 이 유저가 현재 '어떤 배지'를 달고 있는지 판단하는 기준이 됩니다.
final totalRankingProvider = Provider<List<Map<String, dynamic>>>((ref) {
  // 각 종목 스트림 구독
  final ppdAsync = ref.watch(ppdRankingProvider);
  final mprAsync = ref.watch(mprRankingProvider);
  final countUpAsync = ref.watch(countUpRankingProvider);

  // 데이터 로딩 및 안정성 체크
  final ppdList = ppdAsync.asData?.value;
  final mprList = mprAsync.asData?.value;
  final cuList = countUpAsync.asData?.value;

  // 세 데이터가 모두 준비되지 않았다면 빈 리스트 반환 (에러 방지)
  if (ppdList == null || mprList == null || cuList == null) {
    return [];
  }

  // 유저별 통합 점수 맵 (Key: userId)
  final Map<String, Map<String, dynamic>> userScoreMap = {};

  /// 💡 포인트 부여: 1위 10점 ~ 10위 1점
  void processRankingList(List<RankingRecord> list) {
    for (int i = 0; i < list.length && i < 10; i++) {
      final record = list[i];
      final points = 10 - i;

      if (userScoreMap.containsKey(record.userId)) {
        userScoreMap[record.userId]!['totalPoints'] += points;
      } else {
        userScoreMap[record.userId] = {
          'userId': record.userId,
          'record': record,      // 유저 모델 데이터
          'totalPoints': points,
        };
      }
    }
  }

  // 3개 종목 순회하며 합산
  processRankingList(ppdList);
  processRankingList(mprList);
  processRankingList(cuList);

  // 총점 기준 내림차순 정렬 후 리스트 반환
  final sortedTotalList = userScoreMap.values.toList()
    ..sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));

  return sortedTotalList;
});