// lib/presentation/screens/user/my_page_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/screens/login/login_screen.dart';
import 'package:daoapp/presentation/screens/user/point_calendar_screen.dart'; // 변경!
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MY PAGE'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user == null) ...[
              AppCard(
                child: Column(
                  children: [
                    Text(
                      '로그인하면 내 정보를 확인할 수 있어요!',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Google 로그인'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 프로필
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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? '이메일 없음',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 포인트 달력 버튼
              AppCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PointCalendarScreen()),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_month, color: Colors.blue),
                  title: const Text('포인트 달력'),
                  subtitle: const Text('날짜별 포인트 내역 확인'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
              const SizedBox(height: 16),

              // 로그아웃
              AppCard(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('로그아웃'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}