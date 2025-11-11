// lib/presentation/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/screens/user/user_home_screen.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/screens/community/community_home_screen.dart';
import 'package:daoapp/presentation/screens/user/my_page_screen.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/more_menu_button.dart';

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
    return Scaffold(
      appBar: CommonAppBar(
        title: _items[_currentIndex].label ?? '',
        actions: [
          // === 설정 메뉴 + 공지 배지 (모든 사용자) ===
          _buildSettingsWithBadge(context),
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

  // === 설정 아이콘 + 공지 배지 (방법 2) ===
  Widget _buildSettingsWithBadge(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const MoreMenuButton(); // 로그인 안 하면 배지 없음
    }

    return StreamBuilder<int>(
      stream: _getUnreadNoticeCount(user.uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          children: [
            const MoreMenuButton(),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 읽지 않은 공지 수 스트림
  Stream<int> _getUnreadNoticeCount(String userId) {
    final noticesRef = FirebaseFirestore.instance.collection('notices');
    final readRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('readNotices');

    return noticesRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((noticeSnapshot) async {
      final noticeIds = noticeSnapshot.docs.map((doc) => doc.id).toList();
      if (noticeIds.isEmpty) return 0;

      final readSnapshot = await readRef
          .where(FieldPath.documentId, whereIn: noticeIds)
          .get();

      final readIds = readSnapshot.docs.map((doc) => doc.id).toSet();
      return noticeIds.where((id) => !readIds.contains(id)).length;
    });
  }
}