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
                final hasProfile = data['hasProfile'] == true;
                final profileImageUrl = data['profileImageUrl'] as String?;
                final koreanName = data['koreanName'] ?? '';
                final englishName = data['englishName'] ?? '';
                final shopName = data['shopName'] ?? '';
                final email = user.email ?? '이메일 없음';

                return ListView(
                  children: [
                    // === 1. 프로필 정보 ===
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: _getProfileImageProvider(
                                profileImageUrl: profileImageUrl,
                                googlePhotoUrl: hasProfile ? null : user.photoURL,
                              ),
                              child: profileImageUrl == null && (hasProfile || user.photoURL == null)
                                  ? const Icon(Icons.account_circle, size: 50, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 한국 이름 + 홈샵 한 줄
                                  if (koreanName.isNotEmpty)
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
                                          Text(
                                            '· $shopName',
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ],
                                    ),
                                  const SizedBox(height: 4),
                                  // 영어 이름
                                  if (englishName.isNotEmpty)
                                    Text(
                                      englishName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.grey[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  const SizedBox(height: 4),
                                  // 이메일
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
                      ),
                    ),

                    const SizedBox(height: 12), // 카드 간격 통일

                    // === 2. 프로필 수정 ===
                    AppCard(
                      onTap: () => Navigator.pushNamed(context, RouteConstants.profileRegister),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                        title: const Text('프로필 수정'),
                        subtitle: hasProfile
                            ? const Text('닉네임, 샵, 배럴 세팅')
                            : const Text('프로필 등록이 필요합니다', style: TextStyle(color: Colors.red)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // === 3. 포인트 달력 ===
                    AppCard(
                      onTap: () => Navigator.pushNamed(context, RouteConstants.pointCalendar),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                        title: const Text('포인트 달력'),
                        subtitle: const Text('날짜별 내역 확인'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // === 4. KDF 정회원 명단 ===
                    AppCard(
                      onTap: () => Navigator.pushNamed(context, RouteConstants.memberList),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Icon(Icons.card_membership, color: theme.colorScheme.primary),
                        title: const Text('KDF 정회원 명단'),
                        subtitle: const Text('등록된 정회원 리스트 확인'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // === 5. 로그아웃 ===
                    AppCard(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('로그아웃'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await ref.read(authRepositoryProvider).signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, RouteConstants.login);
                          }
                        },
                      ),
                    ),

                    // 하단 여백
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

  ImageProvider? _getProfileImageProvider({
    required String? profileImageUrl,
    required String? googlePhotoUrl,
  }) {
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return NetworkImage(profileImageUrl);
    }
    if (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty) {
      return NetworkImage(googlePhotoUrl);
    }
    return null;
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
}