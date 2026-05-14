import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @badge_name_pro.
  ///
  /// In ko, this message translates to:
  /// **'프로'**
  String get badge_name_pro;

  /// No description provided for @badge_name_emerald.
  ///
  /// In ko, this message translates to:
  /// **'에메랄드'**
  String get badge_name_emerald;

  /// No description provided for @badge_name_diamond.
  ///
  /// In ko, this message translates to:
  /// **'다이아몬드'**
  String get badge_name_diamond;

  /// No description provided for @badge_name_platinum.
  ///
  /// In ko, this message translates to:
  /// **'플래티넘'**
  String get badge_name_platinum;

  /// No description provided for @badge_name_gold.
  ///
  /// In ko, this message translates to:
  /// **'골드'**
  String get badge_name_gold;

  /// No description provided for @badge_name_silver.
  ///
  /// In ko, this message translates to:
  /// **'실버'**
  String get badge_name_silver;

  /// No description provided for @badge_name_bronze.
  ///
  /// In ko, this message translates to:
  /// **'브론즈'**
  String get badge_name_bronze;

  /// No description provided for @badge_name_platinum1.
  ///
  /// In ko, this message translates to:
  /// **'플래티넘 1'**
  String get badge_name_platinum1;

  /// No description provided for @badge_name_platinum2.
  ///
  /// In ko, this message translates to:
  /// **'플래티넘 2'**
  String get badge_name_platinum2;

  /// No description provided for @badge_name_gold1.
  ///
  /// In ko, this message translates to:
  /// **'골드 1'**
  String get badge_name_gold1;

  /// No description provided for @badge_name_gold2.
  ///
  /// In ko, this message translates to:
  /// **'골드 2'**
  String get badge_name_gold2;

  /// No description provided for @badge_name_silver1.
  ///
  /// In ko, this message translates to:
  /// **'실버 1'**
  String get badge_name_silver1;

  /// No description provided for @badge_name_silver2.
  ///
  /// In ko, this message translates to:
  /// **'실버 2'**
  String get badge_name_silver2;

  /// No description provided for @badge_name_bronze1.
  ///
  /// In ko, this message translates to:
  /// **'브론즈 1'**
  String get badge_name_bronze1;

  /// No description provided for @badge_name_bronze2.
  ///
  /// In ko, this message translates to:
  /// **'브론즈 2'**
  String get badge_name_bronze2;

  /// No description provided for @badge_name_bronze3.
  ///
  /// In ko, this message translates to:
  /// **'브론즈 3'**
  String get badge_name_bronze3;

  /// No description provided for @badge_name_trophy.
  ///
  /// In ko, this message translates to:
  /// **'트로피'**
  String get badge_name_trophy;

  /// No description provided for @badge_name_season_champion.
  ///
  /// In ko, this message translates to:
  /// **'시즌 우승자'**
  String get badge_name_season_champion;

  /// No description provided for @badge_name_season_rank1.
  ///
  /// In ko, this message translates to:
  /// **'시즌 1위'**
  String get badge_name_season_rank1;

  /// No description provided for @badge_name_season_rank2.
  ///
  /// In ko, this message translates to:
  /// **'시즌 2위'**
  String get badge_name_season_rank2;

  /// No description provided for @badge_name_season_rank3.
  ///
  /// In ko, this message translates to:
  /// **'시즌 3위'**
  String get badge_name_season_rank3;

  /// No description provided for @badge_name_season_general.
  ///
  /// In ko, this message translates to:
  /// **'시즌 배지'**
  String get badge_name_season_general;

  /// No description provided for @badge_name_monthly.
  ///
  /// In ko, this message translates to:
  /// **'월간 배지'**
  String get badge_name_monthly;

  /// No description provided for @menu_home.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get menu_home;

  /// No description provided for @menu_training.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝'**
  String get menu_training;

  /// No description provided for @menu_arena.
  ///
  /// In ko, this message translates to:
  /// **'아레나'**
  String get menu_arena;

  /// No description provided for @menu_community.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티'**
  String get menu_community;

  /// No description provided for @menu_mypage.
  ///
  /// In ko, this message translates to:
  /// **'마이페이지'**
  String get menu_mypage;

  /// No description provided for @menu_settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get menu_settings;

  /// No description provided for @menu_notice.
  ///
  /// In ko, this message translates to:
  /// **'공지사항'**
  String get menu_notice;

  /// No description provided for @menu_report.
  ///
  /// In ko, this message translates to:
  /// **'버그 신고'**
  String get menu_report;

  /// No description provided for @menu_quick_arena.
  ///
  /// In ko, this message translates to:
  /// **'아레나'**
  String get menu_quick_arena;

  /// No description provided for @menu_quick_league.
  ///
  /// In ko, this message translates to:
  /// **'스틸리그'**
  String get menu_quick_league;

  /// No description provided for @menu_quick_tournament.
  ///
  /// In ko, this message translates to:
  /// **'토너먼트'**
  String get menu_quick_tournament;

  /// No description provided for @menu_quick_training.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝'**
  String get menu_quick_training;

  /// No description provided for @menu_quick_pose.
  ///
  /// In ko, this message translates to:
  /// **'포즈분석'**
  String get menu_quick_pose;

  /// No description provided for @menu_quick_grip.
  ///
  /// In ko, this message translates to:
  /// **'그립랩'**
  String get menu_quick_grip;

  /// No description provided for @menu_quick_profile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get menu_quick_profile;

  /// No description provided for @menu_quick_mylog.
  ///
  /// In ko, this message translates to:
  /// **'마이로그'**
  String get menu_quick_mylog;

  /// No description provided for @menu_quick_livetalk.
  ///
  /// In ko, this message translates to:
  /// **'라이브톡'**
  String get menu_quick_livetalk;

  /// No description provided for @menu_quick_circle.
  ///
  /// In ko, this message translates to:
  /// **'서클'**
  String get menu_quick_circle;

  /// No description provided for @menu_quick_block.
  ///
  /// In ko, this message translates to:
  /// **'차단관리'**
  String get menu_quick_block;

  /// No description provided for @menu_quick_report.
  ///
  /// In ko, this message translates to:
  /// **'신고/버그'**
  String get menu_quick_report;

  /// No description provided for @nav_tab_home.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get nav_tab_home;

  /// No description provided for @nav_tab_training.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝'**
  String get nav_tab_training;

  /// No description provided for @nav_tab_arena.
  ///
  /// In ko, this message translates to:
  /// **'아레나'**
  String get nav_tab_arena;

  /// No description provided for @nav_tab_community.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티'**
  String get nav_tab_community;

  /// No description provided for @nav_tab_mypage.
  ///
  /// In ko, this message translates to:
  /// **'내정보'**
  String get nav_tab_mypage;

  /// No description provided for @drill_history.
  ///
  /// In ko, this message translates to:
  /// **'훈련 히스토리'**
  String get drill_history;

  /// No description provided for @checkout_calculator.
  ///
  /// In ko, this message translates to:
  /// **'체크아웃 계산기'**
  String get checkout_calculator;

  /// No description provided for @drill_run_title.
  ///
  /// In ko, this message translates to:
  /// **'드릴 진행'**
  String get drill_run_title;

  /// No description provided for @drill_difficulty_easy.
  ///
  /// In ko, this message translates to:
  /// **'쉬움'**
  String get drill_difficulty_easy;

  /// No description provided for @drill_difficulty_normal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get drill_difficulty_normal;

  /// No description provided for @drill_difficulty_hard.
  ///
  /// In ko, this message translates to:
  /// **'어려움'**
  String get drill_difficulty_hard;

  /// No description provided for @drill_difficulty_within.
  ///
  /// In ko, this message translates to:
  /// **'이내'**
  String get drill_difficulty_within;

  /// No description provided for @drill_category_boardMapping.
  ///
  /// In ko, this message translates to:
  /// **'보드 맵핑'**
  String get drill_category_boardMapping;

  /// No description provided for @drill_category_scoring.
  ///
  /// In ko, this message translates to:
  /// **'점수 획득'**
  String get drill_category_scoring;

  /// No description provided for @drill_category_finish.
  ///
  /// In ko, this message translates to:
  /// **'피니시'**
  String get drill_category_finish;

  /// No description provided for @drill_category_doublePractice.
  ///
  /// In ko, this message translates to:
  /// **'더블 연습'**
  String get drill_category_doublePractice;

  /// No description provided for @drill_category_bull.
  ///
  /// In ko, this message translates to:
  /// **'불 연습'**
  String get drill_category_bull;

  /// No description provided for @drill_category_other.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get drill_category_other;

  /// No description provided for @guide_target_hit.
  ///
  /// In ko, this message translates to:
  /// **'목표 영역에 다트를 던지고 명중 개수를 입력하세요.'**
  String get guide_target_hit;

  /// No description provided for @guide_finish_desc.
  ///
  /// In ko, this message translates to:
  /// **'최대 3다트 안에 더블 아웃으로 마무리하세요.'**
  String get guide_finish_desc;

  /// No description provided for @guide_mpr_goal.
  ///
  /// In ko, this message translates to:
  /// **'목표: 평균 MPR 2.0 이상!'**
  String get guide_mpr_goal;

  /// No description provided for @tier_beginner.
  ///
  /// In ko, this message translates to:
  /// **'비기너'**
  String get tier_beginner;

  /// No description provided for @tier_learner.
  ///
  /// In ko, this message translates to:
  /// **'러너'**
  String get tier_learner;

  /// No description provided for @tier_competitor.
  ///
  /// In ko, this message translates to:
  /// **'컴페티터'**
  String get tier_competitor;

  /// No description provided for @tier_challenger.
  ///
  /// In ko, this message translates to:
  /// **'챌린저'**
  String get tier_challenger;

  /// No description provided for @tier_elite.
  ///
  /// In ko, this message translates to:
  /// **'엘리트'**
  String get tier_elite;

  /// No description provided for @tier_pro.
  ///
  /// In ko, this message translates to:
  /// **'프로'**
  String get tier_pro;

  /// No description provided for @tier_master.
  ///
  /// In ko, this message translates to:
  /// **'마스터'**
  String get tier_master;

  /// No description provided for @status_upcoming.
  ///
  /// In ko, this message translates to:
  /// **'엔트리 예정'**
  String get status_upcoming;

  /// No description provided for @status_open.
  ///
  /// In ko, this message translates to:
  /// **'엔트리 오픈'**
  String get status_open;

  /// No description provided for @status_closed.
  ///
  /// In ko, this message translates to:
  /// **'엔트리 마감'**
  String get status_closed;

  /// No description provided for @status_in_progress.
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get status_in_progress;

  /// No description provided for @status_finished.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get status_finished;

  /// No description provided for @status_canceled.
  ///
  /// In ko, this message translates to:
  /// **'취소됨'**
  String get status_canceled;

  /// No description provided for @time_just_now.
  ///
  /// In ko, this message translates to:
  /// **'방금 전'**
  String get time_just_now;

  /// No description provided for @time_minutes_ago.
  ///
  /// In ko, this message translates to:
  /// **'{count}분 전'**
  String time_minutes_ago(Object count);

  /// No description provided for @time_hours_ago.
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 전'**
  String time_hours_ago(Object count);

  /// No description provided for @grip_perfect.
  ///
  /// In ko, this message translates to:
  /// **'완벽합니다!'**
  String get grip_perfect;

  /// No description provided for @grip_good_shape.
  ///
  /// In ko, this message translates to:
  /// **'{finger}의 모양은 기준과 잘 맞습니다.'**
  String grip_good_shape(Object finger);

  /// No description provided for @grip_wide.
  ///
  /// In ko, this message translates to:
  /// **'엄지-검지가 기준보다 멉니다.'**
  String get grip_wide;

  /// No description provided for @grip_narrow.
  ///
  /// In ko, this message translates to:
  /// **'엄지-검지가 기준보다 가깝습니다.'**
  String get grip_narrow;

  /// No description provided for @grip_too_straight.
  ///
  /// In ko, this message translates to:
  /// **'기준보다 더 펴졌습니다.'**
  String get grip_too_straight;

  /// No description provided for @grip_too_curved.
  ///
  /// In ko, this message translates to:
  /// **'기준보다 더 구부러졌습니다.'**
  String get grip_too_curved;

  /// No description provided for @cycle_label_format.
  ///
  /// In ko, this message translates to:
  /// **'{tier} 사이클'**
  String cycle_label_format(Object tier);

  /// No description provided for @cycle_old_format.
  ///
  /// In ko, this message translates to:
  /// **'사이클 {number}'**
  String cycle_old_format(Object number);

  /// No description provided for @err_login_required.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요한 서비스입니다.'**
  String get err_login_required;

  /// No description provided for @err_save_failed.
  ///
  /// In ko, this message translates to:
  /// **'기록 저장에 실패했습니다'**
  String get err_save_failed;

  /// No description provided for @name_no_name.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get name_no_name;

  /// No description provided for @calc_btn_reset.
  ///
  /// In ko, this message translates to:
  /// **'다시 시작'**
  String get calc_btn_reset;

  /// No description provided for @calc_undo.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get calc_undo;

  /// No description provided for @calc_title.
  ///
  /// In ko, this message translates to:
  /// **'체크아웃 계산기'**
  String get calc_title;

  /// No description provided for @practice_msg_bust.
  ///
  /// In ko, this message translates to:
  /// **'버스트!'**
  String get practice_msg_bust;

  /// No description provided for @practice_msg_success.
  ///
  /// In ko, this message translates to:
  /// **'체크아웃 성공!'**
  String get practice_msg_success;

  /// No description provided for @practice_msg_finish.
  ///
  /// In ko, this message translates to:
  /// **'모든 문제를 완료했습니다.'**
  String get practice_msg_finish;

  /// No description provided for @state_loading.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중...'**
  String get state_loading;

  /// No description provided for @err_fetch_baseline.
  ///
  /// In ko, this message translates to:
  /// **'기준 그립을 불러오지 못했어요.'**
  String get err_fetch_baseline;

  /// No description provided for @err_save_baseline.
  ///
  /// In ko, this message translates to:
  /// **'기준 그립 저장에 실패했어요.'**
  String get err_save_baseline;

  /// No description provided for @err_delete_baseline.
  ///
  /// In ko, this message translates to:
  /// **'기준 그립 삭제에 실패했어요.'**
  String get err_delete_baseline;

  /// No description provided for @err_session_start.
  ///
  /// In ko, this message translates to:
  /// **'세션 시작 실패'**
  String get err_session_start;

  /// No description provided for @err_session_save.
  ///
  /// In ko, this message translates to:
  /// **'세션 저장 실패'**
  String get err_session_save;

  /// No description provided for @msg_video_selected.
  ///
  /// In ko, this message translates to:
  /// **'영상 선택 완료'**
  String get msg_video_selected;

  /// No description provided for @msg_processing_video.
  ///
  /// In ko, this message translates to:
  /// **'영상 처리 중...'**
  String get msg_processing_video;

  /// No description provided for @msg_analysis_complete.
  ///
  /// In ko, this message translates to:
  /// **'분석 완료!'**
  String get msg_analysis_complete;

  /// No description provided for @msg_video_saved_gallery.
  ///
  /// In ko, this message translates to:
  /// **'분석 영상이 갤러리에 저장되었습니다! 🎉'**
  String get msg_video_saved_gallery;

  /// No description provided for @msg_video_save_failed.
  ///
  /// In ko, this message translates to:
  /// **'영상 생성에 실패했습니다.'**
  String get msg_video_save_failed;

  /// No description provided for @part_right_wrist.
  ///
  /// In ko, this message translates to:
  /// **'오른손목'**
  String get part_right_wrist;

  /// No description provided for @part_left_wrist.
  ///
  /// In ko, this message translates to:
  /// **'왼손목'**
  String get part_left_wrist;

  /// No description provided for @part_right_elbow.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 팔꿈치'**
  String get part_right_elbow;

  /// No description provided for @part_left_elbow.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 팔꿈치'**
  String get part_left_elbow;

  /// No description provided for @part_right_shoulder.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 어깨'**
  String get part_right_shoulder;

  /// No description provided for @part_left_shoulder.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 어깨'**
  String get part_left_shoulder;

  /// No description provided for @auth_login_prompt.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티를 이용하려면 로그인이 필요해요'**
  String get auth_login_prompt;

  /// No description provided for @auth_verify_required.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 이용을 위해 인증이 필요해요'**
  String get auth_verify_required;

  /// No description provided for @auth_profile_needed.
  ///
  /// In ko, this message translates to:
  /// **'프로필 등록을 완료해 주세요'**
  String get auth_profile_needed;

  /// No description provided for @auth_phone_needed.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 인증을 완료해 주세요'**
  String get auth_phone_needed;

  /// No description provided for @filter_all.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get filter_all;

  /// No description provided for @filter_open.
  ///
  /// In ko, this message translates to:
  /// **'엔트리 오픈'**
  String get filter_open;

  /// No description provided for @filter_upcoming.
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get filter_upcoming;

  /// No description provided for @filter_closed.
  ///
  /// In ko, this message translates to:
  /// **'마감'**
  String get filter_closed;

  /// No description provided for @filter_in_progress.
  ///
  /// In ko, this message translates to:
  /// **'진행중'**
  String get filter_in_progress;

  /// No description provided for @filter_season_label.
  ///
  /// In ko, this message translates to:
  /// **'시즌'**
  String get filter_season_label;

  /// No description provided for @filter_year_label.
  ///
  /// In ko, this message translates to:
  /// **'연도'**
  String get filter_year_label;

  /// No description provided for @filter_top9.
  ///
  /// In ko, this message translates to:
  /// **'상위 9개'**
  String get filter_top9;

  /// No description provided for @rank_total_points.
  ///
  /// In ko, this message translates to:
  /// **'총 포인트'**
  String get rank_total_points;

  /// No description provided for @rank_phase_total.
  ///
  /// In ko, this message translates to:
  /// **'누적'**
  String get rank_phase_total;

  /// No description provided for @rank_gender_all.
  ///
  /// In ko, this message translates to:
  /// **'남녀 통합'**
  String get rank_gender_all;

  /// No description provided for @rank_gender_male.
  ///
  /// In ko, this message translates to:
  /// **'남자'**
  String get rank_gender_male;

  /// No description provided for @rank_gender_female.
  ///
  /// In ko, this message translates to:
  /// **'여자'**
  String get rank_gender_female;

  /// No description provided for @msg_no_notices.
  ///
  /// In ko, this message translates to:
  /// **'새로운 공지사항이 없습니다.'**
  String get msg_no_notices;

  /// No description provided for @common_search_hint.
  ///
  /// In ko, this message translates to:
  /// **'이름 또는 이메일로 검색'**
  String get common_search_hint;

  /// No description provided for @common_no_data.
  ///
  /// In ko, this message translates to:
  /// **'등록된 정보가 없습니다.'**
  String get common_no_data;

  /// No description provided for @common_close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get common_close;

  /// No description provided for @common_winner.
  ///
  /// In ko, this message translates to:
  /// **'성공 세트'**
  String get common_winner;

  /// No description provided for @common_location.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get common_location;

  /// No description provided for @common_fee.
  ///
  /// In ko, this message translates to:
  /// **'참가비'**
  String get common_fee;

  /// No description provided for @common_share.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get common_share;

  /// No description provided for @common_edit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get common_edit;

  /// No description provided for @common_delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get common_delete;

  /// No description provided for @common_confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get common_confirm;

  /// No description provided for @common_cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get common_cancel;

  /// No description provided for @common_back.
  ///
  /// In ko, this message translates to:
  /// **'뒤로 가기'**
  String get common_back;

  /// No description provided for @common_msg_deleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제되었습니다'**
  String get common_msg_deleted;

  /// No description provided for @common_msg_img_err.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 불러올 수 없어요'**
  String get common_msg_img_err;

  /// No description provided for @member_list_title.
  ///
  /// In ko, this message translates to:
  /// **'KDF 정회원 명단'**
  String get member_list_title;

  /// No description provided for @player_selection_title.
  ///
  /// In ko, this message translates to:
  /// **'선발 선수'**
  String get player_selection_title;

  /// No description provided for @player_selection_desc.
  ///
  /// In ko, this message translates to:
  /// **'시즌 1–3, 통합 포인트를 기준으로 남녀 각 1명씩 총 8명의 선수가 선발됩니다.'**
  String get player_selection_desc;

  /// No description provided for @player_rep_male.
  ///
  /// In ko, this message translates to:
  /// **'남자 대표'**
  String get player_rep_male;

  /// No description provided for @player_rep_female.
  ///
  /// In ko, this message translates to:
  /// **'여자 대표'**
  String get player_rep_female;

  /// No description provided for @player_upcoming.
  ///
  /// In ko, this message translates to:
  /// **'선발 예정'**
  String get player_upcoming;

  /// No description provided for @league_calendar_title.
  ///
  /// In ko, this message translates to:
  /// **'스틸리그 포인트 달력'**
  String get league_calendar_title;

  /// No description provided for @league_schedule_title.
  ///
  /// In ko, this message translates to:
  /// **'스틸리그 경기 일정'**
  String get league_schedule_title;

  /// No description provided for @league_ranking_title.
  ///
  /// In ko, this message translates to:
  /// **'스틸리그 랭킹'**
  String get league_ranking_title;

  /// No description provided for @tourney_count_unlimited.
  ///
  /// In ko, this message translates to:
  /// **'참가 {count}명'**
  String tourney_count_unlimited(Object count);

  /// No description provided for @tourney_count_fixed.
  ///
  /// In ko, this message translates to:
  /// **'{count}/{max}명'**
  String tourney_count_fixed(Object count, Object max);

  /// No description provided for @tourney_fee_free.
  ///
  /// In ko, this message translates to:
  /// **'무료 입장'**
  String get tourney_fee_free;

  /// No description provided for @tourney_fee_format.
  ///
  /// In ko, this message translates to:
  /// **'{amount}원'**
  String tourney_fee_format(Object amount);

  /// No description provided for @tourney_today.
  ///
  /// In ko, this message translates to:
  /// **'오늘!'**
  String get tourney_today;

  /// No description provided for @tourney_dday.
  ///
  /// In ko, this message translates to:
  /// **'D-{day}'**
  String tourney_dday(Object day);

  /// No description provided for @tourney_closed.
  ///
  /// In ko, this message translates to:
  /// **'마감됨'**
  String get tourney_closed;

  /// No description provided for @img_error_poster.
  ///
  /// In ko, this message translates to:
  /// **'포스터 이미지를 불러올 수 없습니다.'**
  String get img_error_poster;

  /// No description provided for @tourney_my_hosted.
  ///
  /// In ko, this message translates to:
  /// **'내가 주최한 대회'**
  String get tourney_my_hosted;

  /// No description provided for @tourney_create_title.
  ///
  /// In ko, this message translates to:
  /// **'대회 개설'**
  String get tourney_create_title;

  /// No description provided for @tourney_edit_title.
  ///
  /// In ko, this message translates to:
  /// **'대회 수정'**
  String get tourney_edit_title;

  /// No description provided for @tourney_detail_title.
  ///
  /// In ko, this message translates to:
  /// **'대회 상세'**
  String get tourney_detail_title;

  /// No description provided for @tourney_btn_apply.
  ///
  /// In ko, this message translates to:
  /// **'참가 신청하기'**
  String get tourney_btn_apply;

  /// No description provided for @tourney_btn_cancel_apply.
  ///
  /// In ko, this message translates to:
  /// **'참가 신청 취소'**
  String get tourney_btn_cancel_apply;

  /// No description provided for @tourney_btn_delete.
  ///
  /// In ko, this message translates to:
  /// **'대회 삭제하기'**
  String get tourney_btn_delete;

  /// No description provided for @tourney_full_capacity.
  ///
  /// In ko, this message translates to:
  /// **'정원이 가득 찼습니다.'**
  String get tourney_full_capacity;

  /// No description provided for @form_label_title.
  ///
  /// In ko, this message translates to:
  /// **'대회명'**
  String get form_label_title;

  /// No description provided for @form_label_location.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get form_label_location;

  /// No description provided for @form_label_host_name.
  ///
  /// In ko, this message translates to:
  /// **'담당자 이름'**
  String get form_label_host_name;

  /// No description provided for @form_label_host_phone.
  ///
  /// In ko, this message translates to:
  /// **'담당자 연락처'**
  String get form_label_host_phone;

  /// No description provided for @form_label_fee.
  ///
  /// In ko, this message translates to:
  /// **'참가비'**
  String get form_label_fee;

  /// No description provided for @form_label_max_players.
  ///
  /// In ko, this message translates to:
  /// **'최대 인원'**
  String get form_label_max_players;

  /// No description provided for @form_label_desc.
  ///
  /// In ko, this message translates to:
  /// **'상세 안내'**
  String get form_label_desc;

  /// No description provided for @form_hint_desc.
  ///
  /// In ko, this message translates to:
  /// **'대회 규칙, 상금 등을 자세히 작성해주세요'**
  String get form_hint_desc;

  /// No description provided for @msg_save_success.
  ///
  /// In ko, this message translates to:
  /// **'저장되었습니다.'**
  String get msg_save_success;

  /// No description provided for @msg_delete_confirm.
  ///
  /// In ko, this message translates to:
  /// **'이 댓글을 삭제하시겠습니까?'**
  String get msg_delete_confirm;

  /// No description provided for @msg_err_login_needed.
  ///
  /// In ko, this message translates to:
  /// **'로그인 후 이용 가능합니다.'**
  String get msg_err_login_needed;

  /// No description provided for @msg_err_date_order.
  ///
  /// In ko, this message translates to:
  /// **'날짜 설정 순서를 확인해주세요.'**
  String get msg_err_date_order;

  /// No description provided for @arena_league_title.
  ///
  /// In ko, this message translates to:
  /// **'스틸리그'**
  String get arena_league_title;

  /// No description provided for @arena_menu_ranking.
  ///
  /// In ko, this message translates to:
  /// **'랭킹'**
  String get arena_menu_ranking;

  /// No description provided for @arena_menu_schedule.
  ///
  /// In ko, this message translates to:
  /// **'리그 일정'**
  String get arena_menu_schedule;

  /// No description provided for @arena_menu_calendar.
  ///
  /// In ko, this message translates to:
  /// **'포인트 달력'**
  String get arena_menu_calendar;

  /// No description provided for @arena_menu_kdf_member.
  ///
  /// In ko, this message translates to:
  /// **'KDF 정회원'**
  String get arena_menu_kdf_member;

  /// No description provided for @arena_menu_selection.
  ///
  /// In ko, this message translates to:
  /// **'선발 선수'**
  String get arena_menu_selection;

  /// No description provided for @arena_tourney_title.
  ///
  /// In ko, this message translates to:
  /// **'토너먼트'**
  String get arena_tourney_title;

  /// No description provided for @arena_menu_create.
  ///
  /// In ko, this message translates to:
  /// **'개최하기'**
  String get arena_menu_create;

  /// No description provided for @arena_menu_open.
  ///
  /// In ko, this message translates to:
  /// **'참가 가능'**
  String get arena_menu_open;

  /// No description provided for @arena_menu_upcoming.
  ///
  /// In ko, this message translates to:
  /// **'예정 경기'**
  String get arena_menu_upcoming;

  /// No description provided for @arena_menu_my_hosted.
  ///
  /// In ko, this message translates to:
  /// **'내 주최 경기'**
  String get arena_menu_my_hosted;

  /// No description provided for @arena_preview_available.
  ///
  /// In ko, this message translates to:
  /// **'지금 참가 가능한 대회'**
  String get arena_preview_available;

  /// No description provided for @entry_form_title.
  ///
  /// In ko, this message translates to:
  /// **'참가 신청'**
  String get entry_form_title;

  /// No description provided for @entry_label_name_ko.
  ///
  /// In ko, this message translates to:
  /// **'한글이름 *'**
  String get entry_label_name_ko;

  /// No description provided for @entry_label_name_en.
  ///
  /// In ko, this message translates to:
  /// **'영문이름 *'**
  String get entry_label_name_en;

  /// No description provided for @entry_label_phone.
  ///
  /// In ko, this message translates to:
  /// **'연락처 *'**
  String get entry_label_phone;

  /// No description provided for @entry_label_rating.
  ///
  /// In ko, this message translates to:
  /// **'레이팅 (선택)'**
  String get entry_label_rating;

  /// No description provided for @entry_label_homeshop.
  ///
  /// In ko, this message translates to:
  /// **'홈샵 (선택)'**
  String get entry_label_homeshop;

  /// No description provided for @entry_msg_already.
  ///
  /// In ko, this message translates to:
  /// **'이미 참가 신청하셨습니다.'**
  String get entry_msg_already;

  /// No description provided for @entry_msg_full.
  ///
  /// In ko, this message translates to:
  /// **'정원 마감'**
  String get entry_msg_full;

  /// No description provided for @entry_btn_submit.
  ///
  /// In ko, this message translates to:
  /// **'참가 신청 완료'**
  String get entry_btn_submit;

  /// No description provided for @entry_list_title.
  ///
  /// In ko, this message translates to:
  /// **'참가자 명단'**
  String get entry_list_title;

  /// No description provided for @entry_list_empty.
  ///
  /// In ko, this message translates to:
  /// **'아직 참가자가 없습니다'**
  String get entry_list_empty;

  /// No description provided for @entry_detail_no.
  ///
  /// In ko, this message translates to:
  /// **'No.{number}'**
  String entry_detail_no(Object number);

  /// No description provided for @entry_delete_confirm.
  ///
  /// In ko, this message translates to:
  /// **'엔트리를 삭제하시겠습니까?'**
  String get entry_delete_confirm;

  /// No description provided for @comm_comment_title.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get comm_comment_title;

  /// No description provided for @comm_hint_input.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 입력하세요...'**
  String get comm_hint_input;

  /// No description provided for @comm_no_comments.
  ///
  /// In ko, this message translates to:
  /// **'아직 댓글이 없습니다'**
  String get comm_no_comments;

  /// No description provided for @comm_view_all.
  ///
  /// In ko, this message translates to:
  /// **'댓글 모두 보기'**
  String get comm_view_all;

  /// No description provided for @comm_more.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get comm_more;

  /// No description provided for @comm_less.
  ///
  /// In ko, this message translates to:
  /// **'간략히'**
  String get comm_less;

  /// No description provided for @comm_unknown_user.
  ///
  /// In ko, this message translates to:
  /// **'익명'**
  String get comm_unknown_user;

  /// No description provided for @report_title_post.
  ///
  /// In ko, this message translates to:
  /// **'게시물 신고'**
  String get report_title_post;

  /// No description provided for @report_title_comment.
  ///
  /// In ko, this message translates to:
  /// **'댓글 신고'**
  String get report_title_comment;

  /// No description provided for @report_select_reason.
  ///
  /// In ko, this message translates to:
  /// **'사유를 선택해 주세요'**
  String get report_select_reason;

  /// No description provided for @report_reason_spam.
  ///
  /// In ko, this message translates to:
  /// **'스팸/도배'**
  String get report_reason_spam;

  /// No description provided for @report_reason_abuse.
  ///
  /// In ko, this message translates to:
  /// **'욕설/비하'**
  String get report_reason_abuse;

  /// No description provided for @report_reason_hate.
  ///
  /// In ko, this message translates to:
  /// **'혐오/차별'**
  String get report_reason_hate;

  /// No description provided for @report_reason_sexual.
  ///
  /// In ko, this message translates to:
  /// **'성적/선정성'**
  String get report_reason_sexual;

  /// No description provided for @report_reason_privacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 노출'**
  String get report_reason_privacy;

  /// No description provided for @report_reason_other.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get report_reason_other;

  /// No description provided for @block_user_title.
  ///
  /// In ko, this message translates to:
  /// **'사용자 차단'**
  String get block_user_title;

  /// No description provided for @block_user_desc.
  ///
  /// In ko, this message translates to:
  /// **'이 사용자를 차단할까요? 게시글/댓글이 보이지 않게 됩니다.'**
  String get block_user_desc;

  /// No description provided for @msg_report_submitted.
  ///
  /// In ko, this message translates to:
  /// **'신고가 접수되었습니다'**
  String get msg_report_submitted;

  /// No description provided for @msg_block_done.
  ///
  /// In ko, this message translates to:
  /// **'차단 완료'**
  String get msg_block_done;

  /// No description provided for @circle_title_feed.
  ///
  /// In ko, this message translates to:
  /// **'피드'**
  String get circle_title_feed;

  /// No description provided for @circle_no_posts.
  ///
  /// In ko, this message translates to:
  /// **'표시할 게시물이 없습니다'**
  String get circle_no_posts;

  /// No description provided for @circle_label_text_only.
  ///
  /// In ko, this message translates to:
  /// **'글'**
  String get circle_label_text_only;

  /// No description provided for @circle_msg_load_error.
  ///
  /// In ko, this message translates to:
  /// **'피드를 불러오지 못했습니다'**
  String get circle_msg_load_error;

  /// No description provided for @circle_btn_see_all.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get circle_btn_see_all;

  /// No description provided for @post_write_title.
  ///
  /// In ko, this message translates to:
  /// **'서클에 공유하기'**
  String get post_write_title;

  /// No description provided for @post_edit_title.
  ///
  /// In ko, this message translates to:
  /// **'게시물 수정'**
  String get post_edit_title;

  /// No description provided for @post_hint_content.
  ///
  /// In ko, this message translates to:
  /// **'무슨 생각을 하고 계신가요?'**
  String get post_hint_content;

  /// No description provided for @post_hint_from_mylog.
  ///
  /// In ko, this message translates to:
  /// **'마이로그를 다듬어서 공유해 보세요'**
  String get post_hint_from_mylog;

  /// No description provided for @post_btn_submit.
  ///
  /// In ko, this message translates to:
  /// **'게시'**
  String get post_btn_submit;

  /// No description provided for @post_btn_update.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get post_btn_update;

  /// No description provided for @post_add_photo.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가하기'**
  String get post_add_photo;

  /// No description provided for @post_change_photo.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get post_change_photo;

  /// No description provided for @post_delete_confirm_title.
  ///
  /// In ko, this message translates to:
  /// **'삭제 확인'**
  String get post_delete_confirm_title;

  /// No description provided for @post_delete_confirm_msg.
  ///
  /// In ko, this message translates to:
  /// **'이 게시물을 삭제하시겠습니까?'**
  String get post_delete_confirm_msg;

  /// No description provided for @post_msg_upload_fail.
  ///
  /// In ko, this message translates to:
  /// **'업로드 실패'**
  String get post_msg_upload_fail;

  /// No description provided for @post_msg_need_content.
  ///
  /// In ko, this message translates to:
  /// **'내용 또는 사진을 추가해주세요'**
  String get post_msg_need_content;

  /// No description provided for @ugc_gate_title.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 이용 동의가 필요해요'**
  String get ugc_gate_title;

  /// No description provided for @ugc_gate_btn_accept.
  ///
  /// In ko, this message translates to:
  /// **'동의하고 시작'**
  String get ugc_gate_btn_accept;

  /// No description provided for @comm_online_empty.
  ///
  /// In ko, this message translates to:
  /// **'온라인 유저 없음'**
  String get comm_online_empty;

  /// No description provided for @comm_main_grid_title.
  ///
  /// In ko, this message translates to:
  /// **'연습 · 대회 · 기록'**
  String get comm_main_grid_title;

  /// No description provided for @comm_menu_training.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝'**
  String get comm_menu_training;

  /// No description provided for @comm_menu_arena.
  ///
  /// In ko, this message translates to:
  /// **'아레나'**
  String get comm_menu_arena;

  /// No description provided for @comm_menu_mylog.
  ///
  /// In ko, this message translates to:
  /// **'마이로그'**
  String get comm_menu_mylog;

  /// No description provided for @comm_tab_recent.
  ///
  /// In ko, this message translates to:
  /// **'최근'**
  String get comm_tab_recent;

  /// No description provided for @comm_tab_popular.
  ///
  /// In ko, this message translates to:
  /// **'인기'**
  String get comm_tab_popular;

  /// No description provided for @comm_summary_title.
  ///
  /// In ko, this message translates to:
  /// **'오늘 커뮤니티'**
  String get comm_summary_title;

  /// No description provided for @comm_stat_posts.
  ///
  /// In ko, this message translates to:
  /// **'게시글'**
  String get comm_stat_posts;

  /// No description provided for @comm_stat_comments.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get comm_stat_comments;

  /// No description provided for @comm_stat_likes.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get comm_stat_likes;

  /// No description provided for @comm_live_posts.
  ///
  /// In ko, this message translates to:
  /// **'지금 올라온 글'**
  String get comm_live_posts;

  /// No description provided for @auth_login_needed.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티를 이용하려면 로그인이 필요해요'**
  String get auth_login_needed;

  /// No description provided for @auth_verify_needed.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 이용을 위해 인증이 필요해요'**
  String get auth_verify_needed;

  /// No description provided for @auth_profile_incomplete.
  ///
  /// In ko, this message translates to:
  /// **'프로필 등록을 완료해 주세요.'**
  String get auth_profile_incomplete;

  /// No description provided for @auth_phone_incomplete.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 인증을 완료해 주세요.'**
  String get auth_phone_incomplete;

  /// No description provided for @comm_btn_agree_start.
  ///
  /// In ko, this message translates to:
  /// **'동의하고 시작'**
  String get comm_btn_agree_start;

  /// No description provided for @home_title_news.
  ///
  /// In ko, this message translates to:
  /// **'최신 뉴스'**
  String get home_title_news;

  /// No description provided for @home_title_event.
  ///
  /// In ko, this message translates to:
  /// **'다음 경기 일정'**
  String get home_title_event;

  /// No description provided for @home_title_ranking.
  ///
  /// In ko, this message translates to:
  /// **'스틸리그 포인트'**
  String get home_title_ranking;

  /// No description provided for @home_title_photos.
  ///
  /// In ko, this message translates to:
  /// **'대회 사진'**
  String get home_title_photos;

  /// No description provided for @home_title_sponsor.
  ///
  /// In ko, this message translates to:
  /// **'스폰서'**
  String get home_title_sponsor;

  /// No description provided for @home_btn_see_all.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get home_btn_see_all;

  /// No description provided for @home_btn_shortcut.
  ///
  /// In ko, this message translates to:
  /// **'바로가기'**
  String get home_btn_shortcut;

  /// No description provided for @home_training_title.
  ///
  /// In ko, this message translates to:
  /// **'DAO 트레이닝'**
  String get home_training_title;

  /// No description provided for @home_training_gauge.
  ///
  /// In ko, this message translates to:
  /// **'성장 게이지 {percent}%'**
  String home_training_gauge(Object percent);

  /// No description provided for @home_training_prompt.
  ///
  /// In ko, this message translates to:
  /// **'{tier} 티어, 오늘도 연습 시작해볼까요?'**
  String home_training_prompt(Object tier);

  /// No description provided for @home_training_no_tier.
  ///
  /// In ko, this message translates to:
  /// **'내 등급을 등록하면 DAO가 딱 맞는 드릴을 추천해줄게요.'**
  String get home_training_no_tier;

  /// No description provided for @home_training_check_tier.
  ///
  /// In ko, this message translates to:
  /// **'내 등급 확인'**
  String get home_training_check_tier;

  /// No description provided for @home_training_empty.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록된 트레이닝이 없습니다.'**
  String get home_training_empty;

  /// No description provided for @day_mon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get day_mon;

  /// No description provided for @day_tue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get day_tue;

  /// No description provided for @day_wed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get day_wed;

  /// No description provided for @day_thu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get day_thu;

  /// No description provided for @day_fri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get day_fri;

  /// No description provided for @day_sat.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get day_sat;

  /// No description provided for @day_sun.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get day_sun;

  /// No description provided for @login_slogan.
  ///
  /// In ko, this message translates to:
  /// **'Every Point Is Your Story'**
  String get login_slogan;

  /// No description provided for @login_btn_google.
  ///
  /// In ko, this message translates to:
  /// **'Google로 로그인'**
  String get login_btn_google;

  /// No description provided for @login_btn_apple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 로그인'**
  String get login_btn_apple;

  /// No description provided for @login_btn_skip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get login_btn_skip;

  /// No description provided for @login_admin_toggle.
  ///
  /// In ko, this message translates to:
  /// **'운영자 전용 로그인'**
  String get login_admin_toggle;

  /// No description provided for @login_admin_notice.
  ///
  /// In ko, this message translates to:
  /// **'운영자 · 심사용 계정에만 사용하는 로그인 방식입니다.'**
  String get login_admin_notice;

  /// No description provided for @login_msg_fail_email.
  ///
  /// In ko, this message translates to:
  /// **'이메일 로그인에 실패했습니다.'**
  String get login_msg_fail_email;

  /// No description provided for @mylog_title.
  ///
  /// In ko, this message translates to:
  /// **'마이로그'**
  String get mylog_title;

  /// No description provided for @mylog_summary_title.
  ///
  /// In ko, this message translates to:
  /// **'나의 다트 이야기'**
  String get mylog_summary_title;

  /// No description provided for @mylog_summary_count.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}개의 기록이 쌓였어요.'**
  String mylog_summary_count(Object count);

  /// No description provided for @mylog_stat_streak.
  ///
  /// In ko, this message translates to:
  /// **'연속 기록'**
  String get mylog_stat_streak;

  /// No description provided for @mylog_stat_first.
  ///
  /// In ko, this message translates to:
  /// **'첫 기록'**
  String get mylog_stat_first;

  /// No description provided for @mylog_stat_latest.
  ///
  /// In ko, this message translates to:
  /// **'최근 기록'**
  String get mylog_stat_latest;

  /// No description provided for @mylog_calendar_hint.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 탭해서 다트 일기를 작성하거나, 이미 남긴 기록을 다시 볼 수 있어요.'**
  String get mylog_calendar_hint;

  /// No description provided for @mylog_write_new.
  ///
  /// In ko, this message translates to:
  /// **'마이로그 작성'**
  String get mylog_write_new;

  /// No description provided for @mylog_write_edit.
  ///
  /// In ko, this message translates to:
  /// **'마이로그 수정'**
  String get mylog_write_edit;

  /// No description provided for @mylog_add_photo.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가하기 (선택)'**
  String get mylog_add_photo;

  /// No description provided for @mylog_template_good.
  ///
  /// In ko, this message translates to:
  /// **'잘 된 점 💪'**
  String get mylog_template_good;

  /// No description provided for @mylog_template_bad.
  ///
  /// In ko, this message translates to:
  /// **'아쉬웠던 점 🧐'**
  String get mylog_template_bad;

  /// No description provided for @mylog_template_plan.
  ///
  /// In ko, this message translates to:
  /// **'다음 연습 계획 ✏️'**
  String get mylog_template_plan;

  /// No description provided for @mylog_share_circle.
  ///
  /// In ko, this message translates to:
  /// **'서클에 공유하기'**
  String get mylog_share_circle;

  /// No description provided for @mylog_msg_save_done.
  ///
  /// In ko, this message translates to:
  /// **'마이로그 저장 완료!'**
  String get mylog_msg_save_done;

  /// No description provided for @auth_phone_hint.
  ///
  /// In ko, this message translates to:
  /// **'010으로 시작하는 11자리 번호를 입력하세요'**
  String get auth_phone_hint;

  /// No description provided for @auth_code_sent.
  ///
  /// In ko, this message translates to:
  /// **'인증번호가 전송되었습니다'**
  String get auth_code_sent;

  /// No description provided for @auth_code_expired.
  ///
  /// In ko, this message translates to:
  /// **'인증번호가 만료되었습니다. 다시 요청하세요'**
  String get auth_code_expired;

  /// No description provided for @auth_code_invalid.
  ///
  /// In ko, this message translates to:
  /// **'6자리 숫자 인증번호를 입력하세요'**
  String get auth_code_invalid;

  /// No description provided for @auth_verify_success.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호가 성공적으로 인증되었습니다!'**
  String get auth_verify_success;

  /// No description provided for @auth_verify_fail.
  ///
  /// In ko, this message translates to:
  /// **'인증 실패'**
  String get auth_verify_fail;

  /// No description provided for @profile_msg_saving.
  ///
  /// In ko, this message translates to:
  /// **'저장 중입니다. 잠시만 기다려주세요.'**
  String get profile_msg_saving;

  /// No description provided for @profile_save_success.
  ///
  /// In ko, this message translates to:
  /// **'프로필이 저장되었습니다.'**
  String get profile_save_success;

  /// No description provided for @profile_img_delete_title.
  ///
  /// In ko, this message translates to:
  /// **'사진 삭제'**
  String get profile_img_delete_title;

  /// No description provided for @profile_img_delete_msg.
  ///
  /// In ko, this message translates to:
  /// **'정말로 이 사진을 삭제하시겠습니까?'**
  String get profile_img_delete_msg;

  /// No description provided for @profile_err_input.
  ///
  /// In ko, this message translates to:
  /// **'값을 입력해 주세요.'**
  String get profile_err_input;

  /// No description provided for @profile_err_phone_first.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 인증을 완료해주세요!'**
  String get profile_err_phone_first;

  /// No description provided for @profile_none.
  ///
  /// In ko, this message translates to:
  /// **'프로필 없음'**
  String get profile_none;

  /// No description provided for @profile_incomplete.
  ///
  /// In ko, this message translates to:
  /// **'프로필 미완료'**
  String get profile_incomplete;

  /// No description provided for @profile_no_name.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get profile_no_name;

  /// No description provided for @profile_no_content.
  ///
  /// In ko, this message translates to:
  /// **'내용이 없는 기록입니다.'**
  String get profile_no_content;

  /// No description provided for @profile_label_ko_name.
  ///
  /// In ko, this message translates to:
  /// **'한국 이름'**
  String get profile_label_ko_name;

  /// No description provided for @profile_label_en_name.
  ///
  /// In ko, this message translates to:
  /// **'영어 이름'**
  String get profile_label_en_name;

  /// No description provided for @profile_label_shop.
  ///
  /// In ko, this message translates to:
  /// **'샵 이름'**
  String get profile_label_shop;

  /// No description provided for @profile_err_ko_name.
  ///
  /// In ko, this message translates to:
  /// **'한국 이름을 입력하세요'**
  String get profile_err_ko_name;

  /// No description provided for @profile_err_en_name.
  ///
  /// In ko, this message translates to:
  /// **'영어 이름을 입력하세요'**
  String get profile_err_en_name;

  /// No description provided for @profile_err_shop.
  ///
  /// In ko, this message translates to:
  /// **'샵 이름을 입력하세요'**
  String get profile_err_shop;

  /// No description provided for @gear_title_section.
  ///
  /// In ko, this message translates to:
  /// **'배럴 세팅 (선택)'**
  String get gear_title_section;

  /// No description provided for @gear_player_equipment.
  ///
  /// In ko, this message translates to:
  /// **'플레이어 장비'**
  String get gear_player_equipment;

  /// No description provided for @gear_label_barrel.
  ///
  /// In ko, this message translates to:
  /// **'배럴'**
  String get gear_label_barrel;

  /// No description provided for @gear_label_shaft.
  ///
  /// In ko, this message translates to:
  /// **'샤프트'**
  String get gear_label_shaft;

  /// No description provided for @gear_label_flight.
  ///
  /// In ko, this message translates to:
  /// **'플라이트'**
  String get gear_label_flight;

  /// No description provided for @gear_label_tip.
  ///
  /// In ko, this message translates to:
  /// **'팁'**
  String get gear_label_tip;

  /// No description provided for @auth_btn_change.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get auth_btn_change;

  /// No description provided for @auth_btn_cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get auth_btn_cancel;

  /// No description provided for @auth_hint_code.
  ///
  /// In ko, this message translates to:
  /// **'인증번호 6자리'**
  String get auth_hint_code;

  /// No description provided for @guest_title_edit.
  ///
  /// In ko, this message translates to:
  /// **'방명록 수정'**
  String get guest_title_edit;

  /// No description provided for @guest_hint_input.
  ///
  /// In ko, this message translates to:
  /// **'수정할 내용을 입력하세요...'**
  String get guest_hint_input;

  /// No description provided for @guest_btn_complete.
  ///
  /// In ko, this message translates to:
  /// **'수정 완료'**
  String get guest_btn_complete;

  /// No description provided for @guest_msg_delete_confirm.
  ///
  /// In ko, this message translates to:
  /// **'이 방명록을 삭제하시겠습니까?'**
  String get guest_msg_delete_confirm;

  /// No description provided for @mypage_login_prompt.
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 내 정보를 확인할 수 있어요!'**
  String get mypage_login_prompt;

  /// No description provided for @mypage_profile_needed.
  ///
  /// In ko, this message translates to:
  /// **'프로필 등록이 필요해요!'**
  String get mypage_profile_needed;

  /// No description provided for @mypage_btn_register.
  ///
  /// In ko, this message translates to:
  /// **'프로필 등록하기'**
  String get mypage_btn_register;

  /// No description provided for @mypage_btn_edit.
  ///
  /// In ko, this message translates to:
  /// **'프로필 수정'**
  String get mypage_btn_edit;

  /// No description provided for @mypage_label_email.
  ///
  /// In ko, this message translates to:
  /// **'이메일 없음'**
  String get mypage_label_email;

  /// No description provided for @mypage_btn_logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get mypage_btn_logout;

  /// No description provided for @mypage_btn_delete_acc.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get mypage_btn_delete_acc;

  /// No description provided for @guest_title_my.
  ///
  /// In ko, this message translates to:
  /// **'내 방명록'**
  String get guest_title_my;

  /// No description provided for @guest_title_write.
  ///
  /// In ko, this message translates to:
  /// **'방명록 쓰기'**
  String get guest_title_write;

  /// No description provided for @guest_hint_cheer.
  ///
  /// In ko, this message translates to:
  /// **'응원 메시지 남기기...'**
  String get guest_hint_cheer;

  /// No description provided for @guest_msg_success.
  ///
  /// In ko, this message translates to:
  /// **'방명록이 작성되었습니다'**
  String get guest_msg_success;

  /// No description provided for @notice_title.
  ///
  /// In ko, this message translates to:
  /// **'공지사항'**
  String get notice_title;

  /// No description provided for @notice_empty.
  ///
  /// In ko, this message translates to:
  /// **'공지가 없습니다'**
  String get notice_empty;

  /// No description provided for @delete_acc_confirm_title.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제'**
  String get delete_acc_confirm_title;

  /// No description provided for @delete_acc_confirm_msg.
  ///
  /// In ko, this message translates to:
  /// **'DAO 계정을 삭제하면 모든 데이터가 삭제되며 복구할 수 없습니다. 정말 삭제하시겠습니까?'**
  String get delete_acc_confirm_msg;

  /// No description provided for @report_title.
  ///
  /// In ko, this message translates to:
  /// **'버그/신고'**
  String get report_title;

  /// No description provided for @report_label_title.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get report_label_title;

  /// No description provided for @report_label_content.
  ///
  /// In ko, this message translates to:
  /// **'상세 내용'**
  String get report_label_content;

  /// No description provided for @report_hint_content.
  ///
  /// In ko, this message translates to:
  /// **'상황을 자세히 적어주세요'**
  String get report_hint_content;

  /// No description provided for @report_msg_success.
  ///
  /// In ko, this message translates to:
  /// **'신고가 접수되었습니다. 감사합니다!'**
  String get report_msg_success;

  /// No description provided for @calc_start_prompt.
  ///
  /// In ko, this message translates to:
  /// **'시작 점수를 입력하세요'**
  String get calc_start_prompt;

  /// No description provided for @calc_btn_start.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get calc_btn_start;

  /// No description provided for @calc_remaining_score.
  ///
  /// In ko, this message translates to:
  /// **'남은 점수'**
  String get calc_remaining_score;

  /// No description provided for @calc_this_turn.
  ///
  /// In ko, this message translates to:
  /// **'이번 턴: {score}'**
  String calc_this_turn(Object score);

  /// No description provided for @calc_rec_route.
  ///
  /// In ko, this message translates to:
  /// **'추천 체크아웃 루트'**
  String get calc_rec_route;

  /// No description provided for @calc_alt_route.
  ///
  /// In ko, this message translates to:
  /// **'대안 루트:'**
  String get calc_alt_route;

  /// No description provided for @calc_err_range.
  ///
  /// In ko, this message translates to:
  /// **'2~170 사이의 점수를 입력하세요'**
  String get calc_err_range;

  /// No description provided for @calc_err_overflow.
  ///
  /// In ko, this message translates to:
  /// **'남은 점수보다 클 수 없어요'**
  String get calc_err_overflow;

  /// No description provided for @drill_time_format.
  ///
  /// In ko, this message translates to:
  /// **'~{min}분'**
  String drill_time_format(Object min);

  /// No description provided for @drill_progress_title.
  ///
  /// In ko, this message translates to:
  /// **'진행률'**
  String get drill_progress_title;

  /// No description provided for @drill_stat_darts.
  ///
  /// In ko, this message translates to:
  /// **'다트 수'**
  String get drill_stat_darts;

  /// No description provided for @drill_stat_rounds.
  ///
  /// In ko, this message translates to:
  /// **'라운드'**
  String get drill_stat_rounds;

  /// No description provided for @drill_stat_success.
  ///
  /// In ko, this message translates to:
  /// **'성공률'**
  String get drill_stat_success;

  /// No description provided for @drill_stat_darts_count.
  ///
  /// In ko, this message translates to:
  /// **'{count} / {total} 다트'**
  String drill_stat_darts_count(Object count, Object total);

  /// No description provided for @drill_stat_rounds_count.
  ///
  /// In ko, this message translates to:
  /// **'ROUND {count} / {total}'**
  String drill_stat_rounds_count(Object count, Object total);

  /// No description provided for @drill_panel_target.
  ///
  /// In ko, this message translates to:
  /// **'타겟'**
  String get drill_panel_target;

  /// No description provided for @drill_guide_hit_miss.
  ///
  /// In ko, this message translates to:
  /// **'맞으면 ✅ / 빗나가면 ❌ 버튼을 눌러주세요'**
  String get drill_guide_hit_miss;

  /// No description provided for @drill_btn_success.
  ///
  /// In ko, this message translates to:
  /// **'성공'**
  String get drill_btn_success;

  /// No description provided for @drill_btn_fail.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get drill_btn_fail;

  /// No description provided for @drill_btn_undo_input.
  ///
  /// In ko, this message translates to:
  /// **'이전 입력 되돌리기'**
  String get drill_btn_undo_input;

  /// No description provided for @drill_btn_finish_save.
  ///
  /// In ko, this message translates to:
  /// **'드릴 종료하고 결과 저장'**
  String get drill_btn_finish_save;

  /// No description provided for @drill_unit_marks.
  ///
  /// In ko, this message translates to:
  /// **'마크'**
  String get drill_unit_marks;

  /// No description provided for @drill_unit_points.
  ///
  /// In ko, this message translates to:
  /// **'점'**
  String get drill_unit_points;

  /// No description provided for @drill_confirm_round.
  ///
  /// In ko, this message translates to:
  /// **'이번 라운드 확정 ({val} {unit})'**
  String drill_confirm_round(Object unit, Object val);

  /// No description provided for @drill_btn_undo_round.
  ///
  /// In ko, this message translates to:
  /// **'이전 라운드 되돌리기'**
  String get drill_btn_undo_round;

  /// No description provided for @drill_hint_range.
  ///
  /// In ko, this message translates to:
  /// **'{min} ~ {max} {unit}'**
  String drill_hint_range(Object max, Object min, Object unit);

  /// No description provided for @drill_around_title.
  ///
  /// In ko, this message translates to:
  /// **'싱글 한 바퀴: {count} / {total} 타겟'**
  String drill_around_title(Object count, Object total);

  /// No description provided for @drill_bull_title.
  ///
  /// In ko, this message translates to:
  /// **'Bull {count}발 – SBull / DBull 분리 기록'**
  String drill_bull_title(Object count);

  /// No description provided for @drill_msg_limit_reached.
  ///
  /// In ko, this message translates to:
  /// **'설정된 총 다트 수를 모두 사용했습니다.'**
  String get drill_msg_limit_reached;

  /// No description provided for @drill_msg_no_undo.
  ///
  /// In ko, this message translates to:
  /// **'되돌릴 기록이 없습니다.'**
  String get drill_msg_no_undo;

  /// No description provided for @drill_label_set_count.
  ///
  /// In ko, this message translates to:
  /// **'세트 {current} / {total}'**
  String drill_label_set_count(Object current, Object total);

  /// No description provided for @drill_hint_score_input.
  ///
  /// In ko, this message translates to:
  /// **'맞춘 점수 입력'**
  String get drill_hint_score_input;

  /// No description provided for @drill_target_bull.
  ///
  /// In ko, this message translates to:
  /// **'목표 Bull 적중: {count} / {total}'**
  String drill_target_bull(Object count, Object total);

  /// No description provided for @drill_btn_undo_last.
  ///
  /// In ko, this message translates to:
  /// **'1회 되돌리기'**
  String get drill_btn_undo_last;

  /// No description provided for @drill_stat_bull_rate.
  ///
  /// In ko, this message translates to:
  /// **'Bull 적중률'**
  String get drill_stat_bull_rate;

  /// No description provided for @drill_label_single.
  ///
  /// In ko, this message translates to:
  /// **'싱글'**
  String get drill_label_single;

  /// No description provided for @drill_label_double.
  ///
  /// In ko, this message translates to:
  /// **'더블'**
  String get drill_label_double;

  /// No description provided for @drill_confirm_score.
  ///
  /// In ko, this message translates to:
  /// **'이번 라운드 점수 확정'**
  String get drill_confirm_score;

  /// No description provided for @drill_undo_round.
  ///
  /// In ko, this message translates to:
  /// **'직전 라운드 되돌리기'**
  String get drill_undo_round;

  /// No description provided for @drill_undo_input.
  ///
  /// In ko, this message translates to:
  /// **'방금 입력 되돌리기'**
  String get drill_undo_input;

  /// No description provided for @drill_check_result.
  ///
  /// In ko, this message translates to:
  /// **'결과 확인하기'**
  String get drill_check_result;

  /// No description provided for @drill_current_score.
  ///
  /// In ko, this message translates to:
  /// **'현재까지 총점: {score}점'**
  String drill_current_score(Object score);

  /// No description provided for @drill_clock_title.
  ///
  /// In ko, this message translates to:
  /// **'더블 시계'**
  String get drill_clock_title;

  /// No description provided for @drill_clock_back.
  ///
  /// In ko, this message translates to:
  /// **'(뒤 절반)'**
  String get drill_clock_back;

  /// No description provided for @drill_cricket_8r_title.
  ///
  /// In ko, this message translates to:
  /// **'크리켓 8R 실전 훈련'**
  String get drill_cricket_8r_title;

  /// No description provided for @drill_cricket_free.
  ///
  /// In ko, this message translates to:
  /// **'자유 타겟'**
  String get drill_cricket_free;

  /// No description provided for @drill_cricket_select_hint.
  ///
  /// In ko, this message translates to:
  /// **'아래에서 자유 라운드 타겟을 선택하세요'**
  String get drill_cricket_select_hint;

  /// No description provided for @drill_quadrant_title.
  ///
  /// In ko, this message translates to:
  /// **'이번 구역 진행'**
  String get drill_quadrant_title;

  /// No description provided for @drill_quadrant_guide.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트된 색 구역에 집중해서 던져주세요!'**
  String get drill_quadrant_guide;

  /// No description provided for @drill_t20_focus_title.
  ///
  /// In ko, this message translates to:
  /// **'{target} 집중 연습'**
  String drill_t20_focus_title(Object target);

  /// No description provided for @drill_top_half.
  ///
  /// In ko, this message translates to:
  /// **'상단 영역 집중'**
  String get drill_top_half;

  /// No description provided for @drill_bottom_half.
  ///
  /// In ko, this message translates to:
  /// **'하단 영역 집중'**
  String get drill_bottom_half;

  /// No description provided for @drill_hint_round_score.
  ///
  /// In ko, this message translates to:
  /// **'이번 라운드 점수 (0~180)'**
  String get drill_hint_round_score;

  /// No description provided for @drill_err_only_number.
  ///
  /// In ko, this message translates to:
  /// **'숫자만 입력할 수 있습니다.'**
  String get drill_err_only_number;

  /// No description provided for @drill_err_score_range.
  ///
  /// In ko, this message translates to:
  /// **'0 ~ 180점 사이로 입력해 주세요.'**
  String get drill_err_score_range;

  /// No description provided for @drill_msg_all_used.
  ///
  /// In ko, this message translates to:
  /// **'설정된 총 다트 수를 모두 사용했습니다.'**
  String get drill_msg_all_used;

  /// No description provided for @result_title.
  ///
  /// In ko, this message translates to:
  /// **'연습 결과'**
  String get result_title;

  /// No description provided for @result_xp_title.
  ///
  /// In ko, this message translates to:
  /// **'이번 세션 XP'**
  String get result_xp_title;

  /// No description provided for @result_xp_desc.
  ///
  /// In ko, this message translates to:
  /// **'이번 연습으로 획득한 경험치입니다.'**
  String get result_xp_desc;

  /// No description provided for @result_summary_title.
  ///
  /// In ko, this message translates to:
  /// **'세션 요약'**
  String get result_summary_title;

  /// No description provided for @result_stat_attempts.
  ///
  /// In ko, this message translates to:
  /// **'총 시도'**
  String get result_stat_attempts;

  /// No description provided for @result_stat_duration.
  ///
  /// In ko, this message translates to:
  /// **'소요 시간'**
  String get result_stat_duration;

  /// No description provided for @result_growth_point.
  ///
  /// In ko, this message translates to:
  /// **'성장 포인트'**
  String get result_growth_point;

  /// No description provided for @result_time_min.
  ///
  /// In ko, this message translates to:
  /// **'분'**
  String get result_time_min;

  /// No description provided for @result_time_sec.
  ///
  /// In ko, this message translates to:
  /// **'초'**
  String get result_time_sec;

  /// No description provided for @finish_btn_success_1.
  ///
  /// In ko, this message translates to:
  /// **'1다트 성공'**
  String get finish_btn_success_1;

  /// No description provided for @finish_btn_success_2.
  ///
  /// In ko, this message translates to:
  /// **'2다트 성공'**
  String get finish_btn_success_2;

  /// No description provided for @finish_btn_success_3.
  ///
  /// In ko, this message translates to:
  /// **'3다트 성공'**
  String get finish_btn_success_3;

  /// No description provided for @finish_btn_fail_prob.
  ///
  /// In ko, this message translates to:
  /// **'이번 문제 실패'**
  String get finish_btn_fail_prob;

  /// No description provided for @finish_remaining_title.
  ///
  /// In ko, this message translates to:
  /// **'현재 남은 점수'**
  String get finish_remaining_title;

  /// No description provided for @finish_this_turn.
  ///
  /// In ko, this message translates to:
  /// **'이번 턴'**
  String get finish_this_turn;

  /// No description provided for @rank_mini_title.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 랭킹'**
  String get rank_mini_title;

  /// No description provided for @rank_stat_score.
  ///
  /// In ko, this message translates to:
  /// **'점수'**
  String get rank_stat_score;

  /// No description provided for @rank_stat_optimal.
  ///
  /// In ko, this message translates to:
  /// **'최적'**
  String get rank_stat_optimal;

  /// No description provided for @rank_stat_route.
  ///
  /// In ko, this message translates to:
  /// **'정석'**
  String get rank_stat_route;

  /// No description provided for @record_none_start.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록 없음 지금 시작하세요!'**
  String get record_none_start;

  /// No description provided for @record_login_needed.
  ///
  /// In ko, this message translates to:
  /// **'로그인 필요'**
  String get record_login_needed;

  /// No description provided for @finish_home_title.
  ///
  /// In ko, this message translates to:
  /// **'피니시 루트 연습'**
  String get finish_home_title;

  /// No description provided for @finish_promo_title.
  ///
  /// In ko, this message translates to:
  /// **'랜덤 10문제 피니시 루트 연습'**
  String get finish_promo_title;

  /// No description provided for @finish_promo_desc.
  ///
  /// In ko, this message translates to:
  /// **'다트보드를 터치해서 점수를 0으로 만드세요. 더블/불로 마무리해야 합니다.'**
  String get finish_promo_desc;

  /// No description provided for @finish_btn_start.
  ///
  /// In ko, this message translates to:
  /// **'연습 시작하기'**
  String get finish_btn_start;

  /// No description provided for @finish_btn_login_start.
  ///
  /// In ko, this message translates to:
  /// **'로그인 후 연습 시작'**
  String get finish_btn_login_start;

  /// No description provided for @finish_msg_login_rank.
  ///
  /// In ko, this message translates to:
  /// **'로그인하면 내 기록 저장 / 랭킹 참가가 가능해요'**
  String get finish_msg_login_rank;

  /// No description provided for @finish_hint_title.
  ///
  /// In ko, this message translates to:
  /// **'추천 피니시 루트'**
  String get finish_hint_title;

  /// No description provided for @finish_msg_touch_board.
  ///
  /// In ko, this message translates to:
  /// **'다트보드를 눌러 입력하세요'**
  String get finish_msg_touch_board;

  /// No description provided for @finish_msg_bust_guide.
  ///
  /// In ko, this message translates to:
  /// **'BUST! ‘확인’ 버튼을 눌러 다음 문제로 넘어가세요.'**
  String get finish_msg_bust_guide;

  /// No description provided for @finish_msg_done_guide.
  ///
  /// In ko, this message translates to:
  /// **'마무리! ‘확인’ 버튼을 눌러 다음 문제로'**
  String get finish_msg_done_guide;

  /// No description provided for @finish_msg_optimal_pace.
  ///
  /// In ko, this message translates to:
  /// **'최적! {count}다트 페이스'**
  String finish_msg_optimal_pace(Object count);

  /// No description provided for @finish_result_title.
  ///
  /// In ko, this message translates to:
  /// **'피니시 루트 결과'**
  String get finish_result_title;

  /// No description provided for @finish_stat_total_time.
  ///
  /// In ko, this message translates to:
  /// **'총 소요 시간'**
  String get finish_stat_total_time;

  /// No description provided for @finish_stat_avg_darts.
  ///
  /// In ko, this message translates to:
  /// **'평균 다트'**
  String get finish_stat_avg_darts;

  /// No description provided for @finish_stat_optimal_rate.
  ///
  /// In ko, this message translates to:
  /// **'최적 다트율'**
  String get finish_stat_optimal_rate;

  /// No description provided for @finish_stat_route_rate.
  ///
  /// In ko, this message translates to:
  /// **'정석 루트율'**
  String get finish_stat_route_rate;

  /// No description provided for @finish_msg_optimal_success.
  ///
  /// In ko, this message translates to:
  /// **'최적 다트 수로 성공!'**
  String get finish_msg_optimal_success;

  /// No description provided for @finish_msg_optimal_hint.
  ///
  /// In ko, this message translates to:
  /// **'성공했지만 최적 다트 수는 {count}다트입니다.'**
  String finish_msg_optimal_hint(Object count);

  /// No description provided for @grip_metric_pinch.
  ///
  /// In ko, this message translates to:
  /// **'핀치 갭'**
  String get grip_metric_pinch;

  /// No description provided for @grip_metric_flexion.
  ///
  /// In ko, this message translates to:
  /// **'검지 굴곡'**
  String get grip_metric_flexion;

  /// No description provided for @grip_save_date.
  ///
  /// In ko, this message translates to:
  /// **'저장일: {date}'**
  String grip_save_date(Object date);

  /// No description provided for @grip_frame_label.
  ///
  /// In ko, this message translates to:
  /// **'Frame {id}'**
  String grip_frame_label(Object id);

  /// No description provided for @grip_img_load_fail.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 불러올 수 없어요'**
  String get grip_img_load_fail;

  /// No description provided for @grip_cam_unsupported.
  ///
  /// In ko, this message translates to:
  /// **'이 플랫폼에서는 그립 카메라를 지원하지 않습니다: {platform}'**
  String grip_cam_unsupported(Object platform);

  /// No description provided for @grip_label_tight.
  ///
  /// In ko, this message translates to:
  /// **'좁음'**
  String get grip_label_tight;

  /// No description provided for @grip_label_wide.
  ///
  /// In ko, this message translates to:
  /// **'넓음'**
  String get grip_label_wide;

  /// No description provided for @grip_label_extended.
  ///
  /// In ko, this message translates to:
  /// **'펴짐'**
  String get grip_label_extended;

  /// No description provided for @grip_label_curved.
  ///
  /// In ko, this message translates to:
  /// **'굽힘'**
  String get grip_label_curved;

  /// No description provided for @grip_home_title.
  ///
  /// In ko, this message translates to:
  /// **'그립 연구소'**
  String get grip_home_title;

  /// No description provided for @grip_home_desc.
  ///
  /// In ko, this message translates to:
  /// **'가장 좋았던 그립을 저장하고, 매일 그 감각을 맞춰보세요.'**
  String get grip_home_desc;

  /// No description provided for @grip_status_exists.
  ///
  /// In ko, this message translates to:
  /// **'기준 그립이 저장되어 있습니다.'**
  String get grip_status_exists;

  /// No description provided for @grip_status_empty.
  ///
  /// In ko, this message translates to:
  /// **'아직 기준 그립이 없습니다.'**
  String get grip_status_empty;

  /// No description provided for @grip_btn_compare.
  ///
  /// In ko, this message translates to:
  /// **'비교/교정 하기'**
  String get grip_btn_compare;

  /// No description provided for @grip_btn_take_new.
  ///
  /// In ko, this message translates to:
  /// **'새로 촬영하기'**
  String get grip_btn_take_new;

  /// No description provided for @grip_guide_title.
  ///
  /// In ko, this message translates to:
  /// **'그립 촬영 가이드'**
  String get grip_guide_title;

  /// No description provided for @grip_guide_desc.
  ///
  /// In ko, this message translates to:
  /// **'정확한 그립 분석을 위해 다음 사항을 확인해 주세요.'**
  String get grip_guide_desc;

  /// No description provided for @grip_guide_good.
  ///
  /// In ko, this message translates to:
  /// **'Good: 권장하는 촬영 방법'**
  String get grip_guide_good;

  /// No description provided for @grip_guide_bad.
  ///
  /// In ko, this message translates to:
  /// **'Bad: 피해야 할 촬영 방법'**
  String get grip_guide_bad;

  /// No description provided for @grip_cam_hint.
  ///
  /// In ko, this message translates to:
  /// **'엄지와 검지를 + 중심에 맞추고 가로선을 보며 수평을 확인하세요'**
  String get grip_cam_hint;

  /// No description provided for @grip_msg_hand_detect.
  ///
  /// In ko, this message translates to:
  /// **'손이 인식된 상태에서만 촬영할 수 있어요.'**
  String get grip_msg_hand_detect;

  /// No description provided for @grip_msg_stabilizing.
  ///
  /// In ko, this message translates to:
  /// **'시스템 안정화 중입니다. {sec}초만 기다려주세요.'**
  String grip_msg_stabilizing(Object sec);

  /// No description provided for @grip_report_title.
  ///
  /// In ko, this message translates to:
  /// **'그립 분석 리포트'**
  String get grip_report_title;

  /// No description provided for @grip_ai_result.
  ///
  /// In ko, this message translates to:
  /// **'AI 그립 분석 결과'**
  String get grip_ai_result;

  /// No description provided for @grip_metric_middle.
  ///
  /// In ko, this message translates to:
  /// **'중지 받침 각도'**
  String get grip_metric_middle;

  /// No description provided for @grip_metric_ring.
  ///
  /// In ko, this message translates to:
  /// **'약지 굽힘'**
  String get grip_metric_ring;

  /// No description provided for @grip_metric_pinky.
  ///
  /// In ko, this message translates to:
  /// **'소지 밸런스'**
  String get grip_metric_pinky;

  /// No description provided for @grip_msg_mirror.
  ///
  /// In ko, this message translates to:
  /// **'기준 뼈대를 반전합니다 (거울 모드)'**
  String get grip_msg_mirror;

  /// No description provided for @hist_title.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝 히스토리'**
  String get hist_title;

  /// No description provided for @hist_chart_title.
  ///
  /// In ko, this message translates to:
  /// **'성장 추이 (하루 평균, 최근 7일)'**
  String get hist_chart_title;

  /// No description provided for @hist_chart_goal.
  ///
  /// In ko, this message translates to:
  /// **'목표 명중률 70%'**
  String get hist_chart_goal;

  /// No description provided for @hist_tab_trend.
  ///
  /// In ko, this message translates to:
  /// **'추이'**
  String get hist_tab_trend;

  /// No description provided for @hist_tab_list.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get hist_tab_list;

  /// No description provided for @hist_filter_all.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get hist_filter_all;

  /// No description provided for @hist_filter_cycle.
  ///
  /// In ko, this message translates to:
  /// **'사이클 {n}'**
  String hist_filter_cycle(Object n);

  /// No description provided for @hist_tip_delete.
  ///
  /// In ko, this message translates to:
  /// **'Tip. 목록을 길게 누르면 기록을 삭제할 수 있어요.'**
  String get hist_tip_delete;

  /// No description provided for @stat_avg_hitrate.
  ///
  /// In ko, this message translates to:
  /// **'평균 명중률'**
  String get stat_avg_hitrate;

  /// No description provided for @stat_max_ppd.
  ///
  /// In ko, this message translates to:
  /// **'최고 PPD'**
  String get stat_max_ppd;

  /// No description provided for @stat_total_time.
  ///
  /// In ko, this message translates to:
  /// **'총 걸린 시간'**
  String get stat_total_time;

  /// No description provided for @stat_success_attempt.
  ///
  /// In ko, this message translates to:
  /// **'성공 / 시도'**
  String get stat_success_attempt;

  /// No description provided for @detail_meta_id.
  ///
  /// In ko, this message translates to:
  /// **'드릴 ID'**
  String get detail_meta_id;

  /// No description provided for @detail_growth_gauge.
  ///
  /// In ko, this message translates to:
  /// **'성장 게이지'**
  String get detail_growth_gauge;

  /// No description provided for @detail_msg_no_record.
  ///
  /// In ko, this message translates to:
  /// **'아직 연습 기록이 없어요.'**
  String get detail_msg_no_record;

  /// No description provided for @ai_summary_improved.
  ///
  /// In ko, this message translates to:
  /// **'이전 세션보다 분명히 나아졌어요!'**
  String get ai_summary_improved;

  /// No description provided for @ai_summary_stable.
  ///
  /// In ko, this message translates to:
  /// **'내 평균 페이스를 찾고 있다는 신호예요.'**
  String get ai_summary_stable;

  /// No description provided for @ai_summary_first.
  ///
  /// In ko, this message translates to:
  /// **'앞으로 성장 그래프와 히스토리공가 쌓이게 돼요.'**
  String get ai_summary_first;

  /// No description provided for @pose_guide_title.
  ///
  /// In ko, this message translates to:
  /// **'촬영 가이드'**
  String get pose_guide_title;

  /// No description provided for @pose_guide_desc.
  ///
  /// In ko, this message translates to:
  /// **'정확한 분석을 위해 다음 사항을 확인해 주세요.'**
  String get pose_guide_desc;

  /// No description provided for @pose_setting_title.
  ///
  /// In ko, this message translates to:
  /// **'분석 설정'**
  String get pose_setting_title;

  /// No description provided for @pose_change_video.
  ///
  /// In ko, this message translates to:
  /// **'영상 변경'**
  String get pose_change_video;

  /// No description provided for @pose_tip_title.
  ///
  /// In ko, this message translates to:
  /// **'정확한 분석을 위한 팁'**
  String get pose_tip_title;

  /// No description provided for @pose_select_part.
  ///
  /// In ko, this message translates to:
  /// **'추적 부위 선택'**
  String get pose_select_part;

  /// No description provided for @pose_skeleton_color.
  ///
  /// In ko, this message translates to:
  /// **'뼈대 색상'**
  String get pose_skeleton_color;

  /// No description provided for @pose_btn_start.
  ///
  /// In ko, this message translates to:
  /// **'분석 시작'**
  String get pose_btn_start;

  /// No description provided for @pose_msg_analyzing.
  ///
  /// In ko, this message translates to:
  /// **'자세를 분석 중입니다'**
  String get pose_msg_analyzing;

  /// No description provided for @pose_msg_elapsed.
  ///
  /// In ko, this message translates to:
  /// **'소요 시간: {sec}초'**
  String pose_msg_elapsed(Object sec);

  /// No description provided for @pose_msg_ai_frame.
  ///
  /// In ko, this message translates to:
  /// **'AI가 영상을 프레임 단위로 분석하고 있습니다.'**
  String get pose_msg_ai_frame;

  /// No description provided for @pose_msg_rendering.
  ///
  /// In ko, this message translates to:
  /// **'영상 생성 중'**
  String get pose_msg_rendering;

  /// No description provided for @pose_step_extract.
  ///
  /// In ko, this message translates to:
  /// **'프레임 추출 중...'**
  String get pose_step_extract;

  /// No description provided for @pose_step_skeleton.
  ///
  /// In ko, this message translates to:
  /// **'AI 뼈대 분석 중...'**
  String get pose_step_skeleton;

  /// No description provided for @pose_step_encoding.
  ///
  /// In ko, this message translates to:
  /// **'영상 인코딩 중...'**
  String get pose_step_encoding;

  /// No description provided for @pose_result_title.
  ///
  /// In ko, this message translates to:
  /// **'분석 결과'**
  String get pose_result_title;

  /// No description provided for @pose_guide_line.
  ///
  /// In ko, this message translates to:
  /// **'기준선 가이드 (팔꿈치/손목)'**
  String get pose_guide_line;

  /// No description provided for @pose_show_track.
  ///
  /// In ko, this message translates to:
  /// **'트래킹 궤적 보기'**
  String get pose_show_track;

  /// No description provided for @pose_show_release.
  ///
  /// In ko, this message translates to:
  /// **'릴리즈 포인트 보기'**
  String get pose_show_release;

  /// No description provided for @pose_ai_title.
  ///
  /// In ko, this message translates to:
  /// **'AI 자세 분석 결과'**
  String get pose_ai_title;

  /// No description provided for @pose_dist_notice.
  ///
  /// In ko, this message translates to:
  /// **'엄지 손톱 끝과 검지 손톱 끝 사이의 직선 거리를 비교합니다.'**
  String get pose_dist_notice;

  /// No description provided for @pose_btn_save.
  ///
  /// In ko, this message translates to:
  /// **'영상 저장'**
  String get pose_btn_save;

  /// No description provided for @pose_main_title.
  ///
  /// In ko, this message translates to:
  /// **'내 스로우, 분석하기.'**
  String get pose_main_title;

  /// No description provided for @pose_main_headline.
  ///
  /// In ko, this message translates to:
  /// **'내 스로우, 분석하기.'**
  String get pose_main_headline;

  /// No description provided for @pose_main_desc.
  ///
  /// In ko, this message translates to:
  /// **'영상을 업로드하면 뼈대와 궤적을 추적하여 시각적으로 분석해 드립니다.'**
  String get pose_main_desc;

  /// No description provided for @pose_btn_select_video.
  ///
  /// In ko, this message translates to:
  /// **'영상 선택하기'**
  String get pose_btn_select_video;

  /// No description provided for @pose_feat_skeleton_title.
  ///
  /// In ko, this message translates to:
  /// **'스켈레톤(뼈대) 분석'**
  String get pose_feat_skeleton_title;

  /// No description provided for @pose_feat_skeleton_desc.
  ///
  /// In ko, this message translates to:
  /// **'어깨, 팔꿈치, 손목의 움직임을 뼈대로 시각화합니다.'**
  String get pose_feat_skeleton_desc;

  /// No description provided for @pose_feat_track_title.
  ///
  /// In ko, this message translates to:
  /// **'손목 궤적 트래킹'**
  String get pose_feat_track_title;

  /// No description provided for @pose_feat_track_desc.
  ///
  /// In ko, this message translates to:
  /// **'릴리즈 순간의 손목 이동 경로를 선으로 그려줍니다.'**
  String get pose_feat_track_desc;

  /// No description provided for @pose_feat_diag_title.
  ///
  /// In ko, this message translates to:
  /// **'프레임 단위 정밀 진단'**
  String get pose_feat_diag_title;

  /// No description provided for @pose_feat_diag_desc.
  ///
  /// In ko, this message translates to:
  /// **'30FPS 고화질 분석으로 미세한 흔들림까지 확인하세요.'**
  String get pose_feat_diag_desc;

  /// No description provided for @pose_label_set.
  ///
  /// In ko, this message translates to:
  /// **'셋업'**
  String get pose_label_set;

  /// No description provided for @pose_label_release.
  ///
  /// In ko, this message translates to:
  /// **'릴리즈 {n}'**
  String pose_label_release(Object n);

  /// No description provided for @report_header.
  ///
  /// In ko, this message translates to:
  /// **'DAO 트레이닝 리포트'**
  String get report_header;

  /// No description provided for @report_this_result.
  ///
  /// In ko, this message translates to:
  /// **'이번 결과 ({metric})'**
  String report_this_result(Object metric);

  /// No description provided for @report_prev_best.
  ///
  /// In ko, this message translates to:
  /// **'이전 최고 ({metric})'**
  String report_prev_best(Object metric);

  /// No description provided for @report_xp_earned.
  ///
  /// In ko, this message translates to:
  /// **'이번 세션으로 획득한 XP'**
  String get report_xp_earned;

  /// No description provided for @report_goal_standard.
  ///
  /// In ko, this message translates to:
  /// **'이번 회차 목표: {xp} XP 기준'**
  String report_goal_standard(Object xp);

  /// No description provided for @report_gauge_max.
  ///
  /// In ko, this message translates to:
  /// **'성장 게이지 MAX! 레벨 재평가 시점이에요.'**
  String get report_gauge_max;

  /// No description provided for @tier_test_title.
  ///
  /// In ko, this message translates to:
  /// **'보드 마킹 레벨 테스트'**
  String get tier_test_title;

  /// No description provided for @tier_test_desc.
  ///
  /// In ko, this message translates to:
  /// **'1번부터 20번까지 순서대로 명중하며,\n총 몇 발이 들었는지 입력해주세요.'**
  String get tier_test_desc;

  /// No description provided for @tier_test_input_label.
  ///
  /// In ko, this message translates to:
  /// **'총 사용한 다트 수'**
  String get tier_test_input_label;

  /// No description provided for @tier_test_btn_confirm.
  ///
  /// In ko, this message translates to:
  /// **'DAO 티어 확정하기'**
  String get tier_test_btn_confirm;

  /// No description provided for @tier_test_err_too_many.
  ///
  /// In ko, this message translates to:
  /// **'너무 많은 다트 수입니다. 다시 확인해주세요'**
  String get tier_test_err_too_many;

  /// No description provided for @tier_predict_label.
  ///
  /// In ko, this message translates to:
  /// **'예상 DAO 티어'**
  String get tier_predict_label;

  /// No description provided for @drill_rec_start.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get drill_rec_start;

  /// No description provided for @drill_rec_done.
  ///
  /// In ko, this message translates to:
  /// **'오늘 완료'**
  String get drill_rec_done;

  /// No description provided for @drill_stat_hit_count.
  ///
  /// In ko, this message translates to:
  /// **'명중 수'**
  String get drill_stat_hit_count;

  /// No description provided for @train_home_title.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝'**
  String get train_home_title;

  /// No description provided for @train_current_tier.
  ///
  /// In ko, this message translates to:
  /// **'현재 DAO 티어 · {tier}'**
  String train_current_tier(Object tier);

  /// No description provided for @train_btn_edit_rating.
  ///
  /// In ko, this message translates to:
  /// **'레이팅 수정하기'**
  String get train_btn_edit_rating;

  /// No description provided for @train_btn_reset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get train_btn_reset;

  /// No description provided for @train_msg_gauge_full.
  ///
  /// In ko, this message translates to:
  /// **'🔥 성장 게이지 100% 달성!'**
  String get train_msg_gauge_full;

  /// No description provided for @train_msg_gauge_desc.
  ///
  /// In ko, this message translates to:
  /// **'훈련을 통해 성장 게이지가 가득 찼어요. 실력을 다시 측정해볼까요?'**
  String get train_msg_gauge_desc;

  /// No description provided for @train_msg_rating_notice.
  ///
  /// In ko, this message translates to:
  /// **'※ 실제 기기 레이팅과는 약간의 오차가 있을 수 있습니다.'**
  String get train_msg_rating_notice;

  /// No description provided for @rating_input_title.
  ///
  /// In ko, this message translates to:
  /// **'실력 입력'**
  String get rating_input_title;

  /// No description provided for @rating_tab_phoenix.
  ///
  /// In ko, this message translates to:
  /// **'PHOENIX'**
  String get rating_tab_phoenix;

  /// No description provided for @rating_tab_live.
  ///
  /// In ko, this message translates to:
  /// **'DARTSLIVE'**
  String get rating_tab_live;

  /// No description provided for @rating_guide_desc.
  ///
  /// In ko, this message translates to:
  /// **'PPD와 MPR을 모두 입력하면 가장 정확합니다.\n하나만 입력해도 대략적인 값을 계산합니다.'**
  String get rating_guide_desc;

  /// No description provided for @rating_preview_title.
  ///
  /// In ko, this message translates to:
  /// **'실시간 계산 결과'**
  String get rating_preview_title;

  /// No description provided for @rating_msg_min_input.
  ///
  /// In ko, this message translates to:
  /// **'최소 한 가지 값을 입력해주세요.'**
  String get rating_msg_min_input;

  /// No description provided for @train_rec_title.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 추천 연습'**
  String get train_rec_title;

  /// No description provided for @train_rec_desc.
  ///
  /// In ko, this message translates to:
  /// **'티어에 맞는 드릴로 워밍업을 시작해보세요.'**
  String get train_rec_desc;

  /// No description provided for @train_tools_title.
  ///
  /// In ko, this message translates to:
  /// **'훈련 도구'**
  String get train_tools_title;

  /// No description provided for @train_tool_pose.
  ///
  /// In ko, this message translates to:
  /// **'자세분석 & 트래킹'**
  String get train_tool_pose;

  /// No description provided for @train_tool_grip.
  ///
  /// In ko, this message translates to:
  /// **'그립 연구소'**
  String get train_tool_grip;

  /// No description provided for @train_tool_mylog.
  ///
  /// In ko, this message translates to:
  /// **'나만의 다트 이야기'**
  String get train_tool_mylog;

  /// No description provided for @admin_delete_title.
  ///
  /// In ko, this message translates to:
  /// **'삭제 확인'**
  String get admin_delete_title;

  /// No description provided for @admin_delete_msg.
  ///
  /// In ko, this message translates to:
  /// **'이 게시물을 완전히 삭제하시겠습니까? 삭제된 데이터는 복구할 수 없습니다.'**
  String get admin_delete_msg;

  /// No description provided for @admin_mode_label.
  ///
  /// In ko, this message translates to:
  /// **'관리자 모드'**
  String get admin_mode_label;

  /// No description provided for @ad_status_loading.
  ///
  /// In ko, this message translates to:
  /// **'광고를 불러오는 중입니다...'**
  String get ad_status_loading;

  /// No description provided for @ad_status_ready.
  ///
  /// In ko, this message translates to:
  /// **'광고 준비 중'**
  String get ad_status_ready;

  /// No description provided for @profile_go_guestbook.
  ///
  /// In ko, this message translates to:
  /// **'내 방명록 가기'**
  String get profile_go_guestbook;

  /// No description provided for @profile_write_guestbook.
  ///
  /// In ko, this message translates to:
  /// **'방명록 쓰러 가기'**
  String get profile_write_guestbook;

  /// No description provided for @svc_msg_save_gal.
  ///
  /// In ko, this message translates to:
  /// **'갤러리 저장 완료: DAO Darts 앨범'**
  String get svc_msg_save_gal;

  /// No description provided for @svc_msg_no_gal_perm.
  ///
  /// In ko, this message translates to:
  /// **'갤러리 접근 권한이 거부되었습니다'**
  String get svc_msg_no_gal_perm;

  /// No description provided for @svc_msg_upload_fail.
  ///
  /// In ko, this message translates to:
  /// **'사진 업로드에 실패했습니다'**
  String get svc_msg_upload_fail;

  /// No description provided for @svc_msg_rendering_prep.
  ///
  /// In ko, this message translates to:
  /// **'영상 분석 준비 중...'**
  String get svc_msg_rendering_prep;

  /// No description provided for @svc_msg_save_complete.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에 저장되었습니다!'**
  String get svc_msg_save_complete;

  /// No description provided for @status_online_none.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get status_online_none;

  /// No description provided for @status_ad_suspended.
  ///
  /// In ko, this message translates to:
  /// **'광고 기능이 비활성화되었습니다.'**
  String get status_ad_suspended;

  /// No description provided for @ui_btn_later.
  ///
  /// In ko, this message translates to:
  /// **'나중에 하기'**
  String get ui_btn_later;

  /// No description provided for @ui_label_participants.
  ///
  /// In ko, this message translates to:
  /// **'참가자 명단'**
  String get ui_label_participants;

  /// No description provided for @ui_msg_init_ad.
  ///
  /// In ko, this message translates to:
  /// **'AdMob 초기화 중'**
  String get ui_msg_init_ad;

  /// No description provided for @home_welcome_msg.
  ///
  /// In ko, this message translates to:
  /// **'DAO에 오신 것을 환영합니다!'**
  String get home_welcome_msg;

  /// No description provided for @home_title_magazine_ko.
  ///
  /// In ko, this message translates to:
  /// **'한국 다트 소식'**
  String get home_title_magazine_ko;

  /// No description provided for @home_title_magazine_global.
  ///
  /// In ko, this message translates to:
  /// **'해외 다트 소식'**
  String get home_title_magazine_global;

  /// No description provided for @home_title_official_calendar.
  ///
  /// In ko, this message translates to:
  /// **'공식 대회 일정'**
  String get home_title_official_calendar;

  /// No description provided for @home_msg_no_calendar.
  ///
  /// In ko, this message translates to:
  /// **'등록된 공식 일정이 없습니다.'**
  String get home_msg_no_calendar;

  /// No description provided for @home_language_setting.
  ///
  /// In ko, this message translates to:
  /// **'언어 설정 (Language)'**
  String get home_language_setting;

  /// No description provided for @home_msg_lang_changing.
  ///
  /// In ko, this message translates to:
  /// **'로 변경 중...'**
  String get home_msg_lang_changing;

  /// No description provided for @home_msg_profile_needed.
  ///
  /// In ko, this message translates to:
  /// **'로그인 후 프로필을 등록해 주세요.'**
  String get home_msg_profile_needed;

  /// No description provided for @home_msg_profile_register.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 등록해 주세요!'**
  String get home_msg_profile_register;

  /// No description provided for @effect_congrats_title.
  ///
  /// In ko, this message translates to:
  /// **'축하합니다!'**
  String get effect_congrats_title;

  /// No description provided for @effect_perfect_score.
  ///
  /// In ko, this message translates to:
  /// **'완벽한 기록이에요! 🎯'**
  String get effect_perfect_score;

  /// No description provided for @effect_new_record.
  ///
  /// In ko, this message translates to:
  /// **'개인 최고 기록을 경신했습니다! 🎉'**
  String get effect_new_record;

  /// No description provided for @effect_cycle_complete.
  ///
  /// In ko, this message translates to:
  /// **'한 사이클을 멋지게 마쳤습니다.'**
  String get effect_cycle_complete;

  /// No description provided for @effect_epic_success.
  ///
  /// In ko, this message translates to:
  /// **'경이로운 기록입니다! 🎆'**
  String get effect_epic_success;

  /// No description provided for @effect_tier_up.
  ///
  /// In ko, this message translates to:
  /// **'티어가 상승했습니다! 축하합니다!'**
  String get effect_tier_up;

  /// No description provided for @effect_master_clear.
  ///
  /// In ko, this message translates to:
  /// **'마스터 레벨을 완벽하게 마스터했습니다!'**
  String get effect_master_clear;

  /// No description provided for @effect_legendary_darts.
  ///
  /// In ko, this message translates to:
  /// **'당신은 전설입니다! 🎯'**
  String get effect_legendary_darts;

  /// No description provided for @effect_hit_perfect.
  ///
  /// In ko, this message translates to:
  /// **'완벽해요!'**
  String get effect_hit_perfect;

  /// No description provided for @effect_hit_nice.
  ///
  /// In ko, this message translates to:
  /// **'나이스 샷!'**
  String get effect_hit_nice;

  /// No description provided for @effect_hit_cool.
  ///
  /// In ko, this message translates to:
  /// **'멋집니다!'**
  String get effect_hit_cool;

  /// No description provided for @effect_hit_combo.
  ///
  /// In ko, this message translates to:
  /// **'{count} 콤보 달성!'**
  String effect_hit_combo(Object count);

  /// No description provided for @program_title_program_beginner_4w.
  ///
  /// In ko, this message translates to:
  /// **'비기너 4주 기초 프로그램'**
  String get program_title_program_beginner_4w;

  /// No description provided for @program_desc_program_beginner_4w.
  ///
  /// In ko, this message translates to:
  /// **'보드를 4분할/상·하로 나눠 던져 보고, 숫자 한 바퀴와 S20·Bull·Count-Up까지 기초 감각을 쌓는 과정입니다.'**
  String get program_desc_program_beginner_4w;

  /// No description provided for @program_title_program_learner_4w.
  ///
  /// In ko, this message translates to:
  /// **'러너 4주 컨트롤 프로그램'**
  String get program_title_program_learner_4w;

  /// No description provided for @program_desc_program_learner_4w.
  ///
  /// In ko, this message translates to:
  /// **'싱글 20 명중률과 상·하 컨트롤, 섹터 루프를 통해 실전 스코어링의 기본 발판을 만드는 과정입니다.'**
  String get program_desc_program_learner_4w;

  /// No description provided for @drill_title_beginner_quadrant_basic.
  ///
  /// In ko, this message translates to:
  /// **'4분할 감각 만들기'**
  String get drill_title_beginner_quadrant_basic;

  /// No description provided for @drill_desc_beginner_quadrant_basic.
  ///
  /// In ko, this message translates to:
  /// **'보드를 4구역으로 나눠 방향·거리 감각을 만드는 입문 드릴'**
  String get drill_desc_beginner_quadrant_basic;

  /// No description provided for @drill_target_beginner_quadrant_basic.
  ///
  /// In ko, this message translates to:
  /// **'우상단 / 우하단 / 좌하단 / 좌상단'**
  String get drill_target_beginner_quadrant_basic;

  /// No description provided for @drill_guide_beginner_quadrant_basic.
  ///
  /// In ko, this message translates to:
  /// **'보드를 4구역으로 나누고 지시하는 구역에 던지세요. 1구역당 15발씩 진행합니다.'**
  String get drill_guide_beginner_quadrant_basic;

  /// No description provided for @drill_title_beginner_top_bottom_basic.
  ///
  /// In ko, this message translates to:
  /// **'상단/하단 영역 익히기'**
  String get drill_title_beginner_top_bottom_basic;

  /// No description provided for @drill_desc_beginner_top_bottom_basic.
  ///
  /// In ko, this message translates to:
  /// **'상단/하단 큰 영역을 목표로 던져보며 방향 감각을 만든다.'**
  String get drill_desc_beginner_top_bottom_basic;

  /// No description provided for @drill_target_beginner_top_bottom_basic.
  ///
  /// In ko, this message translates to:
  /// **'상단 / 하단'**
  String get drill_target_beginner_top_bottom_basic;

  /// No description provided for @drill_guide_beginner_top_bottom_basic.
  ///
  /// In ko, this message translates to:
  /// **'보드를 상/하로 나누어 각 영역에 30발씩 던지며 감각을 익힙니다.'**
  String get drill_guide_beginner_top_bottom_basic;

  /// No description provided for @drill_title_beginner_around_board_single.
  ///
  /// In ko, this message translates to:
  /// **'싱글 한 바퀴'**
  String get drill_title_beginner_around_board_single;

  /// No description provided for @drill_desc_beginner_around_board_single.
  ///
  /// In ko, this message translates to:
  /// **'1→20→SB까지 싱글을 한 바퀴 도는 기초 드릴'**
  String get drill_desc_beginner_around_board_single;

  /// No description provided for @drill_target_beginner_around_board_single.
  ///
  /// In ko, this message translates to:
  /// **'1~20 + SB'**
  String get drill_target_beginner_around_board_single;

  /// No description provided for @drill_guide_beginner_around_board_single.
  ///
  /// In ko, this message translates to:
  /// **'1부터 SB까지 순서대로 명중시키며 완주에 필요한 다트 수를 줄여보세요.'**
  String get drill_guide_beginner_around_board_single;

  /// No description provided for @drill_title_beginner_large_single_20.
  ///
  /// In ko, this message translates to:
  /// **'Large Single 20 입문'**
  String get drill_title_beginner_large_single_20;

  /// No description provided for @drill_desc_beginner_large_single_20.
  ///
  /// In ko, this message translates to:
  /// **'S20 큰 영역에 안정적으로 맞추는 감각을 만드는 입문 스코어링 드릴'**
  String get drill_desc_beginner_large_single_20;

  /// No description provided for @drill_target_beginner_large_single_20.
  ///
  /// In ko, this message translates to:
  /// **'S20 (싱글 20라인)'**
  String get drill_target_beginner_large_single_20;

  /// No description provided for @drill_guide_beginner_large_single_20.
  ///
  /// In ko, this message translates to:
  /// **'S20 영역만 60발을 던지며 정확도를 50% 이상으로 올리는 것을 목표로 합니다.'**
  String get drill_guide_beginner_large_single_20;

  /// No description provided for @drill_title_beginner_big_bull.
  ///
  /// In ko, this message translates to:
  /// **'빅 Bull 감각'**
  String get drill_title_beginner_big_bull;

  /// No description provided for @drill_desc_beginner_big_bull.
  ///
  /// In ko, this message translates to:
  /// **'Bull 링 전체를 노리며 “그루핑” 감각을 만드는 드릴'**
  String get drill_desc_beginner_big_bull;

  /// No description provided for @drill_target_beginner_big_bull.
  ///
  /// In ko, this message translates to:
  /// **'전체 Bull 60발'**
  String get drill_target_beginner_big_bull;

  /// No description provided for @drill_guide_beginner_big_bull.
  ///
  /// In ko, this message translates to:
  /// **'싱글불과 더블불을 구분하지 않고 전체 Bull 영역에 모아 던지는 연습을 합니다.'**
  String get drill_guide_beginner_big_bull;

  /// No description provided for @drill_title_beginner_loose_countup_8r.
  ///
  /// In ko, this message translates to:
  /// **'느슨한 Count-Up'**
  String get drill_title_beginner_loose_countup_8r;

  /// No description provided for @drill_desc_beginner_loose_countup_8r.
  ///
  /// In ko, this message translates to:
  /// **'점수보다는 “보드에 꽂히는 경험”을 쌓는 가벼운 8R Count-Up'**
  String get drill_desc_beginner_loose_countup_8r;

  /// No description provided for @drill_target_beginner_loose_countup_8r.
  ///
  /// In ko, this message translates to:
  /// **'8R Count-Up'**
  String get drill_target_beginner_loose_countup_8r;

  /// No description provided for @drill_guide_beginner_loose_countup_8r.
  ///
  /// In ko, this message translates to:
  /// **'편안하게 8라운드를 완주하며 다트가 보드에 들어가는 손맛에 집중하세요.'**
  String get drill_guide_beginner_loose_countup_8r;

  /// No description provided for @drill_title_learner_single20_60.
  ///
  /// In ko, this message translates to:
  /// **'Single 20 60발'**
  String get drill_title_learner_single20_60;

  /// No description provided for @drill_desc_learner_single20_60.
  ///
  /// In ko, this message translates to:
  /// **'정규 거리에서 S20만 60발 던지며 명중률을 끌어올리는 드릴'**
  String get drill_desc_learner_single20_60;

  /// No description provided for @drill_target_learner_single20_60.
  ///
  /// In ko, this message translates to:
  /// **'S20'**
  String get drill_target_learner_single20_60;

  /// No description provided for @drill_guide_learner_single20_60.
  ///
  /// In ko, this message translates to:
  /// **'정규 거리에서 60발 중 40발 이상 명중시키는 것을 목표로 합니다.'**
  String get drill_guide_learner_single20_60;

  /// No description provided for @drill_title_learner_20_19_switch.
  ///
  /// In ko, this message translates to:
  /// **'상단 3섹터 루프 (20/19/18)'**
  String get drill_title_learner_20_19_switch;

  /// No description provided for @drill_desc_learner_20_19_switch.
  ///
  /// In ko, this message translates to:
  /// **'20/19/18 상단 구역을 돌면서 빅미스를 줄이는 연습'**
  String get drill_desc_learner_20_19_switch;

  /// No description provided for @drill_target_learner_20_19_switch.
  ///
  /// In ko, this message translates to:
  /// **'20 / 19 / 18'**
  String get drill_target_learner_20_19_switch;

  /// No description provided for @drill_guide_learner_20_19_switch.
  ///
  /// In ko, this message translates to:
  /// **'20, 19, 18번을 순차적으로 공략하며 타겟 전환 리듬을 익힙니다.'**
  String get drill_guide_learner_20_19_switch;

  /// No description provided for @drill_title_comp_triple_20_19_18_line.
  ///
  /// In ko, this message translates to:
  /// **'트리플 루프 (T20/T19/T18)'**
  String get drill_title_comp_triple_20_19_18_line;

  /// No description provided for @drill_desc_comp_triple_20_19_18_line.
  ///
  /// In ko, this message translates to:
  /// **'T20 → T19 → T18 트리플 영역을 순환하며 스코어링 리듬을 만드는 연습'**
  String get drill_desc_comp_triple_20_19_18_line;

  /// No description provided for @drill_target_comp_triple_20_19_18_line.
  ///
  /// In ko, this message translates to:
  /// **'T20 / T19 / T18'**
  String get drill_target_comp_triple_20_19_18_line;

  /// No description provided for @drill_guide_comp_triple_20_19_18_line.
  ///
  /// In ko, this message translates to:
  /// **'스코어링의 핵심인 상단 트리풀 3곳을 번갈아 공략하며 집중력을 유지하세요.'**
  String get drill_guide_comp_triple_20_19_18_line;

  /// No description provided for @drill_title_comp_checkout_40_80.
  ///
  /// In ko, this message translates to:
  /// **'40–80 더블 아웃 필수 구간'**
  String get drill_title_comp_checkout_40_80;

  /// No description provided for @drill_desc_comp_checkout_40_80.
  ///
  /// In ko, this message translates to:
  /// **'40~80 점수대를 더블로 마무리하는 필수 체크아웃 드릴'**
  String get drill_desc_comp_checkout_40_80;

  /// No description provided for @drill_target_comp_checkout_40_80.
  ///
  /// In ko, this message translates to:
  /// **'40~80 Double-Out'**
  String get drill_target_comp_checkout_40_80;

  /// No description provided for @drill_guide_comp_checkout_40_80.
  ///
  /// In ko, this message translates to:
  /// **'실전에서 가장 빈번한 40~80 구간을 3다트 내에 마무리하는 연습입니다.'**
  String get drill_guide_comp_checkout_40_80;

  /// No description provided for @drill_title_pro_501_standard_18darts.
  ///
  /// In ko, this message translates to:
  /// **'501 Double-Out 18다트'**
  String get drill_title_pro_501_standard_18darts;

  /// No description provided for @drill_desc_pro_501_standard_18darts.
  ///
  /// In ko, this message translates to:
  /// **'18다트 이내 501 마무리가 가능한지 체크합니다.'**
  String get drill_desc_pro_501_standard_18darts;

  /// No description provided for @drill_target_pro_501_standard_18darts.
  ///
  /// In ko, this message translates to:
  /// **'501 Double-Out'**
  String get drill_target_pro_501_standard_18darts;

  /// No description provided for @drill_guide_pro_501_standard_18darts.
  ///
  /// In ko, this message translates to:
  /// **'총 10세트 플레이 후 18다트 이내 완주 비율을 확인합니다.'**
  String get drill_guide_pro_501_standard_18darts;

  /// No description provided for @drill_title_master_170_route_focused_30.
  ///
  /// In ko, this message translates to:
  /// **'170 체크아웃 루트 집중'**
  String get drill_title_master_170_route_focused_30;

  /// No description provided for @drill_desc_master_170_route_focused_30.
  ///
  /// In ko, this message translates to:
  /// **'T20 → T20 → Bull 루트를 몸에 새겨넣는 하이피니시 드릴'**
  String get drill_desc_master_170_route_focused_30;

  /// No description provided for @drill_target_master_170_route_focused_30.
  ///
  /// In ko, this message translates to:
  /// **'170 (T20 → T20 → Bull)'**
  String get drill_target_master_170_route_focused_30;

  /// No description provided for @drill_guide_master_170_route_focused_30.
  ///
  /// In ko, this message translates to:
  /// **'170 최고점 피니시 루트를 근육이 기억할 때까지 30세트 반복합니다.'**
  String get drill_guide_master_170_route_focused_30;

  /// No description provided for @exit_drill_title.
  ///
  /// In ko, this message translates to:
  /// **'연습 종료'**
  String get exit_drill_title;

  /// No description provided for @exit_drill_msg.
  ///
  /// In ko, this message translates to:
  /// **'기록이 저장되지 않았습니다. 정말 종료하시겠습니까?'**
  String get exit_drill_msg;

  /// No description provided for @drill_msg_bust.
  ///
  /// In ko, this message translates to:
  /// **'버스트!'**
  String get drill_msg_bust;

  /// No description provided for @drill_msg_darts_left.
  ///
  /// In ko, this message translates to:
  /// **'{count} 다트 남음'**
  String drill_msg_darts_left(Object count);

  /// No description provided for @drill_category_board_mapping.
  ///
  /// In ko, this message translates to:
  /// **'보드 맵핑'**
  String get drill_category_board_mapping;

  /// No description provided for @drill_category_double.
  ///
  /// In ko, this message translates to:
  /// **'더블 연습'**
  String get drill_category_double;

  /// No description provided for @profile_reset_title.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝 데이터 초기화'**
  String get profile_reset_title;

  /// No description provided for @profile_reset_msg.
  ///
  /// In ko, this message translates to:
  /// **'DAO 트레이닝 레이팅과 티어를 초기화합니다.\n다시 레이팅 입력 또는 레벨 테스트로 시작할 수 있습니다.'**
  String get profile_reset_msg;

  /// No description provided for @rating_check_ready_title.
  ///
  /// In ko, this message translates to:
  /// **'🔥 성장 게이지 100% 달성!'**
  String get rating_check_ready_title;

  /// No description provided for @rating_check_ready_msg.
  ///
  /// In ko, this message translates to:
  /// **'훈련을 통해 성장 게이지가 가득 찼어요.\n지금 레이팅을 다시 측정하여 성장한 실력을 확인해볼까요?'**
  String get rating_check_ready_msg;

  /// No description provided for @drill_current_tier.
  ///
  /// In ko, this message translates to:
  /// **'현재 DAO 티어'**
  String get drill_current_tier;

  /// No description provided for @btn_edit_rating.
  ///
  /// In ko, this message translates to:
  /// **'레이팅 수정'**
  String get btn_edit_rating;

  /// No description provided for @tab_free_ranking.
  ///
  /// In ko, this message translates to:
  /// **'자유 랭킹'**
  String get tab_free_ranking;

  /// No description provided for @tab_custom_practice.
  ///
  /// In ko, this message translates to:
  /// **'맞춤 연습'**
  String get tab_custom_practice;

  /// No description provided for @section_training_tools.
  ///
  /// In ko, this message translates to:
  /// **'훈련 도구'**
  String get section_training_tools;

  /// No description provided for @drill_stat_growth_gauge.
  ///
  /// In ko, this message translates to:
  /// **'성장 게이지'**
  String get drill_stat_growth_gauge;

  /// No description provided for @msg_rating_check_ready.
  ///
  /// In ko, this message translates to:
  /// **'레이팅 체크 준비 완료'**
  String get msg_rating_check_ready;

  /// No description provided for @drill_remaining_xp.
  ///
  /// In ko, this message translates to:
  /// **'재평가까지 남은 XP: {xp}'**
  String drill_remaining_xp(Object xp);

  /// No description provided for @msg_input_darts_skill.
  ///
  /// In ko, this message translates to:
  /// **'다트 실력을 입력해주세요!'**
  String get msg_input_darts_skill;

  /// No description provided for @btn_input_rating.
  ///
  /// In ko, this message translates to:
  /// **'레이팅 입력'**
  String get btn_input_rating;

  /// No description provided for @btn_level_test.
  ///
  /// In ko, this message translates to:
  /// **'레벨 테스트'**
  String get btn_level_test;

  /// No description provided for @msg_no_recommended_drills.
  ///
  /// In ko, this message translates to:
  /// **'추천 드릴이 없습니다.'**
  String get msg_no_recommended_drills;

  /// No description provided for @tool_training_history.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝 히스토리'**
  String get tool_training_history;

  /// No description provided for @tool_grip_lab.
  ///
  /// In ko, this message translates to:
  /// **'그립 연구소'**
  String get tool_grip_lab;

  /// No description provided for @tool_pose_analysis.
  ///
  /// In ko, this message translates to:
  /// **'자세분석 & 트래킹'**
  String get tool_pose_analysis;

  /// No description provided for @tool_checkout_calculator.
  ///
  /// In ko, this message translates to:
  /// **'체크아웃 계산기'**
  String get tool_checkout_calculator;

  /// No description provided for @tool_my_dart_story.
  ///
  /// In ko, this message translates to:
  /// **'나만의 다트 이야기'**
  String get tool_my_dart_story;

  /// No description provided for @common_later.
  ///
  /// In ko, this message translates to:
  /// **'나중에 하기'**
  String get common_later;

  /// No description provided for @common_test.
  ///
  /// In ko, this message translates to:
  /// **'테스트 하기'**
  String get common_test;

  /// No description provided for @common_reset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get common_reset;

  /// No description provided for @tier_test_headline.
  ///
  /// In ko, this message translates to:
  /// **'다트 보드 마킹 정확도 테스트'**
  String get tier_test_headline;

  /// No description provided for @tier_test_guide_title.
  ///
  /// In ko, this message translates to:
  /// **'DAO 공식 마킹 레벨 기준'**
  String get tier_test_guide_title;

  /// No description provided for @tier_test_input_hint.
  ///
  /// In ko, this message translates to:
  /// **'예: 28'**
  String get tier_test_input_hint;

  /// No description provided for @tier_test_result_notice.
  ///
  /// In ko, this message translates to:
  /// **'결과는 트레이닝 홈에 바로 반영됩니다'**
  String get tier_test_result_notice;

  /// No description provided for @tier_test_err_empty.
  ///
  /// In ko, this message translates to:
  /// **'다트 수를 입력해주세요'**
  String get tier_test_err_empty;

  /// No description provided for @tier_test_err_invalid.
  ///
  /// In ko, this message translates to:
  /// **'1 이상의 숫자를 입력해주세요'**
  String get tier_test_err_invalid;

  /// No description provided for @drill_active_area.
  ///
  /// In ko, this message translates to:
  /// **'현재 연습 구역'**
  String get drill_active_area;

  /// No description provided for @area_top_right.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 위'**
  String get area_top_right;

  /// No description provided for @area_bottom_right.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 아래'**
  String get area_bottom_right;

  /// No description provided for @area_bottom_left.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 아래'**
  String get area_bottom_left;

  /// No description provided for @area_top_left.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 위'**
  String get area_top_left;

  /// No description provided for @drill_approx_duration.
  ///
  /// In ko, this message translates to:
  /// **'약 {min}분'**
  String drill_approx_duration(Object min);

  /// No description provided for @drill_stat_total_darts.
  ///
  /// In ko, this message translates to:
  /// **'총 다트'**
  String get drill_stat_total_darts;

  /// No description provided for @drill_stat_hit_rate.
  ///
  /// In ko, this message translates to:
  /// **'명중률'**
  String get drill_stat_hit_rate;

  /// No description provided for @drill_stat_total_marks.
  ///
  /// In ko, this message translates to:
  /// **'총 마크'**
  String get drill_stat_total_marks;

  /// No description provided for @drill_stat_total_score.
  ///
  /// In ko, this message translates to:
  /// **'총 점수'**
  String get drill_stat_total_score;

  /// No description provided for @btn_close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get btn_close;

  /// No description provided for @btn_go_history.
  ///
  /// In ko, this message translates to:
  /// **'히스토리'**
  String get btn_go_history;

  /// No description provided for @btn_continue_drill.
  ///
  /// In ko, this message translates to:
  /// **'다른 연습 계속하기'**
  String get btn_continue_drill;

  /// No description provided for @btn_rating_check.
  ///
  /// In ko, this message translates to:
  /// **'레이팅 체크'**
  String get btn_rating_check;

  /// No description provided for @report_header_title.
  ///
  /// In ko, this message translates to:
  /// **'DAO 트레이닝 리포트'**
  String get report_header_title;

  /// No description provided for @report_current_result.
  ///
  /// In ko, this message translates to:
  /// **'이번 결과 ({label})'**
  String report_current_result(Object label);

  /// No description provided for @report_previous_best.
  ///
  /// In ko, this message translates to:
  /// **'이전 최고 ({label})'**
  String report_previous_best(Object label);

  /// No description provided for @report_previous_record.
  ///
  /// In ko, this message translates to:
  /// **'이전 기록'**
  String get report_previous_record;

  /// No description provided for @report_first_record_msg.
  ///
  /// In ko, this message translates to:
  /// **'첫 기록입니다!'**
  String get report_first_record_msg;

  /// No description provided for @report_xp_goal_msg.
  ///
  /// In ko, this message translates to:
  /// **'이번 회차 목표: {goal} XP 기준'**
  String report_xp_goal_msg(Object goal);

  /// No description provided for @report_growth_gauge.
  ///
  /// In ko, this message translates to:
  /// **'성장 게이지 변화'**
  String get report_growth_gauge;

  /// No description provided for @report_gauge_before.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get report_gauge_before;

  /// No description provided for @report_gauge_current.
  ///
  /// In ko, this message translates to:
  /// **'현재'**
  String get report_gauge_current;

  /// No description provided for @report_gauge_max_msg.
  ///
  /// In ko, this message translates to:
  /// **'이번 회차 성장 게이지 MAX! 레벨 재평가 시점이에요.'**
  String get report_gauge_max_msg;

  /// No description provided for @report_summary_first_save.
  ///
  /// In ko, this message translates to:
  /// **'DAO 트레이닝 첫 기록이 저장되었습니다.'**
  String get report_summary_first_save;

  /// No description provided for @report_summary_first_max.
  ///
  /// In ko, this message translates to:
  /// **'DAO 트레이닝 첫 기록과 함께 성장 게이지가 가득 찼어요.'**
  String get report_summary_first_max;

  /// No description provided for @report_summary_improved.
  ///
  /// In ko, this message translates to:
  /// **'이전 기록보다 {diff} 만큼 {label}이 상승했습니다.'**
  String report_summary_improved(Object diff, Object label);

  /// No description provided for @report_summary_steady.
  ///
  /// In ko, this message translates to:
  /// **'이번 연습은 이전과 거의 비슷한 수준의 결과였어요.'**
  String get report_summary_steady;

  /// No description provided for @report_summary_encouragement.
  ///
  /// In ko, this message translates to:
  /// **'이번 결과는 이전보다 조금 낮았지만, 실력은 계속 쌓이고 있습니다.'**
  String get report_summary_encouragement;

  /// No description provided for @rank_select_title.
  ///
  /// In ko, this message translates to:
  /// **'도전 종목 선택'**
  String get rank_select_title;

  /// No description provided for @rank_501_desc.
  ///
  /// In ko, this message translates to:
  /// **'PPD 랭킹 도전 (10라운드)'**
  String get rank_501_desc;

  /// No description provided for @rank_cricket_desc.
  ///
  /// In ko, this message translates to:
  /// **'MPR 랭킹 도전 (15라운드)'**
  String get rank_cricket_desc;

  /// No description provided for @rank_countup_desc.
  ///
  /// In ko, this message translates to:
  /// **'최고 점수 도전 (8라운드)'**
  String get rank_countup_desc;

  /// No description provided for @rank_game_round.
  ///
  /// In ko, this message translates to:
  /// **'ROUND {current} / {max}'**
  String rank_game_round(Object current, Object max);

  /// No description provided for @rank_game_left.
  ///
  /// In ko, this message translates to:
  /// **'남은 점수'**
  String get rank_game_left;

  /// No description provided for @rank_game_total_score.
  ///
  /// In ko, this message translates to:
  /// **'총 점수'**
  String get rank_game_total_score;

  /// No description provided for @rank_game_target.
  ///
  /// In ko, this message translates to:
  /// **'목표'**
  String get rank_game_target;

  /// No description provided for @rank_game_round_score.
  ///
  /// In ko, this message translates to:
  /// **'라운드 점수'**
  String get rank_game_round_score;

  /// No description provided for @rank_game_confirm.
  ///
  /// In ko, this message translates to:
  /// **'확정'**
  String get rank_game_confirm;

  /// No description provided for @rank_msg_bust.
  ///
  /// In ko, this message translates to:
  /// **'BUST 처리되었습니다.'**
  String get rank_msg_bust;

  /// No description provided for @rank_msg_max_score.
  ///
  /// In ko, this message translates to:
  /// **'최대 180점입니다.'**
  String get rank_msg_max_score;

  /// No description provided for @rank_msg_bull_max.
  ///
  /// In ko, this message translates to:
  /// **'BULL은 최대 6마크까지만 가능합니다.'**
  String get rank_msg_bull_max;

  /// No description provided for @rank_finish_title.
  ///
  /// In ko, this message translates to:
  /// **'FINISH! 🎯'**
  String get rank_finish_title;

  /// No description provided for @rank_finish_sub.
  ///
  /// In ko, this message translates to:
  /// **'마지막 {score}점을 몇 발 만에 끝냈나요?'**
  String rank_finish_sub(Object score);

  /// No description provided for @rank_darts_count.
  ///
  /// In ko, this message translates to:
  /// **'{count}발'**
  String rank_darts_count(Object count);

  /// No description provided for @rank_reset_my_title.
  ///
  /// In ko, this message translates to:
  /// **'기록 초기화'**
  String get rank_reset_my_title;

  /// No description provided for @rank_reset_admin_title.
  ///
  /// In ko, this message translates to:
  /// **'관리자 권한: 기록 삭제'**
  String get rank_reset_admin_title;

  /// No description provided for @rank_reset_my_msg.
  ///
  /// In ko, this message translates to:
  /// **'정말로 이번 달 내 모든 최고 기록을 초기화하시겠습니까?\n삭제 후 순위에서 즉시 제외됩니다.'**
  String get rank_reset_my_msg;

  /// No description provided for @rank_reset_admin_msg.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 유저의 부정 기록이 의심되나요?\n이 유저의 이번 달 모든 랭킹 기록을 삭제하시겠습니까?'**
  String rank_reset_admin_msg(Object name);

  /// No description provided for @rank_reset_done.
  ///
  /// In ko, this message translates to:
  /// **'기록이 정상적으로 삭제되었습니다.'**
  String get rank_reset_done;

  /// No description provided for @rank_tab_total.
  ///
  /// In ko, this message translates to:
  /// **'통합 🔥'**
  String get rank_tab_total;

  /// No description provided for @rank_btn_challenge.
  ///
  /// In ko, this message translates to:
  /// **'랭킹 도전하기'**
  String get rank_btn_challenge;

  /// No description provided for @rank_guide_title.
  ///
  /// In ko, this message translates to:
  /// **'💡 기록 관리 안내'**
  String get rank_guide_title;

  /// No description provided for @rank_guide_delete.
  ///
  /// In ko, this message translates to:
  /// **'내 기록을 길게 꾹 누르면 해당 기록을 삭제할 수 있습니다.'**
  String get rank_guide_delete;

  /// No description provided for @rank_guide_warning.
  ///
  /// In ko, this message translates to:
  /// **'공정한 랭킹 문화를 위해 부적절한 방법으로 등록된 기록은\n관리자에 의해 예고 없이 삭제될 수 있습니다.'**
  String get rank_guide_warning;

  /// No description provided for @rank_guide_badge.
  ///
  /// In ko, this message translates to:
  /// **'통합 랭킹으로 배지가 수여되며\n각 종목 TOP 10 기록을 합산하여 결정됩니다.'**
  String get rank_guide_badge;

  /// No description provided for @rank_no_data.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 없습니다.'**
  String get rank_no_data;

  /// No description provided for @rank_no_total_data.
  ///
  /// In ko, this message translates to:
  /// **'아직 통합 집계 데이터가 없습니다.'**
  String get rank_no_total_data;

  /// No description provided for @rank_load_failed.
  ///
  /// In ko, this message translates to:
  /// **'데이터 로드 실패'**
  String get rank_load_failed;

  /// No description provided for @calendar_title.
  ///
  /// In ko, this message translates to:
  /// **'공식 일정 달력'**
  String get calendar_title;

  /// No description provided for @calendar_selected_day.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일 일정'**
  String calendar_selected_day(Object day, Object month);

  /// No description provided for @calendar_no_event.
  ///
  /// In ko, this message translates to:
  /// **'일정이 없습니다.'**
  String get calendar_no_event;

  /// No description provided for @calendar_delete_title.
  ///
  /// In ko, this message translates to:
  /// **'일정 삭제'**
  String get calendar_delete_title;

  /// No description provided for @calendar_delete_msg.
  ///
  /// In ko, this message translates to:
  /// **'정말 이 일정을 삭제하시겠습니까?'**
  String get calendar_delete_msg;

  /// No description provided for @calendar_unit_month.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get calendar_unit_month;

  /// No description provided for @calendar_unit_day.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get calendar_unit_day;

  /// No description provided for @live_list_title.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 연습 현황'**
  String get live_list_title;

  /// No description provided for @live_list_empty.
  ///
  /// In ko, this message translates to:
  /// **'오늘 연습 기록이 아직 없습니다.'**
  String get live_list_empty;

  /// No description provided for @live_status_live.
  ///
  /// In ko, this message translates to:
  /// **'LIVE'**
  String get live_status_live;

  /// No description provided for @live_status_finished.
  ///
  /// In ko, this message translates to:
  /// **'종료됨'**
  String get live_status_finished;

  /// No description provided for @live_no_shop.
  ///
  /// In ko, this message translates to:
  /// **'장소 미지정'**
  String get live_no_shop;

  /// No description provided for @live_blur_text.
  ///
  /// In ko, this message translates to:
  /// **'**** · ****'**
  String get live_blur_text;

  /// No description provided for @live_board_title.
  ///
  /// In ko, this message translates to:
  /// **'LIVE 연습 현황'**
  String get live_board_title;

  /// No description provided for @live_board_view_all.
  ///
  /// In ko, this message translates to:
  /// **'전체보기'**
  String get live_board_view_all;

  /// No description provided for @live_board_login_invite.
  ///
  /// In ko, this message translates to:
  /// **'로그인 후 연습시간을 체크해보세요!'**
  String get live_board_login_invite;

  /// No description provided for @live_board_start_invite.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 연습시간을 체크할까요?'**
  String get live_board_start_invite;

  /// No description provided for @live_board_profile_invite.
  ///
  /// In ko, this message translates to:
  /// **'프로필 등록 후 연습시간을 체크하세요!'**
  String get live_board_profile_invite;

  /// No description provided for @live_board_btn_start.
  ///
  /// In ko, this message translates to:
  /// **'연습 시작'**
  String get live_board_btn_start;

  /// No description provided for @live_board_btn_stop.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get live_board_btn_stop;

  /// No description provided for @live_board_btn_profile.
  ///
  /// In ko, this message translates to:
  /// **'프로필 등록'**
  String get live_board_btn_profile;

  /// No description provided for @live_board_total_count.
  ///
  /// In ko, this message translates to:
  /// **'현재 {count}명의 유저가 연습 중입니다!'**
  String live_board_total_count(Object count);

  /// No description provided for @live_board_no_user.
  ///
  /// In ko, this message translates to:
  /// **'아직 연습 중인 유저가 없습니다.'**
  String get live_board_no_user;

  /// No description provided for @live_board_total_today.
  ///
  /// In ko, this message translates to:
  /// **'오늘 총 연습: {time}'**
  String live_board_total_today(Object time);

  /// No description provided for @common_hour.
  ///
  /// In ko, this message translates to:
  /// **'{value}시간'**
  String common_hour(Object value);

  /// No description provided for @common_minute.
  ///
  /// In ko, this message translates to:
  /// **'{value}분'**
  String common_minute(Object value);

  /// No description provided for @login_title.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get login_title;

  /// No description provided for @live_total_time.
  ///
  /// In ko, this message translates to:
  /// **'총 {time}'**
  String live_total_time(Object time);

  /// No description provided for @practice_setup_title.
  ///
  /// In ko, this message translates to:
  /// **'기록 시작'**
  String get practice_setup_title;

  /// No description provided for @practice_setup_sub.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 연습 환경을 설정하고 기록을 시작하세요.'**
  String get practice_setup_sub;

  /// No description provided for @practice_setup_machine.
  ///
  /// In ko, this message translates to:
  /// **'사용 머신'**
  String get practice_setup_machine;

  /// No description provided for @practice_setup_location.
  ///
  /// In ko, this message translates to:
  /// **'연습 장소'**
  String get practice_setup_location;

  /// No description provided for @practice_setup_location_hint.
  ///
  /// In ko, this message translates to:
  /// **'예: PDK 스타디움, 다트하이브'**
  String get practice_setup_location_hint;

  /// No description provided for @practice_setup_goal.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 연습 목표 (선택)'**
  String get practice_setup_goal;

  /// No description provided for @practice_setup_goal_hint.
  ///
  /// In ko, this message translates to:
  /// **'예: 불 100발, 레이팅 15, 3시간 연습 등'**
  String get practice_setup_goal_hint;

  /// No description provided for @practice_setup_btn_start.
  ///
  /// In ko, this message translates to:
  /// **'연습 기록 시작하기'**
  String get practice_setup_btn_start;

  /// No description provided for @practice_setup_error_location.
  ///
  /// In ko, this message translates to:
  /// **'연습 중인 장소(샵 이름)를 입력해주세요.'**
  String get practice_setup_error_location;

  /// No description provided for @practice_setup_error_start.
  ///
  /// In ko, this message translates to:
  /// **'시작 오류: {error}'**
  String practice_setup_error_start(Object error);

  /// No description provided for @practice_stop_title.
  ///
  /// In ko, this message translates to:
  /// **'연습 종료 리포트'**
  String get practice_stop_title;

  /// No description provided for @practice_stop_sub.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 연습을 마무리하고 기록을 남겨보세요.'**
  String get practice_stop_sub;

  /// No description provided for @practice_stop_total_time.
  ///
  /// In ko, this message translates to:
  /// **'총 연습 시간'**
  String get practice_stop_total_time;

  /// No description provided for @practice_stop_my_goal.
  ///
  /// In ko, this message translates to:
  /// **'나의 목표'**
  String get practice_stop_my_goal;

  /// No description provided for @practice_stop_feedback_label.
  ///
  /// In ko, this message translates to:
  /// **'목표를 달성하셨나요? (결과/피드백)'**
  String get practice_stop_feedback_label;

  /// No description provided for @practice_stop_feedback_hint.
  ///
  /// In ko, this message translates to:
  /// **'예: 100발 완료!, 컨디션 난조로 실패 등'**
  String get practice_stop_feedback_hint;

  /// No description provided for @practice_stop_cheer_msg.
  ///
  /// In ko, this message translates to:
  /// **'오늘도 정말 고생하셨습니다!'**
  String get practice_stop_cheer_msg;

  /// No description provided for @practice_stop_btn_no_save.
  ///
  /// In ko, this message translates to:
  /// **'저장없이 종료'**
  String get practice_stop_btn_no_save;

  /// No description provided for @practice_stop_btn_save.
  ///
  /// In ko, this message translates to:
  /// **'마이로그 저장'**
  String get practice_stop_btn_save;

  /// No description provided for @practice_stop_error.
  ///
  /// In ko, this message translates to:
  /// **'종료 처리 중 오류가 발생했습니다: {error}'**
  String practice_stop_error(Object error);

  /// No description provided for @history_title.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝 히스토리'**
  String get history_title;

  /// No description provided for @history_login_required.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요해요'**
  String get history_login_required;

  /// No description provided for @history_login_msg.
  ///
  /// In ko, this message translates to:
  /// **'내 연습 기록을 저장하고 추이를 확인하려면\n로그인이 필요합니다.'**
  String get history_login_msg;

  /// No description provided for @history_profile_required.
  ///
  /// In ko, this message translates to:
  /// **'프로필 등록이 필요해요'**
  String get history_profile_required;

  /// No description provided for @history_profile_msg.
  ///
  /// In ko, this message translates to:
  /// **'기록의 신뢰성을 위해 프로필 등록 유저만\n히스토리 기능을 사용할 수 있습니다.'**
  String get history_profile_msg;

  /// No description provided for @history_no_record.
  ///
  /// In ko, this message translates to:
  /// **'아직 연습 기록이 없어요.'**
  String get history_no_record;

  /// No description provided for @history_no_cycle_record.
  ///
  /// In ko, this message translates to:
  /// **'이 사이클엔 기록이 없어요.'**
  String get history_no_cycle_record;

  /// No description provided for @history_tab_trend.
  ///
  /// In ko, this message translates to:
  /// **'추이'**
  String get history_tab_trend;

  /// No description provided for @history_tab_list.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get history_tab_list;

  /// No description provided for @history_filter_all.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get history_filter_all;

  /// No description provided for @history_tip_delete.
  ///
  /// In ko, this message translates to:
  /// **'Tip. 목록을 길게 누르면 기록을 삭제할 수 있어요.'**
  String get history_tip_delete;

  /// No description provided for @history_delete_title.
  ///
  /// In ko, this message translates to:
  /// **'기록 삭제'**
  String get history_delete_title;

  /// No description provided for @history_delete_msg.
  ///
  /// In ko, this message translates to:
  /// **'이 연습 기록을 정말 삭제하시겠습니까?\n서버에서도 영구적으로 삭제됩니다.'**
  String get history_delete_msg;

  /// No description provided for @history_cycle_delete_title.
  ///
  /// In ko, this message translates to:
  /// **'사이클 삭제'**
  String get history_cycle_delete_title;

  /// No description provided for @history_cycle_delete_msg.
  ///
  /// In ko, this message translates to:
  /// **'이 사이클의 모든 기록을 삭제할까요?\n복구할 수 없습니다.'**
  String get history_cycle_delete_msg;

  /// No description provided for @history_stat_avg_hit.
  ///
  /// In ko, this message translates to:
  /// **'평균 명중률'**
  String get history_stat_avg_hit;

  /// No description provided for @history_stat_max_hit.
  ///
  /// In ko, this message translates to:
  /// **'최고 명중률'**
  String get history_stat_max_hit;

  /// No description provided for @history_date_today.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get history_date_today;

  /// No description provided for @history_date_yesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get history_date_yesterday;

  /// No description provided for @history_date_days_ago.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 전'**
  String history_date_days_ago(Object days);

  /// No description provided for @history_cycle_label.
  ///
  /// In ko, this message translates to:
  /// **'사이클 {number}'**
  String history_cycle_label(Object number);

  /// No description provided for @history_initial_record.
  ///
  /// In ko, this message translates to:
  /// **'초기 기록'**
  String get history_initial_record;

  /// No description provided for @detail_title.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝 상세'**
  String get detail_title;

  /// No description provided for @detail_error_load.
  ///
  /// In ko, this message translates to:
  /// **'기록을 불러오는 중 문제가 발생했습니다.'**
  String get detail_error_load;

  /// No description provided for @detail_stat_no_record.
  ///
  /// In ko, this message translates to:
  /// **'기록 없음'**
  String get detail_stat_no_record;

  /// No description provided for @detail_info_title.
  ///
  /// In ko, this message translates to:
  /// **'세부 정보'**
  String get detail_info_title;

  /// No description provided for @detail_info_drill_id.
  ///
  /// In ko, this message translates to:
  /// **'드릴 ID'**
  String get detail_info_drill_id;

  /// No description provided for @detail_info_cycle.
  ///
  /// In ko, this message translates to:
  /// **'사이클'**
  String get detail_info_cycle;

  /// No description provided for @detail_info_total_attempts.
  ///
  /// In ko, this message translates to:
  /// **'총 시도'**
  String get detail_info_total_attempts;

  /// No description provided for @detail_summary_no_data.
  ///
  /// In ko, this message translates to:
  /// **'이번 세션의 {metric} 기록이 아직 충분하지 않아요.\n다음 연습에서 한 번 더 같은 드릴을 진행해보면, 변화가 더 잘 보일 거예요.'**
  String detail_summary_no_data(Object metric);

  /// No description provided for @detail_summary_first.
  ///
  /// In ko, this message translates to:
  /// **'{metric} 첫 기록입니다.\n앞으로 이 수치를 기준으로 성장 그래프와 히스토리가 쌓이게 돼요.\n🔥 오늘의 미션: 같은 드릴을 한 번 더 진행해서 \'내 기준 기록\'을 만들어보세요.'**
  String detail_summary_first(Object metric);

  /// No description provided for @detail_summary_up.
  ///
  /// In ko, this message translates to:
  /// **'{metric} +{diff} 상승! 🔥\n이전 세션보다 분명히 나아졌어요.\n지금 템포와 리듬을 한 번 더 유지해서 \'연속 상승\'에 도전해볼까요?'**
  String detail_summary_up(Object diff, Object metric);

  /// No description provided for @detail_summary_steady.
  ///
  /// In ko, this message translates to:
  /// **'{metric} 변화 거의 없음.\n이건 오히려 \'내 평균 페이스\'를 찾고 있다는 신호예요.\n조금 다른 루틴이나 호흡으로 같은 드릴을 한 번 더 시도해보는 것도 좋아요.'**
  String detail_summary_steady(Object metric);

  /// No description provided for @detail_summary_down.
  ///
  /// In ko, this message translates to:
  /// **'{metric} -{diff} 하락.\n하지만 XP와 연습량은 그대로 쌓이고 있습니다.\n오늘은 여기서 마무리하고, 다른 유형 드릴로 한 번 더 몸을 풀어준 뒤\n다음 사이클에서 다시 이 드릴에 도전해보는 건 어떨까요?'**
  String detail_summary_down(Object diff, Object metric);

  /// No description provided for @chart_title.
  ///
  /// In ko, this message translates to:
  /// **'성장 추이 (하루 평균, 최근 7일)'**
  String get chart_title;

  /// No description provided for @chart_sub.
  ///
  /// In ko, this message translates to:
  /// **'그래프는 최근 7일 동안의 하루 평균값을 보여줘요.'**
  String get chart_sub;

  /// No description provided for @chart_legend_ppd.
  ///
  /// In ko, this message translates to:
  /// **'PPD (스케일 x2)'**
  String get chart_legend_ppd;

  /// No description provided for @chart_legend_mpr.
  ///
  /// In ko, this message translates to:
  /// **'MPR (스케일 x10)'**
  String get chart_legend_mpr;

  /// No description provided for @chart_goal_hit.
  ///
  /// In ko, this message translates to:
  /// **'목표 명중률 {percent}%'**
  String chart_goal_hit(Object percent);

  /// No description provided for @chart_toggle_all.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get chart_toggle_all;

  /// No description provided for @chart_tooltip_hit.
  ///
  /// In ko, this message translates to:
  /// **'명중률'**
  String get chart_tooltip_hit;

  /// No description provided for @chart_no_data.
  ///
  /// In ko, this message translates to:
  /// **'표시할 수 있는 데이터가 없어요'**
  String get chart_no_data;

  /// No description provided for @profile_register_btn.
  ///
  /// In ko, this message translates to:
  /// **'프로필 등록하러 가기'**
  String get profile_register_btn;

  /// No description provided for @pose_title.
  ///
  /// In ko, this message translates to:
  /// **'AI 자세 분석'**
  String get pose_title;

  /// No description provided for @pose_login_msg.
  ///
  /// In ko, this message translates to:
  /// **'자세 분석 기능을 사용하고 기록을 저장하려면\n로그인이 필요합니다.'**
  String get pose_login_msg;

  /// No description provided for @pose_main_sub.
  ///
  /// In ko, this message translates to:
  /// **'영상을 업로드하면 뼈대와 궤적을 추적하여\n시각적으로 분석해 드립니다.'**
  String get pose_main_sub;

  /// No description provided for @pose_feature1_title.
  ///
  /// In ko, this message translates to:
  /// **'스켈레톤(뼈대) 분석'**
  String get pose_feature1_title;

  /// No description provided for @pose_feature1_desc.
  ///
  /// In ko, this message translates to:
  /// **'어깨, 팔꿈치, 손목의 움직임을 뼈대로 시각화합니다.'**
  String get pose_feature1_desc;

  /// No description provided for @pose_feature2_title.
  ///
  /// In ko, this message translates to:
  /// **'손목 궤적 트래킹'**
  String get pose_feature2_title;

  /// No description provided for @pose_feature2_desc.
  ///
  /// In ko, this message translates to:
  /// **'릴리즈 순간의 손목 이동 경로를 선으로 그려줍니다.'**
  String get pose_feature2_desc;

  /// No description provided for @pose_feature3_title.
  ///
  /// In ko, this message translates to:
  /// **'프레임 단위 정밀 진단'**
  String get pose_feature3_title;

  /// No description provided for @pose_feature3_desc.
  ///
  /// In ko, this message translates to:
  /// **'30FPS 고화질 분석으로 미세한 흔들림까지 확인하세요.'**
  String get pose_feature3_desc;

  /// No description provided for @pose_label_r_wrist.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 손목'**
  String get pose_label_r_wrist;

  /// No description provided for @pose_label_l_wrist.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 손목'**
  String get pose_label_l_wrist;

  /// No description provided for @pose_label_r_elbow.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 팔꿈치'**
  String get pose_label_r_elbow;

  /// No description provided for @pose_label_l_elbow.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 팔꿈치'**
  String get pose_label_l_elbow;

  /// No description provided for @pose_label_r_shoulder.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 어깨'**
  String get pose_label_r_shoulder;

  /// No description provided for @pose_label_l_shoulder.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 어깨'**
  String get pose_label_l_shoulder;

  /// No description provided for @pose_result_guide_title.
  ///
  /// In ko, this message translates to:
  /// **'기준선 가이드 (팔꿈치/손목)'**
  String get pose_result_guide_title;

  /// No description provided for @pose_result_guide_off.
  ///
  /// In ko, this message translates to:
  /// **'끄기'**
  String get pose_result_guide_off;

  /// No description provided for @pose_result_guide_left.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 켜기'**
  String get pose_result_guide_left;

  /// No description provided for @pose_result_guide_right.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 켜기'**
  String get pose_result_guide_right;

  /// No description provided for @pose_result_show_track.
  ///
  /// In ko, this message translates to:
  /// **'트래킹 궤적 보기'**
  String get pose_result_show_track;

  /// No description provided for @pose_result_show_track_sub.
  ///
  /// In ko, this message translates to:
  /// **'투구 궤적 표시'**
  String get pose_result_show_track_sub;

  /// No description provided for @pose_result_show_release.
  ///
  /// In ko, this message translates to:
  /// **'릴리즈 포인트 보기'**
  String get pose_result_show_release;

  /// No description provided for @pose_result_show_release_sub.
  ///
  /// In ko, this message translates to:
  /// **'던지는 순간 표시 (점)'**
  String get pose_result_show_release_sub;

  /// No description provided for @pose_result_select_part.
  ///
  /// In ko, this message translates to:
  /// **'보고 싶은 부위 선택'**
  String get pose_result_select_part;

  /// No description provided for @pose_result_btn_repick.
  ///
  /// In ko, this message translates to:
  /// **'다른 영상 선택'**
  String get pose_result_btn_repick;

  /// No description provided for @pose_result_btn_save.
  ///
  /// In ko, this message translates to:
  /// **'영상 저장'**
  String get pose_result_btn_save;

  /// No description provided for @pose_render_preparing.
  ///
  /// In ko, this message translates to:
  /// **'영상 분석 준비 중...'**
  String get pose_render_preparing;

  /// No description provided for @pose_render_extracting.
  ///
  /// In ko, this message translates to:
  /// **'프레임 추출 중...'**
  String get pose_render_extracting;

  /// No description provided for @pose_render_analyzing.
  ///
  /// In ko, this message translates to:
  /// **'AI 뼈대 분석 중...'**
  String get pose_render_analyzing;

  /// No description provided for @pose_render_encoding.
  ///
  /// In ko, this message translates to:
  /// **'영상 인코딩 중...'**
  String get pose_render_encoding;

  /// No description provided for @pose_render_complete.
  ///
  /// In ko, this message translates to:
  /// **'저장 완료!'**
  String get pose_render_complete;

  /// No description provided for @pose_render_dialog_title.
  ///
  /// In ko, this message translates to:
  /// **'영상 생성 중'**
  String get pose_render_dialog_title;

  /// No description provided for @pose_render_save_success.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에 저장되었습니다!'**
  String get pose_render_save_success;

  /// No description provided for @pose_setting_change_video.
  ///
  /// In ko, this message translates to:
  /// **'영상 변경'**
  String get pose_setting_change_video;

  /// No description provided for @pose_setting_tip_title.
  ///
  /// In ko, this message translates to:
  /// **'정확한 분석을 위한 팁'**
  String get pose_setting_tip_title;

  /// No description provided for @pose_setting_tip1.
  ///
  /// In ko, this message translates to:
  /// **'• 원활한 분석을 위해 20~25초 내외의 영상을 권장합니다.'**
  String get pose_setting_tip1;

  /// No description provided for @pose_setting_tip2.
  ///
  /// In ko, this message translates to:
  /// **'• 측면에서 몸과 팔 전체가 나오도록 촬영하면 가장 정확합니다.'**
  String get pose_setting_tip2;

  /// No description provided for @pose_setting_section_part.
  ///
  /// In ko, this message translates to:
  /// **'추적 부위 선택'**
  String get pose_setting_section_part;

  /// No description provided for @pose_setting_section_skeleton.
  ///
  /// In ko, this message translates to:
  /// **'뼈대 색상'**
  String get pose_setting_section_skeleton;

  /// No description provided for @pose_setting_section_line.
  ///
  /// In ko, this message translates to:
  /// **'트래킹 라인 색상'**
  String get pose_setting_section_line;

  /// No description provided for @pose_setting_btn_start.
  ///
  /// In ko, this message translates to:
  /// **'분석 시작'**
  String get pose_setting_btn_start;

  /// No description provided for @pose_proc_title.
  ///
  /// In ko, this message translates to:
  /// **'자세를 분석 중입니다'**
  String get pose_proc_title;

  /// No description provided for @pose_proc_time.
  ///
  /// In ko, this message translates to:
  /// **'소요 시간: {seconds}초'**
  String pose_proc_time(Object seconds);

  /// No description provided for @pose_proc_ad_loading.
  ///
  /// In ko, this message translates to:
  /// **'광고를 불러오는 중입니다...'**
  String get pose_proc_ad_loading;

  /// No description provided for @pose_proc_ad_dev.
  ///
  /// In ko, this message translates to:
  /// **'MREC 광고 영역 (개발중)'**
  String get pose_proc_ad_dev;

  /// No description provided for @pose_proc_guide.
  ///
  /// In ko, this message translates to:
  /// **'AI가 영상을 프레임 단위로 분석하고 있습니다.\n영상이 길수록 시간이 조금 더 소요됩니다.'**
  String get pose_proc_guide;

  /// No description provided for @pose_proc_failed.
  ///
  /// In ko, this message translates to:
  /// **'분석 실패. 다시 시도해주세요.'**
  String get pose_proc_failed;

  /// No description provided for @pose_guide_main.
  ///
  /// In ko, this message translates to:
  /// **'정확한 분석을 위해\n다음 사항을 확인해 주세요.'**
  String get pose_guide_main;

  /// No description provided for @pose_guide_sub.
  ///
  /// In ko, this message translates to:
  /// **'AI가 뼈대를 잘 인식할수록 분석 결과가 정확해집니다.'**
  String get pose_guide_sub;

  /// No description provided for @pose_guide_good_title.
  ///
  /// In ko, this message translates to:
  /// **'Good: 권장하는 촬영 방법'**
  String get pose_guide_good_title;

  /// No description provided for @pose_guide_good_1.
  ///
  /// In ko, this message translates to:
  /// **'영상 길이는 20초~25초 사이가 분석 및 저장에 가장 적합합니다.'**
  String get pose_guide_good_1;

  /// No description provided for @pose_guide_good_2.
  ///
  /// In ko, this message translates to:
  /// **'분석할 사용자의 측면 모습(90도)에서 촬영해 주세요.'**
  String get pose_guide_good_2;

  /// No description provided for @pose_guide_good_3.
  ///
  /// In ko, this message translates to:
  /// **'머리부터 상체, 골반, 무릎까지 나오도록 찍는 것이 좋습니다.'**
  String get pose_guide_good_3;

  /// No description provided for @pose_guide_good_4.
  ///
  /// In ko, this message translates to:
  /// **'긴팔보다는 반팔을 입어야 관절 위치가 정확히 인식됩니다.'**
  String get pose_guide_good_4;

  /// No description provided for @pose_guide_good_5.
  ///
  /// In ko, this message translates to:
  /// **'강한 역광이나 배경의 방해 요소가 없는 밝은 곳이 좋습니다.'**
  String get pose_guide_good_5;

  /// No description provided for @pose_guide_bad_title.
  ///
  /// In ko, this message translates to:
  /// **'Bad: 피해야 할 촬영 방법'**
  String get pose_guide_bad_title;

  /// No description provided for @pose_guide_bad_1.
  ///
  /// In ko, this message translates to:
  /// **'영상이 너무 길면 분석 시간이 오래 걸리거나 앱이 종료될 수 있습니다.'**
  String get pose_guide_bad_1;

  /// No description provided for @pose_guide_bad_2.
  ///
  /// In ko, this message translates to:
  /// **'상반신만 찍으면 중요 포인트와 궤적 추적이 안 될 수 있습니다.'**
  String get pose_guide_bad_2;

  /// No description provided for @pose_guide_bad_3.
  ///
  /// In ko, this message translates to:
  /// **'정면이나 45도 각도는 현재 정확한 분석이 어렵습니다.'**
  String get pose_guide_bad_3;

  /// No description provided for @pose_guide_bad_4.
  ///
  /// In ko, this message translates to:
  /// **'신체를 가리는 헐렁한 옷이나 장신구는 피해 주세요.'**
  String get pose_guide_bad_4;

  /// No description provided for @pose_guide_bad_5.
  ///
  /// In ko, this message translates to:
  /// **'강한 조명이나 촬영 중 배경에 다른 움직임이 있으면 분석이 부정확할 수 있습니다.'**
  String get pose_guide_bad_5;

  /// No description provided for @pose_guide_btn_confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인했습니다 (영상 선택)'**
  String get pose_guide_btn_confirm;

  /// No description provided for @grip_title.
  ///
  /// In ko, this message translates to:
  /// **'그립 연구소'**
  String get grip_title;

  /// No description provided for @grip_main_title.
  ///
  /// In ko, this message translates to:
  /// **'내 그립, 기록하고\n비교하기.'**
  String get grip_main_title;

  /// No description provided for @grip_main_sub.
  ///
  /// In ko, this message translates to:
  /// **'정답은 없지만, 나에게 잘 맞는 ‘기준’은 있습니다.\n가장 좋았던 그립을 저장하고, 매일 그 감각을 맞춰보세요.'**
  String get grip_main_sub;

  /// No description provided for @grip_info1_title.
  ///
  /// In ko, this message translates to:
  /// **'촬영 & 저장'**
  String get grip_info1_title;

  /// No description provided for @grip_info1_desc.
  ///
  /// In ko, this message translates to:
  /// **'손을 비추면 뼈대를 추적합니다.\n가장 마음에 드는 그립을 \'기준\'으로 저장하세요.'**
  String get grip_info1_desc;

  /// No description provided for @grip_info2_title.
  ///
  /// In ko, this message translates to:
  /// **'비교/교정'**
  String get grip_info2_title;

  /// No description provided for @grip_info2_desc.
  ///
  /// In ko, this message translates to:
  /// **'기준과 달라진 손가락을 찾아내어 조언해줍니다.'**
  String get grip_info2_desc;

  /// No description provided for @grip_info3_title.
  ///
  /// In ko, this message translates to:
  /// **'수치 분석'**
  String get grip_info3_title;

  /// No description provided for @grip_info3_desc.
  ///
  /// In ko, this message translates to:
  /// **'엄지-검지 사이 거리, 손가락 굽힘 각도 등\n미세한 차이를 수치로 확인할 수 있어요.'**
  String get grip_info3_desc;

  /// No description provided for @grip_status_has.
  ///
  /// In ko, this message translates to:
  /// **'기준 그립이 저장되어 있습니다.'**
  String get grip_status_has;

  /// No description provided for @grip_status_no.
  ///
  /// In ko, this message translates to:
  /// **'아직 기준 그립이 없습니다.'**
  String get grip_status_no;

  /// No description provided for @grip_msg_has.
  ///
  /// In ko, this message translates to:
  /// **'저장된 기준 데이터를 확인하거나, 아래 버튼을 눌러 비교 훈련을 시작하세요.'**
  String get grip_msg_has;

  /// No description provided for @grip_msg_no.
  ///
  /// In ko, this message translates to:
  /// **'먼저 [촬영하기] 버튼을 눌러 기준 그립을 만들어주세요.'**
  String get grip_msg_no;

  /// No description provided for @grip_btn_view_data.
  ///
  /// In ko, this message translates to:
  /// **'저장된 기준 데이터(수치) 보기'**
  String get grip_btn_view_data;

  /// No description provided for @grip_btn_new_shoot.
  ///
  /// In ko, this message translates to:
  /// **'새로 촬영하기'**
  String get grip_btn_new_shoot;

  /// No description provided for @grip_guide_main.
  ///
  /// In ko, this message translates to:
  /// **'정확한 그립 분석을 위해\n다음 사항을 확인해 주세요.'**
  String get grip_guide_main;

  /// No description provided for @grip_guide_sub.
  ///
  /// In ko, this message translates to:
  /// **'손가락 마디와 손톱 위치가 명확할수록 분석이 정교해집니다.'**
  String get grip_guide_sub;

  /// No description provided for @grip_guide_good_title.
  ///
  /// In ko, this message translates to:
  /// **'Good: 권장하는 촬영 방법'**
  String get grip_guide_good_title;

  /// No description provided for @grip_guide_good_1.
  ///
  /// In ko, this message translates to:
  /// **'다트를 잡은 손을 \'정확한 측면(90도)\'에서 촬영해 주세요.'**
  String get grip_guide_good_1;

  /// No description provided for @grip_guide_good_2.
  ///
  /// In ko, this message translates to:
  /// **'엄지와 검지가 겹친 부위를 + 포인트에 맞춰주세요.'**
  String get grip_guide_good_2;

  /// No description provided for @grip_guide_good_3.
  ///
  /// In ko, this message translates to:
  /// **'배경이 복잡하지 않은 깔끔한 곳이 좋습니다.'**
  String get grip_guide_good_3;

  /// No description provided for @grip_guide_good_4.
  ///
  /// In ko, this message translates to:
  /// **'손목까지 화면 안에 들어오도록 거리를 조절해 주세요.'**
  String get grip_guide_good_4;

  /// No description provided for @grip_guide_good_5.
  ///
  /// In ko, this message translates to:
  /// **'조명이 밝은 곳에서 촬영해야 손가락 마디가 잘 보입니다.'**
  String get grip_guide_good_5;

  /// No description provided for @grip_guide_bad_title.
  ///
  /// In ko, this message translates to:
  /// **'Bad: 피해야 할 촬영 방법'**
  String get grip_guide_bad_title;

  /// No description provided for @grip_guide_bad_1.
  ///
  /// In ko, this message translates to:
  /// **'정면에서 찍으면 손가락 깊이(Depth) 분석이 불가능합니다.'**
  String get grip_guide_bad_1;

  /// No description provided for @grip_guide_bad_2.
  ///
  /// In ko, this message translates to:
  /// **'손가락이 다트 배럴에 완전히 가려지면 안 됩니다.'**
  String get grip_guide_bad_2;

  /// No description provided for @grip_guide_bad_3.
  ///
  /// In ko, this message translates to:
  /// **'너무 어둡거나 역광인 곳은 피해주세요.'**
  String get grip_guide_bad_3;

  /// No description provided for @grip_guide_bad_4.
  ///
  /// In ko, this message translates to:
  /// **'카메라가 너무 멀어서 손이 작게 나오면 인식이 어렵습니다.'**
  String get grip_guide_bad_4;

  /// No description provided for @grip_guide_btn_start.
  ///
  /// In ko, this message translates to:
  /// **'확인했습니다 (촬영 시작)'**
  String get grip_guide_btn_start;

  /// No description provided for @grip_auth_camera_title.
  ///
  /// In ko, this message translates to:
  /// **'카메라 권한 필요'**
  String get grip_auth_camera_title;

  /// No description provided for @grip_auth_camera_msg.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 카메라 권한을 허용해야 그립 분석 기능을 사용할 수 있습니다.'**
  String get grip_auth_camera_msg;

  /// No description provided for @grip_auth_camera_denied.
  ///
  /// In ko, this message translates to:
  /// **'촬영을 위해 카메라 권한 허용이 필요합니다.'**
  String get grip_auth_camera_denied;

  /// No description provided for @grip_auth_go_settings.
  ///
  /// In ko, this message translates to:
  /// **'설정으로 이동'**
  String get grip_auth_go_settings;

  /// No description provided for @grip_comp_title.
  ///
  /// In ko, this message translates to:
  /// **'그립 비교 촬영'**
  String get grip_comp_title;

  /// No description provided for @grip_comp_result_title.
  ///
  /// In ko, this message translates to:
  /// **'분석 결과'**
  String get grip_comp_result_title;

  /// No description provided for @grip_comp_mirror_on.
  ///
  /// In ko, this message translates to:
  /// **'기준 뼈대 반전(거울 모드)'**
  String get grip_comp_mirror_on;

  /// No description provided for @grip_comp_mirror_off.
  ///
  /// In ko, this message translates to:
  /// **'기준 뼈대 원복'**
  String get grip_comp_mirror_off;

  /// No description provided for @grip_comp_retake.
  ///
  /// In ko, this message translates to:
  /// **'재촬영'**
  String get grip_comp_retake;

  /// No description provided for @grip_comp_ai_title.
  ///
  /// In ko, this message translates to:
  /// **'AI 그립 분석 결과'**
  String get grip_comp_ai_title;

  /// No description provided for @grip_comp_info_dist.
  ///
  /// In ko, this message translates to:
  /// **'거리 분석 기준: 엄지 손톱 끝과 검지 손톱 끝 사이의 직선 거리를 비교합니다.'**
  String get grip_comp_info_dist;

  /// No description provided for @grip_comp_no_result.
  ///
  /// In ko, this message translates to:
  /// **'분석 결과가 없습니다.'**
  String get grip_comp_no_result;

  /// No description provided for @grip_comp_btn_retake.
  ///
  /// In ko, this message translates to:
  /// **'다시 촬영하기'**
  String get grip_comp_btn_retake;

  /// No description provided for @grip_comp_live_guide.
  ///
  /// In ko, this message translates to:
  /// **'손을 카메라에 비춰주세요'**
  String get grip_comp_live_guide;

  /// No description provided for @grip_comp_baseline_label.
  ///
  /// In ko, this message translates to:
  /// **'기준 그립'**
  String get grip_comp_baseline_label;

  /// No description provided for @grip_comp_shoot_guide.
  ///
  /// In ko, this message translates to:
  /// **'기준 사진과 비슷하게 잡고\n+ 중심에 맞춰 촬영하세요'**
  String get grip_comp_shoot_guide;

  /// No description provided for @grip_comp_cooldown.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 뒤 촬영 가능'**
  String grip_comp_cooldown(Object seconds);

  /// No description provided for @grip_comp_no_baseline.
  ///
  /// In ko, this message translates to:
  /// **'기준 그립이 없습니다.'**
  String get grip_comp_no_baseline;

  /// No description provided for @grip_comp_btn_go_shoot.
  ///
  /// In ko, this message translates to:
  /// **'촬영하러 가기'**
  String get grip_comp_btn_go_shoot;

  /// No description provided for @grip_cam_checking_auth.
  ///
  /// In ko, this message translates to:
  /// **'카메라 권한을 확인하고 있습니다...'**
  String get grip_cam_checking_auth;

  /// No description provided for @grip_cam_guide_center.
  ///
  /// In ko, this message translates to:
  /// **'엄지와 검지를 '**
  String get grip_cam_guide_center;

  /// No description provided for @grip_cam_guide_plus.
  ///
  /// In ko, this message translates to:
  /// **'+ 중심'**
  String get grip_cam_guide_plus;

  /// No description provided for @grip_cam_guide_align.
  ///
  /// In ko, this message translates to:
  /// **'에 맞추고\n'**
  String get grip_cam_guide_align;

  /// No description provided for @grip_cam_guide_horizon.
  ///
  /// In ko, this message translates to:
  /// **'가로선 ― '**
  String get grip_cam_guide_horizon;

  /// No description provided for @grip_cam_guide_desc.
  ///
  /// In ko, this message translates to:
  /// **'을 보며 다트의 각도(수평)를 확인하세요'**
  String get grip_cam_guide_desc;

  /// No description provided for @grip_cam_msg_detected_only.
  ///
  /// In ko, this message translates to:
  /// **'손이 인식된 상태에서만 촬영할 수 있어요.'**
  String get grip_cam_msg_detected_only;

  /// No description provided for @grip_cam_msg_save_success.
  ///
  /// In ko, this message translates to:
  /// **'✅ 기준 그립 저장 완료!'**
  String get grip_cam_msg_save_success;

  /// No description provided for @grip_cam_msg_save_error.
  ///
  /// In ko, this message translates to:
  /// **'저장 중 오류 발생: {error}'**
  String grip_cam_msg_save_error(Object error);

  /// No description provided for @grip_report_main_ctrl.
  ///
  /// In ko, this message translates to:
  /// **'메인 컨트롤 (Main Control)'**
  String get grip_report_main_ctrl;

  /// No description provided for @grip_report_support.
  ///
  /// In ko, this message translates to:
  /// **'보조 지지대 (Support Fingers)'**
  String get grip_report_support;

  /// No description provided for @grip_report_gap.
  ///
  /// In ko, this message translates to:
  /// **'엄지-검지 간격 (Gap)'**
  String get grip_report_gap;

  /// No description provided for @grip_report_index.
  ///
  /// In ko, this message translates to:
  /// **'검지 굽힘 (Index Angle)'**
  String get grip_report_index;

  /// No description provided for @grip_report_middle.
  ///
  /// In ko, this message translates to:
  /// **'중지 받침 각도 (Middle)'**
  String get grip_report_middle;

  /// No description provided for @grip_report_ring.
  ///
  /// In ko, this message translates to:
  /// **'약지 굽힘 (Ring)'**
  String get grip_report_ring;

  /// No description provided for @grip_report_pinky.
  ///
  /// In ko, this message translates to:
  /// **'소지 밸런스 (Pinky)'**
  String get grip_report_pinky;

  /// No description provided for @grip_report_tight.
  ///
  /// In ko, this message translates to:
  /// **'타이트함'**
  String get grip_report_tight;

  /// No description provided for @grip_report_wide.
  ///
  /// In ko, this message translates to:
  /// **'와이드함'**
  String get grip_report_wide;

  /// No description provided for @grip_report_bent.
  ///
  /// In ko, this message translates to:
  /// **'많이 굽힘'**
  String get grip_report_bent;

  /// No description provided for @grip_report_straight.
  ///
  /// In ko, this message translates to:
  /// **'펴짐'**
  String get grip_report_straight;

  /// No description provided for @grip_report_deep.
  ///
  /// In ko, this message translates to:
  /// **'깊게 잡음'**
  String get grip_report_deep;

  /// No description provided for @grip_report_shallow.
  ///
  /// In ko, this message translates to:
  /// **'얕게 잡음'**
  String get grip_report_shallow;

  /// No description provided for @grip_report_rolled.
  ///
  /// In ko, this message translates to:
  /// **'말아 쥠'**
  String get grip_report_rolled;

  /// No description provided for @grip_report_relaxed.
  ///
  /// In ko, this message translates to:
  /// **'편안함'**
  String get grip_report_relaxed;

  /// No description provided for @grip_report_inner.
  ///
  /// In ko, this message translates to:
  /// **'안쪽 지지'**
  String get grip_report_inner;

  /// No description provided for @grip_report_outer.
  ///
  /// In ko, this message translates to:
  /// **'바깥 지지'**
  String get grip_report_outer;

  /// No description provided for @grip_report_zoom.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 확대'**
  String get grip_report_zoom;

  /// No description provided for @grip_report_delete_confirm.
  ///
  /// In ko, this message translates to:
  /// **'기준 삭제'**
  String get grip_report_delete_confirm;

  /// No description provided for @grip_report_delete_msg.
  ///
  /// In ko, this message translates to:
  /// **'정말 삭제하시겠습니까?'**
  String get grip_report_delete_msg;

  /// No description provided for @grip_report_ad_area.
  ///
  /// In ko, this message translates to:
  /// **'AdMob 배너 광고 영역'**
  String get grip_report_ad_area;

  /// No description provided for @grip_metric_index_angle.
  ///
  /// In ko, this message translates to:
  /// **'검지 각도'**
  String get grip_metric_index_angle;

  /// No description provided for @grip_metric_thumb_dist.
  ///
  /// In ko, this message translates to:
  /// **'엄지 거리'**
  String get grip_metric_thumb_dist;

  /// No description provided for @grip_metric_stable.
  ///
  /// In ko, this message translates to:
  /// **'안정적'**
  String get grip_metric_stable;

  /// No description provided for @grip_metric_unstable.
  ///
  /// In ko, this message translates to:
  /// **'불안정'**
  String get grip_metric_unstable;

  /// No description provided for @grip_metric_gap_diff.
  ///
  /// In ko, this message translates to:
  /// **'기준 대비 차이'**
  String get grip_metric_gap_diff;

  /// No description provided for @grip_gauge_tight.
  ///
  /// In ko, this message translates to:
  /// **'타이트함'**
  String get grip_gauge_tight;

  /// No description provided for @grip_gauge_wide.
  ///
  /// In ko, this message translates to:
  /// **'와이드함'**
  String get grip_gauge_wide;

  /// No description provided for @grip_gauge_bent.
  ///
  /// In ko, this message translates to:
  /// **'많이 굽힘'**
  String get grip_gauge_bent;

  /// No description provided for @grip_gauge_straight.
  ///
  /// In ko, this message translates to:
  /// **'펴짐'**
  String get grip_gauge_straight;

  /// No description provided for @grip_gauge_deep.
  ///
  /// In ko, this message translates to:
  /// **'깊게 잡음'**
  String get grip_gauge_deep;

  /// No description provided for @grip_gauge_shallow.
  ///
  /// In ko, this message translates to:
  /// **'얕게 잡음'**
  String get grip_gauge_shallow;

  /// No description provided for @grip_preview_load_error.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 불러올 수 없어요'**
  String get grip_preview_load_error;

  /// No description provided for @grip_preview_created_at.
  ///
  /// In ko, this message translates to:
  /// **'저장일: {date}'**
  String grip_preview_created_at(Object date);

  /// No description provided for @grip_preview_frame.
  ///
  /// In ko, this message translates to:
  /// **'프레임 {id}'**
  String grip_preview_frame(Object id);

  /// No description provided for @history_no_data.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러올 수 없습니다.'**
  String get history_no_data;

  /// No description provided for @calc_start_msg.
  ///
  /// In ko, this message translates to:
  /// **'시작 점수를 입력하세요'**
  String get calc_start_msg;

  /// No description provided for @calc_start_hint.
  ///
  /// In ko, this message translates to:
  /// **'2 ~ 170'**
  String get calc_start_hint;

  /// No description provided for @calc_remain_score.
  ///
  /// In ko, this message translates to:
  /// **'남은 점수'**
  String get calc_remain_score;

  /// No description provided for @calc_current_turn.
  ///
  /// In ko, this message translates to:
  /// **'이번 턴: {score}'**
  String calc_current_turn(Object score);

  /// No description provided for @calc_recommend_title.
  ///
  /// In ko, this message translates to:
  /// **'추천 체크아웃 루트'**
  String get calc_recommend_title;

  /// No description provided for @calc_error_range.
  ///
  /// In ko, this message translates to:
  /// **'2~170 사이의 점수를 입력하세요'**
  String get calc_error_range;

  /// No description provided for @calc_error_exceed.
  ///
  /// In ko, this message translates to:
  /// **'남은 점수보다 클 수 없어요'**
  String get calc_error_exceed;

  /// No description provided for @grip_coach_gap_wide.
  ///
  /// In ko, this message translates to:
  /// **'↔️ [그립 너비] 엄지-검지가 기준보다 멉니다.'**
  String get grip_coach_gap_wide;

  /// No description provided for @grip_coach_gap_tight.
  ///
  /// In ko, this message translates to:
  /// **'-><- [그립 너비] 엄지-검지가 기준보다 가깝습니다.'**
  String get grip_coach_gap_tight;

  /// No description provided for @grip_coach_gap_perfect.
  ///
  /// In ko, this message translates to:
  /// **'✅ [그립 너비] 엄지와 검지 간격이 완벽합니다!'**
  String get grip_coach_gap_perfect;

  /// No description provided for @grip_coach_finger_straight.
  ///
  /// In ko, this message translates to:
  /// **'☝️ [{finger}] 기준보다 더 펴졌습니다.'**
  String grip_coach_finger_straight(Object finger);

  /// No description provided for @grip_coach_finger_bent.
  ///
  /// In ko, this message translates to:
  /// **'✊ [{finger}] 기준보다 더 구부러졌습니다.'**
  String grip_coach_finger_bent(Object finger);

  /// No description provided for @grip_coach_all_perfect.
  ///
  /// In ko, this message translates to:
  /// **'🎉 완벽합니다! 모든 손가락이 기준 그립과 일치합니다.'**
  String get grip_coach_all_perfect;

  /// No description provided for @grip_coach_good_job.
  ///
  /// In ko, this message translates to:
  /// **'🆗 {fingers}의 모양은 기준과 잘 맞습니다.'**
  String grip_coach_good_job(Object fingers);

  /// No description provided for @grip_coach_index.
  ///
  /// In ko, this message translates to:
  /// **'검지'**
  String get grip_coach_index;

  /// No description provided for @grip_coach_middle.
  ///
  /// In ko, this message translates to:
  /// **'중지'**
  String get grip_coach_middle;

  /// No description provided for @grip_coach_ring.
  ///
  /// In ko, this message translates to:
  /// **'약지'**
  String get grip_coach_ring;

  /// No description provided for @grip_coach_pinky.
  ///
  /// In ko, this message translates to:
  /// **'새끼손가락'**
  String get grip_coach_pinky;

  /// No description provided for @arena_title_steel.
  ///
  /// In ko, this message translates to:
  /// **'스틸리그'**
  String get arena_title_steel;

  /// No description provided for @arena_title_tournament.
  ///
  /// In ko, this message translates to:
  /// **'토너먼트'**
  String get arena_title_tournament;

  /// No description provided for @arena_menu_member.
  ///
  /// In ko, this message translates to:
  /// **'KDF 정회원'**
  String get arena_menu_member;

  /// No description provided for @arena_menu_my.
  ///
  /// In ko, this message translates to:
  /// **'내 주최 경기'**
  String get arena_menu_my;

  /// No description provided for @arena_menu_admin.
  ///
  /// In ko, this message translates to:
  /// **'메일 테스트'**
  String get arena_menu_admin;

  /// No description provided for @arena_preview_open.
  ///
  /// In ko, this message translates to:
  /// **'지금 참가 가능한 대회'**
  String get arena_preview_open;

  /// No description provided for @arena_preview_upcoming.
  ///
  /// In ko, this message translates to:
  /// **'예정된 대회'**
  String get arena_preview_upcoming;

  /// No description provided for @arena_preview_see_all.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get arena_preview_see_all;

  /// No description provided for @arena_preview_no_data.
  ///
  /// In ko, this message translates to:
  /// **'아직 {title}가 없어요'**
  String arena_preview_no_data(Object title);

  /// No description provided for @arena_preview_closed.
  ///
  /// In ko, this message translates to:
  /// **'마감됨'**
  String get arena_preview_closed;

  /// No description provided for @tournament_home_title.
  ///
  /// In ko, this message translates to:
  /// **'대회 찾기'**
  String get tournament_home_title;

  /// No description provided for @tournament_empty_open.
  ///
  /// In ko, this message translates to:
  /// **'현재 참여 가능한 대회가 없습니다.\n새로운 대회가 열리면 알려드릴게요!'**
  String get tournament_empty_open;

  /// No description provided for @tournament_empty_upcoming.
  ///
  /// In ko, this message translates to:
  /// **'아직 예정된 대회가 없습니다.\n곧 멋진 대회가 열릴 예정이니 기다려주세요.'**
  String get tournament_empty_upcoming;

  /// No description provided for @tournament_empty_closed.
  ///
  /// In ko, this message translates to:
  /// **'마감된 대회가 없습니다.'**
  String get tournament_empty_closed;

  /// No description provided for @tournament_empty_default.
  ///
  /// In ko, this message translates to:
  /// **'등록된 대회가 없습니다.\n직접 대회를 개최해 보시는 건 어떨까요?'**
  String get tournament_empty_default;

  /// No description provided for @entry_list_no_data.
  ///
  /// In ko, this message translates to:
  /// **'아직 참가자가 없습니다'**
  String get entry_list_no_data;

  /// No description provided for @entry_list_not_found.
  ///
  /// In ko, this message translates to:
  /// **'대회를 찾을 수 없습니다.'**
  String get entry_list_not_found;

  /// No description provided for @entry_list_manual.
  ///
  /// In ko, this message translates to:
  /// **'수동'**
  String get entry_list_manual;

  /// No description provided for @entry_list_team_prefix.
  ///
  /// In ko, this message translates to:
  /// **'[팀] {name}'**
  String entry_list_team_prefix(Object name);

  /// No description provided for @entry_list_team_leader.
  ///
  /// In ko, this message translates to:
  /// **'팀장: {name}'**
  String entry_list_team_leader(Object name);

  /// No description provided for @entry_list_paid.
  ///
  /// In ko, this message translates to:
  /// **'입금완료'**
  String get entry_list_paid;

  /// No description provided for @entry_list_not_paid.
  ///
  /// In ko, this message translates to:
  /// **'미입금'**
  String get entry_list_not_paid;

  /// No description provided for @entry_list_detail_no.
  ///
  /// In ko, this message translates to:
  /// **'No.{order}'**
  String entry_list_detail_no(Object order);

  /// No description provided for @entry_list_info_name.
  ///
  /// In ko, this message translates to:
  /// **'성함'**
  String get entry_list_info_name;

  /// No description provided for @entry_list_info_leader.
  ///
  /// In ko, this message translates to:
  /// **'팀장 성함'**
  String get entry_list_info_leader;

  /// No description provided for @entry_list_info_phone.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get entry_list_info_phone;

  /// No description provided for @entry_list_info_rating.
  ///
  /// In ko, this message translates to:
  /// **'레이팅'**
  String get entry_list_info_rating;

  /// No description provided for @entry_list_info_homeshop.
  ///
  /// In ko, this message translates to:
  /// **'홈샵'**
  String get entry_list_info_homeshop;

  /// No description provided for @entry_list_qna_title.
  ///
  /// In ko, this message translates to:
  /// **'신청 질문 답변'**
  String get entry_list_qna_title;

  /// No description provided for @entry_list_member_title.
  ///
  /// In ko, this message translates to:
  /// **'팀원 목록 및 개별 답변'**
  String get entry_list_member_title;

  /// No description provided for @entry_list_total_rating.
  ///
  /// In ko, this message translates to:
  /// **'팀 합계 레이팅: {rating}'**
  String entry_list_total_rating(Object rating);

  /// No description provided for @entry_list_btn_edit.
  ///
  /// In ko, this message translates to:
  /// **'정보 수정'**
  String get entry_list_btn_edit;

  /// No description provided for @entry_list_btn_delete.
  ///
  /// In ko, this message translates to:
  /// **'엔트리 삭제'**
  String get entry_list_btn_delete;

  /// No description provided for @entry_list_edit_dialog_title.
  ///
  /// In ko, this message translates to:
  /// **'참가자 정보 수정'**
  String get entry_list_edit_dialog_title;

  /// No description provided for @entry_list_edit_name_ko.
  ///
  /// In ko, this message translates to:
  /// **'한글 이름'**
  String get entry_list_edit_name_ko;

  /// No description provided for @entry_list_edit_name_en.
  ///
  /// In ko, this message translates to:
  /// **'영문 이름'**
  String get entry_list_edit_name_en;

  /// No description provided for @entry_list_edit_phone.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get entry_list_edit_phone;

  /// No description provided for @entry_list_edit_rating.
  ///
  /// In ko, this message translates to:
  /// **'레이팅 (선택)'**
  String get entry_list_edit_rating;

  /// No description provided for @entry_list_edit_homeshop.
  ///
  /// In ko, this message translates to:
  /// **'홈샵 (선택)'**
  String get entry_list_edit_homeshop;

  /// No description provided for @entry_list_delete_confirm_title.
  ///
  /// In ko, this message translates to:
  /// **'엔트리 삭제'**
  String get entry_list_delete_confirm_title;

  /// No description provided for @entry_list_delete_confirm_msg.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 참가자를 삭제하시겠습니까?'**
  String entry_list_delete_confirm_msg(Object name);

  /// No description provided for @entry_form_manual_title.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 참가자 추가'**
  String get entry_form_manual_title;

  /// No description provided for @entry_form_manual_banner.
  ///
  /// In ko, this message translates to:
  /// **'주최자 권한으로 외부 참가자를 등록합니다.\n입력한 정보는 실시간 명단에 즉시 반영됩니다.'**
  String get entry_form_manual_banner;

  /// No description provided for @entry_form_guide_team.
  ///
  /// In ko, this message translates to:
  /// **'팀 참가 신청 정보를 입력해 주세요.'**
  String get entry_form_guide_team;

  /// No description provided for @entry_form_guide_single.
  ///
  /// In ko, this message translates to:
  /// **'개인 참가 신청 정보를 입력해 주세요.'**
  String get entry_form_guide_single;

  /// No description provided for @entry_form_section_leader.
  ///
  /// In ko, this message translates to:
  /// **'팀장 정보'**
  String get entry_form_section_leader;

  /// No description provided for @entry_form_section_my.
  ///
  /// In ko, this message translates to:
  /// **'내 정보'**
  String get entry_form_section_my;

  /// No description provided for @entry_form_section_member.
  ///
  /// In ko, this message translates to:
  /// **'팀원 정보'**
  String get entry_form_section_member;

  /// No description provided for @entry_form_field_team_name.
  ///
  /// In ko, this message translates to:
  /// **'팀명'**
  String get entry_form_field_team_name;

  /// No description provided for @entry_form_field_name_ko.
  ///
  /// In ko, this message translates to:
  /// **'이름(한글)'**
  String get entry_form_field_name_ko;

  /// No description provided for @entry_form_field_name_en.
  ///
  /// In ko, this message translates to:
  /// **'이름(영문)'**
  String get entry_form_field_name_en;

  /// No description provided for @entry_form_field_phone.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get entry_form_field_phone;

  /// No description provided for @entry_form_field_rating.
  ///
  /// In ko, this message translates to:
  /// **'레이팅'**
  String get entry_form_field_rating;

  /// No description provided for @entry_form_field_rating_opt.
  ///
  /// In ko, this message translates to:
  /// **'레이팅 (선택)'**
  String get entry_form_field_rating_opt;

  /// No description provided for @entry_form_field_homeshop.
  ///
  /// In ko, this message translates to:
  /// **'홈샵 (선택)'**
  String get entry_form_field_homeshop;

  /// No description provided for @entry_form_field_member_no.
  ///
  /// In ko, this message translates to:
  /// **'팀원 {index}'**
  String entry_form_field_member_no(Object index);

  /// No description provided for @entry_form_field_required.
  ///
  /// In ko, this message translates to:
  /// **'필수 입력 항목입니다.'**
  String get entry_form_field_required;

  /// No description provided for @entry_form_btn_submit.
  ///
  /// In ko, this message translates to:
  /// **'참가 신청 완료'**
  String get entry_form_btn_submit;

  /// No description provided for @entry_form_btn_manual.
  ///
  /// In ko, this message translates to:
  /// **'수동 참가 등록 완료'**
  String get entry_form_btn_manual;

  /// No description provided for @entry_form_msg_success.
  ///
  /// In ko, this message translates to:
  /// **'참가 신청 완료!'**
  String get entry_form_msg_success;

  /// No description provided for @entry_form_msg_manual_success.
  ///
  /// In ko, this message translates to:
  /// **'수동 등록이 완료되었습니다.'**
  String get entry_form_msg_manual_success;

  /// No description provided for @entry_form_msg_fail.
  ///
  /// In ko, this message translates to:
  /// **'신청 실패: {error}'**
  String entry_form_msg_fail(Object error);

  /// No description provided for @entry_form_status_pending.
  ///
  /// In ko, this message translates to:
  /// **'신청 접수 완료'**
  String get entry_form_status_pending;

  /// No description provided for @entry_form_status_paid.
  ///
  /// In ko, this message translates to:
  /// **'입금 확인 완료!'**
  String get entry_form_status_paid;

  /// No description provided for @entry_form_desc_pending.
  ///
  /// In ko, this message translates to:
  /// **'신청서가 정상 접수되었습니다.\n주최자가 입금을 확인하면 \"입금완료\"로 변경됩니다.'**
  String get entry_form_desc_pending;

  /// No description provided for @entry_form_desc_paid.
  ///
  /// In ko, this message translates to:
  /// **'참가비 입금이 확인되었습니다.\n대회 당일 현장에서 뵙겠습니다!'**
  String get entry_form_desc_paid;

  /// No description provided for @entry_form_cancel_title.
  ///
  /// In ko, this message translates to:
  /// **'참가 취소'**
  String get entry_form_cancel_title;

  /// No description provided for @entry_form_cancel_msg.
  ///
  /// In ko, this message translates to:
  /// **'참가 신청을 취소하시겠습니까?'**
  String get entry_form_cancel_msg;

  /// No description provided for @entry_form_cancel_confirm.
  ///
  /// In ko, this message translates to:
  /// **'취소하기'**
  String get entry_form_cancel_confirm;

  /// No description provided for @entry_form_cancel_success.
  ///
  /// In ko, this message translates to:
  /// **'신청이 취소되었습니다.'**
  String get entry_form_cancel_success;

  /// No description provided for @entry_edit_title.
  ///
  /// In ko, this message translates to:
  /// **'엔트리 정보 수정'**
  String get entry_edit_title;

  /// No description provided for @entry_edit_manual_banner.
  ///
  /// In ko, this message translates to:
  /// **'오프라인으로 직접 추가한 참가자 정보입니다.'**
  String get entry_edit_manual_banner;

  /// No description provided for @entry_edit_section_setup.
  ///
  /// In ko, this message translates to:
  /// **'대회 방식 설정'**
  String get entry_edit_section_setup;

  /// No description provided for @entry_edit_section_leader.
  ///
  /// In ko, this message translates to:
  /// **'대표자(팀장) 정보'**
  String get entry_edit_section_leader;

  /// No description provided for @entry_edit_section_leader_qna.
  ///
  /// In ko, this message translates to:
  /// **'대표자 개별 답변'**
  String get entry_edit_section_leader_qna;

  /// No description provided for @entry_edit_section_member.
  ///
  /// In ko, this message translates to:
  /// **'팀원 정보 및 답변 수정'**
  String get entry_edit_section_member;

  /// No description provided for @entry_edit_success.
  ///
  /// In ko, this message translates to:
  /// **'참가 정보가 수정되었습니다.'**
  String get entry_edit_success;

  /// No description provided for @entry_edit_fail.
  ///
  /// In ko, this message translates to:
  /// **'수정 실패: {error}'**
  String entry_edit_fail(Object error);

  /// No description provided for @entry_edit_field_member_no.
  ///
  /// In ko, this message translates to:
  /// **'팀원 {index}'**
  String entry_edit_field_member_no(Object index);

  /// No description provided for @entry_edit_field_member_qna.
  ///
  /// In ko, this message translates to:
  /// **'팀원 개별 답변'**
  String get entry_edit_field_member_qna;

  /// No description provided for @tournament_edit_title.
  ///
  /// In ko, this message translates to:
  /// **'대회 수정'**
  String get tournament_edit_title;

  /// No description provided for @tournament_edit_save_success.
  ///
  /// In ko, this message translates to:
  /// **'수정되었습니다.'**
  String get tournament_edit_save_success;

  /// No description provided for @tournament_edit_poster_title.
  ///
  /// In ko, this message translates to:
  /// **'대회 포스터 수정'**
  String get tournament_edit_poster_title;

  /// No description provided for @tournament_edit_method_title.
  ///
  /// In ko, this message translates to:
  /// **'대회 방식 설정'**
  String get tournament_edit_method_title;

  /// No description provided for @tournament_edit_type_single.
  ///
  /// In ko, this message translates to:
  /// **'개인전 (Single)'**
  String get tournament_edit_type_single;

  /// No description provided for @tournament_edit_type_team.
  ///
  /// In ko, this message translates to:
  /// **'팀전 (Team)'**
  String get tournament_edit_type_team;

  /// No description provided for @tournament_edit_team_size.
  ///
  /// In ko, this message translates to:
  /// **'팀당 인원수 (대표자 포함)'**
  String get tournament_edit_team_size;

  /// No description provided for @tournament_edit_basic_title.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get tournament_edit_basic_title;

  /// No description provided for @tournament_edit_field_title.
  ///
  /// In ko, this message translates to:
  /// **'대회명'**
  String get tournament_edit_field_title;

  /// No description provided for @tournament_edit_field_location.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get tournament_edit_field_location;

  /// No description provided for @tournament_edit_field_manager.
  ///
  /// In ko, this message translates to:
  /// **'담당자 성함'**
  String get tournament_edit_field_manager;

  /// No description provided for @tournament_edit_field_contact.
  ///
  /// In ko, this message translates to:
  /// **'담당자 연락처'**
  String get tournament_edit_field_contact;

  /// No description provided for @tournament_edit_date_title.
  ///
  /// In ko, this message translates to:
  /// **'참가 및 날짜 설정'**
  String get tournament_edit_date_title;

  /// No description provided for @tournament_edit_field_fee.
  ///
  /// In ko, this message translates to:
  /// **'참가비'**
  String get tournament_edit_field_fee;

  /// No description provided for @tournament_edit_field_max.
  ///
  /// In ko, this message translates to:
  /// **'최대 인원'**
  String get tournament_edit_field_max;

  /// No description provided for @tournament_edit_field_unlimited.
  ///
  /// In ko, this message translates to:
  /// **'무제한'**
  String get tournament_edit_field_unlimited;

  /// No description provided for @tournament_edit_date_event.
  ///
  /// In ko, this message translates to:
  /// **'대회 날짜'**
  String get tournament_edit_date_event;

  /// No description provided for @tournament_edit_time_event.
  ///
  /// In ko, this message translates to:
  /// **'대회 시간'**
  String get tournament_edit_time_event;

  /// No description provided for @tournament_edit_date_entry_start.
  ///
  /// In ko, this message translates to:
  /// **'엔트리 시작'**
  String get tournament_edit_date_entry_start;

  /// No description provided for @tournament_edit_date_entry_end.
  ///
  /// In ko, this message translates to:
  /// **'엔트리 마감'**
  String get tournament_edit_date_entry_end;

  /// No description provided for @tournament_edit_desc_title.
  ///
  /// In ko, this message translates to:
  /// **'상세 안내'**
  String get tournament_edit_desc_title;

  /// No description provided for @tournament_edit_desc_hint.
  ///
  /// In ko, this message translates to:
  /// **'대회 규칙 등을 작성해주세요.'**
  String get tournament_edit_desc_hint;

  /// No description provided for @tournament_edit_custom_q_title.
  ///
  /// In ko, this message translates to:
  /// **'신청 시 추가 질문 (선택)'**
  String get tournament_edit_custom_q_title;

  /// No description provided for @tournament_edit_custom_q_hint.
  ///
  /// In ko, this message translates to:
  /// **'질문을 입력하고 추가 버튼을 누르세요.'**
  String get tournament_edit_custom_q_hint;

  /// No description provided for @tournament_edit_co_host_title.
  ///
  /// In ko, this message translates to:
  /// **'공동주최자 추가'**
  String get tournament_edit_co_host_title;

  /// No description provided for @tournament_edit_co_host_hint.
  ///
  /// In ko, this message translates to:
  /// **'이메일 입력'**
  String get tournament_edit_co_host_hint;

  /// No description provided for @tournament_edit_time_picker_title.
  ///
  /// In ko, this message translates to:
  /// **'대회 시간 수정'**
  String get tournament_edit_time_picker_title;

  /// No description provided for @tournament_detail_loading_error.
  ///
  /// In ko, this message translates to:
  /// **'데이터 로딩 중 오류가 발생했습니다.'**
  String get tournament_detail_loading_error;

  /// No description provided for @tournament_detail_not_found.
  ///
  /// In ko, this message translates to:
  /// **'존재하지 않거나 삭제된 대회입니다. 😅'**
  String get tournament_detail_not_found;

  /// No description provided for @tournament_detail_entry_count.
  ///
  /// In ko, this message translates to:
  /// **'신청 {current}/{max}명'**
  String tournament_detail_entry_count(Object current, Object max);

  /// No description provided for @tournament_detail_info_title.
  ///
  /// In ko, this message translates to:
  /// **'대회 상세 정보'**
  String get tournament_detail_info_title;

  /// No description provided for @tournament_detail_no_desc.
  ///
  /// In ko, this message translates to:
  /// **'상세 정보가 없습니다.'**
  String get tournament_detail_no_desc;

  /// No description provided for @tournament_detail_list_title.
  ///
  /// In ko, this message translates to:
  /// **'실시간 참가 명단'**
  String get tournament_detail_list_title;

  /// No description provided for @tournament_detail_no_entries.
  ///
  /// In ko, this message translates to:
  /// **'아직 신청자가 없습니다.'**
  String get tournament_detail_no_entries;

  /// No description provided for @tournament_detail_admin_title.
  ///
  /// In ko, this message translates to:
  /// **'주최자 권한'**
  String get tournament_detail_admin_title;

  /// No description provided for @tournament_detail_admin_delete.
  ///
  /// In ko, this message translates to:
  /// **'대회 삭제'**
  String get tournament_detail_admin_delete;

  /// No description provided for @tournament_detail_admin_delete_msg.
  ///
  /// In ko, this message translates to:
  /// **'참가자 명단과 포스터 사진을 포함한 모든 데이터가 영구적으로 삭제됩니다. 정말 진행하시겠습니까?'**
  String get tournament_detail_admin_delete_msg;

  /// No description provided for @tournament_detail_btn_apply.
  ///
  /// In ko, this message translates to:
  /// **'참가 신청하기'**
  String get tournament_detail_btn_apply;

  /// No description provided for @tournament_detail_btn_cancel.
  ///
  /// In ko, this message translates to:
  /// **'참가 신청 취소하기'**
  String get tournament_detail_btn_cancel;

  /// No description provided for @tournament_detail_btn_manual.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 참가자 직접 추가'**
  String get tournament_detail_btn_manual;

  /// No description provided for @tournament_detail_btn_not_period.
  ///
  /// In ko, this message translates to:
  /// **'신청 기간이 아닙니다'**
  String get tournament_detail_btn_not_period;

  /// No description provided for @tournament_detail_btn_closed.
  ///
  /// In ko, this message translates to:
  /// **'신청이 마감되었습니다'**
  String get tournament_detail_btn_closed;

  /// No description provided for @tournament_detail_manage_title.
  ///
  /// In ko, this message translates to:
  /// **'참가자 관리'**
  String get tournament_detail_manage_title;

  /// No description provided for @tournament_detail_manage_edit.
  ///
  /// In ko, this message translates to:
  /// **'참가자 정보 수정'**
  String get tournament_detail_manage_edit;

  /// No description provided for @tournament_detail_manage_pay_on.
  ///
  /// In ko, this message translates to:
  /// **'입금 확인 처리'**
  String get tournament_detail_manage_pay_on;

  /// No description provided for @tournament_detail_manage_pay_off.
  ///
  /// In ko, this message translates to:
  /// **'입금 확인 취소'**
  String get tournament_detail_manage_pay_off;

  /// No description provided for @tournament_detail_manage_delete.
  ///
  /// In ko, this message translates to:
  /// **'엔트리 강제 삭제'**
  String get tournament_detail_manage_delete;

  /// No description provided for @tournament_detail_share_title.
  ///
  /// In ko, this message translates to:
  /// **'[DAO 아레나] 새로운 다트 대회가 열렸습니다! 🎯'**
  String get tournament_detail_share_title;

  /// No description provided for @tournament_detail_share_info.
  ///
  /// In ko, this message translates to:
  /// **'🏆 대회명: {title}\n📍 장소: {location}\n📅 일시: {date}\n💰 참가비: {fee}'**
  String tournament_detail_share_info(
      Object date, Object fee, Object location, Object title);

  /// No description provided for @tournament_detail_share_footer.
  ///
  /// In ko, this message translates to:
  /// **'지금 DAO 앱에서 실시간 명단을 확인하고 신청하세요!'**
  String get tournament_detail_share_footer;

  /// No description provided for @debug_title.
  ///
  /// In ko, this message translates to:
  /// **'Tournament Debug Tools'**
  String get debug_title;

  /// No description provided for @debug_mail_section_title.
  ///
  /// In ko, this message translates to:
  /// **'테스트 메일 발송 (admin only)'**
  String get debug_mail_section_title;

  /// No description provided for @debug_mail_guide.
  ///
  /// In ko, this message translates to:
  /// **'※ functions/index.js의 관리자 UID 조건을 통과해야 동작합니다.\n※ tournamentId는 Firestore tournaments 문서 ID를 넣어주세요.'**
  String get debug_mail_guide;

  /// No description provided for @debug_mail_field_id.
  ///
  /// In ko, this message translates to:
  /// **'tournamentId'**
  String get debug_mail_field_id;

  /// No description provided for @debug_mail_field_hint.
  ///
  /// In ko, this message translates to:
  /// **'예: aBcD1234....'**
  String get debug_mail_field_hint;

  /// No description provided for @debug_mail_btn_send.
  ///
  /// In ko, this message translates to:
  /// **'테스트 메일 보내기'**
  String get debug_mail_btn_send;

  /// No description provided for @debug_mail_btn_sending.
  ///
  /// In ko, this message translates to:
  /// **'발송 중...'**
  String get debug_mail_btn_sending;

  /// No description provided for @debug_mail_tip_title.
  ///
  /// In ko, this message translates to:
  /// **'팁: tournamentId 찾는 법'**
  String get debug_mail_tip_title;

  /// No description provided for @debug_mail_tip_desc.
  ///
  /// In ko, this message translates to:
  /// **'• Firebase Console → Firestore → tournaments 컬렉션\n• 문서 클릭하면 상단에 Document ID가 tournamentId 입니다.'**
  String get debug_mail_tip_desc;

  /// No description provided for @debug_mail_msg_enter_id.
  ///
  /// In ko, this message translates to:
  /// **'tournamentId를 입력해주세요'**
  String get debug_mail_msg_enter_id;

  /// No description provided for @debug_mail_msg_success.
  ///
  /// In ko, this message translates to:
  /// **'✅ 테스트 메일 발송 요청 완료! (받은편지함/스팸함 확인)'**
  String get debug_mail_msg_success;

  /// No description provided for @debug_mail_msg_functions_error.
  ///
  /// In ko, this message translates to:
  /// **'❌ Functions 오류: {code}\n{message}'**
  String debug_mail_msg_functions_error(Object code, Object message);

  /// No description provided for @debug_mail_msg_error.
  ///
  /// In ko, this message translates to:
  /// **'❌ 오류: {error}'**
  String debug_mail_msg_error(Object error);

  /// No description provided for @tournament_create_title.
  ///
  /// In ko, this message translates to:
  /// **'대회 개설'**
  String get tournament_create_title;

  /// No description provided for @tournament_create_login_title.
  ///
  /// In ko, this message translates to:
  /// **'로그인 필요'**
  String get tournament_create_login_title;

  /// No description provided for @tournament_create_login_msg.
  ///
  /// In ko, this message translates to:
  /// **'대회를 개설하려면 로그인이 필요합니다.\n로그인 후 다시 이용해주세요.'**
  String get tournament_create_login_msg;

  /// No description provided for @tournament_create_success.
  ///
  /// In ko, this message translates to:
  /// **'대회가 성공적으로 개설되었습니다!'**
  String get tournament_create_success;

  /// No description provided for @tournament_create_poster_add.
  ///
  /// In ko, this message translates to:
  /// **'대회 포스터 추가'**
  String get tournament_create_poster_add;

  /// No description provided for @tournament_create_team_guide.
  ///
  /// In ko, this message translates to:
  /// **'※ 팀전 선택 시 신청 폼에서 팀원 정보를 추가로 입력받습니다.'**
  String get tournament_create_team_guide;

  /// No description provided for @tournament_create_email_guide.
  ///
  /// In ko, this message translates to:
  /// **'📩 엔트리 마감 시 참가자 명단이 담당자 이메일로 자동 전송됩니다.'**
  String get tournament_create_email_guide;

  /// No description provided for @tournament_create_desc_hint.
  ///
  /// In ko, this message translates to:
  /// **'대회 규칙, 상금, 경기 방식 등을 작성해주세요.'**
  String get tournament_create_desc_hint;

  /// No description provided for @tournament_create_custom_q_hint.
  ///
  /// In ko, this message translates to:
  /// **'예: 카드번호, 파트너 이름 등'**
  String get tournament_create_custom_q_hint;

  /// No description provided for @tournament_create_btn.
  ///
  /// In ko, this message translates to:
  /// **'개설하기'**
  String get tournament_create_btn;

  /// No description provided for @my_tournaments_title.
  ///
  /// In ko, this message translates to:
  /// **'내가 주최한 대회'**
  String get my_tournaments_title;

  /// No description provided for @my_tournaments_no_data.
  ///
  /// In ko, this message translates to:
  /// **'아직 주최한 대회가 없어요'**
  String get my_tournaments_no_data;

  /// No description provided for @my_tournaments_no_data_guide.
  ///
  /// In ko, this message translates to:
  /// **'지금 바로 첫 대회를 만들어보세요!'**
  String get my_tournaments_no_data_guide;

  /// No description provided for @my_tournaments_error.
  ///
  /// In ko, this message translates to:
  /// **'대회 정보를 불러오는 중 오류가 발생했습니다.'**
  String get my_tournaments_error;

  /// No description provided for @my_tournaments_btn_create.
  ///
  /// In ko, this message translates to:
  /// **'대회 개최하기'**
  String get my_tournaments_btn_create;

  /// No description provided for @tournament_filter_all.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get tournament_filter_all;

  /// No description provided for @tournament_filter_open.
  ///
  /// In ko, this message translates to:
  /// **'진행중'**
  String get tournament_filter_open;

  /// No description provided for @tournament_filter_upcoming.
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get tournament_filter_upcoming;

  /// No description provided for @tournament_filter_closed.
  ///
  /// In ko, this message translates to:
  /// **'마감'**
  String get tournament_filter_closed;

  /// No description provided for @common_free.
  ///
  /// In ko, this message translates to:
  /// **'무료'**
  String get common_free;

  /// No description provided for @common_unit_people.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String common_unit_people(Object count);

  /// No description provided for @common_currency_won.
  ///
  /// In ko, this message translates to:
  /// **'원'**
  String get common_currency_won;

  /// No description provided for @arena_dday_today.
  ///
  /// In ko, this message translates to:
  /// **'오늘!'**
  String get arena_dday_today;

  /// No description provided for @arena_capacity_full.
  ///
  /// In ko, this message translates to:
  /// **'매진'**
  String get arena_capacity_full;

  /// No description provided for @arena_status_open.
  ///
  /// In ko, this message translates to:
  /// **'참가 가능'**
  String get arena_status_open;

  /// No description provided for @arena_status_upcoming.
  ///
  /// In ko, this message translates to:
  /// **'접수 예정'**
  String get arena_status_upcoming;

  /// No description provided for @arena_status_closed.
  ///
  /// In ko, this message translates to:
  /// **'접수 마감'**
  String get arena_status_closed;

  /// No description provided for @arena_status_in_progress.
  ///
  /// In ko, this message translates to:
  /// **'경기 중'**
  String get arena_status_in_progress;

  /// No description provided for @arena_status_finished.
  ///
  /// In ko, this message translates to:
  /// **'대회 종료'**
  String get arena_status_finished;

  /// No description provided for @arena_status_canceled.
  ///
  /// In ko, this message translates to:
  /// **'대회 취소'**
  String get arena_status_canceled;

  /// No description provided for @common_ok.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get common_ok;

  /// No description provided for @common_no.
  ///
  /// In ko, this message translates to:
  /// **'아니오'**
  String get common_no;

  /// No description provided for @common_save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get common_save;

  /// No description provided for @common_select.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get common_select;

  /// No description provided for @common_people.
  ///
  /// In ko, this message translates to:
  /// **'명'**
  String get common_people;

  /// No description provided for @common_admin_authority.
  ///
  /// In ko, this message translates to:
  /// **'관리자 권한'**
  String get common_admin_authority;

  /// No description provided for @login_required.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다.'**
  String get login_required;

  /// No description provided for @entry_edit_setup.
  ///
  /// In ko, this message translates to:
  /// **'대회 방식 설정'**
  String get entry_edit_setup;

  /// No description provided for @league_schedule_empty_day.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 선택하세요'**
  String get league_schedule_empty_day;

  /// No description provided for @league_schedule_no_events.
  ///
  /// In ko, this message translates to:
  /// **'경기 없음'**
  String get league_schedule_no_events;

  /// No description provided for @league_schedule_match_suffix.
  ///
  /// In ko, this message translates to:
  /// **'{shop} 경기'**
  String league_schedule_match_suffix(Object shop);

  /// No description provided for @league_schedule_status_completed.
  ///
  /// In ko, this message translates to:
  /// **'종료됨'**
  String get league_schedule_status_completed;

  /// No description provided for @league_schedule_status_ongoing.
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get league_schedule_status_ongoing;

  /// No description provided for @league_schedule_status_upcoming.
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get league_schedule_status_upcoming;

  /// No description provided for @league_schedule_winner.
  ///
  /// In ko, this message translates to:
  /// **'우승자: {name}'**
  String league_schedule_winner(Object name);

  /// No description provided for @league_schedule_detail_date.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get league_schedule_detail_date;

  /// No description provided for @league_schedule_detail_time.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get league_schedule_detail_time;

  /// No description provided for @league_schedule_detail_location.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get league_schedule_detail_location;

  /// No description provided for @league_schedule_detail_fee.
  ///
  /// In ko, this message translates to:
  /// **'참가비'**
  String get league_schedule_detail_fee;

  /// No description provided for @league_schedule_detail_admin.
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get league_schedule_detail_admin;

  /// No description provided for @league_schedule_detail_contact.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get league_schedule_detail_contact;

  /// No description provided for @league_schedule_detail_status.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get league_schedule_detail_status;

  /// No description provided for @league_schedule_no_photo.
  ///
  /// In ko, this message translates to:
  /// **'사진 없음'**
  String get league_schedule_no_photo;

  /// No description provided for @ranking_title.
  ///
  /// In ko, this message translates to:
  /// **'스틸리그 랭킹'**
  String get ranking_title;

  /// No description provided for @ranking_filter_title.
  ///
  /// In ko, this message translates to:
  /// **'필터'**
  String get ranking_filter_title;

  /// No description provided for @ranking_filter_year.
  ///
  /// In ko, this message translates to:
  /// **'연도'**
  String get ranking_filter_year;

  /// No description provided for @ranking_filter_season.
  ///
  /// In ko, this message translates to:
  /// **'시즌'**
  String get ranking_filter_season;

  /// No description provided for @ranking_filter_gender.
  ///
  /// In ko, this message translates to:
  /// **'성별'**
  String get ranking_filter_gender;

  /// No description provided for @ranking_filter_mode.
  ///
  /// In ko, this message translates to:
  /// **'방식'**
  String get ranking_filter_mode;

  /// No description provided for @ranking_filter_season_total.
  ///
  /// In ko, this message translates to:
  /// **'통합'**
  String get ranking_filter_season_total;

  /// No description provided for @ranking_filter_season_1.
  ///
  /// In ko, this message translates to:
  /// **'시즌1'**
  String get ranking_filter_season_1;

  /// No description provided for @ranking_filter_season_2.
  ///
  /// In ko, this message translates to:
  /// **'시즌2'**
  String get ranking_filter_season_2;

  /// No description provided for @ranking_filter_season_3.
  ///
  /// In ko, this message translates to:
  /// **'시즌3'**
  String get ranking_filter_season_3;

  /// No description provided for @ranking_filter_gender_all.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get ranking_filter_gender_all;

  /// No description provided for @ranking_filter_gender_male.
  ///
  /// In ko, this message translates to:
  /// **'남자'**
  String get ranking_filter_gender_male;

  /// No description provided for @ranking_filter_gender_female.
  ///
  /// In ko, this message translates to:
  /// **'여자'**
  String get ranking_filter_gender_female;

  /// No description provided for @ranking_filter_mode_total.
  ///
  /// In ko, this message translates to:
  /// **'종합'**
  String get ranking_filter_mode_total;

  /// No description provided for @ranking_filter_mode_top9.
  ///
  /// In ko, this message translates to:
  /// **'상위 9개'**
  String get ranking_filter_mode_top9;

  /// No description provided for @ranking_no_data.
  ///
  /// In ko, this message translates to:
  /// **'랭킹 데이터가 없습니다.\n포인트를 부여해 보세요!'**
  String get ranking_no_data;

  /// No description provided for @ranking_load_error.
  ///
  /// In ko, this message translates to:
  /// **'랭킹 로드 오류'**
  String get ranking_load_error;

  /// No description provided for @ranking_total_points.
  ///
  /// In ko, this message translates to:
  /// **'전체: {points}'**
  String ranking_total_points(Object points);

  /// No description provided for @point_calendar_title.
  ///
  /// In ko, this message translates to:
  /// **'스틸리그 포인트 달력'**
  String get point_calendar_title;

  /// No description provided for @point_calendar_search_hint.
  ///
  /// In ko, this message translates to:
  /// **'이름 검색 (한글/영어)'**
  String get point_calendar_search_hint;

  /// No description provided for @point_calendar_no_selection.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 선택하세요'**
  String get point_calendar_no_selection;

  /// No description provided for @point_calendar_no_data.
  ///
  /// In ko, this message translates to:
  /// **'해당 날짜에 포인트 내역 없음'**
  String get point_calendar_no_data;

  /// No description provided for @point_calendar_search_empty.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과 없음'**
  String get point_calendar_search_empty;

  /// No description provided for @point_calendar_label_season.
  ///
  /// In ko, this message translates to:
  /// **'{year} 시즌 {phase}'**
  String point_calendar_label_season(Object phase, Object year);

  /// No description provided for @point_calendar_label_total.
  ///
  /// In ko, this message translates to:
  /// **'{year} 통합'**
  String point_calendar_label_total(Object year);

  /// No description provided for @selection_title.
  ///
  /// In ko, this message translates to:
  /// **'선발 선수'**
  String get selection_title;

  /// No description provided for @selection_header_title.
  ///
  /// In ko, this message translates to:
  /// **'KDF 스틸리그 선발 선수'**
  String get selection_header_title;

  /// No description provided for @selection_header_desc.
  ///
  /// In ko, this message translates to:
  /// **'시즌 1–3, 통합 포인트를 기준으로\n남녀 각 1명씩 총 8명의 선수가 선발됩니다.'**
  String get selection_header_desc;

  /// No description provided for @selection_label_male.
  ///
  /// In ko, this message translates to:
  /// **'남자 대표'**
  String get selection_label_male;

  /// No description provided for @selection_label_female.
  ///
  /// In ko, this message translates to:
  /// **'여자 대표'**
  String get selection_label_female;

  /// No description provided for @selection_status_empty.
  ///
  /// In ko, this message translates to:
  /// **'아직 선발된 선수가 없습니다.'**
  String get selection_status_empty;

  /// No description provided for @selection_status_upcoming.
  ///
  /// In ko, this message translates to:
  /// **'선발 예정'**
  String get selection_status_upcoming;

  /// No description provided for @selection_label_season1.
  ///
  /// In ko, this message translates to:
  /// **'시즌 1 대표'**
  String get selection_label_season1;

  /// No description provided for @selection_label_season2.
  ///
  /// In ko, this message translates to:
  /// **'시즌 2 대표'**
  String get selection_label_season2;

  /// No description provided for @selection_label_season3.
  ///
  /// In ko, this message translates to:
  /// **'시즌 3 대표'**
  String get selection_label_season3;

  /// No description provided for @selection_label_total.
  ///
  /// In ko, this message translates to:
  /// **'통합 대표'**
  String get selection_label_total;

  /// No description provided for @selection_sub_total.
  ///
  /// In ko, this message translates to:
  /// **'전체 시즌 통합'**
  String get selection_sub_total;

  /// No description provided for @selection_shop_prefix.
  ///
  /// In ko, this message translates to:
  /// **'소속: {shop}'**
  String selection_shop_prefix(Object shop);

  /// No description provided for @member_list_search_hint.
  ///
  /// In ko, this message translates to:
  /// **'이름 또는 이메일로 검색'**
  String get member_list_search_hint;

  /// No description provided for @member_list_no_data.
  ///
  /// In ko, this message translates to:
  /// **'등록된 정회원이 없습니다.'**
  String get member_list_no_data;

  /// No description provided for @member_list_no_name.
  ///
  /// In ko, this message translates to:
  /// **'이름 없음'**
  String get member_list_no_name;

  /// No description provided for @member_list_no_email.
  ///
  /// In ko, this message translates to:
  /// **'이메일 없음'**
  String get member_list_no_email;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
