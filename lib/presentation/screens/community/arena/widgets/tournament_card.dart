// lib/presentation/screens/community/arena/widgets/tournament_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/screens/community/arena/widgets/entry_status_badge.dart';

class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ArenaUtils.getEntryStatus(
      entryStartDate: tournament.entryStartDate,
      entryEndDate: tournament.entryEndDate,
      eventDate: tournament.eventDate,
    );

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 포스터 이미지
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: tournament.posterUrl != null && tournament.posterUrl!.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: tournament.posterUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 60, color: Colors.white70),
              ),
            )
                : Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.emoji_events, size: 80, color: Colors.white),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상태 뱃지 + 참가 인원
                Row(
                  children: [
                    EntryStatusBadge(tournament: tournament),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${tournament.entryCount}/${tournament.maxParticipants}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 대회명
                Text(
                  tournament.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // 장소
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tournament.location,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 참가비 (0원일 때 "무료" 표시!)
                Row(
                  children: [
                    Icon(Icons.paid_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      tournament.entryFee > 0
                          ? '${tournament.entryFee.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원'
                          : '무료 입장',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: tournament.entryFee > 0 ? theme.colorScheme.primary : Colors.green[700],
                      ),
                    ),
                  ],
                ),

                // 진행중/예정일 때만 D-Day 표시
                if (status == EntryStatus.open || status == EntryStatus.upcoming)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      ArenaUtils.entryDday(tournament.entryEndDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: status == EntryStatus.open ? Colors.red[600] : Colors.orange[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}