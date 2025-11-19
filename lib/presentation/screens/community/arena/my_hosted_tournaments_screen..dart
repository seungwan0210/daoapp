// lib/presentation/screens/arena/my_hosted_tournaments_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/arena_provider.dart';
import 'package:daoapp/presentation/screens/community/arena/widgets/tournament_card.dart';

class MyHostedTournamentsScreen extends ConsumerWidget {
  const MyHostedTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 화면 들어올 때마다 자동으로 'my_hosted' 필터 적용
    ref.listen(arenaProvider, (previous, next) {
      if (next.selectedFilter != 'my_hosted') {
        ref.read(arenaProvider.notifier).changeFilter('my_hosted');
      }
    });

    final arenaState = ref.watch(arenaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내가 주최한 대회'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(arenaProvider.notifier).loadMore(reset: true),
        color: Theme.of(context).colorScheme.primary,
        child: arenaState.isLoading && arenaState.tournaments.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : arenaState.tournaments.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // FAB 공간 확보
          itemCount: arenaState.tournaments.length,
          itemBuilder: (context, index) {
            final tournament = arenaState.tournaments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TournamentCard(tournament: tournament),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // RefreshIndicator 동작 보장
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 100,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  '아직 주최한 대회가 없어요',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '지금 바로 첫 대회를 만들어보세요!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // 또는 직접 이동
                    // Navigator.pushNamed(context, RouteConstants.tournamentCreate);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('대회 개설하기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}