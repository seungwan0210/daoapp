import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/ad_manager.dart';


import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/constants/training_drill_constants.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/ad_banner.dart';

import 'widgets/dual_neon_gauge_row.dart';
import 'widgets/dao_tier_badge_large.dart';
import 'drills/drill_run_screen.dart';
import 'package:daoapp/core/constants/training_program_constants.dart' as program_constants;

// 🔹 XP/게이지 Progress Provider
import 'package:daoapp/presentation/providers/training/training_progress_provider.dart';

// 🔹 레이팅 체크 후 게이지 리셋에 사용할 Repository
import 'package:daoapp/data/repositories/training_progress_repository.dart';
import 'package:daoapp/di/service_locator.dart';

// 🔹 마이로그 홈 스크린
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_home_screen.dart';

// ✅ 포즈 분석 및 그립 랩 화면 import
import 'package:daoapp/presentation/screens/training/pose_analysis/pose_analysis_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_lab_home_screen.dart';

// ✅ 자유 랭킹 탭 뷰 import
import 'package:daoapp/presentation/screens/training/ranking/ranking_tab_view.dart';

enum TrainingTab { free, practice }

class TrainingHomeScreen extends ConsumerStatefulWidget {
  const TrainingHomeScreen({super.key});

  @override
  ConsumerState<TrainingHomeScreen> createState() => _TrainingHomeScreenState();
}

class _TrainingHomeScreenState extends ConsumerState<TrainingHomeScreen> {
  DaoTrainingProfile? _profile;
  bool _isLoadingProfile = true;
  TrainingTab _selectedTab = TrainingTab.free;
  bool _ratingDialogShownForThisCycle = false;

  CollectionReference<Map<String, dynamic>> get _trainingCol =>
      FirebaseFirestore.instance.collection('trainingProfiles');

  Future<void> _loadProfileFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final doc = await _trainingCol.doc(user.uid).get();
      if (!doc.exists) {
        setState(() {
          _profile = null;
          _isLoadingProfile = false;
        });
        return;
      }

      final data = doc.data()!;
      final tierIndex = (data['tierIndex'] as int?) ?? 0;
      final tier = DaoTrainingTier.values[tierIndex.clamp(0, DaoTrainingTier.values.length - 1)];

