// lib/presentation/screens/training/history/training_session_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

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

/// 내부에서 쓸 뷰모델
class _DetailViewData {
  final String mainMetricLabel; // PPD / MPR / 명중률
  final String mainMetricUnit; // '' or '%'
  final double? currentMetric; // 현재 값
  final double? previousMetric; // 직전 세션 값 (없으면 null)

  final int successCount;
  final int totalAttempts;
  final double? hitRatePercent; // 성공률 %

  final int xpCurrent; // 현재 사이클에서 누적 XP
  final int xpCycleSize; // 사이클 목표 XP
  final double xpRatio; // 0.0 ~ 1.0

  final DaoTrainingTier? tier; // 당시 티어

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
    _future = _loadDetailData();
  }

  Future<_DetailViewData> _loadDetailData() async {
    final session = widget.session;

    // === 기본 성공/시도, 명중률 계산 ===
    final int successCount = session.successCount;
    final int totalAttempts = session.totalAttempts;
    double? hitRatePercent;

    if (session.hitRate != null) {
      hitRatePercent = session.hitRate! * 100;
    } else if (totalAttempts > 0) {
      hitRatePercent = (successCount / totalAttempts) * 100;
    }

    // === 메인 지표 (PPD / MPR / 명중률) + 이전 기록 ===
    final String mode = session.inputModeString ?? '';
    String mainLabel;
    String mainUnit;
    double? currentMetric;
    double? previousMetric;

    TrainingSessionModel? previousSession;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 직전 같은 드릴 세션 하나 가져오기 (현재보다 앞선 기록 중 가장 최근)
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
      previousMetric =
      (previousSession == null) ? null : _calcMpr(previousSession);
    } else if (mode == 'scoreOnly') {
      mainLabel = 'PPD';
      mainUnit = '';
      currentMetric = _calcPpd(session);
      previousMetric =
      (previousSession == null) ? null : _calcPpd(previousSession);
    } else {
      mainLabel = '명중률';
      mainUnit = '%';
      final hrNow = _calcHitRate(session);
      currentMetric = hrNow == null ? null : hrNow * 100;

      final hrPrev = previousSession == null ? null : _calcHitRate(previousSession);
      previousMetric = hrPrev == null ? null : hrPrev * 100;
    }

    // === XP 게이지 (trainingProgress 기준) ===
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
        if (xpCycleSize > 0) {
          xpRatio = xpCurrent / xpCycleSize;
        }
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
    final session = widget.session;
    final dateText = _formatDateTime(session.endedAt);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "트레이닝 상세",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: FutureBuilder<_DetailViewData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.cyan),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  "기록을 불러오는 중 문제가 발생했습니다.\n${snapshot.error ?? ''}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final data = snapshot.data!;
            final tier = data.tier;
            final mainMetricText =
            _formatMetric(data.currentMetric, data.mainMetricUnit);
            final mainMetricLabel = data.mainMetricLabel;

            final successCount = data.successCount;
            final totalAttempts = data.totalAttempts;
            final hitRatePercent = data.hitRatePercent;

            final successLine = (hitRatePercent != null && totalAttempts > 0)
                ? "${hitRatePercent.toStringAsFixed(1)}%  ($successCount/$totalAttempts 다트)"
                : totalAttempts > 0
                ? "$successCount/$totalAttempts 다트"
                : "기록 없음";

            final xpCurrent = data.xpCurrent;
            final xpCycleSize = data.xpCycleSize;
            final xpRatio = data.xpRatio;
            final xpPercentText = (xpCycleSize > 0)
                ? "${(xpRatio * 100).toStringAsFixed(0)}%"
                : "-";

            final xpLabelText = (xpCycleSize > 0)
                ? "$xpCurrent/$xpCycleSize XP ($xpPercentText)"
                : "XP 정보 없음";

            final summaryText = _buildSummaryText(
              mainMetricLabel: mainMetricLabel,
              currentMetric: data.currentMetric,
              previousMetric: data.previousMetric,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                // ===== 헤더: 드릴 제목 + 날짜 + 메인 지표 (PPD / MPR / 명중률) =====
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 드릴 제목
                        Text(
                          session.drillTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // 날짜
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 18),
                        // 메인 지표 (예: PPD: 24.1)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "$mainMetricLabel:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mainMetricText,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: _metricColor(mainMetricLabel),
                              ),
                            ),
                            if (mainMetricLabel == '명중률')
                              const Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== 성공률 한 줄 =====
                AppCard(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 20,
                          color: Colors.cyan[700],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            successLine,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== XP 게이지 + 티어 뱃지 =====
                AppCard(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상단 라인: "성장 게이지" + 티어 배지
                        Row(
                          children: [
                            const Text(
                              "성장 게이지",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            if (tier != null) _TierBadge(tier: tier),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: xpRatio,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              tier != null
                                  ? _gaugeColorForTier(tier)
                                  : Colors.cyan,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          xpLabelText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== 요약 문장 =====
                AppCard(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text(
                      summaryText,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // (옵션) 드릴 ID / 사이클 / 시간 등 메타 정보 - 작게
                AppCard(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "세부 정보",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _MetaRow(
                          label: "드릴 ID",
                          value: session.drillId,
                        ),
                        _MetaRow(
                          label: "사이클",
                          value: _cycleDisplayLabelFromId(session.cycleId) ?? "-",
                        ),
                        _MetaRow(
                          label: "총 시도",
                          value:
                          "${session.totalAttempts}회 (${session.totalRounds}R)",
                        ),
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
}

/// ==== 메트릭 / 요약 관련 헬퍼 ====

// 명중률
double? _calcHitRate(TrainingSessionModel s) {
  if (s.hitRate != null) return s.hitRate;
  if (s.totalAttempts <= 0) return null;
  return s.successCount / s.totalAttempts;
}

// MPR
double? _calcMpr(TrainingSessionModel s) => s.mpr;

// PPD (없으면 totalScoreExtra 로 계산)
double? _calcPpd(TrainingSessionModel s) {
  if (s.ppd != null) return s.ppd;
  final int? totalScore = s.totalScoreExtra;
  if (totalScore == null || s.totalAttempts <= 0) return null;
  final double darts = s.totalAttempts.toDouble();
  return (totalScore / darts) * 3.0;
}

String _formatMetric(double? value, String unit) {
  if (value == null) return "—";
  final String text;
  if (unit == '%') {
    text = value.toStringAsFixed(1);
  } else {
    text = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return unit.isEmpty ? text : "$text$unit";
}

Color _metricColor(String label) {
  switch (label) {
    case 'PPD':
      return Colors.cyan[700]!;
    case 'MPR':
      return Colors.purple[700]!;
    case '명중률':
      return Colors.amber[800]!;
    default:
      return Colors.black87;
  }
}

String _buildSummaryText({
  required String mainMetricLabel,
  required double? currentMetric,
  required double? previousMetric,
}) {
  // 기록 자체가 없는 경우
  if (currentMetric == null) {
    return "이번 세션의 $mainMetricLabel 기록이 아직 충분하지 않아요.\n"
        "다음 연습에서 한 번 더 같은 드릴을 진행해보면, 변화가 더 잘 보일 거예요.";
  }

  // 이전 기록이 없는 첫 세션
  if (previousMetric == null) {
    return "$mainMetricLabel 첫 기록입니다.\n"
        "앞으로 이 수치를 기준으로 성장 그래프와 히스토리가 쌓이게 돼요.\n"
        "🔥 오늘의 미션: 같은 드릴을 한 번 더 진행해서 '내 기준 기록'을 만들어보세요.";
  }

  final diff = currentMetric - previousMetric;
  final improved = diff > 0;
  final absDiff = diff.abs();

  String diffText;
  if (mainMetricLabel == '명중률') {
    diffText = "${absDiff.toStringAsFixed(1)}%";
  } else {
    diffText = absDiff.toStringAsFixed(2);
  }

  if (improved) {
    return "$mainMetricLabel +$diffText 상승! 🔥\n"
        "이전 세션보다 분명히 나아졌어요.\n"
        "지금 템포와 리듬을 한 번 더 유지해서 '연속 상승'에 도전해볼까요?";
  } else if (absDiff < 0.01) {
    return "$mainMetricLabel 변화 거의 없음.\n"
        "이건 오히려 '내 평균 페이스'를 찾고 있다는 신호예요.\n"
        "조금 다른 루틴이나 호흡으로 같은 드릴을 한 번 더 시도해보는 것도 좋아요.";
  } else {
    return "$mainMetricLabel -$diffText 하락.\n"
        "하지만 XP와 연습량은 그대로 쌓이고 있습니다.\n"
        "오늘은 여기서 마무리하고, 다른 유형 드릴로 한 번 더 몸을 풀어준 뒤\n"
        "다음 사이클에서 다시 이 드릴에 도전해보는 건 어떨까요?";
  }
}

/// ==== 티어 관련 ====

Color _gaugeColorForTier(DaoTrainingTier tier) {
  switch (tier) {
    case DaoTrainingTier.master:
      return Colors.deepPurpleAccent;
    case DaoTrainingTier.pro:
      return Colors.redAccent;
    case DaoTrainingTier.elite:
      return Colors.orange;
    case DaoTrainingTier.challenger:
      return Colors.green;
    case DaoTrainingTier.competitor:
      return Colors.teal;
    case DaoTrainingTier.learner:
      return Colors.blue;
    case DaoTrainingTier.beginner:
    default:
      return const Color(0xFFFF8EC7); // 비기너 핑크
  }
}

String _tierLabelKo(DaoTrainingTier tier) {
  switch (tier) {
    case DaoTrainingTier.beginner:
      return '비기너';
    case DaoTrainingTier.learner:
      return '러너';
    case DaoTrainingTier.competitor:
      return '컴페티터';
    case DaoTrainingTier.challenger:
      return '첼린저';
    case DaoTrainingTier.elite:
      return '엘리트';
    case DaoTrainingTier.pro:
      return '프로';
    case DaoTrainingTier.master:
      return '마스터';
  }
}

class _TierBadge extends StatelessWidget {
  final DaoTrainingTier tier;

  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final label = _tierLabelKo(tier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _gaugeColorForTier(tier).withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _gaugeColorForTier(tier).withOpacity(0.6),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.military_tech_rounded,
            size: 14,
            color: _gaugeColorForTier(tier),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _gaugeColorForTier(tier),
            ),
          ),
        ],
      ),
    );
  }
}

/// ==== 기타 공용 ====

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

String? _cycleDisplayLabelFromId(String? id) {
  if (id == null || id.isEmpty) return null;
  if (id.startsWith('cycle_')) {
    final numStr = id.substring(6);
    final n = int.tryParse(numStr);
    if (n != null) return '사이클 $n';
  }
  return id;
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
