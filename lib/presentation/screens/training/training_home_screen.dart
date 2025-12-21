// lib/presentation/screens/training/training_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/core/constants/training_drill_constants.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/ad_banner.dart'; // ✅ 배너 광고 위젯 추가

import 'widgets/dual_neon_gauge_row.dart';
import 'widgets/dao_tier_badge_large.dart';
import 'drills/drill_run_screen.dart';
import 'package:daoapp/core/constants/training_program_constants.dart'
as program_constants;

// 🔹 XP/게이지 Progress Provider
import 'package:daoapp/presentation/providers/training/training_progress_provider.dart';

// 🔹 레이팅 체크 후 게이지 리셋에 사용할 Repository
import 'package:daoapp/data/repositories/training_progress_repository.dart';
import 'package:daoapp/di/service_locator.dart';

// 🔹 마이로그 홈 스크린
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_home_screen.dart';

class TrainingHomeScreen extends ConsumerStatefulWidget {
  const TrainingHomeScreen({super.key});

  @override
  ConsumerState<TrainingHomeScreen> createState() =>
      _TrainingHomeScreenState();
}

class _TrainingHomeScreenState extends ConsumerState<TrainingHomeScreen> {
  DaoTrainingProfile? _profile;
  bool _isLoadingProfile = true;

  /// 🔥 한 사이클(게이지 0→100%) 동안 팝업을 딱 1번만 띄우기 위한 플래그
  bool _ratingDialogShownForThisCycle = false;

  // ========= Firestore 헬퍼 =========

  CollectionReference<Map<String, dynamic>> get _trainingCol =>
      FirebaseFirestore.instance.collection('trainingProfiles');

