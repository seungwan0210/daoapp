// lib/presentation/screens/community/community_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  static Widget body() => const CommunityScreenBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommunityScreen.body();
  }
}

class CommunityScreenBody extends ConsumerWidget {
  const CommunityScreenBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final hasProfile = ref.watch(userHasProfileProvider);
    final theme = Theme.of(context);

    return SafeArea(
      top: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 비로그인
                    if (user == null) ...[
                      AppCard(
                        child: Column(
                          children: [
                            Text(
                              '로그인 후 커뮤니티에 참여하세요!',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, RouteConstants.login),
                              child: const Text('로그인'),
                            ),
                          ],
                        ),
                      ),
                    ]
                    // 프로필 미등록
                    else if (hasProfile.value == false) ...[
                      AppCard(
                        child: Column(
                          children: [
                            Text(
                              '프로필 등록 후 글을 작성할 수 있습니다!',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, RouteConstants.profileRegister),
                              child: const Text('프로필 등록'),
                            ),
                          ],
                        ),
                      ),
                    ]
                    // 프로필 등록 완료
                    else ...[
                        Text(
                          '커뮤니티 글 목록 (곧 구현 예정!)',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: diary_write_screen.dart로 이동
                          },
                          child: const Text('글쓰기'),
                        ),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}