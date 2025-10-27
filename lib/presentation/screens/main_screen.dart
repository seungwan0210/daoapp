// lib/presentation/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/screens/user/user_home_screen.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/screens/user/my_page_screen.dart';
import 'package:daoapp/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _basePages = [
    const UserHomeScreen(),
    const RankingScreen(),
    const CalendarScreen(),
    const MyPageScreen(),
  ];
  final List<BottomNavigationBarItem> _baseItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
    const BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: '랭킹'),
    const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '일정'),
    const BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
  ];

  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _items = [];
  bool _isAdminLoaded = false;

  @override
  void initState() {
    super.initState();
    _pages = List.from(_basePages);
    _items = List.from(_baseItems);
  }

  @override
  Widget build(BuildContext context) {
    // 실시간으로 isAdminProvider 감시
    ref.listen(isAdminProvider, (previous, next) {
      next.whenData((isAdmin) {
        print('isAdminProvider 변경 감지: $isAdmin'); // 디버그
        if (isAdmin && !_isAdminLoaded) {
          setState(() {
            _pages = List.from(_basePages)..add(const AdminDashboardScreen());
            _items = List.from(_baseItems)..add(const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: '관리자',
            ));
            _isAdminLoaded = true;
          });
        }
      });
    });

    final safeIndex = _currentIndex < _pages.length ? _currentIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (index) {
          if (index < _items.length) {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        items: _items,
      ),
    );
  }
}