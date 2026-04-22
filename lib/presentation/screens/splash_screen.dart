// lib/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 추가 필요
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 추가 필요
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/core/constants/route_constants.dart';

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
    final authState = ref.read(authStateProvider); // watch 대신 read 권장 (initState 시점)

    authState.when(
      data: (user) async {
        if (user == null) {
          Navigator.pushReplacementNamed(context, RouteConstants.login);
        } else {
          // 🔥 [추가] 정지 여부 확인
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists && userDoc.data()?['isBanned'] == true) {
            await FirebaseAuth.instance.signOut(); // 강제 로그아웃
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('운영 정책에 의해 이용이 제한된 계정입니다.'))
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