// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/core/theme/app_theme.dart';
import 'package:daoapp/core/constants/route_constants.dart';

// 스크린 import
import 'package:daoapp/presentation/screens/splash_screen.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/screens/login/login_screen.dart';
import 'package:daoapp/presentation/screens/community/community_screen.dart';
import 'package:daoapp/presentation/screens/user/point_calendar_screen.dart';
import 'package:daoapp/presentation/screens/user/profile_register_screen.dart';
import 'package:daoapp/presentation/screens/user/my_page_screen.dart';
import 'package:daoapp/presentation/screens/admin/admin_dashboard_screen.dart';

// 관리자 스크린 import
import 'package:daoapp/presentation/screens/admin/point_award_screen.dart';
import 'package:daoapp/presentation/screens/admin/point_award_list_screen.dart';
import 'package:daoapp/presentation/screens/admin/event_create_screen.dart';
import 'package:daoapp/presentation/screens/admin/event_list_screen.dart';
import 'package:daoapp/presentation/screens/admin/event_edit_screen.dart'; // 추가
import 'package:daoapp/presentation/screens/admin/forms/notice_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/news_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/sponsor_form_screen.dart';

// 정회원 등록/명단 스크린 import
import 'package:daoapp/presentation/screens/admin/member_register_screen.dart';
import 'package:daoapp/presentation/screens/user/member_list_screen.dart';

// 방명록 스크린 import
import 'package:daoapp/presentation/screens/user/guestbook_screen.dart';

// 새로 추가: 공지 리스트 + 대회 사진 폼
import 'package:daoapp/presentation/screens/user/notice_list_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/competition_photos_form_screen.dart';

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
        // === 정적 라우트 ===
        RouteConstants.splash: (_) => const SplashScreen(),
        RouteConstants.login: (_) => const LoginScreen(),
        RouteConstants.main: (_) => const MainScreen(),
        RouteConstants.ranking: (_) => const RankingScreenBody(),
        RouteConstants.calendar: (_) => const CalendarScreenBody(),
        RouteConstants.community: (_) => const CommunityScreenBody(),
        RouteConstants.myPage: (_) => const MyPageScreenBody(),
        RouteConstants.profileRegister: (_) => const ProfileRegisterScreen(),
        RouteConstants.pointCalendar: (_) => const PointCalendarScreen(),
        RouteConstants.adminDashboard: (_) => const AdminDashboardScreen(),
        RouteConstants.pointAward: (_) => const PointAwardScreen(),
        RouteConstants.pointAwardList: (_) => const PointAwardListScreen(),
        RouteConstants.eventCreate: (_) => const EventCreateScreen(),
        RouteConstants.eventList: (_) => const EventListScreen(),
        RouteConstants.eventEdit: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return EventEditScreen(
            docId: args['docId'] as String,
            initialData: args['initialData'] as Map<String, dynamic>,
          );
        }, // 추가: 동적 생성
        RouteConstants.noticeForm: (_) => const NoticeFormScreen(),
        RouteConstants.newsForm: (_) => const NewsFormScreen(),
        RouteConstants.sponsorForm: (_) => const SponsorFormScreen(),
        RouteConstants.memberRegister: (_) => const MemberRegisterScreen(),
        RouteConstants.memberList: (_) => const MemberListScreen(),
      },
      onGenerateRoute: (settings) {
        // === 동적 라우트 ===
        if (settings.name == RouteConstants.guestbook) {
          final userId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => GuestbookScreen(userId: userId),
            settings: settings,
          );
        }

        if (settings.name == RouteConstants.noticeList) {
          return MaterialPageRoute(
            builder: (_) => const NoticeListScreen(),
            settings: settings,
          );
        }

        if (settings.name == RouteConstants.competitionPhotosForm) {
          return MaterialPageRoute(
            builder: (_) => const CompetitionPhotosFormScreen(),
            settings: settings,
          );
        }

        return null;
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