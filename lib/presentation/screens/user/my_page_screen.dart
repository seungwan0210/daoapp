// lib/presentation/screens/user/my_page_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';

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

  bool _determineHasProfile(Map<String, dynamic> data) {
    final hasProfile = data['hasProfile'] as bool? ?? false;
    final isPhoneVerified = data['isPhoneVerified'] as bool? ?? false;
    final koreanName = data['koreanName']?.toString().trim();
    return hasProfile && isPhoneVerified && koreanName != null && koreanName.isNotEmpty;
  }

  // 핵심 기능 3개 (마이로그 추가!)
  static const List<_GridItem> _mainFunctions = [
    _GridItem(Icons.calendar_month, '포인트 달력', RouteConstants.pointCalendar),
    _GridItem(Icons.card_membership, 'KDF 정회원', RouteConstants.memberList),
    _GridItem(Icons.edit_note, '마이로그', RouteConstants.myLogHome),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

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
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final hasProfile = _determineHasProfile(data);
                if (!hasProfile) {
                  return _buildProfilePrompt(context, ref);
                }
                return _buildFullProfile(context, user, data, theme, ref);
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
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '이름 입력 + 휴대폰 인증을 완료해야\n다른 유저와 소통할 수 있어요',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, RouteConstants.profileRegister),
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
      ) {
    final profileImageUrl = data['profileImageUrl'] as String?;
    final barrelImageUrl = data['barrelImageUrl'] as String?;
    final koreanName = data['koreanName']?.toString().trim() ?? '이름 없음';
    final shopName = data['shopName']?.toString().trim() ?? '';
    final barrelName = data['barrelName']?.toString().trim() ?? '';
    final shaft = data['shaft']?.toString().trim() ?? '';
    final flight = data['flight']?.toString().trim() ?? '';
    final tip = data['tip']?.toString().trim() ?? '';
    final email = user.email ?? '이메일 없음';
    final phoneNumber = data['phoneNumber']?.toString().trim() ?? '';

    final hasBarrelSetting = barrelName.isNotEmpty ||
        shaft.isNotEmpty ||
        flight.isNotEmpty ||
        tip.isNotEmpty ||
        (barrelImageUrl?.isNotEmpty == true);

    final badgesMap = BadgeUtils.extractBadges(data);
    final monthlyBadge = BadgeUtils.getLatestMonthlyBadge(badgesMap);
    final adminBadge = BadgeUtils.getLatestAdminBadge(badgesMap);

    final badgesToShow = <String>[];
    if (monthlyBadge != null) badgesToShow.add(monthlyBadge);
    if (adminBadge != null) badgesToShow.add(adminBadge);

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
                          ...badgesToShow.asMap().entries.map((entry) {
                            final index = entry.key;
                            final key = entry.value;
                            return Positioned(
                              left: -8 - (index * 18),
                              top: -8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Tooltip(
                                  message: BadgeUtils.getBadgeTooltip(key),
                                  child: BadgeWidget(badgeKey: key, size: 20),
                                ),
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
                                child: Text(
                                  koreanName,
                                  style: theme.textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (shopName.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '· $shopName',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (phoneNumber.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  phoneNumber,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
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
                        onTap: () =>
                            Navigator.pushNamed(context, RouteConstants.profileRegister),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Icons.comment,
                        label: '내 방명록',
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteConstants.guestbook,
                          arguments: user.uid,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasBarrelSetting) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLAYERS_DART',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _showImageDialog(context, barrelImageUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: barrelImageUrl?.isNotEmpty == true
                                    ? Image.network(
                                  barrelImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.error),
                                )
                                    : const Icon(Icons.sports_esports,
                                    size: 30, color: Colors.grey),
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

        // 첫 번째 카드: 포인트 달력, KDF 정회원, 마이로그
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 0.9, // 🔧 세로 공간 확보
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: _mainFunctions
                  .map((item) =>
                  _buildIconButton(context, item.icon, item.label, item.route))
                  .toList(),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 두 번째 카드: 로그아웃
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 0.9, // 🔧 세로 공간 확보
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildIconButton(
                  context,
                  Icons.logout,
                  '로그아웃',
                  null,
                  onTap: () => _showLogoutDialog(context, ref),
                ),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // 프로필 미등록 시에도 사용하는 그리드
  Widget _buildFunctionGrid(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 0.9, // 🔧 세로 공간 확보
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: _mainFunctions
                  .map((item) =>
                  _buildIconButton(context, item.icon, item.label, item.route))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 0.9, // 🔧 세로 공간 확보
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildIconButton(
                  context,
                  Icons.logout,
                  '로그아웃',
                  null,
                  onTap: () => _showLogoutDialog(context, ref),
                ),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(
      BuildContext context,
      IconData icon,
      String label,
      String? route, {
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap ??
              () {
            if (route != null) {
              Navigator.pushNamed(context, route);
            }
          },
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔧 콘텐츠 크기에 맞게
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26, // 🔧 살짝 줄임
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4), // 🔧 간격 조금 줄임
          Text(
            label,
            maxLines: 2, // 🔧 긴 텍스트 대비
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(authRepositoryProvider).signOut();
    await FirebaseFirestore.instance.clearPersistence();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteConstants.login,
            (route) => false,
      );
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
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(
              text: ' ',
              style: TextStyle(color: Colors.transparent),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black87),
            ),
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
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.error, color: Colors.white),
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
  const _GridItem(this.icon, this.label, this.route);
}
