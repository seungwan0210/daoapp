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

// 🔹 트레이닝 관련
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/providers/training/training_progress_provider.dart';
import 'package:daoapp/data/models/training_progress_model.dart';

// 아레나/트레이닝 상세 화면들
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_ranking_screen.dart';
import 'package:daoapp/presentation/screens/arena/steel_league/steel_league_schedule_screen.dart';
import 'package:daoapp/presentation/screens/arena/tournament/tournaments_home_screen.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/pose_analysis_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_lab_home_screen.dart';

// ✅ 배너 광고 위젯
import 'package:daoapp/presentation/widgets/ad_banner.dart';
import 'package:daoapp/core/utils/ad_manager.dart';

// ✅ 추가 임포트
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:daoapp/presentation/screens/home/official_calendar_screen.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';

// 마이로그 홈
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_home_screen.dart';
import 'package:daoapp/presentation/screens/my_page/block_list_screen.dart';
import 'package:daoapp/presentation/screens/my_page/report_form_screen.dart';
import 'package:daoapp/presentation/screens/community/chat/chat_screen.dart';


/// 🆕 퀵 메뉴 데이터 구조
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

  void _handleAdminCleanup() {
    final user = FirebaseAuth.instance.currentUser;
    const String adminUid = "NanHPgCdsbMCFkHEs7MtxS51OSX2";
    if (user != null && user.uid == adminUid) {
      sl<ArenaRepository>().autoCleanOldTournaments();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rankingProvider.notifier).updateFilters('2026', 'total', 'all');
      _handleAdminCleanup();
    });
  }

  @override
  void dispose() {
    _quickMenuController1.dispose();
    _quickMenuController2.dispose();
    super.dispose();
  }

  List<_QuickMenuData> _getGroup1(BuildContext context) => [
    _QuickMenuData(icon: Icons.stadium_outlined, label: '아레나', color: Colors.indigo, onTap: () => MainScreen.changeTab(context, 2)),
    _QuickMenuData(icon: Icons.leaderboard_rounded, label: '스틸리그', color: Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SteelLeagueRankingScreen()))),
    _QuickMenuData(icon: Icons.emoji_events_outlined, label: '토너먼트', color: Colors.cyan, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentsHomeScreen()))),
    _QuickMenuData(icon: Icons.fitness_center_rounded, label: '트레이닝', color: Colors.orange, onTap: () => MainScreen.changeTab(context, 1)),
    _QuickMenuData(icon: Icons.accessibility_new_rounded, label: '포즈분석', color: const Color(0xFF1565C0), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoseAnalysisScreen()))),
    _QuickMenuData(icon: Icons.fingerprint_rounded, label: '그립랩', color: Colors.deepPurple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GripLabHomeScreen()))),
  ];

  List<_QuickMenuData> _getGroup2(BuildContext context) => [
    _QuickMenuData(icon: Icons.person_outline_rounded, label: '프로필', color: Colors.blueAccent, onTap: () => MainScreen.changeTab(context, 4)),
    _QuickMenuData(icon: Icons.edit_note_rounded, label: '마이로그', color: const Color(0xFFFFA000), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLogHomeScreen()))),
    _QuickMenuData(
        icon: Icons.forum_outlined,
        label: '라이브톡',
        color: Colors.green,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: const Color(0xFF0F172A),
                appBar: AppBar(
                  title: const Text("라이브톡", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                ),
                body: const ChatScreen(),
              ),
            ),
          );
        }
    ),
    _QuickMenuData(icon: Icons.photo_library_outlined, label: '서클', color: Colors.pinkAccent, onTap: () => Navigator.pushNamed(context, RouteConstants.circle)),
    _QuickMenuData(icon: Icons.person_off_outlined, label: '차단관리', color: const Color(0xFF616161), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockListScreen()))),
    _QuickMenuData(icon: Icons.report_gmailerrorred_rounded, label: '신고/버그', color: Colors.redAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportFormScreen()))),
  ];

  @override
  Widget build(BuildContext context) {
    final rankingState = ref.watch(rankingProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopProfileSection(context, ref),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(thickness: 1, color: Color(0xFFEEEEEE))),
          _buildTrainingMiniCard(context, ref),
          const SizedBox(height: 24),
          AppCard(child: _buildNewsSection(context, ref)),
          const SizedBox(height: 16),
          _buildKoreanMagazineSection(context),
          const SizedBox(height: 24),
          _buildGlobalMagazineSection(context),
          const SizedBox(height: 16),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(thickness: 1, color: Color(0xFFEEEEEE))),
          const SizedBox(height: 4),
          _buildQuickMenuSlider(_getGroup1(context), _quickMenuController1),
          const SizedBox(height: 4),
          _buildQuickMenuSlider(_getGroup2(context), _quickMenuController2),
          const SizedBox(height: 16),
          _buildWeeklyTimeline(context),
          const SizedBox(height: 16),
          AppCard(child: _buildNextEventCard(context)),
          const SizedBox(height: 4),
          AppCard(child: _buildTop3Ranking(rankingState, context)),
          const SizedBox(height: 4),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('대회 사진', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                SizedBox(height: 220, child: _buildCompetitionPhotos(context)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          AppCard(child: _buildSponsorSection(context, ref)),
          const SizedBox(height: 20),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AD', style: TextStyle(fontSize: 9, color: Colors.grey[400], letterSpacing: 1.0, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                const AdBanner(type: AdBannerType.main),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ✅ 수정된 로고 아이콘 빌더
  Widget _buildLogoIcon(String? logoKey) {
    if (logoKey == null || logoKey == 'none') return const SizedBox.shrink();

    // 🔥 핵심: 파일명 규칙에 맞춰 'logo_'를 접두어로 붙여줍니다.
    String assetPath = 'assets/images/logos/$logoKey.png';

    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // 💡 디버그용 로그: 실제 어떤 경로를 찾으려다 실패했는지 콘솔에서 확인 가능합니다.
            print("❌ 이미지 로드 실패: $assetPath");
            return const Icon(Icons.emoji_events_outlined, size: 16, color: Colors.grey);
          },
        ),
      ),
    );
  }

  // ✅ 퀵 메뉴 슬라이더: 스크롤바 위치 보정 (left: 0)
  Widget _buildQuickMenuSlider(List<_QuickMenuData> items, ScrollController controller) {
    return RawScrollbar(
      controller: controller,
      thumbVisibility: false,
      thumbColor: Colors.blueAccent.withOpacity(0.6),
      thickness: 2.5,
      radius: const Radius.circular(10),
      minThumbLength: 20,
      padding: const EdgeInsets.only(left: 0, right: 16), // ✅ 바 시작점을 왼쪽 벽에 밀착
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(left: 0, right: 16, bottom: 12),
          child: Row(
            children: items.asMap().entries.map((entry) {
              int idx = entry.key;
              var item = entry.value;
              return Row(
                children: [
                  if (idx > 0) const SizedBox(width: 8),
                  SizedBox(
                    width: 68,
                    child: _QuickMenuItem(data: item),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ✅ 공식 대회 일정 섹션: 동적 로고 및 텍스트 반영 통합 버전
  Widget _buildWeeklyTimeline(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('official_calendar').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        final selectedDayEvents = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final start = (data['startDate'] as Timestamp).toDate();
          final end = (data['endDate'] as Timestamp).toDate();
          final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
          final compareStart = DateTime(start.year, start.month, start.day);
          final compareEnd = DateTime(end.year, end.month, end.day);

          return (target.isAtSameMomentAs(compareStart) ||
              target.isAtSameMomentAs(compareEnd) ||
              (target.isAfter(compareStart) && target.isBefore(compareEnd)));
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("공식 대회 일정", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => setState(() => _selectedDate = DateTime.now()),
                      child: Text(
                        "${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일 <${_getWeekday(_selectedDate.weekday)}>",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    )
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, RouteConstants.officialCalendar),
                  icon: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.calendar_month, size: 20, color: theme.colorScheme.primary),
                  ),
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
                final now = DateTime.now();
                final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

                final dayEvents = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final start = (data['startDate'] as Timestamp).toDate();
                  final end = (data['endDate'] as Timestamp).toDate();
                  final target = DateTime(date.year, date.month, date.day);
                  return (target.isAtSameMomentAs(DateTime(start.year, start.month, start.day)) ||
                      target.isAtSameMomentAs(DateTime(end.year, end.month, end.day)) ||
                      (target.isAfter(start) && target.isBefore(end)));
                }).toList();

                return InkWell(
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: isToday
                          ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                          : Border.all(color: isSelected ? Colors.transparent : Colors.grey[200]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_getWeekday(date.weekday),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white70 : (isToday ? theme.colorScheme.primary : Colors.grey[400]),
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            )),
                        Text("${date.day}",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : (isToday ? theme.colorScheme.primary : Colors.black87))),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dayEvents.map((e) {
                            final type = (e.data() as Map<String, dynamic>)['type'];
                            return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: 8, height: 3,
                                decoration: BoxDecoration(
                                    color: type == 'domestic' ? Colors.blue : (type == 'overseas' ? Colors.red : Colors.green),
                                    borderRadius: BorderRadius.circular(2)));
                          }).toList(),
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
                  if (selectedDayEvents.isEmpty)
                    Row(
                      children: [
                        Container(width: 3, height: 14, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        const Text("등록된 공식 일정이 없습니다.",
                            style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                      ],
                    )
                  else
                    ...selectedDayEvents.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final type = data['type'] as String? ?? 'domestic';
                      final title = data['title'] as String? ?? '일정 정보 없음';
                      final logoKey = data['logoKey'] as String?; // ✅ 로고 키 가져오기

                      Color typeColor = type == 'domestic' ? Colors.blue : (type == 'overseas' ? Colors.red : Colors.green);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6), // ✅ 여백 살짝 확보
                        child: Row(
                          children: [
                            Container(width: 4, height: 18, decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 10),
                            _buildLogoIcon(logoKey), // ✅ 로고 표시
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
            _buildOngoingLeagueBar(),
          ],
        );
      },
    );
  }

  // --- 이하 헬퍼 함수들 ---
  Widget _buildKoreanMagazineSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("다트 매거진 (한국)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('magazines').where('category', isEqualTo: 'magazine_ko').where('isActive', isEqualTo: true).orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyMagazineCard("새로운 소식을 준비 중입니다.");
            return CarouselSlider(
              options: CarouselOptions(height: 110, viewportFraction: 1.0, autoPlay: true, scrollDirection: Axis.vertical),
              items: snapshot.data!.docs.map((doc) => _buildMagazineItemCard(context, doc.data() as Map<String, dynamic>)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGlobalMagazineSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("해외 다트 소식", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('magazines').where('category', isEqualTo: 'magazine_global').where('isActive', isEqualTo: true).orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyMagazineCard("해외 소식을 불러오는 중입니다.");
            return CarouselSlider(
              options: CarouselOptions(height: 110, viewportFraction: 1.0, autoPlay: true, scrollDirection: Axis.vertical),
              items: snapshot.data!.docs.map((doc) => _buildMagazineItemCard(context, doc.data() as Map<String, dynamic>)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMagazineItemCard(BuildContext context, Map<String, dynamic> data) {
    final String type = data['actionType'] ?? 'none';
    final String actionUrl = data['actionUrl']?.toString().trim() ?? '';
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () async {
          if (type == 'none' || actionUrl.isEmpty) return;
          if (type == 'internal') _navigateToTab(context, actionUrl);
          else if (type == 'link') {
            String finalUrl = actionUrl.startsWith('http') ? actionUrl : 'https://$actionUrl';
            await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
          }
        },
        child: SizedBox(
          height: 110,
          child: Row(
            children: [
              ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)), child: SizedBox(width: 120, height: 110, child: _buildMagazineImage(data['imageUrl'] ?? ''))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(data['content'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['category'] == 'magazine_ko' ? "KR Magazine" : "Global News", style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary.withOpacity(0.8), fontWeight: FontWeight.bold)),
                          Icon(type == 'none' ? Icons.visibility_outlined : Icons.arrow_forward, size: 14, color: type == 'none' ? Colors.grey : Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagazineImage(String imageUrl) {
    if (imageUrl.isEmpty) return Container(color: Colors.grey[100], child: const Icon(Icons.image_not_supported, color: Colors.grey));
    return imageUrl.startsWith('http') ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder()) : Image.asset(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder());
  }

  Widget _buildPlaceholder() => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image_outlined, color: Colors.grey));

  Widget _buildTopProfileSection(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildProfileCardWrapper(child: InkWell(onTap: () => Navigator.pushNamed(context, RouteConstants.login), child: const Row(children: [CircleAvatar(radius: 25, child: Icon(Icons.person_outline)), SizedBox(width: 12), Text("로그인 후 프로필을 등록해 주세요.", style: TextStyle(fontWeight: FontWeight.w600))])));
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return _buildProfileCardWrapper(child: InkWell(onTap: () => Navigator.pushNamed(context, RouteConstants.profileRegister), child: const Row(children: [CircleAvatar(radius: 25, child: Icon(Icons.person_add)), SizedBox(width: 12), Text("프로필을 등록해 주세요!", style: TextStyle(fontWeight: FontWeight.w600))])));
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final totalRanking = ref.watch(totalRankingProvider);
        final rankIndex = totalRanking.indexWhere((item) => item['userId'] == user.uid);
        final int? currentRank = (rankIndex != -1 && rankIndex < 10) ? rankIndex + 1 : null;
        final badgesMap = BadgeUtils.extractBadges(data);
        final adminBadge = BadgeUtils.getLatestAdminBadge(badgesMap);
        return Row(
          children: [
            Stack(clipBehavior: Clip.none, children: [
              CircleAvatar(radius: 28, backgroundImage: data['profileImageUrl'] != null ? NetworkImage(data['profileImageUrl']) : null, backgroundColor: Colors.grey[200], child: data['profileImageUrl'] == null ? const Icon(Icons.person, color: Colors.grey) : null),
              if (currentRank != null) Positioned(left: -5, top: -5, child: BadgeWidget(rank: currentRank, size: 20)),
              if (adminBadge != null) Positioned(left: currentRank != null ? -18 : -5, top: -5, child: BadgeWidget(badgeKey: adminBadge, size: 20)),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${data['koreanName'] ?? '이름 없음'}님,", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const Text("DAO에 오신 것을 환영합니다!", style: TextStyle(fontSize: 13, color: Colors.grey))])),
            GestureDetector(onTap: () => _showTopSnackBar(context, "🌐 다국어 언어팩 개발 중입니다."), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: Row(children: [Image.asset('assets/images/flags/kr.png', width: 20, errorBuilder: (_,__,___) => const Text("🇰🇷")), const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey)]))),
          ],
        );
      },
    );
  }

  void _showTopSnackBar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(builder: (context) => Positioned(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, child: Material(color: Colors.transparent, child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(25)), child: Text(message, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)))));
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  Widget _buildProfileCardWrapper({required Widget child}) => Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: child);
  Widget _buildEmptyMagazineCard(String msg) => Container(width: double.infinity, height: 80, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)), child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13)));

  Widget _buildTrainingMiniCard(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildNoTierTrainingCard(context);
    final progressAsync = ref.watch(trainingProgressProvider);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('trainingProfiles').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        DaoTrainingTier? tier;
        if (snapshot.hasData && snapshot.data!.data() != null) {
          final tierIndex = (snapshot.data!.data()!['tierIndex'] as int?) ?? 0;
          tier = DaoTrainingTier.values[tierIndex.clamp(0, DaoTrainingTier.values.length - 1)];
        }
        if (tier == null) return _buildNoTierTrainingCard(context);
        final tierColor = _tierColor(tier);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: tierColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: tierColor, width: 2)), alignment: Alignment.center, child: Text(tier.labelKo, textAlign: TextAlign.center, style: TextStyle(color: tierColor, fontSize: 12, fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Text('DAO 트레이닝', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5)), const SizedBox(width: 6), Icon(Icons.verified, size: 16, color: tierColor)]), const SizedBox(height: 2), Text('현재 ${tier.labelKo} 등급 | 오늘의 연습을 시작하세요!', style: TextStyle(fontSize: 13, color: Colors.grey[600]))])),
              IconButton(onPressed: () => _navigateToTab(context, RouteConstants.trainingHome), icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)),
            ]),
            const SizedBox(height: 16),
            progressAsync.when(data: (p) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10))), FractionallySizedBox(widthFactor: p.progressRatio.toDouble().clamp(0.0, 1.0), child: Container(height: 8, decoration: BoxDecoration(gradient: LinearGradient(colors: [tierColor.withOpacity(0.6), tierColor]), borderRadius: BorderRadius.circular(10))))]), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('성장 포인트', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)), Text('${(p.progressRatio * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: tierColor, fontWeight: FontWeight.bold))])]), loading: () => const SizedBox(height: 30, child: Center(child: LinearProgressIndicator())), error: (_, __) => const SizedBox()),
          ]),
        );
      },
    );
  }

  Widget _buildNoTierTrainingCard(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 14), child: Row(children: [const Text('🎯', style: TextStyle(fontSize: 24)), const SizedBox(width: 12), const Expanded(child: Text('DAO 트레이닝\n내 등급을 등록해 보세요.', style: TextStyle(fontSize: 12))), TextButton(onPressed: () => _navigateToTab(context, RouteConstants.trainingHome), child: const Text('내 등급 확인'))]));

  Widget _buildOngoingLeagueBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quick_notices')
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('endDate')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final notices = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: CarouselSlider(
            options: CarouselOptions(
              height: 40, // ✅ 네온 테두리가 돋보이게 높이 살짝 조정
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              scrollDirection: Axis.horizontal,
            ),
            items: notices.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // ✅ 관리자 선택 색상을 '네온 테두리 컬러'로 활용
              final neonColor = Color(int.parse("0xFF${data['colorHex'] ?? '3B82F6'}"));

              return Builder(
                builder: (context) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    // 🔥 요청사항 1: 깨끗한 흰색 배경
                    color: Colors.white,
                    // ✅ 요청사항 3: 둥근 부분에 살짝 두꺼운 줄 (네온 컬러)
                    borderRadius: BorderRadius.circular(20), // 둥글게
                    border: Border.all(
                      color: neonColor, // ✅ 요청사항 2: 네온 테두리
                      width: 2.5, // ✅ 살짝 두꺼운 줄 느낌
                    ),
                    // ✨ 네온느낌을 강화하기 위한 은은한 글로우 효과
                    boxShadow: [
                      BoxShadow(
                        color: neonColor.withOpacity(0.15),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 0), // 중앙에서 퍼지게
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ 로고 정렬 보정 (텍스트와 자연스럽게 매칭)
                      if (data['logoKey'] != null && data['logoKey'] != 'none')
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Image.asset(
                            'assets/images/logos/${data['logoKey']}.png',
                            height: 24, // 텍스트 높이에 맞춤
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),

                      Flexible(
                        child: Text(
                          data['content'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold, // ✅ 가독성을 위해 볼드체
                            color: Color(0xFF1E293B), // ✅ 글씨는 딥 네이비로 깔끔하게
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ✅ 테두리 색상과 맞춘 화살표
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: neonColor),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildNewsSection(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);
    return news.when(data: (snap) {
      if (snap.docs.isEmpty) return const Text('뉴스 없음');
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('최신 뉴스', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        CarouselSlider(options: CarouselOptions(height: 220, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.85), items: snap.docs.map((doc) {
          final item = doc.data() as Map<String, dynamic>;
          return GestureDetector(onTap: () => _handleActionTap(context, item), child: Stack(fit: StackFit.expand, children: [ClipRRect(borderRadius: BorderRadius.circular(16), child: Container(color: Colors.black, child: Image.network(item['imageUrl'] ?? '', fit: BoxFit.contain))), Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black54, Colors.transparent]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))), child: Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1)))]));
        }).toList()),
      ]);
    }, loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => const Text('뉴스 로드 오류'));
  }

  Widget _buildNextEventCard(BuildContext context) {
    final theme = Theme.of(context);
    final now = Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 5)));
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').where('eventDateTime', isGreaterThan: now).orderBy('eventDateTime').limit(3).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyCard(context, '예정된 경기 없음');
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text('다음 경기 일정', style: theme.textTheme.titleLarge), const Spacer(), TextButton(onPressed: () => _navigateToTab(context, RouteConstants.steelLeagueSchedule), child: const Text('전체 보기'))]),
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['eventDateTime'] as Timestamp).toDate();
              return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(Icons.location_on, color: theme.colorScheme.primary, size: 18), const SizedBox(width: 6), Expanded(child: Text(data['shopName'] ?? '', overflow: TextOverflow.ellipsis)), Text('${date.month}/${date.day}(${_getWeekday(date.weekday)}) ${date.hour}:${date.minute.toString().padLeft(2, '0')}', style: TextStyle(color: Colors.grey[600], fontSize: 12))]));
            }).toList()
          ]);
        });
  }

  Widget _buildTop3Ranking(AsyncValue<List<RankingUser>> state, BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('스틸리그 포인트', style: theme.textTheme.titleLarge), const Spacer(), TextButton(onPressed: () => _navigateToTab(context, RouteConstants.steelLeagueRanking), child: const Text('전체 보기'))]),
      state.when(data: (list) => Column(children: list.take(3).toList().asMap().entries.map((e) {
        final rank = e.key + 1;
        return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [CircleAvatar(backgroundColor: _getRankColor(rank), radius: 14, child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 13))), const SizedBox(width: 12), Expanded(child: Text('${e.value.koreanName} (${e.value.englishName})')), Text('${e.value.displayPoints} pt', style: const TextStyle(fontWeight: FontWeight.bold))]));
      }).toList()), loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => const Text('랭킹 로드 오류'))
    ]);
  }

  Widget _buildCompetitionPhotos(BuildContext context) => StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('competition_photos').where('isActive', isEqualTo: true).orderBy('createdAt', descending: true).snapshots(), builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyBanner(context, '사진 없음');
    return CarouselSlider(options: CarouselOptions(height: 200, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.85), items: snapshot.data!.docs.map((doc) => GestureDetector(onTap: () => _handleActionTap(context, doc.data() as Map<String, dynamic>), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network((doc.data() as Map<String, dynamic>)['imageUrl'] ?? '', fit: BoxFit.cover)))).toList());
  });

  Widget _buildSponsorSection(BuildContext context, WidgetRef ref) {
    final sponsors = ref.watch(sponsorBannerProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('스폰서', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      sponsors.when(data: (s) => CarouselSlider(options: CarouselOptions(height: 120, autoPlay: true, viewportFraction: 1.0), items: s.docs.map((d) => GestureDetector(onTap: () => _handleActionTap(context, d.data() as Map<String, dynamic>), child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network((d.data() as Map<String, dynamic>)['imageUrl'] ?? '', fit: BoxFit.cover)))).toList()), loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())), error: (_, __) => const SizedBox())
    ]);
  }

  void _handleActionTap(BuildContext context, Map<String, dynamic> item) {
    final type = item['actionType'];
    if (type == 'link' && item['actionUrl'] != null) launchUrl(Uri.parse(item['actionUrl']), mode: LaunchMode.externalApplication);
    else if (type == 'internal' && item['actionRoute'] != null) _navigateToTab(context, item['actionRoute']);
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

  String _getWeekday(int weekday) => ['월', '화', '수', '목', '금', '토', '일'][weekday - 1];
  Color _tierColor(DaoTrainingTier tier) => [const Color(0xFFFF8EC7), Colors.blue, Colors.teal, Colors.green, Colors.orange, Colors.redAccent, Colors.deepPurpleAccent][tier.index];
  Widget _buildEmptyCard(BuildContext context, String msg) => Padding(padding: const EdgeInsets.all(16), child: Text(msg, style: const TextStyle(color: Colors.grey)));
  Widget _buildEmptyBanner(BuildContext context, String msg) => Container(height: 200, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: Center(child: Text(msg)));
  Color _getRankColor(int rank) => rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : (rank == 3 ? Colors.brown : const Color(0xFF1565C0)));
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: data.color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(data.icon, size: 24, color: data.color)),
            const SizedBox(height: 8),
            Text(data.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87, letterSpacing: -0.5), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}