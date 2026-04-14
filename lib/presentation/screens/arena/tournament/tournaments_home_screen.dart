// lib/presentation/screens/arena/tournament/tournaments_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/providers/arena_provider.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_detail_screen.dart';

import 'package:daoapp/presentation/screens/arena/tournament/widgets/tournament_card.dart';
import 'package:daoapp/presentation/screens/arena/tournament/widgets/tournament_filter_chips.dart';

class TournamentsHomeScreen extends ConsumerWidget {
  const TournamentsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arenaState = ref.watch(arenaProvider);

    final currentFilter = arenaState.currentFilter;

    // ✅ provider가 이미 필터 적용해서 내려주는 리스트
    final filtered = arenaState.tournaments.toList(growable: false);

    final isInitialLoading = arenaState.isLoading && filtered.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '대회 찾기',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const TournamentFilterChips(),
          const Divider(height: 1),

          Expanded(
            child: isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: () async {
                // ✅ arenaProvider에 refresh 메서드가 있다면 연결
                // 없다면 아래 줄을 주석 처리해도 됨.
                // await ref.read(arenaProvider.notifier).refresh();
              },
              child: filtered.isEmpty
                  ? _EmptyState(filter: currentFilter)
                  : NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  // ✅ 무한스크롤용 훅 (arenaProvider에 loadMore가 있으면 연결)
                  // - 스크롤이 바닥 근처(200px 이내)로 오면 다음 페이지 로드
                  //
                  // if (n.metrics.pixels >=
                  //     n.metrics.maxScrollExtent - 200) {
                  //   ref.read(arenaProvider.notifier).loadMore();
                  // }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final t = filtered[index];

                    return TournamentCard(
                      key: ValueKey(t.id ?? '${t.title}_$index'),
                      tournament: t,
                      onTap: () {
                        final id = t.id;
                        if (id == null || id.isEmpty) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TournamentDetailScreen(
                              tournamentId: id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // ✅ (선택) 아래쪽 로딩 인디케이터 슬롯
          // arenaState.isLoading 이 "추가 로드 중"에도 true라면,
          // 초기 로딩과 구분하려면 arenaState에 isPaging 같은 플래그를 추가하는 게 베스트.
          if (!isInitialLoading && arenaState.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 10, top: 6),
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final msg = _emptyMessage(filter);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.emoji_events_outlined,
          size: 64,
          color: Colors.grey[350],
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            msg,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.5,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  String _emptyMessage(String filter) {
    switch (filter) {
      case 'open':
        return '현재 참가 가능한 대회가 없습니다.\n새로운 대회가 열리면 여기에서 확인할 수 있어요.';
      case 'upcoming':
        return '아직 예정된 대회가 없습니다.\n조만간 새로운 일정이 추가될 수 있어요.';
      case 'closed':
        return '마감된 대회가 없습니다.';
      default:
        return '등록된 대회가 없습니다.\n첫 번째 대회의 주최자가 되어보세요!';
    }
  }
}
