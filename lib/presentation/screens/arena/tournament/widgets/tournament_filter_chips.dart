// lib/presentation/screens/arena/tournament/widgets/tournament_filter_chips.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/arena_provider.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class TournamentFilterChips extends ConsumerWidget {
  const TournamentFilterChips({super.key});

  // 🔹 필터 정보에서 label을 제외한 메타데이터만 상수로 관리
  static const List<_FilterMetadata> _filterMeta = <_FilterMetadata>[
    _FilterMetadata(
      value: "all",
      icon: Icons.grid_view_rounded,
      color: Colors.blueGrey,
    ),
    _FilterMetadata(
      value: "open",
      icon: Icons.play_circle_fill_rounded,
      color: Colors.green,
    ),
    _FilterMetadata(
      value: "upcoming",
      icon: Icons.schedule_rounded,
      color: Colors.indigo,
    ),
    _FilterMetadata(
      value: "closed",
      icon: Icons.lock_rounded,
      color: Colors.grey,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스
    final currentFilter = ref.watch(arenaProvider.select((s) => s.currentFilter));
    final theme = Theme.of(context);

    // 🔹 value에 맞는 다국어 라벨 매핑 함수
    String getLabel(String value) {
      switch (value) {
        case "open": return s.tournament_filter_open;
        case "upcoming": return s.tournament_filter_upcoming;
        case "closed": return s.tournament_filter_closed;
        default: return s.tournament_filter_all;
      }
    }

    final safeCurrent = _filterMeta.any((f) => f.value == currentFilter)
        ? currentFilter
        : "all";

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _filterMeta.map((f) {
          final isSelected = f.value == safeCurrent;
          final String label = getLabel(f.value); // 🔹 다국어 라벨 할당

          final Color accent =
          (f.value == "all") ? theme.colorScheme.primary : f.color;

          final Color border =
          isSelected ? accent.withOpacity(0.90) : Colors.grey.shade300;

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
              label: Text(label), // 🔹 적용
              selected: isSelected,
              onSelected: (selected) async {
                if (!selected) return;
                await ref.read(arenaProvider.notifier).changeFilter(f.value);
              },
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

// 🔹 라벨을 제외한 메타데이터 클래스로 변경
class _FilterMetadata {
  final String value;
  final IconData icon;
  final Color color;

  const _FilterMetadata({
    required this.value,
    required this.icon,
    required this.color,
  });
}