      setState(() {
        _profile = DaoTrainingProfile(
          phoenixPpd: (data['phoenixPpd'] as num?)?.toDouble(),
          phoenixMpr: (data['phoenixMpr'] as num?)?.toDouble(),
          phoenixClass: (data['phoenixClass'] as num?)?.toDouble(),
          livePpd: (data['livePpd'] as num?)?.toDouble(),
          liveMpr: (data['liveMpr'] as num?)?.toDouble(),
          liveRating: (data['liveRating'] as num?)?.toDouble(),
          boardTestDarts: data['boardTestDarts'] as int?,
          tier: tier,
        );
        _isLoadingProfile = false;
      });
    } catch (e) {
      debugPrint('Failed to load training profile: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _saveProfileToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _profile == null) return;

    try {
      await _trainingCol.doc(user.uid).set({
        'phoenixPpd': _profile!.phoenixPpd,
        'phoenixMpr': _profile!.phoenixMpr,
        'phoenixClass': _profile!.phoenixClass,
        'livePpd': _profile!.livePpd,
        'liveMpr': _profile!.liveMpr,
        'liveRating': _profile!.liveRating,
        'boardTestDarts': _profile!.boardTestDarts,
        'tierIndex': _profile!.tier.index,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save training profile: $e');
    }
  }

  Future<void> _resetProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("트레이닝 데이터 초기화"),
        content: const Text("DAO 트레이닝 레이팅과 티어를 초기화합니다.\n다시 레이팅 입력 또는 레벨 테스트로 시작할 수 있습니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("초기화", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await _trainingCol.doc(user.uid).delete();
    } catch (e) {
      debugPrint('Failed to delete: $e');
    }
    if (!mounted) return;
    setState(() => _profile = null);
  }

  Future<void> _updateProgressAfterRatingCheck(DaoTrainingTier tier) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final repo = sl<TrainingProgressRepository>();
      await repo.markRatingChecked(userId: user.uid, newTier: tier);
    } catch (e) {
      debugPrint('Failed to update progress: $e');
    }
  }

  Future<void> _openRatingInput() async {
    final result = await Navigator.pushNamed(context, RouteConstants.trainingRatingInput);
    if (result is DaoTrainingProfile) {
      setState(() => _profile = result);
      await _saveProfileToFirestore();
      await _updateProgressAfterRatingCheck(result.tier);
    }
  }

  Future<void> _openBoardLevelTest() async {
    final result = await Navigator.pushNamed(context, RouteConstants.boardLevelTest);
    if (result is DaoTrainingProfile) {
      setState(() => _profile = result);
      await _saveProfileToFirestore();
      await _updateProgressAfterRatingCheck(result.tier);
    }
  }

  String _formatRating(double? rating) {
    if (rating == null) return "-";
    if (rating % 1 == 0) return rating.toInt().toString();
    return rating.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _handleProgressForRatingDialog(TrainingProgressModel progress) {
    if (progress.isCycleComplete) {
      if (!_ratingDialogShownForThisCycle) {
        _ratingDialogShownForThisCycle = true;
        Future.microtask(_showRatingCheckDialog);
      }
    } else {
      if (_ratingDialogShownForThisCycle) _ratingDialogShownForThisCycle = false;
    }
  }

  Future<void> _showRatingCheckDialog() async {
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🔥 성장 게이지 100% 달성!', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('훈련을 통해 성장 게이지가 가득 찼어요.\n지금 레이팅을 다시 측정하여 성장한 실력을 확인해볼까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('나중에 하기')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('테스트 하기', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (result == true && mounted) Navigator.pushNamed(context, RouteConstants.trainingRatingInput);
  }

  @override
  void initState() {
    super.initState();
    _loadProfileFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final progressAsync = ref.watch(trainingProgressProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          children: [
            if (_profile == null) ...[
              _buildEmptyState(),
              const SizedBox(height: 12),
              progressAsync.when(
                data: (p) { _handleProgressForRatingDialog(p); return _buildXpGauge(p); },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ] else ...[
              Center(child: DaoTierBadgeLarge(tier: _profile!.tier)),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "현재 DAO 티어 · ${_profile!.tier.labelKo}",
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth > 400 ? 20 : 0),
                child: DualNeonGaugeRow(
                  phoenixRating: _profile!.phoenixClass,
                  liveRating: _profile!.liveRating,
                  gaugeSize: screenWidth > 400 ? 150 : 130,
                ),
              ),
              const SizedBox(height: 12),
              progressAsync.when(
                data: (p) { _handleProgressForRatingDialog(p); return _buildXpGauge(p); },
                loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              AppCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    children: [
                      _buildRatingRow("PHOENIX CLASS", _formatRating(_profile!.phoenixClass), Colors.cyan),
                      const Divider(height: 16),
                      _buildRatingRow("DARTSLIVE RATING", _formatRating(_profile!.liveRating), Colors.orange),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _openRatingInput,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.cyan,
                                side: const BorderSide(color: Colors.cyan),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("레이팅 수정", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _resetProfile,
                            child: const Text("초기화", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeChip("🏆 자유 랭킹", TrainingTab.free),
                const SizedBox(width: 12),
                _buildModeChip("🎯 맞춤 연습", TrainingTab.practice),
              ],
            ),
            const SizedBox(height: 16),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _selectedTab == TrainingTab.free
                  ? const RankingTabView()
                  : _buildRecommendationCards(_profile?.tier),
            ),

            const SizedBox(height: 32),

            Text("훈련 도구", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._buildPracticeItems(),

            /// ==========================================
            /// 🔥 [정책 준수] 슬림 배너 광고 영역
            /// ==========================================
            const SizedBox(height: 12),
            Column( // 👈 1. 여기 앞에 있던 const를 반드시 지워주세요!
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AD',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[400], // 이제 여기서 에러가 안 납니다!
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const AdBanner(type: AdBannerType.main), // 2. 여기도 const 없이!
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildModeChip(String label, TrainingTab tab) {
    final isSelected = _selectedTab == tab;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) { if (val) setState(() => _selectedTab = tab); },
      selectedColor: Colors.cyan.withOpacity(0.1),
      backgroundColor: Colors.grey[50],
      labelStyle: TextStyle(
        color: isSelected ? Colors.cyan[800] : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: isSelected ? Colors.cyan : Colors.transparent),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildXpGauge(TrainingProgressModel progress) {
    final ratio = progress.progressRatio;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("성장 게이지", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text("${(ratio * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                minHeight: 6,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.shade600),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ratio >= 1.0 ? "레이팅 체크 준비 완료" : "재평가까지 남은 XP: ${progress.remainingXp}",
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Icon(Icons.sports_esports_outlined, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text("다트 실력을 입력해주세요!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: ElevatedButton(onPressed: _openRatingInput, style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text("레이팅 입력"))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(onPressed: _openBoardLevelTest, style: OutlinedButton.styleFrom(foregroundColor: Colors.cyan, side: const BorderSide(color: Colors.cyan), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text("레벨 테스트"))),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationCards(DaoTrainingTier? tier) {
    final drills = program_constants.getRecommendedDrillsForToday(tier ?? DaoTrainingTier.beginner);
    if (drills.isEmpty) return const Center(child: Text("추천 드릴이 없습니다."));
    return Column(
      children: drills.map((drill) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DrillRunScreen(drill: drill, tier: _profile?.tier ?? DaoTrainingTier.beginner))),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(radius: 18, backgroundColor: _categoryColor(drill.category).withOpacity(0.1), child: Icon(_categoryIcon(drill.category), color: _categoryColor(drill.category), size: 18)),
            title: Text(drill.titleKo, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(drill.shortDescriptionKo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12),
          ),
        ),
      )).toList(),
    );
  }

  List<Widget> _buildPracticeItems() {
    return [
      _toolTile(Icons.timeline, "트레이닝 히스토리", Colors.blueGrey, () => Navigator.pushNamed(context, RouteConstants.trainingHistory)),
      _toolTile(Icons.fingerprint, "그립 연구소", Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GripLabHomeScreen()))),
      _toolTile(Icons.accessibility_new_rounded, "자세분석 & 트래킹", const Color(0xFF1565C0), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoseAnalysisScreen()))),
      _toolTile(Icons.calculate, "체크아웃 계산기", Colors.deepPurple, () => Navigator.pushNamed(context, RouteConstants.checkoutCalculator)),
      _toolTile(Icons.menu_book, "나만의 다트 이야기", Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLogHomeScreen()))),
    ];
  }

  Widget _toolTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: color, size: 22),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 12),
        ),
      ),
    );
  }

  Color _categoryColor(TrainingDrillCategory category) {
    switch (category) {
      case TrainingDrillCategory.boardMapping: return Colors.teal;
      case TrainingDrillCategory.finish: return Colors.redAccent;
      case TrainingDrillCategory.doublePractice: return Colors.indigo;
      case TrainingDrillCategory.scoring: return Colors.orange;
      case TrainingDrillCategory.bull: return Colors.green;
      case TrainingDrillCategory.other: return const Color(0xFFFF8EC7);
    }
  }

  IconData _categoryIcon(TrainingDrillCategory category) {
    switch (category) {
      case TrainingDrillCategory.boardMapping: return Icons.grid_3x3;
      case TrainingDrillCategory.finish: return Icons.flag_circle;
      case TrainingDrillCategory.doublePractice: return Icons.blur_circular;
      case TrainingDrillCategory.scoring: return Icons.trending_up;
      case TrainingDrillCategory.bull: return Icons.my_location;
      case TrainingDrillCategory.other: return Icons.extension;
    }
  }
}