// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/screens/main_screen.dart'; // 추가!

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
      home: const MainScreen(), // SplashScreen → MainScreen으로 변경!
      debugShowCheckedModeBanner: false,
    );
  }
}