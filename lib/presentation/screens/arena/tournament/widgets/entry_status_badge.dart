// lib/presentation/screens/arena/tournament/widgets/entry_status_badge.dart

import 'package:flutter/material.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

/// 토너먼트 카드 상단에 붙는 엔트리 상태 + D-day 배지
class EntryStatusBadge extends StatelessWidget {
  final TournamentModel tournament;

  const EntryStatusBadge({
    super.key,
    required this.tournament,
  });

  IconData _statusIcon(EntryStatus status) {
    switch (status) {
      case EntryStatus.open:
        return Icons.how_to_reg_rounded;
      case EntryStatus.upcoming:
        return Icons.schedule_rounded;
      case EntryStatus.closed:
        return Icons.lock_rounded;
      case EntryStatus.inProgress:
        return Icons.play_circle_fill_rounded;
      case EntryStatus.finished:
        return Icons.check_circle_rounded;
      case EntryStatus.canceled:
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // 🔹 상태별 다국어 라벨 매핑 헬퍼
  String _getStatusLabel(BuildContext context, EntryStatus status) {
    final s = AppLocalizations.of(context)!;
    switch (status) {
      case EntryStatus.open:
        return s.arena_status_open;
      case EntryStatus.upcoming:
        return s.arena_status_upcoming;
      case EntryStatus.closed:
        return s.arena_status_closed;
      case EntryStatus.inProgress:
        return s.arena_status_in_progress;
      case EntryStatus.finished:
        return s.arena_status_finished;
      case EntryStatus.canceled:
        return s.arena_status_canceled;
      default:
        return ArenaUtils.statusText(status); // 예외 상황은 유틸 텍스트 유지
    }
  }

  @override
  Widget build(BuildContext context) {
    final entryStart = tournament.entryStartDate;
    final entryEnd = tournament.entryEndDate;
    final eventDate = tournament.eventDate;

    final status = ArenaUtils.getEntryStatus(
      entryStartDate: entryStart,
      entryEndDate: entryEnd,
      eventDate: eventDate,
    );

    final label = _getStatusLabel(context, status); // 🔹 다국어 적용
    final color = ArenaUtils.statusColor(status, context);

    String? entryDdayText;
    if (status == EntryStatus.upcoming) {
      entryDdayText = ArenaUtils.entryDday(entryStart);
    } else if (status == EntryStatus.open) {
      entryDdayText = ArenaUtils.entryDday(entryEnd);
    }

    final showChip = (entryDdayText ?? '').trim().isNotEmpty;
    final icon = _statusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),

          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                height: 1.0,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          if (showChip) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color.withOpacity(0.12),
              ),
              child: Text(
                entryDdayText!.trim(),
                style: TextStyle(
                  fontSize: 10,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
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