// lib/presentation/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/screens/home/home_screen.dart';
import 'package:daoapp/presentation/screens/training/training_home_screen.dart';
import 'package:daoapp/presentation/screens/arena/arena_home_screen.dart';
import 'package:daoapp/presentation/screens/community/community_home_screen.dart';
import 'package:daoapp/presentation/screens/my_page/my_page_screen.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/more_menu_button.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();

  /// 외부에서 탭 변경하고 싶을 때 사용
  static void changeTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainScreenState>();
    state?._onTabTapped(index);
  }
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pageBodies;

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      label: '홈',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center_outlined),
      label: '트레이닝',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.emoji_events_outlined),
      label: '아레나',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.forum_outlined),
      label: '커뮤니티',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: '내정보',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageBodies = const [
      HomeScreen(),
      TrainingHomeScreen(),
      ArenaHomeScreen(),
      CommunityHomeScreen(),
      MyPageScreenBody(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String get _currentTitle => _items[_currentIndex].label ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: _currentTitle,
        actions: const [
          // 알림/설정 등 공통 더보기 메뉴
          MoreMenuButton(),
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
