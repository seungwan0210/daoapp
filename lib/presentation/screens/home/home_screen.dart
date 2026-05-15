import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/presentation/providers/home_provider.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/data/models/ranking_user.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';
import 'package:daoapp/core/constants/route_constants.dart';

import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_ranking_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_schedule_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournaments_home_screen.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/pose_analysis_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_lab_home_screen.dart';

import 'package:daoapp/presentation/widgets/ad_banner.dart';
import 'package:daoapp/core/utils/ad_manager.dart';

import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:daoapp/presentation/screens/home/official_calendar_screen.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';
import 'package:daoapp/core/services/google_calendar_service.dart';

import 'package:daoapp/presentation/screens/my_page/my_log/my_log_home_screen.dart';
import 'package:daoapp/presentation/screens/my_page/block_list_screen.dart';
import 'package:daoapp/presentation/screens/my_page/report_form_screen.dart';
import 'package:daoapp/presentation/screens/community/chat/chat_screen.dart';
import 'package:daoapp/presentation/screens/home/widgets/live_practice_board.dart';
import 'package:daoapp/presentation/providers/practice/practice_provider.dart';

import 'package:daoapp/l10n/app_localizations.dart';
import 'package:daoapp/presentation/providers/locale_provider.dart';
import 'package:intl/intl.dart';

