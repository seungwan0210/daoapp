// lib/presentation/screens/arena/tournament/widgets/entry_status_badge.dart

import 'package:flutter/material.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/core/utils/arena_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    // ✅ null/비정상 데이터 방어 (모델이 non-null이어도 legacy 데이터가 있을 수 있음)
    final entryStart = tournament.entryStartDate;
    final entryEnd = tournament.entryEndDate;
    final eventDate = tournament.eventDate;

    final status = ArenaUtils.getEntryStatus(
      entryStartDate: entryStart,
      entryEndDate: entryEnd,
      eventDate: eventDate,
    );

    final label = ArenaUtils.statusText(status);
    final color = ArenaUtils.statusColor(status, context);

    // 👉 배지 오른쪽에 붙일 "엔트리 기준" D-Day
    // - 예정(upcoming): 엔트리 시작일 기준 D-표기
    // - 엔트리 중(open): 엔트리 마감일 기준 D-표기
    String? entryDdayText;
    if (status == EntryStatus.upcoming) {
      entryDdayText = ArenaUtils.entryDday(entryStart);
    } else if (status == EntryStatus.open) {
      entryDdayText = ArenaUtils.entryDday(entryEnd);
    }

    final showChip = (entryDdayText ?? '').trim().isNotEmpty;

    final icon = _statusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.90), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),

          // 상태 텍스트 (엔트리 예정 / 엔트리 중 / 마감 / 진행중 / 종료 ...)
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              height: 1.0,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),

          // 오른쪽 작은 D-day 칩 (더 고급스럽게: 살짝 채움)
          if (showChip) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: color.withOpacity(0.16),
                border: Border.all(color: color.withOpacity(0.35), width: 1),
              ),
              child: Text(
                entryDdayText!.trim(),
                style: TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
