// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/screens/splash_screen.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/screens/login/login_screen.dart';
import 'package:daoapp/core/theme/app_theme.dart';
import 'package:daoapp/core/constants/route_constants.dart'; // 수정
import 'package:daoapp/presentation/screens/community/community_screen.dart'; // 추가
import 'package:daoapp/presentation/screens/user/point_calendar_screen.dart';
import 'package:daoapp/presentation/screens/user/profile_register_screen.dart'; // 추가
import 'package:daoapp/presentation/screens/admin/admin_dashboard_screen.dart'; // 추가

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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteConstants.splash,
      routes: {
        RouteConstants.splash: (context) => const SplashScreen(),
        RouteConstants.login: (context) => const LoginScreen(),
        RouteConstants.main: (context) => const MainScreen(),
        RouteConstants.ranking: (context) => const RankingScreen(),
        RouteConstants.calendar: (context) => const CalendarScreen(),
        RouteConstants.community: (context) => const CommunityScreen(),
        RouteConstants.profileRegister: (context) => const ProfileRegisterScreen(),
        RouteConstants.pointCalendar: (context) => const PointCalendarScreen(),
        RouteConstants.adminDashboard: (context) => const AdminDashboardScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      },
    );
  }
}