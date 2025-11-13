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
import 'package:daoapp/presentation/screens/community/arena/arena_preview.dart';

class CommunityHomeScreen extends ConsumerStatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  ConsumerState<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends ConsumerState<CommunityHomeScreen> with TickerProviderStateMixin {
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
    Navigator.pushNamed(context, RouteConstants.checkoutHome); // 체크아웃 홈으로 이동!
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
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(includeMetadataChanges: true),
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
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 3),
                          insets: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
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
                          // 1. 서클
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: CommunityPreview(onSeeAllPressed: _goToCircleFull),
                          ),

                          // 2. 체크아웃 홈 → 클릭 시 전체 계산기 이동!
                          GestureDetector(
                            onTap: _goToCheckoutHome, // 수정됨
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                    child: Icon(
                                      Icons.sports_score,
                                      size: 56,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "체크아웃",
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "계산기, 연습 모드\n통계까지 한 번에!",
                                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Icon(Icons.touch_app, size: 32, color: theme.colorScheme.primary),
                                ],
                              ),
                            ),
                          ),

                          // 3. 아레나
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
            if (!hasProfile) Text('• 프로필 등록', style: theme.textTheme.bodyMedium),
            if (!isPhoneVerified) Text('• 핸드폰 인증', style: theme.textTheme.bodyMedium),
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