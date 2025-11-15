// lib/presentation/screens/user/my_page_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/badge_constants.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/data/models/user_model.dart'; // 추가!

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

  static const List<_GridItem> _functionItems = [
    _GridItem(Icons.calendar_month, '포인트 달력', RouteConstants.pointCalendar),
    _GridItem(Icons.card_membership, 'KDF 정회원', RouteConstants.memberList),
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
            if (user == null) {
              return _buildLoginPrompt(context);
            }

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
                            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20, color: Colors.red),
                          ),
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

  Widget _buildFullProfile(BuildContext context, User user, Map<String, dynamic> data, ThemeData theme, WidgetRef ref) {
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

    // AppUser 생성 → currentBadgeKey 추출
    final appUser = AppUser.fromMap(user.uid, data);
    final currentBadgeKey = appUser.currentMonthlyBadgeKey;

    return ListView(
      children: [
        // === 월간 배지 섹션 ===
        _buildBadgeSection(context, data, theme),

        const SizedBox(height: 20),

        // 프로필 정보
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // === 프로필 사진 + 배지 (우측 상단) ===
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
                          if (currentBadgeKey != null)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                                  ],
                                ),
                                child: BadgeWidget(badgeKey: currentBadgeKey, size: 28),
                              ),
                            ),
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
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
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
                        onTap: () => Navigator.pushNamed(context, RouteConstants.profileRegister),
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
                                    ? Image.network(barrelImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.error))
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

  Widget _buildBadgeSection(BuildContext context, Map<String, dynamic> data, ThemeData theme) {
    final badges = data['badges'] as Map<String, dynamic>? ?? {};
    final monthlyBadges = badges.entries
        .where((e) => e.key.startsWith('monthly_') && e.value == true)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (monthlyBadges.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayBadges = monthlyBadges.take(3).toList();
    final hasMore = monthlyBadges.length > 3;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  '월간 랭킹 배지',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: displayBadges.map((key) {
                return BadgeWidget(badgeKey: key, size: 36);
              }).toList(),
            ),
            if (hasMore) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('배지 갤러리 준비 중...')),
                    );
                  },
                  child: const Text('더보기'),
                ),
              ),
            ],
          ],
        ),
      ),
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
          childAspectRatio: 1.4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            ..._functionItems.map((item) => _buildIconButton(
              context,
              item.icon,
              item.label,
              item.route,
            )),
            _buildLogoutButton(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return _buildIconButton(
      context,
      Icons.logout,
      '로그아웃',
      null,
      onTap: () async {
        await ref.read(authRepositoryProvider).signOut();
        await FirebaseFirestore.instance.clearPersistence();
        ProviderScope.containerOf(context).refresh(authStateProvider);
        ProviderScope.containerOf(context).refresh(userHasProfileProvider);

        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteConstants.login,
                (route) => false,
          );
        }
      },
    );
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
            TextSpan(text: value, style: const TextStyle(color: Colors.black87)),
          ],
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
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

  Widget _buildIconButton(BuildContext context, IconData icon, String label, String? route, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pushNamed(context, route!),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
  const _GridItem(this.icon, this.label, this.route);
}