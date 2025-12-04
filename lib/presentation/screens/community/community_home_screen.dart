// lib/presentation/screens/community/community_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/screens/community/widgets/community_avatar_slider.dart';
import 'package:daoapp/presentation/screens/community/widgets/community_preview.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';

class CommunityHomeScreen extends ConsumerStatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  ConsumerState<CommunityHomeScreen> createState() =>
      _CommunityHomeScreenState();
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

  void _goToTraining() {
    // 트레이닝 탭 인덱스: 1
    MainScreen.changeTab(context, 1);
  }

  void _goToArena() {
    // 아레나 탭 인덱스: 2
    MainScreen.changeTab(context, 2);
  }

  void _goToMyLog() {
    Navigator.pushNamed(context, RouteConstants.myLogHome);
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

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final hasProfile = data['hasProfile'] as bool? ?? false;
                final isPhoneVerified =
                    data['isPhoneVerified'] as bool? ?? false;

                if (!hasProfile || !isPhoneVerified) {
                  return _buildVerificationPrompt(
                      hasProfile, isPhoneVerified);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const CommunityAvatarSlider(),
                    const SizedBox(height: 16),

                    // ==========================
                    // 메인 이동 그리드 섹션 (슬림 버전)
                    // ==========================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '연습 · 대회 · 기록',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppCard(
                        child: Padding(
                          // 카드 안 여백을 많이 줄임
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            // 가로에 비해 세로를 더 작게 → 전체 높이 감소
                            childAspectRatio: 1.2,
                            children: [
                              _MainGridItem(
                                icon: Icons.track_changes_outlined,
                                label: '트레이닝',
                                color: Colors.teal,
                                onTap: _goToTraining,
                              ),
                              _MainGridItem(
                                icon: Icons.emoji_events_outlined,
                                label: '아레나',
                                color: Colors.indigo,
                                onTap: _goToArena,
                              ),
                              _MainGridItem(
                                icon: Icons.edit_note_outlined,
                                label: '마이로그',
                                color: Colors.deepOrange,
                                onTap: _goToMyLog,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==========================
                    // 커뮤니티 프리뷰 (최근 / 인기)
                    // ==========================
                    Expanded(
                      child: CommunityPreview(
                        onSeeAllPressed: () {
                          Navigator.pushNamed(
                            context,
                            RouteConstants.circle,
                          );
                        },
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
            Icon(Icons.people_alt_outlined,
                size: 80, color: Colors.grey[400]!),
            const SizedBox(height: 32),
            Text(
              "커뮤니티에 오신 걸 환영해요!",
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
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
                onPressed: () => Navigator.pushReplacementNamed(
                    context, RouteConstants.login),
                icon: const Icon(Icons.login, size: 24),
                label: const Text(
                  "Google로 로그인",
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(elevation: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationPrompt(
      bool hasProfile, bool isPhoneVerified) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined,
                size: 80, color: Colors.orange[600]),
            const SizedBox(height: 32),
            Text(
              "커뮤니티 이용을 위해\n인증이 필요해요",
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
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
                onPressed: () => Navigator.pushNamed(
                    context, RouteConstants.profileRegister),
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                label: const Text(
                  "인증하러 가기",
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================
/// 메인 기능 그리드 타일
/// ===============================
class _MainGridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MainGridItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘 영역 (조금 더 작게)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }
}
