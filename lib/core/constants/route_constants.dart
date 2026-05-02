// lib/core/constants/route_constants.dart

class RouteConstants {
  // === 공통 ===
  static const String splash = '/splash';
  static const String login = '/login';
  static const String main = '/main';

  // === 홈 ===
  static const String home = '/home';

  // === 트레이닝 탭 (Training) ===
  static const String trainingHome = '/training';                      // TrainingHomeScreen
  static const String todayTasks = '/training/today-tasks';            // 미래 기능
  static const String ratingTest = '/training/rating-test';            // 임시

  // 🔹 트레이닝 프로필 관련
  static const String trainingRatingInput = '/training/rating-input';  // 레이팅/PPD 입력
  static const String boardLevelTest = '/training/board-level-test';   // 1~20 레벨 테스트

  // 🔹 드릴 & 히스토리 관련
  static const String trainingDrillRun = '/training/drill-run';        // DrillRunScreen
  static const String trainingDrillResult = '/training/drill-result';  // DrillResultScreen
  static const String trainingHistory = '/training/history';           // TrainingHistoryScreen

  // ============================================================
  // 🔥🔥 피니쉬 루트 연습(Finish Route Practice) 🔥🔥
  // ============================================================

  static const String finishRouteHome =
      '/training/finish-route/home';            // FinishRouteHomeScreen

  static const String finishRoutePractice =
      '/training/finish-route/practice';        // FinishRoutePracticeScreen

  static const String finishRouteResult =
      '/training/finish-route/result';          // FinishRouteResultScreen

  static const String finishRouteRanking =
      '/training/finish-route/ranking';         // FinishRouteRankingScreen

  static const String finishRouteMyHistory =
      '/training/finish-route/my-history';      // FinishRouteMyHistoryScreen

  // 🔹 체크아웃 계산기 (서큘레이터)
  //   → TrainingCalculatorScreen 에 매핑
  static const String checkoutCalculator =
      '/training/checkout/calculator';

  // === 아레나 탭 (Arena) ===
  static const String arenaHome = '/arena';     // ArenaHomeScreen

  // 스틸리그
  static const String steelLeagueRanking = '/arena/steel/ranking';
  static const String steelLeagueSchedule = '/arena/steel/schedule';
  static const String steelLeaguePointCalendar = '/arena/steel/point-calendar';
  static const String steelLeagueMembers = '/arena/steel/members';
  static const String steelLeagueSelection = '/arena/steel/selection';

  // === 토너먼트 ===
  static const String tournamentHome = '/arena/tournament';
  static const String tournamentCreate = '/arena/tournament/create';
  static const String tournamentDetail = '/arena/tournament/detail';
  static const String tournamentEntryForm = '/arena/tournament/entry';
  static const String tournamentParticipantList =
      '/arena/tournament/participants';

  // === 커뮤니티 ===
  static const String community = '/community';
  static const String circle = '/community/circle';
  static const String postWrite = '/community/circle/post-write';
  static const String chat = '/community/chat'; // 🔥 이 줄을 추가하세요!
  static const String blockList = '/my-page/block-list';

  // === 마이페이지 ===
  static const String myPage = '/my-page';
  static const String profileRegister = '/my-page/profile-register';
  static const String noticeList = '/my-page/notices';
  static const String guestbook = '/my-page/guestbook';
  static const String report = '/my-page/report';
  static const String myLogHome = '/my-page/my-log';

  // === 관리자 ===
  static const String adminDashboard = '/admin/dashboard';
  static const String adminMemberList = '/admin/member-list';
  static const String adminReportList = '/admin/report-list';
  static const String pointAward = '/admin/point-award';
  static const String pointAwardList = '/admin/point-award-list';
  static const String eventCreate = '/admin/event-create';
  static const String eventList = '/admin/event-list';
  static const String eventEdit = '/admin/event-edit';
  static const String noticeForm = '/admin/notice-form';
  static const String newsForm = '/admin/news-form';
  static const String sponsorForm = '/admin/sponsor-form';
  static const String memberRegister = '/admin/member-register';
  static const String competitionPhotosForm = '/admin/competition-photos-form';
  static const String selectionPlayersAdmin = '/admin/selection-players';
  static const String adminBlockManage = '/admin/block-manage'; // 전체 차단 현황
  static const String adminBlockStats = '/admin/block-manage';
  static const String adminChatConfig = '/admin/chat-config';
  static const String adminHardCleanup = '/admin/hard-cleanup';
  // === 홈 (공식 일정 관련 추가) ===
  static const String officialCalendar = '/home/official-calendar'; // 공식 일정 전체보기

  // === 관리자 (공식 일정 관리 추가) ===
  static const String officialCalendarCreate = '/admin/official-calendar/create'; // 일정 등록
  static const String officialCalendarList = '/admin/official-calendar/list';
  static const String magazineForm = '/admin/magazine-form';
  static const String adminQuickNotice = '/admin/quick-notice';
  static const String livePracticeFullList = '/live-practice-full-list';
}

