// lib/presentation/screens/community/community_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/circle_avatar_slider.dart';
import 'package:daoapp/presentation/screens/community/circle/circle_preview.dart';
import 'package:daoapp/presentation/screens/community/checkout/checkout_trainer_preview.dart';
import 'package:daoapp/presentation/screens/community/arena/arena_preview.dart';

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

  // 전체 보기 → CircleScreen 이동
  void _goToCircleFull() {
    Navigator.pushNamed(context, RouteConstants.circleFull); // 라우트 추가 필요
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
            if (user == null) {
              return _buildLoginPrompt(context);
            }

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
                    // 슬라이더 위에 간격 추가
                    const SizedBox(height: 12), // ← 여기만 추가!
                    const ProfileAvatarSlider(),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: Colors.grey[600],
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 3),
                          insets: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        padding: const EdgeInsets.only(top: 8), // 여백 줄임
                        tabAlignment: TabAlignment.fill,
                        tabs: const [
                          Tab(icon: Icon(Icons.groups, size: 22), text: "서클", iconMargin: EdgeInsets.only(bottom: 4)),
                          Tab(icon: Icon(Icons.sports_score, size: 22), text: "체크아웃", iconMargin: EdgeInsets.only(bottom: 4)),
                          Tab(icon: Icon(Icons.sports_esports, size: 22), text: "아레나", iconMargin: EdgeInsets.only(bottom: 4)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8), // 여백 줄임
                            child: CirclePreview(onSeeAllPressed: _goToCircleFull),
                          ),
                          const CheckoutTrainerPreview(),
                          const ArenaPreview(),
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
    );
  }

  // 로그인 유도
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
            Text(
              '커뮤니티는 로그인 후 이용 가능해요!',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Google 계정으로 간편하게 시작하세요',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, RouteConstants.login),
                style: theme.elevatedButtonTheme.style,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: Image.asset('assets/images/google_logo.png', width: 20, height: 20, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    const Text('Google로 로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 인증 유도
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
            Text(
              '커뮤니티 이용을 위해\n인증이 필요해요!',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!hasProfile)
              Text('• 프로필 등록', style: theme.textTheme.bodyMedium),
            if (!isPhoneVerified)
              Text('• 핸드폰 인증', style: theme.textTheme.bodyMedium),
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