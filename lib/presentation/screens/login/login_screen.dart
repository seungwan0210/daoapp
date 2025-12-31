// lib/presentation/screens/login/login_screen.dart
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  // =========================
  // 🔐 Apple 로그인용 nonce 유틸
  // =========================
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signInWithApple() async {
    try {
      // 0) Firebase용 nonce 생성
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // 1) 애플 계정 선택 / Face ID 인증 (nonce 포함)
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // 2) Firebase Auth용 credential 생성 (rawNonce 넣기 중요!)
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      // 3) Firebase 로그인
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, RouteConstants.splash);
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      // 유저가 취소했으면 조용히 무시
      if (e.code == AuthorizationErrorCode.canceled) {
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Apple 로그인 실패: ${e.message ?? e.code.toString()}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple 로그인 중 오류가 발생했습니다. (${e.toString()})'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 이미지 로딩 순간 흰 화면 번쩍임 방지
      backgroundColor: const Color(0xFF06142A),
      body: Stack(
        children: [
          // 배경 이미지
          Image.asset(
            'assets/images/login_background.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            filterQuality: FilterQuality.high,
          ),

          // 반짝이는 별들
          ..._starPositions.asMap().entries.map((entry) {
            final index = entry.key;
            final pos = entry.value;
            final size = _starSizes[index];
            return AnimatedBuilder(
              animation: _starController,
              builder: (_, __) {
                final opacity = 0.3 +
                    0.7 *
                        (sin(_starController.value * 2 * pi + index) + 1) /
                        2;
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

          // 중앙: 로고 + 슬로건 + 로그인 버튼들
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

                // 🔹 Google 로그인
                SizedBox(
                  width: 280,
                  child: ElevatedButton(
                    onPressed: () async {
                      final user = await ref
                          .read(authRepositoryProvider)
                          .signInWithGoogle();
                      if (user != null && context.mounted) {
                        Navigator.pushReplacementNamed(
                            context, RouteConstants.splash);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
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
                              return const Icon(Icons.g_mobiledata,
                                  size: 20, color: Colors.red);
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

                // 🔹 iOS일 때만 Apple 로그인 표시
                if (Platform.isIOS) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 280,
                    child: SignInWithAppleButton(
                      onPressed: _signInWithApple,
                      style: SignInWithAppleButtonStyle.white, // 흰색 버튼
                    ),
                  ),
                ],
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

  /// ✅ 네온 글로우 로고
  Widget _buildGlowingLogo() {
    return AnimatedBuilder(
      animation: _starController,
      builder: (context, _) {
        final t = _starController.value; // 0..1 반복
        final pulse = 0.96 + 0.04 * (sin(t * 2 * pi) + 1) / 2; // 0.96~1.00
        final glowA = 0.22 + 0.14 * (sin(t * 2 * pi) + 1) / 2; // 민트
        final glowB = 0.16 + 0.12 * (sin(t * 2 * pi + 1.3) + 1) / 2; // 블루

        return Transform.scale(
          scale: pulse,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 바깥 네온 헤일로(민트→블루)
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2FE6FF).withOpacity(glowA),
                      const Color(0xFF1B6CFF).withOpacity(glowB),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),

              // 부드러운 글로우/깊이감
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2FE6FF).withOpacity(glowA),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: const Color(0xFF1B6CFF).withOpacity(glowB),
                      blurRadius: 80,
                      spreadRadius: 14,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.30),
                      blurRadius: 28,
                      spreadRadius: -10,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
              ),

              // 유리 느낌 카드
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                    width: 1,
                  ),
                ),
              ),

              // 투명 로고
              Image.asset(
                'assets/images/ic_launcher_foreground.png',
                width: 132,
                height: 132,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),

              // 작은 하이라이트 반짝임
              Positioned(
                top: 26,
                right: 32,
                child: Opacity(
                  opacity: 0.12 + 0.10 * (sin(t * 2 * pi + 0.7) + 1) / 2,
                  child: Container(
                    width: 26,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
