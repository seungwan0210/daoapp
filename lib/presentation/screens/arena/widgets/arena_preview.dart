// lib/presentation/screens/arena/widgets/arena_preview.dart
// 100% 컴파일 에러 없는 최종본 (수정 버전)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/presentation/providers/arena_provider.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_detail_screen.dart';

class ArenaPreview extends ConsumerWidget {
  final VoidCallback onSeeAllPressed;

  const ArenaPreview({super.key, required this.onSeeAllPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arenaState = ref.watch(arenaProvider);

    final openTournaments = arenaState.tournaments
        .where(
          (t) => ArenaUtils.getEntryStatus(
        entryStartDate: t.entryStartDate,
        entryEndDate: t.entryEndDate,
        eventDate: t.eventDate,
      ) ==
          EntryStatus.open,
    )
        .take(8)
        .toList();

    final upcomingTournaments = arenaState.tournaments
        .where(
          (t) => ArenaUtils.getEntryStatus(
        entryStartDate: t.entryStartDate,
        entryEndDate: t.entryEndDate,
        eventDate: t.eventDate,
      ) ==
          EntryStatus.upcoming,
    )
        .take(8)
        .toList();

    final isLoading = arenaState.isLoading && arenaState.tournaments.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: [
          _buildSection(
            context: context,
            title: "지금 참가 가능한 대회",
            tournaments: openTournaments,
            showSeeAll: true,
            showDday: true,
            isLoading: isLoading,
          ),
          const SizedBox(height: 12),
          _buildSection(
            context: context,
            title: "예정된 대회",
            tournaments: upcomingTournaments,
            showSeeAll: false,
            showDday: true,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<TournamentModel> tournaments,
    required bool showSeeAll,
    required bool showDday,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final hasData = tournaments.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showSeeAll)
                TextButton(
                  onPressed: onSeeAllPressed,
                  child: const Text('전체 보기'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: hasData
              ? ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: tournaments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final t = tournaments[i];
              return GestureDetector(
                onTap: () {
                  if (t.id == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TournamentDetailScreen(tournamentId: t.id!),
                    ),
                  );
                },
                child: _buildCard(t, showDday: showDday),
              );
            },
          )
              : Center(
            child: Text(
              '아직 $title가 없어요',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(TournamentModel t, {required bool showDday}) {
    String dday = '';

    if (showDday) {
      final status = ArenaUtils.getEntryStatus(
        entryStartDate: t.entryStartDate,
        entryEndDate: t.entryEndDate,
        eventDate: t.eventDate,
      );

      if (status == EntryStatus.upcoming) {
        dday = ArenaUtils.entryStartDday(t.entryStartDate);
      } else if (status == EntryStatus.open) {
        dday = ArenaUtils.entryDday(t.entryEndDate);
      } else {
        dday = '마감됨';
      }
    }

    return Container(
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[300],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (t.posterUrl != null && t.posterUrl!.isNotEmpty)
            Image.network(
              t.posterUrl!,
              width: 100,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          else
            _placeholder(),
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dday.isNotEmpty) ...[
                      Text(
                        dday,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    const Icon(Icons.people, size: 11, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      '${t.entryCount}/${t.maxParticipants}',
                      style:
                      const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 120,
      color: Colors.grey[300],
      child: const Icon(
        Icons.emoji_events,
        size: 36,
        color: Colors.white70,
      ),
    );
  }
}
