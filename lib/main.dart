// lib/main.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

// ✅ kReleaseMode 사용
import 'package:flutter/foundation.dart';

import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/core/theme/app_theme.dart';
import 'package:daoapp/core/constants/route_constants.dart';

// ✅ AdMob(광고) SDK
import 'package:google_mobile_ads/google_mobile_ads.dart';

// === Screens Import (새 구조 완벽 반영) ===
import 'package:daoapp/presentation/screens/splash_screen.dart';
import 'package:daoapp/presentation/screens/login/login_screen.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';

// 홈
import 'package:daoapp/presentation/screens/home/home_screen.dart';

// 트레이닝
import 'package:daoapp/presentation/screens/training/training_home_screen.dart';
import 'package:daoapp/presentation/screens/training/calculator/training_calculator_screen.dart';

// 🔥 피니쉬 루트 연습 (기존 checkout 연습 → finish_route)
import 'package:daoapp/presentation/screens/training/finish_route/finish_route_home_screen.dart';
import 'package:daoapp/presentation/screens/training/finish_route/finish_route_practice_screen.dart';
import 'package:daoapp/presentation/screens/training/finish_route/finish_route_result_screen.dart';
import 'package:daoapp/presentation/screens/training/finish_route/finish_route_ranking_screen.dart';
import 'package:daoapp/presentation/screens/training/finish_route/finish_route_my_history_screen.dart';

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

// -----------------------------------------------------------
// ⚠️ [긴급] 애드몹 정지(29일) 대응을 위한 설정
// -----------------------------------------------------------
// 정지가 풀린 후(2월 중순 이후) 이 값을 false로 바꾸고,
// 아래 MobileAds.instance.initialize() 로직을 복구하세요.
const bool kAdMobSuspended = true;

// 기존 디버그 설정 (무시됨)
const bool kEnableAdsInDebug = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck, // 🔥 iOS용 추가
  );

  await initializeDateFormatting('ko_KR', null);
  setupDependencies();

  // ✅ AdMob (광고) SDK 초기화 로직 수정
  // 정지 기간 동안은 초기화를 아예 수행하지 않음 (안전 장치)
  if (!kAdMobSuspended) {
    if (kReleaseMode || kEnableAdsInDebug) {
      await MobileAds.instance.initialize();
      debugPrint("🚀 AdMob Initialized");
    }
  } else {
    debugPrint("🚫 AdMob Suspended: 광고 기능이 비활성화되었습니다.");
  }

  // ✅ 온라인 상태 관리
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
        .set(
      {
        'uid': _currentUser!.uid,
        'name': _currentUser!.displayName ?? '이름 없음',
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    ).catchError(
          (e) => debugPrint('Online status error: $e'),
    );
  }

  static void start(User user) {
    if (_currentUser?.uid == user.uid) return;

    _currentUser = user;
    _timer?.cancel();

    _update(); // 즉시 한 번 저장
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
        // 공통
        RouteConstants.splash: (_) => const SplashScreen(),
        RouteConstants.login: (_) => const LoginScreen(),
        RouteConstants.main: (_) => const MainScreen(),

        // 홈
        RouteConstants.home: (_) => const HomeScreen(),

        // 트레이닝 메인
        RouteConstants.trainingHome: (_) => const TrainingHomeScreen(),

        // 🔥 피니쉬 루트 연습 (Finish Route)
        RouteConstants.finishRouteHome: (_) =>
        const FinishRouteHomeScreen(),
        RouteConstants.finishRoutePractice: (_) =>
        const FinishRoutePracticeScreen(),
        RouteConstants.finishRouteResult: (_) =>
        const FinishRouteResultScreen(),
        RouteConstants.finishRouteRanking: (_) =>
        const FinishRouteRankingScreen(),
        RouteConstants.finishRouteMyHistory: (_) =>
        const FinishRouteMyHistoryScreen(),

        // 체크아웃 계산기
        RouteConstants.checkoutCalculator: (_) =>
        const CheckoutCalculatorScreen(),

        // 🔹 트레이닝 프로필 관련
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
        RouteConstants.eventCreate: (_) => const EventCreateScreen(),
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
        RouteConstants.selectionPlayersAdmin: (_) =>
        const SelectionPlayersAdminScreen(),

        // 스틸리그 선발 공개 화면
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
              tournamentTitle:
              args['tournamentTitle'] as String? ?? '참가자 명단',
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