  Future<void> _loadProfileFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingProfile = false;
      });
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
      final tier = DaoTrainingTier
          .values[tierIndex.clamp(0, DaoTrainingTier.values.length - 1)];

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
      setState(() {
        _isLoadingProfile = false;
      });
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
        content: const Text(
          "DAO 트레이닝 레이팅과 티어를 초기화합니다.\n"
              "다시 레이팅 입력 또는 레벨 테스트로 시작할 수 있습니다.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "초기화",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _trainingCol.doc(user.uid).delete();
    } catch (e) {
      debugPrint('Failed to delete training profile: $e');
    }

    if (!mounted) return;
    setState(() {
      _profile = null;
    });
  }

  // ========= 레이팅/레벨 테스트 완료 후: XP 게이지 리셋 =========

  Future<void> _updateProgressAfterRatingCheck(DaoTrainingTier tier) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final repo = sl<TrainingProgressRepository>();
      await repo.markRatingChecked(
        userId: user.uid,
        newTier: tier,
      );
    } catch (e) {
      debugPrint('Failed to mark rating checked: $e');
    }
  }

  // ========= 레이팅/레벨 테스트 화면 이동 =========

  Future<void> _openRatingInput() async {
    final result =
    await Navigator.pushNamed(context, RouteConstants.trainingRatingInput);

    if (result is DaoTrainingProfile) {
      setState(() => _profile = result);
      await _saveProfileToFirestore();

      // 🔹 레이팅 입력으로 티어 확정 → XP 게이지도 새 티어 기준으로 리셋
      await _updateProgressAfterRatingCheck(result.tier);
    }
  }

  Future<void> _openBoardLevelTest() async {
    final result =
    await Navigator.pushNamed(context, RouteConstants.boardLevelTest);

    if (result is DaoTrainingProfile) {
      setState(() => _profile = result);
      await _saveProfileToFirestore();

      // 🔹 보드 레벨 테스트로 티어 확정 → XP 게이지 리셋
      await _updateProgressAfterRatingCheck(result.tier);
    }
  }

  // 숫자 예쁘게 포맷 (16.00 → 16, 16.63 → 16.63)
  String _formatRating(double? rating) {
    if (rating == null) return "-";
    if (rating % 1 == 0) return rating.toInt().toString();
    return rating.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  /// 🔥 성장 게이지 100% 달성 시 호출되는 다이얼로그
  Future<void> _showRatingCheckDialog() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          '🔥 성장 게이지 100% 달성!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '훈련을 통해 성장 게이지가 가득 찼어요.\n\n'
              '지금 레이팅을 다시 측정하여\n'
              '성장한 실력을 확인해볼까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('나중에 하기'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '레이팅 / 레벨 테스트 하기',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == true) {
      Navigator.pushNamed(context, RouteConstants.trainingRatingInput);
    }
  }

  /// 🔍 Progress를 보고, 게이지 100% 도달 시 다이얼로그 한 번만 띄우는 로직
  void _handleProgressForRatingDialog(TrainingProgressModel progress) {
    if (progress.isCycleComplete) {
      if (!_ratingDialogShownForThisCycle) {
        _ratingDialogShownForThisCycle = true;
        Future.microtask(_showRatingCheckDialog);
      }
    } else {
      // 새 사이클 (xpSinceLastCheck 리셋 등) 시작되면 다시 false로
      if (_ratingDialogShownForThisCycle) {
        _ratingDialogShownForThisCycle = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    final hasRating =
        _profile?.phoenixClass != null || _profile?.liveRating != null;
    final screenWidth = MediaQuery.of(context).size.width;

    // 🔹 XP/게이지 Progress 구독
    final progressAsync = ref.watch(trainingProgressProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
          children: [
            // === 프로필 없으면 입력 유도 ===
            if (_profile == null) ...[
              _buildEmptyState(),
              const SizedBox(height: 24),

              // 프로필 없을 때도 기본 게이지(0%)는 보여줄 수 있음
              progressAsync.when(
                data: (progress) {
                  _handleProgressForRatingDialog(progress);
                  return _buildXpGauge(progress);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 60),
            ] else ...[
              // === DAO 티어 크게 표시 ===
              Center(
                child: DaoTierBadgeLarge(
                  tier: _profile!.tier,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  "현재 DAO 티어 · ${_profile!.tier.labelKo}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // === 네온 듀얼 게이지 (PHOENIX / LIVE) ===
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 400 ? 20 : 0,
                ),
                child: DualNeonGaugeRow(
                  phoenixRating: _profile!.phoenixClass,
                  liveRating: _profile!.liveRating,
                  gaugeSize: screenWidth > 400 ? 160 : 140,
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 XP 성장 게이지
              progressAsync.when(
                data: (progress) {
                  _handleProgressForRatingDialog(progress);
                  return _buildXpGauge(progress);
                },
                loading: () => const SizedBox(
                  height: 72,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) {
                  debugPrint('Progress load error: $e');
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 24),

              // === 상세 정보 카드 + 수정 / 초기화 ===
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "PHOENIX CLASS",
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatRating(_profile!.phoenixClass),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.cyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "DARTSLIVE RATING",
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatRating(_profile!.liveRating),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 버튼 2개: 수정 / 초기화
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openRatingInput,
                              icon: const Icon(Icons.edit),
                              label: const Text(
                                "레이팅 수정하기",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.cyan,
                                side: const BorderSide(
                                    color: Colors.cyan),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: TextButton(
                              onPressed: _resetProfile,
                              child: const Text(
                                "초기화",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // === 안내 문구 ===
              if (hasRating) ...[
                const SizedBox(height: 8),
                Text(
                  "※ 이 수치는 DAO 트레이닝을 위한 참고용 레이팅입니다.\n"
                      "※ 실제 PHOENIX / DARTSLIVE 레이팅과는 약간의 오차가 있을 수 있습니다.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 40),
            ],

            // === 오늘의 추천 연습 ===
            Text(
              "오늘의 추천 연습",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "지금 티어에 가장 잘 맞는 드릴로 가볍게 워밍업을 시작해보세요.",
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildRecommendationCards(_profile?.tier),
            const SizedBox(height: 40),

            // === 훈련 도구 ===
            Text(
              "훈련 도구",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "기록을 확인하고, 체크아웃 연습과 계산을 도와주는 도구들입니다.",
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ..._buildPracticeItems(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// ✅ XP 성장 게이지 카드
  Widget _buildXpGauge(TrainingProgressModel progress) {
    final ratio = progress.progressRatio; // 0.0 ~ 1.0
    final percentText =
    (ratio * 100).clamp(0, 100).toStringAsFixed(0);
    final remain = progress.remainingXp;

    String subtitle;
    if (ratio >= 1.0) {
      subtitle = "게이지가 가득 찼습니다! 레이팅/레벨 테스트를 진행해 보세요.";
    } else if (ratio >= 0.7) {
      subtitle = "거의 다 왔어요. 집중해서 한두 세션만 더!";
    } else {
      subtitle =
      "연습을 할수록 XP가 쌓이고, 가득 차면 레이팅을 다시 체크합니다.";
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 텍스트
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "성장 게이지",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "$percentText%",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.cyan.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ratio >= 1.0
                  ? "다음 레이팅 체크를 진행해주세요."
                  : "레이팅/레벨 재평가까지 남은 XP: $remain",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Icon(Icons.sports_esports_outlined,
            size: 100, color: Colors.grey[400]),
        const SizedBox(height: 32),
        const Text(
          "당신의 다트 실력을 알려주세요!",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "피닉스나 다트라이브 레이팅을 입력하거나\n"
              "간단한 레벨 테스트로 시작해보세요",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openRatingInput,
                icon: const Icon(Icons.bar_chart, color: Colors.white),
                label: const Text(
                  "레이팅 입력",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  padding:
                  const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openBoardLevelTest,
                icon: const Icon(Icons.flag),
                label: const Text(
                  "레벨 테스트",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.cyan, width: 2),
                  foregroundColor: Colors.cyan,
                  padding:
                  const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 티어 기반 "오늘의 추천 드릴" 카드
  Widget _buildRecommendationCards(DaoTrainingTier? tier) {
    // 프로필 없으면 일단 Beginner(비기너) 기준으로 보여주기
    final DaoTrainingTier effectiveTier =
        tier ?? DaoTrainingTier.beginner;

    final List<TrainingDrillDefinition> drills =
    program_constants.getRecommendedDrillsForToday(
        effectiveTier);

    if (drills.isEmpty) {
      return const Text(
        "아직 준비된 추천 드릴이 없습니다.",
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: drills
          .map(
            (drill) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: InkWell(
              onTap: () {
                final DaoTrainingTier runTier =
                    _profile?.tier ?? effectiveTier;

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DrillRunScreen(
                      drill: drill,
                      tier: runTier,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                      _categoryColor(drill.category)
                          .withOpacity(0.12),
                      child: Icon(
                        _categoryIcon(drill.category),
                        color: _categoryColor(drill.category),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            drill.titleKo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            drill.shortDescriptionKo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _pill(
                                _categoryColor(drill.category),
                                _categoryLabel(drill.category),
                              ),
                              _pill(
                                Colors.blueGrey,
                                _inputModeLabel(drill.inputMode),
                              ),
                              _pill(
                                Colors.deepPurple,
                                _tierRangeLabel(drill.tierRange),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  List<Widget> _buildPracticeItems() {
    return [
      // 🔹 트레이닝 히스토리
      _practiceTile(
        Icons.timeline,
        "트레이닝 히스토리",
        RouteConstants.trainingHistory,
        Colors.blueGrey,
      ),

      // 🔹 피니시 루트 연습
      _practiceTile(
        Icons.sports_score,
        "피니시 루트 연습",
        RouteConstants.finishRouteHome,
        Colors.green,
      ),

      // 🔹 체크아웃 계산기
      _practiceTile(
        Icons.calculate,
        "체크아웃 계산기",
        RouteConstants.checkoutCalculator,
        Colors.deepPurple,
      ),

      // 🔹 나만의 다트 이야기 (마이로그)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MyLogHomeScreen(),
              ),
            );
          },
          child: const ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFFFFF3E0),
              child: Icon(Icons.menu_book, color: Color(0xFFFF9800)),
            ),
            title: Text(
              "나만의 다트 이야기",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              "오늘의 경기, 느낌, 기록을 마이로그에 남겨보세요.",
              style: TextStyle(fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
        ),
      ),

      // ✅ 여기 바로 아래에 배너 광고 한 줄 추가
      const SizedBox(height: 4),
      const AdBanner(),
    ];
  }

  Widget _practiceTile(
      IconData icon, String title, String route, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => Navigator.pushNamed(context, route),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }

  // ======= 추천 카드용 헬퍼들 =======

  Color _categoryColor(TrainingDrillCategory category) {
    switch (category) {
      case TrainingDrillCategory.boardMapping:
        return Colors.teal;
      case TrainingDrillCategory.finish:
        return Colors.redAccent;
      case TrainingDrillCategory.doublePractice:
        return Colors.indigo;
      case TrainingDrillCategory.scoring:
        return Colors.orange;
      case TrainingDrillCategory.bull:
        return Colors.green;
      case TrainingDrillCategory.other:
        return const Color(0xFFFF8EC7);
    }
  }

  IconData _categoryIcon(TrainingDrillCategory category) {
    switch (category) {
      case TrainingDrillCategory.boardMapping:
        return Icons.grid_3x3;
      case TrainingDrillCategory.finish:
        return Icons.flag_circle;
      case TrainingDrillCategory.doublePractice:
        return Icons.blur_circular;
      case TrainingDrillCategory.scoring:
        return Icons.trending_up;
      case TrainingDrillCategory.bull:
        return Icons.my_location;
      case TrainingDrillCategory.other:
        return Icons.extension;
    }
  }

  String _categoryLabel(TrainingDrillCategory category) {
    switch (category) {
      case TrainingDrillCategory.boardMapping:
        return '보드 감각';
      case TrainingDrillCategory.finish:
        return '체크아웃';
      case TrainingDrillCategory.doublePractice:
        return '더블 연습';
      case TrainingDrillCategory.scoring:
        return '스코어링';
      case TrainingDrillCategory.bull:
        return 'BULL 연습';
      case TrainingDrillCategory.other:
        return '기타';
    }
  }

  String _inputModeLabel(TrainingDrillInputMode mode) {
    switch (mode) {
      case TrainingDrillInputMode.hitCount:
        return '명중률 드릴';
      case TrainingDrillInputMode.cricketMarks:
        return 'MPR 드릴';
      case TrainingDrillInputMode.scoreOnly:
        return '점수 드릴';
    }
  }

  String _tierRangeLabel(DrillTierRange range) {
    if (range.minTier == range.maxTier) {
      return range.minTier.labelKo;
    }
    return '${range.minTier.labelKo}~${range.maxTier.labelKo}';
  }

  Widget _pill(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color.darken(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// 간단한 Color 확장: 살짝 어둡게
extension _ColorX on Color {
  Color darken([double amount = .15]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark =
    hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
