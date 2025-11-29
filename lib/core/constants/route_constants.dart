// lib/core/constants/route_constants.dart

class RouteConstants {
  // === 공통 ===
  static const String splash = '/splash';
  static const String login = '/login';
  static const String main = '/main';

  // === 홈 ===
  static const String home = '/home';

  // === 트레이닝 탭 (Training) ===
  static const String trainingHome = '/training';                          // TrainingHomeScreen
  static const String todayTasks = '/training/today-tasks';                // 오늘의 체크아웃 과제 (미래)
  static const String ratingTest = '/training/rating-test';                // 레이팅 테스트 (미래)

  // 체크아웃 연습 & 계산기
  static const String checkoutPracticeHome = '/training/checkout/practice-home';     // 연습 홈
  static const String checkoutPracticePlay = '/training/checkout/practice';         // 실제 연습 플레이
  static const String checkoutResult = '/training/checkout/result';                 // 결과 화면
  static const String checkoutRanking = '/training/checkout/ranking';               // 전체 랭킹
  static const String checkoutMyHistory = '/training/checkout/my-history';          // 내 기록
  static const String checkoutCalculator = '/training/checkout/calculator';         // 체크아웃 계산기

  // === 아레나 탭 (Arena) ===
  static const String arenaHome = '/arena';                                 // ArenaHomeScreen

  // 스틸리그
  static const String steelLeagueRanking = '/arena/steel/ranking';
  static const String steelLeagueSchedule = '/arena/steel/schedule';
  static const String steelLeaguePointCalendar = '/arena/steel/point-calendar';
  static const String steelLeagueMembers = '/arena/steel/members';
  static const String steelLeagueSelection = '/arena/steel/selection';

  // 토너먼트
  static const String tournamentHome = '/arena/tournament';
  static const String tournamentCreate = '/arena/tournament/create';
  static const String tournamentDetail = '/arena/tournament/detail';           // args: tournamentId
  static const String tournamentEntryForm = '/arena/tournament/entry';         // args: tournamentId
  static const String tournamentParticipantList = '/arena/tournament/participants'; // args: Map

  // === 커뮤니티 ===
  static const String community = '/community';
  static const String circle = '/community/circle';
  static const String postWrite = '/community/circle/post-write';

  // === 마이페이지 ===
  static const String myPage = '/my-page';
  static const String profileRegister = '/my-page/profile-register';
  static const String noticeList = '/my-page/notices';
  static const String guestbook = '/my-page/guestbook';       // args: userId
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
  static const String eventEdit = '/admin/event-edit';                 // args: Map
  static const String noticeForm = '/admin/notice-form';
  static const String newsForm = '/admin/news-form';
  static const String sponsorForm = '/admin/sponsor-form';
  static const String memberRegister = '/admin/member-register';
  static const String competitionPhotosForm = '/admin/competition-photos-form';
  static const String selectionPlayersAdmin = '/admin/selection-players';
}