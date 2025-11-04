// lib/presentation/screens/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/core/constants/route_constants.dart'; // 추가!

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _starController;
  final List<Offset> _starPositions = [];
  final List<double> _starSizes = [];

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    final random = Random();
    for (int i = 0; i < 25; i++) {
      _starPositions.add(Offset(
        random.nextDouble() * 400,
        random.nextDouble() * 800,
      ));
      _starSizes.add(2 + random.nextDouble() * 3);
    }
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 너가 만든 로그인 배경 이미지
          Image.asset(
            'assets/images/login_background.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // 반짝이는 별들 (애니메이션)
          ..._starPositions.asMap().entries.map((entry) {
            final index = entry.key;
            final pos = entry.value;
            final size = _starSizes[index];
            return AnimatedBuilder(
              animation: _starController,
              builder: (_, __) {
                final opacity = 0.3 + 0.7 * (sin(_starController.value * 2 * pi + index) + 1) / 2;
                return Positioned(
                  left: pos.dx,
                  top: pos.dy,
                  child: Opacity(
                    opacity: opacity,
                    child: Icon(Icons.star, color: Colors.white, size: size),
                  ),
                );
              },
            );
          }),

          // 중앙: 로고 + 슬로건 + Google 로그인
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGlowingLogo(),
                const SizedBox(height: 24),
                const Text(
                  'Every Point Is Your Story',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 280,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
                      if (user != null && context.mounted) {
                        // 기존: MainScreen 직행 → X
                        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));

                        // 수정: SplashScreen으로 이동 → 상태 감지 시작
                        Navigator.pushReplacementNamed(context, RouteConstants.splash);
                      }
                    },
                    icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
                    label: const Text(
                      'Google로 로그인',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 오른쪽 상단: 건너뛰기
          Positioned(
            top: 60,
            right: 24,
            child: TextButton(
              onPressed: () {
                // 건너뛰기 → SplashScreen으로
                Navigator.pushReplacementNamed(context, RouteConstants.splash);
              },
              child: const Text(
                '건너뛰기',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 50,
            spreadRadius: 20,
          ),
          BoxShadow(
            color: const Color(0xFF00D4FF).withOpacity(0.6),
            blurRadius: 90,
            spreadRadius: 40,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo_dao.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}