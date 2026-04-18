// lib/presentation/screens/arena/tournament/widgets/tournament_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
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

  Widget _buildCompactPill({
    required IconData icon,
    required String text,
    required Color color,
    Color? fill,
  }) {
    final bg = fill ?? color.withOpacity(0.06);
    final bd = color.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bg,
        border: Border.all(color: bd, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color), // 공간 확보를 위해 아이콘 미세 축소
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5, // 공간 확보를 위해 폰트 미세 축소
              height: 1.0,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(int value) {
    return NumberFormat('#,###').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final eventDday = ArenaUtils.eventDday(tournament.eventDate);
    Color ddayColor = Colors.grey[600]!;
    if (eventDday == '오늘!') ddayColor = Colors.redAccent;
    else if (eventDday.startsWith('D-')) ddayColor = Colors.orange.shade700;

    final int maxP = tournament.maxParticipants;
    final int count = tournament.entryCount;
    final bool unlimited = (maxP <= 0 || maxP >= 9999);

    // 공간 확보를 위해 '참가' 글자 제외 가능성 고려
    final String capacityText = unlimited ? '$count명' : '$count/$maxP';

    Color capacityColor = Colors.cyan.shade600;
    if (maxP > 0 && count >= maxP) capacityColor = Colors.redAccent;
    else if (maxP > 0 && (count / maxP) >= 0.8) capacityColor = Colors.orange.shade700;

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ 포스터 이미지 영역
          Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: (tournament.posterUrl ?? '').trim().isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: tournament.posterUrl!.trim(),
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan)
                ),
                errorWidget: (_, __, ___) => _buildPlaceholderIcon(),
              )
                  : _buildPlaceholderIcon(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 배지 및 현황 행 (🔥 오버플로우 방지 핵심 수정 구역)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 왼쪽 배지 영역: 남은 공간에 따라 유연하게 줄어듦
                    Flexible(
                      flex: 5,
                      child: EntryStatusBadge(tournament: tournament),
                    ),
                    const SizedBox(width: 8),
                    // 오른쪽 칩 영역: 자기 크기를 유지하되 너무 밀리면 Flexible하게
                    Flexible(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildCompactPill(
                            icon: Icons.people_rounded,
                            text: capacityText, // '참가' 문구 제거로 공간 확보
                            color: capacityColor,
                          ),
                          const SizedBox(width: 4),
                          _buildCompactPill(
                            icon: Icons.event_rounded,
                            text: eventDday,
                            color: ddayColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. 대회명
                Text(
                  tournament.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.3,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // 3. 장소 및 참가비
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tournament.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      tournament.entryFee > 0
                          ? '${_formatMoney(tournament.entryFee)}원'
                          : '무료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: tournament.entryFee > 0 ? Colors.cyan.shade700 : Colors.green[700],
                      ),
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

  Widget _buildPlaceholderIcon() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF81D4FA), Color(0xFFCE93D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(child: Icon(Icons.emoji_events_outlined, size: 60, color: Colors.white)),
    );
  }
}