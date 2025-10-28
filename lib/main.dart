// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/screens/splash_screen.dart'; // 스플래시
import 'package:daoapp/presentation/screens/main_screen.dart'; // 메인
import 'package:daoapp/presentation/screens/user/user_home_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  setupDependencies(); // GetIt 초기화
  runApp(
    const ProviderScope(
      child: DaoApp(),
    ),
  );
}

class DaoApp extends StatelessWidget {
  const DaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAO App - Steel League',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/main': (context) => const MainScreen(), // 네비게이션 바 포함
        '/home': (context) => const UserHomeScreen(),
        '/event': (context) => const CalendarScreen(),
        '/ranking': (context) => const RankingScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      },
    );
  }
}