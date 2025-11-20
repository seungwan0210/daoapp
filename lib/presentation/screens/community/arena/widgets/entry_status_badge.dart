// lib/presentation/screens/community/arena/widgets/entry_status_badge.dart

import 'package:flutter/material.dart';
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/data/models/tournament_model.dart';

class EntryStatusBadge extends StatelessWidget {
  final TournamentModel tournament;

  const EntryStatusBadge({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final status = ArenaUtils.getEntryStatus(
      entryStartDate: tournament.entryStartDate,
      entryEndDate: tournament.entryEndDate,
      eventDate: tournament.eventDate,
    );

    final Color statusColor;
    final String statusText;

    switch (status) {
      case EntryStatus.open:
        statusColor = Colors.green[700]!;
        statusText = '엔트리 중';
        break;
      case EntryStatus.upcoming:
        statusColor = Colors.orange[700]!;
        statusText = '엔트리 예정';
        break;
      case EntryStatus.closed:
        statusColor = Colors.red[700]!;
        statusText = '엔트리 마감';
        break;
      default:
        statusColor = Colors.grey[600]!;
        statusText = '종료됨';
    }

    // 예정일 때만 D-Day 표시
    final bool showDday = status == EntryStatus.upcoming;
    final String? ddayText = showDday ? ArenaUtils.entryDday(tournament.entryStartDate) : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 상태 뱃지 (항상 보임)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor, width: 1.8),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // 예정일 때만 D-Day 표시!
        if (ddayText != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.orange[600]!, width: 1.5),
            ),
            child: Text(
              ddayText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ],
    );
  }
}