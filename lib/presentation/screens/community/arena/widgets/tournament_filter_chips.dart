// lib/presentation/screens/community/arena/widgets/tournament_filter_chips.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/arena_provider.dart';

class TournamentFilterChips extends ConsumerWidget {
  const TournamentFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(arenaProvider.select((p) => p.selectedFilter));

    final filters = [
      ('all', '전체'),
      ('open', '엔트리 오픈'),
      ('upcoming', '엔트리 예정'),
      ('closed', '마감'),
      ('my_hosted', '내가 주최'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final key = f.$1;
            final label = f.$2;
            final selected = selectedFilter == key;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => ref.read(arenaProvider.notifier).changeFilter(key),
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Colors.grey[100],
                side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 1.5),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}