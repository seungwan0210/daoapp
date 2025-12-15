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
            if (user == null) return _buildLoginPrompt(context, theme);

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
                  return _buildVerificationPrompt(
                    context: context,
                    theme: theme,
                    hasProfile: hasProfile,
                    isPhoneVerified: isPhoneVerified,
                  );
                }

                // ✅ 인증 완료 유저만 커뮤니티 사용 가능
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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

                    const SizedBox(height: 12),

                    // ==========================
                    // 커뮤니티 프리뷰 (최근 / 인기)
                    // ==========================
                    Expanded(
                      child: CommunityPreview(
                        onSeeAllPressed: () {
                          Navigator.pushNamed(context, RouteConstants.circle);
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildLoginPrompt(context, theme),
        ),
      ),
    );
  }

  // ==========================
  // ✅ MyPage 톤으로 통일된 로그인 유도
  // ==========================
  Widget _buildLoginPrompt(BuildContext context, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_alt_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  '커뮤니티를 이용하려면\n로그인이 필요해요',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '다트 친구들과 소통하고\n서클에서 함께 즐겨보세요',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
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
                          child: Image.asset(
                            'assets/images/google_logo.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.g_mobiledata, size: 20, color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Google로 로그인',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================
  // ✅ MyPage 톤으로 통일된 인증/프로필 유도
  // ==========================
  Widget _buildVerificationPrompt({
    required BuildContext context,
    required ThemeData theme,
    required bool hasProfile,
    required bool isPhoneVerified,
  }) {
    final items = <_RequirementItem>[
      _RequirementItem(
        title: '프로필 등록',
        done: hasProfile,
        icon: Icons.person_outline,
      ),
      _RequirementItem(
        title: '휴대폰 인증',
        done: isPhoneVerified,
        icon: Icons.phone_android_outlined,
      ),
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey[500]),
                const SizedBox(height: 20),
                Text(
                  '커뮤니티 이용을 위해\n인증이 필요해요',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '아래 항목을 완료하면\n서클 글/댓글/좋아요가 가능해져요',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // ✅ 체크리스트(칩 대신 통일감 있는 리스트)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: items.map((e) => _buildRequirementRow(theme, e)).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, RouteConstants.profileRegister),
                    style: theme.elevatedButtonTheme.style,
                    child: const Text(
                      '인증하러 가기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  '완료 후 자동으로 커뮤니티가 열려요',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(ThemeData theme, _RequirementItem item) {
    final doneColor = theme.colorScheme.primary;
    final offColor = Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: item.done ? doneColor : offColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: item.done ? Colors.grey[900] : Colors.grey[800],
              ),
            ),
          ),
          Icon(
            item.done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: item.done ? doneColor : Colors.grey[400],
          ),
        ],
      ),
    );
  }
}

class _RequirementItem {
  final String title;
  final bool done;
  final IconData icon;

  _RequirementItem({
    required this.title,
    required this.done,
    required this.icon,
  });
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
