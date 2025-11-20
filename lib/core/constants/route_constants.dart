// lib/core/constants/route_constants.dart

class RouteConstants {
  // === 공통 ===
  static const String splash = '/splash';
  static const String login = '/login';
  static const String main = '/main';

  // === 유저 ===
  static const String ranking = '/ranking';
  static const String calendar = '/calendar';
  static const String community = '/community';
  static const String myPage = '/my-page';
  static const String profileRegister = '/profile-register';
  static const String pointCalendar = '/point-calendar';
  static const String noticeList = '/notice-list';
  static const String memberList = '/member-list';
  static const String guestbook = '/guestbook';
  static const String report = '/report';
  static const String adminReportList = '/admin/report-list';

  // === 관리자 ===
  static const String adminDashboard = '/admin/dashboard';
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
  static const String adminMemberList = '/admin/member-list';

  // === 커뮤니티 - 서클 ===
  static const String circle = '/community/circle';
  static const String postWrite = '/community/circle/post-write';

  // === 체크아웃 ===
  static const String checkoutHome = '/checkout';
  static const String checkoutCalculator = '/checkout/calculator';
  static const String checkoutPractice = '/checkout/practice';
  static const String checkoutPracticePlay = '/checkout/practice/play';
  static const String checkoutResult = '/checkout/result';
  static const String checkoutRanking = '/checkout/ranking';
  static const String checkoutMyHistory = '/checkout/my-history';

  // === 아레나 토너먼트 (신규) ===
  static const String arenaHome = '/arena/home';
  static const String tournamentCreate = '/arena/tournament/create';
  static const String tournamentDetail = '/arena/tournament/detail';                 // onGenerateRoute
  static const String tournamentEntryForm = '/arena/tournament/entry';               // onGenerateRoute
  static const String tournamentParticipantList = '/arena/tournament/participants'; // onGenerateRoute
}