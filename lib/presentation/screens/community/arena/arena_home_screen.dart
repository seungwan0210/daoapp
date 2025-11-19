// lib/presentation/screens/community/arena/arena_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/arena_provider.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'widgets/tournament_card.dart';
import 'widgets/tournament_filter_chips.dart';

class ArenaHomeScreen extends ConsumerStatefulWidget {
  const ArenaHomeScreen({super.key});

  @override
  ConsumerState<ArenaHomeScreen> createState() => _ArenaHomeScreenState();
}

class _ArenaHomeScreenState extends ConsumerState<ArenaHomeScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // 무한 스크롤 리스너 등록
    _scrollController.addListener(_scrollListener);

    // 화면 처음 들어올 때 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(arenaProvider.notifier).loadMore(reset: true);
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(arenaProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arena = ref.watch(arenaProvider);
    final tournaments = arena.tournaments;
    final isLoading = arena.isLoading;
    final hasMore = arena.hasMore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('아레나'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, RouteConstants.tournamentCreate),
          ),
        ],
      ),
      body: Column(
        children: [
          const TournamentFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(arenaProvider.notifier).loadMore(reset: true);
              },
              child: tournaments.isEmpty && !isLoading
                  ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            '아직 개설된 대회가 없어요\n지금 바로 첫 번째 대회를 만들어보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: tournaments.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= tournaments.length) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TournamentCard(tournament: tournaments[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, RouteConstants.tournamentCreate),
        child: const Icon(Icons.add),
      ),
    );
  }
}