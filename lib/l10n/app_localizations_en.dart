// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get badge_name_pro => 'Pro';

  @override
  String get badge_name_emerald => 'Emerald';

  @override
  String get badge_name_diamond => 'Diamond';

  @override
  String get badge_name_platinum => 'Platinum';

  @override
  String get badge_name_gold => 'Gold';

  @override
  String get badge_name_silver => 'Silver';

  @override
  String get badge_name_bronze => 'Bronze';

  @override
  String get badge_name_platinum1 => 'Platinum 1';

  @override
  String get badge_name_platinum2 => 'Platinum 2';

  @override
  String get badge_name_gold1 => 'Gold 1';

  @override
  String get badge_name_gold2 => 'Gold 2';

  @override
  String get badge_name_silver1 => 'Silver 1';

  @override
  String get badge_name_silver2 => 'Silver 2';

  @override
  String get badge_name_bronze1 => 'Bronze 1';

  @override
  String get badge_name_bronze2 => 'Bronze 2';

  @override
  String get badge_name_bronze3 => 'Bronze 3';

  @override
  String get badge_name_trophy => 'Trophy';

  @override
  String get badge_name_season_champion => 'Season Champion';

  @override
  String get badge_name_season_rank1 => 'Season 1st Place';

  @override
  String get badge_name_season_rank2 => 'Season 2nd Place';

  @override
  String get badge_name_season_rank3 => 'Season 3rd Place';

  @override
  String get badge_name_season_general => 'Season Badge';

  @override
  String get badge_name_monthly => 'Monthly Badge';

  @override
  String get menu_home => 'Home';

  @override
  String get menu_training => 'Training';

  @override
  String get menu_arena => 'Arena';

  @override
  String get menu_community => 'Community';

  @override
  String get menu_mypage => 'My Page';

  @override
  String get menu_settings => 'Settings';

  @override
  String get menu_notice => 'Notices';

  @override
  String get menu_report => 'Report Bug';

  @override
  String get menu_quick_arena => 'Arena';

  @override
  String get menu_quick_league => 'Steel League';

  @override
  String get menu_quick_tournament => 'Tournament';

  @override
  String get menu_quick_training => 'Training';

  @override
  String get menu_quick_pose => 'Pose Analysis';

  @override
  String get menu_quick_grip => 'Grip Lab';

  @override
  String get menu_quick_profile => 'Profile';

  @override
  String get menu_quick_mylog => 'My Log';

  @override
  String get menu_quick_livetalk => 'Live Talk';

  @override
  String get menu_quick_circle => 'Circle';

  @override
  String get menu_quick_block => 'Block List';

  @override
  String get menu_quick_report => 'Report Bug';

  @override
  String get nav_tab_home => 'Home';

  @override
  String get nav_tab_training => 'Training';

  @override
  String get nav_tab_arena => 'Arena';

  @override
  String get nav_tab_community => 'Community';

  @override
  String get nav_tab_mypage => 'My Info';

  @override
  String get drill_history => 'Training History';

  @override
  String get checkout_calculator => 'Checkout Calculator';

  @override
  String get drill_run_title => 'Drill in Progress';

  @override
  String get drill_difficulty_easy => 'Easy';

  @override
  String get drill_difficulty_normal => 'Normal';

  @override
  String get drill_difficulty_hard => 'Hard';

  @override
  String get drill_difficulty_within => 'Within';

  @override
  String get drill_category_boardMapping => 'Board Mapping';

  @override
  String get drill_category_scoring => 'Scoring';

  @override
  String get drill_category_finish => 'Finish';

  @override
  String get drill_category_doublePractice => 'Double Practice';

  @override
  String get drill_category_bull => 'Bullseye Practice';

  @override
  String get drill_category_other => 'Others';

  @override
  String get guide_target_hit =>
      'Throw darts at the target area and enter the number of hits.';

  @override
  String get guide_finish_desc => 'Finish with a double-out within 3 darts.';

  @override
  String get guide_mpr_goal => 'Goal: Average MPR 2.0 or higher!';

  @override
  String get tier_beginner => 'Beginner';

  @override
  String get tier_learner => 'Learner';

  @override
  String get tier_competitor => 'Competitor';

  @override
  String get tier_challenger => 'Challenger';

  @override
  String get tier_elite => 'Elite';

  @override
  String get tier_pro => 'Pro';

  @override
  String get tier_master => 'Master';

  @override
  String get status_upcoming => 'Upcoming';

  @override
  String get status_open => 'Entry Open';

  @override
  String get status_closed => 'Closed';

  @override
  String get status_in_progress => 'In Progress';

  @override
  String get status_finished => 'Finished';

  @override
  String get status_canceled => 'Canceled';

  @override
  String get time_just_now => 'Just now';

  @override
  String time_minutes_ago(Object count) {
    return '${count}m ago';
  }

  @override
  String time_hours_ago(Object count) {
    return '${count}h ago';
  }

  @override
  String get grip_perfect => 'Perfect!';

  @override
  String grip_good_shape(Object finger) {
    return '$finger shape matches the baseline.';
  }

  @override
  String get grip_wide => 'Thumb and index are too wide.';

  @override
  String get grip_narrow => 'Thumb and index are too narrow.';

  @override
  String get grip_too_straight => 'Straighter than the baseline.';

  @override
  String get grip_too_curved => 'More curved than the baseline.';

  @override
  String cycle_label_format(Object tier) {
    return '$tier Cycle';
  }

  @override
  String cycle_old_format(Object number) {
    return 'Cycle $number';
  }

  @override
  String get err_login_required => 'Login required to access this service.';

  @override
  String get err_save_failed => 'Failed to save the record.';

  @override
  String get name_no_name => 'No Name';

  @override
  String get calc_btn_reset => 'Reset';

  @override
  String get calc_undo => 'Undo';

  @override
  String get calc_title => 'Checkout Calculator';

  @override
  String get practice_msg_bust => 'Bust!';

  @override
  String get practice_msg_success => 'Checkout Success!';

  @override
  String get practice_msg_finish => 'All problems completed.';

  @override
  String get state_loading => 'Loading...';

  @override
  String get err_fetch_baseline => 'Failed to load the baseline grip.';

  @override
  String get err_save_baseline => 'Failed to save the baseline grip.';

  @override
  String get err_delete_baseline => 'Failed to delete the baseline grip.';

  @override
  String get err_session_start => 'Failed to start session';

  @override
  String get err_session_save => 'Failed to save session';

  @override
  String get msg_video_selected => 'Video selection complete';

  @override
  String get msg_processing_video => 'Processing video...';

  @override
  String get msg_analysis_complete => 'Analysis complete!';

  @override
  String get msg_video_saved_gallery => 'Video saved to gallery! 🎉';

  @override
  String get msg_video_save_failed => 'Failed to generate video.';

  @override
  String get part_right_wrist => 'Right Wrist';

  @override
  String get part_left_wrist => 'Left Wrist';

  @override
  String get part_right_elbow => 'Right Elbow';

  @override
  String get part_left_elbow => 'Left Elbow';

  @override
  String get part_right_shoulder => 'Right Shoulder';

  @override
  String get part_left_shoulder => 'Left Shoulder';

  @override
  String get auth_login_prompt => 'Login required for community';

  @override
  String get auth_verify_required => 'Verification required';

  @override
  String get auth_profile_needed => 'Please complete your profile';

  @override
  String get auth_phone_needed => 'Please verify your phone number';

  @override
  String get filter_all => 'All';

  @override
  String get filter_open => 'Entry Open';

  @override
  String get filter_upcoming => 'Upcoming';

  @override
  String get filter_closed => 'Closed';

  @override
  String get filter_in_progress => 'In Progress';

  @override
  String get filter_season_label => 'Season';

  @override
  String get filter_year_label => 'Year';

  @override
  String get filter_top9 => 'Top 9';

  @override
  String get rank_total_points => 'Total Points';

  @override
  String get rank_phase_total => 'Cumulative';

  @override
  String get rank_gender_all => 'All Genders';

  @override
  String get rank_gender_male => 'Male';

  @override
  String get rank_gender_female => 'Female';

  @override
  String get msg_no_notices => 'No new notices.';

  @override
  String get common_search_hint => 'Search by name or email';

  @override
  String get common_no_data => 'No registered information.';

  @override
  String get common_close => 'Close';

  @override
  String get common_winner => 'Winner';

  @override
  String get common_location => 'Location';

  @override
  String get common_fee => 'Entry Fee';

  @override
  String get common_share => 'Share';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_back => 'Back';

  @override
  String get common_msg_deleted => 'Deleted';

  @override
  String get common_msg_img_err => 'Failed to load image';

  @override
  String get member_list_title => 'KDF Official Members';

  @override
  String get player_selection_title => 'Selected Players';

  @override
  String get player_selection_desc =>
      'A total of 8 players are selected based on cumulative points.';

  @override
  String get player_rep_male => 'Male Rep.';

  @override
  String get player_rep_female => 'Female Rep.';

  @override
  String get player_upcoming => 'TBD';

  @override
  String get league_calendar_title => 'Point Calendar';

  @override
  String get league_schedule_title => 'Steel League Schedule';

  @override
  String get league_ranking_title => 'Steel League Ranking';

  @override
  String tourney_count_unlimited(Object count) {
    return '$count Joined';
  }

  @override
  String tourney_count_fixed(Object count, Object max) {
    return '$count/$max';
  }

  @override
  String get tourney_fee_free => 'Free Entry';

  @override
  String tourney_fee_format(Object amount) {
    return '$amount KRW';
  }

  @override
  String get tourney_today => 'Today!';

  @override
  String tourney_dday(Object day) {
    return 'D-$day';
  }

  @override
  String get tourney_closed => 'Closed';

  @override
  String get img_error_poster => 'Failed to load poster image.';

  @override
  String get tourney_my_hosted => 'My Hosted';

  @override
  String get tourney_create_title => 'Create Tournament';

  @override
  String get tourney_edit_title => 'Edit Tournament';

  @override
  String get tourney_detail_title => 'Tournament Details';

  @override
  String get tourney_btn_apply => 'Apply Now';

  @override
  String get tourney_btn_cancel_apply => 'Cancel Application';

  @override
  String get tourney_btn_delete => 'Delete Tournament';

  @override
  String get tourney_full_capacity => 'Fully Booked';

  @override
  String get form_label_title => 'Tournament Name';

  @override
  String get form_label_location => 'Location';

  @override
  String get form_label_host_name => 'Host Name';

  @override
  String get form_label_host_phone => 'Contact Number';

  @override
  String get form_label_fee => 'Entry Fee';

  @override
  String get form_label_max_players => 'Max Participants';

  @override
  String get form_label_desc => 'Description';

  @override
  String get form_hint_desc => 'Enter rules, prizes, etc.';

  @override
  String get msg_save_success => 'Saved successfully.';

  @override
  String get msg_delete_confirm => 'Delete this comment?';

  @override
  String get msg_err_login_needed => 'Login required to continue.';

  @override
  String get msg_err_date_order => 'Check the date order.';

  @override
  String get arena_league_title => 'Steel League';

  @override
  String get arena_menu_ranking => 'Ranking';

  @override
  String get arena_menu_schedule => 'Schedule';

  @override
  String get arena_menu_calendar => 'Point Calendar';

  @override
  String get arena_menu_kdf_member => 'KDF Member';

  @override
  String get arena_menu_selection => 'Selection';

  @override
  String get arena_tourney_title => 'Tournament';

  @override
  String get arena_menu_create => 'Host';

  @override
  String get arena_menu_open => 'Available';

  @override
  String get arena_menu_upcoming => 'Upcoming';

  @override
  String get arena_menu_my_hosted => 'My Events';

  @override
  String get arena_preview_available => 'Available Now';

  @override
  String get entry_form_title => 'Tournament Entry';

  @override
  String get entry_label_name_ko => 'Name (Local) *';

  @override
  String get entry_label_name_en => 'Name (English) *';

  @override
  String get entry_label_phone => 'Phone *';

  @override
  String get entry_label_rating => 'Rating (Optional)';

  @override
  String get entry_label_homeshop => 'Home Shop (Optional)';

  @override
  String get entry_msg_already => 'You have already entered.';

  @override
  String get entry_msg_full => 'Fully Booked';

  @override
  String get entry_btn_submit => 'Complete Entry';

  @override
  String get entry_list_title => 'Participant List';

  @override
  String get entry_list_empty => 'No participants yet.';

  @override
  String entry_detail_no(Object number) {
    return 'No.$number';
  }

  @override
  String get entry_delete_confirm => 'Delete this entry?';

  @override
  String get comm_comment_title => 'Comments';

  @override
  String get comm_hint_input => 'Enter a comment...';

  @override
  String get comm_no_comments => 'No comments yet.';

  @override
  String get comm_view_all => 'View all comments';

  @override
  String get comm_more => 'More';

  @override
  String get comm_less => 'Less';

  @override
  String get comm_unknown_user => 'Anonymous';

  @override
  String get report_title_post => 'Report Post';

  @override
  String get report_title_comment => 'Report Comment';

  @override
  String get report_select_reason => 'Select a reason';

  @override
  String get report_reason_spam => 'Spam';

  @override
  String get report_reason_abuse => 'Abuse';

  @override
  String get report_reason_hate => 'Hate speech';

  @override
  String get report_reason_sexual => 'Sexual content';

  @override
  String get report_reason_privacy => 'Privacy violation';

  @override
  String get report_reason_other => 'Other';

  @override
  String get block_user_title => 'Block User';

  @override
  String get block_user_desc =>
      'Block this user? Their posts and comments will be hidden.';

  @override
  String get msg_report_submitted => 'Report submitted';

  @override
  String get msg_block_done => 'Blocked';

  @override
  String get circle_title_feed => 'Feed';

  @override
  String get circle_no_posts => 'No posts to show';

  @override
  String get circle_label_text_only => 'Text';

  @override
  String get circle_msg_load_error => 'Failed to load feed';

  @override
  String get circle_btn_see_all => 'View All';

  @override
  String get post_write_title => 'Share to Circle';

  @override
  String get post_edit_title => 'Edit Post';

  @override
  String get post_hint_content => 'What\'s on your mind?';

  @override
  String get post_hint_from_mylog => 'Refine and share your My Log';

  @override
  String get post_btn_submit => 'Post';

  @override
  String get post_btn_update => 'Update';

  @override
  String get post_add_photo => 'Add Photo';

  @override
  String get post_change_photo => 'Change';

  @override
  String get post_delete_confirm_title => 'Confirm Delete';

  @override
  String get post_delete_confirm_msg => 'Do you want to delete this post?';

  @override
  String get post_msg_upload_fail => 'Upload failed';

  @override
  String get post_msg_need_content => 'Please add content or a photo';

  @override
  String get ugc_gate_title => 'Community Agreement Required';

  @override
  String get ugc_gate_btn_accept => 'Agree and Start';

  @override
  String get comm_online_empty => 'No users online';

  @override
  String get comm_main_grid_title => 'Training · Arena · Log';

  @override
  String get comm_menu_training => 'Training';

  @override
  String get comm_menu_arena => 'Arena';

  @override
  String get comm_menu_mylog => 'My Log';

  @override
  String get comm_tab_recent => 'Recent';

  @override
  String get comm_tab_popular => 'Popular';

  @override
  String get comm_summary_title => 'Today\'s Community';

  @override
  String get comm_stat_posts => 'Posts';

  @override
  String get comm_stat_comments => 'Comments';

  @override
  String get comm_stat_likes => 'Likes';

  @override
  String get comm_live_posts => 'Live Posts';

  @override
  String get auth_login_needed => 'Login required for community';

  @override
  String get auth_verify_needed => 'Verification required';

  @override
  String get auth_profile_incomplete => 'Please complete your profile.';

  @override
  String get auth_phone_incomplete => 'Please verify your phone number.';

  @override
  String get comm_btn_agree_start => 'Agree and Start';

  @override
  String get home_title_news => 'Latest News';

  @override
  String get home_title_event => 'Next Events';

  @override
  String get home_title_ranking => 'Steel League Points';

  @override
  String get home_title_photos => 'Competition Photos';

  @override
  String get home_title_sponsor => 'Sponsors';

  @override
  String get home_btn_see_all => 'View All';

  @override
  String get home_btn_shortcut => 'Go';

  @override
  String get home_training_title => 'DAO Training';

  @override
  String home_training_gauge(Object percent) {
    return 'Growth Gauge $percent%';
  }

  @override
  String home_training_prompt(Object tier) {
    return '$tier Tier, shall we practice today?';
  }

  @override
  String get home_training_no_tier =>
      'Register your tier and DAO will recommend drills.';

  @override
  String get home_training_check_tier => 'Check My Tier';

  @override
  String get home_training_empty => 'No training records yet.';

  @override
  String get day_mon => 'Mon';

  @override
  String get day_tue => 'Tue';

  @override
  String get day_wed => 'Wed';

  @override
  String get day_thu => 'Thu';

  @override
  String get day_fri => 'Fri';

  @override
  String get day_sat => 'Sat';

  @override
  String get day_sun => 'Sun';

  @override
  String get login_slogan => 'Every Point Is Your Story';

  @override
  String get login_btn_google => 'Sign in with Google';

  @override
  String get login_btn_apple => 'Sign in with Apple';

  @override
  String get login_btn_skip => 'Skip';

  @override
  String get login_admin_toggle => 'Admin Login';

  @override
  String get login_admin_notice =>
      'This method is for admin and review accounts only.';

  @override
  String get login_msg_fail_email => 'Email login failed.';

  @override
  String get mylog_title => 'My Log';

  @override
  String get mylog_summary_title => 'My Dart Story';

  @override
  String mylog_summary_count(Object count) {
    return '$count records saved.';
  }

  @override
  String get mylog_stat_streak => 'Streak';

  @override
  String get mylog_stat_first => 'First Log';

  @override
  String get mylog_stat_latest => 'Latest Log';

  @override
  String get mylog_calendar_hint =>
      'Tap a date to write a diary or view records.';

  @override
  String get mylog_write_new => 'New My Log';

  @override
  String get mylog_write_edit => 'Edit My Log';

  @override
  String get mylog_add_photo => 'Add Photo (Optional)';

  @override
  String get mylog_template_good => 'Successes 💪';

  @override
  String get mylog_template_bad => 'Improvements 🧐';

  @override
  String get mylog_template_plan => 'Next Plan ✏️';

  @override
  String get mylog_share_circle => 'Share to Circle';

  @override
  String get mylog_msg_save_done => 'Log saved!';

  @override
  String get auth_phone_hint => 'Enter your phone number';

  @override
  String get auth_code_sent => 'Verification code sent';

  @override
  String get auth_code_expired => 'Code expired. Please request again';

  @override
  String get auth_code_invalid => 'Enter 6-digit verification code';

  @override
  String get auth_verify_success => 'Phone number verified successfully!';

  @override
  String get auth_verify_fail => 'Verification failed';

  @override
  String get profile_msg_saving => 'Saving... please wait.';

  @override
  String get profile_save_success => 'Profile saved successfully.';

  @override
  String get profile_img_delete_title => 'Delete Photo';

  @override
  String get profile_img_delete_msg =>
      'Are you sure you want to delete this photo?';

  @override
  String get profile_err_input => 'Please check your input.';

  @override
  String get profile_err_phone_first =>
      'Please verify your phone number first!';

  @override
  String get profile_none => 'No Profile';

  @override
  String get profile_incomplete => 'Incomplete';

  @override
  String get profile_no_name => 'No Name';

  @override
  String get profile_no_content => 'No content.';

  @override
  String get profile_label_ko_name => 'Name (Local)';

  @override
  String get profile_label_en_name => 'Name (English)';

  @override
  String get profile_label_shop => 'Home Shop';

  @override
  String get profile_err_ko_name => 'Please enter local name';

  @override
  String get profile_err_en_name => 'Please enter English name';

  @override
  String get profile_err_shop => 'Please enter shop name';

  @override
  String get gear_title_section => 'Barrel Setup (Optional)';

  @override
  String get gear_player_equipment => 'Player Equipment';

  @override
  String get gear_label_barrel => 'Barrel';

  @override
  String get gear_label_shaft => 'Shaft';

  @override
  String get gear_label_flight => 'Flight';

  @override
  String get gear_label_tip => 'Tip';

  @override
  String get auth_btn_change => 'Change';

  @override
  String get auth_btn_cancel => 'Cancel';

  @override
  String get auth_hint_code => '6-digit code';

  @override
  String get guest_title_edit => 'Edit Guestbook';

  @override
  String get guest_hint_input => 'Enter content to edit...';

  @override
  String get guest_btn_complete => 'Done';

  @override
  String get guest_msg_delete_confirm => 'Delete this guestbook entry?';

  @override
  String get mypage_login_prompt => 'Log in to check your profile!';

  @override
  String get mypage_profile_needed => 'Profile registration required!';

  @override
  String get mypage_btn_register => 'Register';

  @override
  String get mypage_btn_edit => 'Edit';

  @override
  String get mypage_label_email => 'No Email';

  @override
  String get mypage_btn_logout => 'Log Out';

  @override
  String get mypage_btn_delete_acc => 'Delete Account';

  @override
  String get guest_title_my => 'My Guestbook';

  @override
  String get guest_title_write => 'Write Guestbook';

  @override
  String get guest_hint_cheer => 'Leave a message...';

  @override
  String get guest_msg_success => 'Message posted!';

  @override
  String get notice_title => 'Notices';

  @override
  String get notice_empty => 'No notices.';

  @override
  String get delete_acc_confirm_title => 'Delete Account';

  @override
  String get delete_acc_confirm_msg =>
      'Deleting your account will remove all data and cannot be undone. Are you sure?';

  @override
  String get report_title => 'Bug Report';

  @override
  String get report_label_title => 'Title';

  @override
  String get report_label_content => 'Details';

  @override
  String get report_hint_content => 'Please describe the situation in detail';

  @override
  String get report_msg_success => 'Report submitted. Thank you!';

  @override
  String get calc_start_prompt => 'Enter starting score';

  @override
  String get calc_btn_start => 'Start';

  @override
  String get calc_remaining_score => 'Remaining';

  @override
  String calc_this_turn(Object score) {
    return 'This Turn: $score';
  }

  @override
  String get calc_rec_route => 'Recommended Route';

  @override
  String get calc_alt_route => 'Alternative Routes:';

  @override
  String get calc_err_range => 'Enter a score between 2 and 170';

  @override
  String get calc_err_overflow => 'Cannot exceed remaining score';

  @override
  String drill_time_format(Object min) {
    return 'Approx. ${min}m';
  }

  @override
  String get drill_progress_title => 'Progress';

  @override
  String get drill_stat_darts => 'Darts';

  @override
  String get drill_stat_rounds => 'Rounds';

  @override
  String get drill_stat_success => 'Success Rate';

  @override
  String drill_stat_darts_count(Object count, Object total) {
    return '$count / $total Darts';
  }

  @override
  String drill_stat_rounds_count(Object count, Object total) {
    return 'ROUND $count / $total';
  }

  @override
  String get drill_panel_target => 'Target';

  @override
  String get drill_guide_hit_miss => 'Press ✅ for Hit / ❌ for Miss';

  @override
  String get drill_btn_success => 'Success';

  @override
  String get drill_btn_fail => 'Fail';

  @override
  String get drill_btn_undo_input => 'Undo Input';

  @override
  String get drill_btn_finish_save => 'Finish and Save';

  @override
  String get drill_unit_marks => 'Marks';

  @override
  String get drill_unit_points => 'pts';

  @override
  String drill_confirm_round(Object unit, Object val) {
    return 'Confirm Round ($val $unit)';
  }

  @override
  String get drill_btn_undo_round => 'Undo Round';

  @override
  String drill_hint_range(Object max, Object min, Object unit) {
    return '$min ~ $max $unit';
  }

  @override
  String drill_around_title(Object count, Object total) {
    return 'Around Board: $count / $total';
  }

  @override
  String drill_bull_title(Object count) {
    return 'Bull $count Darts – SBull / DBull Track';
  }

  @override
  String get drill_msg_limit_reached => 'All darts used.';

  @override
  String get drill_msg_no_undo => 'No history to undo.';

  @override
  String drill_label_set_count(Object current, Object total) {
    return 'Set $current / $total';
  }

  @override
  String get drill_hint_score_input => 'Enter score';

  @override
  String drill_target_bull(Object count, Object total) {
    return 'Target Bulls: $count / $total';
  }

  @override
  String get drill_btn_undo_last => 'Undo Last';

  @override
  String get drill_stat_bull_rate => 'Bull Rate';

  @override
  String get drill_label_single => 'Single';

  @override
  String get drill_label_double => 'Double';

  @override
  String get drill_confirm_score => 'Confirm Score';

  @override
  String get drill_undo_round => 'Undo Last Round';

  @override
  String get drill_undo_input => 'Undo Last Input';

  @override
  String get drill_check_result => 'View Results';

  @override
  String drill_current_score(Object score) {
    return 'Total: $score pts';
  }

  @override
  String get drill_clock_title => 'Double Clock';

  @override
  String get drill_clock_back => '(Back Half)';

  @override
  String get drill_cricket_8r_title => 'Cricket 8R Training';

  @override
  String get drill_cricket_free => 'Free Choice';

  @override
  String get drill_cricket_select_hint => 'Select a free round target';

  @override
  String get drill_quadrant_title => 'Area Practice';

  @override
  String get drill_quadrant_guide => 'Focus on the highlighted area!';

  @override
  String drill_t20_focus_title(Object target) {
    return '$target Focus';
  }

  @override
  String get drill_top_half => 'Top Area Focus';

  @override
  String get drill_bottom_half => 'Bottom Area Focus';

  @override
  String get drill_hint_round_score => 'Round score (0–180)';

  @override
  String get drill_err_only_number => 'Numbers only.';

  @override
  String get drill_err_score_range => 'Out of range.';

  @override
  String get drill_msg_all_used => 'All darts used.';

  @override
  String get result_title => 'Drill Results';

  @override
  String get result_xp_title => 'Session XP';

  @override
  String get result_xp_desc => 'XP earned from this session.';

  @override
  String get result_summary_title => 'Session Summary';

  @override
  String get result_stat_attempts => 'Total Attempts';

  @override
  String get result_stat_duration => 'Duration';

  @override
  String get result_growth_point => 'Growth Points';

  @override
  String get result_time_min => 'min';

  @override
  String get result_time_sec => 'sec';

  @override
  String get finish_btn_success_1 => '1 Dart Success';

  @override
  String get finish_btn_success_2 => '2 Darts Success';

  @override
  String get finish_btn_success_3 => '3 Darts Success';

  @override
  String get finish_btn_fail_prob => 'Fail';

  @override
  String get finish_remaining_title => 'Remaining Score';

  @override
  String get finish_this_turn => 'This Turn';

  @override
  String get rank_mini_title => 'Monthly Ranking';

  @override
  String get rank_stat_score => 'Score';

  @override
  String get rank_stat_optimal => 'Optimal';

  @override
  String get rank_stat_route => 'Correct';

  @override
  String get record_none_start => 'No records. Start now!';

  @override
  String get record_login_needed => 'Login Required';

  @override
  String get finish_home_title => 'Finish Route Practice';

  @override
  String get finish_promo_title => 'Random 10 Finish Problems';

  @override
  String get finish_promo_desc =>
      'Touch the board to reach 0. Must finish with Double or Bull.';

  @override
  String get finish_btn_start => 'Start Practice';

  @override
  String get finish_btn_login_start => 'Login to Start';

  @override
  String get finish_msg_login_rank => 'Login to join rankings';

  @override
  String get finish_hint_title => 'Recommended Route';

  @override
  String get finish_msg_touch_board => 'Tap the dartboard to input';

  @override
  String get finish_msg_bust_guide => 'BUST! Press \'Confirm\' for next';

  @override
  String get finish_msg_done_guide => 'CHECKOUT! Next';

  @override
  String finish_msg_optimal_pace(Object count) {
    return 'Optimal! $count-dart pace';
  }

  @override
  String get finish_result_title => 'Practice Results';

  @override
  String get finish_stat_total_time => 'Total Time';

  @override
  String get finish_stat_avg_darts => 'Avg Darts';

  @override
  String get finish_stat_optimal_rate => 'Optimal Rate';

  @override
  String get finish_stat_route_rate => 'Correct Route Rate';

  @override
  String get finish_msg_optimal_success => 'Shortest success!';

  @override
  String finish_msg_optimal_hint(Object count) {
    return 'Success! (Shortest: $count)';
  }

  @override
  String get grip_metric_pinch => 'Pinch';

  @override
  String get grip_metric_flexion => 'Finger Flexion';

  @override
  String grip_save_date(Object date) {
    return 'Saved: $date';
  }

  @override
  String grip_frame_label(Object id) {
    return 'Frame $id';
  }

  @override
  String get grip_img_load_fail => 'Failed to load image';

  @override
  String grip_cam_unsupported(Object platform) {
    return 'Grip camera is not supported on: $platform';
  }

  @override
  String get grip_label_tight => 'Tight';

  @override
  String get grip_label_wide => 'Wide';

  @override
  String get grip_label_extended => 'Extended';

  @override
  String get grip_label_curved => 'Curved';

  @override
  String get grip_home_title => 'Grip Lab';

  @override
  String get grip_home_desc => 'Save your best grip and check it every day.';

  @override
  String get grip_status_exists => 'Baseline grip saved.';

  @override
  String get grip_status_empty => 'No baseline yet.';

  @override
  String get grip_btn_compare => 'Compare & Correct';

  @override
  String get grip_btn_take_new => 'Take New';

  @override
  String get grip_guide_title => 'Grip Filming Guide';

  @override
  String get grip_guide_desc =>
      'Please check the following for accurate analysis.';

  @override
  String get grip_guide_good => 'Good: Recommended';

  @override
  String get grip_guide_bad => 'Bad: Avoid';

  @override
  String get grip_cam_hint => 'Align fingertips to + center and check level';

  @override
  String get grip_msg_hand_detect => 'Waiting for hand detection...';

  @override
  String grip_msg_stabilizing(Object sec) {
    return 'Stabilizing... ${sec}s';
  }

  @override
  String get grip_report_title => 'Grip Analysis Report';

  @override
  String get grip_ai_result => 'AI Analysis Result';

  @override
  String get grip_metric_middle => 'Middle Angle';

  @override
  String get grip_metric_ring => 'Ring Flexion';

  @override
  String get grip_metric_pinky => 'Pinky Balance';

  @override
  String get grip_msg_mirror => '左右反転 (ミラーモード)';

  @override
  String get hist_title => 'Training History';

  @override
  String get hist_chart_title => 'Growth Trend (Last 7 Days)';

  @override
  String get hist_chart_goal => 'Target Hit Rate 70%';

  @override
  String get hist_tab_trend => 'Trend';

  @override
  String get hist_tab_list => 'List';

  @override
  String get hist_filter_all => 'All';

  @override
  String hist_filter_cycle(Object n) {
    return 'Cycle $n';
  }

  @override
  String get hist_tip_delete => 'Tip: Long press to delete a record.';

  @override
  String get stat_avg_hitrate => 'Avg Hit Rate';

  @override
  String get stat_max_ppd => 'Max PPD';

  @override
  String get stat_total_time => 'Total Time';

  @override
  String get stat_success_attempt => 'Success / Attempts';

  @override
  String get detail_meta_id => 'Drill ID';

  @override
  String get detail_growth_gauge => 'Growth Gauge';

  @override
  String get detail_msg_no_record => 'No records yet.';

  @override
  String get ai_summary_improved => 'Better than last time!';

  @override
  String get ai_summary_stable => 'Stable pace maintained.';

  @override
  String get ai_summary_first => 'Growth chart will be created.';

  @override
  String get pose_guide_title => 'Filming Guide';

  @override
  String get pose_guide_desc =>
      'Please check the following for accurate analysis.';

  @override
  String get pose_setting_title => 'Analysis Settings';

  @override
  String get pose_change_video => 'Change Video';

  @override
  String get pose_tip_title => 'Analysis Tips';

  @override
  String get pose_select_part => 'Select Parts';

  @override
  String get pose_skeleton_color => 'Skeleton Color';

  @override
  String get pose_btn_start => 'Start Analysis';

  @override
  String get pose_msg_analyzing => 'Analyzing pose...';

  @override
  String pose_msg_elapsed(Object sec) {
    return 'Elapsed: ${sec}s';
  }

  @override
  String get pose_msg_ai_frame => 'AI is analyzing the video frame by frame.';

  @override
  String get pose_msg_rendering => 'Generating video...';

  @override
  String get pose_step_extract => 'Extracting frames...';

  @override
  String get pose_step_skeleton => 'Analyzing skeleton...';

  @override
  String get pose_step_encoding => 'Encoding video...';

  @override
  String get pose_result_title => 'Analysis Result';

  @override
  String get pose_guide_line => 'Reference Line';

  @override
  String get pose_show_track => 'Show Path';

  @override
  String get pose_show_release => 'Show Release Point';

  @override
  String get pose_ai_title => 'AI Pose Analysis Result';

  @override
  String get pose_dist_notice => 'Comparing fingertip gaps.';

  @override
  String get pose_btn_save => 'Save Video';

  @override
  String get pose_main_title => 'Analyze Your Throw.';

  @override
  String get pose_main_headline => 'Analyze your throw.';

  @override
  String get pose_main_desc =>
      'Upload a video to track your skeleton and trajectory.';

  @override
  String get pose_btn_select_video => 'Select Video';

  @override
  String get pose_feat_skeleton_title => 'Skeleton Analysis';

  @override
  String get pose_feat_skeleton_desc =>
      'Visualizes movements of shoulders, elbows, and wrists.';

  @override
  String get pose_feat_track_title => 'Wrist Path Tracking';

  @override
  String get pose_feat_track_desc =>
      'Draws the movement of the wrist at release.';

  @override
  String get pose_feat_diag_title => 'Precision Diagnosis';

  @override
  String get pose_feat_diag_desc => 'Check subtle shakes with 30FPS analysis.';

  @override
  String get pose_label_set => 'SET';

  @override
  String pose_label_release(Object n) {
    return 'Release $n';
  }

  @override
  String get report_header => 'DAO Training Report';

  @override
  String report_this_result(Object metric) {
    return 'Current Result ($metric)';
  }

  @override
  String report_prev_best(Object metric) {
    return 'Prev. Best ($metric)';
  }

  @override
  String get report_xp_earned => 'XP Earned This Session';

  @override
  String report_goal_standard(Object xp) {
    return 'Target: $xp XP';
  }

  @override
  String get report_gauge_max => 'Gauge MAX! Re-evaluation time.';

  @override
  String get tier_test_title => 'Board Mapping Level Test';

  @override
  String get tier_test_desc =>
      'Hit the numbers from 1 to 20 in order,\nand enter the total number of darts used.';

  @override
  String get tier_test_input_label => 'Total Darts Used';

  @override
  String get tier_test_btn_confirm => 'Confirm DAO Tier';

  @override
  String get tier_test_err_too_many =>
      'That\'s a lot of darts. Please check again';

  @override
  String get tier_predict_label => 'Predicted DAO Tier';

  @override
  String get drill_rec_start => 'Start';

  @override
  String get drill_rec_done => 'Done Today';

  @override
  String get drill_stat_hit_count => 'Hits';

  @override
  String get train_home_title => 'Training';

  @override
  String train_current_tier(Object tier) {
    return 'Current Tier: $tier';
  }

  @override
  String get train_btn_edit_rating => 'Edit Rating';

  @override
  String get train_btn_reset => 'Reset';

  @override
  String get train_msg_gauge_full => '🔥 Growth Gauge 100%!';

  @override
  String get train_msg_gauge_desc => 'Ready to re-evaluate your skill?';

  @override
  String get train_msg_rating_notice =>
      '※ Values may differ slightly from actual machine ratings.';

  @override
  String get rating_input_title => 'Skill Input';

  @override
  String get rating_tab_phoenix => 'PHOENIX';

  @override
  String get rating_tab_live => 'DARTSLIVE';

  @override
  String get rating_guide_desc =>
      'It\'s most accurate to enter both PPD and MPR.\nEntering just one will calculate an estimate.';

  @override
  String get rating_preview_title => 'Real-time Calculation';

  @override
  String get rating_msg_min_input => 'Please enter at least one value.';

  @override
  String get train_rec_title => 'Recommended';

  @override
  String get train_rec_desc => 'Warm up with drills suited for your rank.';

  @override
  String get train_tools_title => 'Tools';

  @override
  String get train_tool_pose => 'Pose Analysis';

  @override
  String get train_tool_grip => 'Grip Lab';

  @override
  String get train_tool_mylog => 'My Log';

  @override
  String get admin_delete_title => 'Confirm Delete';

  @override
  String get admin_delete_msg => 'Are you sure? This cannot be undone.';

  @override
  String get admin_mode_label => 'Admin Mode';

  @override
  String get ad_status_loading => 'Loading ads...';

  @override
  String get ad_status_ready => 'Ad Ready';

  @override
  String get profile_go_guestbook => 'Go to My Guestbook';

  @override
  String get profile_write_guestbook => 'Write Guestbook';

  @override
  String get svc_msg_save_gal => 'Saved to gallery';

  @override
  String get svc_msg_no_gal_perm => 'Permission denied';

  @override
  String get svc_msg_upload_fail => 'Upload failed';

  @override
  String get svc_msg_rendering_prep => 'Preparing analysis...';

  @override
  String get svc_msg_save_complete => 'Saved!';

  @override
  String get status_online_none => 'Unknown User';

  @override
  String get status_ad_suspended => 'Ads Disabled';

  @override
  String get ui_btn_later => 'Later';

  @override
  String get ui_label_participants => 'Participants';

  @override
  String get ui_msg_init_ad => 'Initializing AdMob';

  @override
  String get home_welcome_msg => 'Welcome to DAO!';

  @override
  String get home_title_magazine_ko => 'Dart News (KO)';

  @override
  String get home_title_magazine_global => 'Global Dart News';

  @override
  String get home_title_official_calendar => 'Official Calendar';

  @override
  String get home_msg_no_calendar => 'No events registered.';

  @override
  String get home_language_setting => 'Language Setting';

  @override
  String get home_msg_lang_changing => 'Changing to...';

  @override
  String get home_msg_profile_needed => 'Register after logging in.';

  @override
  String get home_msg_profile_register => 'Register Profile!';

  @override
  String get effect_congrats_title => 'Congratulations!';

  @override
  String get effect_perfect_score => 'Perfect record! 🎯';

  @override
  String get effect_new_record => 'New Personal Best! 🎉';

  @override
  String get effect_cycle_complete => '1 Cycle completed.';

  @override
  String get effect_epic_success => 'Epic Success! 🎆';

  @override
  String get effect_tier_up => 'Tier Up! Congrats!';

  @override
  String get effect_master_clear => 'Master level cleared!';

  @override
  String get effect_legendary_darts => 'You are a Legend! 🎯';

  @override
  String get effect_hit_perfect => 'Perfect!';

  @override
  String get effect_hit_nice => 'Nice Shot!';

  @override
  String get effect_hit_cool => 'Excellent!';

  @override
  String effect_hit_combo(Object count) {
    return '$count Combo!';
  }

  @override
  String get program_title_program_beginner_4w =>
      'Beginner 4-Week Basic Program';

  @override
  String get program_desc_program_beginner_4w =>
      'Focus on 4 quadrants, top/bottom splits, around board, and basic Count-Ups.';

  @override
  String get program_title_program_learner_4w =>
      'Learner 4-Week Control Program';

  @override
  String get program_desc_program_learner_4w =>
      'Enhance S20 hit rate and top/bottom control to build your scoring base.';

  @override
  String get drill_title_beginner_quadrant_basic => 'Basic Quadrant Feel';

  @override
  String get drill_desc_beginner_quadrant_basic =>
      'Intro drill using 4 zones to build direction and distance feel.';

  @override
  String get drill_target_beginner_quadrant_basic => 'TR / BR / BL / TL';

  @override
  String get drill_guide_beginner_quadrant_basic =>
      'Throw 15 darts at each specified area.';

  @override
  String get drill_title_beginner_top_bottom_basic => 'Learn Top/Bottom Zones';

  @override
  String get drill_desc_beginner_top_bottom_basic =>
      'Target large top/bottom zones to develop direction feel.';

  @override
  String get drill_target_beginner_top_bottom_basic => 'Top / Bottom';

  @override
  String get drill_guide_beginner_top_bottom_basic =>
      'Throw 30 darts at each zone to get the feel.';

  @override
  String get drill_title_beginner_around_board_single => 'Around the Board';

  @override
  String get drill_desc_beginner_around_board_single =>
      'Basic drill hitting singles 1–20 and SB in order.';

  @override
  String get drill_target_beginner_around_board_single => '1~20 + SB';

  @override
  String get drill_guide_beginner_around_board_single =>
      'Hit in order and reduce the darts needed to finish.';

  @override
  String get drill_title_beginner_large_single_20 => 'Large Single 20 Intro';

  @override
  String get drill_desc_beginner_large_single_20 =>
      'Intro scoring drill focusing on hitting the large S20 zone.';

  @override
  String get drill_target_beginner_large_single_20 => 'S20 (Single 20)';

  @override
  String get drill_guide_beginner_large_single_20 =>
      'Throw 60 darts at S20 aiming for 50%+ accuracy.';

  @override
  String get drill_title_beginner_big_bull => 'Big Bull Feel';

  @override
  String get drill_desc_beginner_big_bull =>
      'Build grouping feel aiming at the whole Bull ring.';

  @override
  String get drill_target_beginner_big_bull => 'Whole Bull 60 Darts';

  @override
  String get drill_guide_beginner_big_bull =>
      'Focus on grouping at the Bull area (SB or DB).';

  @override
  String get drill_title_beginner_loose_countup_8r => 'Loose Count-Up';

  @override
  String get drill_desc_beginner_loose_countup_8r =>
      'A light 8R Count-Up to experience darts hitting the board.';

  @override
  String get drill_target_beginner_loose_countup_8r => '8R Count-Up';

  @override
  String get drill_guide_beginner_loose_countup_8r =>
      'Relax and finish all 8 rounds focusing on the feel.';

  @override
  String get drill_title_learner_single20_60 => 'Single 20 60 Darts';

  @override
  String get drill_desc_learner_single20_60 =>
      'Enhance precision by throwing 60 darts at S20 at regulation distance.';

  @override
  String get drill_target_learner_single20_60 => 'S20';

  @override
  String get drill_guide_learner_single20_60 =>
      'Aim for 40+ hits out of 60 darts.';

  @override
  String get drill_title_learner_20_19_switch => 'Top 3 Sector Loop (20/19/18)';

  @override
  String get drill_desc_learner_20_19_switch =>
      'Practice switching targets across 20/19/18 to reduce big misses.';

  @override
  String get drill_target_learner_20_19_switch => '20 / 19 / 18';

  @override
  String get drill_guide_learner_20_19_switch =>
      'Learn the rhythm of target switching across 20, 19, and 18.';

  @override
  String get drill_title_comp_triple_20_19_18_line =>
      'Triple Loop (T20/T19/T18)';

  @override
  String get drill_desc_comp_triple_20_19_18_line =>
      'Practice scoring rhythm by looping T20 → T19 → T18.';

  @override
  String get drill_target_comp_triple_20_19_18_line => 'T20 / T19 / T18';

  @override
  String get drill_guide_comp_triple_20_19_18_line =>
      'Stay focused while switching between the key scoring triples.';

  @override
  String get drill_title_comp_checkout_40_80 => '40–80 Essential Double-Outs';

  @override
  String get drill_desc_comp_checkout_40_80 =>
      'Essential practice for finishing scores between 40 and 80 with doubles.';

  @override
  String get drill_target_comp_checkout_40_80 => '40~80 Double-Out';

  @override
  String get drill_guide_comp_checkout_40_80 =>
      'Finish the most common 40–80 range within 3 darts.';

  @override
  String get drill_title_pro_501_standard_18darts => '501 Double-Out 18 Darts';

  @override
  String get drill_desc_pro_501_standard_18darts =>
      'Check if you can finish 501 within 18 darts.';

  @override
  String get drill_target_pro_501_standard_18darts => '501 Double-Out';

  @override
  String get drill_guide_pro_501_standard_18darts =>
      'Play 10 sets and check your 18-dart finish rate.';

  @override
  String get drill_title_master_170_route_focused_30 =>
      '170 Checkout Route Focus';

  @override
  String get drill_desc_master_170_route_focused_30 =>
      'High-finish drill to memorize the T20 → T20 → Bull route.';

  @override
  String get drill_target_master_170_route_focused_30 =>
      '170 (T20 → T20 → Bull)';

  @override
  String get drill_guide_master_170_route_focused_30 =>
      'Repeat the max checkout route for 30 sets.';

  @override
  String get exit_drill_title => 'Exit Drill';

  @override
  String get exit_drill_msg =>
      'Records are not saved. Are you sure you want to exit?';

  @override
  String get drill_msg_bust => 'Bust!';

  @override
  String drill_msg_darts_left(Object count) {
    return '$count darts left';
  }

  @override
  String get drill_category_board_mapping => 'Board Mapping';

  @override
  String get drill_category_double => 'Double Practice';

  @override
  String get profile_reset_title => 'Reset Training Data';

  @override
  String get profile_reset_msg =>
      'This will reset your DAO training rating and tier.\nYou can start over by entering your rating or taking a level test.';

  @override
  String get rating_check_ready_title => '🔥 Growth Gauge 100%!';

  @override
  String get rating_check_ready_msg =>
      'Your growth gauge is full! Shall we re-evaluate your rating to see your progress?';

  @override
  String get drill_current_tier => 'Current DAO Tier';

  @override
  String get btn_edit_rating => 'Edit Rating';

  @override
  String get tab_free_ranking => 'Free Ranking';

  @override
  String get tab_custom_practice => 'Custom Practice';

  @override
  String get section_training_tools => 'Training Tools';

  @override
  String get drill_stat_growth_gauge => 'Growth Gauge';

  @override
  String get msg_rating_check_ready => 'Ready for rating check';

  @override
  String drill_remaining_xp(Object xp) {
    return '$xp XP until re-evaluation';
  }

  @override
  String get msg_input_darts_skill => 'Please enter your darts skill!';

  @override
  String get btn_input_rating => 'Input Rating';

  @override
  String get btn_level_test => 'Level Test';

  @override
  String get msg_no_recommended_drills => 'No recommended drills available.';

  @override
  String get tool_training_history => 'Training History';

  @override
  String get tool_grip_lab => 'Grip Lab';

  @override
  String get tool_pose_analysis => 'Pose Analysis & Tracking';

  @override
  String get tool_checkout_calculator => 'Checkout Calculator';

  @override
  String get tool_my_dart_story => 'My Dart Story';

  @override
  String get common_later => 'Maybe Later';

  @override
  String get common_test => 'Take Test';

  @override
  String get common_reset => 'Reset';

  @override
  String get tier_test_headline => 'Darts Board Mapping Accuracy Test';

  @override
  String get tier_test_guide_title => 'Official DAO Mapping Standards';

  @override
  String get tier_test_input_hint => 'e.g. 28';

  @override
  String get tier_test_result_notice =>
      'The results will be applied to the Training Home immediately';

  @override
  String get tier_test_err_empty => 'Please enter the number of darts';

  @override
  String get tier_test_err_invalid =>
      'Please enter a number greater than or equal to 1';

  @override
  String get drill_active_area => 'Current Target Area';

  @override
  String get area_top_right => 'Top Right';

  @override
  String get area_bottom_right => 'Bottom Right';

  @override
  String get area_bottom_left => 'Bottom Left';

  @override
  String get area_top_left => 'Top Left';

  @override
  String drill_approx_duration(Object min) {
    return 'Approx. $min min';
  }

  @override
  String get drill_stat_total_darts => 'Total Darts';

  @override
  String get drill_stat_hit_rate => 'Hit Rate';

  @override
  String get drill_stat_total_marks => 'Total Marks';

  @override
  String get drill_stat_total_score => 'Total Score';

  @override
  String get btn_close => 'Close';

  @override
  String get btn_go_history => 'History';

  @override
  String get btn_continue_drill => 'Continue Practice';

  @override
  String get btn_rating_check => 'Rating Check';

  @override
  String get report_header_title => 'DAO TRAINING REPORT';

  @override
  String report_current_result(Object label) {
    return 'Current Result ($label)';
  }

  @override
  String report_previous_best(Object label) {
    return 'Previous Best ($label)';
  }

  @override
  String get report_previous_record => 'Previous Record';

  @override
  String get report_first_record_msg => 'This is your first record!';

  @override
  String report_xp_goal_msg(Object goal) {
    return 'Cycle Goal: $goal XP';
  }

  @override
  String get report_growth_gauge => 'Growth Gauge';

  @override
  String get report_gauge_before => 'Before';

  @override
  String get report_gauge_current => 'After';

  @override
  String get report_gauge_max_msg => 'Gauge MAX! Time for a Level Check.';

  @override
  String get report_summary_first_save =>
      'Your first DAO training record has been saved.';

  @override
  String get report_summary_first_max =>
      'First record saved and your Growth Gauge is full!';

  @override
  String report_summary_improved(Object diff, Object label) {
    return 'Your $label increased by $diff compared to before.';
  }

  @override
  String get report_summary_steady =>
      'This session was consistent with your previous performance.';

  @override
  String get report_summary_encouragement =>
      'Result is slightly lower, but your experience is still growing.';

  @override
  String get rank_select_title => 'Select Game Mode';

  @override
  String get rank_501_desc => 'PPD Ranking Challenge (10 Rounds)';

  @override
  String get rank_cricket_desc => 'MPR Ranking Challenge (15 Rounds)';

  @override
  String get rank_countup_desc => 'High Score Challenge (8 Rounds)';

  @override
  String rank_game_round(Object current, Object max) {
    return 'ROUND $current / $max';
  }

  @override
  String get rank_game_left => 'LEFT';

  @override
  String get rank_game_total_score => 'TOTAL SCORE';

  @override
  String get rank_game_target => 'TARGET';

  @override
  String get rank_game_round_score => 'ROUND SCORE';

  @override
  String get rank_game_confirm => 'CONFIRM';

  @override
  String get rank_msg_bust => 'BUST!';

  @override
  String get rank_msg_max_score => 'Maximum is 180.';

  @override
  String get rank_msg_bull_max => 'BULL allows maximum 6 marks.';

  @override
  String get rank_finish_title => 'FINISH! 🎯';

  @override
  String rank_finish_sub(Object score) {
    return 'How many darts for the last $score points?';
  }

  @override
  String rank_darts_count(Object count) {
    return '$count Darts';
  }

  @override
  String get rank_reset_my_title => 'Reset Record';

  @override
  String get rank_reset_admin_title => 'Admin: Delete Record';

  @override
  String get rank_reset_my_msg =>
      'Are you sure you want to reset all your best records for this month?\nYou will be removed from the rankings immediately.';

  @override
  String rank_reset_admin_msg(Object name) {
    return 'Do you suspect fraudulent records for user \'$name\'?\nDelete all ranking records for this user this month?';
  }

  @override
  String get rank_reset_done => 'Record has been successfully deleted.';

  @override
  String get rank_tab_total => 'Total 🔥';

  @override
  String get rank_btn_challenge => 'Challenge Ranking';

  @override
  String get rank_guide_title => '💡 Record Management';

  @override
  String get rank_guide_delete => 'Long press on your record to delete it.';

  @override
  String get rank_guide_warning =>
      'For a fair culture, inappropriate records may be\ndeleted by admins without prior notice.';

  @override
  String get rank_guide_badge =>
      'Badges are awarded based on the Total Ranking,\ncalculated by summing the TOP 10 of each game.';

  @override
  String get rank_no_data => 'No records yet.';

  @override
  String get rank_no_total_data => 'No total ranking data yet.';

  @override
  String get rank_load_failed => 'Failed to load data';

  @override
  String get calendar_title => 'Official Calendar';

  @override
  String calendar_selected_day(Object day, Object month) {
    return 'Schedule for $month/$day';
  }

  @override
  String get calendar_no_event => 'No events scheduled.';

  @override
  String get calendar_delete_title => 'Delete Event';

  @override
  String get calendar_delete_msg =>
      'Are you sure you want to delete this event?';

  @override
  String get calendar_unit_month => '';

  @override
  String get calendar_unit_day => '';

  @override
  String get live_list_title => 'Today\'s Practice Status';

  @override
  String get live_list_empty => 'No practice records for today.';

  @override
  String get live_status_live => 'LIVE';

  @override
  String get live_status_finished => 'FINISHED';

  @override
  String get live_no_shop => 'Unknown Location';

  @override
  String get live_blur_text => '**** · ****';

  @override
  String get live_board_title => 'LIVE Practice';

  @override
  String get live_board_view_all => 'View All';

  @override
  String get live_board_login_invite => 'Login to track your practice time!';

  @override
  String get live_board_start_invite => 'Ready to track your practice?';

  @override
  String get live_board_profile_invite => 'Register profile to track practice!';

  @override
  String get live_board_btn_start => 'Start';

  @override
  String get live_board_btn_stop => 'Stop';

  @override
  String get live_board_btn_profile => 'Register';

  @override
  String live_board_total_count(Object count) {
    return '$count users are practicing now!';
  }

  @override
  String get live_board_no_user => 'No users practicing yet.';

  @override
  String live_board_total_today(Object time) {
    return 'Today\'s Total: $time';
  }

  @override
  String common_hour(Object value) {
    return '${value}h';
  }

  @override
  String common_minute(Object value) {
    return '${value}m';
  }

  @override
  String get login_title => 'Login';

  @override
  String live_total_time(Object time) {
    return 'Total $time';
  }

  @override
  String get practice_setup_title => 'Start Tracking';

  @override
  String get practice_setup_sub =>
      'Set up your environment and start recording.';

  @override
  String get practice_setup_machine => 'Machine Type';

  @override
  String get practice_setup_location => 'Location';

  @override
  String get practice_setup_location_hint => 'e.g. PDK Stadium, Darts Hive';

  @override
  String get practice_setup_goal => 'Today\'s Goal (Optional)';

  @override
  String get practice_setup_goal_hint =>
      'e.g. 100 Bulls, Rating 15, 3h practice';

  @override
  String get practice_setup_btn_start => 'Start Recording';

  @override
  String get practice_setup_error_location =>
      'Please enter the practice location (Shop name).';

  @override
  String practice_setup_error_start(Object error) {
    return 'Start error: $error';
  }

  @override
  String get practice_stop_title => 'Practice Summary';

  @override
  String get practice_stop_sub =>
      'Wrap up today\'s practice and leave a record.';

  @override
  String get practice_stop_total_time => 'Total Practice Time';

  @override
  String get practice_stop_my_goal => 'My Goal';

  @override
  String get practice_stop_feedback_label =>
      'Did you achieve your goal? (Feedback)';

  @override
  String get practice_stop_feedback_hint =>
      'e.g. Completed 100 bulls!, Failed due to fatigue, etc.';

  @override
  String get practice_stop_cheer_msg => 'Great job today!';

  @override
  String get practice_stop_btn_no_save => 'Discard';

  @override
  String get practice_stop_btn_save => 'Save to My Log';

  @override
  String practice_stop_error(Object error) {
    return 'Error during completion: $error';
  }

  @override
  String get history_title => 'Training History';

  @override
  String get history_login_required => 'Login Required';

  @override
  String get history_login_msg =>
      'You need to login to save your\npractice records and track trends.';

  @override
  String get history_profile_required => 'Profile Registration Required';

  @override
  String get history_profile_msg =>
      'To ensure record reliability, only registered\nprofiles can use the history feature.';

  @override
  String get history_no_record => 'No practice records yet.';

  @override
  String get history_no_cycle_record => 'No records in this cycle.';

  @override
  String get history_tab_trend => 'Trend';

  @override
  String get history_tab_list => 'List';

  @override
  String get history_filter_all => 'All';

  @override
  String get history_tip_delete =>
      'Tip: Long press an item to delete a record.';

  @override
  String get history_delete_title => 'Delete Record';

  @override
  String get history_delete_msg =>
      'Are you sure you want to delete this record?\nIt will be permanently removed from the server.';

  @override
  String get history_cycle_delete_title => 'Delete Cycle';

  @override
  String get history_cycle_delete_msg =>
      'Delete all records in this cycle?\nThis cannot be undone.';

  @override
  String get history_stat_avg_hit => 'Avg Hit Rate';

  @override
  String get history_stat_max_hit => 'Max Hit Rate';

  @override
  String get history_date_today => 'Today';

  @override
  String get history_date_yesterday => 'Yesterday';

  @override
  String history_date_days_ago(Object days) {
    return '${days}d ago';
  }

  @override
  String history_cycle_label(Object number) {
    return 'Cycle $number';
  }

  @override
  String get history_initial_record => 'Initial Record';

  @override
  String get detail_title => 'Training Details';

  @override
  String get detail_error_load => 'An error occurred while loading the record.';

  @override
  String get detail_stat_no_record => 'No Record';

  @override
  String get detail_info_title => 'Details';

  @override
  String get detail_info_drill_id => 'Drill ID';

  @override
  String get detail_info_cycle => 'Cycle';

  @override
  String get detail_info_total_attempts => 'Total Attempts';

  @override
  String detail_summary_no_data(Object metric) {
    return 'There\'s not enough $metric data for this session yet.\nChanges will be more visible if you try this drill again.';
  }

  @override
  String detail_summary_first(Object metric) {
    return 'This is your first $metric record.\nGrowth graphs and history will be built based on this value.\n🔥 Today\'s Mission: Try the same drill again to set your benchmark.';
  }

  @override
  String detail_summary_up(Object diff, Object metric) {
    return '$metric +$diff Improved! 🔥\nYou\'ve definitely gotten better than the previous session.\nKeep this tempo and rhythm to aim for a \'Consecutive Rise\'!';
  }

  @override
  String detail_summary_steady(Object metric) {
    return '$metric No significant change.\nThis is a sign that you are finding your \'Average Pace\'.\nTry attempting the drill again with a different routine or breath.';
  }

  @override
  String detail_summary_down(Object diff, Object metric) {
    return '$metric -$diff Decreased.\nHowever, XP and practice volume are still accumulating.\nHow about trying a different drill today and challenging this one again in the next cycle?';
  }

  @override
  String get chart_title => 'Growth Trends (Daily Avg, Last 7 Days)';

  @override
  String get chart_sub =>
      'The graph shows the daily average for the last 7 days.';

  @override
  String get chart_legend_ppd => 'PPD (Scale x2)';

  @override
  String get chart_legend_mpr => 'MPR (Scale x10)';

  @override
  String chart_goal_hit(Object percent) {
    return 'Target Hit Rate $percent%';
  }

  @override
  String get chart_toggle_all => 'All';

  @override
  String get chart_tooltip_hit => 'Hit Rate';

  @override
  String get chart_no_data => 'No data available to display';

  @override
  String get profile_register_btn => 'Register Profile';

  @override
  String get pose_title => 'AI Pose Analysis';

  @override
  String get pose_login_msg =>
      'Login is required to use pose analysis\nand save your records.';

  @override
  String get pose_main_sub =>
      'Upload a video to track your skeleton and trajectory\nfor visual analysis.';

  @override
  String get pose_feature1_title => 'Skeleton Analysis';

  @override
  String get pose_feature1_desc =>
      'Visualizes shoulder, elbow, and wrist movements.';

  @override
  String get pose_feature2_title => 'Wrist Trajectory Tracking';

  @override
  String get pose_feature2_desc =>
      'Draws the wrist path during the release moment.';

  @override
  String get pose_feature3_title => 'Frame-by-Frame Diagnosis';

  @override
  String get pose_feature3_desc =>
      'Check fine tremors with 30FPS high-definition analysis.';

  @override
  String get pose_label_r_wrist => 'Right Wrist';

  @override
  String get pose_label_l_wrist => 'Left Wrist';

  @override
  String get pose_label_r_elbow => 'Right Elbow';

  @override
  String get pose_label_l_elbow => 'Left Elbow';

  @override
  String get pose_label_r_shoulder => 'Right Shoulder';

  @override
  String get pose_label_l_shoulder => 'Left Shoulder';

  @override
  String get pose_result_guide_title => 'Baseline Guide (Elbow/Wrist)';

  @override
  String get pose_result_guide_off => 'Off';

  @override
  String get pose_result_guide_left => 'Left On';

  @override
  String get pose_result_guide_right => 'Right On';

  @override
  String get pose_result_show_track => 'Show Tracking Path';

  @override
  String get pose_result_show_track_sub => 'Display throw trajectory';

  @override
  String get pose_result_show_release => 'Show Release Points';

  @override
  String get pose_result_show_release_sub => 'Mark release moments (dots)';

  @override
  String get pose_result_select_part => 'Select Parts to View';

  @override
  String get pose_result_btn_repick => 'Pick Another Video';

  @override
  String get pose_result_btn_save => 'Save Video';

  @override
  String get pose_render_preparing => 'Preparing analysis...';

  @override
  String get pose_render_extracting => 'Extracting frames...';

  @override
  String get pose_render_analyzing => 'AI skeleton analysis...';

  @override
  String get pose_render_encoding => 'Encoding video...';

  @override
  String get pose_render_complete => 'Save complete!';

  @override
  String get pose_render_dialog_title => 'Generating Video';

  @override
  String get pose_render_save_success => 'Saved to gallery!';

  @override
  String get pose_setting_change_video => 'Change Video';

  @override
  String get pose_setting_tip_title => 'Tips for Accurate Analysis';

  @override
  String get pose_setting_tip1 =>
      '• Recommended video length is around 20-25 seconds.';

  @override
  String get pose_setting_tip2 =>
      '• For best results, film from the side showing your full body and arm.';

  @override
  String get pose_setting_section_part => 'Select Tracking Part';

  @override
  String get pose_setting_section_skeleton => 'Skeleton Color';

  @override
  String get pose_setting_section_line => 'Tracking Line Color';

  @override
  String get pose_setting_btn_start => 'Start Analysis';

  @override
  String get pose_proc_title => 'Analyzing pose...';

  @override
  String pose_proc_time(Object seconds) {
    return 'Elapsed: ${seconds}s';
  }

  @override
  String get pose_proc_ad_loading => 'Loading advertisement...';

  @override
  String get pose_proc_ad_dev => 'MREC Ad Area (Dev)';

  @override
  String get pose_proc_guide =>
      'AI is analyzing the video frame by frame.\nLonger videos may take more time.';

  @override
  String get pose_proc_failed => 'Analysis failed. Please try again.';

  @override
  String get pose_guide_main =>
      'Please check the following\nfor accurate analysis.';

  @override
  String get pose_guide_sub =>
      'The better the AI recognizes the skeleton, the more accurate the results.';

  @override
  String get pose_guide_good_title => 'Good: Recommended Method';

  @override
  String get pose_guide_good_1 =>
      'Video length between 20-25 seconds is best for analysis.';

  @override
  String get pose_guide_good_2 =>
      'Film from a side view (90 degrees) of the user.';

  @override
  String get pose_guide_good_3 =>
      'Capture from head to upper body, pelvis, and knees.';

  @override
  String get pose_guide_good_4 =>
      'Short sleeves are better than long sleeves for joint recognition.';

  @override
  String get pose_guide_good_5 =>
      'Bright areas without strong backlighting are best.';

  @override
  String get pose_guide_bad_title => 'Bad: Methods to Avoid';

  @override
  String get pose_guide_bad_1 =>
      'Too long videos may cause slow analysis or app crashes.';

  @override
  String get pose_guide_bad_2 =>
      'Capturing only the upper body may result in failed tracking.';

  @override
  String get pose_guide_bad_3 =>
      'Front or 45-degree angles are difficult to analyze accurately.';

  @override
  String get pose_guide_bad_4 =>
      'Avoid baggy clothes or accessories that cover the body.';

  @override
  String get pose_guide_bad_5 =>
      'Strong lighting or background movement can cause inaccuracies.';

  @override
  String get pose_guide_btn_confirm => 'Understood (Select Video)';

  @override
  String get grip_title => 'Grip Lab';

  @override
  String get grip_main_title => 'Record & Compare\nYour Grip.';

  @override
  String get grip_main_sub =>
      'There\'s no right answer, but there\'s a \'standard\' for you.\nSave your best grip and match that feeling every day.';

  @override
  String get grip_info1_title => 'Shoot & Save';

  @override
  String get grip_info1_desc =>
      'Track your hand skeleton in real-time.\nSave your favorite grip as the \'Baseline\'.';

  @override
  String get grip_info2_title => 'Compare & Correct';

  @override
  String get grip_info2_desc =>
      'Detect fingers that differ from the baseline and get advice.';

  @override
  String get grip_info3_title => 'Numerical Analysis';

  @override
  String get grip_info3_desc =>
      'Check subtle differences like thumb-index distance\nand finger bend angles with data.';

  @override
  String get grip_status_has => 'A baseline grip is saved.';

  @override
  String get grip_status_no => 'No baseline grip yet.';

  @override
  String get grip_msg_has =>
      'Check the saved data or press the button below to start comparison training.';

  @override
  String get grip_msg_no =>
      'Please press [Shoot] to create your baseline grip first.';

  @override
  String get grip_btn_view_data => 'View Saved Baseline Data';

  @override
  String get grip_btn_new_shoot => 'Shoot New Grip';

  @override
  String get grip_guide_main =>
      'Please check the following\nfor accurate grip analysis.';

  @override
  String get grip_guide_sub =>
      'Clearer finger joints and nail positions lead to more precise analysis.';

  @override
  String get grip_guide_good_title => 'Good: Recommended Method';

  @override
  String get grip_guide_good_1 =>
      'Film the hand holding the dart from a \'perfect side view (90 degrees)\'.';

  @override
  String get grip_guide_good_2 =>
      'Align the overlapping thumb and index finger area with the + point.';

  @override
  String get grip_guide_good_3 =>
      'A clean area without a busy background is best.';

  @override
  String get grip_guide_good_4 =>
      'Adjust the distance so the wrist is also visible in the frame.';

  @override
  String get grip_guide_good_5 =>
      'Film in a brightly lit place to see the finger joints clearly.';

  @override
  String get grip_guide_bad_title => 'Bad: Methods to Avoid';

  @override
  String get grip_guide_bad_1 =>
      'Analyzing finger depth is impossible if filmed from the front.';

  @override
  String get grip_guide_bad_2 =>
      'The fingers should not be completely hidden by the dart barrel.';

  @override
  String get grip_guide_bad_3 =>
      'Avoid places that are too dark or have strong backlighting.';

  @override
  String get grip_guide_bad_4 =>
      'Recognition is difficult if the hand is too small due to the camera being too far.';

  @override
  String get grip_guide_btn_start => 'Understood (Start Filming)';

  @override
  String get grip_auth_camera_title => 'Camera Permission Required';

  @override
  String get grip_auth_camera_msg =>
      'You must allow camera permission in settings to use the grip analysis feature.';

  @override
  String get grip_auth_camera_denied =>
      'Camera permission is required for filming.';

  @override
  String get grip_auth_go_settings => 'Go to Settings';

  @override
  String get grip_comp_title => 'Compare Grip';

  @override
  String get grip_comp_result_title => 'Analysis Result';

  @override
  String get grip_comp_mirror_on => 'Baseline Mirrored (Mirror Mode)';

  @override
  String get grip_comp_mirror_off => 'Baseline Restored';

  @override
  String get grip_comp_retake => 'Retake';

  @override
  String get grip_comp_ai_title => 'AI Grip Analysis Result';

  @override
  String get grip_comp_info_dist =>
      'Distance Standard: Compares the straight-line distance between the tips of the thumb and index finger.';

  @override
  String get grip_comp_no_result => 'No analysis results found.';

  @override
  String get grip_comp_btn_retake => 'Retake Photo';

  @override
  String get grip_comp_live_guide => 'Please show your hand to the camera';

  @override
  String get grip_comp_baseline_label => 'Baseline';

  @override
  String get grip_comp_shoot_guide =>
      'Hold it like the baseline photo\nand align with the + center';

  @override
  String grip_comp_cooldown(Object seconds) {
    return 'Ready in ${seconds}s';
  }

  @override
  String get grip_comp_no_baseline => 'No baseline grip found.';

  @override
  String get grip_comp_btn_go_shoot => 'Go to Shoot';

  @override
  String get grip_cam_checking_auth => 'Checking camera permission...';

  @override
  String get grip_cam_guide_center => 'Align thumb & index with ';

  @override
  String get grip_cam_guide_plus => '+ Center';

  @override
  String get grip_cam_guide_align => '\n';

  @override
  String get grip_cam_guide_horizon => 'Horizontal line ― ';

  @override
  String get grip_cam_guide_desc => 'Check dart angle (level)';

  @override
  String get grip_cam_msg_detected_only =>
      'You can only shoot when a hand is detected.';

  @override
  String get grip_cam_msg_save_success => '✅ Baseline grip saved!';

  @override
  String grip_cam_msg_save_error(Object error) {
    return 'Error during saving: $error';
  }

  @override
  String get grip_report_main_ctrl => 'Main Control';

  @override
  String get grip_report_support => 'Support Fingers';

  @override
  String get grip_report_gap => 'Thumb-Index Gap';

  @override
  String get grip_report_index => 'Index Finger Bend';

  @override
  String get grip_report_middle => 'Middle Finger Angle';

  @override
  String get grip_report_ring => 'Ring Finger Bend';

  @override
  String get grip_report_pinky => 'Pinky Balance';

  @override
  String get grip_report_tight => 'Tight';

  @override
  String get grip_report_wide => 'Wide';

  @override
  String get grip_report_bent => 'Bent';

  @override
  String get grip_report_straight => 'Straight';

  @override
  String get grip_report_deep => 'Deep Grip';

  @override
  String get grip_report_shallow => 'Shallow Grip';

  @override
  String get grip_report_rolled => 'Rolled';

  @override
  String get grip_report_relaxed => 'Relaxed';

  @override
  String get grip_report_inner => 'Inner Support';

  @override
  String get grip_report_outer => 'Outer Support';

  @override
  String get grip_report_zoom => 'Tap to zoom';

  @override
  String get grip_report_delete_confirm => 'Delete Baseline';

  @override
  String get grip_report_delete_msg => 'Are you sure you want to delete this?';

  @override
  String get grip_report_ad_area => 'AdMob Banner Ad Area';

  @override
  String get grip_metric_index_angle => 'Index Angle';

  @override
  String get grip_metric_thumb_dist => 'Thumb Dist';

  @override
  String get grip_metric_stable => 'Stable';

  @override
  String get grip_metric_unstable => 'Unstable';

  @override
  String get grip_metric_gap_diff => 'Diff from Baseline';

  @override
  String get grip_gauge_tight => 'Tight';

  @override
  String get grip_gauge_wide => 'Wide';

  @override
  String get grip_gauge_bent => 'Bent';

  @override
  String get grip_gauge_straight => 'Straight';

  @override
  String get grip_gauge_deep => 'Deep Grip';

  @override
  String get grip_gauge_shallow => 'Shallow Grip';

  @override
  String get grip_preview_load_error => 'Unable to load image';

  @override
  String grip_preview_created_at(Object date) {
    return 'Saved: $date';
  }

  @override
  String grip_preview_frame(Object id) {
    return 'Frame $id';
  }

  @override
  String get history_no_data => 'Unable to load data.';

  @override
  String get calc_start_msg => 'Enter starting score';

  @override
  String get calc_start_hint => '2 ~ 170';

  @override
  String get calc_remain_score => 'Remaining';

  @override
  String calc_current_turn(Object score) {
    return 'Current: $score';
  }

  @override
  String get calc_recommend_title => 'Recommended Checkout';

  @override
  String get calc_error_range => 'Enter a score between 2 and 170';

  @override
  String get calc_error_exceed => 'Cannot exceed remaining score';

  @override
  String get grip_coach_gap_wide =>
      '↔️ [Grip Width] Thumb-Index gap is wider than baseline.';

  @override
  String get grip_coach_gap_tight =>
      '-><- [Grip Width] Thumb-Index gap is tighter than baseline.';

  @override
  String get grip_coach_gap_perfect =>
      '✅ [Grip Width] Perfect gap between thumb and index!';

  @override
  String grip_coach_finger_straight(Object finger) {
    return '☝️ [$finger] Straighter than baseline.';
  }

  @override
  String grip_coach_finger_bent(Object finger) {
    return '✊ [$finger] More bent than baseline.';
  }

  @override
  String get grip_coach_all_perfect =>
      '🎉 Perfect! All fingers match the baseline grip.';

  @override
  String grip_coach_good_job(Object fingers) {
    return '🆗 $fingers shapes match the baseline well.';
  }

  @override
  String get grip_coach_index => 'Index';

  @override
  String get grip_coach_middle => 'Middle';

  @override
  String get grip_coach_ring => 'Ring';

  @override
  String get grip_coach_pinky => 'Pinky';

  @override
  String get arena_title_steel => 'Steel League';

  @override
  String get arena_title_tournament => 'Tournament';

  @override
  String get arena_menu_member => 'KDF Member';

  @override
  String get arena_menu_my => 'My Hosted';

  @override
  String get arena_menu_admin => 'Mail Test';

  @override
  String get arena_preview_open => 'Available Now';

  @override
  String get arena_preview_upcoming => 'Upcoming Events';

  @override
  String get arena_preview_see_all => 'See All';

  @override
  String arena_preview_no_data(Object title) {
    return 'No $title yet';
  }

  @override
  String get arena_preview_closed => 'Closed';

  @override
  String get tournament_home_title => 'Find Tournaments';

  @override
  String get tournament_empty_open =>
      'No tournaments available to join right now.\nWe\'ll notify you when new ones open!';

  @override
  String get tournament_empty_upcoming =>
      'No upcoming tournaments yet.\nStay tuned for exciting events coming soon.';

  @override
  String get tournament_empty_closed => 'No closed tournaments.';

  @override
  String get tournament_empty_default =>
      'No tournaments found.\nHow about hosting your own tournament?';

  @override
  String get entry_list_no_data => 'No participants yet';

  @override
  String get entry_list_not_found => 'Tournament not found.';

  @override
  String get entry_list_manual => 'Manual';

  @override
  String entry_list_team_prefix(Object name) {
    return '[Team] $name';
  }

  @override
  String entry_list_team_leader(Object name) {
    return 'Leader: $name';
  }

  @override
  String get entry_list_paid => 'Paid';

  @override
  String get entry_list_not_paid => 'Unpaid';

  @override
  String entry_list_detail_no(Object order) {
    return 'No.$order';
  }

  @override
  String get entry_list_info_name => 'Name';

  @override
  String get entry_list_info_leader => 'Leader Name';

  @override
  String get entry_list_info_phone => 'Phone';

  @override
  String get entry_list_info_rating => 'Rating';

  @override
  String get entry_list_info_homeshop => 'Home Shop';

  @override
  String get entry_list_qna_title => 'Questionnaire Answers';

  @override
  String get entry_list_member_title => 'Member List & Answers';

  @override
  String entry_list_total_rating(Object rating) {
    return 'Total Team Rating: $rating';
  }

  @override
  String get entry_list_btn_edit => 'Edit Info';

  @override
  String get entry_list_btn_delete => 'Delete Entry';

  @override
  String get entry_list_edit_dialog_title => 'Edit Participant Info';

  @override
  String get entry_list_edit_name_ko => 'Korean Name';

  @override
  String get entry_list_edit_name_en => 'English Name';

  @override
  String get entry_list_edit_phone => 'Phone';

  @override
  String get entry_list_edit_rating => 'Rating (Optional)';

  @override
  String get entry_list_edit_homeshop => 'Home Shop (Optional)';

  @override
  String get entry_list_delete_confirm_title => 'Delete Entry';

  @override
  String entry_list_delete_confirm_msg(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get entry_form_manual_title => 'Add Offline Participant';

  @override
  String get entry_form_manual_banner =>
      'Register external participants with organizer authority.\nEntered info is immediately reflected in the list.';

  @override
  String get entry_form_guide_team => 'Please enter team entry information.';

  @override
  String get entry_form_guide_single =>
      'Please enter individual entry information.';

  @override
  String get entry_form_section_leader => 'Leader Information';

  @override
  String get entry_form_section_my => 'My Information';

  @override
  String get entry_form_section_member => 'Member Information';

  @override
  String get entry_form_field_team_name => 'Team Name';

  @override
  String get entry_form_field_name_ko => 'Name (Korean)';

  @override
  String get entry_form_field_name_en => 'Name (English)';

  @override
  String get entry_form_field_phone => 'Phone';

  @override
  String get entry_form_field_rating => 'Rating';

  @override
  String get entry_form_field_rating_opt => 'Rating (Optional)';

  @override
  String get entry_form_field_homeshop => 'Home Shop (Optional)';

  @override
  String entry_form_field_member_no(Object index) {
    return 'Member $index';
  }

  @override
  String get entry_form_field_required => 'This field is required.';

  @override
  String get entry_form_btn_submit => 'Submit Entry';

  @override
  String get entry_form_btn_manual => 'Complete Manual Registration';

  @override
  String get entry_form_msg_success => 'Entry submitted successfully!';

  @override
  String get entry_form_msg_manual_success => 'Manual registration complete.';

  @override
  String entry_form_msg_fail(Object error) {
    return 'Entry failed: $error';
  }

  @override
  String get entry_form_status_pending => 'Entry Received';

  @override
  String get entry_form_status_paid => 'Payment Confirmed!';

  @override
  String get entry_form_desc_pending =>
      'Your application has been received.\nStatus will change to \'Paid\' once the organizer confirms payment.';

  @override
  String get entry_form_desc_paid =>
      'Payment confirmed.\nSee you at the tournament!';

  @override
  String get entry_form_cancel_title => 'Cancel Entry';

  @override
  String get entry_form_cancel_msg =>
      'Are you sure you want to cancel your entry?';

  @override
  String get entry_form_cancel_confirm => 'Cancel My Entry';

  @override
  String get entry_form_cancel_success => 'Entry has been cancelled.';

  @override
  String get entry_edit_title => 'Edit Entry Info';

  @override
  String get entry_edit_manual_banner =>
      'This is participant info added offline.';

  @override
  String get entry_edit_section_setup => 'Tournament Setup';

  @override
  String get entry_edit_section_leader => 'Leader Information';

  @override
  String get entry_edit_section_leader_qna => 'Leader\'s Individual Answers';

  @override
  String get entry_edit_section_member => 'Edit Member Info & Answers';

  @override
  String get entry_edit_success => 'Entry information has been updated.';

  @override
  String entry_edit_fail(Object error) {
    return 'Update failed: $error';
  }

  @override
  String entry_edit_field_member_no(Object index) {
    return 'Member $index';
  }

  @override
  String get entry_edit_field_member_qna => 'Member\'s Individual Answers';

  @override
  String get tournament_edit_title => 'Edit Tournament';

  @override
  String get tournament_edit_save_success => 'Changes saved successfully.';

  @override
  String get tournament_edit_poster_title => 'Edit Tournament Poster';

  @override
  String get tournament_edit_method_title => 'Tournament Setup';

  @override
  String get tournament_edit_type_single => 'Single';

  @override
  String get tournament_edit_type_team => 'Team';

  @override
  String get tournament_edit_team_size => 'Players per Team (including leader)';

  @override
  String get tournament_edit_basic_title => 'Basic Information';

  @override
  String get tournament_edit_field_title => 'Tournament Title';

  @override
  String get tournament_edit_field_location => 'Location';

  @override
  String get tournament_edit_field_manager => 'Contact Person';

  @override
  String get tournament_edit_field_contact => 'Contact Number';

  @override
  String get tournament_edit_date_title => 'Entry & Schedule Settings';

  @override
  String get tournament_edit_field_fee => 'Entry Fee';

  @override
  String get tournament_edit_field_max => 'Max Capacity';

  @override
  String get tournament_edit_field_unlimited => 'Unlimited';

  @override
  String get tournament_edit_date_event => 'Tournament Date';

  @override
  String get tournament_edit_time_event => 'Tournament Time';

  @override
  String get tournament_edit_date_entry_start => 'Entry Starts';

  @override
  String get tournament_edit_date_entry_end => 'Entry Deadline';

  @override
  String get tournament_edit_desc_title => 'Detailed Description';

  @override
  String get tournament_edit_desc_hint =>
      'Please enter the rules or details of the tournament.';

  @override
  String get tournament_edit_custom_q_title =>
      'Additional Questions (Optional)';

  @override
  String get tournament_edit_custom_q_hint => 'Enter a question and tap add.';

  @override
  String get tournament_edit_co_host_title => 'Add Co-Organizers';

  @override
  String get tournament_edit_co_host_hint => 'Enter email address';

  @override
  String get tournament_edit_time_picker_title => 'Edit Tournament Time';

  @override
  String get tournament_detail_loading_error =>
      'An error occurred while loading data.';

  @override
  String get tournament_detail_not_found =>
      'The tournament does not exist or has been deleted. 😅';

  @override
  String tournament_detail_entry_count(Object current, Object max) {
    return 'Entries $current/$max';
  }

  @override
  String get tournament_detail_info_title => 'Tournament Details';

  @override
  String get tournament_detail_no_desc => 'No detailed information available.';

  @override
  String get tournament_detail_list_title => 'Live Participant List';

  @override
  String get tournament_detail_no_entries => 'No applicants yet.';

  @override
  String get tournament_detail_admin_title => 'Organizer Authority';

  @override
  String get tournament_detail_admin_delete => 'Delete Tournament';

  @override
  String get tournament_detail_admin_delete_msg =>
      'All data, including the participant list and poster, will be permanently deleted. Do you want to proceed?';

  @override
  String get tournament_detail_btn_apply => 'Apply Now';

  @override
  String get tournament_detail_btn_cancel => 'Cancel Application';

  @override
  String get tournament_detail_btn_manual => 'Add Offline Participant';

  @override
  String get tournament_detail_btn_not_period => 'Not in application period';

  @override
  String get tournament_detail_btn_closed => 'Application closed';

  @override
  String get tournament_detail_manage_title => 'Manage Participant';

  @override
  String get tournament_detail_manage_edit => 'Edit Participant Info';

  @override
  String get tournament_detail_manage_pay_on => 'Mark as Paid';

  @override
  String get tournament_detail_manage_pay_off => 'Mark as Unpaid';

  @override
  String get tournament_detail_manage_delete => 'Force Remove Entry';

  @override
  String get tournament_detail_share_title =>
      '[DAO Arena] A new dart tournament is open! 🎯';

  @override
  String tournament_detail_share_info(
      Object date, Object fee, Object location, Object title) {
    return '🏆 Title: $title\n📍 Location: $location\n📅 Date: $date\n💰 Fee: $fee';
  }

  @override
  String get tournament_detail_share_footer =>
      'Check the live list and apply now on the DAO app!';

  @override
  String get debug_title => 'Tournament Debug Tools';

  @override
  String get debug_mail_section_title => 'Send Test Email (Admin Only)';

  @override
  String get debug_mail_guide =>
      '※ Admin UID check in functions/index.js must pass.\n※ Enter the Firestore tournament document ID.';

  @override
  String get debug_mail_field_id => 'Tournament ID';

  @override
  String get debug_mail_field_hint => 'e.g., aBcD1234....';

  @override
  String get debug_mail_btn_send => 'Send Test Email';

  @override
  String get debug_mail_btn_sending => 'Sending...';

  @override
  String get debug_mail_tip_title => 'Tip: How to find Tournament ID';

  @override
  String get debug_mail_tip_desc =>
      '• Firebase Console → Firestore → tournaments collection\n• The Document ID shown at the top is the tournamentId.';

  @override
  String get debug_mail_msg_enter_id => 'Please enter a tournamentId';

  @override
  String get debug_mail_msg_success =>
      '✅ Test email request complete! (Check your inbox/spam)';

  @override
  String debug_mail_msg_functions_error(Object code, Object message) {
    return '❌ Functions Error: $code\n$message';
  }

  @override
  String debug_mail_msg_error(Object error) {
    return '❌ Error: $error';
  }

  @override
  String get tournament_create_title => 'Create Tournament';

  @override
  String get tournament_create_login_title => 'Login Required';

  @override
  String get tournament_create_login_msg =>
      'You need to log in to create a tournament.\nPlease log in and try again.';

  @override
  String get tournament_create_success => 'Tournament created successfully!';

  @override
  String get tournament_create_poster_add => 'Add Tournament Poster';

  @override
  String get tournament_create_team_guide =>
      '※ For Team mode, member info will be required in the entry form.';

  @override
  String get tournament_create_email_guide =>
      '📩 Participant list will be sent to the host\'s email upon deadline.';

  @override
  String get tournament_create_desc_hint =>
      'Enter rules, prizes, match format, etc.';

  @override
  String get tournament_create_custom_q_hint =>
      'e.g., Card ID, Partner\'s Name, etc.';

  @override
  String get tournament_create_btn => 'Create';

  @override
  String get my_tournaments_title => 'My Hosted Tournaments';

  @override
  String get my_tournaments_no_data =>
      'You haven\'t hosted any tournaments yet';

  @override
  String get my_tournaments_no_data_guide =>
      'Create your first tournament right now!';

  @override
  String get my_tournaments_error =>
      'An error occurred while loading tournament information.';

  @override
  String get my_tournaments_btn_create => 'Host a Tournament';

  @override
  String get tournament_filter_all => 'All';

  @override
  String get tournament_filter_open => 'Open';

  @override
  String get tournament_filter_upcoming => 'Upcoming';

  @override
  String get tournament_filter_closed => 'Closed';

  @override
  String get common_free => 'Free';

  @override
  String common_unit_people(Object count) {
    return '$count ppl';
  }

  @override
  String get common_currency_won => 'KRW';

  @override
  String get arena_dday_today => 'Today!';

  @override
  String get arena_capacity_full => 'Full';

  @override
  String get arena_status_open => 'Open';

  @override
  String get arena_status_upcoming => 'Upcoming';

  @override
  String get arena_status_closed => 'Closed';

  @override
  String get arena_status_in_progress => 'In Progress';

  @override
  String get arena_status_finished => 'Finished';

  @override
  String get arena_status_canceled => 'Canceled';

  @override
  String get common_ok => 'OK';

  @override
  String get common_no => 'No';

  @override
  String get common_save => 'Save';

  @override
  String get common_select => 'Select';

  @override
  String get common_people => 'ppl';

  @override
  String get common_admin_authority => 'Admin Authority';

  @override
  String get login_required => 'Login is required.';

  @override
  String get entry_edit_setup => 'Tournament Setup';

  @override
  String get league_schedule_empty_day => 'Please select a date';

  @override
  String get league_schedule_no_events => 'No matches';

  @override
  String league_schedule_match_suffix(Object shop) {
    return '$shop Match';
  }

  @override
  String get league_schedule_status_completed => 'Completed';

  @override
  String get league_schedule_status_ongoing => 'Ongoing';

  @override
  String get league_schedule_status_upcoming => 'Upcoming';

  @override
  String league_schedule_winner(Object name) {
    return 'Winner: $name';
  }

  @override
  String get league_schedule_detail_date => 'Date';

  @override
  String get league_schedule_detail_time => 'Time';

  @override
  String get league_schedule_detail_location => 'Location';

  @override
  String get league_schedule_detail_fee => 'Entry Fee';

  @override
  String get league_schedule_detail_admin => 'Admin';

  @override
  String get league_schedule_detail_contact => 'Contact';

  @override
  String get league_schedule_detail_status => 'Status';

  @override
  String get league_schedule_no_photo => 'No Photo';

  @override
  String get ranking_title => 'Steel League Ranking';

  @override
  String get ranking_filter_title => 'Filters';

  @override
  String get ranking_filter_year => 'Year';

  @override
  String get ranking_filter_season => 'Season';

  @override
  String get ranking_filter_gender => 'Gender';

  @override
  String get ranking_filter_mode => 'Mode';

  @override
  String get ranking_filter_season_total => 'Total';

  @override
  String get ranking_filter_season_1 => 'Season 1';

  @override
  String get ranking_filter_season_2 => 'Season 2';

  @override
  String get ranking_filter_season_3 => 'Season 3';

  @override
  String get ranking_filter_gender_all => 'All';

  @override
  String get ranking_filter_gender_male => 'Male';

  @override
  String get ranking_filter_gender_female => 'Female';

  @override
  String get ranking_filter_mode_total => 'Accumulated';

  @override
  String get ranking_filter_mode_top9 => 'Top 9';

  @override
  String get ranking_no_data =>
      'No ranking data available.\nTry awarding some points!';

  @override
  String get ranking_load_error => 'Error loading rankings';

  @override
  String ranking_total_points(Object points) {
    return 'Total: $points';
  }

  @override
  String get point_calendar_title => 'Steel League Point Calendar';

  @override
  String get point_calendar_search_hint => 'Search name (KO/EN)';

  @override
  String get point_calendar_no_selection => 'Please select a date';

  @override
  String get point_calendar_no_data => 'No point records for this date';

  @override
  String get point_calendar_search_empty => 'No search results';

  @override
  String point_calendar_label_season(Object phase, Object year) {
    return '$year Season $phase';
  }

  @override
  String point_calendar_label_total(Object year) {
    return '$year Total';
  }

  @override
  String get selection_title => 'Selected Players';

  @override
  String get selection_header_title => 'KDF Steel League Selection';

  @override
  String get selection_header_desc =>
      'A total of 8 players (1 male and 1 female per category) will be selected based on Season 1–3 and Total points.';

  @override
  String get selection_label_male => 'Men\'s Rep';

  @override
  String get selection_label_female => 'Women\'s Rep';

  @override
  String get selection_status_empty => 'No players selected yet.';

  @override
  String get selection_status_upcoming => 'To be selected';

  @override
  String get selection_label_season1 => 'Season 1 Rep';

  @override
  String get selection_label_season2 => 'Season 2 Rep';

  @override
  String get selection_label_season3 => 'Season 3 Rep';

  @override
  String get selection_label_total => 'Total Rep';

  @override
  String get selection_sub_total => 'All Seasons Combined';

  @override
  String selection_shop_prefix(Object shop) {
    return 'Shop: $shop';
  }

  @override
  String get member_list_search_hint => 'Search by name or email';

  @override
  String get member_list_no_data => 'No official members registered.';

  @override
  String get member_list_no_name => 'No Name';

  @override
  String get member_list_no_email => 'No Email';
}
