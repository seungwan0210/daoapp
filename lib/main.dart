// lib/main.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/core/theme/app_theme.dart';
import 'package:daoapp/core/constants/route_constants.dart';

// === Screens Import (새 구조 완벽 반영) ===
import 'package:daoapp/presentation/screens/splash_screen.dart';
import 'package:daoapp/presentation/screens/login/login_screen.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';

// 홈
import 'package:daoapp/presentation/screens/home/home_screen.dart';

// 트레이닝
import 'package:daoapp/presentation/screens/training/training_home_screen.dart';
import 'package:daoapp/presentation/screens/training/calculator/training_calculator_screen.dart';
import 'package:daoapp/presentation/screens/training/checkout/checkout_practice_home_screen.dart';
import 'package:daoapp/presentation/screens/training/checkout/checkout_practice_screen.dart';
import 'package:daoapp/presentation/screens/training/checkout/checkout_result_screen.dart';
import 'package:daoapp/presentation/screens/training/checkout/checkout_ranking_screen.dart';
import 'package:daoapp/presentation/screens/training/checkout/checkout_my_history_screen.dart';

// 🔹 트레이닝 프로필/레벨 테스트 스크린
import 'package:daoapp/presentation/screens/training/training_rating_input_screen.dart';
import 'package:daoapp/presentation/screens/training/board_level_test_screen.dart';

// 🔹 트레이닝 히스토리
import 'package:daoapp/presentation/screens/training/history/training_history_screen.dart';

// 아레나
import 'package:daoapp/presentation/screens/arena/arena_home_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_ranking_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_schedule_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_point_calendar_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/member_list_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_create_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_detail_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_entry_form_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_participant_list_screen.dart';

// 커뮤니티
import 'package:daoapp/presentation/screens/community/community_home_screen.dart';
import 'package:daoapp/presentation/screens/community/circle/circle_screen.dart';
import 'package:daoapp/presentation/screens/community/circle/post_write_screen.dart';

