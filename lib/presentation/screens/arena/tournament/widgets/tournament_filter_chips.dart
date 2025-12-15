// lib/presentation/screens/arena/tournament/widgets/tournament_filter_chips.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/arena_provider.dart';

class TournamentFilterChips extends ConsumerWidget {
  const TournamentFilterChips({super.key});

  static const List<_TournamentFilter> _filters = <_TournamentFilter>[
    _TournamentFilter(
      label: "전체",
      value: "all",
      icon: Icons.grid_view_rounded,
      color: Colors.blueGrey,
    ),
    _TournamentFilter(
      label: "진행중",
      value: "open",
      icon: Icons.play_circle_fill_rounded,
      color: Colors.green,
    ),
    _TournamentFilter(
      label: "예정",
      value: "upcoming",
      icon: Icons.schedule_rounded,
      color: Colors.indigo,
    ),
    _TournamentFilter(
      label: "마감",
      value: "closed",
      icon: Icons.lock_rounded,
      color: Colors.grey,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter =
    ref.watch(arenaProvider.select((s) => s.currentFilter));

    final theme = Theme.of(context);

    // ✅ 혹시 currentFilter가 예상 밖이면 UI가 꼬이지 않게
    final safeCurrent = _filters.any((f) => f.value == currentFilter)
        ? currentFilter
        : "all";

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _filters.map((f) {
          final isSelected = f.value == safeCurrent;

          // all은 앱 메인 컬러를 따라가게
          final Color accent =
          (f.value == "all") ? theme.colorScheme.primary : f.color;

          final Color border =
          isSelected ? accent.withOpacity(0.90) : Colors.grey.shade300;

          // ✅ 비선택은 투명 + 보더만 (더 깔끔하고 고급스러움)
          final Color fill = isSelected ? accent.withOpacity(0.14) : Colors.transparent;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              labelPadding: const EdgeInsets.only(left: 2, right: 10),
              avatar: Icon(
                f.icon,
                size: 18,
                color: isSelected ? accent : Colors.grey[700],
              ),
              label: Text(f.label),
              selected: isSelected,
              onSelected: (selected) async {
                // FilterChip은 토글이라 false도 들어옴 → 우리는 "선택"만 처리
                if (!selected) return;

                // ✅ 빠른 연타에서 상태 꼬임 방지 (changeFilter가 async)
                await ref.read(arenaProvider.notifier).changeFilter(f.value);
              },

              // ==== UI 스타일 =====
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              showCheckmark: false,

              backgroundColor: fill,
              selectedColor: fill,

              side: BorderSide(
                color: border,
                width: isSelected ? 1.8 : 1.2,
              ),

              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),

              // 그림자(선택일 때만 아주 약하게)
              elevation: isSelected ? 2 : 0,
              pressElevation: 4,
              shadowColor:
              isSelected ? accent.withOpacity(0.16) : Colors.transparent,

              labelStyle: TextStyle(
                fontSize: 14.5,
                color: isSelected
                    ? accent
                    : theme.textTheme.bodyLarge?.color?.withOpacity(0.85),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TournamentFilter {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TournamentFilter({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
