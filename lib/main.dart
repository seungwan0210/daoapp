// lib/main.dart
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/core/theme/app_theme.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:intl/date_symbol_data_local.dart'; // 추가

// 공통
import 'package:daoapp/presentation/screens/splash_screen.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';
import 'package:daoapp/presentation/screens/login/login_screen.dart';

// 유저
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/screens/community/community_home_screen.dart';
import 'package:daoapp/presentation/screens/user/point_calendar_screen.dart';
import 'package:daoapp/presentation/screens/user/profile_register_screen.dart';
import 'package:daoapp/presentation/screens/user/my_page_screen.dart';
import 'package:daoapp/presentation/screens/user/notice_list_screen.dart';
import 'package:daoapp/presentation/screens/user/member_list_screen.dart';
import 'package:daoapp/presentation/screens/user/guestbook_screen.dart';
import 'package:daoapp/presentation/screens/user/report_form_screen.dart';

// 마이로그 (신규 추가!)
import 'package:daoapp/presentation/screens/user/my_log/my_log_home_screen.dart'; // 마이로그 홈

// 관리자
import 'package:daoapp/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:daoapp/presentation/screens/admin/point_award_screen.dart';
import 'package:daoapp/presentation/screens/admin/point_award_list_screen.dart';
import 'package:daoapp/presentation/screens/admin/event_create_screen.dart';
import 'package:daoapp/presentation/screens/admin/event_list_screen.dart';
import 'package:daoapp/presentation/screens/admin/event_edit_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/notice_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/news_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/sponsor_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/member_register_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/competition_photos_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/admin_report_list_screen.dart';
import 'package:daoapp/presentation/screens/admin/admin_member_list_screen.dart';

// 서클
import 'package:daoapp/presentation/screens/community/circle/post_write_screen.dart';
import 'package:daoapp/presentation/screens/community/circle/circle_screen.dart';

// 체크아웃
import 'package:daoapp/presentation/screens/community/checkout/checkout_home_screen.dart';
import 'package:daoapp/presentation/screens/community/checkout/calculator/checkout_calculator_screen.dart';
import 'package:daoapp/presentation/screens/community/checkout/practice/checkout_practice_screen.dart';
import 'package:daoapp/presentation/screens/community/checkout/practice/checkout_result_screen.dart';
import 'package:daoapp/presentation/screens/community/checkout/practice/checkout_ranking_screen.dart';
import 'package:daoapp/presentation/screens/community/checkout/practice/checkout_my_history_screen.dart';
import 'package:daoapp/presentation/screens/community/checkout/practice/checkout_practice_home_screen.dart';

// 아레나 (토너먼트)
import 'package:daoapp/presentation/screens/community/arena/arena_home_screen.dart';
import 'package:daoapp/presentation/screens/community/arena/tournament_create_screen.dart';
import 'package:daoapp/presentation/screens/community/arena/tournament_detail_screen.dart';
import 'package:daoapp/presentation/screens/community/arena/tournament_entry_form_screen.dart';
import 'package:daoapp/presentation/screens/community/arena/tournament_participant_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('ko_KR', null); // ← 이거 추가!!
  setupDependencies();

  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      OnlineStatusManager.start(user);
    } else {
      OnlineStatusManager.stop();
    }
  });

  runApp(const ProviderScope(child: DaoApp()));
}

class OnlineStatusManager {
  static Timer? _timer;
  static User? _currentUser;

  static void _update() {
    if (_currentUser == null) return;

    FirebaseFirestore.instance
        .collection('online_users')
        .doc(_currentUser!.uid)
        .set({
      'uid': _currentUser!.uid,
      'name': _currentUser!.displayName ?? '이름 없음',
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true))
        .catchError((e) => debugPrint('Online status update error: $e'));
  }

