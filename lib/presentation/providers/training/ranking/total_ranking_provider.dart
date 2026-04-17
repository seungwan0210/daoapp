import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/data/models/ranking_game_model.dart';

/// [핵심 로직]
/// 1. 기존의 3개 종목별 랭킹 리스트를 감시(watch)합니다.
/// 2. 각 리스트의 1위~10위에게 10점~1점을 차등 부여합니다.
/// 3. 유저별로 점수를 합산한 뒤, 총점이 높은 순으로 정렬하여 반환합니다.
final totalRankingProvider = Provider<List<Map<String, dynamic>>>((ref) {
  // 기존 프로바이더들로부터 실시간 데이터를 가져옵니다 (서버 통신 없이 앱 내 계산)
  final ppdAsync = ref.watch(ppdRankingProvider);
  final mprAsync = ref.watch(mprRankingProvider);
  final countUpAsync = ref.watch(countUpRankingProvider);

  // 데이터가 아직 로딩 중이거나 에러가 있으면 빈 리스트 반환
  if (ppdAsync is! AsyncData || mprAsync is! AsyncData || countUpAsync is! AsyncData) {
    return [];
  }

  final ppdList = ppdAsync.value!;
  final mprList = mprAsync.value!;
  final countUpList = countUpAsync.value!;

  // 유저별 통합 점수를 합산할 맵 (Key: userId)
  final Map<String, Map<String, dynamic>> userScoreMap = {};

  // 점수 합산 함수 (TOP 10에게만 부여)
  void processRankingList(List<RankingRecord> list) {
    for (int i = 0; i < list.length && i < 10; i++) {
      final record = list[i];
      final points = 10 - i; // 1위 10점, 2위 9점 ... 10위 1점

      if (userScoreMap.containsKey(record.userId)) {
        userScoreMap[record.userId]!['totalPoints'] += points;
      } else {
        userScoreMap[record.userId] = {
          'userId': record.userId,
          'record': record,      // 랭킹 표시를 위한 유저 정보 객체
          'totalPoints': points,
        };
      }
    }
  }

  // 3개 종목 리스트 순회하며 점수 누적
  processRankingList(ppdList);
  processRankingList(mprList);
  processRankingList(countUpList);

  // 맵의 값들을 리스트로 변환 후 점수 순으로 내림차순 정렬
  final sortedTotalList = userScoreMap.values.toList()
    ..sort((a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));

  return sortedTotalList;
});