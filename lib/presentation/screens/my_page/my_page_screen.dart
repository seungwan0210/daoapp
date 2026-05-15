// lib/presentation/screens/user/my_page_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/data/repositories/practice_repository.dart';
import 'package:daoapp/presentation/providers/practice/practice_provider.dart';
import 'package:daoapp/l10n/app_localizations.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  static Widget body() => const MyPageScreenBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MyPageScreen.body();
  }
}

class MyPageScreenBody extends ConsumerWidget {
  const MyPageScreenBody({super.key});

  /// ✅ [수정됨] 휴대폰 번호 로직 제거
  bool _determineHasProfile(Map<String, dynamic> data) {
    final koreanName = data['koreanName']?.toString().trim() ?? '';
    return koreanName.isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final totalRanking = ref.watch(totalRankingProvider);

    return SafeArea(
      top: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: authState.when(
          data: (user) {
            if (user == null) return _buildLoginPrompt(context, s);
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildProfilePrompt(context, ref, s);
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final hasProfile = _determineHasProfile(data);

                if (!hasProfile) return _buildProfilePrompt(context, ref, s);

                final rankIndex = totalRanking.indexWhere((item) => item['userId'] == user.uid);
                final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

                return _buildFullProfile(context, user, data, theme, ref, currentRank, s);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildLoginPrompt(context, s),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, AppLocalizations s) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_circle, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  s.mypage_login_prompt_title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  s.mypage_login_prompt_subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, RouteConstants.login),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset('assets/images/google_logo.png', width: 20, height: 20, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20, color: Colors.red)),
                        ),
                        const SizedBox(width: 12),
                        Text(s.mypage_login_btn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildProfilePrompt(BuildContext context, WidgetRef ref, AppLocalizations s) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add, size: 64, color: Colors.orange[400]),
                  const SizedBox(height: 24),
                  Text(
                    s.mypage_profile_prompt_title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.mypage_profile_prompt_subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, RouteConstants.profileRegister),
                      child: Text(s.mypage_profile_reg_btn),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildFunctionGrid(context, ref, s),
        ],
      ),
    );
  }

  Widget _buildFullProfile(BuildContext context, User user, Map<String, dynamic> data, ThemeData theme, WidgetRef ref, int? currentRank, AppLocalizations s) {
    final profileImageUrl = data['profileImageUrl'] as String?;
    final barrelImageUrl = data['barrelImageUrl'] as String?;
    final koreanName = data['koreanName']?.toString().trim() ?? s.member_list_no_name;
    final shopName = data['shopName']?.toString().trim() ?? '';

    final barrelName = data['barrelName']?.toString().trim() ?? '';
    final shaft = data['shaft']?.toString().trim() ?? '';
    final flight = data['flight']?.toString().trim() ?? '';
    final tip = data['tip']?.toString().trim() ?? '';

    final email = user.email ?? s.mypage_no_email;

    final hasBarrelSetting = barrelName.isNotEmpty || shaft.isNotEmpty || flight.isNotEmpty || tip.isNotEmpty || (barrelImageUrl?.isNotEmpty == true);

    final List<Widget> badgeWidgets = [];
    if (currentRank != null) badgeWidgets.add(BadgeWidget(rank: currentRank, size: 22));

    final badgesMap = BadgeUtils.extractBadges(data);
    final adminBadge = BadgeUtils.getLatestAdminBadge(badgesMap);
    if (adminBadge != null && badgeWidgets.length < 2) badgeWidgets.add(BadgeWidget(badgeKey: adminBadge, size: 22));

    return ListView(
      children: [
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showImageDialog(context, profileImageUrl),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: profileImageUrl?.isNotEmpty == true ? NetworkImage(profileImageUrl!) : null,
                            child: profileImageUrl?.isNotEmpty != true ? const Icon(Icons.account_circle, size: 44, color: Colors.grey) : null,
                          ),
                          ...badgeWidgets.asMap().entries.map((entry) {
                            final index = entry.key;
                            return Positioned(
                              left: -8 - (index * 18),
                              top: -8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))]),
                                child: entry.value,
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(koreanName, style: theme.textTheme.titleLarge, overflow: TextOverflow.ellipsis)),
                              if (shopName.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Flexible(child: Text('· $shopName', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(email, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ✅ [수정본] 프로필 수정 및 방명록 버튼 Row
                Row(
                  children: [
                    Expanded(child: _buildActionButton(context, icon: Icons.edit, label: s.mypage_edit_profile, onTap: () => Navigator.pushNamed(context, RouteConstants.profileRegister))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildActionButton(context, icon: Icons.comment, label: s.mypage_my_guestbook, onTap: () => Navigator.pushNamed(context, RouteConstants.guestbook, arguments: user.uid))),
                  ],
                ),
                if (hasBarrelSetting) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PLAYERS_DART', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _showImageDialog(context, barrelImageUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(color: Colors.grey[100], border: Border.all(color: Colors.grey.shade300)),
                                child: barrelImageUrl?.isNotEmpty == true
                                    ? Image.network(barrelImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey))
                                    : const Icon(Icons.sports_esports, size: 30, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBarrelInfoRow('BARREL', barrelName, theme),
                                _buildBarrelInfoRow('SHAFT', shaft, theme),
                                _buildBarrelInfoRow('FLIGHT', flight, theme),
                                _buildBarrelInfoRow('TIP', tip, theme),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildFunctionGrid(context, ref, s),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFunctionGrid(BuildContext context, WidgetRef ref, AppLocalizations s) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildIconButton(context, icon: Icons.edit_note, label: s.mypage_menu_mylog, route: RouteConstants.myLogHome, color: Colors.blueAccent),
            _buildIconButton(context, icon: Icons.delete_forever, label: s.mypage_account_delete, route: null, color: Colors.redAccent, onTap: () => _showAccountDeleteDialog(context, ref, s)),
            _buildIconButton(context, icon: Icons.logout, label: s.mypage_logout, route: null, color: Colors.grey, onTap: () => _showLogoutDialog(context, ref, s)),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, {required IconData icon, required String label, String? route, required Color color, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap ?? () { if (route != null) Navigator.pushNamed(context, route); },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(height: 6),
          // ✅ [수정본] 일본어 등 긴 텍스트 대응을 위한 Flexible 및 스타일 조정
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontSize: 11, // 텍스트 크기 살짝 조정
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref, AppLocalizations s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.mypage_logout),
        content: Text(s.mypage_logout_confirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.mypage_logout, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try { await sl<PracticeRepository>().stopPractice(user.uid, saveToMyLog: true); } catch (e) { debugPrint('Logout fail: $e'); }
    }

    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(myPracticeSessionProvider);
    ref.invalidate(practiceTimerProvider);
    ref.invalidate(livePracticeUsersProvider);

    if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, RouteConstants.login, (route) => false);
  }

  Future<void> _showAccountDeleteDialog(BuildContext context, WidgetRef ref, AppLocalizations s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.mypage_delete_confirm_title),
        content: Text(s.mypage_delete_confirm_body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.mypage_account_delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) await _deleteAccount(context, ref, s);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref, AppLocalizations s) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      await functions.httpsCallable('requestAccountDeletion').call();
      await ref.read(authRepositoryProvider).signOut();

      if (rootNavigator.canPop()) rootNavigator.pop();
      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, RouteConstants.login, (route) => false);
    } on FirebaseFunctionsException catch (e) {
      if (rootNavigator.canPop()) rootNavigator.pop();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? s.mypage_delete_error_general)));
    } on FirebaseAuthException catch (e) {
      if (rootNavigator.canPop()) rootNavigator.pop();
      String message = e.code == 'requires-recent-login' ? s.mypage_delete_error_recent_login : s.mypage_delete_error_general;
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (rootNavigator.canPop()) rootNavigator.pop();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.mypage_delete_error_server)));
    }
  }

  Widget _buildBarrelInfoRow(String label, String value, ThemeData theme) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: ' ', style: TextStyle(color: Colors.transparent)),
            TextSpan(text: value, style: const TextStyle(color: Colors.black87)),
          ],
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  // ✅ [수정본] 일본어 등 긴 텍스트 오버플로우 방지 로직 적용
  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // 좌우 패딩 추가
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary), // 아이콘 크기 소폭 축소
            const SizedBox(width: 4),
            Flexible( // 텍스트가 가용 공간을 넘지 않도록 Flexible 처리
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13, // 텍스트 크기 소폭 축소
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(child: Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.white))),
            Positioned(top: MediaQuery.of(ctx).padding.top + 16, right: 16, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(ctx))),
          ],
        ),
      ),
    );
  }
}