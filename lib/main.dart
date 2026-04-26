import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart'; // ✅ 딥링크 패키지

import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/core/theme/app_theme.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// === Screens Import ===
import 'package:daoapp/presentation/screens/splash_screen.dart';
import 'package:daoapp/presentation/screens/login/login_screen.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';
import 'package:daoapp/presentation/screens/home/home_screen.dart';
import 'package:daoapp/presentation/screens/training/training_home_screen.dart';
import 'package:daoapp/presentation/screens/training/calculator/training_calculator_screen.dart';
import 'package:daoapp/presentation/screens/training/training_rating_input_screen.dart';
import 'package:daoapp/presentation/screens/training/board_level_test_screen.dart';
import 'package:daoapp/presentation/screens/training/history/training_history_screen.dart';
import 'package:daoapp/presentation/screens/arena/arena_home_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_ranking_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_schedule_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_point_calendar_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/member_list_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_create_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_detail_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_entry_form_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournament_participant_list_screen.dart';
import 'package:daoapp/presentation/screens/community/community_home_screen.dart';
import 'package:daoapp/presentation/screens/community/circle/circle_screen.dart';
import 'package:daoapp/presentation/screens/community/circle/post_write_screen.dart';
import 'package:daoapp/presentation/screens/my_page/my_page_screen.dart';
import 'package:daoapp/presentation/screens/my_page/profile_register_screen.dart';
import 'package:daoapp/presentation/screens/my_page/notice_list_screen.dart';
import 'package:daoapp/presentation/screens/my_page/report_form_screen.dart';
import 'package:daoapp/presentation/screens/my_page/guestbook_screen.dart';
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_home_screen.dart';
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
import 'package:daoapp/presentation/screens/community/chat/chat_screen.dart';
import 'package:daoapp/presentation/screens/my_page/block_list_screen.dart';
import 'package:daoapp/presentation/screens/admin/admin_block_manage_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/admin_chat_config_screen.dart';
import 'package:daoapp/presentation/screens/admin/admin_hard_cleanup_screen.dart';

