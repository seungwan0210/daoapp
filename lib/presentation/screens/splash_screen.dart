// lib/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/screens/login/login_screen.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _navigateToNext();
    });
  }

  void _navigateToNext() {
    final authState = ref.read(authStateProvider);
    if (authState.value == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지 (꽉 채움!)
          Image.asset(
            'assets/images/splash_portrait.png',
            fit: BoxFit.cover,           // 꽉 채움 + 확대
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center, // 중앙 정렬
          ),

          // 로딩 (하단 중앙)
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