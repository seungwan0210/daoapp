// lib/presentation/providers/training/ranking/ranking_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/repositories/ranking_repository.dart';
import 'package:daoapp/data/models/ranking_game_model.dart';

// 1. 레포지토리 주입
final rankingRepositoryProvider = Provider((ref) => RankingRepository());

// 2. 501 PPD 랭킹 (Top 30까지 확장하여 동점자 정렬 로직 포함)
final ppdRankingProvider = StreamProvider<List<RankingRecord>>((ref) {
  return ref.watch(rankingRepositoryProvider).getTopRankings('bestPpd', limit: 30);
});

// 3. 크리켓 MPR 랭킹 (Top 30까지 확장하여 동점자 정렬 로직 포함)
final mprRankingProvider = StreamProvider<List<RankingRecord>>((ref) {
  return ref.watch(rankingRepositoryProvider).getTopRankings('bestMpr', limit: 30);
});

// 4. 카운트업 점수 랭킹 (Top 30까지 확장하여 동점자 정렬 로직 포함)
final countUpRankingProvider = StreamProvider<List<RankingRecord>>((ref) {
  return ref.watch(rankingRepositoryProvider).getTopRankings('bestCountUp', limit: 30);
});

// 💡 메모:
// RankingTabView에서 이미 'list.indexWhere((r) => r.userId == myUid)' 로직을 사용하여
// 내 순위를 찾고 있으므로 별도의 myRankInfoProvider는 삭제해도 무방합니다.