const bool kAdMobSuspended = false;
const bool kEnableAdsInDebug = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
    appleProvider: kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
  );
  await initializeDateFormatting('ko_KR', null);
  setupDependencies();

  if (!kAdMobSuspended) {
    if (kReleaseMode || kEnableAdsInDebug) {
      await MobileAds.instance.initialize();
      debugPrint("🚀 AdMob Initialized");
    }
  }

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
    FirebaseFirestore.instance.collection('online_users').doc(_currentUser!.uid).set({
      'uid': _currentUser!.uid,
      'name': _currentUser!.displayName ?? '이름 없음',
      'photoUrl': _currentUser!.photoURL,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((e) => debugPrint('Online status error: $e'));
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

class DaoApp extends ConsumerStatefulWidget { // ✅ ConsumerStatefulWidget으로 변경
  const DaoApp({super.key});

  @override
  ConsumerState<DaoApp> createState() => _DaoAppState();
}

class _DaoAppState extends ConsumerState<DaoApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>(); // ✅ 네비게이션용 키

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // 🎯 딥링크 수신 및 처리 로직
  void _initDeepLinks() async {
    // 1. 앱이 꺼진 상태에서 링크로 실행된 경우
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // 2. 앱이 켜져 있는 상태에서 링크를 누른 경우 감시
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 딥링크 감지: $uri');
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // 💡 앱이 켜지는 초기화 과정(Splash -> Main)과 겹치지 않도록
    // 1.2초 ~ 1.5초 정도 충분한 딜레이를 줍니다.
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (_navigatorKey.currentState == null) return;

      // 🏆 대회 상세 페이지 이동 (tournament?id=...)
      if (uri.path.contains('tournament')) {
        final tournamentId = uri.queryParameters['id'];
        if (tournamentId != null) {
          debugPrint('🎯 대회 상세 페이지로 강제 이동: $tournamentId');
          _navigatorKey.currentState?.pushNamed(
            RouteConstants.tournamentDetail,
            arguments: tournamentId,
          );
        }
      }

      // 📝 커뮤니티 게시물 이동 (추가 수정)
      if (uri.path.contains('post')) {
        final postId = uri.queryParameters['id'];
        if (postId != null) {
          debugPrint('🎯 게시물 위치로 이동 시도: $postId');
          // ✅ 커뮤니티 화면(Circle)으로 보내면서 postId를 인자로 전달
          _navigatorKey.currentState?.pushNamed(
            RouteConstants.circle,
            arguments: postId, // CircleScreen에서 이 ID를 받아서 해당 위치로 스크롤해야 함
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey, // ✅ 네비게이터 키 등록 필수
      title: 'DAO App - Steel League',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteConstants.splash,
      routes: {
        RouteConstants.splash: (_) => const SplashScreen(),
        RouteConstants.login: (_) => const LoginScreen(),
        RouteConstants.main: (_) => const MainScreen(),
        RouteConstants.home: (_) => const HomeScreen(),
        RouteConstants.trainingHome: (_) => const TrainingHomeScreen(),
        RouteConstants.checkoutCalculator: (_) => const CheckoutCalculatorScreen(),
        RouteConstants.trainingRatingInput: (_) => const TrainingRatingInputScreen(),
        RouteConstants.boardLevelTest: (_) => const BoardLevelTestScreen(),
        RouteConstants.trainingHistory: (_) => const TrainingHistoryScreen(),
        RouteConstants.arenaHome: (_) => const ArenaHomeScreen(),
        RouteConstants.steelLeagueRanking: (_) => const SteelLeagueRankingScreen(),
        RouteConstants.steelLeagueSchedule: (_) => const SteelLeagueScheduleScreen(),
        RouteConstants.chat: (_) => const ChatScreen(),
        RouteConstants.steelLeaguePointCalendar: (_) => const SteelLeaguePointCalendarScreen(),
        RouteConstants.steelLeagueMembers: (_) => const MemberListScreen(),
        RouteConstants.tournamentCreate: (_) => const TournamentCreateScreen(),
        RouteConstants.community: (_) => const CommunityHomeScreen(),
        RouteConstants.circle: (_) => const CircleScreen(),
        RouteConstants.postWrite: (_) => const PostWriteScreen(),
        RouteConstants.myPage: (_) => const MyPageScreen(),
        RouteConstants.profileRegister: (_) => const ProfileRegisterScreen(),
        RouteConstants.noticeList: (_) => const NoticeListScreen(),
        RouteConstants.report: (_) => const ReportFormScreen(),
        RouteConstants.myLogHome: (_) => const MyLogHomeScreen(),
        RouteConstants.adminDashboard: (_) => const AdminDashboardScreen(),
        RouteConstants.blockList: (_) => const BlockListScreen(),
        RouteConstants.pointAward: (_) => const PointAwardScreen(),
        RouteConstants.pointAwardList: (_) => const PointAwardListScreen(),
        RouteConstants.eventCreate: (_) => const EventCreateScreen(),
        RouteConstants.eventList: (_) => const EventListScreen(),
        RouteConstants.noticeForm: (_) => const NoticeFormScreen(),
        RouteConstants.newsForm: (_) => const NewsFormScreen(),
        RouteConstants.sponsorForm: (_) => const SponsorFormScreen(),
        RouteConstants.memberRegister: (_) => const MemberRegisterScreen(),
        RouteConstants.competitionPhotosForm: (_) => const CompetitionPhotosFormScreen(),
        RouteConstants.adminReportList: (_) => const AdminReportListScreen(),
        RouteConstants.adminMemberList: (_) => const AdminMemberListScreen(),
        RouteConstants.selectionPlayersAdmin: (_) => const SelectionPlayersAdminScreen(),
        RouteConstants.steelLeagueSelection: (_) => const SelectionPlayersScreen(),
        RouteConstants.adminBlockManage: (_) => const AdminBlockManageScreen(),
        RouteConstants.adminHardCleanup: (_) => const AdminHardCleanupScreen(),
        RouteConstants.adminChatConfig: (_) => const AdminChatConfigScreen(),
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
        if (settings.name == RouteConstants.tournamentDetail) {
          final id = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: id));
        }

        if (settings.name == RouteConstants.tournamentEntryForm) {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (_) => TournamentEntryFormScreen(
                tournamentId: args['tournamentId'] as String,
                isManualMode: args['isManualMode'] as bool? ?? false,
              ),
            );
          } else {
            return MaterialPageRoute(
              builder: (_) => TournamentEntryFormScreen(
                tournamentId: args as String,
                isManualMode: false,
              ),
            );
          }
        }

        if (settings.name == RouteConstants.tournamentParticipantList) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => TournamentParticipantListScreen(
              tournamentId: args['tournamentId'] as String,
              tournamentTitle: args['tournamentTitle'] as String? ?? '참가자 명단',
            ),
          );
        }
        return null;
      },
      onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }
}