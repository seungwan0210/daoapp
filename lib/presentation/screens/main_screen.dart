import 'dart:async'; // 🔥 StreamSubscription을 위해 추가
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 추가
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 추가

import 'package:daoapp/core/constants/route_constants.dart'; // 🔥 추가
import 'package:daoapp/presentation/screens/home/home_screen.dart';
import 'package:daoapp/presentation/screens/training/training_home_screen.dart';
import 'package:daoapp/presentation/screens/arena/arena_home_screen.dart';
import 'package:daoapp/presentation/screens/community/community_home_screen.dart';
import 'package:daoapp/presentation/screens/my_page/my_page_screen.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/more_menu_button.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';

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

  // 🔥 [추가] 실시간 정지 감시를 위한 구독 변수
  StreamSubscription<DocumentSnapshot>? _banSubscription;

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
    BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), label: '트레이닝'),
    BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: '아레나'),
    BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: '커뮤니티'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '내정보'),
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

    // 🔥 [추가] 앱 실행 중 관리자의 차단 여부를 실시간으로 감시
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

        // ✅ 1. Firebase 로그아웃
        await FirebaseAuth.instance.signOut();

        // ✅ 2. 구글/애플 세션까지 완전히 끊어서 '계정 선택창'이 뜨게 함
        // authRepository에 구현된 signOut이 구글 세션까지 끊는 역할을 한다면 아래처럼 호출
        try {
          await ref.read(authRepositoryProvider).signOut();
        } catch (e) {
          debugPrint("세션 종료 중 오류: $e");
        }

        if (mounted) {
          // ✅ 3. 스플래시가 아닌 '로그인' 화면으로 즉시 이동 (히스토리 삭제)
          Navigator.pushNamedAndRemoveUntil(
              context,
              RouteConstants.login,
                  (route) => false
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
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
    // 🔥 [추가] 메모리 누수 방지를 위해 리스너 해제
    _banSubscription?.cancel();
    super.dispose();
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