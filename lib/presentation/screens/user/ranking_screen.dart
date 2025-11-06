// lib/presentation/screens/user/ranking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/data/models/ranking_user.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  static Widget body() => const RankingScreenBody();

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        ref.read(rankingProvider.notifier).updateFilters('2026', 'total', 'all');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return RankingScreen.body();
  }
}

class RankingScreenBody extends ConsumerWidget {
  const RankingScreenBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingState = ref.watch(rankingProvider);
    final theme = Theme.of(context);

    return SafeArea(
      top: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildYearDropdown(ref)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPhaseDropdown(ref)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildGenderDropdown(ref)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTop9Dropdown(ref)),
                ],
              ),
            ),
            Expanded(
              child: rankingState.when(
                data: (rankings) {
                  if (rankings.isEmpty) {
                    return Center(
                      child: Text(
                        '랭킹 데이터가 없습니다.\n포인트를 부여해 보세요!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: rankings.length,
                    itemBuilder: (_, i) {
                      final user = rankings[i];
                      return AppCard(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: _getRankColor(user.rank),
                            child: Text(
                              '${user.rank}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 한국 이름 + 성별
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.koreanName,
                                      style: theme.textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${user.gender == 'male' ? '남자' : '여자'})',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: user.gender == 'male' ? Colors.blue[700] : Colors.pink[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              // 영어 이름
                              Text(
                                '(${user.englishName})',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            user.shopName,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${user.displayPoints} pt',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              if (user.top9Points != null && user.top9Points != user.totalPoints)
                                Text(
                                  '전체: ${user.totalPoints}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('랭킹 로드 오류')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildYearDropdown(WidgetRef ref) {
    final notifier = ref.read(rankingProvider.notifier);
    return DropdownButton<String>(
      isExpanded: true,
      value: notifier.selectedYear,
      items: ['2026', '2027', '2028']
          .map((y) => DropdownMenuItem(value: y, child: Text(y)))
          .toList(),
      onChanged: (v) => notifier.updateFilters(
        v!,
        notifier.selectedPhase,
        notifier.selectedGender,
      ),
      underline: Container(height: 1, color: Colors.grey),
    );
  }

  static Widget _buildPhaseDropdown(WidgetRef ref) {
    final notifier = ref.read(rankingProvider.notifier);
    return DropdownButton<String>(
      isExpanded: true,
      value: notifier.selectedPhase,
      items: const [
        DropdownMenuItem(value: 'total', child: Text('통합')),
        DropdownMenuItem(value: 'season1', child: Text('시즌1')),
        DropdownMenuItem(value: 'season2', child: Text('시즌2')),
        DropdownMenuItem(value: 'season3', child: Text('시즌3')),
      ],
      onChanged: (v) => notifier.updateFilters(
        notifier.selectedYear,
        v!,
        notifier.selectedGender,
      ),
      underline: Container(height: 1, color: Colors.grey),
    );
  }

  static Widget _buildGenderDropdown(WidgetRef ref) {
    final notifier = ref.read(rankingProvider.notifier);
    return DropdownButton<String>(
      isExpanded: true,
      value: notifier.selectedGender,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('전체')),
        DropdownMenuItem(value: 'male', child: Text('남자')),
        DropdownMenuItem(value: 'female', child: Text('여자')),
      ],
      onChanged: (v) => notifier.updateFilters(
        notifier.selectedYear,
        notifier.selectedPhase,
        v!,
      ),
      underline: Container(height: 1, color: Colors.grey),
    );
  }

  static Widget _buildTop9Dropdown(WidgetRef ref) {
    final notifier = ref.read(rankingProvider.notifier);
    return DropdownButton<bool>(
      isExpanded: true,
      value: notifier.selectedPhase == 'total' ? false : notifier.top9Mode,
      items: [
        const DropdownMenuItem(value: false, child: Text('성적')),
        if (notifier.selectedPhase != 'total')
          const DropdownMenuItem(value: true, child: Text('상위 9개')),
      ],
      onChanged: notifier.selectedPhase == 'total'
          ? null
          : (v) => notifier.toggleTop9Mode(),
      underline: Container(height: 1, color: Colors.grey),
    );
  }

  static Color _getRankColor(int rank) {
    return switch (rank) {
      1 => Colors.amber,
      2 => Colors.grey,
      3 => Colors.brown[700]!,
      _ => const Color(0xFF1565C0),
    };
  }
}