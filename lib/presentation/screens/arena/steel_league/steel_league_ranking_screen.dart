// lib/presentation/screens/arena/steel_league/steel_league_ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/data/models/ranking_user.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SteelLeagueRankingScreen extends ConsumerStatefulWidget {
  const SteelLeagueRankingScreen({super.key});

  @override
  ConsumerState<SteelLeagueRankingScreen> createState() =>
      _SteelLeagueRankingScreenState();
}

class _SteelLeagueRankingScreenState
    extends ConsumerState<SteelLeagueRankingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        ref
            .read(rankingProvider.notifier)
            .updateFilters('2026', 'total', 'all');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '스틸리그 랭킹',
        showBackButton: true, // 아레나 탭 안에서 들어오는 화면이니까 뒤로가기 O
      ),
      body: const SteelLeagueRankingScreenBody(),
    );
  }
}

class SteelLeagueRankingScreenBody extends ConsumerWidget {
  const SteelLeagueRankingScreenBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingState = ref.watch(rankingProvider);
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Column(
        children: [
          // 필터 섹션
          AppCard(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    '필터',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildYearDropdown(ref)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildPhaseDropdown(ref)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildGenderDropdown(ref)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTop9Dropdown(ref)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 랭킹 리스트
          Expanded(
            child: rankingState.when(
              data: (rankings) {
                if (rankings.isEmpty) {
                  return Center(
                    child: Text(
                      '랭킹 데이터가 없습니다.\n포인트를 부여해 보세요!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: rankings.length,
                  itemBuilder: (_, i) {
                    final RankingUser user = rankings[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: AppCard(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: _getRankColor(user.rank),
                            child: Text(
                              '${user.rank}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.koreanName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user.gender == 'male'
                                          ? Colors.blue[50]
                                          : Colors.pink[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      user.gender == 'male' ? '남자' : '여자',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: user.gender == 'male'
                                            ? Colors.blue[700]
                                            : Colors.pink[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // 배지 (이름 + 성별 옆)
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.userId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const SizedBox.shrink();
                                      }
                                      final userData = snapshot.data!.data()
                                      as Map<String, dynamic>? ??
                                          {};
                                      final badgesMap =
                                      BadgeUtils.extractBadges(userData);
                                      final monthly =
                                      BadgeUtils.getLatestMonthlyBadge(
                                          badgesMap);
                                      final admin =
                                      BadgeUtils.getLatestAdminBadge(
                                          badgesMap);
                                      final badges = <String>[];
                                      if (monthly != null) badges.add(monthly);
                                      if (admin != null) badges.add(admin);

                                      return Wrap(
                                        spacing: 2,
                                        children: badges
                                            .map(
                                              (key) => Tooltip(
                                            message: BadgeUtils
                                                .getBadgeTooltip(key),
                                            child: BadgeWidget(
                                              badgeKey: key,
                                              size: 18,
                                            ),
                                          ),
                                        )
                                            .toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.englishName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    user.shopName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${user.displayPoints} pt',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              if (user.top9Points != null &&
                                  user.top9Points != user.totalPoints)
                                Text(
                                  '전체: ${user.totalPoints}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
              const Center(child: Text('랭킹 로드 오류')),
            ),
          ),
        ],
      ),
    );
  }

  // === 필터 위젯들 ===

  static Widget _buildYearDropdown(WidgetRef ref) {
    final notifier = ref.read(rankingProvider.notifier);
    return DropdownButtonFormField<String>(
      value: notifier.selectedYear,
      decoration: InputDecoration(
        labelText: '연도',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ['2026', '2027', '2028']
          .map((y) => DropdownMenuItem(value: y, child: Text(y)))
          .toList(),
      onChanged: (v) =>
          notifier.updateFilters(v!, notifier.selectedPhase, notifier.selectedGender),
    );
  }

  static Widget _buildPhaseDropdown(WidgetRef ref) {
    final notifier = ref.read(rankingProvider.notifier);
    return DropdownButtonFormField<String>(
      value: notifier.selectedPhase,
      decoration: InputDecoration(
        labelText: '시즌',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(value: 'total', child: Text('통합')),
        DropdownMenuItem(value: 'season1', child: Text('시즌1')),
        DropdownMenuItem(value: 'season2', child: Text('시즌2')),
        DropdownMenuItem(value: 'season3', child: Text('시즌3')),
      ],
      onChanged: (v) =>
          notifier.updateFilters(notifier.selectedYear, v!, notifier.selectedGender),
    );
  }

  static Widget _buildGenderDropdown(WidgetRef ref) {
    final notifier = ref.read(rankingProvider.notifier);
    return DropdownButtonFormField<String>(
      value: notifier.selectedGender,
      decoration: InputDecoration(
        labelText: '성별',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('전체')),
        DropdownMenuItem(value: 'male', child: Text('남자')),
        DropdownMenuItem(value: 'female', child: Text('여자')),
      ],
      onChanged: (v) =>
          notifier.updateFilters(notifier.selectedYear, notifier.selectedPhase, v!),
    );
  }

  static Widget _buildTop9Dropdown(WidgetRef ref) {
    final notifier = ref.read(rankingProvider.notifier);
    return DropdownButtonFormField<bool>(
      value: notifier.selectedPhase == 'total' ? false : notifier.top9Mode,
      decoration: InputDecoration(
        labelText: '종합',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: false, child: Text('종합')),
        if (notifier.selectedPhase != 'total')
          const DropdownMenuItem(value: true, child: Text('상위 9개')),
      ],
      onChanged: notifier.selectedPhase == 'total'
          ? null
          : (v) => notifier.toggleTop9Mode(),
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
