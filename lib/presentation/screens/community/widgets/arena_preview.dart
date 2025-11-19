// lib/presentation/screens/community/widgets/arena_preview.dart

import 'package:flutter/material.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/utils/arena_utils.dart';

class ArenaPreview extends StatelessWidget {
  final VoidCallback onSeeAllPressed;

  const ArenaPreview({super.key, required this.onSeeAllPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSection(
          context: context,
          title: '지금 참가 가능한 대회',
          filter: 'open',
          showSeeAll: true,
          sortByEntryEndDate: true,
        ),
        const SizedBox(height: 12),
        _buildSection(
          context: context,
          title: '예정된 대회',
          filter: 'upcoming',
          showSeeAll: false,
          sortByEntryEndDate: false,
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String filter,
    required bool showSeeAll,
    required bool sortByEntryEndDate,
  }) {
    return StreamBuilder<List<TournamentModel>>(
      stream: sl<ArenaRepository>().getTournaments(filter: filter, limit: 10),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 120);
        }

        var tournaments = snapshot.data!;

        // 정렬 로직 (이전 요청대로 완벽 적용)
        if (sortByEntryEndDate) {
          tournaments.sort((a, b) => (a.entryEndDate?.toDate() ?? DateTime(9999))
              .compareTo(b.entryEndDate?.toDate() ?? DateTime(9999)));
        } else {
          tournaments.sort((a, b) =>
              a.eventDate.toDate().compareTo(b.eventDate.toDate()));
        }

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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (showSeeAll)
                    TextButton(onPressed: onSeeAllPressed, child: const Text('전체 보기')),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: tournaments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final t = tournaments[index];
                  return _buildTournamentItem(context, t, filter == 'open');
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTournamentItem(BuildContext context, TournamentModel t, bool isOpenSection) {
    final String dday = isOpenSection && t.entryEndDate != null
        ? ArenaUtils.getEntryDday(t.entryEndDate!)
        : '';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, RouteConstants.arenaHome),
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 포스터
            t.imageUrl != null && t.imageUrl!.isNotEmpty
                ? Image.network(
              t.imageUrl!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.emoji_events, size: 40, color: Colors.grey),
              ),
            )
                : Container(
              color: Colors.grey[300],
              child: const Icon(Icons.emoji_events, size: 40, color: Colors.grey),
            ),

            // 하단 오버레이 (CommunityPreview와 완전히 동일한 느낌 + overflow 방지)
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: FittedBox(  // ← 이게 핵심! 텍스트 길어도 자동 축소
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOpenSection && dday.isNotEmpty) ...[
                        const Icon(Icons.access_time, color: Colors.orange, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          dday,
                          style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                      ],
                      const Icon(Icons.people, color: Colors.white, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        '${t.entryCount}명',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}