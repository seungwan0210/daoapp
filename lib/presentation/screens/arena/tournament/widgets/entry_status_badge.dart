// lib/presentation/screens/community/arena/widgets/entry_status_badge.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/core/utils/arena_utils.dart';

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

    final label = ArenaUtils.statusText(status);
    final color = ArenaUtils.statusColor(status, context);

    // 👉 위쪽 배지에 들어갈 D-Day (엔트리 기준)
    String? entryDdayText;
    if (status == EntryStatus.upcoming) {
      // 엔트리 예정 = 엔트리 시작일 기준
      entryDdayText = ArenaUtils.entryDday(tournament.entryStartDate);
    } else if (status == EntryStatus.open) {
      // 엔트리 중 = 엔트리 마감일 기준
      entryDdayText = ArenaUtils.entryDday(tournament.entryEndDate);
    } else {
      entryDdayText = null; // closed / inProgress / finished 는 표시 X
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.08),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (entryDdayText != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withOpacity(0.6)),
              ),
              child: Text(
                entryDdayText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
