// lib/core/constants/route_constants.dart

/// 앱 내 모든 라우트 상수 정의
class RouteConstants {
  // 공통
  static const String splash = '/splash';
  static const String login = '/login';
  static const String main = '/main';

  // 유저
  static const String ranking = '/ranking';
  static const String calendar = '/calendar';
  static const String community = '/community';
  static const String myPage = '/my-page'; // ← 이거 추가!
  static const String profileRegister = '/profile-register';
  static const String pointCalendar = '/point-calendar';

  // 관리자
  static const String adminDashboard = '/admin-dashboard';

  // 관리자 - 포인트
  static const String pointAward = '/admin/point-award';
  static const String pointAwardList = '/admin/point-award-list';

  // 관리자 - 경기
  static const String eventCreate = '/admin/event-create';
  static const String eventList = '/admin/event-list';

  // 관리자 - 폼
  static const String noticeForm = '/admin/notice-form';
  static const String newsForm = '/admin/news-form';
  static const String sponsorForm = '/admin/sponsor-form';

  // 관리자 - 정회원
  static const String memberRegister = '/admin/member-register';
  static const String memberList = '/member-list';
}