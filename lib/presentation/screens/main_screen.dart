// lib/presentation/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/screens/user/user_home_screen.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/screens/community/community_home_screen.dart';
import 'package:daoapp/presentation/screens/user/my_page_screen.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();

  static void changeTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainScreenState>();
    state?._onTabTapped(index);
  }
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  static final List<Widget> _pageBodies = [
    const UserHomeScreenBody(),
    const RankingScreenBody(),
    const CalendarScreenBody(),
    const CommunityHomeScreen(),
    const MyPageScreenBody(),
  ];

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
    BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), label: '랭킹'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: '일정'),
    BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '커뮤니티'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '내정보'),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // isAdminProvider → bool 타입
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: CommonAppBar(
        title: _items[_currentIndex].label ?? '',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: '공지사항',
            onPressed: () => Navigator.pushNamed(context, RouteConstants.noticeList),
          ),
          // 관리자 버튼 (bool → 바로 사용)
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: '관리자 모드',
              onPressed: () => Navigator.pushNamed(context, RouteConstants.adminDashboard),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pageBodies,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: _items,
      ),
    );
  }
}