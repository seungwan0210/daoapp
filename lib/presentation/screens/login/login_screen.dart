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

  // ✅ 이메일 로그인용 컨트롤러 & 상태
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isEmailLoading = false;

  // ✅ 운영자 전용 로그인 섹션 토글
  bool _showAdminLogin = false;

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
    _emailController.dispose();
    _passwordController.dispose();
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

  // =========================
  // 🔐 이메일 로그인 (운영자/테스트용)
  // =========================
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEmailLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteConstants.splash);
    } on FirebaseAuthException catch (e) {
      String message = '이메일 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.';

      if (e.code == 'user-not-found') {
        message = '해당 이메일의 계정을 찾을 수 없습니다.';
      } else if (e.code == 'wrong-password') {
        message = '비밀번호가 올바르지 않습니다.';
      } else if (e.code == 'invalid-email') {
        message = '이메일 형식이 올바르지 않습니다.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEmailLoading = false);
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
                        (sin(_starController.value * 2 * pi + index) + 1) / 2;
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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

                  // ========================
                  // 🔹 Google 로그인
                  // ========================
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

                  // ========================
                  // 🍎 iOS일 때만 Apple 로그인
                  // ========================
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 280,
                      child: SignInWithAppleButton(
                        onPressed: _signInWithApple,
                        style: SignInWithAppleButtonStyle.white,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ========================
                  // ⚙️ 운영자 전용 로그인 토글
                  // ========================
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAdminLogin = !_showAdminLogin;
                      });
                    },
                    icon: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white70,
                      size: 18,
                    ),
                    label: Text(
                      '운영자 전용 로그인',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // ========================
                  // ✉️ 운영자 전용 이메일 로그인 카드
                  // ========================
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: !_showAdminLogin
                        ? const SizedBox.shrink()
                        : Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Form(
                        key: _formKey,
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '운영자 · 심사용 계정에만 사용하는 로그인 방식입니다.',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.75),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style:
                                const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: '이메일',
                                  labelStyle: TextStyle(
                                    color:
                                    Colors.white.withOpacity(0.8),
                                  ),
                                  hintText: 'test@daoapp.com',
                                  hintStyle: TextStyle(
                                    color:
                                    Colors.white.withOpacity(0.4),
                                  ),
                                  filled: true,
                                  fillColor:
                                  Colors.white.withOpacity(0.06),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2FE6FF),
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return '이메일을 입력해주세요.';
                                  }
                                  if (!value.contains('@')) {
                                    return '이메일 형식이 올바르지 않습니다.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style:
                                const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: '비밀번호',
                                  labelStyle: TextStyle(
                                    color:
                                    Colors.white.withOpacity(0.8),
                                  ),
                                  filled: true,
                                  fillColor:
                                  Colors.white.withOpacity(0.06),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2FE6FF),
                                      width: 1.4,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                        !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '비밀번호를 입력해주세요.';
                                  }
                                  if (value.length < 6) {
                                    return '비밀번호는 6자 이상이어야 합니다.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isEmailLoading
                                      ? null
                                      : () => _signInWithEmail(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF2FE6FF),
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isEmailLoading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                      AlwaysStoppedAnimation<
                                          Color>(
                                        Colors.black87,
                                      ),
                                    ),
                                  )
                                      : const Text(
                                    '이메일로 로그인',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
