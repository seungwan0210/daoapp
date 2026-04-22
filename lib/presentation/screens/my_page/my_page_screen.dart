// lib/presentation/screens/user/my_page_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';

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

  /// ✅ [수정됨] 글로벌 번호 대응 프로필 보유 판단 로직
  bool _determineHasProfile(Map<String, dynamic> data) {
    // 1. 휴대폰 인증이 확실히 성공했는지 (isPhoneVerified)
    final isPhoneVerified = data['isPhoneVerified'] as bool? ?? false;

    // 2. 현재 저장된 번호가 유효한지
    final phoneNumber = data['phoneNumber']?.toString().trim() ?? '';

    // 3. 이름이 입력되었는지
    final koreanName = data['koreanName']?.toString().trim() ?? '';

    // 🔥 핵심: 번호가 바뀌는 중(인증 미완료)이라면 phoneNumber가 있어도
    // isPhoneVerified가 false이므로 프로필 등록 화면으로 유도하게 됩니다.
    // 이렇게 해야 Auth 서버와 DB 번호를 강제로 일치시킬 수 있습니다.
    return isPhoneVerified && phoneNumber.isNotEmpty && koreanName.isNotEmpty;
  }

  static const List<_GridItem> _mainFunctions = [
    _GridItem(Icons.edit_note, '마이로그', RouteConstants.myLogHome, Colors.blueAccent),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final totalRanking = ref.watch(totalRankingProvider);

    return SafeArea(
      top: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: authState.when(
          data: (user) {
            if (user == null) return _buildLoginPrompt(context);
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildProfilePrompt(context, ref);
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final hasProfile = _determineHasProfile(data);

                if (!hasProfile) return _buildProfilePrompt(context, ref);

                final rankIndex = totalRanking.indexWhere((item) => item['userId'] == user.uid);
                final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;

                return _buildFullProfile(context, user, data, theme, ref, currentRank);
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
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_circle, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  '로그인하면 내 정보를 확인할 수 있어요!',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Google 계정으로 간편하게 시작하세요',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      RouteConstants.login,
                    ),
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
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Google로 로그인',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildProfilePrompt(BuildContext context, WidgetRef ref) {
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
                    '프로필 등록이 필요해요!',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '이름 입력 + 휴대폰 인증을 완료해야\n다른 유저와 소통할 수 있어요',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, RouteConstants.profileRegister),
                      child: const Text('프로필 등록하기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildFunctionGrid(context, ref),
        ],
      ),
    );
  }

  Widget _buildFullProfile(
      BuildContext context,
      User user,
      Map<String, dynamic> data,
      ThemeData theme,
      WidgetRef ref,
      int? currentRank,
      ) {
    final profileImageUrl = data['profileImageUrl'] as String?;
    final barrelImageUrl = data['barrelImageUrl'] as String?;
    final koreanName = data['koreanName']?.toString().trim() ?? '이름 없음';
    final shopName = data['shopName']?.toString().trim() ?? '';

    // 🛠️ 배럴 정보 파싱
    final barrelName = data['barrelName']?.toString().trim() ?? '';
    final shaft = data['shaft']?.toString().trim() ?? '';
    final flight = data['flight']?.toString().trim() ?? '';
    final tip = data['tip']?.toString().trim() ?? '';

    final email = user.email ?? '이메일 없음';

    // ✅ [수정됨] 국제 번호 표시 대응
    final rawPhoneNumber = data['phoneNumber']?.toString().trim() ?? '';
    String displayPhone = rawPhoneNumber;

    // 한국 번호(+82)인 경우에만 가독성을 위해 하이픈 포맷팅 적용
    if (rawPhoneNumber.startsWith('+82')) {
      final digits = rawPhoneNumber.substring(3);
      if (digits.length == 10) {
        displayPhone = '0${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
      } else if (digits.length == 11) {
        displayPhone = '0${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
      }
    }

    final hasBarrelSetting = barrelName.isNotEmpty ||
        shaft.isNotEmpty ||
        flight.isNotEmpty ||
        tip.isNotEmpty ||
        (barrelImageUrl?.isNotEmpty == true);

    final List<Widget> badgeWidgets = [];
    if (currentRank != null) {
      badgeWidgets.add(BadgeWidget(rank: currentRank, size: 22));
    }

    final badgesMap = BadgeUtils.extractBadges(data);
    final adminBadge = BadgeUtils.getLatestAdminBadge(badgesMap);
    if (adminBadge != null && badgeWidgets.length < 2) {
      badgeWidgets.add(BadgeWidget(badgeKey: adminBadge, size: 22));
    }

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
                            backgroundImage: profileImageUrl?.isNotEmpty == true
                                ? NetworkImage(profileImageUrl!)
                                : null,
                            child: profileImageUrl?.isNotEmpty != true
                                ? const Icon(Icons.account_circle, size: 44, color: Colors.grey)
                                : null,
                          ),
                          ...badgeWidgets.asMap().entries.map((entry) {
                            final index = entry.key;
                            return Positioned(
                              left: -8 - (index * 18),
                              top: -8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                                ),
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
                              Flexible(
                                child: Text(koreanName, style: theme.textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                              ),
                              if (shopName.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text('· $shopName',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(email, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                          if (displayPhone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(displayPhone, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildActionButton(
                            context,
                            icon: Icons.edit,
                            label: '프로필 수정',
                            onTap: () => Navigator.pushNamed(context, RouteConstants.profileRegister)
                        )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildActionButton(
                            context,
                            icon: Icons.comment,
                            label: '내 방명록',
                            onTap: () => Navigator.pushNamed(context, RouteConstants.guestbook, arguments: user.uid)
                        )
                    ),
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
                                width: 64,
                                height: 64,
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
        _buildFunctionGrid(context, ref),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFunctionGrid(BuildContext context, WidgetRef ref) {
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
            ..._mainFunctions.map(
                  (item) => _buildIconButton(
                context,
                icon: item.icon,
                label: item.label,
                route: item.route,
                color: item.color,
              ),
            ),
            _buildIconButton(
              context,
              icon: Icons.delete_forever,
              label: '계정 삭제',
              route: null,
              color: Colors.redAccent,
              onTap: () => _showAccountDeleteDialog(context, ref),
            ),
            _buildIconButton(
              context,
              icon: Icons.logout,
              label: '로그아웃',
              route: null,
              color: Colors.grey,
              onTap: () => _showLogoutDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        String? route,
        required Color color,
        VoidCallback? onTap,
      }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap ??
              () {
            if (route != null) {
              Navigator.pushNamed(context, route);
            }
          },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 26,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(authRepositoryProvider).signOut();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteConstants.login,
            (route) => false,
      );
    }
  }

  Future<void> _showAccountDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('계정 삭제'),
        content: const Text(
          'DAO 계정을 삭제하면 프로필 정보와 앱 내 데이터가 삭제되며,\n'
              '이 작업은 되돌릴 수 없습니다.\n\n정말 계정을 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('계정 삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount(context, ref);
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');
      await functions.httpsCallable('requestAccountDeletion').call();
      await ref.read(authRepositoryProvider).signOut();

      try {
        if (rootNavigator.canPop()) rootNavigator.pop();
      } catch (_) {}

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteConstants.login,
              (route) => false,
        );
      }
    } on FirebaseFunctionsException catch (e) {
      try {
        if (rootNavigator.canPop()) rootNavigator.pop();
      } catch (_) {}
      final msg = _mapAccountDeleteFunctionError(e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } on FirebaseAuthException catch (e) {
      try {
        if (rootNavigator.canPop()) rootNavigator.pop();
      } catch (_) {}
      String message = e.code == 'requires-recent-login'
          ? '보안을 위해 최근 로그인한 사용자만 계정을 삭제할 수 있어요.\n다시 로그인한 후 시도해주세요.'
          : '계정 삭제 중 오류가 발생했습니다.';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      try {
        if (rootNavigator.canPop()) rootNavigator.pop();
      } catch (_) {}
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('계정 삭제 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.')),
        );
      }
    }
  }

  String _mapAccountDeleteFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated': return '로그인이 필요합니다. 다시 로그인한 뒤 시도해주세요.';
      case 'permission-denied': return '권한이 없습니다. 관리자에게 문의해주세요.';
      case 'deadline-exceeded': return '삭제 작업이 지연되고 있어요. 네트워크 확인 후 다시 시도해주세요.';
      case 'unavailable': return '서버 연결이 불안정합니다. 잠시 후 다시 시도해주세요.';
      default:
        final details = (e.message ?? '').trim();
        return details.isNotEmpty ? details : '계정 삭제 처리 중 오류가 발생했습니다.';
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

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
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
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _GridItem(this.icon, this.label, this.route, this.color);
}