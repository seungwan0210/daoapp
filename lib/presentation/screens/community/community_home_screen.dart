// lib/presentation/screens/community/community_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/screens/community/widgets/community_avatar_slider.dart';
import 'package:daoapp/presentation/screens/community/widgets/community_preview.dart';
import 'package:daoapp/presentation/screens/community/checkout/checkout_home_screen.dart';

// 아레나 프리뷰 임포트
import 'package:daoapp/presentation/screens/community/widgets/arena_preview.dart';

class CommunityHomeScreen extends ConsumerStatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  ConsumerState<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends ConsumerState<CommunityHomeScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToCircleFull() {
    Navigator.pushNamed(context, RouteConstants.circle);
  }

  void _goToCheckoutHome() {
    Navigator.pushNamed(context, RouteConstants.checkoutHome);
  }

  void _goToArenaFull() {
    Navigator.pushNamed(context, RouteConstants.arenaHome);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) return _buildLoginPrompt(context);

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final hasProfile = data['hasProfile'] as bool? ?? false;
                final isPhoneVerified = data['isPhoneVerified'] as bool? ?? false;

                if (!hasProfile || !isPhoneVerified) {
                  return _buildVerificationPrompt(context, hasProfile, isPhoneVerified);
                }

                return Column(
                  children: [
                    const SizedBox(height: 16),
                    const CommunityAvatarSlider(),

                    // 탭바
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: Colors.grey[600],
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 3),
                          insets: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        tabs: const [
                          Tab(icon: Icon(Icons.groups, size: 22), text: "서클"),
                          Tab(icon: Icon(Icons.sports_score, size: 22), text: "체크아웃"),
                          Tab(icon: Icon(Icons.sports_esports, size: 22), text: "아레나"),
                        ],
                      ),
                    ),

                    // 본문
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // 1. 서클
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: CommunityPreview(onSeeAllPressed: _goToCircleFull),
                          ),

                          // 2. 체크아웃
                          GestureDetector(
                            onTap: _goToCheckoutHome,
                            child: Container(
                              color: Colors.transparent,
                              child: _buildCheckoutPreview(theme),
                            ),
                          ),

                          // 3. 아레나 - 사진만 쭉!
                          ArenaPreview(onSeeAllPressed: _goToArenaFull),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildLoginPrompt(context),
        ),
      ),

      // 아레나 탭일 때만 FAB
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          if (_tabController.index != 2) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, RouteConstants.tournamentCreate),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildCheckoutPreview(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(Icons.sports_score, size: 56, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text("체크아웃", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Text("계산기, 연습 모드\n통계까지 한 번에!", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Icon(Icons.touch_app, size: 32, color: theme.colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_circle, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text('커뮤니티는 로그인 후 이용 가능해요!', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Google 계정으로 간편하게 시작하세요', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, RouteConstants.login),
                child: const Text('Google로 로그인'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationPrompt(BuildContext context, bool hasProfile, bool isPhoneVerified) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, size: 64, color: Colors.orange[400]),
            const SizedBox(height: 24),
            Text('커뮤니티 이용을 위해\n인증이 필요해요!', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (!hasProfile) const Text('• 프로필 등록'),
            if (!isPhoneVerified) const Text('• 핸드폰 인증'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, RouteConstants.profileRegister),
                child: const Text('인증하러 가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}