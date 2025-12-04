// lib/presentation/screens/arena/arena_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── 공용 카드 위젯 ─────────────────────────────────────────────
import 'package:daoapp/presentation/widgets/app_card.dart';

// ── 스틸리그 화면들 ─────────────────────────────────────────────
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_ranking_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_schedule_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_point_calendar_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/member_list_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/selection_players_screen.dart';

// ── 토너먼트 관련 ─────────────────────────────────────────────
import 'package:daoapp/presentation/screens/arena/tournament/tournament_create_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/my_tournaments_screen.dart';

// 아레나 프리뷰 위젯
import 'package:daoapp/presentation/screens/arena/widgets/arena_preview.dart';

/// 탭에서 사용되는 진입용 위젯
class ArenaHomeScreen extends ConsumerWidget {
  const ArenaHomeScreen({super.key});

  static Widget body() => const ArenaHomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ArenaHomeScreen.body();
  }
}

/// 실제 내용 렌더링
class ArenaHomeBody extends ConsumerWidget {
  const ArenaHomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      top: true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 상단 Row(아레나 + 대회 만들기/내가 주최한 대회)는 제거
          //    → 최상단 AppBar(CommonAppBar)에서 타이틀/설정 아이콘 처리

          const SizedBox(height: 8),

          // ==========================
          // 스틸리그 카드 섹션
          // ==========================
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

          // ==========================
          // 토너먼트 카드 섹션
          // ==========================
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
                      // TODO: tournaments_home_screen.dart와 연동해서
                      // "참가 가능" 탭으로 이동하도록 확장 가능
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('참가 가능 대회 화면은 준비 중입니다.'),
                        ),
                      );
                    },
                  ),
                  _ArenaGridItem(
                    icon: Icons.schedule_outlined,
                    label: '예정 경기',
                    color: Colors.blueGrey,
                    onTap: () {
                      // TODO: tournaments_home_screen.dart의 "예정" 탭과 연동 예정
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('예정 경기 화면은 준비 중입니다.'),
                        ),
                      );
                    },
                  ),
                  _ArenaGridItem(
                    icon: Icons.emoji_events_outlined,
                    label: '내 주최 경기',
                    color: Colors.amber.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyTournamentsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ==========================
          // 토너먼트 프리뷰 (참가 가능 / 예정)
          // ==========================
          ArenaPreview(
            onSeeAllPressed: () {
              // TODO: 추후 "참가 가능 대회 전체 리스트" 화면으로 교체
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('대회 전체 보기 화면은 준비 중입니다.'),
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
