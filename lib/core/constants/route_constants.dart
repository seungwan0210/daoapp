// lib/core/constants/route_constants.dart
class RouteConstants {
  // === 공통 ===
  static const String splash = '/splash';                    // splash_screen.dart
  static const String login = '/login';                      // login_screen.dart
  static const String main = '/main';                        // main_screen.dart

  // === 유저 ===
  static const String ranking = '/ranking';                  // ranking_screen.dart
  static const String calendar = '/calendar';                // calendar_screen.dart
  static const String community = '/community';              // community_home_screen.dart
  static const String myPage = '/my-page';                   // my_page_screen.dart
  static const String profileRegister = '/profile-register'; // profile_register_screen.dart
  static const String pointCalendar = '/point-calendar';     // point_calendar_screen.dart
  static const String noticeList = '/notice-list';           // notice_list_screen.dart
  static const String memberList = '/member-list';           // member_list_screen.dart
  static const String guestbook = '/guestbook';              // guestbook_screen.dart (onGenerateRoute)
  static const String report = '/report';                    // report_form_screen.dart

  // === 관리자 ===
  static const String adminDashboard = '/admin/dashboard';               // admin_dashboard_screen.dart
  static const String pointAward = '/admin/point-award';                 // point_award_screen.dart
  static const String pointAwardList = '/admin/point-award-list';       // point_award_list_screen.dart
  static const String eventCreate = '/admin/event-create';              // event_create_screen.dart
  static const String eventList = '/admin/event-list';                  // event_list_screen.dart
  static const String eventEdit = '/admin/event-edit';                   // event_edit_screen.dart (onGenerateRoute)
  static const String noticeForm = '/admin/notice-form';                 // notice_form_screen.dart
  static const String newsForm = '/admin/news-form';                     // news_form_screen.dart
  static const String sponsorForm = '/admin/sponsor-form';               // sponsor_form_screen.dart
  static const String memberRegister = '/admin/member-register';         // member_register_screen.dart
  static const String competitionPhotosForm = '/admin/competition-photos-form'; // competition_photos_form_screen.dart
  static const String adminReportList = '/admin/report-list';            // admin_report_list_screen.dart
  static const String adminMemberList = '/admin/member-list';

  // === 커뮤니티 - 서클 ===
  static const String circle = '/community/circle';          // circle_screen.dart
  static const String postWrite = '/community/circle/post-write'; // post_write_screen.dart

  // === 커뮤니티 - 체크아웃 ===
  static const String checkoutHome = '/checkout';                     // checkout_home_screen.dart
  static const String checkoutCalculator = '/checkout/calculator';    // checkout_calculator_screen.dart

  // 연습 모드 세분화
  static const String checkoutPractice = '/checkout/practice';        // checkout_practice_home_screen.dart
  static const String checkoutPracticePlay = '/checkout/practice/play'; // checkout_practice_screen.dart
  static const String checkoutResult = '/checkout/result';            // checkout_result_screen.dart
  static const String checkoutRanking = '/checkout_ranking';          // checkout_ranking_screen.dart
  static const String checkoutMyHistory = '/checkout_my_history';  // checkout_my_history_screen.dart

  // === 커뮤니티 - 아레나 ===
  static const String arenaDetail = '/community/arena/detail';           // arena_screen.dart
  static const String arenaReviewWrite = '/community/arena/review-write'; // arena_review_write_screen.dart
  static const String arenaReviewDetail = '/community/arena/review-detail'; // arena_review_detail_screen.dart (onGenerateRoute)
}