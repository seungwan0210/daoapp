// lib/presentation/screens/training/drills/drill_result_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_report_model.dart';

import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/screens/training/report/training_report_overlay.dart';
import 'package:daoapp/presentation/screens/training/widgets/report/training_report_viewmodel.dart';

// ✅ 히스토리 화면으로 이동할 수 있도록 import
import 'package:daoapp/presentation/screens/training/history/training_history_screen.dart';

class DrillResultScreen extends StatefulWidget {
  final TrainingSessionModel session;
  final TrainingDrillDefinition drill;
  final DaoTrainingTier tier;

  const DrillResultScreen({
    super.key,
    required this.session,
    required this.drill,
    required this.tier,
  });

  @override
  State<DrillResultScreen> createState() => _DrillResultScreenState();
}

class _DrillResultScreenState extends State<DrillResultScreen> {
  bool _reportTried = false;

  int get _xpEarned {
    if (widget.session.xpEarned > 0) return widget.session.xpEarned;
    final extraXp = widget.session.extra?['xpEarned'];
    if (extraXp is num) return extraXp.toInt();
    return 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTrainingReportIfPossible();
    });
  }

  /// 🔍 같은 드릴의 이전 기록 1개 가져오기
  Future<TrainingSessionModel?> _fetchPreviousSession(
      String userId, TrainingSessionModel current) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('trainingSessions')
        .where('drillId', isEqualTo: current.drillId)
        .where('endedAt', isLessThan: current.endedAt)
        .orderBy('endedAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return TrainingSessionModel.fromJson(doc.id, doc.data());
  }

  Future<void> _showTrainingReportIfPossible() async {
    if (_reportTried) return;
    _reportTried = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      /// 🔹 Progress After 불러오기
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trainingMeta')
          .doc('trainingProgress')
          .get();
      if (!doc.exists) return;

      // ✅ fromJson 첫 번째 인자는 userId 라서 user.uid 로 넘기도록 수정
      final progressAfter = TrainingProgressModel.fromJson(
        user.uid,
        doc.data() ?? <String, dynamic>{},
      );

      final int earned = _xpEarned;

      // ✅ 세션이 이미 Firestore에 저장된 상태라면 xp / cycleId도 문서에 merge 업데이트
      if (widget.session.id != null && widget.session.id!.isNotEmpty) {
        final sessionRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('trainingSessions')
            .doc(widget.session.id);

        await sessionRef.set(
          {
            'xpEarned': earned,
            // 세션에 cycleId가 아직 없다면, progressAfter.currentCycleId 로 채워준다.
            if (widget.session.cycleId == null ||
                widget.session.cycleId!.isEmpty)
              'cycleId': progressAfter.currentCycleId,
          },
          SetOptions(merge: true),
        );
      }

      /// 🔹 Before 계산 (earned 만큼 빼서 이전 상태 추정)
      final beforeProgress = progressAfter.copyWith(
        totalXp:
        (progressAfter.totalXp - earned).clamp(0, progressAfter.totalXp),
        xpSinceLastCheck: (progressAfter.xpSinceLastCheck - earned)
            .clamp(0, progressAfter.cycleSize),
      );

      /// 🔥 이전 최고 기록 로드
      final previousBest =
      await _fetchPreviousSession(user.uid, widget.session);

      /// 🔹 Report Model 생성
      final reportModel = TrainingReportBuilder.build(
        session: widget.session,
        progressBefore: beforeProgress,
        progressAfter: progressAfter,
      );

      /// 🔹 ViewModel 구성
      final viewModel = TrainingReportViewModel(
        currentSession: widget.session,
        previousBestSession: previousBest,
        previousProgress: beforeProgress,
        updatedProgress: progressAfter,
        reportModel: reportModel,
      );

      if (!mounted) return;

      await showTrainingReportOverlayDialog(
        context: context,
        report: viewModel,
        tier: widget.tier, // 🔹 티어 전달

        // ✅ 닫기: 현재 화면 pop
        onClose: () => Navigator.of(context).pop(),

        // ✅ 히스토리로 이동: 히스토리 화면 푸시
        onGoHistory: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TrainingHistoryScreen(),
            ),
          );
        },

        // 지금은 아직 안 쓰는 콜백은 null 유지
        onGoNextDrill: null,
        onGoRatingCheck: null,
      );
    } catch (e) {
      debugPrint('Training report overlay error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final drill = widget.drill;
    final tier = widget.tier;

    final mode = session.inputModeString;
    final duration = session.endedAt.difference(session.startedAt);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('연습 결과',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drill.titleKo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    drill.titleEn,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ChipLabel(
                        label: '티어',
                        value: '${tier.labelKo} (${tier.labelEn})',
                      ),
                      const SizedBox(width: 8),
                      _ChipLabel(
                        label: '카테고리',
                        value: drill.category.name,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.drillTitle.isNotEmpty
                        ? session.drillTitle
                        : drill.shortDescriptionKo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _XpResultCard(xp: _xpEarned),
            const SizedBox(height: 16),
            _MainStatsCard(session: session, mode: mode),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '세션 요약',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _RowItem(
                    label: '총 시도',
                    value:
                    '${session.totalAttempts}회 (${session.totalRounds}R)',
                  ),
                  if (session.hitRate != null)
                    _RowItem(
                      label: '명중률',
                      value:
                      '${(session.hitRate! * 100).toStringAsFixed(1)}%',
                    ),
                  if (session.ppd != null)
                    _RowItem(
                      label: 'PPD',
                      value: session.ppd!.toStringAsFixed(2),
                    ),
                  if (session.mpr != null)
                    _RowItem(
                      label: 'MPR',
                      value: session.mpr!.toStringAsFixed(2),
                    ),
                  _RowItem(
                    label: '소요 시간',
                    value: minutes > 0
                        ? '$minutes분 $seconds초'
                        : '$seconds초',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 큰 XP 카드
class _XpResultCard extends StatelessWidget {
  final int xp;

  const _XpResultCard({
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasXp = xp > 0;
    final String mainText = hasXp ? '+$xp XP' : 'XP 0 (테스트 중)';
    final String subText = hasXp
        ? '이번 연습으로 획득한 경험치입니다.'
        : 'XP 계산 테스트용 기록입니다.';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 세션 XP',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                mainText,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color:
                  hasXp ? Colors.cyan.shade600 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              if (hasXp)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '성장 포인트',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 메인 성과 카드 (모드별로 가장 중요한 수치 1~2개만 강조)
class _MainStatsCard extends StatelessWidget {
  final TrainingSessionModel session;
  final String? mode;

  const _MainStatsCard({
    required this.session,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final inputMode = mode ?? session.inputModeString;

    String title = '주요 성과';
    Widget content;

    if (inputMode == 'hitCount') {
      final hitRate = session.hitRate != null
          ? (session.hitRate! * 100).toStringAsFixed(1)
          : '--';
      title = '명중률 드릴 결과';
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(
            label: '명중률',
            value: '$hitRate%',
          ),
          _BigStat(
            label: '성공 / 실패',
            value: '${session.successCount} / ${session.failCount}',
          ),
        ],
      );
    } else if (inputMode == 'scoreOnly') {
      final ppdText =
      session.ppd != null ? session.ppd!.toStringAsFixed(2) : '--';
      final threeDartText = session.threeDartAvg != null
          ? session.threeDartAvg!.toStringAsFixed(2)
          : '--';
      title = '점수형 드릴 결과';

      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(
            label: 'PPD',
            value: ppdText,
          ),
          _BigStat(
            label: '3다트 평균',
            value: threeDartText,
          ),
        ],
      );
    } else if (inputMode == 'cricketMarks') {
      final mprText =
      session.mpr != null ? session.mpr!.toStringAsFixed(2) : '--';
      title = '크리켓 드릴 결과';
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(
            label: 'Cricket MPR',
            value: mprText,
          ),
          _BigStat(
            label: '총 마크',
            value: '${session.totalMarksExtra ?? '-'}',
          ),
        ],
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(
            label: '시도 수',
            value: '${session.totalAttempts}',
          ),
          _BigStat(
            label: '라운드',
            value: '${session.totalRounds}R',
          ),
        ],
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}

/// 작은 라벨+값 칩
class _ChipLabel extends StatelessWidget {
  final String label;
  final String value;

  const _ChipLabel({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;

  const _BigStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;

  const _RowItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
