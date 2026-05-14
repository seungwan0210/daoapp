import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class TrainingSessionDetailScreen extends StatefulWidget {
  final TrainingSessionModel session;

  const TrainingSessionDetailScreen({
    super.key,
    required this.session,
  });

  @override
  State<TrainingSessionDetailScreen> createState() =>
      _TrainingSessionDetailScreenState();
}

class _DetailViewData {
  final String mainMetricLabel;
  final String mainMetricUnit;
  final double? currentMetric;
  final double? previousMetric;
  final int successCount;
  final int totalAttempts;
  final double? hitRatePercent;
  final int xpCurrent;
  final int xpCycleSize;
  final double xpRatio;
  final DaoTrainingTier? tier;

  const _DetailViewData({
    required this.mainMetricLabel,
    required this.mainMetricUnit,
    required this.currentMetric,
    required this.previousMetric,
    required this.successCount,
    required this.totalAttempts,
    required this.hitRatePercent,
    required this.xpCurrent,
    required this.xpCycleSize,
    required this.xpRatio,
    required this.tier,
  });
}

class _TrainingSessionDetailScreenState
    extends State<TrainingSessionDetailScreen> {
  late Future<_DetailViewData> _future;

  @override
  void initState() {
    super.initState();
    // 🔹 initState에서는 context를 쓸 수 없으므로, build에서 s를 쓰거나 지연 로딩 처리
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _loadDetailData();
  }

  Future<_DetailViewData> _loadDetailData() async {
    final session = widget.session;
    final s = AppLocalizations.of(context)!;

    final int successCount = session.successCount;
    final int totalAttempts = session.totalAttempts;
    double? hitRatePercent;

    if (session.hitRate != null) {
      hitRatePercent = session.hitRate! * 100;
    } else if (totalAttempts > 0) {
      hitRatePercent = (successCount / totalAttempts) * 100;
    }

    final String mode = session.inputModeString ?? '';
    String mainLabel;
    String mainUnit;
    double? currentMetric;
    double? previousMetric;

    TrainingSessionModel? previousSession;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trainingSessions')
          .where('drillId', isEqualTo: session.drillId)
          .where('endedAt', isLessThan: session.endedAt)
          .orderBy('endedAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        previousSession = TrainingSessionModel.fromJson(doc.id, doc.data());
      }
    }

    if (mode == 'cricketMarks') {
      mainLabel = 'MPR';
      mainUnit = '';
      currentMetric = _calcMpr(session);
      previousMetric = (previousSession == null) ? null : _calcMpr(previousSession);
    } else if (mode == 'scoreOnly') {
      mainLabel = 'PPD';
      mainUnit = '';
      currentMetric = _calcPpd(session);
      previousMetric = (previousSession == null) ? null : _calcPpd(previousSession);
    } else {
      mainLabel = s.drill_stat_hit_rate;
      mainUnit = '%';
      final hrNow = _calcHitRate(session);
      currentMetric = hrNow == null ? null : hrNow * 100;
      final hrPrev = previousSession == null ? null : _calcHitRate(previousSession);
      previousMetric = hrPrev == null ? null : hrPrev * 100;
    }

    int xpCurrent = 0;
    int xpCycleSize = 0;
    double xpRatio = 0.0;

    if (user != null) {
      final progressDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trainingMeta')
          .doc('trainingProgress')
          .get();

      if (progressDoc.exists) {
        final progress = TrainingProgressModel.fromJson(
          user.uid,
          progressDoc.data() ?? <String, dynamic>{},
        );
        xpCurrent = progress.xpSinceLastCheck;
        xpCycleSize = progress.cycleSize;
        if (xpCycleSize > 0) xpRatio = xpCurrent / xpCycleSize;
      }
    }

    return _DetailViewData(
      mainMetricLabel: mainLabel,
      mainMetricUnit: mainUnit,
      currentMetric: currentMetric,
      previousMetric: previousMetric,
      successCount: successCount,
      totalAttempts: totalAttempts,
      hitRatePercent: hitRatePercent,
      xpCurrent: xpCurrent,
      xpCycleSize: xpCycleSize,
      xpRatio: xpRatio.clamp(0.0, 1.0),
      tier: session.tierAtThatTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final session = widget.session;
    final dateText = _formatDateTime(session.endedAt);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(s.detail_title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: FutureBuilder<_DetailViewData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyan));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text("${s.detail_error_load}\n${snapshot.error ?? ''}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)));
            }

            final data = snapshot.data!;
            final tier = data.tier;
            final mainMetricText = _formatMetric(data.currentMetric, data.mainMetricUnit);
            final mainMetricLabel = data.mainMetricLabel;

            final successLine = (data.hitRatePercent != null && data.totalAttempts > 0)
                ? "${data.hitRatePercent!.toStringAsFixed(1)}%  (${data.successCount}/${data.totalAttempts} ${s.drill_stat_darts})"
                : data.totalAttempts > 0
                ? "${data.successCount}/${data.totalAttempts} ${s.drill_stat_darts}"
                : s.detail_stat_no_record;

            final xpPercentText = (data.xpCycleSize > 0) ? "${(data.xpRatio * 100).toStringAsFixed(0)}%" : "-";
            final xpLabelText = (data.xpCycleSize > 0) ? "${data.xpCurrent}/${data.xpCycleSize} XP ($xpPercentText)" : "—";

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.drillTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                        const SizedBox(height: 6),
                        Text(dateText, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("$mainMetricLabel:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                            const SizedBox(width: 8),
                            Text(mainMetricText, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _metricColor(mainMetricLabel))),
                            if (mainMetricLabel == s.drill_stat_hit_rate) const Text('%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.my_location, size: 20, color: Colors.cyan[700]),
                        const SizedBox(width: 10),
                        Expanded(child: Text(successLine, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(s.detail_growth_gauge, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            if (tier != null) _TierBadge(tier: tier),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: data.xpRatio,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(tier != null ? _gaugeColorForTier(tier) : Colors.cyan),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(xpLabelText, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text(
                      _buildSummaryText(
                        context: context,
                        mainMetricLabel: mainMetricLabel,
                        currentMetric: data.currentMetric,
                        previousMetric: data.previousMetric,
                      ),
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.detail_info_title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        _MetaRow(label: s.detail_info_drill_id, value: session.drillId),
                        _MetaRow(label: s.detail_info_cycle, value: _cycleDisplayLabelFromId(context, session.cycleId) ?? "-"),
                        _MetaRow(label: s.detail_info_total_attempts, value: "${session.totalAttempts}${s.drill_stat_darts} (${session.totalRounds}R)"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  String _buildSummaryText({
    required BuildContext context,
    required String mainMetricLabel,
    required double? currentMetric,
    required double? previousMetric,
  }) {
    final s = AppLocalizations.of(context)!;
    if (currentMetric == null) return s.detail_summary_no_data(mainMetricLabel);
    if (previousMetric == null) return s.detail_summary_first(mainMetricLabel);

    final diff = currentMetric - previousMetric;
    final improved = diff > 0;
    final absDiff = diff.abs();

    final String diffText = (mainMetricLabel == s.drill_stat_hit_rate)
        ? "${absDiff.toStringAsFixed(1)}%"
        : absDiff.toStringAsFixed(2);

    if (improved) {
      return s.detail_summary_up(mainMetricLabel, diffText);
    } else if (absDiff < 0.01) {
      return s.detail_summary_steady(mainMetricLabel);
    } else {
      return s.detail_summary_down(mainMetricLabel, diffText);
    }
  }
}

// (헬퍼 함수들은 이전과 동일하지만 티어 라벨 등은 s.tier_... 사용 권장)
double? _calcHitRate(TrainingSessionModel s) {
  if (s.hitRate != null) return s.hitRate;
  if (s.totalAttempts <= 0) return null;
  return s.successCount / s.totalAttempts;
}
double? _calcMpr(TrainingSessionModel s) => s.mpr;
double? _calcPpd(TrainingSessionModel s) {
  if (s.ppd != null) return s.ppd;
  final int? totalScore = s.totalScoreExtra;
  if (totalScore == null || s.totalAttempts <= 0) return null;
  return (totalScore / s.totalAttempts) * 3.0;
}

String _formatMetric(double? value, String unit) {
  if (value == null) return "—";
  final text = (unit == '%') ? value.toStringAsFixed(1) : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return unit.isEmpty ? text : "$text$unit";
}

Color _metricColor(String label) {
  if (label == 'PPD') return Colors.cyan[700]!;
  if (label == 'MPR') return Colors.purple[700]!;
  return Colors.amber[800]!;
}

Color _gaugeColorForTier(DaoTrainingTier tier) {
  switch (tier) {
    case DaoTrainingTier.master: return Colors.deepPurpleAccent;
    case DaoTrainingTier.pro: return Colors.redAccent;
    case DaoTrainingTier.elite: return Colors.orange;
    case DaoTrainingTier.challenger: return Colors.green;
    case DaoTrainingTier.competitor: return Colors.teal;
    case DaoTrainingTier.learner: return Colors.blue;
    default: return const Color(0xFFFF8EC7);
  }
}

class _TierBadge extends StatelessWidget {
  final DaoTrainingTier tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    String label = "";
    switch (tier) {
      case DaoTrainingTier.beginner: label = s.tier_beginner; break;
      case DaoTrainingTier.learner: label = s.tier_learner; break;
      case DaoTrainingTier.competitor: label = s.tier_competitor; break;
      case DaoTrainingTier.challenger: label = s.tier_challenger; break;
      case DaoTrainingTier.elite: label = s.tier_elite; break;
      case DaoTrainingTier.pro: label = s.tier_pro; break;
      case DaoTrainingTier.master: label = s.tier_master; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _gaugeColorForTier(tier).withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _gaugeColorForTier(tier).withOpacity(0.6), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech_rounded, size: 14, color: _gaugeColorForTier(tier)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _gaugeColorForTier(tier))),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2,'0')}-${local.day.toString().padLeft(2,'0')} ${local.hour.toString().padLeft(2,'0')}:${local.minute.toString().padLeft(2,'0')}';
}

String? _cycleDisplayLabelFromId(BuildContext context, String? id) {
  final s = AppLocalizations.of(context)!;
  if (id == null || id.isEmpty) return null;
  if (id.startsWith('cycle_')) {
    return s.history_cycle_label(id.substring(6));
  }
  return id;
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600))),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}