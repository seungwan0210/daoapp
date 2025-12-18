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

class _CommunityHomeScreenState extends ConsumerState<CommunityHomeScreen> {
  void _goToTraining() {
    MainScreen.changeTab(context, 1);
  }

  void _goToArena() {
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
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) return _buildLoginPrompt(context, theme);

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
                final hasProfile = data['hasProfile'] == true;
                final isPhoneVerified = data['isPhoneVerified'] == true;

                if (!hasProfile || !isPhoneVerified) {
                  return _buildVerificationPrompt(
                    context: context,
                    theme: theme,
                    hasProfile: hasProfile,
                    isPhoneVerified: isPhoneVerified,
                  );
                }

                // ✅ 여기부터: 홈 전체 스크롤 구조
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const CommunityAvatarSlider(),
                      const SizedBox(height: 16),

                      // ==========================
                      // 메인 이동 그리드
                      // ==========================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '연습 · 대회 · 기록',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AppCard(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics:
                              const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
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

                      const SizedBox(height: 16),

                      // ==========================
                      // 커뮤니티 프리뷰
                      // ==========================
                      CommunityPreview(
                        onSeeAllPressed: () {
                          Navigator.pushNamed(
                              context, RouteConstants.circle);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () =>
          const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildLoginPrompt(context, theme),
        ),
      ),
    );
  }

  // ==========================
  // 로그인 유도
  // ==========================
  Widget _buildLoginPrompt(BuildContext context, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_alt_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  '커뮤니티를 이용하려면\n로그인이 필요해요',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================
  // 인증 유도
  // ==========================
  Widget _buildVerificationPrompt({
    required BuildContext context,
    required ThemeData theme,
    required bool hasProfile,
    required bool isPhoneVerified,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 64, color: Colors.grey[500]),
                const SizedBox(height: 20),
                Text(
                  '커뮤니티 이용을 위해\n인증이 필요해요',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================
// 메인 기능 그리드 타일
// ===============================
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
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