class _QuickMenuData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickMenuData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _quickMenuController1 = ScrollController();
  final ScrollController _quickMenuController2 = ScrollController();

  List<Map<String, dynamic>> _cachedGoogleEvents = [];
  bool _isGoogleLoading = true;

  final List<String> _calendarIds = [
    "f9835d9449eb197aa4a28882d6b6b0921047274d9d4b9bb9b472dcbec53255c4@group.calendar.google.com",
    "ab9da573f02ba69a46207d551d3d1e1fc159757ccd90cee2e3804a676914f91c@group.calendar.google.com",
    "c012aafa1e98360bb080db8b43c8b1bc560d61d8c7ed28c076bc80a181af52cc@group.calendar.google.com",
    "39t7lea718pdr5f51sts0ljo8u98pub6@import.calendar.google.com",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rankingProvider.notifier).updateFilters('2026', 'total', 'all');
      _handleAdminCleanup();
      _loadHomeCalendarEvents();
    });
  }

  Future<void> _loadHomeCalendarEvents() async {
    try {
      final events = await sl<GoogleCalendarService>().fetchMergedEvents(_calendarIds, _selectedDate);
      if (mounted) {
        setState(() {
          _cachedGoogleEvents = events;
          _isGoogleLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showLanguageSelector(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text(l10n.home_language_setting, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              _languageTile(context, '한국어', const Locale('ko'), '🇰🇷', l10n),
              _languageTile(context, 'English', const Locale('en'), '🇺🇸', l10n),
              _languageTile(context, '日本語', const Locale('ja'), '🇯🇵', l10n),
              _languageTile(context, '简体中文', const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'), '🇨🇳', l10n),
              _languageTile(context, '繁體中文', const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'), '🇹🇼', l10n),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _languageTile(BuildContext context, String label, Locale locale, String flagEmoji, AppLocalizations l10n) {
    return ListTile(
      leading: Text(flagEmoji, style: const TextStyle(fontSize: 24)),
      title: Text(label),
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        Navigator.pop(context);
        _showTopSnackBar(context, "$label ${l10n.home_msg_lang_changing}");
      },
    );
  }

  void _showTopSnackBar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  Map<String, dynamic> _getEventConfig(String? calendarId, {String? firestoreType}) {
    if (calendarId != null) {
      if (calendarId.contains("f9835d")) return {'color': Colors.red, 'logo': 'phoenix'};
      if (calendarId.contains("ab9da5")) return {'color': Colors.blue, 'logo': 'dartslive'};
      if (calendarId.contains("c012aafa")) return {'color': Colors.yellow[700], 'logo': 'pdc'};
      if (calendarId.contains("39t7lea")) return {'color': Colors.greenAccent[700], 'logo': 'wdf'};
    }
    switch (firestoreType) {
      case 'domestic': return {'color': Colors.blue, 'logo': 'league'};
      case 'overseas': return {'color': Colors.yellow[700], 'logo': 'pdc'};
      case 'league': return {'color': Colors.greenAccent[700], 'logo': 'league'};
      default: return {'color': Colors.grey, 'logo': 'none'};
    }
  }

  String _getDDayString(Map<String, dynamic> data) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String content = data['content'] ?? '';

    if (data['targetDate'] != null) {
      final target = (data['targetDate'] as Timestamp).toDate();
      final targetDay = DateTime(target.year, target.month, target.day);
      final diff = targetDay.difference(today).inDays;

      if (diff == 0) content = "🔥 [오늘 개최] $content";
      else if (diff > 0) content = "🏆 [D-$diff] $content";
    }

    if (data['entryDeadline'] != null) {
      final deadline = (data['entryDeadline'] as Timestamp).toDate();
      final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
      final diff = deadlineDay.difference(today).inDays;

      if (diff == 0) content = "$content ⏰ [오늘 마감!]";
      else if (diff == 1) content = "$content ⏰ [내일 마감]";
    }

    return content;
  }

  List<_QuickMenuData> _getGroup1(BuildContext context, AppLocalizations l10n) => [
    _QuickMenuData(icon: Icons.stadium_outlined, label: l10n.menu_quick_arena, color: Colors.indigo, onTap: () => MainScreen.changeTab(context, 2)),
    _QuickMenuData(icon: Icons.leaderboard_rounded, label: l10n.menu_quick_league, color: Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SteelLeagueRankingScreen()))),
    _QuickMenuData(icon: Icons.emoji_events_outlined, label: l10n.menu_quick_tournament, color: Colors.cyan, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentsHomeScreen()))),
    _QuickMenuData(icon: Icons.fitness_center_rounded, label: l10n.menu_quick_training, color: Colors.orange, onTap: () => MainScreen.changeTab(context, 1)),
    _QuickMenuData(icon: Icons.accessibility_new_rounded, label: l10n.menu_quick_pose, color: const Color(0xFF1565C0), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoseAnalysisScreen()))),
    _QuickMenuData(icon: Icons.fingerprint_rounded, label: l10n.menu_quick_grip, color: Colors.deepPurple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GripLabHomeScreen()))),
  ];

  List<_QuickMenuData> _getGroup2(BuildContext context, AppLocalizations l10n) => [
    _QuickMenuData(icon: Icons.person_outline_rounded, label: l10n.menu_quick_profile, color: Colors.blueAccent, onTap: () => MainScreen.changeTab(context, 4)),
    _QuickMenuData(icon: Icons.edit_note_rounded, label: l10n.menu_quick_mylog, color: const Color(0xFFFFA000), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLogHomeScreen()))),
    _QuickMenuData(icon: Icons.forum_outlined, label: l10n.menu_quick_livetalk, color: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: const Color(0xFF0F172A), appBar: AppBar(title: Text(l10n.menu_quick_livetalk, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, elevation: 0, centerTitle: true), body: const ChatScreen())))),
    _QuickMenuData(icon: Icons.photo_library_outlined, label: l10n.menu_quick_circle, color: Colors.pinkAccent, onTap: () => Navigator.pushNamed(context, RouteConstants.circle)),
    _QuickMenuData(icon: Icons.person_off_outlined, label: l10n.menu_quick_block, color: const Color(0xFF616161), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockListScreen()))),
    _QuickMenuData(icon: Icons.report_gmailerrorred_rounded, label: l10n.menu_quick_report, color: Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportFormScreen()))),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopProfileSection(context, ref, l10n),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(thickness: 1, color: Color(0xFFEEEEEE))),

          _buildKoreanMagazineSection(context, l10n),
          const SizedBox(height: 24),
          _buildGlobalMagazineSection(context, l10n),
          const SizedBox(height: 16),

          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(thickness: 1, color: Color(0xFFEEEEEE))),

          _buildQuickMenuSlider(_getGroup1(context, l10n), _quickMenuController1),
          const SizedBox(height: 4),
          _buildQuickMenuSlider(_getGroup2(context, l10n), _quickMenuController2),
          const SizedBox(height: 16),

          // 1. 라이브 현황
          const LivePracticeBoard(),
          const SizedBox(height: 24),

          // 2. 퀵 노티스 (라이브 현황 아래로 위치 변경)
          _buildOngoingLeagueBar(),
          const SizedBox(height: 16),

          // 3. 주간 일정 (퀵 노티스 아래로 위치 변경)
          _buildWeeklyTimeline(context, l10n),
          const SizedBox(height: 24),

          AppCard(child: _buildSponsorSection(context, ref, l10n)),
          const SizedBox(height: 20),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AD',
                  style: TextStyle(fontSize: 9, color: Colors.grey[400], letterSpacing: 1.0, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                const AdBanner(key: Key('main_home_ad_banner'), type: AdBannerType.main),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTopProfileSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final user = FirebaseAuth.instance.currentUser;
    final currentLocale = ref.watch(localeProvider);

    String getFlagEmoji(Locale locale) {
      switch (locale.languageCode) {
        case 'en': return '🇺🇸';
        case 'ja': return '🇯🇵';
        case 'zh':
          return (locale.scriptCode == 'Hant') ? '🇹🇼' : '🇨🇳';
        case 'ko':
        default:
          return '🇰🇷';
      }
    }

    Widget languageSelector() => GestureDetector(
        onTap: () => _showLanguageSelector(context, l10n),
        child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Text(getFlagEmoji(currentLocale), style: const TextStyle(fontSize: 18)),
              const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey)
            ])
        )
    );

    if (user == null) {
      return Row(
        children: [
          Expanded(
            child: _buildProfileCardWrapper(
                child: InkWell(
                    onTap: () => Navigator.pushNamed(context, RouteConstants.login),
                    child: Row(children: [
                      const CircleAvatar(radius: 25, child: Icon(Icons.person_outline)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.home_msg_profile_needed, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))
                    ])
                )
            ),
          ),
          const SizedBox(width: 8),
          languageSelector(),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Row(
            children: [
              Expanded(
                child: _buildProfileCardWrapper(
                    child: InkWell(
                        onTap: () => Navigator.pushNamed(context, RouteConstants.profileRegister),
                        child: Row(children: [
                          const CircleAvatar(radius: 25, child: Icon(Icons.person_add)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(l10n.home_msg_profile_register, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))
                        ])
                    )
                ),
              ),
              const SizedBox(width: 8),
              languageSelector(),
            ],
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final totalRanking = ref.watch(totalRankingProvider);
        final rankIndex = totalRanking.indexWhere((item) => item['userId'] == user.uid);
        final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;
        final badgesMap = BadgeUtils.extractBadges(data);
        final adminBadge = BadgeUtils.getLatestAdminBadge(badgesMap);

        return Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            CircleAvatar(radius: 28, backgroundImage: data['profileImageUrl'] != null ? NetworkImage(data['profileImageUrl']) : null, backgroundColor: Colors.grey[200], child: data['profileImageUrl'] == null ? const Icon(Icons.person, color: Colors.grey) : null),
            if (currentRank != null) Positioned(left: -5, top: -5, child: BadgeWidget(rank: currentRank, size: 20)),
            if (adminBadge != null) Positioned(left: currentRank != null ? -18 : -5, top: -5, child: BadgeWidget(badgeKey: adminBadge, size: 20)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${data['koreanName'] ?? l10n.name_no_name}님,", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              Text(l10n.home_welcome_msg, style: const TextStyle(fontSize: 13, color: Colors.grey), overflow: TextOverflow.ellipsis)
            ]),
          ),
          languageSelector(),
        ]);
      },
    );
  }

  Widget _buildKoreanMagazineSection(BuildContext context, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.home_title_magazine_ko, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('magazines').where('category', isEqualTo: 'magazine_ko').where('isActive', isEqualTo: true).orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyMagazineCard("새로운 소식을 준비 중입니다.");
            return CarouselSlider(options: CarouselOptions(height: 110, viewportFraction: 1.0, autoPlay: true, scrollDirection: Axis.vertical), items: snapshot.data!.docs.map((doc) => _buildMagazineItemCard(context, doc.data() as Map<String, dynamic>)).toList());
          }
      )
    ]);
  }

  Widget _buildGlobalMagazineSection(BuildContext context, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.home_title_magazine_global, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('magazines').where('category', isEqualTo: 'magazine_global').where('isActive', isEqualTo: true).orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyMagazineCard("해외 소식을 불러오는 중입니다.");
            return CarouselSlider(options: CarouselOptions(height: 110, viewportFraction: 1.0, autoPlay: true, scrollDirection: Axis.vertical), items: snapshot.data!.docs.map((doc) => _buildMagazineItemCard(context, doc.data() as Map<String, dynamic>)).toList());
          }
      )
    ]);
  }

  Widget _buildWeeklyTimeline(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('official_calendar').snapshots(),
      builder: (context, snapshot) {
        final fDocs = snapshot.data?.docs ?? [];
        final targetDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

        final filteredF = fDocs.where((doc) => _isDateInRange(targetDate, doc['startDate'], doc['endDate'])).toList();
        final filteredG = _cachedGoogleEvents.where((e) {
          final s = e['start']?['dateTime'] ?? e['start']?['date'];
          if (s == null) return false;
          final sDateOrig = DateTime.parse(s).toLocal();
          final sDate = DateTime(sDateOrig.year, sDateOrig.month, sDateOrig.day);
          final ev = e['end']?['dateTime'] ?? e['end']?['date'];
          if (ev != null) {
            final eDateOrig = DateTime.parse(ev).toLocal();
            var eDate = DateTime(eDateOrig.year, eDateOrig.month, eDateOrig.day);
            if (e['start']?['date'] != null) eDate = eDate.subtract(const Duration(days: 1));
            return (sDate.isAtSameMomentAs(eDate)) ? targetDate.isAtSameMomentAs(sDate) : _isDateInSimpleRange(targetDate, sDate, eDate);
          }
          return targetDate.isAtSameMomentAs(sDate);
        }).toList();

        final combinedDailyEvents = [...filteredF, ...filteredG];

        final String dateDisplay = DateFormat.yMMMEd(locale).format(_selectedDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.home_title_official_calendar, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => setState(() => _selectedDate = DateTime.now()),
                        child: Text(
                          dateDisplay,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, RouteConstants.officialCalendar),
                  icon: CircleAvatar(backgroundColor: theme.colorScheme.primary.withOpacity(0.1), child: Icon(Icons.calendar_month, size: 20, color: theme.colorScheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            EasyInfiniteDateTimeLine(
              key: ValueKey("${_selectedDate.year}-${_selectedDate.month}"),
              firstDate: DateTime(_selectedDate.year, _selectedDate.month, 1),
              lastDate: DateTime(_selectedDate.year, _selectedDate.month + 1, 0),
              focusDate: _selectedDate,
              onDateChange: (date) => setState(() => _selectedDate = date),
              showTimelineHeader: false,
              dayProps: const EasyDayProps(height: 75, width: 58),
              itemBuilder: (context, date, isSelected, onTap) {
                final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
                final tDate = DateTime(date.year, date.month, date.day);

                final hasF = fDocs.any((doc) => _isDateInRange(tDate, doc['startDate'], doc['endDate']));
                final gEventsForDay = _cachedGoogleEvents.where((e) {
                  final s = e['start']?['dateTime'] ?? e['start']?['date'];
                  if (s == null) return false;
                  final sDateOrig = DateTime.parse(s).toLocal();
                  final sDate = DateTime(sDateOrig.year, sDateOrig.month, sDateOrig.day);
                  final ev = e['end']?['dateTime'] ?? e['end']?['date'];
                  if (ev != null) {
                    final eDateOrig = DateTime.parse(ev).toLocal();
                    var eDate = DateTime(eDateOrig.year, eDateOrig.month, eDateOrig.day);
                    if (e['start']?['date'] != null) eDate = eDate.subtract(const Duration(days: 1));
                    return sDate.isAtSameMomentAs(eDate) ? tDate.isAtSameMomentAs(sDate) : _isDateInSimpleRange(tDate, sDate, eDate);
                  }
                  return tDate.isAtSameMomentAs(sDate);
                }).toList();

                final List<Color> distinctColors = [];
                if (hasF) distinctColors.add(Colors.blue);
                distinctColors.addAll(gEventsForDay.map((e) => _getEventConfig(e['calendarId'])['color'] as Color).toSet());

                return InkWell(
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: isToday ? Border.all(color: theme.colorScheme.primary, width: 1.5) : Border.all(color: isSelected ? Colors.transparent : Colors.grey[200]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_getWeekday(date.weekday, l10n), style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : (isToday ? theme.colorScheme.primary : Colors.grey[400]))),
                        Text("${date.day}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isToday ? theme.colorScheme.primary : Colors.black87))),
                        const SizedBox(height: 4),
                        if (distinctColors.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: distinctColors.take(4).map((c) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: 6,
                                height: 3,
                                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))
                            )).toList(),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (combinedDailyEvents.isEmpty)
                    Row(children: [
                      Container(width: 3, height: 14, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.home_msg_no_calendar, style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    ])
                  else
                    ...combinedDailyEvents.map((item) {
                      String title = "";
                      String? venue;
                      String? logoKey;
                      Color typeColor = Colors.grey;

                      if (item is QueryDocumentSnapshot) {
                        final data = item.data() as Map<String, dynamic>;
                        title = data['title'] ?? '';
                        venue = data['venue'];
                        logoKey = data['logoKey'];
                        typeColor = _getEventConfig(null, firestoreType: data['type'])['color'];
                      } else {
                        final e = item as Map<String, dynamic>;
                        title = e['summary'] ?? '';
                        venue = e['location'];
                        final config = _getEventConfig(e['calendarId']);
                        typeColor = config['color'];
                        logoKey = config['logo'];
                      }

                      final bool hasVenue = venue != null && venue.trim().isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 4,
                                  height: hasVenue ? 32 : 18,
                                  decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(2))
                              ),
                              const SizedBox(width: 10),
                              _buildLogoIcon(logoKey),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis, maxLines: 1),
                                    if (hasVenue)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(venue!, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis, maxLines: 1),
                                      ),
                                  ],
                                ),
                              ),
                            ]),
                      );
                    }).toList(),
                ],
              ),
            ),
            // 💡 원래 여기서 호출하던 _buildOngoingLeagueBar()를 삭제하고 build 메서드 상단으로 옮겼습니다.
          ],
        );
      },
    );
  }

  Widget _buildSponsorSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final sponsors = ref.watch(sponsorBannerProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.home_title_sponsor, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      sponsors.when(data: (s) => CarouselSlider(options: CarouselOptions(height: 120, autoPlay: true, viewportFraction: 1.0), items: s.docs.map((d) => GestureDetector(onTap: () => _handleActionTap(context, d.data() as Map<String, dynamic>), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network((d.data() as Map<String, dynamic>)['imageUrl'] ?? '', fit: BoxFit.cover)))).toList()), loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())), error: (_, __) => const SizedBox())
    ]);
  }

  String _getWeekday(int weekday, AppLocalizations l10n) {
    return [l10n.day_mon, l10n.day_tue, l10n.day_wed, l10n.day_thu, l10n.day_fri, l10n.day_sat, l10n.day_sun][weekday - 1];
  }

  void _handleAdminCleanup() {
    final user = FirebaseAuth.instance.currentUser;
    const String adminUid = "NanHPgCdsbMCFkHEs7MtxS51OSX2";
    if (user != null && user.uid == adminUid) {
      sl<ArenaRepository>().autoCleanOldTournaments();
    }
  }

  bool _isDateInSimpleRange(DateTime target, DateTime start, DateTime end) {
    return (target.isAtSameMomentAs(start) || target.isAfter(start)) && (target.isAtSameMomentAs(end) || target.isBefore(end));
  }

  bool _isDateInRange(DateTime target, dynamic start, dynamic end) {
    if (start == null || end == null) return false;
    final s = (start as Timestamp).toDate();
    final e = (end as Timestamp).toDate();
    return _isDateInSimpleRange(target, DateTime(s.year, s.month, s.day), DateTime(e.year, e.month, e.day));
  }

  Widget _buildLogoIcon(String? logoKey) {
    if (logoKey == null || logoKey == 'none') return const SizedBox.shrink();
    String assetPath = 'assets/images/logos/$logoKey.png';
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 26, height: 26,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: ClipOval(child: Image.asset(assetPath, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events_outlined, size: 16, color: Colors.grey))),
    );
  }

  Widget _buildQuickMenuSlider(List<_QuickMenuData> items, ScrollController controller) {
    return RawScrollbar(
      controller: controller,
      thumbVisibility: false,
      thickness: 2.5,
      radius: const Radius.circular(10),
      padding: const EdgeInsets.only(left: 0, right: 16),
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(left: 0, right: 16, bottom: 12),
          child: Row(children: items.asMap().entries.map((entry) => Row(children: [if (entry.key > 0) const SizedBox(width: 8), SizedBox(width: 72, child: _QuickMenuItem(data: entry.value))])).toList()),
        ),
      ),
    );
  }

  Widget _buildMagazineItemCard(BuildContext context, Map<String, dynamic> data) {
    final String type = data['actionType'] ?? 'none';
    final String actionUrl = data['actionUrl']?.toString().trim() ?? '';
    return AppCard(margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: InkWell(
      onTap: () async {
        if (type == 'none' || actionUrl.isEmpty) return;
        if (type == 'internal') _navigateToTab(context, actionUrl);
        else if (type == 'link') { String finalUrl = actionUrl.startsWith('http') ? actionUrl : 'https://$actionUrl'; await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication); }
      },
      child: SizedBox(height: 110, child: Row(children: [ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)), child: SizedBox(width: 120, height: 110, child: _buildMagazineImage(data['imageUrl'] ?? ''))), Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(data['content'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis), const Spacer(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(data['category'] == 'magazine_ko' ? "KR Magazine" : "Global News", style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)), Icon(type == 'none' ? Icons.visibility_outlined : Icons.arrow_forward, size: 14, color: type == 'none' ? Colors.grey : Theme.of(context).colorScheme.primary)] )])))])),
    ));
  }

  Widget _buildMagazineImage(String imageUrl) {
    if (imageUrl.isEmpty) return Container(color: Colors.grey[100], child: const Icon(Icons.image_not_supported, color: Colors.grey));
    return imageUrl.startsWith('http') ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder()) : Image.asset(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder());
  }

  Widget _buildPlaceholder() => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image_outlined, color: Colors.grey));

  Widget _buildOngoingLeagueBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quick_notices').where('endDate', isGreaterThanOrEqualTo: Timestamp.now()).orderBy('endDate').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: CarouselSlider(
            options: CarouselOptions(height: 40, viewportFraction: 1.0, autoPlay: true, autoPlayInterval: const Duration(seconds: 5)),
            items: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final neonColor = Color(int.parse("0xFF${data['colorHex'] ?? '3B82F6'}"));
              final displayContent = _getDDayString(data);

              return GestureDetector(
                onTap: () => _handleActionTap(context, data),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: neonColor, width: 2.5), boxShadow: [BoxShadow(color: neonColor.withOpacity(0.15), blurRadius: 10)]),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (data['logoKey'] != null && data['logoKey'] != 'none') Padding(padding: const EdgeInsets.only(right: 10), child: Image.asset('assets/images/logos/${data['logoKey']}.png', height: 24, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
                    Expanded(child: Text(displayContent, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis, maxLines: 1)),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: neonColor),
                  ]),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _navigateToTab(BuildContext context, String route) {
    if (route == RouteConstants.home) MainScreen.changeTab(context, 0);
    else if (route == RouteConstants.trainingHome) MainScreen.changeTab(context, 1);
    else if (route == RouteConstants.arenaHome) MainScreen.changeTab(context, 2);
    else if (route == RouteConstants.community) MainScreen.changeTab(context, 3);
    else if (route == RouteConstants.myPage) MainScreen.changeTab(context, 4);
    else if (route == RouteConstants.steelLeagueSchedule) { MainScreen.changeTab(context, 2); Navigator.push(context, MaterialPageRoute(builder: (_) => const SteelLeagueScheduleScreen())); }
    else if (route == RouteConstants.steelLeagueRanking) { MainScreen.changeTab(context, 2); Navigator.push(context, MaterialPageRoute(builder: (_) => const SteelLeagueRankingScreen())); }
  }

  Widget _buildProfileCardWrapper({required Widget child}) => Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: child);
  Widget _buildEmptyMagazineCard(String msg) => Container(width: double.infinity, height: 80, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)), child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13)));

  void _handleActionTap(BuildContext context, Map<String, dynamic> item) {
    final type = item['actionType'];
    final url = item['actionUrl'];
    if (type == 'link' && url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    else if (type == 'internal' && url != null) _navigateToTab(context, url);
  }
}

class _QuickMenuItem extends StatelessWidget {
  final _QuickMenuData data;
  const _QuickMenuItem({required this.data});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: data.color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(data.icon, size: 24, color: data.color)),
            const SizedBox(height: 8),
            Text(
              data.label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87, letterSpacing: -0.5),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}