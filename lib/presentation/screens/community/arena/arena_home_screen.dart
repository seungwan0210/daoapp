// lib/presentation/screens/community/arena/arena_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/arena_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'widgets/tournament_card.dart';
import 'widgets/tournament_filter_chips.dart';

class ArenaHomeScreen extends ConsumerWidget {
  const ArenaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 필터 바뀔 때마다 자동 리로드
    ref.listen(arenaProvider.select((state) => state.selectedFilter), (_, __) {
      ref.read(arenaProvider.notifier).loadMore(reset: true);
    });

    // 첫 진입 시 강제 로드 (필터 기본값 기준)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(arenaProvider).tournaments.isEmpty) {
        ref.read(arenaProvider.notifier).loadMore(reset: true);
      }
    });

    final arenaState = ref.watch(arenaProvider);
    final tournaments = arenaState.tournaments;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CommonAppBar(
        title: '아레나',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 알림 화면 연결
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            tooltip: '대회 개설',
            onPressed: () {
              Navigator.pushNamed(context, RouteConstants.tournamentCreate);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(arenaProvider.notifier).loadMore(reset: true);
        },
        color: Theme.of(context).colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            // 필터 칩
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: TournamentFilterChips(),
              ),
            ),

            // 빈 상태
            if (tournaments.isEmpty && !arenaState.isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 90,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        arenaState.selectedFilter == 'my_hosted'
                            ? '아직 주최한 대회가 없어요\n직접 만들어보세요!'
                            : '등록된 대회가 없어요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        onPressed: () => ref.read(arenaProvider.notifier).loadMore(reset: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('새로고침'),
                      ),
                    ],
                  ),
                ),
              )
            else
            // 대회 리스트
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      // 무한 스크롤 로딩
                      if (index >= tournaments.length) {
                        if (arenaState.hasMore && !arenaState.isLoading) {
                          ref.read(arenaProvider.notifier).loadMore();
                        }
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final tournament = tournaments[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: TournamentCard(tournament: tournament),
                      );
                    },
                    childCount: tournaments.length + (arenaState.hasMore ? 1 : 0),
                  ),
                ),
              ),

            // 하단 여백 (키보드나 FAB 없어도 안전하게)
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }
}