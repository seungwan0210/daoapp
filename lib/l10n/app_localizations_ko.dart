// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get badge_name_pro => '프로';

  @override
  String get badge_name_emerald => '에메랄드';

  @override
  String get badge_name_diamond => '다이아몬드';

  @override
  String get badge_name_platinum => '플래티넘';

  @override
  String get badge_name_gold => '골드';

  @override
  String get badge_name_silver => '실버';

  @override
  String get badge_name_bronze => '브론즈';

  @override
  String get badge_name_platinum1 => '플래티넘 1';

  @override
  String get badge_name_platinum2 => '플래티넘 2';

  @override
  String get badge_name_gold1 => '골드 1';

  @override
  String get badge_name_gold2 => '골드 2';

  @override
  String get badge_name_silver1 => '실버 1';

  @override
  String get badge_name_silver2 => '실버 2';

  @override
  String get badge_name_bronze1 => '브론즈 1';

  @override
  String get badge_name_bronze2 => '브론즈 2';

  @override
  String get badge_name_bronze3 => '브론즈 3';

  @override
  String get badge_name_trophy => '트로피';

  @override
  String get badge_name_season_champion => '시즌 우승자';

  @override
  String get badge_name_season_rank1 => '시즌 1위';

  @override
  String get badge_name_season_rank2 => '시즌 2위';

  @override
  String get badge_name_season_rank3 => '시즌 3위';

  @override
  String get badge_name_season_general => '시즌 배지';

  @override
  String get badge_name_monthly => '월간 배지';

  @override
  String get menu_home => '홈';

  @override
  String get menu_training => '트레이닝';

  @override
  String get menu_arena => '아레나';

  @override
  String get menu_community => '커뮤니티';

  @override
  String get menu_mypage => '마이페이지';

  @override
  String get menu_settings => '설정';

  @override
  String get menu_notice => '공지사항';

  @override
  String get menu_report => '문의 및 신고';

  @override
  String get menu_quick_arena => '아레나';

  @override
  String get menu_quick_league => '스틸리그';

  @override
  String get menu_quick_tournament => '토너먼트';

  @override
  String get menu_quick_training => '트레이닝';

  @override
  String get menu_quick_pose => '포즈분석';

  @override
  String get menu_quick_grip => '그립랩';

  @override
  String get menu_quick_profile => '프로필';

  @override
  String get menu_quick_mylog => '마이로그';

  @override
  String get menu_quick_livetalk => '라이브톡';

  @override
  String get menu_quick_circle => '서클';

  @override
  String get menu_quick_block => '차단관리';

  @override
  String get menu_quick_report => '신고/버그';

  @override
  String get nav_tab_home => '홈';

  @override
  String get nav_tab_training => '트레이닝';

  @override
  String get nav_tab_arena => '아레나';

  @override
  String get nav_tab_community => '커뮤니티';

  @override
  String get nav_tab_mypage => '내정보';

  @override
  String get drill_history => '훈련 히스토리';

  @override
  String get checkout_calculator => '체크아웃 계산기';

  @override
  String get drill_run_title => '드릴 진행';

  @override
  String get drill_difficulty_easy => '쉬움';

  @override
  String get drill_difficulty_normal => '보통';

  @override
  String get drill_difficulty_hard => '어려움';

  @override
  String get drill_difficulty_within => '이내';

  @override
  String get drill_category_boardMapping => '보드 맵핑';

  @override
  String get drill_category_scoring => '점수 획득';

  @override
  String get drill_category_finish => '피니시';

  @override
  String get drill_category_doublePractice => '더블 연습';

  @override
  String get drill_category_bull => '불 연습';

  @override
  String get drill_category_other => '기타';

  @override
  String get guide_target_hit => '목표 영역에 다트를 던지고 명중 개수를 입력하세요.';

  @override
  String get guide_finish_desc => '최대 3다트 안에 더블 아웃으로 마무리하세요.';

  @override
  String get guide_mpr_goal => '목표: 평균 MPR 2.0 이상!';

  @override
  String get tier_beginner => '비기너';

  @override
  String get tier_learner => '러너';

  @override
  String get tier_competitor => '컴페티터';

  @override
  String get tier_challenger => '챌린저';

  @override
  String get tier_elite => '엘리트';

  @override
  String get tier_pro => '프로';

  @override
  String get tier_master => '마스터';

  @override
  String get status_upcoming => '엔트리 예정';

  @override
  String get status_open => '엔트리 오픈';

  @override
  String get status_closed => '엔트리 마감';

  @override
  String get status_in_progress => '진행 중';

  @override
  String get status_finished => '종료';

  @override
  String get status_canceled => '취소됨';

  @override
  String get time_just_now => '방금 전';

  @override
  String time_minutes_ago(Object count) {
    return '$count분 전';
  }

  @override
  String time_hours_ago(Object count) {
    return '$count시간 전';
  }

  @override
  String get grip_perfect => '완벽합니다!';

  @override
  String grip_good_shape(Object finger) {
    return '$finger의 모양은 기준과 잘 맞습니다.';
  }

  @override
  String get grip_wide => '엄지-검지가 기준보다 멉니다.';

  @override
  String get grip_narrow => '엄지-검지가 기준보다 가깝습니다.';

  @override
  String get grip_too_straight => '기준보다 더 펴졌습니다.';

  @override
  String get grip_too_curved => '기준보다 더 구부러졌습니다.';

  @override
  String cycle_label_format(Object tier) {
    return '$tier 사이클';
  }

  @override
  String cycle_old_format(Object number) {
    return '사이클 $number';
  }

  @override
  String get err_login_required => '로그인이 필요한 서비스입니다.';

  @override
  String get err_save_failed => '기록 저장에 실패했습니다';

  @override
  String get name_no_name => '이름 없음';

  @override
  String get calc_btn_reset => '다시 시작';

  @override
  String get calc_undo => '되돌리기';

  @override
  String get calc_title => '체크아웃 계산기';

  @override
  String get practice_msg_bust => '버스트!';

  @override
  String get practice_msg_success => '체크아웃 성공!';

  @override
  String get practice_msg_finish => '모든 문제를 완료했습니다.';

  @override
  String get state_loading => '불러오는 중...';

  @override
  String get err_fetch_baseline => '기준 그립을 불러오지 못했어요.';

  @override
  String get err_save_baseline => '기준 그립 저장에 실패했어요.';

  @override
  String get err_delete_baseline => '기준 그립 삭제에 실패했어요.';

  @override
  String get err_session_start => '세션 시작 실패';

  @override
  String get err_session_save => '세션 저장 실패';

  @override
  String get msg_video_selected => '영상 선택 완료';

  @override
  String get msg_processing_video => '영상 처리 중...';

  @override
  String get msg_analysis_complete => '분석 완료!';

  @override
  String get msg_video_saved_gallery => '분석 영상이 갤러리에 저장되었습니다! 🎉';

  @override
  String get msg_video_save_failed => '영상 생성에 실패했습니다.';

  @override
  String get part_right_wrist => '오른손목';

  @override
  String get part_left_wrist => '왼손목';

  @override
  String get part_right_elbow => '오른쪽 팔꿈치';

  @override
  String get part_left_elbow => '왼쪽 팔꿈치';

  @override
  String get part_right_shoulder => '오른쪽 어깨';

  @override
  String get part_left_shoulder => '왼쪽 어깨';

  @override
  String get auth_login_prompt => '커뮤니티를 이용하려면 로그인이 필요해요';

  @override
  String get auth_verify_required => '커뮤니티 이용을 위해 인증이 필요해요';

  @override
  String get auth_profile_needed => '프로필 등록을 완료해 주세요';

  @override
  String get auth_phone_needed => '휴대폰 인증을 완료해 주세요';

  @override
  String get filter_all => '전체';

  @override
  String get filter_open => '엔트리 오픈';

  @override
  String get filter_upcoming => '예정';

  @override
  String get filter_closed => '마감';

  @override
  String get filter_in_progress => '진행중';

  @override
  String get filter_season_label => '시즌';

  @override
  String get filter_year_label => '연도';

  @override
  String get filter_top9 => '상위 9개';

  @override
  String get rank_total_points => '총 포인트';

  @override
  String get rank_phase_total => '누적';

  @override
  String get rank_gender_all => '남녀 통합';

  @override
  String get rank_gender_male => '남자';

  @override
  String get rank_gender_female => '여자';

  @override
  String get msg_no_notices => '새로운 공지사항이 없습니다.';

  @override
  String get common_search_hint => '이름 또는 이메일로 검색';

  @override
  String get common_no_data => '등록된 정보가 없습니다.';

  @override
  String get common_close => '닫기';

  @override
  String get common_winner => '성공 세트';

  @override
  String get common_location => '장소';

  @override
  String get common_fee => '참가비';

  @override
  String get common_share => '공유';

  @override
  String get common_edit => '수정';

  @override
  String get common_delete => '삭제';

  @override
  String get common_confirm => '확인';

  @override
  String get common_cancel => '취소';

  @override
  String get common_back => '뒤로 가기';

  @override
  String get common_msg_deleted => '삭제되었습니다';

  @override
  String get common_msg_img_err => '이미지를 불러올 수 없어요';

  @override
  String get member_list_title => 'KDF 정회원 명단';

  @override
  String get player_selection_title => '선발 선수';

  @override
  String get player_selection_desc =>
      '시즌 1–3, 통합 포인트를 기준으로 남녀 각 1명씩 총 8명의 선수가 선발됩니다.';

  @override
  String get player_rep_male => '남자 대표';

  @override
  String get player_rep_female => '여자 대표';

  @override
  String get player_upcoming => '선발 예정';

  @override
  String get league_calendar_title => '스틸리그 포인트 달력';

  @override
  String get league_schedule_title => '스틸리그 경기 일정';

  @override
  String get league_ranking_title => '스틸리그 랭킹';

  @override
  String tourney_count_unlimited(Object count) {
    return '참가 $count명';
  }

  @override
  String tourney_count_fixed(Object count, Object max) {
    return '$count/$max명';
  }

  @override
  String get tourney_fee_free => '무료 입장';

  @override
  String tourney_fee_format(Object amount) {
    return '$amount원';
  }

  @override
  String get tourney_today => '오늘!';

  @override
  String tourney_dday(Object day) {
    return 'D-$day';
  }

  @override
  String get tourney_closed => '마감됨';

  @override
  String get img_error_poster => '포스터 이미지를 불러올 수 없습니다.';

  @override
  String get tourney_my_hosted => '내가 주최한 대회';

  @override
  String get tourney_create_title => '대회 개설';

  @override
  String get tourney_edit_title => '대회 수정';

  @override
  String get tourney_detail_title => '대회 상세';

  @override
  String get tourney_btn_apply => '참가 신청하기';

  @override
  String get tourney_btn_cancel_apply => '참가 신청 취소';

  @override
  String get tourney_btn_delete => '대회 삭제하기';

  @override
  String get tourney_full_capacity => '정원이 가득 찼습니다.';

  @override
  String get form_label_title => '대회명';

  @override
  String get form_label_location => '장소';

  @override
  String get form_label_host_name => '담당자 이름';

  @override
  String get form_label_host_phone => '담당자 연락처';

  @override
  String get form_label_fee => '참가비';

  @override
  String get form_label_max_players => '최대 인원';

  @override
  String get form_label_desc => '상세 안내';

  @override
  String get form_hint_desc => '대회 규칙, 상금 등을 자세히 작성해주세요';

  @override
  String get msg_save_success => '저장되었습니다.';

  @override
  String get msg_delete_confirm => '이 댓글을 삭제하시겠습니까?';

  @override
  String get msg_err_login_needed => '로그인 후 이용 가능합니다.';

  @override
  String get msg_err_date_order => '날짜 설정 순서를 확인해주세요.';

  @override
  String get arena_league_title => '스틸리그';

  @override
  String get arena_menu_ranking => '랭킹';

  @override
  String get arena_menu_schedule => '리그 일정';

  @override
  String get arena_menu_calendar => '포인트 달력';

  @override
  String get arena_menu_kdf_member => 'KDF 정회원';

  @override
  String get arena_menu_selection => '선발 선수';

  @override
  String get arena_tourney_title => '토너먼트';

  @override
  String get arena_menu_create => '개최하기';

  @override
  String get arena_menu_open => '참가 가능';

  @override
  String get arena_menu_upcoming => '예정 경기';

  @override
  String get arena_menu_my_hosted => '내 주최 경기';

  @override
  String get arena_preview_available => '지금 참가 가능한 대회';

  @override
  String get entry_form_title => '참가 신청';

  @override
  String get entry_label_name_ko => '한글이름 *';

  @override
  String get entry_label_name_en => '영문이름 *';

  @override
  String get entry_label_phone => '연락처 *';

  @override
  String get entry_label_rating => '레이팅 (선택)';

  @override
  String get entry_label_homeshop => '홈샵 (선택)';

  @override
  String get entry_msg_already => '이미 참가 신청하셨습니다.';

  @override
  String get entry_msg_full => '정원 마감';

  @override
  String get entry_btn_submit => '참가 신청 완료';

  @override
  String get entry_list_title => '참가자 명단';

  @override
  String get entry_list_empty => '아직 참가자가 없습니다';

  @override
  String entry_detail_no(Object number) {
    return 'No.$number';
  }

  @override
  String get entry_delete_confirm => '엔트리를 삭제하시겠습니까?';

  @override
  String get comm_comment_title => '댓글';

  @override
  String get comm_hint_input => '댓글을 입력하세요...';

  @override
  String get comm_no_comments => '아직 댓글이 없습니다';

  @override
  String get comm_view_all => '댓글 모두 보기';

  @override
  String get comm_more => '더보기';

  @override
  String get comm_less => '간략히';

  @override
  String get comm_unknown_user => '익명';

  @override
  String get report_title_post => '게시물 신고';

  @override
  String get report_title_comment => '댓글 신고';

  @override
  String get report_select_reason => '사유를 선택해 주세요';

  @override
  String get report_reason_spam => '스팸/도배';

  @override
  String get report_reason_abuse => '욕설/비하';

  @override
  String get report_reason_hate => '혐오/차별';

  @override
  String get report_reason_sexual => '성적/선정성';

  @override
  String get report_reason_privacy => '개인정보 노출';

  @override
  String get report_reason_other => '기타';

  @override
  String get block_user_title => '사용자 차단';

  @override
  String get block_user_desc => '이 사용자를 차단할까요? 게시글/댓글이 보이지 않게 됩니다.';

  @override
  String get msg_report_submitted => '신고가 접수되었습니다';

  @override
  String get msg_block_done => '차단 완료';

  @override
  String get circle_title_feed => '피드';

  @override
  String get circle_no_posts => '아직 게시물이 없습니다';

  @override
  String get circle_label_text_only => '글';

  @override
  String get circle_msg_load_error => '피드를 불러오지 못했습니다';

  @override
  String get circle_btn_see_all => '전체 보기';

  @override
  String get post_write_title => '서클에 공유하기';

  @override
  String get post_edit_title => '게시물 수정';

  @override
  String get post_hint_content => '무슨 생각을 하고 계신가요?';

  @override
  String get post_hint_from_mylog => '마이로그를 다듬어서 공유해 보세요';

  @override
  String get post_btn_submit => '게시';

  @override
  String get post_btn_update => '수정';

  @override
  String get post_add_photo => '사진 추가하기';

  @override
  String get post_change_photo => '변경';

  @override
  String get post_delete_confirm_title => '삭제 확인';

  @override
  String get post_delete_confirm_msg => '이 게시물을 삭제하시겠습니까?';

  @override
  String get post_msg_upload_fail => '업로드 실패';

  @override
  String get post_msg_need_content => '내용 또는 사진을 추가해주세요';

  @override
  String get ugc_gate_title => '커뮤니티 이용 동의가 필요해요';

  @override
  String get ugc_gate_btn_accept => '동의하고 시작';

  @override
  String get comm_online_empty => '온라인 유저 없음';

  @override
  String get comm_main_grid_title => '연습 · 대회 · 기록';

  @override
  String get comm_menu_training => '트레이닝';

  @override
  String get comm_menu_arena => '아레나';

  @override
  String get comm_menu_mylog => '마이로그';

  @override
  String get comm_tab_recent => '최근';

  @override
  String get comm_tab_popular => '인기';

  @override
  String get comm_summary_title => '오늘 커뮤니티';

  @override
  String get comm_stat_posts => '게시글';

  @override
  String get comm_stat_comments => '댓글';

  @override
  String get comm_stat_likes => '좋아요';

  @override
  String get comm_live_posts => '지금 올라온 글';

  @override
  String get auth_login_needed => '커뮤니티를 이용하려면 로그인이 필요해요';

  @override
  String get auth_verify_needed => '커뮤니티 이용을 위해 인증이 필요해요';

  @override
  String get auth_profile_incomplete => '프로필 등록을 완료해 주세요.';

  @override
  String get auth_phone_incomplete => '휴대폰 인증을 완료해 주세요.';

  @override
  String get comm_btn_agree_start => '동의하고 시작';

  @override
  String get home_title_news => '최신 뉴스';

  @override
  String get home_title_event => '다음 경기 일정';

  @override
  String get home_title_ranking => '스틸리그 포인트';

  @override
  String get home_title_photos => '대회 사진';

  @override
  String get home_title_sponsor => '스폰서';

  @override
  String get home_btn_see_all => '전체 보기';

  @override
  String get home_btn_shortcut => '바로가기';

  @override
  String get home_training_title => 'DAO 트레이닝';

  @override
  String home_training_gauge(Object percent) {
    return '성장 게이지 $percent%';
  }

  @override
  String home_training_prompt(Object tier) {
    return '$tier 티어, 오늘도 연습 시작해볼까요?';
  }

  @override
  String get home_training_no_tier => '내 등급을 등록하면 DAO가 딱 맞는 드릴을 추천해줄게요.';

  @override
  String get home_training_check_tier => '내 등급 확인';

  @override
  String get home_training_empty => '아직 기록된 트레이닝이 없습니다.';

  @override
  String get day_mon => '월';

  @override
  String get day_tue => '화';

  @override
  String get day_wed => '수';

  @override
  String get day_thu => '목';

  @override
  String get day_fri => '금';

  @override
  String get day_sat => '토';

  @override
  String get day_sun => '일';

  @override
  String get login_slogan => 'Every Point Is Your Story';

  @override
  String get login_btn_google => 'Google로 로그인';

  @override
  String get login_btn_apple => 'Apple로 로그인';

  @override
  String get login_btn_skip => '건너뛰기';

  @override
  String get login_admin_toggle => '운영자 전용 로그인';

  @override
  String get login_admin_notice => '운영자 · 심사용 계정에만 사용하는 로그인 방식입니다.';

  @override
  String get login_msg_fail_email => '이메일 로그인에 실패했습니다.';

  @override
  String get mylog_title => '나의 다트 일기';

  @override
  String get mylog_summary_title => '차곡차곡 쌓이는 성장';

  @override
  String mylog_summary_count(Object count) {
    return '총 $count번의 기록이 모였어요.';
  }

  @override
  String get mylog_stat_streak => '연속 기록';

  @override
  String get mylog_stat_first => '첫 기록';

  @override
  String get mylog_stat_latest => '최근 기록';

  @override
  String get mylog_calendar_hint =>
      '날짜를 탭해서 다트 일기를 작성하거나, 이미 남긴 기록을 다시 볼 수 있어요.';

  @override
  String get mylog_write_new => '마이로그 작성';

  @override
  String get mylog_write_edit => '마이로그 수정';

  @override
  String get mylog_add_photo => '사진 추가하기 (선택)';

  @override
  String get mylog_template_good => '잘 된 점 💪';

  @override
  String get mylog_template_bad => '아쉬웠던 점 🧐';

  @override
  String get mylog_template_plan => '다음 연습 계획 ✏️';

  @override
  String get mylog_share_circle => '서클에 공유하기';

  @override
  String get mylog_msg_save_done => '마이로그 저장 완료!';

  @override
  String get auth_phone_hint => '010으로 시작하는 11자리 번호를 입력하세요';

  @override
  String get auth_code_sent => '인증번호가 전송되었습니다';

  @override
  String get auth_code_expired => '인증번호가 만료되었습니다. 다시 요청하세요';

  @override
  String get auth_code_invalid => '6자리 숫자 인증번호를 입력하세요';

  @override
  String get auth_verify_success => '휴대폰 번호가 성공적으로 인증되었습니다!';

  @override
  String get auth_verify_fail => '인증 실패';

  @override
  String get profile_msg_saving => '저장 중입니다. 잠시만 기다려주세요.';

  @override
  String get profile_save_success => '프로필이 저장되었습니다.';

  @override
  String get profile_img_delete_title => '사진 삭제';

  @override
  String get profile_img_delete_msg => '정말로 이 사진을 삭제하시겠습니까?';

  @override
  String get profile_err_input => '값을 입력해 주세요.';

  @override
  String get profile_err_phone_first => '전화번호 인증을 완료해주세요!';

  @override
  String get profile_none => '프로필 없음';

  @override
  String get profile_incomplete => '프로필 미완료';

  @override
  String get profile_no_name => '이름 없음';

  @override
  String get profile_no_content => '내용이 없는 기록입니다.';

  @override
  String get profile_label_ko_name => '한국 이름';

  @override
  String get profile_label_en_name => '영어 이름';

  @override
  String get profile_label_shop => '샵 이름';

  @override
  String get profile_err_ko_name => '한국 이름을 입력하세요';

  @override
  String get profile_err_en_name => '영어 이름을 입력하세요';

  @override
  String get profile_err_shop => '샵 이름을 입력하세요';

  @override
  String get gear_title_section => '배럴 세팅 (선택)';

  @override
  String get gear_player_equipment => '플레이어 장비';

  @override
  String get gear_label_barrel => '배럴';

  @override
  String get gear_label_shaft => '샤프트';

  @override
  String get gear_label_flight => '플라이트';

  @override
  String get gear_label_tip => '팁';

  @override
  String get auth_btn_change => '변경';

  @override
  String get auth_btn_cancel => '취소';

  @override
  String get auth_hint_code => '인증번호 6자리';

  @override
  String get guest_title_edit => '방명록 수정';

  @override
  String get guest_hint_input => '수정할 내용을 입력하세요...';

  @override
  String get guest_btn_complete => '수정 완료';

  @override
  String get guest_msg_delete_confirm => '이 방명록을 삭제하시겠습니까?';

  @override
  String get mypage_login_prompt => '로그인하면 내 정보를 확인할 수 있어요!';

  @override
  String get mypage_profile_needed => '프로필 등록이 필요해요!';

  @override
  String get mypage_btn_register => '프로필 등록하기';

  @override
  String get mypage_btn_edit => '프로필 수정';

  @override
  String get mypage_label_email => '이메일 없음';

  @override
  String get mypage_btn_logout => '로그아웃';

  @override
  String get mypage_btn_delete_acc => '계정 삭제';

  @override
  String get guest_title_my => '내 방명록';

  @override
  String get guest_title_write => '방명록 쓰기';

  @override
  String get guest_hint_cheer => '응원 메시지 남기기...';

  @override
  String get guest_msg_success => '방명록이 작성되었습니다';

  @override
  String get notice_title => '공지사항';

  @override
  String get notice_empty => '등록된 공지사항이 없습니다.';

  @override
  String get delete_acc_confirm_title => '계정 삭제';

  @override
  String get delete_acc_confirm_msg =>
      'DAO 계정을 삭제하면 모든 데이터가 삭제되며 복구할 수 없습니다. 정말 삭제하시겠습니까?';

  @override
  String get report_title => '버그/신고';

  @override
  String get report_label_title => '제목';

  @override
  String get report_label_content => '상세 내용';

  @override
  String get report_hint_content => '상황을 자세히 적어주세요';

  @override
  String get report_msg_success => '신고가 접수되었습니다. 감사합니다!';

  @override
  String get calc_start_prompt => '시작 점수를 입력하세요';

  @override
  String get calc_btn_start => '시작하기';

  @override
  String get calc_remaining_score => '남은 점수';

  @override
  String calc_this_turn(Object score) {
    return '이번 턴: $score';
  }

  @override
  String get calc_rec_route => '추천 체크아웃 루트';

  @override
  String get calc_alt_route => '대안 루트:';

  @override
  String get calc_err_range => '2~170 사이의 점수를 입력하세요';

  @override
  String get calc_err_overflow => '남은 점수보다 클 수 없어요';

  @override
  String drill_time_format(Object min) {
    return '~$min분';
  }

  @override
  String get drill_progress_title => '진행률';

  @override
  String get drill_stat_darts => '다트 수';

  @override
  String get drill_stat_rounds => '라운드';

  @override
  String get drill_stat_success => '성공률';

  @override
  String drill_stat_darts_count(Object count, Object total) {
    return '$count / $total 다트';
  }

  @override
  String drill_stat_rounds_count(Object count, Object total) {
    return 'ROUND $count / $total';
  }

  @override
  String get drill_panel_target => '타겟';

  @override
  String get drill_guide_hit_miss => '맞으면 ✅ / 빗나가면 ❌ 버튼을 눌러주세요';

  @override
  String get drill_btn_success => '성공';

  @override
  String get drill_btn_fail => '실패';

  @override
  String get drill_btn_undo_input => '이전 입력 되돌리기';

  @override
  String get drill_btn_finish_save => '드릴 종료하고 결과 저장';

  @override
  String get drill_unit_marks => '마크';

  @override
  String get drill_unit_points => '점';

  @override
  String drill_confirm_round(Object unit, Object val) {
    return '이번 라운드 확정 ($val $unit)';
  }

  @override
  String get drill_btn_undo_round => '이전 라운드 되돌리기';

  @override
  String drill_hint_range(Object max, Object min, Object unit) {
    return '$min ~ $max $unit';
  }

  @override
  String drill_around_title(Object count, Object total) {
    return '싱글 한 바퀴: $count / $total 타겟';
  }

  @override
  String drill_bull_title(Object count) {
    return 'Bull $count발 – SBull / DBull 분리 기록';
  }

  @override
  String get drill_msg_limit_reached => '설정된 총 다트 수를 모두 사용했습니다.';

  @override
  String get drill_msg_no_undo => '되돌릴 기록이 없습니다.';

  @override
  String drill_label_set_count(Object current, Object total) {
    return '세트 $current / $total';
  }

  @override
  String get drill_hint_score_input => '맞춘 점수 입력';

  @override
  String drill_target_bull(Object count, Object total) {
    return '목표 Bull 적중: $count / $total';
  }

  @override
  String get drill_btn_undo_last => '1회 되돌리기';

  @override
  String get drill_stat_bull_rate => 'Bull 적중률';

  @override
  String get drill_label_single => '싱글';

  @override
  String get drill_label_double => '더블';

  @override
  String get drill_confirm_score => '이번 라운드 점수 확정';

  @override
  String get drill_undo_round => '직전 라운드 되돌리기';

  @override
  String get drill_undo_input => '방금 입력 되돌리기';

  @override
  String get drill_check_result => '결과 확인하기';

  @override
  String drill_current_score(Object score) {
    return '현재까지 총점: $score점';
  }

  @override
  String get drill_clock_title => '더블 시계';

  @override
  String get drill_clock_back => '(뒤 절반)';

  @override
  String get drill_cricket_8r_title => '크리켓 8R 실전 훈련';

  @override
  String get drill_cricket_free => '자유 타겟';

  @override
  String get drill_cricket_select_hint => '아래에서 자유 라운드 타겟을 선택하세요';

  @override
  String get drill_quadrant_title => '이번 구역 진행';

  @override
  String get drill_quadrant_guide => '하이라이트된 색 구역에 집중해서 던져주세요!';

  @override
  String drill_t20_focus_title(Object target) {
    return '$target 집중 연습';
  }

  @override
  String get drill_top_half => '상단 영역 집중';

  @override
  String get drill_bottom_half => '하단 영역 집중';

  @override
  String get drill_hint_round_score => '이번 라운드 점수 (0~180)';

  @override
  String get drill_err_only_number => '숫자만 입력할 수 있습니다.';

  @override
  String get drill_err_score_range => '0 ~ 180점 사이로 입력해 주세요.';

  @override
  String get drill_msg_all_used => '설정된 총 다트 수를 모두 사용했습니다.';

  @override
  String get result_title => '연습 결과';

  @override
  String get result_xp_title => '이번 세션 XP';

  @override
  String get result_xp_desc => '이번 연습으로 획득한 경험치입니다.';

  @override
  String get result_summary_title => '세션 요약';

  @override
  String get result_stat_attempts => '총 시도';

  @override
  String get result_stat_duration => '소요 시간';

  @override
  String get result_growth_point => '성장 포인트';

  @override
  String get result_time_min => '분';

  @override
  String get result_time_sec => '초';

  @override
  String get finish_btn_success_1 => '1다트 성공';

  @override
  String get finish_btn_success_2 => '2다트 성공';

  @override
  String get finish_btn_success_3 => '3다트 성공';

  @override
  String get finish_btn_fail_prob => '이번 문제 실패';

  @override
  String get finish_remaining_title => '현재 남은 점수';

  @override
  String get finish_this_turn => '이번 턴';

  @override
  String get rank_mini_title => '이번 달 랭킹';

  @override
  String get rank_stat_score => '점수';

  @override
  String get rank_stat_optimal => '최적';

  @override
  String get rank_stat_route => '정석';

  @override
  String get record_none_start => '아직 기록 없음 지금 시작하세요!';

  @override
  String get record_login_needed => '로그인 필요';

  @override
  String get finish_home_title => '피니시 루트 연습';

  @override
  String get finish_promo_title => '랜덤 10문제 피니시 루트 연습';

  @override
  String get finish_promo_desc => '다트보드를 터치해서 점수를 0으로 만드세요. 더블/불로 마무리해야 합니다.';

  @override
  String get finish_btn_start => '연습 시작하기';

  @override
  String get finish_btn_login_start => '로그인 후 연습 시작';

  @override
  String get finish_msg_login_rank => '로그인하면 내 기록 저장 / 랭킹 참가가 가능해요';

  @override
  String get finish_hint_title => '추천 피니시 루트';

  @override
  String get finish_msg_touch_board => '다트보드를 눌러 입력하세요';

  @override
  String get finish_msg_bust_guide => 'BUST! ‘확인’ 버튼을 눌러 다음 문제로 넘어가세요.';

  @override
  String get finish_msg_done_guide => '마무리! ‘확인’ 버튼을 눌러 다음 문제로';

  @override
  String finish_msg_optimal_pace(Object count) {
    return '최적! $count다트 페이스';
  }

  @override
  String get finish_result_title => '피니시 루트 결과';

  @override
  String get finish_stat_total_time => '총 소요 시간';

  @override
  String get finish_stat_avg_darts => '평균 다트';

  @override
  String get finish_stat_optimal_rate => '최적 다트율';

  @override
  String get finish_stat_route_rate => '정석 루트율';

  @override
  String get finish_msg_optimal_success => '최적 다트 수로 성공!';

  @override
  String finish_msg_optimal_hint(Object count) {
    return '성공했지만 최적 다트 수는 $count다트입니다.';
  }

  @override
  String get grip_metric_pinch => '핀치 갭';

  @override
  String get grip_metric_flexion => '검지 굴곡';

  @override
  String grip_save_date(Object date) {
    return '저장일: $date';
  }

  @override
  String grip_frame_label(Object id) {
    return 'Frame $id';
  }

  @override
  String get grip_img_load_fail => '이미지를 불러올 수 없어요';

  @override
  String grip_cam_unsupported(Object platform) {
    return '이 플랫폼에서는 그립 카메라를 지원하지 않습니다: $platform';
  }

  @override
  String get grip_label_tight => '좁음';

  @override
  String get grip_label_wide => '넓음';

  @override
  String get grip_label_extended => '펴짐';

  @override
  String get grip_label_curved => '굽힘';

  @override
  String get grip_home_title => '그립 연구소';

  @override
  String get grip_home_desc => '가장 좋았던 그립을 저장하고, 매일 그 감각을 맞춰보세요.';

  @override
  String get grip_status_exists => '기준 그립이 저장되어 있습니다.';

  @override
  String get grip_status_empty => '아직 기준 그립이 없습니다.';

  @override
  String get grip_btn_compare => '비교/교정 하기';

  @override
  String get grip_btn_take_new => '새로 촬영하기';

  @override
  String get grip_guide_title => '그립 촬영 가이드';

  @override
  String get grip_guide_desc => '정확한 그립 분석을 위해 다음 사항을 확인해 주세요.';

  @override
  String get grip_guide_good => 'Good: 권장하는 촬영 방법';

  @override
  String get grip_guide_bad => 'Bad: 피해야 할 촬영 방법';

  @override
  String get grip_cam_hint => '엄지와 검지를 + 중심에 맞추고 가로선을 보며 수평을 확인하세요';

  @override
  String get grip_msg_hand_detect => '손이 인식된 상태에서만 촬영할 수 있어요.';

  @override
  String grip_msg_stabilizing(Object sec) {
    return '시스템 안정화 중입니다. $sec초만 기다려주세요.';
  }

  @override
  String get grip_report_title => '그립 분석 리포트';

  @override
  String get grip_ai_result => 'AI 그립 분석 결과';

  @override
  String get grip_metric_middle => '중지 받침 각도';

  @override
  String get grip_metric_ring => '약지 굽힘';

  @override
  String get grip_metric_pinky => '소지 밸런스';

  @override
  String get grip_msg_mirror => '기준 뼈대를 반전합니다 (거울 모드)';

  @override
  String get hist_title => '트레이닝 히스토리';

  @override
  String get hist_chart_title => '성장 추이 (하루 평균, 최근 7일)';

  @override
  String get hist_chart_goal => '목표 명중률 70%';

  @override
  String get hist_tab_trend => '추이';

  @override
  String get hist_tab_list => '목록';

  @override
  String get hist_filter_all => '전체';

  @override
  String hist_filter_cycle(Object n) {
    return '사이클 $n';
  }

  @override
  String get hist_tip_delete => 'Tip. 목록을 길게 누르면 기록을 삭제할 수 있어요.';

  @override
  String get stat_avg_hitrate => '평균 명중률';

  @override
  String get stat_max_ppd => '최고 PPD';

  @override
  String get stat_total_time => '총 걸린 시간';

  @override
  String get stat_success_attempt => '성공 / 시도';

  @override
  String get detail_meta_id => '드릴 ID';

  @override
  String get detail_growth_gauge => '성장 게이지';

  @override
  String get detail_msg_no_record => '아직 연습 기록이 없어요.';

  @override
  String get ai_summary_improved => '이전 세션보다 분명히 나아졌어요!';

  @override
  String get ai_summary_stable => '내 평균 페이스를 찾고 있다는 신호예요.';

  @override
  String get ai_summary_first => '앞으로 성장 그래프와 히스토리공가 쌓이게 돼요.';

  @override
  String get pose_guide_title => '촬영 가이드';

  @override
  String get pose_guide_desc => '정확한 분석을 위해 다음 사항을 확인해 주세요.';

  @override
  String get pose_setting_title => '분석 설정';

  @override
  String get pose_change_video => '영상 변경';

  @override
  String get pose_tip_title => '정확한 분석을 위한 팁';

  @override
  String get pose_select_part => '추적 부위 선택';

  @override
  String get pose_skeleton_color => '뼈대 색상';

  @override
  String get pose_btn_start => '분석 시작';

  @override
  String get pose_msg_analyzing => '자세를 분석 중입니다';

  @override
  String pose_msg_elapsed(Object sec) {
    return '소요 시간: $sec초';
  }

  @override
  String get pose_msg_ai_frame => 'AI가 영상을 프레임 단위로 분석하고 있습니다.';

  @override
  String get pose_msg_rendering => '영상 생성 중';

  @override
  String get pose_step_extract => '프레임 추출 중...';

  @override
  String get pose_step_skeleton => 'AI 뼈대 분석 중...';

  @override
  String get pose_step_encoding => '영상 인코딩 중...';

  @override
  String get pose_result_title => '분석 결과';

  @override
  String get pose_guide_line => '기준선 가이드 (팔꿈치/손목)';

  @override
  String get pose_show_track => '트래킹 궤적 보기';

  @override
  String get pose_show_release => '릴리즈 포인트 보기';

  @override
  String get pose_ai_title => 'AI 자세 분석 결과';

  @override
  String get pose_dist_notice => '엄지 손톱 끝과 검지 손톱 끝 사이의 직선 거리를 비교합니다.';

  @override
  String get pose_btn_save => '영상 저장';

  @override
  String get pose_main_title => '내 스로우, 분석하기.';

  @override
  String get pose_main_headline => '내 스로우, 분석하기.';

  @override
  String get pose_main_desc => '영상을 업로드하면 뼈대와 궤적을 추적하여 시각적으로 분석해 드립니다.';

  @override
  String get pose_btn_select_video => '영상 선택하기';

  @override
  String get pose_feat_skeleton_title => '스켈레톤(뼈대) 분석';

  @override
  String get pose_feat_skeleton_desc => '어깨, 팔꿈치, 손목의 움직임을 뼈대로 시각화합니다.';

  @override
  String get pose_feat_track_title => '손목 궤적 트래킹';

  @override
  String get pose_feat_track_desc => '릴리즈 순간의 손목 이동 경로를 선으로 그려줍니다.';

  @override
  String get pose_feat_diag_title => '프레임 단위 정밀 진단';

  @override
  String get pose_feat_diag_desc => '30FPS 고화질 분석으로 미세한 흔들림까지 확인하세요.';

  @override
  String get pose_label_set => '셋업';

  @override
  String pose_label_release(Object n) {
    return '릴리즈 $n';
  }

  @override
  String get report_header => 'DAO 트레이닝 리포트';

  @override
  String report_this_result(Object metric) {
    return '이번 결과 ($metric)';
  }

  @override
  String report_prev_best(Object metric) {
    return '이전 최고 ($metric)';
  }

  @override
  String get report_xp_earned => '이번 세션으로 획득한 XP';

  @override
  String report_goal_standard(Object xp) {
    return '이번 회차 목표: $xp XP 기준';
  }

  @override
  String get report_gauge_max => '성장 게이지 MAX! 레벨 재평가 시점이에요.';

  @override
  String get tier_test_title => '보드 마킹 레벨 테스트';

  @override
  String get tier_test_desc => '1번부터 20번까지 순서대로 명중하며,\n총 몇 발이 들었는지 입력해주세요.';

  @override
  String get tier_test_input_label => '총 사용한 다트 수';

  @override
  String get tier_test_btn_confirm => 'DAO 티어 확정하기';

  @override
  String get tier_test_err_too_many => '너무 많은 다트 수입니다. 다시 확인해주세요';

  @override
  String get tier_predict_label => '예상 DAO 티어';

  @override
  String get drill_rec_start => '시작하기';

  @override
  String get drill_rec_done => '오늘 완료';

  @override
  String get drill_stat_hit_count => '명중 수';

  @override
  String get train_home_title => '트레이닝';

  @override
  String train_current_tier(Object tier) {
    return '현재 DAO 티어 · $tier';
  }

  @override
  String get train_btn_edit_rating => '레이팅 수정하기';

  @override
  String get train_btn_reset => '초기화';

  @override
  String get train_msg_gauge_full => '🔥 성장 게이지 100% 달성!';

  @override
  String get train_msg_gauge_desc => '훈련을 통해 성장 게이지가 가득 찼어요. 실력을 다시 측정해볼까요?';

  @override
  String get train_msg_rating_notice => '※ 실제 기기 레이팅과는 약간의 오차가 있을 수 있습니다.';

  @override
  String get rating_input_title => '실력 입력';

  @override
  String get rating_tab_phoenix => 'PHOENIX';

  @override
  String get rating_tab_live => 'DARTSLIVE';

  @override
  String get rating_guide_desc =>
      'PPD와 MPR을 모두 입력하면 가장 정확합니다.\n하나만 입력해도 대략적인 값을 계산합니다.';

  @override
  String get rating_preview_title => '실시간 계산 결과';

  @override
  String get rating_msg_min_input => '최소 한 가지 값을 입력해주세요.';

  @override
  String get train_rec_title => '오늘의 추천 연습';

  @override
  String get train_rec_desc => '티어에 맞는 드릴로 워밍업을 시작해보세요.';

  @override
  String get train_tools_title => '훈련 도구';

  @override
  String get train_tool_pose => '자세분석 & 트래킹';

  @override
  String get train_tool_grip => '그립 연구소';

  @override
  String get train_tool_mylog => '나만의 다트 이야기';

  @override
  String get admin_delete_title => '삭제 확인';

  @override
  String get admin_delete_msg => '이 게시물을 완전히 삭제하시겠습니까? 삭제된 데이터는 복구할 수 없습니다.';

  @override
  String get admin_mode_label => '관리자 모드';

  @override
  String get ad_status_loading => '광고를 불러오는 중입니다...';

  @override
  String get ad_status_ready => '광고 준비 중';

  @override
  String get profile_go_guestbook => '내 방명록 가기';

  @override
  String get profile_write_guestbook => '방명록 쓰러 가기';

  @override
  String get svc_msg_save_gal => '갤러리 저장 완료: DAO Darts 앨범';

  @override
  String get svc_msg_no_gal_perm => '갤러리 접근 권한이 거부되었습니다';

  @override
  String get svc_msg_upload_fail => '사진 업로드에 실패했습니다';

  @override
  String get svc_msg_rendering_prep => '영상 분석 준비 중...';

  @override
  String get svc_msg_save_complete => '갤러리에 저장되었습니다!';

  @override
  String get status_online_none => '이름 없음';

  @override
  String get status_ad_suspended => '광고 기능이 비활성화되었습니다.';

  @override
  String get ui_btn_later => '나중에 하기';

  @override
  String get ui_label_participants => '참가자 명단';

  @override
  String get ui_msg_init_ad => 'AdMob 초기화 중';

  @override
  String get home_welcome_msg => 'DAO에 오신 것을 환영합니다!';

  @override
  String get home_title_magazine_ko => '한국 다트 소식';

  @override
  String get home_title_magazine_global => '해외 다트 소식';

  @override
  String get home_title_official_calendar => '공식 대회 일정';

  @override
  String get home_msg_no_calendar => '등록된 공식 일정이 없습니다.';

  @override
  String get home_language_setting => '언어 설정 (Language)';

  @override
  String get home_msg_lang_changing => '로 변경 중...';

  @override
  String get home_msg_profile_needed => '로그인 후 프로필을 등록해 주세요.';

  @override
  String get home_msg_profile_register => '프로필을 등록해 주세요!';

  @override
  String get effect_congrats_title => '축하합니다!';

  @override
  String get effect_perfect_score => '완벽한 기록이에요! 🎯';

  @override
  String get effect_new_record => '개인 최고 기록을 경신했습니다! 🎉';

  @override
  String get effect_cycle_complete => '한 사이클을 멋지게 마쳤습니다.';

  @override
  String get effect_epic_success => '경이로운 기록입니다! 🎆';

  @override
  String get effect_tier_up => '티어가 상승했습니다! 축하합니다!';

  @override
  String get effect_master_clear => '마스터 레벨을 완벽하게 마스터했습니다!';

  @override
  String get effect_legendary_darts => '당신은 전설입니다! 🎯';

  @override
  String get effect_hit_perfect => '완벽해요!';

  @override
  String get effect_hit_nice => '나이스 샷!';

  @override
  String get effect_hit_cool => '멋집니다!';

  @override
  String effect_hit_combo(Object count) {
    return '$count 콤보 달성!';
  }

  @override
  String get program_title_program_beginner_4w => '비기너 4주 기초 프로그램';

  @override
  String get program_desc_program_beginner_4w =>
      '보드를 4분할/상·하로 나눠 던져 보고, 숫자 한 바퀴와 S20·Bull·Count-Up까지 기초 감각을 쌓는 과정입니다.';

  @override
  String get program_title_program_learner_4w => '러너 4주 컨트롤 프로그램';

  @override
  String get program_desc_program_learner_4w =>
      '싱글 20 명중률과 상·하 컨트롤, 섹터 루프를 통해 실전 스코어링의 기본 발판을 만드는 과정입니다.';

  @override
  String get drill_title_beginner_quadrant_basic => '4분할 감각 만들기';

  @override
  String get drill_desc_beginner_quadrant_basic =>
      '보드를 4구역으로 나눠 방향·거리 감각을 만드는 입문 드릴';

  @override
  String get drill_target_beginner_quadrant_basic => '우상단 / 우하단 / 좌하단 / 좌상단';

  @override
  String get drill_guide_beginner_quadrant_basic =>
      '보드를 4구역으로 나누고 지시하는 구역에 던지세요. 1구역당 15발씩 진행합니다.';

  @override
  String get drill_title_beginner_top_bottom_basic => '상단/하단 영역 익히기';

  @override
  String get drill_desc_beginner_top_bottom_basic =>
      '상단/하단 큰 영역을 목표로 던져보며 방향 감각을 만든다.';

  @override
  String get drill_target_beginner_top_bottom_basic => '상단 / 하단';

  @override
  String get drill_guide_beginner_top_bottom_basic =>
      '보드를 상/하로 나누어 각 영역에 30발씩 던지며 감각을 익힙니다.';

  @override
  String get drill_title_beginner_around_board_single => '싱글 한 바퀴';

  @override
  String get drill_desc_beginner_around_board_single =>
      '1→20→SB까지 싱글을 한 바퀴 도는 기초 드릴';

  @override
  String get drill_target_beginner_around_board_single => '1~20 + SB';

  @override
  String get drill_guide_beginner_around_board_single =>
      '1부터 SB까지 순서대로 명중시키며 완주에 필요한 다트 수를 줄여보세요.';

  @override
  String get drill_title_beginner_large_single_20 => 'Large Single 20 입문';

  @override
  String get drill_desc_beginner_large_single_20 =>
      'S20 큰 영역에 안정적으로 맞추는 감각을 만드는 입문 스코어링 드릴';

  @override
  String get drill_target_beginner_large_single_20 => 'S20 (싱글 20라인)';

  @override
  String get drill_guide_beginner_large_single_20 =>
      'S20 영역만 60발을 던지며 정확도를 50% 이상으로 올리는 것을 목표로 합니다.';

  @override
  String get drill_title_beginner_big_bull => '빅 Bull 감각';

  @override
  String get drill_desc_beginner_big_bull => 'Bull 링 전체를 노리며 “그루핑” 감각을 만드는 드릴';

  @override
  String get drill_target_beginner_big_bull => '전체 Bull 60발';

  @override
  String get drill_guide_beginner_big_bull =>
      '싱글불과 더블불을 구분하지 않고 전체 Bull 영역에 모아 던지는 연습을 합니다.';

  @override
  String get drill_title_beginner_loose_countup_8r => '느슨한 Count-Up';

  @override
  String get drill_desc_beginner_loose_countup_8r =>
      '점수보다는 “보드에 꽂히는 경험”을 쌓는 가벼운 8R Count-Up';

  @override
  String get drill_target_beginner_loose_countup_8r => '8R Count-Up';

  @override
  String get drill_guide_beginner_loose_countup_8r =>
      '편안하게 8라운드를 완주하며 다트가 보드에 들어가는 손맛에 집중하세요.';

  @override
  String get drill_title_learner_single20_60 => 'Single 20 60발';

  @override
  String get drill_desc_learner_single20_60 =>
      '정규 거리에서 S20만 60발 던지며 명중률을 끌어올리는 드릴';

  @override
  String get drill_target_learner_single20_60 => 'S20';

  @override
  String get drill_guide_learner_single20_60 =>
      '정규 거리에서 60발 중 40발 이상 명중시키는 것을 목표로 합니다.';

  @override
  String get drill_title_learner_20_19_switch => '상단 3섹터 루프 (20/19/18)';

  @override
  String get drill_desc_learner_20_19_switch =>
      '20/19/18 상단 구역을 돌면서 빅미스를 줄이는 연습';

  @override
  String get drill_target_learner_20_19_switch => '20 / 19 / 18';

  @override
  String get drill_guide_learner_20_19_switch =>
      '20, 19, 18번을 순차적으로 공략하며 타겟 전환 리듬을 익힙니다.';

  @override
  String get drill_title_comp_triple_20_19_18_line => '트리플 루프 (T20/T19/T18)';

  @override
  String get drill_desc_comp_triple_20_19_18_line =>
      'T20 → T19 → T18 트리플 영역을 순환하며 스코어링 리듬을 만드는 연습';

  @override
  String get drill_target_comp_triple_20_19_18_line => 'T20 / T19 / T18';

  @override
  String get drill_guide_comp_triple_20_19_18_line =>
      '스코어링의 핵심인 상단 트리풀 3곳을 번갈아 공략하며 집중력을 유지하세요.';

  @override
  String get drill_title_comp_checkout_40_80 => '40–80 더블 아웃 필수 구간';

  @override
  String get drill_desc_comp_checkout_40_80 =>
      '40~80 점수대를 더블로 마무리하는 필수 체크아웃 드릴';

  @override
  String get drill_target_comp_checkout_40_80 => '40~80 Double-Out';

  @override
  String get drill_guide_comp_checkout_40_80 =>
      '실전에서 가장 빈번한 40~80 구간을 3다트 내에 마무리하는 연습입니다.';

  @override
  String get drill_title_pro_501_standard_18darts => '501 Double-Out 18다트';

  @override
  String get drill_desc_pro_501_standard_18darts =>
      '18다트 이내 501 마무리가 가능한지 체크합니다.';

  @override
  String get drill_target_pro_501_standard_18darts => '501 Double-Out';

  @override
  String get drill_guide_pro_501_standard_18darts =>
      '총 10세트 플레이 후 18다트 이내 완주 비율을 확인합니다.';

  @override
  String get drill_title_master_170_route_focused_30 => '170 체크아웃 루트 집중';

  @override
  String get drill_desc_master_170_route_focused_30 =>
      'T20 → T20 → Bull 루트를 몸에 새겨넣는 하이피니시 드릴';

  @override
  String get drill_target_master_170_route_focused_30 =>
      '170 (T20 → T20 → Bull)';

  @override
  String get drill_guide_master_170_route_focused_30 =>
      '170 최고점 피니시 루트를 근육이 기억할 때까지 30세트 반복합니다.';

  @override
  String get exit_drill_title => '연습 종료';

  @override
  String get exit_drill_msg => '기록이 저장되지 않았습니다. 정말 종료하시겠습니까?';

  @override
  String get drill_msg_bust => '버스트!';

  @override
  String drill_msg_darts_left(Object count) {
    return '$count 다트 남음';
  }

  @override
  String get drill_category_board_mapping => '보드 맵핑';

  @override
  String get drill_category_double => '더블 연습';

  @override
  String get profile_reset_title => '트레이닝 데이터 초기화';

  @override
  String get profile_reset_msg =>
      'DAO 트레이닝 레이팅과 티어를 초기화합니다.\n다시 레이팅 입력 또는 레벨 테스트로 시작할 수 있습니다.';

  @override
  String get rating_check_ready_title => '🔥 성장 게이지 100% 달성!';

  @override
  String get rating_check_ready_msg =>
      '훈련을 통해 성장 게이지가 가득 찼어요.\n지금 레이팅을 다시 측정하여 성장한 실력을 확인해볼까요?';

  @override
  String get drill_current_tier => '현재 DAO 티어';

  @override
  String get btn_edit_rating => '레이팅 수정';

  @override
  String get tab_free_ranking => '자유 랭킹';

  @override
  String get tab_custom_practice => '맞춤 연습';

  @override
  String get section_training_tools => '훈련 도구';

  @override
  String get drill_stat_growth_gauge => '성장 게이지';

  @override
  String get msg_rating_check_ready => '레이팅 체크 준비 완료';

  @override
  String drill_remaining_xp(Object xp) {
    return '재평가까지 남은 XP: $xp';
  }

  @override
  String get msg_input_darts_skill => '다트 실력을 입력해주세요!';

  @override
  String get btn_input_rating => '레이팅 입력';

  @override
  String get btn_level_test => '레벨 테스트';

  @override
  String get msg_no_recommended_drills => '추천 드릴이 없습니다.';

  @override
  String get tool_training_history => '트레이닝 히스토리';

  @override
  String get tool_grip_lab => '그립 연구소';

  @override
  String get tool_pose_analysis => '자세분석 & 트래킹';

  @override
  String get tool_checkout_calculator => '체크아웃 계산기';

  @override
  String get tool_my_dart_story => '나만의 다트 이야기';

  @override
  String get common_later => '나중에 하기';

  @override
  String get common_test => '테스트 하기';

  @override
  String get common_reset => '초기화';

  @override
  String get tier_test_headline => '다트 보드 마킹 정확도 테스트';

  @override
  String get tier_test_guide_title => 'DAO 공식 마킹 레벨 기준';

  @override
  String get tier_test_input_hint => '예: 28';

  @override
  String get tier_test_result_notice => '결과는 트레이닝 홈에 바로 반영됩니다';

  @override
  String get tier_test_err_empty => '다트 수를 입력해주세요';

  @override
  String get tier_test_err_invalid => '1 이상의 숫자를 입력해주세요';

  @override
  String get drill_active_area => '현재 연습 구역';

  @override
  String get area_top_right => '오른쪽 위';

  @override
  String get area_bottom_right => '오른쪽 아래';

  @override
  String get area_bottom_left => '왼쪽 아래';

  @override
  String get area_top_left => '왼쪽 위';

  @override
  String drill_approx_duration(Object min) {
    return '약 $min분';
  }

  @override
  String get drill_stat_total_darts => '총 다트';

  @override
  String get drill_stat_hit_rate => '명중률';

  @override
  String get drill_stat_total_marks => '총 마크';

  @override
  String get drill_stat_total_score => '총 점수';

  @override
  String get btn_close => '닫기';

  @override
  String get btn_go_history => '히스토리';

  @override
  String get btn_continue_drill => '다른 연습 계속하기';

  @override
  String get btn_rating_check => '레이팅 체크';

  @override
  String get report_header_title => 'DAO 트레이닝 리포트';

  @override
  String report_current_result(Object label) {
    return '이번 결과 ($label)';
  }

  @override
  String report_previous_best(Object label) {
    return '이전 최고 ($label)';
  }

  @override
  String get report_previous_record => '이전 기록';

  @override
  String get report_first_record_msg => '첫 기록입니다!';

  @override
  String report_xp_goal_msg(Object goal) {
    return '이번 회차 목표: $goal XP 기준';
  }

  @override
  String get report_growth_gauge => '성장 게이지 변화';

  @override
  String get report_gauge_before => '이전';

  @override
  String get report_gauge_current => '현재';

  @override
  String get report_gauge_max_msg => '이번 회차 성장 게이지 MAX! 레벨 재평가 시점이에요.';

  @override
  String get report_summary_first_save => 'DAO 트레이닝 첫 기록이 저장되었습니다.';

  @override
  String get report_summary_first_max => 'DAO 트레이닝 첫 기록과 함께 성장 게이지가 가득 찼어요.';

  @override
  String report_summary_improved(Object diff, Object label) {
    return '이전 기록보다 $diff 만큼 $label이 상승했습니다.';
  }

  @override
  String get report_summary_steady => '이번 연습은 이전과 거의 비슷한 수준의 결과였어요.';

  @override
  String get report_summary_encouragement =>
      '이번 결과는 이전보다 조금 낮았지만, 실력은 계속 쌓이고 있습니다.';

  @override
  String get rank_select_title => '도전 종목 선택';

  @override
  String get rank_501_desc => 'PPD 랭킹 도전 (10라운드)';

  @override
  String get rank_cricket_desc => 'MPR 랭킹 도전 (15라운드)';

  @override
  String get rank_countup_desc => '최고 점수 도전 (8라운드)';

  @override
  String rank_game_round(Object current, Object max) {
    return 'ROUND $current / $max';
  }

  @override
  String get rank_game_left => '남은 점수';

  @override
  String get rank_game_total_score => '총 점수';

  @override
  String get rank_game_target => '목표';

  @override
  String get rank_game_round_score => '라운드 점수';

  @override
  String get rank_game_confirm => '확정';

  @override
  String get rank_msg_bust => 'BUST 처리되었습니다.';

  @override
  String get rank_msg_max_score => '최대 180점입니다.';

  @override
  String get rank_msg_bull_max => 'BULL은 최대 6마크까지만 가능합니다.';

  @override
  String get rank_finish_title => 'FINISH! 🎯';

  @override
  String rank_finish_sub(Object score) {
    return '마지막 $score점을 몇 발 만에 끝냈나요?';
  }

  @override
  String rank_darts_count(Object count) {
    return '$count발';
  }

  @override
  String get rank_reset_my_title => '기록 초기화';

  @override
  String get rank_reset_admin_title => '관리자 권한: 기록 삭제';

  @override
  String get rank_reset_my_msg =>
      '정말로 이번 달 내 모든 최고 기록을 초기화하시겠습니까?\n삭제 후 순위에서 즉시 제외됩니다.';

  @override
  String rank_reset_admin_msg(Object name) {
    return '\'$name\' 유저의 부정 기록이 의심되나요?\n이 유저의 이번 달 모든 랭킹 기록을 삭제하시겠습니까?';
  }

  @override
  String get rank_reset_done => '기록이 정상적으로 삭제되었습니다.';

  @override
  String get rank_tab_total => '통합 🔥';

  @override
  String get rank_btn_challenge => '랭킹 도전하기';

  @override
  String get rank_guide_title => '💡 기록 관리 안내';

  @override
  String get rank_guide_delete => '내 기록을 길게 꾹 누르면 해당 기록을 삭제할 수 있습니다.';

  @override
  String get rank_guide_warning =>
      '공정한 랭킹 문화를 위해 부적절한 방법으로 등록된 기록은\n관리자에 의해 예고 없이 삭제될 수 있습니다.';

  @override
  String get rank_guide_badge =>
      '통합 랭킹으로 배지가 수여되며\n각 종목 TOP 10 기록을 합산하여 결정됩니다.';

  @override
  String get rank_no_data => '아직 기록이 없습니다.';

  @override
  String get rank_no_total_data => '아직 통합 집계 데이터가 없습니다.';

  @override
  String get rank_load_failed => '데이터 로드 실패';

  @override
  String get calendar_title => '공식 일정 달력';

  @override
  String calendar_selected_day(Object day, Object month) {
    return '$month월 $day일 일정';
  }

  @override
  String get calendar_no_event => '일정이 없습니다.';

  @override
  String get calendar_delete_title => '일정 삭제';

  @override
  String get calendar_delete_msg => '정말 이 일정을 삭제하시겠습니까?';

  @override
  String get calendar_unit_month => '월';

  @override
  String get calendar_unit_day => '일';

  @override
  String get live_list_title => '실시간 연습 현황';

  @override
  String get live_list_empty => '현재 연습 중인 유저가 없습니다.';

  @override
  String get live_status_live => 'LIVE';

  @override
  String get live_status_finished => 'FINISHED';

  @override
  String get live_no_shop => '소속 샵 없음';

  @override
  String get live_blur_text => '로그인 후 확인 가능합니다.';

  @override
  String get live_board_title => 'LIVE 연습 현황';

  @override
  String get live_board_view_all => '전체보기';

  @override
  String get live_board_login_invite => '로그인 후 연습시간을 체크해보세요!';

  @override
  String get live_board_start_invite => '오늘의 연습시간을 체크할까요?';

  @override
  String get live_board_profile_invite => '프로필 등록 후 연습시간을 체크하세요!';

  @override
  String get live_board_btn_start => '연습 시작';

  @override
  String get live_board_btn_stop => '종료';

  @override
  String get live_board_btn_profile => '프로필 등록';

  @override
  String live_board_total_count(Object count) {
    return '현재 $count명의 유저가 연습 중입니다!';
  }

  @override
  String get live_board_no_user => '아직 연습 중인 유저가 없습니다.';

  @override
  String live_board_total_today(Object time) {
    return '오늘 총 연습: $time';
  }

  @override
  String common_hour(Object value) {
    return '$value시간';
  }

  @override
  String common_minute(Object value) {
    return '$value분';
  }

  @override
  String get login_title => '로그인';

  @override
  String live_total_time(Object time) {
    return '총 $time';
  }

  @override
  String get practice_setup_title => '기록 시작';

  @override
  String get practice_setup_sub => '오늘의 연습 환경을 설정하고 기록을 시작하세요.';

  @override
  String get practice_setup_machine => '사용 머신';

  @override
  String get practice_setup_location => '연습 장소';

  @override
  String get practice_setup_location_hint => '예: PDK 스타디움, 다트하이브';

  @override
  String get practice_setup_goal => '오늘의 연습 목표 (선택)';

  @override
  String get practice_setup_goal_hint => '예: 불 100발, 레이팅 15, 3시간 연습 등';

  @override
  String get practice_setup_btn_start => '연습 기록 시작하기';

  @override
  String get practice_setup_error_location => '연습 중인 장소(샵 이름)를 입력해주세요.';

  @override
  String practice_setup_error_start(Object error) {
    return '시작 오류: $error';
  }

  @override
  String get practice_stop_title => '연습 종료 리포트';

  @override
  String get practice_stop_sub => '오늘의 연습을 마무리하고 기록을 남겨보세요.';

  @override
  String get practice_stop_total_time => '총 연습 시간';

  @override
  String get practice_stop_my_goal => '나의 목표';

  @override
  String get practice_stop_feedback_label => '목표를 달성하셨나요? (결과/피드백)';

  @override
  String get practice_stop_feedback_hint => '예: 100발 완료!, 컨디션 난조로 실패 등';

  @override
  String get practice_stop_cheer_msg => '오늘도 정말 고생하셨습니다!';

  @override
  String get practice_stop_btn_no_save => '저장없이 종료';

  @override
  String get practice_stop_btn_save => '마이로그 저장';

  @override
  String practice_stop_error(Object error) {
    return '종료 처리 중 오류가 발생했습니다: $error';
  }

  @override
  String get history_title => '트레이닝 히스토리';

  @override
  String get history_login_required => '로그인이 필요해요';

  @override
  String get history_login_msg => '내 연습 기록을 저장하고 추이를 확인하려면\n로그인이 필요합니다.';

  @override
  String get history_profile_required => '프로필 등록이 필요해요';

  @override
  String get history_profile_msg =>
      '기록의 신뢰성을 위해 프로필 등록 유저만\n히스토리 기능을 사용할 수 있습니다.';

  @override
  String get history_no_record => '아직 연습 기록이 없어요.';

  @override
  String get history_no_cycle_record => '이 사이클엔 기록이 없어요.';

  @override
  String get history_tab_trend => '추이';

  @override
  String get history_tab_list => '목록';

  @override
  String get history_filter_all => '전체';

  @override
  String get history_tip_delete => 'Tip. 목록을 길게 누르면 기록을 삭제할 수 있어요.';

  @override
  String get history_delete_title => '기록 삭제';

  @override
  String get history_delete_msg => '이 연습 기록을 정말 삭제하시겠습니까?\n서버에서도 영구적으로 삭제됩니다.';

  @override
  String get history_cycle_delete_title => '사이클 삭제';

  @override
  String get history_cycle_delete_msg => '이 사이클의 모든 기록을 삭제할까요?\n복구할 수 없습니다.';

  @override
  String get history_stat_avg_hit => '평균 명중률';

  @override
  String get history_stat_max_hit => '최고 명중률';

  @override
  String get history_date_today => '오늘';

  @override
  String get history_date_yesterday => '어제';

  @override
  String history_date_days_ago(Object days) {
    return '$days일 전';
  }

  @override
  String history_cycle_label(Object number) {
    return '사이클 $number';
  }

  @override
  String get history_initial_record => '초기 기록';

  @override
  String get detail_title => '트레이닝 상세';

  @override
  String get detail_error_load => '기록을 불러오는 중 문제가 발생했습니다.';

  @override
  String get detail_stat_no_record => '기록 없음';

  @override
  String get detail_info_title => '세부 정보';

  @override
  String get detail_info_drill_id => '드릴 ID';

  @override
  String get detail_info_cycle => '사이클';

  @override
  String get detail_info_total_attempts => '총 시도';

  @override
  String detail_summary_no_data(Object metric) {
    return '이번 세션의 $metric 기록이 아직 충분하지 않아요.\n다음 연습에서 한 번 더 같은 드릴을 진행해보면, 변화가 더 잘 보일 거예요.';
  }

  @override
  String detail_summary_first(Object metric) {
    return '$metric 첫 기록입니다.\n앞으로 이 수치를 기준으로 성장 그래프와 히스토리가 쌓이게 돼요.\n🔥 오늘의 미션: 같은 드릴을 한 번 더 진행해서 \'내 기준 기록\'을 만들어보세요.';
  }

  @override
  String detail_summary_up(Object diff, Object metric) {
    return '$metric +$diff 상승! 🔥\n이전 세션보다 분명히 나아졌어요.\n지금 템포와 리듬을 한 번 더 유지해서 \'연속 상승\'에 도전해볼까요?';
  }

  @override
  String detail_summary_steady(Object metric) {
    return '$metric 변화 거의 없음.\n이건 오히려 \'내 평균 페이스\'를 찾고 있다는 신호예요.\n조금 다른 루틴이나 호흡으로 같은 드릴을 한 번 더 시도해보는 것도 좋아요.';
  }

  @override
  String detail_summary_down(Object diff, Object metric) {
    return '$metric -$diff 하락.\n하지만 XP와 연습량은 그대로 쌓이고 있습니다.\n오늘은 여기서 마무리하고, 다른 유형 드릴로 한 번 더 몸을 풀어준 뒤\n다음 사이클에서 다시 이 드릴에 도전해보는 건 어떨까요?';
  }

  @override
  String get chart_title => '성장 추이 (하루 평균, 최근 7일)';

  @override
  String get chart_sub => '그래프는 최근 7일 동안의 하루 평균값을 보여줘요.';

  @override
  String get chart_legend_ppd => 'PPD (스케일 x2)';

  @override
  String get chart_legend_mpr => 'MPR (스케일 x10)';

  @override
  String chart_goal_hit(Object percent) {
    return '목표 명중률 $percent%';
  }

  @override
  String get chart_toggle_all => '전체';

  @override
  String get chart_tooltip_hit => '명중률';

  @override
  String get chart_no_data => '표시할 수 있는 데이터가 없어요';

  @override
  String get profile_register_btn => '프로필 등록하러 가기';

  @override
  String get pose_title => 'AI 자세 분석';

  @override
  String get pose_login_msg => '자세 분석 기능을 사용하고 기록을 저장하려면\n로그인이 필요합니다.';

  @override
  String get pose_main_sub => '영상을 업로드하면 뼈대와 궤적을 추적하여\n시각적으로 분석해 드립니다.';

  @override
  String get pose_feature1_title => '스켈레톤(뼈대) 분석';

  @override
  String get pose_feature1_desc => '어깨, 팔꿈치, 손목의 움직임을 뼈대로 시각화합니다.';

  @override
  String get pose_feature2_title => '손목 궤적 트래킹';

  @override
  String get pose_feature2_desc => '릴리즈 순간의 손목 이동 경로를 선으로 그려줍니다.';

  @override
  String get pose_feature3_title => '프레임 단위 정밀 진단';

  @override
  String get pose_feature3_desc => '30FPS 고화질 분석으로 미세한 흔들림까지 확인하세요.';

  @override
  String get pose_label_r_wrist => '오른쪽 손목';

  @override
  String get pose_label_l_wrist => '왼쪽 손목';

  @override
  String get pose_label_r_elbow => '오른쪽 팔꿈치';

  @override
  String get pose_label_l_elbow => '왼쪽 팔꿈치';

  @override
  String get pose_label_r_shoulder => '오른쪽 어깨';

  @override
  String get pose_label_l_shoulder => '왼쪽 어깨';

  @override
  String get pose_result_guide_title => '기준선 가이드 (팔꿈치/손목)';

  @override
  String get pose_result_guide_off => '끄기';

  @override
  String get pose_result_guide_left => '왼쪽 켜기';

  @override
  String get pose_result_guide_right => '오른쪽 켜기';

  @override
  String get pose_result_show_track => '트래킹 궤적 보기';

  @override
  String get pose_result_show_track_sub => '투구 궤적 표시';

  @override
  String get pose_result_show_release => '릴리즈 포인트 보기';

  @override
  String get pose_result_show_release_sub => '던지는 순간 표시 (점)';

  @override
  String get pose_result_select_part => '보고 싶은 부위 선택';

  @override
  String get pose_result_btn_repick => '다른 영상 선택';

  @override
  String get pose_result_btn_save => '영상 저장';

  @override
  String get pose_render_preparing => '영상 분석 준비 중...';

  @override
  String get pose_render_extracting => '프레임 추출 중...';

  @override
  String get pose_render_analyzing => 'AI 뼈대 분석 중...';

  @override
  String get pose_render_encoding => '영상 인코딩 중...';

  @override
  String get pose_render_complete => '저장 완료!';

  @override
  String get pose_render_dialog_title => '영상 생성 중';

  @override
  String get pose_render_save_success => '갤러리에 저장되었습니다!';

  @override
  String get pose_setting_change_video => '영상 변경';

  @override
  String get pose_setting_tip_title => '정확한 분석을 위한 팁';

  @override
  String get pose_setting_tip1 => '• 원활한 분석을 위해 20~25초 내외의 영상을 권장합니다.';

  @override
  String get pose_setting_tip2 => '• 측면에서 몸과 팔 전체가 나오도록 촬영하면 가장 정확합니다.';

  @override
  String get pose_setting_section_part => '추적 부위 선택';

  @override
  String get pose_setting_section_skeleton => '뼈대 색상';

  @override
  String get pose_setting_section_line => '트래킹 라인 색상';

  @override
  String get pose_setting_btn_start => '분석 시작';

  @override
  String get pose_proc_title => '자세를 분석 중입니다';

  @override
  String pose_proc_time(Object seconds) {
    return '소요 시간: $seconds초';
  }

  @override
  String get pose_proc_ad_loading => '광고를 불러오는 중입니다...';

  @override
  String get pose_proc_ad_dev => 'MREC 광고 영역 (개발중)';

  @override
  String get pose_proc_guide =>
      'AI가 영상을 프레임 단위로 분석하고 있습니다.\n영상이 길수록 시간이 조금 더 소요됩니다.';

  @override
  String get pose_proc_failed => '분석 실패. 다시 시도해주세요.';

  @override
  String get pose_guide_main => '정확한 분석을 위해\n다음 사항을 확인해 주세요.';

  @override
  String get pose_guide_sub => 'AI가 뼈대를 잘 인식할수록 분석 결과가 정확해집니다.';

  @override
  String get pose_guide_good_title => 'Good: 권장하는 촬영 방법';

  @override
  String get pose_guide_good_1 => '영상 길이는 20초~25초 사이가 분석 및 저장에 가장 적합합니다.';

  @override
  String get pose_guide_good_2 => '분석할 사용자의 측면 모습(90도)에서 촬영해 주세요.';

  @override
  String get pose_guide_good_3 => '머리부터 상체, 골반, 무릎까지 나오도록 찍는 것이 좋습니다.';

  @override
  String get pose_guide_good_4 => '긴팔보다는 반팔을 입어야 관절 위치가 정확히 인식됩니다.';

  @override
  String get pose_guide_good_5 => '강한 역광이나 배경의 방해 요소가 없는 밝은 곳이 좋습니다.';

  @override
  String get pose_guide_bad_title => 'Bad: 피해야 할 촬영 방법';

  @override
  String get pose_guide_bad_1 => '영상이 너무 길면 분석 시간이 오래 걸리거나 앱이 종료될 수 있습니다.';

  @override
  String get pose_guide_bad_2 => '상반신만 찍으면 중요 포인트와 궤적 추적이 안 될 수 있습니다.';

  @override
  String get pose_guide_bad_3 => '정면이나 45도 각도는 현재 정확한 분석이 어렵습니다.';

  @override
  String get pose_guide_bad_4 => '신체를 가리는 헐렁한 옷이나 장신구는 피해 주세요.';

  @override
  String get pose_guide_bad_5 =>
      '강한 조명이나 촬영 중 배경에 다른 움직임이 있으면 분석이 부정확할 수 있습니다.';

  @override
  String get pose_guide_btn_confirm => '확인했습니다 (영상 선택)';

  @override
  String get grip_title => '그립 연구소';

  @override
  String get grip_main_title => '내 그립, 기록하고\n비교하기.';

  @override
  String get grip_main_sub =>
      '정답은 없지만, 나에게 잘 맞는 ‘기준’은 있습니다.\n가장 좋았던 그립을 저장하고, 매일 그 감각을 맞춰보세요.';

  @override
  String get grip_info1_title => '촬영 & 저장';

  @override
  String get grip_info1_desc =>
      '손을 비추면 뼈대를 추적합니다.\n가장 마음에 드는 그립을 \'기준\'으로 저장하세요.';

  @override
  String get grip_info2_title => '비교/교정';

  @override
  String get grip_info2_desc => '기준과 달라진 손가락을 찾아내어 조언해줍니다.';

  @override
  String get grip_info3_title => '수치 분석';

  @override
  String get grip_info3_desc =>
      '엄지-검지 사이 거리, 손가락 굽힘 각도 등\n미세한 차이를 수치로 확인할 수 있어요.';

  @override
  String get grip_status_has => '기준 그립이 저장되어 있습니다.';

  @override
  String get grip_status_no => '아직 기준 그립이 없습니다.';

  @override
  String get grip_msg_has => '저장된 기준 데이터를 확인하거나, 아래 버튼을 눌러 비교 훈련을 시작하세요.';

  @override
  String get grip_msg_no => '먼저 [촬영하기] 버튼을 눌러 기준 그립을 만들어주세요.';

  @override
  String get grip_btn_view_data => '저장된 기준 데이터(수치) 보기';

  @override
  String get grip_btn_new_shoot => '새로 촬영하기';

  @override
  String get grip_guide_main => '정확한 그립 분석을 위해\n다음 사항을 확인해 주세요.';

  @override
  String get grip_guide_sub => '손가락 마디와 손톱 위치가 명확할수록 분석이 정교해집니다.';

  @override
  String get grip_guide_good_title => 'Good: 권장하는 촬영 방법';

  @override
  String get grip_guide_good_1 => '다트를 잡은 손을 \'정확한 측면(90도)\'에서 촬영해 주세요.';

  @override
  String get grip_guide_good_2 => '엄지와 검지가 겹친 부위를 + 포인트에 맞춰주세요.';

  @override
  String get grip_guide_good_3 => '배경이 복잡하지 않은 깔끔한 곳이 좋습니다.';

  @override
  String get grip_guide_good_4 => '손목까지 화면 안에 들어오도록 거리를 조절해 주세요.';

  @override
  String get grip_guide_good_5 => '조명이 밝은 곳에서 촬영해야 손가락 마디가 잘 보입니다.';

  @override
  String get grip_guide_bad_title => 'Bad: 피해야 할 촬영 방법';

  @override
  String get grip_guide_bad_1 => '정면에서 찍으면 손가락 깊이(Depth) 분석이 불가능합니다.';

  @override
  String get grip_guide_bad_2 => '손가락이 다트 배럴에 완전히 가려지면 안 됩니다.';

  @override
  String get grip_guide_bad_3 => '너무 어둡거나 역광인 곳은 피해주세요.';

  @override
  String get grip_guide_bad_4 => '카메라가 너무 멀어서 손이 작게 나오면 인식이 어렵습니다.';

  @override
  String get grip_guide_btn_start => '확인했습니다 (촬영 시작)';

  @override
  String get grip_auth_camera_title => '카메라 권한 필요';

  @override
  String get grip_auth_camera_msg => '설정에서 카메라 권한을 허용해야 그립 분석 기능을 사용할 수 있습니다.';

  @override
  String get grip_auth_camera_denied => '촬영을 위해 카메라 권한 허용이 필요합니다.';

  @override
  String get grip_auth_go_settings => '설정으로 이동';

  @override
  String get grip_comp_title => '그립 비교 촬영';

  @override
  String get grip_comp_result_title => '분석 결과';

  @override
  String get grip_comp_mirror_on => '기준 뼈대 반전(거울 모드)';

  @override
  String get grip_comp_mirror_off => '기준 뼈대 원복';

  @override
  String get grip_comp_retake => '재촬영';

  @override
  String get grip_comp_ai_title => 'AI 그립 분석 결과';

  @override
  String get grip_comp_info_dist =>
      '거리 분석 기준: 엄지 손톱 끝과 검지 손톱 끝 사이의 직선 거리를 비교합니다.';

  @override
  String get grip_comp_no_result => '분석 결과가 없습니다.';

  @override
  String get grip_comp_btn_retake => '다시 촬영하기';

  @override
  String get grip_comp_live_guide => '손을 카메라에 비춰주세요';

  @override
  String get grip_comp_baseline_label => '기준 그립';

  @override
  String get grip_comp_shoot_guide => '기준 사진과 비슷하게 잡고\n+ 중심에 맞춰 촬영하세요';

  @override
  String grip_comp_cooldown(Object seconds) {
    return '$seconds초 뒤 촬영 가능';
  }

  @override
  String get grip_comp_no_baseline => '기준 그립이 없습니다.';

  @override
  String get grip_comp_btn_go_shoot => '촬영하러 가기';

  @override
  String get grip_cam_checking_auth => '카메라 권한을 확인하고 있습니다...';

  @override
  String get grip_cam_guide_center => '엄지와 검지를 ';

  @override
  String get grip_cam_guide_plus => '+ 중심';

  @override
  String get grip_cam_guide_align => '에 맞추고\n';

  @override
  String get grip_cam_guide_horizon => '가로선 ― ';

  @override
  String get grip_cam_guide_desc => '을 보며 다트의 각도(수평)를 확인하세요';

  @override
  String get grip_cam_msg_detected_only => '손이 인식된 상태에서만 촬영할 수 있어요.';

  @override
  String get grip_cam_msg_save_success => '✅ 기준 그립 저장 완료!';

  @override
  String grip_cam_msg_save_error(Object error) {
    return '저장 중 오류 발생: $error';
  }

  @override
  String get grip_report_main_ctrl => '메인 컨트롤 (Main Control)';

  @override
  String get grip_report_support => '보조 지지대 (Support Fingers)';

  @override
  String get grip_report_gap => '엄지-검지 간격 (Gap)';

  @override
  String get grip_report_index => '검지 굽힘 (Index Angle)';

  @override
  String get grip_report_middle => '중지 받침 각도 (Middle)';

  @override
  String get grip_report_ring => '약지 굽힘 (Ring)';

  @override
  String get grip_report_pinky => '소지 밸런스 (Pinky)';

  @override
  String get grip_report_tight => '타이트함';

  @override
  String get grip_report_wide => '와이드함';

  @override
  String get grip_report_bent => '많이 굽힘';

  @override
  String get grip_report_straight => '펴짐';

  @override
  String get grip_report_deep => '깊게 잡음';

  @override
  String get grip_report_shallow => '얕게 잡음';

  @override
  String get grip_report_rolled => '말아 쥠';

  @override
  String get grip_report_relaxed => '편안함';

  @override
  String get grip_report_inner => '안쪽 지지';

  @override
  String get grip_report_outer => '바깥 지지';

  @override
  String get grip_report_zoom => '탭하여 확대';

  @override
  String get grip_report_delete_confirm => '기준 삭제';

  @override
  String get grip_report_delete_msg => '정말 삭제하시겠습니까?';

  @override
  String get grip_report_ad_area => 'AdMob 배너 광고 영역';

  @override
  String get grip_metric_index_angle => '검지 각도';

  @override
  String get grip_metric_thumb_dist => '엄지 거리';

  @override
  String get grip_metric_stable => '안정적';

  @override
  String get grip_metric_unstable => '불안정';

  @override
  String get grip_metric_gap_diff => '기준 대비 차이';

  @override
  String get grip_gauge_tight => '타이트함';

  @override
  String get grip_gauge_wide => '와이드함';

  @override
  String get grip_gauge_bent => '많이 굽힘';

  @override
  String get grip_gauge_straight => '펴짐';

  @override
  String get grip_gauge_deep => '깊게 잡음';

  @override
  String get grip_gauge_shallow => '얕게 잡음';

  @override
  String get grip_preview_load_error => '이미지를 불러올 수 없어요';

  @override
  String grip_preview_created_at(Object date) {
    return '저장일: $date';
  }

  @override
  String grip_preview_frame(Object id) {
    return '프레임 $id';
  }

  @override
  String get history_no_data => '데이터를 불러올 수 없습니다.';

  @override
  String get calc_start_msg => '시작 점수를 입력하세요';

  @override
  String get calc_start_hint => '2 ~ 170';

  @override
  String get calc_remain_score => '남은 점수';

  @override
  String calc_current_turn(Object score) {
    return '이번 턴: $score';
  }

  @override
  String get calc_recommend_title => '추천 체크아웃 루트';

  @override
  String get calc_error_range => '2~170 사이의 점수를 입력하세요';

  @override
  String get calc_error_exceed => '남은 점수보다 클 수 없어요';

  @override
  String get grip_coach_gap_wide => '↔️ [그립 너비] 엄지-검지가 기준보다 멉니다.';

  @override
  String get grip_coach_gap_tight => '-><- [그립 너비] 엄지-검지가 기준보다 가깝습니다.';

  @override
  String get grip_coach_gap_perfect => '✅ [그립 너비] 엄지와 검지 간격이 완벽합니다!';

  @override
  String grip_coach_finger_straight(Object finger) {
    return '☝️ [$finger] 기준보다 더 펴졌습니다.';
  }

  @override
  String grip_coach_finger_bent(Object finger) {
    return '✊ [$finger] 기준보다 더 구부러졌습니다.';
  }

  @override
  String get grip_coach_all_perfect => '🎉 완벽합니다! 모든 손가락이 기준 그립과 일치합니다.';

  @override
  String grip_coach_good_job(Object fingers) {
    return '🆗 $fingers의 모양은 기준과 잘 맞습니다.';
  }

  @override
  String get grip_coach_index => '검지';

  @override
  String get grip_coach_middle => '중지';

  @override
  String get grip_coach_ring => '약지';

  @override
  String get grip_coach_pinky => '새끼손가락';

  @override
  String get arena_title_steel => '스틸리그';

  @override
  String get arena_title_tournament => '토너먼트';

  @override
  String get arena_menu_member => 'KDF 정회원';

  @override
  String get arena_menu_my => '내 주최 경기';

  @override
  String get arena_menu_admin => '메일 테스트';

  @override
  String get arena_preview_open => '지금 참가 가능한 대회';

  @override
  String get arena_preview_upcoming => '예정된 대회';

  @override
  String get arena_preview_see_all => '전체 보기';

  @override
  String arena_preview_no_data(Object title) {
    return '아직 $title가 없어요';
  }

  @override
  String get arena_preview_closed => '마감됨';

  @override
  String get tournament_home_title => '대회 찾기';

  @override
  String get tournament_empty_open =>
      '현재 참여 가능한 대회가 없습니다.\n새로운 대회가 열리면 알려드릴게요!';

  @override
  String get tournament_empty_upcoming =>
      '아직 예정된 대회가 없습니다.\n곧 멋진 대회가 열릴 예정이니 기다려주세요.';

  @override
  String get tournament_empty_closed => '마감된 대회가 없습니다.';

  @override
  String get tournament_empty_default =>
      '등록된 대회가 없습니다.\n직접 대회를 개최해 보시는 건 어떨까요?';

  @override
  String get entry_list_no_data => '아직 참가자가 없습니다';

  @override
  String get entry_list_not_found => '대회를 찾을 수 없습니다.';

  @override
  String get entry_list_manual => '수동';

  @override
  String entry_list_team_prefix(Object name) {
    return '[팀] $name';
  }

  @override
  String entry_list_team_leader(Object name) {
    return '팀장: $name';
  }

  @override
  String get entry_list_paid => '입금완료';

  @override
  String get entry_list_not_paid => '미입금';

  @override
  String entry_list_detail_no(Object order) {
    return 'No.$order';
  }

  @override
  String get entry_list_info_name => '성함';

  @override
  String get entry_list_info_leader => '팀장 성함';

  @override
  String get entry_list_info_phone => '연락처';

  @override
  String get entry_list_info_rating => '레이팅';

  @override
  String get entry_list_info_homeshop => '홈샵';

  @override
  String get entry_list_qna_title => '신청 질문 답변';

  @override
  String get entry_list_member_title => '팀원 목록 및 개별 답변';

  @override
  String entry_list_total_rating(Object rating) {
    return '팀 합계 레이팅: $rating';
  }

  @override
  String get entry_list_btn_edit => '정보 수정';

  @override
  String get entry_list_btn_delete => '엔트리 삭제';

  @override
  String get entry_list_edit_dialog_title => '참가자 정보 수정';

  @override
  String get entry_list_edit_name_ko => '한글 이름';

  @override
  String get entry_list_edit_name_en => '영문 이름';

  @override
  String get entry_list_edit_phone => '연락처';

  @override
  String get entry_list_edit_rating => '레이팅 (선택)';

  @override
  String get entry_list_edit_homeshop => '홈샵 (선택)';

  @override
  String get entry_list_delete_confirm_title => '엔트리 삭제';

  @override
  String entry_list_delete_confirm_msg(Object name) {
    return '\"$name\" 참가자를 삭제하시겠습니까?';
  }

  @override
  String get entry_form_manual_title => '오프라인 참가자 추가';

  @override
  String get entry_form_manual_banner =>
      '주최자 권한으로 외부 참가자를 등록합니다.\n입력한 정보는 실시간 명단에 즉시 반영됩니다.';

  @override
  String get entry_form_guide_team => '팀 참가 신청 정보를 입력해 주세요.';

  @override
  String get entry_form_guide_single => '개인 참가 신청 정보를 입력해 주세요.';

  @override
  String get entry_form_section_leader => '팀장 정보';

  @override
  String get entry_form_section_my => '내 정보';

  @override
  String get entry_form_section_member => '팀원 정보';

  @override
  String get entry_form_field_team_name => '팀명';

  @override
  String get entry_form_field_name_ko => '이름(한글)';

  @override
  String get entry_form_field_name_en => '이름(영문)';

  @override
  String get entry_form_field_phone => '연락처';

  @override
  String get entry_form_field_rating => '레이팅';

  @override
  String get entry_form_field_rating_opt => '레이팅 (선택)';

  @override
  String get entry_form_field_homeshop => '홈샵 (선택)';

  @override
  String entry_form_field_member_no(Object index) {
    return '팀원 $index';
  }

  @override
  String get entry_form_field_required => '필수 입력 항목입니다.';

  @override
  String get entry_form_btn_submit => '참가 신청 완료';

  @override
  String get entry_form_btn_manual => '수동 참가 등록 완료';

  @override
  String get entry_form_msg_success => '참가 신청 완료!';

  @override
  String get entry_form_msg_manual_success => '수동 등록이 완료되었습니다.';

  @override
  String entry_form_msg_fail(Object error) {
    return '신청 실패: $error';
  }

  @override
  String get entry_form_status_pending => '신청 접수 완료';

  @override
  String get entry_form_status_paid => '입금 확인 완료!';

  @override
  String get entry_form_desc_pending =>
      '신청서가 정상 접수되었습니다.\n주최자가 입금을 확인하면 \"입금완료\"로 변경됩니다.';

  @override
  String get entry_form_desc_paid => '참가비 입금이 확인되었습니다.\n대회 당일 현장에서 뵙겠습니다!';

  @override
  String get entry_form_cancel_title => '참가 취소';

  @override
  String get entry_form_cancel_msg => '참가 신청을 취소하시겠습니까?';

  @override
  String get entry_form_cancel_confirm => '취소하기';

  @override
  String get entry_form_cancel_success => '신청이 취소되었습니다.';

  @override
  String get entry_edit_title => '엔트리 정보 수정';

  @override
  String get entry_edit_manual_banner => '오프라인으로 직접 추가한 참가자 정보입니다.';

  @override
  String get entry_edit_section_setup => '대회 방식 설정';

  @override
  String get entry_edit_section_leader => '대표자(팀장) 정보';

  @override
  String get entry_edit_section_leader_qna => '대표자 개별 답변';

  @override
  String get entry_edit_section_member => '팀원 정보 및 답변 수정';

  @override
  String get entry_edit_success => '참가 정보가 수정되었습니다.';

  @override
  String entry_edit_fail(Object error) {
    return '수정 실패: $error';
  }

  @override
  String entry_edit_field_member_no(Object index) {
    return '팀원 $index';
  }

  @override
  String get entry_edit_field_member_qna => '팀원 개별 답변';

  @override
  String get tournament_edit_title => '대회 수정';

  @override
  String get tournament_edit_save_success => '수정되었습니다.';

  @override
  String get tournament_edit_poster_title => '대회 포스터 수정';

  @override
  String get tournament_edit_method_title => '대회 방식 설정';

  @override
  String get tournament_edit_type_single => '개인전 (Single)';

  @override
  String get tournament_edit_type_team => '팀전 (Team)';

  @override
  String get tournament_edit_team_size => '팀당 인원수 (대표자 포함)';

  @override
  String get tournament_edit_basic_title => '기본 정보';

  @override
  String get tournament_edit_field_title => '대회명';

  @override
  String get tournament_edit_field_location => '장소';

  @override
  String get tournament_edit_field_manager => '담당자 성함';

  @override
  String get tournament_edit_field_contact => '담당자 연락처';

  @override
  String get tournament_edit_date_title => '참가 및 날짜 설정';

  @override
  String get tournament_edit_field_fee => '참가비';

  @override
  String get tournament_edit_field_max => '최대 인원';

  @override
  String get tournament_edit_field_unlimited => '무제한';

  @override
  String get tournament_edit_date_event => '대회 날짜';

  @override
  String get tournament_edit_time_event => '대회 시간';

  @override
  String get tournament_edit_date_entry_start => '엔트리 시작';

  @override
  String get tournament_edit_date_entry_end => '엔트리 마감';

  @override
  String get tournament_edit_desc_title => '상세 안내';

  @override
  String get tournament_edit_desc_hint => '대회 규칙 등을 작성해주세요.';

  @override
  String get tournament_edit_custom_q_title => '신청 시 추가 질문 (선택)';

  @override
  String get tournament_edit_custom_q_hint => '질문을 입력하고 추가 버튼을 누르세요.';

  @override
  String get tournament_edit_co_host_title => '공동주최자 추가';

  @override
  String get tournament_edit_co_host_hint => '이메일 입력';

  @override
  String get tournament_edit_time_picker_title => '대회 시간 수정';

  @override
  String get tournament_detail_loading_error => '데이터 로딩 중 오류가 발생했습니다.';

  @override
  String get tournament_detail_not_found => '존재하지 않거나 삭제된 대회입니다. 😅';

  @override
  String tournament_detail_entry_count(Object current, Object max) {
    return '신청 $current/$max명';
  }

  @override
  String get tournament_detail_info_title => '대회 상세 정보';

  @override
  String get tournament_detail_no_desc => '상세 정보가 없습니다.';

  @override
  String get tournament_detail_list_title => '실시간 참가 명단';

  @override
  String get tournament_detail_no_entries => '아직 신청자가 없습니다.';

  @override
  String get tournament_detail_admin_title => '주최자 권한';

  @override
  String get tournament_detail_admin_delete => '대회 삭제';

  @override
  String get tournament_detail_admin_delete_msg =>
      '참가자 명단과 포스터 사진을 포함한 모든 데이터가 영구적으로 삭제됩니다. 정말 진행하시겠습니까?';

  @override
  String get tournament_detail_btn_apply => '참가 신청하기';

  @override
  String get tournament_detail_btn_cancel => '참가 신청 취소하기';

  @override
  String get tournament_detail_btn_manual => '오프라인 참가자 직접 추가';

  @override
  String get tournament_detail_btn_not_period => '신청 기간이 아닙니다';

  @override
  String get tournament_detail_btn_closed => '신청이 마감되었습니다';

  @override
  String get tournament_detail_manage_title => '참가자 관리';

  @override
  String get tournament_detail_manage_edit => '참가자 정보 수정';

  @override
  String get tournament_detail_manage_pay_on => '입금 확인 처리';

  @override
  String get tournament_detail_manage_pay_off => '입금 확인 취소';

  @override
  String get tournament_detail_manage_delete => '엔트리 강제 삭제';

  @override
  String get tournament_detail_share_title => '[DAO 아레나] 새로운 다트 대회가 열렸습니다! 🎯';

  @override
  String tournament_detail_share_info(
      Object date, Object fee, Object location, Object title) {
    return '🏆 대회명: $title\n📍 장소: $location\n📅 일시: $date\n💰 참가비: $fee';
  }

  @override
  String get tournament_detail_share_footer => '지금 DAO 앱에서 실시간 명단을 확인하고 신청하세요!';

  @override
  String get debug_title => 'Tournament Debug Tools';

  @override
  String get debug_mail_section_title => '테스트 메일 발송 (admin only)';

  @override
  String get debug_mail_guide =>
      '※ functions/index.js의 관리자 UID 조건을 통과해야 동작합니다.\n※ tournamentId는 Firestore tournaments 문서 ID를 넣어주세요.';

  @override
  String get debug_mail_field_id => 'tournamentId';

  @override
  String get debug_mail_field_hint => '예: aBcD1234....';

  @override
  String get debug_mail_btn_send => '테스트 메일 보내기';

  @override
  String get debug_mail_btn_sending => '발송 중...';

  @override
  String get debug_mail_tip_title => '팁: tournamentId 찾는 법';

  @override
  String get debug_mail_tip_desc =>
      '• Firebase Console → Firestore → tournaments 컬렉션\n• 문서 클릭하면 상단에 Document ID가 tournamentId 입니다.';

  @override
  String get debug_mail_msg_enter_id => 'tournamentId를 입력해주세요';

  @override
  String get debug_mail_msg_success => '✅ 테스트 메일 발송 요청 완료! (받은편지함/스팸함 확인)';

  @override
  String debug_mail_msg_functions_error(Object code, Object message) {
    return '❌ Functions 오류: $code\n$message';
  }

  @override
  String debug_mail_msg_error(Object error) {
    return '❌ 오류: $error';
  }

  @override
  String get tournament_create_title => '대회 개설';

  @override
  String get tournament_create_login_title => '로그인 필요';

  @override
  String get tournament_create_login_msg =>
      '대회를 개설하려면 로그인이 필요합니다.\n로그인 후 다시 이용해주세요.';

  @override
  String get tournament_create_success => '대회가 성공적으로 개설되었습니다!';

  @override
  String get tournament_create_poster_add => '대회 포스터 추가';

  @override
  String get tournament_create_team_guide =>
      '※ 팀전 선택 시 신청 폼에서 팀원 정보를 추가로 입력받습니다.';

  @override
  String get tournament_create_email_guide =>
      '📩 엔트리 마감 시 참가자 명단이 담당자 이메일로 자동 전송됩니다.';

  @override
  String get tournament_create_desc_hint => '대회 규칙, 상금, 경기 방식 등을 작성해주세요.';

  @override
  String get tournament_create_custom_q_hint => '예: 카드번호, 파트너 이름 등';

  @override
  String get tournament_create_btn => '개설하기';

  @override
  String get my_tournaments_title => '내가 주최한 대회';

  @override
  String get my_tournaments_no_data => '아직 주최한 대회가 없어요';

  @override
  String get my_tournaments_no_data_guide => '지금 바로 첫 대회를 만들어보세요!';

  @override
  String get my_tournaments_error => '대회 정보를 불러오는 중 오류가 발생했습니다.';

  @override
  String get my_tournaments_btn_create => '대회 개최하기';

  @override
  String get tournament_filter_all => '전체';

  @override
  String get tournament_filter_open => '진행중';

  @override
  String get tournament_filter_upcoming => '예정';

  @override
  String get tournament_filter_closed => '마감';

  @override
  String get common_free => '무료';

  @override
  String common_unit_people(Object count) {
    return '$count명';
  }

  @override
  String get common_currency_won => '원';

  @override
  String get arena_dday_today => '오늘!';

  @override
  String get arena_capacity_full => '매진';

  @override
  String get arena_status_open => '참가 가능';

  @override
  String get arena_status_upcoming => '접수 예정';

  @override
  String get arena_status_closed => '접수 마감';

  @override
  String get arena_status_in_progress => '경기 중';

  @override
  String get arena_status_finished => '대회 종료';

  @override
  String get arena_status_canceled => '대회 취소';

  @override
  String get common_ok => '확인';

  @override
  String get common_no => '아니오';

  @override
  String get common_save => '저장';

  @override
  String get common_select => '선택';

  @override
  String get common_people => '명';

  @override
  String get common_admin_authority => '관리자 권한';

  @override
  String get login_required => '로그인이 필요합니다.';

  @override
  String get entry_edit_setup => '대회 방식 설정';

  @override
  String get league_schedule_empty_day => '날짜를 선택하세요';

  @override
  String get league_schedule_no_events => '경기 없음';

  @override
  String league_schedule_match_suffix(Object shop) {
    return '$shop 경기';
  }

  @override
  String get league_schedule_status_completed => '종료됨';

  @override
  String get league_schedule_status_ongoing => '진행 중';

  @override
  String get league_schedule_status_upcoming => '예정';

  @override
  String league_schedule_winner(Object name) {
    return '우승자: $name';
  }

  @override
  String get league_schedule_detail_date => '날짜';

  @override
  String get league_schedule_detail_time => '시간';

  @override
  String get league_schedule_detail_location => '장소';

  @override
  String get league_schedule_detail_fee => '참가비';

  @override
  String get league_schedule_detail_admin => '관리자';

  @override
  String get league_schedule_detail_contact => '연락처';

  @override
  String get league_schedule_detail_status => '상태';

  @override
  String get league_schedule_no_photo => '사진 없음';

  @override
  String get ranking_title => '스틸리그 랭킹';

  @override
  String get ranking_filter_title => '필터';

  @override
  String get ranking_filter_year => '연도';

  @override
  String get ranking_filter_season => '시즌';

  @override
  String get ranking_filter_gender => '성별';

  @override
  String get ranking_filter_mode => '방식';

  @override
  String get ranking_filter_season_total => '통합';

  @override
  String get ranking_filter_season_1 => '시즌1';

  @override
  String get ranking_filter_season_2 => '시즌2';

  @override
  String get ranking_filter_season_3 => '시즌3';

  @override
  String get ranking_filter_gender_all => '전체';

  @override
  String get ranking_filter_gender_male => '남자';

  @override
  String get ranking_filter_gender_female => '여자';

  @override
  String get ranking_filter_mode_total => '종합';

  @override
  String get ranking_filter_mode_top9 => '상위 9개';

  @override
  String get ranking_no_data => '랭킹 데이터가 없습니다.\n포인트를 부여해 보세요!';

  @override
  String get ranking_load_error => '랭킹 로드 오류';

  @override
  String ranking_total_points(Object points) {
    return '전체: $points';
  }

  @override
  String get point_calendar_title => '스틸리그 포인트 달력';

  @override
  String get point_calendar_search_hint => '이름 검색 (한글/영어)';

  @override
  String get point_calendar_no_selection => '날짜를 선택하세요';

  @override
  String get point_calendar_no_data => '해당 날짜에 포인트 내역 없음';

  @override
  String get point_calendar_search_empty => '검색 결과 없음';

  @override
  String point_calendar_label_season(Object phase, Object year) {
    return '$year 시즌 $phase';
  }

  @override
  String point_calendar_label_total(Object year) {
    return '$year 통합';
  }

  @override
  String get selection_title => '선발 선수';

  @override
  String get selection_header_title => 'KDF 스틸리그 선발 선수';

  @override
  String get selection_header_desc =>
      '시즌 1–3, 통합 포인트를 기준으로\n남녀 각 1명씩 총 8명의 선수가 선발됩니다.';

  @override
  String get selection_label_male => '남자 대표';

  @override
  String get selection_label_female => '여자 대표';

  @override
  String get selection_status_empty => '아직 선발된 선수가 없습니다.';

  @override
  String get selection_status_upcoming => '선발 예정';

  @override
  String get selection_label_season1 => '시즌 1 대표';

  @override
  String get selection_label_season2 => '시즌 2 대표';

  @override
  String get selection_label_season3 => '시즌 3 대표';

  @override
  String get selection_label_total => '통합 대표';

  @override
  String get selection_sub_total => '전체 시즌 통합';

  @override
  String selection_shop_prefix(Object shop) {
    return '소속: $shop';
  }

  @override
  String get member_list_search_hint => '이름 또는 이메일로 검색';

  @override
  String get member_list_no_data => '등록된 정회원이 없습니다.';

  @override
  String get member_list_no_name => '이름 없음';

  @override
  String get member_list_no_email => '이메일 없음';

  @override
  String get community_home_tab_title => '연습 · 대회 · 기록';

  @override
  String get community_home_menu_training => '트레이닝';

  @override
  String get community_home_menu_arena => '아레나';

  @override
  String get community_home_menu_mylog => '마이로그';

  @override
  String get community_home_login_prompt => '커뮤니티를 이용하려면\n로그인이 필요해요';

  @override
  String get community_home_verify_prompt => '커뮤니티 이용을 위해\n인증이 필요해요';

  @override
  String get community_home_verify_profile => '프로필 등록을 완료해 주세요.';

  @override
  String get community_home_verify_phone => '휴대폰 인증을 완료해 주세요.';

  @override
  String get community_home_ugc_title => '커뮤니티 이용 동의가 필요해요';

  @override
  String get community_home_ugc_desc =>
      '커뮤니티에는 사용자가 작성한 글/사진(UGC)이 노출됩니다.\n안전한 이용을 위해 아래 내용에 동의해 주세요.\n\n• 타인을 비방/혐오/차별/괴롭힘하는 콘텐츠 금지\n• 불법/음란/폭력/사기 등 유해 콘텐츠 금지\n• 신고/차단 기능 및 운영 정책에 따라 제재될 수 있음\n• 신고된 콘텐츠는 운영자가 검토할 수 있음';

  @override
  String get community_home_ugc_btn_no => '동의 안함';

  @override
  String get community_home_ugc_btn_yes => '동의하고 시작';

  @override
  String get community_home_ugc_msg_reject => '동의 후 커뮤니티 이용이 가능합니다.';

  @override
  String community_home_ugc_msg_fail(Object error) {
    return '동의 처리 실패: $error';
  }

  @override
  String get community_preview_recent => '최근';

  @override
  String get community_preview_popular => '인기';

  @override
  String get community_preview_see_all => '전체 보기';

  @override
  String get community_preview_type_text => '글';

  @override
  String get community_preview_today_title => '오늘 커뮤니티';

  @override
  String get community_preview_stat_posts => '게시글';

  @override
  String get community_preview_stat_comments => '댓글';

  @override
  String get community_preview_stat_likes => '좋아요';

  @override
  String get community_preview_live_title => '지금 올라온 글';

  @override
  String get community_preview_default_title => '새 게시글';

  @override
  String get community_avatar_no_online => '온라인 유저 없음';

  @override
  String get community_avatar_no_name => '이름 없음';

  @override
  String get post_write_edit_title => '게시물 수정';

  @override
  String get post_write_btn_post => '게시';

  @override
  String get post_write_btn_edit => '수정';

  @override
  String get post_write_hint => '무슨 생각을 하고 계신가요?';

  @override
  String get post_write_photo_limit => '사진은 최대 7장까지 등록 가능합니다.';

  @override
  String get post_write_uploading => '게시글을 올리는 중입니다...';

  @override
  String post_write_upload_progress(Object current, Object total) {
    return '사진 업로드 중 ($current / $total)';
  }

  @override
  String post_write_photo_count(Object current) {
    return '사진 ($current/7)';
  }

  @override
  String get post_write_photo_add => '추가';

  @override
  String get post_write_photo_placeholder => '사진 추가 (최대 7장)';

  @override
  String post_write_error_upload(Object error) {
    return '업로드 실패: $error';
  }

  @override
  String get circle_title => '피드';

  @override
  String get circle_no_visible_posts => '표시할 게시물이 없습니다';

  @override
  String get circle_error_feed => '피드를 불러오지 못했습니다';

  @override
  String get circle_error_auth => '로그인 상태 오류';

  @override
  String get circle_profile_required => '프로필 등록 후 이용 가능합니다';

  @override
  String get circle_list_delete_title => '삭제 확인';

  @override
  String get circle_list_delete_body => '이 게시물을 삭제하시겠습니까?';

  @override
  String get circle_list_no_visible_posts => '표시할 게시물이 없습니다';

  @override
  String get post_card_more => '더 보기';

  @override
  String get post_card_fold => '간단히 접기 ▲';

  @override
  String get post_card_share => '공유';

  @override
  String get post_card_report => '신고';

  @override
  String get post_card_block => '차단';

  @override
  String get post_card_block_title => '사용자 차단';

  @override
  String post_card_block_body(Object name) {
    return '$name 님을 차단할까요?\n\n차단하면 이 사용자의 게시글이 보이지 않습니다.';
  }

  @override
  String post_card_block_success(Object name) {
    return '$name 님을 차단했어요';
  }

  @override
  String get post_card_report_title => '게시물 신고';

  @override
  String get post_card_report_reason => '신고 사유';

  @override
  String get post_card_report_detail => '추가 설명(선택)';

  @override
  String get post_card_report_success => '신고가 접수되었어요.';

  @override
  String get post_card_report_r1 => '스팸/도배';

  @override
  String get post_card_report_r2 => '욕설/혐오';

  @override
  String get post_card_report_r3 => '괴롭힘/따돌림';

  @override
  String get post_card_report_r4 => '성적인 콘텐츠';

  @override
  String get post_card_report_r5 => '폭력/위협';

  @override
  String get post_card_report_r6 => '기타';

  @override
  String post_card_share_msg(Object content, Object link) {
    return '[DAO 커뮤니티] 새로운 게시물이 올라왔습니다! 🎯\n\n$content\n\n지금 DAO 앱에서 확인해보세요.\n👉 $link';
  }

  @override
  String get comment_preview_see_all => '댓글 모두 보기';

  @override
  String get common_anonymous => '익명';

  @override
  String get comment_title => '댓글';

  @override
  String get comment_hint => '댓글을 입력하세요...';

  @override
  String get comment_empty => '아직 댓글이 없습니다';

  @override
  String get comment_no_visible => '표시할 댓글이 없습니다';

  @override
  String get comment_report_title => '댓글 신고';

  @override
  String get comment_report_select_reason => '사유를 선택해 주세요';

  @override
  String get comment_report_success => '신고가 접수되었습니다';

  @override
  String comment_report_fail(Object error) {
    return '신고 실패: $error';
  }

  @override
  String get comment_delete_title => '삭제 확인';

  @override
  String get comment_delete_body => '이 댓글을 삭제하시겠습니까?';

  @override
  String get comment_time_just_now => '방금 전';

  @override
  String get profile_form_korean_name => '활동 이름 (국문)';

  @override
  String get profile_form_korean_name_hint => '이름을 입력하세요';

  @override
  String get profile_form_english_name => '활동 이름 (영문)';

  @override
  String get profile_form_english_name_hint => '이름을 영문으로 입력하세요';

  @override
  String get profile_form_shop_name => '소속 샵';

  @override
  String get profile_form_shop_name_hint => '주로 활동하는 샵을 입력하세요';

  @override
  String get profile_reg_title => '프로필 등록/수정';

  @override
  String get profile_reg_save => '저장 완료';

  @override
  String get profile_reg_success => '성공적으로 저장되었습니다!';

  @override
  String get profile_reg_fail => '저장에 실패했어요. 다시 시도해주세요.';

  @override
  String profile_reg_error(Object error) {
    return '저장 중 오류가 발생했습니다: $error';
  }

  @override
  String get profile_reg_input_check => '입력값을 확인해주세요.';

  @override
  String get profile_image_save => '프로필 사진 저장 완료!';

  @override
  String get profile_image_delete_title => '이미지 영구 삭제';

  @override
  String get profile_image_delete_body =>
      '삭제된 이미지는 즉시 반영되며 되돌릴 수 없습니다.\n정말 삭제하시겠습니까?';

  @override
  String get profile_image_deleted => '이미지가 삭제되었습니다.';

  @override
  String profile_image_fail(Object error) {
    return '이미지 처리 실패: $error';
  }

  @override
  String get barrel_image_save => '배럴 사진 저장 완료!';

  @override
  String get report_screen_title => '버그/신고';

  @override
  String get report_form_title_label => '제목';

  @override
  String get report_form_content_label => '상세 내용';

  @override
  String get report_form_content_hint => '발생 상황, 재현 방법 등을 자세히 적어주세요';

  @override
  String get report_form_photo_add => '사진 추가 (선택)';

  @override
  String get report_form_photo_change => '사진 변경';

  @override
  String get report_form_submit => '신고하기';

  @override
  String get report_form_error_empty => '제목과 내용을 입력하세요';

  @override
  String get report_form_success => '신고가 접수되었습니다. 감사합니다!';

  @override
  String report_form_fail(Object error) {
    return '전송 실패: $error';
  }

  @override
  String get notice_no_title => '제목 없음';

  @override
  String notice_error(Object error) {
    return '공지사항을 불러오는 중 오류가 발생했습니다: $error';
  }

  @override
  String get mypage_login_prompt_title => '로그인하면 내 정보를 확인할 수 있어요!';

  @override
  String get mypage_login_prompt_subtitle => 'Google 계정으로 간편하게 시작하세요';

  @override
  String get mypage_login_btn => 'Google로 로그인';

  @override
  String get mypage_profile_prompt_title => '프로필 등록이 필요해요!';

  @override
  String get mypage_profile_prompt_subtitle => '이름과 소속 샵을 등록하고\n다른 유저와 소통해보세요';

  @override
  String get mypage_profile_reg_btn => '프로필 등록하기';

  @override
  String get mypage_edit_profile => '프로필 수정';

  @override
  String get mypage_my_guestbook => '내 방명록';

  @override
  String get mypage_account_delete => '계정 삭제';

  @override
  String get mypage_logout => '로그아웃';

  @override
  String get mypage_logout_confirm => '정말 로그아웃하시겠습니까?';

  @override
  String get mypage_delete_confirm_title => '계정 삭제';

  @override
  String get mypage_delete_confirm_body =>
      'DAO 계정을 삭제하면 프로필 정보와 앱 내 데이터가 삭제되며,\n이 작업은 되돌릴 수 없습니다.\n\n정말 계정을 삭제하시겠습니까?';

  @override
  String get mypage_delete_error_recent_login =>
      '보안을 위해 최근 로그인한 사용자만 계정을 삭제할 수 있어요.\n다시 로그인한 후 시도해주세요.';

  @override
  String get mypage_delete_error_general => '계정 삭제 중 오류가 발생했습니다.';

  @override
  String get mypage_delete_error_server =>
      '계정 삭제 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get mypage_no_email => '이메일 없음';

  @override
  String get mypage_menu_mylog => '마이로그';

  @override
  String get guestbook_title_me => '내 방명록';

  @override
  String get guestbook_title_other => '방명록 쓰기';

  @override
  String get guestbook_hint => '응원 메시지 남기기...';

  @override
  String get guestbook_empty => '아직 방명록이 없습니다';

  @override
  String get guestbook_success => '방명록이 작성되었습니다';

  @override
  String guestbook_fail(Object error) {
    return '전송 실패: $error';
  }

  @override
  String get block_title => '차단 관리';

  @override
  String get block_empty => '차단한 유저가 없습니다.';

  @override
  String get block_status => '차단됨';

  @override
  String get block_unblock_btn => '차단 해제';

  @override
  String get block_unblock_confirm_title => '차단 해제';

  @override
  String block_unblock_confirm_body(Object name) {
    return '$name님의 차단을 해제하시겠습니까?\n이제 상대방의 게시글과 채팅이 보입니다.';
  }

  @override
  String block_unblock_success(Object name) {
    return '$name님의 차단이 해제되었습니다.';
  }

  @override
  String get block_unblock_fail => '해제 중 오류가 발생했습니다.';

  @override
  String get block_error_load => '데이터를 불러오지 못했습니다.';

  @override
  String get guestbook_header_no_name => '이름 없음';

  @override
  String get guestbook_header_barrel_title => 'PLAYERS_DART';

  @override
  String get guestbook_menu_edit => '수정';

  @override
  String get guestbook_menu_delete => '삭제';

  @override
  String get guestbook_edit_title => '방명록 수정';

  @override
  String get guestbook_edit_complete => '수정 완료';

  @override
  String get guestbook_delete_confirm_title => '삭제 확인';

  @override
  String get guestbook_delete_confirm_body => '이 방명록을 삭제하시겠습니까?';

  @override
  String get guestbook_unknown_user => '알 수 없는 사용자';

  @override
  String get barrel_section_title => '배럴 세팅 (선택)';

  @override
  String get barrel_label_name => '배럴 이름';

  @override
  String get barrel_label_shaft => '샤프트';

  @override
  String get barrel_label_flight => '플라이트';

  @override
  String get barrel_label_tip => '팁';

  @override
  String get image_picker_error => '사진을 선택하지 못했습니다.';

  @override
  String get image_upload_error => '이미지 업로드 중 오류가 발생했습니다.';

  @override
  String get image_delete_error => '이미지 삭제 중 오류가 발생했습니다.';

  @override
  String get mylog_login_required_title => '로그인이 필요해요';

  @override
  String get mylog_login_required_subtitle =>
      '나만의 다트 일기를 기록하고 관리하려면\n로그인이 필요합니다.';

  @override
  String get mylog_login_btn => '로그인 하러 가기';

  @override
  String mylog_summary_streak(Object days) {
    return '🔥 $days일 연속 기록 중';
  }

  @override
  String get mylog_recent_title => '최근 작성한 다트 이야기';

  @override
  String get mylog_no_content => '내용 없음';

  @override
  String get mylog_error_load => '기록을 불러오는 중 오류가 발생했습니다.';

  @override
  String mylog_confirm_sheet_title(Object day, Object month, Object year) {
    return '$year년 $month월 $day일';
  }

  @override
  String get mylog_confirm_sheet_body => '이 날짜에 새로운 다트 일기를 작성할까요?';

  @override
  String get mylog_confirm_sheet_btn_later => '나중에';

  @override
  String get mylog_confirm_sheet_btn_write => '작성하기';

  @override
  String get mylog_calendar_month_label => '월';

  @override
  String get mylog_write_title_new => '일기 작성';

  @override
  String get mylog_write_title_edit => '일기 수정';

  @override
  String get mylog_write_subtitle_new => '오늘의 성장을 기록하세요';

  @override
  String get mylog_write_subtitle_edit => '기억을 다듬고 있어요';

  @override
  String get mylog_write_image_add => '사진 추가 (선택)';

  @override
  String get mylog_write_guide_title => '작성 가이드 (탭해서 추가/삭제)';

  @override
  String get mylog_write_guide_good => '💪 잘 된 점';

  @override
  String get mylog_write_guide_bad => '🧐 아쉬운 점';

  @override
  String get mylog_write_guide_next => '✏️ 다음 계획';

  @override
  String get mylog_write_guide_review => '📝 한 줄 평';

  @override
  String get mylog_write_template_good => '💪 오늘 잘 된 점\n- ';

  @override
  String get mylog_write_template_bad => '🧐 아쉬웠던 점\n- ';

  @override
  String get mylog_write_template_next => '✏️ 다음 연습 계획\n- ';

  @override
  String get mylog_write_template_review => '📝 오늘의 한 줄\n- ';

  @override
  String get mylog_write_hint => '오늘 다트 어땠나요?\n기억에 남는 샷이나 보완할 점을 적어보세요.';

  @override
  String get mylog_write_share_title => '서클(커뮤니티)에 공유';

  @override
  String get mylog_write_share_subtitle_new => '저장과 동시에 피드에 게시합니다.';

  @override
  String get mylog_write_share_subtitle_edit => '이미 공유된 기록입니다.';

  @override
  String get mylog_write_save_btn => '기록 저장하기';

  @override
  String get mylog_write_empty_error => '기록할 내용을 입력해주세요.';

  @override
  String mylog_write_save_fail(Object error) {
    return '저장 실패: $error';
  }

  @override
  String get mylog_detail_error_not_found => '기록을 찾을 수 없습니다.';

  @override
  String mylog_detail_written_at(Object time) {
    return '$time 작성됨';
  }

  @override
  String get mylog_detail_shared_circle => '서클 공유됨';

  @override
  String get mylog_detail_content_title => '오늘의 다트 이야기';

  @override
  String get mylog_detail_no_content => '작성된 내용이 없습니다.';

  @override
  String get mylog_detail_footer => 'DAO와 함께한 당신의 성장을 응원합니다.';

  @override
  String get mylog_detail_delete_title => '기록 삭제';

  @override
  String get mylog_detail_delete_body => '이 날의 소중한 기록을 정말 삭제하시겠습니까?';

  @override
  String get mylog_detail_delete_btn => '삭제하기';

  @override
  String get mylog_detail_delete_success => '기록이 삭제되었습니다.';

  @override
  String get mylog_card_subtitle => '오늘의 다트 이야기';

  @override
  String get mylog_card_image_error => '사진을 불러올 수 없어요';

  @override
  String get mylog_card_image_tag => '오늘의 샷';

  @override
  String get mylog_card_no_content =>
      '아직 내용이 없어요. 다음엔 오늘의 다트 이야기를 더 자세히 남겨볼까요?';

  @override
  String get mylog_card_shared_badge => '서클에 공유됨';

  @override
  String get chat_login_required => '로그인이 필요합니다.';

  @override
  String get chat_empty_title => 'DAO 라이브 톡에 오신 것을 환영합니다!';

  @override
  String get chat_empty_subtitle => '첫 번째 메시지를 남겨보세요.';

  @override
  String get chat_error_load => '데이터를 불러오는 중 에러가 발생했습니다.';

  @override
  String get chat_ticker_default_notice => 'DAO 라이브 톡에 오신 것을 환영합니다!';

  @override
  String get chat_ticker_prefix_ranking => '[랭킹]';

  @override
  String get chat_ticker_prefix_tournament => '[대회]';

  @override
  String get chat_ticker_prefix_welcome => '[환영]';

  @override
  String get chat_ticker_prefix_notice => '[공지]';

  @override
  String get chat_overlay_title => 'DAO 라이브 톡';

  @override
  String get chat_overlay_block_guide => '상대방의 메시지를 꾹 누르면 차단을 할 수 있습니다.';

  @override
  String get chat_bubble_menu_report_title => '신고하기';

  @override
  String get chat_bubble_menu_report_subtitle => '부적절한 메시지로 신고합니다.';

  @override
  String chat_bubble_menu_block_title(Object name) {
    return '$name 님 차단하기';
  }

  @override
  String get chat_bubble_menu_block_subtitle => '이 사용자의 메시지를 더 이상 보지 않습니다.';

  @override
  String get chat_bubble_block_dialog_title => '사용자 차단';

  @override
  String chat_bubble_block_dialog_body(Object name) {
    return '$name 님을 차단하시겠습니까?\n차단 후에는 이 사용자의 대화가 보이지 않습니다.';
  }

  @override
  String chat_bubble_block_success(Object name) {
    return '$name 님이 차단되었습니다.';
  }

  @override
  String get chat_bubble_block_fail => '차단 중 오류가 발생했습니다.';

  @override
  String get chat_bubble_unknown_user => '알 수 없는 사용자';

  @override
  String get chat_input_hint => '메시지를 입력하세요...';

  @override
  String get chat_input_cooldown => '잠시 대기 중...';

  @override
  String chat_input_send_fail(Object error) {
    return '전송 실패: $error';
  }

  @override
  String get profile_reg_fail_duplicate_name =>
      '이미 사용 중인 닉네임입니다. 다른 이름을 입력해주세요.';

  @override
  String get common_login_required => '로그인이 필요합니다';

  @override
  String get common_error_msg => '오류가 발생했습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get live_btn_move => '이동하기';

  @override
  String get common_msg_processing => '처리 중입니다...';

  @override
  String get circle_translate_btn => '번역하기';

  @override
  String get circle_translate_show_original => '원문 보기';

  @override
  String get circle_translate_fail => '번역에 실패했습니다. 다시 시도해주세요.';

  @override
  String get tab_home => '홈';

  @override
  String get tab_training => '트레이닝';

  @override
  String get tab_arena => '아레나';

  @override
  String get tab_community => '커뮤니티';

  @override
  String get tab_mypage => '내정보';

  @override
  String get ban_msg_restricted => '운영 정책에 의해 이용이 제한된 계정입니다.';

  @override
  String get menu_tooltip_settings => '설정';

  @override
  String get menu_block_manage => '차단 유저 관리';

  @override
  String get menu_admin_block_manage => '전체 차단 관리';

  @override
  String get menu_admin_mode => '관리자 모드';

  @override
  String get profile_players_dart => '플레이어 다트 장비';

  @override
  String get profile_barrel => '배럴';

  @override
  String get profile_shaft => '샤프트';

  @override
  String get profile_flight => '플라이트';

  @override
  String get profile_tip => '팁';

  @override
  String get profile_go_guestbook_me => '내 방명록 가기';

  @override
  String get profile_go_guestbook_other => '방명록 쓰러 가기';

  @override
  String get login_google => 'Google로 로그인';

  @override
  String get login_apple => 'Apple로 로그인';

  @override
  String get login_admin_info => '운영자 · 심사용 계정에만 사용하는 로그인 방식입니다.';

  @override
  String get login_email => '이메일';

  @override
  String get login_password => '비밀번호';

  @override
  String get login_email_btn => '이메일로 로그인';

  @override
  String get login_skip => '건너뛰기';

  @override
  String get login_fail_google => 'Google 로그인 중 오류가 발생했습니다.';

  @override
  String get login_fail_apple => 'Apple 로그인 중 오류가 발생했습니다.';

  @override
  String get login_error_email_empty => '이메일을 입력해주세요.';

  @override
  String get login_error_email_format => '이메일 형식이 올바르지 않습니다.';

  @override
  String get login_error_password_empty => '비밀번호를 입력해주세요.';

  @override
  String get login_error_password_length => '비밀번호는 6자 이상이어야 합니다.';

  @override
  String get post_write_delay_msg => '잠시 후 다시 시도해주세요. 게시글은 1분마다 작성할 수 있습니다.';

  @override
  String notice_detail_photo_count(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get notice_lang_ko => '한국어';

  @override
  String get notice_lang_en => 'English';

  @override
  String get notice_lang_ja => '日本語';

  @override
  String get notice_lang_zh_hant => '繁體';

  @override
  String get notice_lang_zh_hans => '简体';

  @override
  String notice_photo_indicator(Object current, Object total) {
    return '$current / $total';
  }
}
