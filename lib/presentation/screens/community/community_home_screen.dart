// lib/presentation/screens/community/community_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/screens/community/widgets/community_avatar_slider.dart';
import 'package:daoapp/presentation/screens/community/widgets/community_preview.dart';

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
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToCircleFull() {
    Navigator.pushNamed(context, RouteConstants.circle);
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
            if (user == null) return _buildLoginPrompt();

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final hasProfile = data['hasProfile'] as bool? ?? false;
                final isPhoneVerified = data['isPhoneVerified'] as bool? ?? false;

                if (!hasProfile || !isPhoneVerified) {
                  return _buildVerificationPrompt(hasProfile, isPhoneVerified);
                }

                return Column(
                  children: [
                    const SizedBox(height: 16),
                    const CommunityAvatarSlider(),
                    const SizedBox(height: 24),

                    // 서클 피드 타이틀
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.groups, size: 32, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            "서클 피드",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _goToCircleFull,
                            child: const Text("전체보기", style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 서클 피드 프리뷰
                    Expanded(
                      child: CommunityPreview(
                        onSeeAllPressed: _goToCircleFull,
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildLoginPrompt(),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_outlined, size: 80, color: Colors.grey[400]!),
            const SizedBox(height: 32),
            Text(
              "커뮤니티에 오신 걸 환영해요!",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "다트 친구들과 소통하고,\n서클에서 함께 즐겨보세요",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, RouteConstants.login),
                icon: const Icon(Icons.login, size: 24),
                label: const Text("Google로 로그인", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(elevation: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationPrompt(bool hasProfile, bool isPhoneVerified) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined, size: 80, color: Colors.orange[600]),
            const SizedBox(height: 32),
            Text(
              "커뮤니티 이용을 위해\n인증이 필요해요",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!hasProfile)
              const Chip(
                avatar: Icon(Icons.person_add, size: 18),
                label: Text("프로필 등록 필요"),
                backgroundColor: Colors.orangeAccent,
              ),
            if (!isPhoneVerified)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Chip(
                  avatar: Icon(Icons.phone_android, size: 18),
                  label: Text("핸드폰 인증 필요"),
                  backgroundColor: Colors.redAccent,
                ),
              ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, RouteConstants.profileRegister),
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                label: const Text("인증하러 가기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}