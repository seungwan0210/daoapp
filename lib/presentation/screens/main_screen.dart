// lib/presentation/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/screens/user/user_home_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/screens/user/my_page_screen.dart';
import 'package:daoapp/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    UserHomeScreen(),
    RankingScreen(),
    CalendarScreen(),
    MyPageScreen(),
  ];

  final List<BottomNavigationBarItem> _baseItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
    BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: '랭킹'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '일정'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
  ];

  List<BottomNavigationBarItem> _items = [];

  @override
  void initState() {
    super.initState();
    _items = List.from(_baseItems);
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return provider.ChangeNotifierProvider<RankingProvider>(
      create: (_) => sl<RankingProvider>(),
      child: Builder(builder: (context) {
        isAdminAsync.whenData((isAdmin) {
          if (isAdmin && _items.length == 4) {
            print('관리자 탭 추가!');
            setState(() {
              _items = List.from(_baseItems)
                ..add(const BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: '관리자',
                ));
            });
          }
        });

        final safeIndex = _currentIndex < (_items.length == 5 ? 5 : 4) ? _currentIndex : 0;

        return Scaffold(
          body: _items.length == 5 && safeIndex == 4
              ? const AdminDashboardScreen()
              : IndexedStack(
            index: safeIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            items: _items,
          ),
        );
      }),
    );
  }
}