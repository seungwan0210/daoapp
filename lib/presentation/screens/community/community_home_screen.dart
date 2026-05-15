import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/ad_manager.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/screens/community/widgets/community_avatar_slider.dart';
import 'package:daoapp/presentation/screens/community/widgets/community_preview.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';

// ✅ 라이브 채팅 전광판 임포트
import 'package:daoapp/presentation/screens/community/chat/widgets/live_chat_ticker.dart';

// ✅ AdMob 배너 광고 위젯 임포트
import 'package:daoapp/presentation/widgets/ad_banner.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

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
    final s = AppLocalizations.of(context)!;
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
          content: Text(s.community_home_ugc_msg_fail(e.toString())),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) return _buildLoginPrompt(context, theme, s);

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

                if (!hasProfile || !isPhoneVerified) {
                  return _buildVerificationPrompt(
                    context: context,
                    theme: theme,
                    s: s,
                    hasProfile: hasProfile,
                    isPhoneVerified: isPhoneVerified,
                  );
                }

                final ugcAccepted = data['ugcTermsAccepted'] == true;
                if (!ugcAccepted) {
                  return _buildUgcTermsGate(
                    context: context,
                    theme: theme,
                    s: s,
                    uid: user.uid,
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      const CommunityAvatarSlider(),

                      const SizedBox(height: 8),
                      const LiveChatTicker(),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          s.community_home_tab_title,
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
                                  label: s.community_home_menu_training,
                                  color: Colors.teal,
                                  onTap: _goToTraining,
                                ),
                                _MainGridItem(
                                  icon: Icons.emoji_events_outlined,
                                  label: s.community_home_menu_arena,
                                  color: Colors.indigo,
                                  onTap: _goToArena,
                                ),
                                _MainGridItem(
                                  icon: Icons.edit_note_outlined,
                                  label: s.community_home_menu_mylog,
                                  color: Colors.deepOrange,
                                  onTap: _goToMyLog,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      CommunityPreview(
                        onSeeAllPressed: () {
                          Navigator.pushNamed(context, RouteConstants.circle);
                        },
                      ),

                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ADVERTISEMENT',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const AdBanner(type: AdBannerType.main),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildLoginPrompt(context, theme, s),
        ),
      ),
    );
  }

  Widget _buildUgcTermsGate({
    required BuildContext context,
    required ThemeData theme,
    required AppLocalizations s,
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
                  s.community_home_ugc_title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.community_home_ugc_desc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[800],
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.community_home_ugc_msg_reject),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(s.community_home_ugc_btn_no),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _acceptUgcTerms(uid),
                        child: Text(s.community_home_ugc_btn_yes),
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

  Widget _buildLoginPrompt(BuildContext context, ThemeData theme, AppLocalizations s) {
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
                  s.community_home_login_prompt,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationPrompt({
    required BuildContext context,
    required ThemeData theme,
    required AppLocalizations s,
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
                Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey[500]),
                const SizedBox(height: 20),
                Text(
                  s.community_home_verify_prompt,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  !hasProfile ? s.community_home_verify_profile : s.community_home_verify_phone,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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