  static void start(User user) {
    if (_currentUser?.uid == user.uid) return;
    _currentUser = user;
    _timer?.cancel();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => _update());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _currentUser = null;
  }
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
        RouteConstants.splash: (_) => const SplashScreen(),
        RouteConstants.login: (_) => const LoginScreen(),
        RouteConstants.main: (_) => const MainScreen(),

        // 유저
        RouteConstants.ranking: (_) => const RankingScreenBody(),
        RouteConstants.calendar: (_) => const CalendarScreenBody(),
        RouteConstants.community: (_) => const CommunityHomeScreen(),
        RouteConstants.myPage: (_) => const MyPageScreenBody(),
        RouteConstants.profileRegister: (_) => const ProfileRegisterScreen(),
        RouteConstants.pointCalendar: (_) => const PointCalendarScreen(),
        RouteConstants.noticeList: (_) => const NoticeListScreen(),
        RouteConstants.memberList: (_) => const MemberListScreen(),
        RouteConstants.report: (_) => const ReportFormScreen(),
        RouteConstants.adminReportList: (_) => const AdminReportListScreen(),

        // 마이로그 (신규 추가!)
        RouteConstants.myLogHome: (_) => const MyLogHomeScreen(), // 마이로그 홈

        // 관리자
        RouteConstants.adminDashboard: (_) => const AdminDashboardScreen(),
        RouteConstants.pointAward: (_) => const PointAwardScreen(),
        RouteConstants.pointAwardList: (_) => const PointAwardListScreen(),
        RouteConstants.eventCreate: (_) => const EventCreateScreen(),
        RouteConstants.eventList: (_) => const EventListScreen(),
        RouteConstants.noticeForm: (_) => const NoticeFormScreen(),
        RouteConstants.newsForm: (_) => const NewsFormScreen(),
        RouteConstants.sponsorForm: (_) => const SponsorFormScreen(),
        RouteConstants.memberRegister: (_) => const MemberRegisterScreen(),
        RouteConstants.competitionPhotosForm: (_) => const CompetitionPhotosFormScreen(),
        RouteConstants.adminMemberList: (_) => const AdminMemberListScreen(),

        // 서클
        RouteConstants.postWrite: (_) => PostWriteScreen(),
        RouteConstants.circle: (_) => const CircleScreen(),

        // 체크아웃
        RouteConstants.checkoutHome: (_) => const CheckoutHomeScreen(),
        RouteConstants.checkoutCalculator: (_) => CheckoutCalculatorScreen(),
        RouteConstants.checkoutPractice: (_) => const CheckoutPracticeHomeScreen(),
        RouteConstants.checkoutPracticePlay: (_) => const CheckoutPracticeScreen(),
        RouteConstants.checkoutResult: (_) => const CheckoutResultScreen(),
        RouteConstants.checkoutRanking: (_) => const CheckoutRankingScreen(),
        RouteConstants.checkoutMyHistory: (_) => const CheckoutMyHistoryScreen(),

        // 아레나 토너먼트
        RouteConstants.arenaHome: (_) => const ArenaHomeScreen(),
        RouteConstants.tournamentCreate: (_) => const TournamentCreateScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == RouteConstants.guestbook) {
          final userId = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => GuestbookScreen(userId: userId));
        }

        if (settings.name == RouteConstants.eventEdit) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => EventEditScreen(
              docId: args['docId'] as String,
              initialData: args['initialData'] as Map<String, dynamic>,
            ),
          );
        }

        // 토너먼트 상세
        if (settings.name == RouteConstants.tournamentDetail) {
          final tournamentId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => TournamentDetailScreen(tournamentId: tournamentId),
          );
        }

        // 참가 신청 폼
        if (settings.name == RouteConstants.tournamentEntryForm) {
          final tournamentId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => TournamentEntryFormScreen(tournamentId: tournamentId),
          );
        }

        // 참가자 명단
        if (settings.name == RouteConstants.tournamentParticipantList) {
          final args = settings.arguments as Map<String, dynamic>;
          final tournamentId = args['tournamentId'] as String;
          final tournamentTitle = args['tournamentTitle'] as String? ?? '참가자 명단';
          return MaterialPageRoute(
            builder: (_) => TournamentParticipantListScreen(
              tournamentId: tournamentId,
              tournamentTitle: tournamentTitle,
            ),
          );
        }

        return null;
      },
      onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }
}