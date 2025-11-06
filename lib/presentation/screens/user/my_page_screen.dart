// lib/presentation/screens/user/my_page_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

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
                final profileImageUrl = data['profileImageUrl'] as String?;
                final barrelImageUrl = data['barrelImageUrl'] as String?;
                final koreanName = data['koreanName'] ?? '이름 없음';
                final shopName = data['shopName'] ?? '';
                final barrelName = data['barrelName'] ?? '';
                final shaft = data['shaft'] ?? '';
                final flight = data['flight'] ?? '';
                final tip = data['tip'] ?? '';
                final email = user.email ?? '이메일 없음';

                // 배럴 세팅 존재 여부 확인
                final hasBarrelSetting = barrelName.isNotEmpty ||
                    shaft.isNotEmpty ||
                    flight.isNotEmpty ||
                    tip.isNotEmpty ||
                    (barrelImageUrl != null && barrelImageUrl.isNotEmpty);

                return ListView(
                  children: [
                    // === 1. 내 정보 카드 ===
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // 사진 + 이름 + 이메일
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _showImageDialog(context, profileImageUrl),
                                  child: CircleAvatar(
                                    radius: 36,
                                    backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                        ? NetworkImage(profileImageUrl)
                                        : null,
                                    child: profileImageUrl == null || profileImageUrl.isEmpty
                                        ? const Icon(Icons.account_circle, size: 44, color: Colors.grey)
                                        : null,
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
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 프로필 수정 + 내 방명록
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

                            // 배럴 세팅 (존재할 때만 표시)
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
                                            child: barrelImageUrl != null && barrelImageUrl.isNotEmpty
                                                ? Image.network(barrelImageUrl, fit: BoxFit.cover)
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

                    // === 2. 나머지 기능 ===
                    AppCard(
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
                            _buildIconButton(context, Icons.calendar_month, '포인트 달력', RouteConstants.pointCalendar),
                            _buildIconButton(context, Icons.card_membership, 'KDF 정회원', RouteConstants.memberList),
                            _buildIconButton(context, Icons.logout, '로그아웃', null, onTap: () async {
                              await ref.read(authRepositoryProvider).signOut();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, RouteConstants.login);
                              }
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildLoginPrompt(context),
        ),
      ),
    );
  }

  // 배럴 정보 라벨 + ... 처리
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

  // 액션 버튼
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

  // 아이콘 버튼
  Widget _buildIconButton(BuildContext context, IconData icon, String label, String? route, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pushNamed(context, route!),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // 사진 확대
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
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
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

  static Widget _buildLoginPrompt(BuildContext context) {
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
                Text('로그인하면 내 정보를 확인할 수 있어요!', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text('Google 계정으로 간편하게 시작하세요', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
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
                          child: Image.asset('assets/images/google_logo.png', width: 20, height: 20, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20, color: Colors.red)),
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
}