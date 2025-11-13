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
  static const String adminReportList = '/admin/report-list';

  // === 커뮤니티 - 서클 ===
  static const String circle = '/community/circle';           // 메인 서클 피드
  static const String postWrite = '/community/circle/post-write';

  // === 커뮤니티 - 체크아웃 ===
  static const String checkoutHome = '/checkout';                     // 체크아웃 메인 (모드 선택)
  static const String checkoutCalculator = '/checkout/calculator';    // 계산기 모드
  static const String checkoutPractice = '/checkout/practice';        // 연습 모드
  static const String checkoutResult = '/checkout/result';            // 연습 결과

  // === 커뮤니티 - 아레나 ===
  static const String arenaDetail = '/community/arena/detail';
  static const String arenaReviewWrite = '/community/arena/review-write';
  static const String arenaReviewDetail = '/community/arena/review-detail';
}