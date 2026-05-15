// lib/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔥 추가

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  int _retryCount = 0;
  static const int _maxRetries = 10; // 최대 10초 대기

  @override
  void initState() {
    super.initState();
    // 첫 프레임 후 즉시 상태 확인 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  void _checkAuthState() async {
    final authState = ref.read(authStateProvider);
    final s = AppLocalizations.of(context)!; // 🔥 110n 객체 가져오기

    authState.when(
      data: (user) async {
        if (user == null) {
          Navigator.pushReplacementNamed(context, RouteConstants.login);
        } else {
          // 🔥 정지 여부 확인
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists && userDoc.data()?['isBanned'] == true) {
            await FirebaseAuth.instance.signOut(); // 강제 로그아웃
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.ban_msg_restricted)) // 🔥 다국어 적용
              );
              Navigator.pushReplacementNamed(context, RouteConstants.login);
            }
          } else {
            Navigator.pushReplacementNamed(context, RouteConstants.main);
          }
        }
      },
      loading: () {
        // 로딩 중 → 1초 후 재시도
        if (_retryCount < _maxRetries) {
          _retryCount++;
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _checkAuthState();
            }
          });
        } else {
          // 타임아웃 → 강제 로그인 화면
          if (mounted) {
            Navigator.pushReplacementNamed(context, RouteConstants.login);
          }
        }
      },
      error: (_, __) {
        // 에러 → 로그인 화면
        Navigator.pushReplacementNamed(context, RouteConstants.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash_portrait.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
          ),
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.white30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}