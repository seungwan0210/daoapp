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
import 'package:daoapp/l10n/app_localizations.dart'; // 🔥 추가

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

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isEmailLoading = false;

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
    final s = AppLocalizations.of(context)!;
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, RouteConstants.splash);
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.login_fail_apple}: ${e.message ?? e.code.toString()}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.login_fail_apple} (${e.toString()})'),
          ),
        );
      }
    }
  }

  Future<void> _signInWithEmail() async {
    final s = AppLocalizations.of(context)!;
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
      // 💡 상세 에러 메시지는 프로젝트 정책에 따라 추가 키값을 정의하거나 e.message를 활용할 수 있습니다.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login Failed')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error')),
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
    final s = AppLocalizations.of(context)!; // 🔥 l10n 객체

    return Scaffold(
      backgroundColor: const Color(0xFF06142A),
      body: Stack(
        children: [
          Image.asset(
            'assets/images/login_background.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
            filterQuality: FilterQuality.high,
          ),

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

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGlowingLogo(),
                  const SizedBox(height: 24),
                  Text(
                    s.login_slogan, // 🔥 다국어 적용
                    style: const TextStyle(
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
                          Text(
                            s.login_google, // 🔥 다국어 적용
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (Platform.isIOS) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 280,
                      child: SignInWithAppleButton(
                        onPressed: _signInWithApple,
                        style: SignInWithAppleButtonStyle.white,
                        // 💡 버튼 텍스트는 라이브러리가 시스템 언어에 맞춰 자동 생성하거나 
                        // 아래처럼 커스텀 텍스트를 사용할 수 있습니다.
                        text: s.login_apple,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAdminLogin = !_showAdminLogin;
                      });
                    },
                    icon: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white70,
                      size: 18,
                    ),
                    label: Text(
                      s.login_admin_toggle, // 🔥 다국어 적용
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

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
                                      s.login_admin_info, // 🔥 다국어 적용
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
                                  labelText: s.login_email, // 🔥 다국어 적용
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
                                    return s.login_error_email_empty; // 🔥 다국어 적용
                                  }
                                  if (!value.contains('@')) {
                                    return s.login_error_email_format; // 🔥 다국어 적용
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
                                  labelText: s.login_password, // 🔥 다국어 적용
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
                                    return s.login_error_password_empty; // 🔥 다국어 적용
                                  }
                                  if (value.length < 6) {
                                    return s.login_error_password_length; // 🔥 다국어 적용
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
                                      : Text(
                                    s.login_email_btn, // 🔥 다국어 적용
                                    style: const TextStyle(
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

          Positioned(
            top: 60,
            right: 24,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, RouteConstants.main);
              },
              child: Text(
                s.login_skip, // 🔥 다국어 적용
                style: const TextStyle(
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
        final t = _starController.value;
        final pulse = 0.96 + 0.04 * (sin(t * 2 * pi) + 1) / 2;
        final glowA = 0.22 + 0.14 * (sin(t * 2 * pi) + 1) / 2;
        final glowB = 0.16 + 0.12 * (sin(t * 2 * pi + 1.3) + 1) / 2;

        return Transform.scale(
          scale: pulse,
          child: Stack(
            alignment: Alignment.center,
            children: [
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
              Image.asset(
                'assets/images/ic_launcher_foreground.png',
                width: 132,
                height: 132,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
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