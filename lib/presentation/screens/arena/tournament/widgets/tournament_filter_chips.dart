// lib/presentation/screens/community/arena/widgets/tournament_filter_chips.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/arena_provider.dart';

class TournamentFilterChips extends ConsumerWidget {
  const TournamentFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(arenaProvider.select((s) => s.currentFilter));

    final filters = [
      ('전체', 'all'),
      ('진행중', 'open'),
      ('예정', 'upcoming'),
      ('마감', 'closed'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final index = entry.key;
          final (label, value) = entry.value;
          final isSelected = currentFilter == value;

          return Padding(
            padding: EdgeInsets.only(
              right: index < filters.length - 1 ? 12 : 0,
              left: index == 0 ? 4 : 0,
            ),
            child: FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                ref.read(arenaProvider.notifier).changeFilter(value);
              },
              backgroundColor: Colors.transparent,
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              showCheckmark: false,
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: isSelected ? 2.2 : 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              elevation: isSelected ? 4 : 0,
              pressElevation: 8,
              shadowColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : Colors.transparent,
            ),
          );
        }).toList(),
      ),
    );
  }
}