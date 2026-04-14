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

  /// ✅ UGC(커뮤니티) 동의 저장
  Future<void> _acceptUgcTerms(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'ugcTermsAccepted': true,
          'ugcTermsAcceptedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('동의 처리 실패: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// ✅ (선택) 동의서/가이드 자세히 보기: 프라이버시 페이지로 보내고 싶으면 사용
  /// - 지금은 라우트가 없을 수 있어서, 버튼은 주석으로 두었어.
  /// - 프라이버시/약관 라우트가 있으면 여기에 연결하면 돼.
  void _openTermsDetail() {
    // 예시:
    // Navigator.pushNamed(context, RouteConstants.privacy);
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

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final hasProfile = data['hasProfile'] == true;
                final isPhoneVerified = data['isPhoneVerified'] == true;

                // ✅ 1) 프로필/폰 인증 먼저
                if (!hasProfile || !isPhoneVerified) {
                  return _buildVerificationPrompt(
                    context: context,
                    theme: theme,
                    hasProfile: hasProfile,
                    isPhoneVerified: isPhoneVerified,
                  );
                }

                // ✅ 2) UGC 동의 게이트 (커뮤니티 프리뷰가 UGC를 보여주므로 여기서 막는게 정답)
                final ugcAccepted = data['ugcTermsAccepted'] == true;
                if (!ugcAccepted) {
                  return _buildUgcTermsGate(
                    context: context,
                    theme: theme,
                    uid: user.uid,
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

                      const SizedBox(height: 16),

                      // ==========================
                      // 커뮤니티 프리뷰 (동의 완료 후에만 노출됨)
                      // ==========================
                      CommunityPreview(
                        onSeeAllPressed: () {
                          Navigator.pushNamed(context, RouteConstants.circle);
                        },
                      ),
                    ],
                  ),
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
  // UGC 동의 게이트 UI
  // ==========================
  Widget _buildUgcTermsGate({
    required BuildContext context,
    required ThemeData theme,
    required String uid,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.policy_outlined, size: 64, color: Colors.grey[500]),
                const SizedBox(height: 18),
                Text(
                  '커뮤니티 이용 동의가 필요해요',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '커뮤니티에는 사용자가 작성한 글/사진(UGC)이 노출됩니다.\n'
                      '안전한 이용을 위해 아래 내용에 동의해 주세요.\n\n'
                      '• 타인을 비방/혐오/차별/괴롭힘하는 콘텐츠 금지\n'
                      '• 불법/음란/폭력/사기 등 유해 콘텐츠 금지\n'
                      '• 신고/차단 기능 및 운영 정책에 따라 제재될 수 있음\n'
                      '• 신고된 콘텐츠는 운영자가 검토할 수 있음',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[800],
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),

                // (선택) 자세히 보기 버튼 — 라우트 준비되면 연결
                // Align(
                //   alignment: Alignment.centerRight,
                //   child: TextButton(
                //     onPressed: _openTermsDetail,
                //     child: const Text('자세히 보기'),
                //   ),
                // ),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // ✅ 동의 안 하면 커뮤니티 이용을 막는게 애플 심사상 안전함
                          // 홈 탭에서는 "아무것도 안 보여주기" 상태로 유지.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('동의 후 커뮤니티 이용이 가능합니다.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('동의 안함'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _acceptUgcTerms(uid),
                        child: const Text('동의하고 시작'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                const SizedBox(height: 10),
                Text(
                  !hasProfile
                      ? '프로필 등록을 완료해 주세요.'
                      : '휴대폰 인증을 완료해 주세요.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
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
