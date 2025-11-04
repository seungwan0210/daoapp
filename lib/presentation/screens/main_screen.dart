// lib/presentation/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/screens/user/user_home_screen.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/screens/community/community_screen.dart';
import 'package:daoapp/presentation/screens/user/my_page_screen.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  // body만 반환
  static final List<Widget> _pageBodies = [
    const UserHomeScreenBody(),
    const RankingScreenBody(),
    const CalendarScreen(), // 직접 사용
    const CommunityScreenBody(),
    const MyPageScreenBody(),
  ];

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),           // ← 여기!
    BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: '랭킹'), // ← 여기!
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '일정'), // ← 여기!
    BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: '커뮤니티'), // ← 여기!
    BottomNavigationBarItem(icon: Icon(Icons.person), label: '내정보'),   // ← 여기!
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_items[_currentIndex].label ?? ''),
        centerTitle: true,
        actions: ref.watch(isAdminProvider).when(
          data: (isAdmin) => isAdmin
              ? [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.pushNamed(context, RouteConstants.adminDashboard),
            ),
          ]
              : null,
          loading: () => null,
          error: (_, __) => null,
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pageBodies,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: _items,
      ),
    );
  }
}