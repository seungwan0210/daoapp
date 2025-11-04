// lib/presentation/screens/user/my_page_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  // body만 반환
  static Widget body() => const MyPageScreenBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MyPageScreen.body();
  }
}

class MyPageScreenBody extends ConsumerWidget {
  const MyPageScreenBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(userHasProfileProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: authState.when(
        data: (user) {
          if (user == null) {
            return _buildLoginPrompt(context);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 등록 유도
              profileState.when(
                data: (hasProfile) {
                  return hasProfile
                      ? _buildProfileComplete(context, user, theme)
                      : _buildProfilePrompt(context, theme);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('프로필 확인 오류'),
              ),

              const SizedBox(height: 24),

              // 로그아웃 (항상 보임!)
              AppCard(
                child: ListTile(
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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildLoginPrompt(context),
      ),
    );
  }

  static Widget _buildLoginPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AppCard(
          child: Column(
            children: [
              Text(
                '로그인하면 내 정보를 확인할 수 있어요!',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, RouteConstants.login);
                },
                child: const Text('Google 로그인'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildProfilePrompt(BuildContext context, ThemeData theme) {
    return AppCard(
      child: Column(
        children: [
          Text(
            '프로필을 등록하면 커뮤니티에 참여할 수 있어요!',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, RouteConstants.profileRegister);
            },
            child: const Text('프로필 등록'),
          ),
        ],
      ),
    );
  }

  static Widget _buildProfileComplete(BuildContext context, User user, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? '이름 없음',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? '이메일 없음',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        AppCard(
          onTap: () => Navigator.pushNamed(context, RouteConstants.pointCalendar),
          child: ListTile(
            leading: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
            title: const Text('포인트 달력'),
            subtitle: const Text('날짜별 포인트 내역 확인'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
      ],
    );
  }
}