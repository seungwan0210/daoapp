import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/screens/arena/tournament/widgets/entry_status_badge.dart';

class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  Widget _pill({
    required IconData icon,
    required String text,
    required Color color,
    Color? fill,
  }) {
    final bg = fill ?? color.withOpacity(0.10);
    final bd = color.withOpacity(0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
        border: Border.all(color: bd, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.0,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Color _ddayColor(String dday, BuildContext context) {
    final theme = Theme.of(context);
    if (dday == '오늘!') return Colors.redAccent;
    if (dday.startsWith('D-')) return Colors.orange.shade700;
    return theme.textTheme.bodySmall?.color?.withOpacity(0.55) ?? Colors.grey;
  }

  Color _capacityColor({
    required int count,
    required int maxP,
    required Color primary,
  }) {
    if (maxP <= 0) return primary;
    if (count >= maxP) return Colors.redAccent;

    final ratio = count / maxP;
    if (ratio >= 0.8) return Colors.orange.shade700;

    return primary;
  }

  String _formatMoney(int value) {
    final raw = value.toString();
    return raw.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 대회일 기준 D-DAY
    final eventDday = ArenaUtils.eventDday(tournament.eventDate);
    final ddayColor = _ddayColor(eventDday, context);

    final int maxP = tournament.maxParticipants;
    final int count = tournament.entryCount; // ✅ 단일 소스 (문서 필드)

    final Color capacityColor = _capacityColor(
      count: count,
      maxP: maxP,
      primary: theme.colorScheme.primary,
    );

    final bool unlimited = (maxP <= 0 || maxP >= 9999);
    final String capacityText = unlimited ? '$count명' : '$count/$maxP';

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
            child: (tournament.posterUrl ?? '').trim().isNotEmpty
                ? CachedNetworkImage(
              imageUrl: tournament.posterUrl!.trim(),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 160,
                color: Colors.grey[200],
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 160,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image_not_supported,
                  size: 56,
                  color: Colors.white70,
                ),
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
                child: Icon(
                  Icons.emoji_events,
                  size: 76,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // 본문
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상태 뱃지 + 참가 인원 pill
                Row(
                  children: [
                    EntryStatusBadge(tournament: tournament),
                    const Spacer(),
                    _pill(
                      icon: Icons.people_rounded,
                      text: unlimited ? '참가 $count' : capacityText,
                      color: capacityColor,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 대회명
                Text(
                  tournament.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // 장소
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tournament.location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 참가비 + D-day pill
                Row(
                  children: [
                    Icon(
                      Icons.paid_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tournament.entryFee > 0
                            ? '${_formatMoney(tournament.entryFee)}원'
                            : '무료 입장',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: tournament.entryFee > 0
                              ? theme.colorScheme.primary
                              : Colors.green[700],
                        ),
                      ),
                    ),
                    _pill(
                      icon: Icons.event_rounded,
                      text: eventDday,
                      color: ddayColor,
                      fill: ddayColor.withOpacity(0.10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
