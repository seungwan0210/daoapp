// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/screens/splash_screen.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  setupDependencies();
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
        '/main': (context) => const MainScreen(), // ← 여기서 모든 탭 관리
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      },
    );
  }
}