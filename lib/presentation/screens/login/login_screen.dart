// lib/presentation/screens/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고
              const Icon(
                Icons.sports_esports,
                size: 100,
                color: Color(0xFF00D4FF),
              ),
              const SizedBox(height: 20),

              // 앱 이름
              const Text(
                '스틸리그 포인트',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D4FF),
                ),
              ),
              const SizedBox(height: 60),

              // Google 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final user = await ref.read(authRepositoryProvider).signInWithGoogle();
                    if (user != null && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                      );
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                  label: const Text(
                    'Google로 로그인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 로그인 없이 둘러보기
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                    );
                  },
                  child: const Text(
                    '로그인 없이 둘러보기',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),

              // 테스트용 로그아웃 (나중에 삭제!)
              // if (kDebugMode)
              //   TextButton(
              //     onPressed: () async {
              //       await ref.read(authRepositoryProvider).signOut();
              //       if (context.mounted) {
              //         Navigator.pushReplacement(
              //           context,
              //           MaterialPageRoute(builder: (_) => const LoginScreen()),
              //         );
              //       }
              //     },
              //     child: const Text('로그아웃 (테스트용)', style: TextStyle(color: Colors.red)),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}