// 마이페이지
import 'package:daoapp/presentation/screens/my_page/my_page_screen.dart';
import 'package:daoapp/presentation/screens/my_page/profile_register_screen.dart';
import 'package:daoapp/presentation/screens/my_page/notice_list_screen.dart';
import 'package:daoapp/presentation/screens/my_page/report_form_screen.dart';
import 'package:daoapp/presentation/screens/my_page/guestbook_screen.dart';
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_home_screen.dart';

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
import 'package:daoapp/presentation/screens/admin/selection_players_admin_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/selection_players_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    // androidProvider: AndroidProvider.debug,
  );

  await initializeDateFormatting('ko_KR', null);
  setupDependencies();

  FirebaseAuth.instance.authStateChanges().listen((user) {
    user != null ? OnlineStatusManager.start(user) : OnlineStatusManager.stop();
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
        .catchError((e) => debugPrint('Online status error: $e'));
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

        // 홈
        RouteConstants.home: (_) => const HomeScreen(),

        // 트레이닝
        RouteConstants.trainingHome: (_) => const TrainingHomeScreen(),
        RouteConstants.checkoutPracticeHome: (_) =>
        const CheckoutPracticeHomeScreen(),
        RouteConstants.checkoutPracticePlay: (_) =>
        const CheckoutPracticeScreen(),
        RouteConstants.checkoutResult: (_) => const CheckoutResultScreen(),
        RouteConstants.checkoutRanking: (_) =>
        const CheckoutRankingScreen(),
        RouteConstants.checkoutMyHistory: (_) =>
        const CheckoutMyHistoryScreen(),
        RouteConstants.checkoutCalculator: (_) =>
        const TrainingCalculatorScreen(),

        // 🔹 트레이닝 프로필 관련 라우트
        RouteConstants.trainingRatingInput: (_) =>
        const TrainingRatingInputScreen(),
        RouteConstants.boardLevelTest: (_) =>
        const BoardLevelTestScreen(),

        // 🔹 트레이닝 히스토리
        RouteConstants.trainingHistory: (_) =>
        const TrainingHistoryScreen(),

        // 아레나
        RouteConstants.arenaHome: (_) => const ArenaHomeScreen(),
        RouteConstants.steelLeagueRanking: (_) =>
        const SteelLeagueRankingScreen(),
        RouteConstants.steelLeagueSchedule: (_) =>
        const SteelLeagueScheduleScreen(),
        RouteConstants.steelLeaguePointCalendar: (_) =>
        const SteelLeaguePointCalendarScreen(),
        RouteConstants.steelLeagueMembers: (_) =>
        const MemberListScreen(),
        RouteConstants.tournamentCreate: (_) =>
        const TournamentCreateScreen(),

        // 커뮤니티
        RouteConstants.community: (_) => const CommunityHomeScreen(),
        RouteConstants.circle: (_) => const CircleScreen(),
        RouteConstants.postWrite: (_) => const PostWriteScreen(),

        // 마이페이지
        RouteConstants.myPage: (_) => const MyPageScreen(),
        RouteConstants.profileRegister: (_) =>
        const ProfileRegisterScreen(),
        RouteConstants.noticeList: (_) => const NoticeListScreen(),
        RouteConstants.report: (_) => const ReportFormScreen(),
        RouteConstants.myLogHome: (_) => const MyLogHomeScreen(),

        // 관리자
        RouteConstants.adminDashboard: (_) =>
        const AdminDashboardScreen(),
        RouteConstants.pointAward: (_) => const PointAwardScreen(),
        RouteConstants.pointAwardList: (_) =>
        const PointAwardListScreen(),
        RouteConstants.eventCreate: (_) =>
        const EventCreateScreen(),
        RouteConstants.eventList: (_) => const EventListScreen(),
        RouteConstants.noticeForm: (_) => const NoticeFormScreen(),
        RouteConstants.newsForm: (_) => const NewsFormScreen(),
        RouteConstants.sponsorForm: (_) => const SponsorFormScreen(),
        RouteConstants.memberRegister: (_) =>
        const MemberRegisterScreen(),
        RouteConstants.competitionPhotosForm: (_) =>
        const CompetitionPhotosFormScreen(),
        RouteConstants.adminReportList: (_) =>
        const AdminReportListScreen(),
        RouteConstants.adminMemberList: (_) =>
        const AdminMemberListScreen(),
        // 🔹 여기 추가
        RouteConstants.selectionPlayersAdmin: (_) =>
        const SelectionPlayersAdminScreen(),

        // (선택) 스틸리그 선발 공개 화면도 라우트로 쓰고 싶으면
        RouteConstants.steelLeagueSelection: (_) =>
        const SelectionPlayersScreen(),
      },
      onGenerateRoute: (settings) {
        // 방명록
        if (settings.name == RouteConstants.guestbook) {
          final userId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => GuestbookScreen(userId: userId),
          );
        }

        // 이벤트 수정
        if (settings.name == RouteConstants.eventEdit) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => EventEditScreen(
              docId: args['docId'] as String,
              initialData:
              args['initialData'] as Map<String, dynamic>,
            ),
          );
        }

        // 토너먼트 상세
        if (settings.name == RouteConstants.tournamentDetail) {
          final id = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) =>
                TournamentDetailScreen(tournamentId: id),
          );
        }

        // 참가 신청
        if (settings.name == RouteConstants.tournamentEntryForm) {
          final id = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) =>
                TournamentEntryFormScreen(tournamentId: id),
          );
        }

        // 참가자 명단
        if (settings.name ==
            RouteConstants.tournamentParticipantList) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => TournamentParticipantListScreen(
              tournamentId: args['tournamentId'] as String,
              tournamentTitle: args['tournamentTitle']
              as String? ??
                  '참가자 명단',
            ),
          );
        }

        return null;
      },
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }
}
