import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/presentation/widgets/app_card.dart';

// 스틸리그
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_ranking_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_schedule_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_point_calendar_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/member_list_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/selection_players_screen.dart';

// 토너먼트
import 'package:daoapp/presentation/screens/arena/tournament/tournament_create_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/my_tournaments_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournaments_home_screen.dart';

// 관리자 테스트 툴
import 'package:daoapp/presentation/screens/arena/tournament/tournament_debug_tools_screen.dart';

// 토너먼트 프리뷰
import 'package:daoapp/presentation/screens/arena/widgets/arena_preview.dart';

// 아레나 상태
import 'package:daoapp/presentation/providers/arena_provider.dart';

// ✅ AdMob 배너 광고 위젯 (실제 광고 단위 ID는 AdBanner 쪽에서 관리)
import 'package:daoapp/presentation/widgets/ad_banner.dart';

const String kAdminUid = 'NanHPgCdsbMCFkHEs7MtxS51OSX2';

class ArenaHomeScreen extends ConsumerWidget {
  const ArenaHomeScreen({super.key});

  static Widget body() => const ArenaHomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ArenaHomeBody();
  }
}

class ArenaHomeBody extends ConsumerWidget {
  const ArenaHomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.uid == kAdminUid;

    return SafeArea(
      top: true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          /// ==============================
          /// 🔥 상단 배너 광고
          /// ==============================
          AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  AdBanner(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          /// ==============================
          /// 스틸리그
          /// ==============================
          Text(
            '스틸리그',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: [
                  _ArenaGridItem(
                    icon: Icons.leaderboard_outlined,
                    label: '랭킹',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SteelLeagueRankingScreen(),
                        ),
                      );
                    },
                  ),
                  _ArenaGridItem(
                    icon: Icons.event_available_outlined,
                    label: '리그 일정',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SteelLeagueScheduleScreen(),
                        ),
                      );
                    },
                  ),
                  _ArenaGridItem(
                    icon: Icons.calendar_month_outlined,
                    label: '포인트 달력',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const SteelLeaguePointCalendarScreen(),
                        ),
                      );
                    },
                  ),
                  _ArenaGridItem(
                    icon: Icons.card_membership_outlined,
                    label: 'KDF 정회원',
                    color: Colors.pinkAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MemberListScreen(),
                        ),
                      );
                    },
                  ),
                  _ArenaGridItem(
                    icon: Icons.groups_3_outlined,
                    label: '선발 선수',
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SelectionPlayersScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          /// ==============================
          /// 토너먼트
          /// ==============================
          Text(
            '토너먼트',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: [
                  _ArenaGridItem(
                    icon: Icons.add_circle_outline,
                    label: '개최하기',
                    color: Colors.cyan,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TournamentCreateScreen(),
                        ),
                      );
                    },
                  ),
                  _ArenaGridItem(
                    icon: Icons.how_to_reg_outlined,
                    label: '참가 가능',
                    color: Colors.green,
                    onTap: () {
                      ref.read(arenaProvider.notifier).changeFilter('open');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TournamentsHomeScreen(),
                        ),
                      );
                    },
                  ),
                  _ArenaGridItem(
                    icon: Icons.schedule_outlined,
                    label: '예정 경기',
                    color: Colors.blueGrey,
                    onTap: () {
                      ref
                          .read(arenaProvider.notifier)
                          .changeFilter('upcoming');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TournamentsHomeScreen(),
                        ),
                      );
                    },
                  ),
                  _ArenaGridItem(
                    icon: Icons.emoji_events_outlined,
                    label: '내 주최 경기',
                    color: Colors.amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyTournamentsScreen(),
                        ),
                      );
                    },
                  ),

                  // 관리자만
                  if (isAdmin)
                    _ArenaGridItem(
                      icon: Icons.bug_report_outlined,
                      label: '메일 테스트',
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const TournamentDebugToolsScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          /// ==============================
          /// 토너먼트 프리뷰
          /// ==============================
          ArenaPreview(
            onSeeAllPressed: () {
              ref.read(arenaProvider.notifier).changeFilter('open');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TournamentsHomeScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ArenaGridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ArenaGridItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 26,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
