// lib/presentation/screens/arena/tournament/tournaments_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/core/utils/ad_manager.dart';

import 'package:daoapp/presentation/providers/arena_provider.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_detail_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/widgets/tournament_card.dart';
import 'package:daoapp/presentation/screens/arena/tournament/widgets/tournament_filter_chips.dart';

// ✅ AdMob 배너 광고 위젯 임포트
import 'package:daoapp/presentation/widgets/ad_banner.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class TournamentsHomeScreen extends ConsumerWidget {
  const TournamentsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스
    final arenaState = ref.watch(arenaProvider);
    final currentFilter = arenaState.currentFilter;
    final filtered = arenaState.tournaments.toList(growable: false);
    final isInitialLoading = arenaState.isLoading && filtered.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          s.tournament_home_title, // 🔹 다국어 적용
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AD',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[400],
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              const AdBanner(type: AdBannerType.arena),
            ],
          ),
          const SizedBox(height: 4),

          /// 필터 칩 영역
          const TournamentFilterChips(),
          Container(height: 1, color: Colors.grey[100]),

          Expanded(
            child: isInitialLoading
                ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.cyan),
            )
                : RefreshIndicator(
              color: Colors.cyan,
              onRefresh: () async {
                // refresh 로직
              },
              child: filtered.isEmpty
                  ? _EmptyState(filter: currentFilter)
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
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

          if (!isInitialLoading && arenaState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.cyan),
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
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(
          Icons.emoji_events_outlined,
          size: 70,
          color: Colors.grey[200],
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            _emptyMessage(filter, s), // 🔹 s 전달
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // 🔹 다국어 대응을 위해 s를 인자로 받음
  String _emptyMessage(String filter, AppLocalizations s) {
    switch (filter) {
      case 'open':
        return s.tournament_empty_open;
      case 'upcoming':
        return s.tournament_empty_upcoming;
      case 'closed':
        return s.tournament_empty_closed;
      default:
        return s.tournament_empty_default;
    }
  }
}