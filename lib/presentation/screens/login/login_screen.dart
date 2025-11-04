// lib/presentation/screens/login/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/core/constants/route_constants.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Image.asset(
            'assets/images/login_background.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // 반짝이는 별들
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
                // 완벽한 Google 로그인 버튼
                SizedBox(
                  width: 280,
                  child: ElevatedButton(
                    onPressed: () async {
                      final user = await ref.read(authRepositoryProvider).signInWithGoogle();
                      if (user != null && context.mounted) {
                        Navigator.pushReplacementNamed(context, RouteConstants.splash);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
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
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.g_mobiledata, size: 20, color: Colors.red);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Google로 로그인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 오른쪽 상단: 건너뛰기 → main
          Positioned(
            top: 60,
            right: 24,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, RouteConstants.main);
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