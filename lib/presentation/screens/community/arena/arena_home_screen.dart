// lib/presentation/screens/community/arena/arena_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/arena_provider.dart';
import 'package:daoapp/presentation/screens/community/arena/widgets/tournament_card.dart';
import 'package:daoapp/presentation/screens/community/arena/widgets/tournament_filter_chips.dart';
import 'package:daoapp/presentation/screens/community/arena/tournament_create_screen.dart';
import 'package:daoapp/presentation/screens/community/arena/tournament_detail_screen.dart';
import 'package:daoapp/presentation/screens/community/arena/my_tournaments_screen.dart';

class ArenaHomeScreen extends ConsumerStatefulWidget {
  const ArenaHomeScreen({super.key});

  @override
  ConsumerState<ArenaHomeScreen> createState() => _ArenaHomeScreenState();
}

class _ArenaHomeScreenState extends ConsumerState<ArenaHomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arenaState = ref.watch(arenaProvider);
    final notifier = ref.read(arenaProvider.notifier);

    final filteredTournaments = arenaState.tournaments.where((t) {
      return t.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          '아레나',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TournamentCreateScreen()),
            ).then((_) => notifier.refresh()),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: '대회 만들기',
            iconSize: 28,
            color: theme.colorScheme.primary,
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyTournamentsScreen()),
            ).then((_) => notifier.refresh()),
            icon: const Icon(Icons.emoji_events),
            tooltip: '내가 주최한 대회',
            iconSize: 28,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: TournamentFilterChips()),

            // 검색바
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '대회명을 검색하세요',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _searchController.clear,
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),

            // 대회 리스트
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: _buildListSliver(
                context: context,
                arenaState: arenaState,
                filteredTournaments: filteredTournaments,
                notifier: notifier,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSliver({
    required BuildContext context,
    required ArenaState arenaState,
    required List filteredTournaments,
    required ArenaNotifier notifier,
  }) {
    if (arenaState.isLoading && arenaState.tournaments.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 400,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (filteredTournaments.isEmpty && !arenaState.isLoading) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              children: [
                Icon(
                  _searchQuery.isEmpty ? Icons.sports_esports_outlined : Icons.search_off,
                  size: 100,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  _searchQuery.isEmpty ? '등록된 대회가 없어요' : '검색 결과가 없어요',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isEmpty
                      ? '새로운 대회를 기다려주세요!'
                      : '"$_searchQuery"에 맞는 대회가 없어요',
                  style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          if (index >= filteredTournaments.length) {
            if (arenaState.hasMore) {
              notifier.loadTournaments();
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final tournament = filteredTournaments[index];
          return TournamentCard(
            tournament: tournament,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TournamentDetailScreen(tournamentId: tournament.id!),
                ),
              );
            },
          );
        },
        childCount: filteredTournaments.length + (arenaState.hasMore ? 1 : 0),
      ),
    );
  }
}