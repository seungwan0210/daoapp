import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/screens/home/home_screen.dart';
import 'package:daoapp/presentation/screens/training/training_home_screen.dart';
import 'package:daoapp/presentation/screens/arena/arena_home_screen.dart';
import 'package:daoapp/presentation/screens/community/community_home_screen.dart';
import 'package:daoapp/presentation/screens/my_page/my_page_screen.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/more_menu_button.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔥 추가

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
  late final List<Widget> _pageBodies;

  StreamSubscription<DocumentSnapshot>? _banSubscription;

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

    _startBanListener();
  }

  void _startBanListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _banSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) async {
      if (doc.exists && doc.data()?['isBanned'] == true) {
        await _banSubscription?.cancel();

        await FirebaseAuth.instance.signOut();

        try {
          await ref.read(authRepositoryProvider).signOut();
        } catch (e) {
          debugPrint("세션 종료 중 오류: $e");
        }

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context,
              RouteConstants.login,
                  (route) => false
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              // TODO: 이 메시지도 s.ban_msg 등으로 ARB화 하면 좋습니다.
              content: Text('운영 정책에 의해 이용이 제한되었습니다. 다른 계정으로 로그인하세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _banSubscription?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔥 110n 객체 가져오기

    // 🔥 탭 아이템 리스트를 build 내부로 이동하여 실시간 언어 반영
    final List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: s.tab_home),
      BottomNavigationBarItem(icon: const Icon(Icons.fitness_center_outlined), label: s.tab_training),
      BottomNavigationBarItem(icon: const Icon(Icons.emoji_events_outlined), label: s.tab_arena),
      BottomNavigationBarItem(icon: const Icon(Icons.forum_outlined), label: s.tab_community),
      BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: s.tab_mypage),
    ];

    // 현재 선택된 탭의 타이틀 가져오기
    final String currentTitle = items[_currentIndex].label ?? '';

    return Scaffold(
      appBar: CommonAppBar(
        title: currentTitle,
        actions: const [
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
        items: items, // 🔥 수정한 리스트 사용
      ),
    );
  }
}