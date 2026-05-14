// lib/presentation/screens/training/drills/drill_result_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/data/models/training_report_model.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/screens/training/report/training_report_overlay.dart';
import 'package:daoapp/presentation/screens/training/widgets/report/training_report_viewmodel.dart';
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

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trainingMeta')
          .doc('trainingProgress')
          .get();
      if (!doc.exists) return;

      final progressAfter = TrainingProgressModel.fromJson(
        user.uid,
        doc.data() ?? <String, dynamic>{},
      );

      final int earned = _xpEarned;

      if (widget.session.id != null && widget.session.id!.isNotEmpty) {
        final sessionRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('trainingSessions')
            .doc(widget.session.id);

        await sessionRef.set(
          {
            'xpEarned': earned,
            if (widget.session.cycleId == null ||
                widget.session.cycleId!.isEmpty)
              'cycleId': progressAfter.currentCycleId,
          },
          SetOptions(merge: true),
        );
      }

      final beforeProgress = progressAfter.copyWith(
        totalXp:
        (progressAfter.totalXp - earned).clamp(0, progressAfter.totalXp),
        xpSinceLastCheck: (progressAfter.xpSinceLastCheck - earned)
            .clamp(0, progressAfter.cycleSize),
      );

      final previousBest =
      await _fetchPreviousSession(user.uid, widget.session);

      final reportModel = TrainingReportBuilder.build(
        context: context, // 🔹 context 추가
        session: widget.session,
        progressBefore: beforeProgress,
        progressAfter: progressAfter,
      );

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
        tier: widget.tier,
        onClose: () => Navigator.of(context).pop(),
        onGoHistory: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TrainingHistoryScreen(),
            ),
          );
        },
        onGoNextDrill: null,
        onGoRatingCheck: null,
      );
    } catch (e) {
      debugPrint('Training report overlay error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final session = widget.session;
    final drill = widget.drill;
    final tier = widget.tier;

    // 현재 기기의 언어 코드 확인 (ko, ja, en 등)
    final String locale = Localizations.localeOf(context).languageCode;

    // 🔹 다국어 텍스트 선택 헬퍼
    String getTitle() {
      if (locale == 'ja') return drill.titleJa;
      if (locale == 'zh') {
        final script = Localizations.localeOf(context).scriptCode;
        return script == 'Hant' ? drill.titleZhHant : drill.titleZhHans;
      }
      return drill.titleKo; // 기본 한국어
    }

    String getDesc() {
      if (locale == 'ja') return drill.shortDescriptionJa;
      if (locale == 'zh') {
        final script = Localizations.localeOf(context).scriptCode;
        return script == 'Hant' ? drill.shortDescriptionZhHant : drill.shortDescriptionZhHans;
      }
      return drill.shortDescriptionKo;
    }

    final mode = session.inputModeString;
    final duration = session.endedAt.difference(session.startedAt);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(s.result_title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    getTitle(), // 🔹 다국어 타이틀
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ChipLabel(
                        label: s.menu_quick_profile,
                        value: tier.name.toUpperCase(),
                      ),
                      const SizedBox(width: 8),
                      _ChipLabel(
                        label: s.filter_all,
                        value: drill.category.name.toUpperCase(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getDesc(), // 🔹 다국어 설명
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
                  Text(
                    s.result_summary_title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _RowItem(
                    label: s.result_stat_attempts,
                    value:
                    '${session.totalAttempts}${s.drill_stat_darts} (${session.totalRounds}R)',
                  ),
                  if (session.hitRate != null)
                    _RowItem(
                      label: s.stat_avg_hitrate,
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
                    label: s.stat_total_time,
                    value: minutes > 0
                        ? '$minutes${s.result_time_min} $seconds${s.result_time_sec}'
                        : '$seconds${s.result_time_sec}',
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
              child: Text(
                s.common_confirm,
                style: const TextStyle(
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

class _XpResultCard extends StatelessWidget {
  final int xp;
  const _XpResultCard({required this.xp});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final bool hasXp = xp > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.result_xp_title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                hasXp ? '+$xp XP' : 'XP 0',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: hasXp ? Colors.cyan.shade600 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              if (hasXp)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    s.result_growth_point,
                    style: const TextStyle(
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
            s.result_xp_desc,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _MainStatsCard extends StatelessWidget {
  final TrainingSessionModel session;
  final String? mode;

  const _MainStatsCard({required this.session, required this.mode});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final inputMode = mode ?? session.inputModeString;

    String title = s.result_summary_title;
    Widget content;

    if (inputMode == 'hitCount') {
      final hitRate = session.hitRate != null ? (session.hitRate! * 100).toStringAsFixed(1) : '--';
      title = s.stat_avg_hitrate;
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(label: s.stat_avg_hitrate, value: '$hitRate%'),
          _BigStat(label: s.stat_success_attempt, value: '${session.successCount} / ${session.totalAttempts}'),
        ],
      );
    } else if (inputMode == 'scoreOnly') {
      title = s.drill_category_scoring;
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(label: 'PPD', value: session.ppd?.toStringAsFixed(2) ?? '--'),
          _BigStat(label: 'Avg', value: session.threeDartAvg?.toStringAsFixed(2) ?? '--'),
        ],
      );
    } else if (inputMode == 'cricketMarks') {
      title = s.drill_unit_marks;
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(label: 'MPR', value: session.mpr?.toStringAsFixed(2) ?? '--'),
          _BigStat(label: s.drill_unit_marks, value: '${session.totalMarksExtra ?? '-'}'),
        ],
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(label: s.drill_stat_darts, value: '${session.totalAttempts}'),
          _BigStat(label: s.drill_stat_rounds, value: '${session.totalRounds}R'),
        ],
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;
  final String value;
  const _ChipLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  const _BigStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  const _RowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100, // 🔹 다국어 고려하여 너비 살짝 조정
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 4),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}