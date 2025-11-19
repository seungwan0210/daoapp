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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: filters.map((filter) {
            final key = filter.$1;
            final label = filter.$2;
            final isSelected = selectedFilter == key;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => ref.read(arenaProvider.notifier).changeFilter(key),
                selectedColor: Theme.of(context).primaryColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: isSelected ? null : Colors.grey[200],
                side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}