// lib/presentation/screens/training/history/training_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/training/training_history_provider.dart';
import 'package:daoapp/presentation/screens/training/history/training_session_detail_screen.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

import 'widgets/training_history_chart.dart';

class TrainingHistoryScreen extends ConsumerWidget {
  const TrainingHistoryScreen({super.key});

  bool _determineHasProfile(Map<String, dynamic> data) {
    final hasProfile = data['hasProfile'] as bool? ?? false;
    final isPhoneVerified = data['isPhoneVerified'] as bool? ?? false;
    final koreanName = data['koreanName']?.toString().trim();
    return hasProfile &&
        isPhoneVerified &&
        koreanName != null &&
        koreanName.isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildDefaultAppBar(),
        body: _buildLoginPrompt(context),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.grey,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final hasProfile = _determineHasProfile(data);

        if (!hasProfile) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: _buildDefaultAppBar(),
            body: _buildProfilePrompt(context, data),
          );
        }

        return const _TrainingHistoryAuthedBody();
      },
    );
  }

  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: const Text(
        "트레이닝 히스토리",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "히스토리는 로그인 후 이용 가능해요",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "로그인하면 내 연습 기록을 저장하고\n추이를 확인할 수 있어요.",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, RouteConstants.login),
                    child: const Text("로그인 하러 가기"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePrompt(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);

    final hasProfile = data['hasProfile'] as bool? ?? false;
    final isPhoneVerified = data['isPhoneVerified'] as bool? ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  "프로필 등록 후 이용 가능해요",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "기록(히스토리)은 계정 신뢰/중복 방지를 위해\n프로필 등록 유저만 사용할 수 있어요.",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (!hasProfile)
                      const Chip(
                        avatar: Icon(Icons.person_add, size: 18),
                        label: Text("프로필 등록 필요"),
                      ),
                    if (!isPhoneVerified)
                      const Chip(
                        avatar: Icon(Icons.phone_android, size: 18),
                        label: Text("휴대폰 인증 필요"),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                        context, RouteConstants.profileRegister),
                    child: const Text("프로필 등록하러 가기"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainingHistoryAuthedBody extends ConsumerWidget {
  const _TrainingHistoryAuthedBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredTrainingHistoryProvider);
    final allAsync = ref.watch(trainingRecentSessionsProvider);
    final selectedCycleId = ref.watch(selectedCycleIdProvider);

    final allSessions =
    allAsync.maybeWhen(data: (v) => v, orElse: () => <TrainingSessionModel>[]);
    final cycleInfos = _buildCycleInfos(allSessions);

    String _cycleLabelForDelete(String cycleId) {
      final matched = cycleInfos.where((c) => c.cycleId == cycleId).toList();
      if (matched.isNotEmpty) return matched.first.label; // ✅ 등급 라벨
      return _cycleDisplayLabelFromId(cycleId) ?? cycleId;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "트레이닝 히스토리",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
        ),
        actions: [
          if (selectedCycleId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: "이 사이클 전체 삭제",
              onPressed: () => _onDeleteCyclePressed(
                context,
                ref,
                selectedCycleId,
                cycleLabel: _cycleLabelForDelete(selectedCycleId),
              ),
            ),
        ],
      ),
      body: filteredAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator(color: Colors.cyan)),
        error: (e, _) => Center(
          child: Text(
            "불러오기 실패\n$e",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 90, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    selectedCycleId == null
                        ? "아직 연습 기록이 없어요\n지금 바로 시작해볼까요?"
                        : "이 사이클에는 기록이 없어요",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                if (cycleInfos.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _cycleChip(ref, null, "전체", selectedCycleId == null),
                          ...cycleInfos.map(
                                (info) => _cycleChip(
                              ref,
                              info.cycleId,
                              info.label,
                              selectedCycleId == info.cycleId,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.cyan,
                    indicatorWeight: 3.5,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    tabs: const [
                      Tab(text: "추이"),
                      Tab(text: "목록"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TrendTab(sessions: sessions),
                      _ListTab(sessions: sessions),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cycleChip(WidgetRef ref, String? cycleId, String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        selected: selected,
        selectedColor: Colors.cyan.withOpacity(0.22),
        backgroundColor: Colors.grey[200],
        side: BorderSide(
          color: selected ? Colors.cyan : Colors.transparent,
          width: 2,
        ),
        onSelected: (_) =>
        ref.read(selectedCycleIdProvider.notifier).state = cycleId,
      ),
    );
  }
}

Future<void> _onDeleteCyclePressed(
    BuildContext context,
    WidgetRef ref,
    String cycleId, {
      required String cycleLabel,
    }) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text("사이클 삭제"),
        content: Text(
          "‘$cycleLabel’ 사이클에 포함된 모든 연습 기록을\n정말 삭제할까요?\n\n"
              "⚠️ 이 작업은 되돌릴 수 없습니다.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("로그인 정보가 없어 삭제할 수 없어요.")),
    );
    return;
  }

  try {
    final firestore = FirebaseFirestore.instance;

    final query = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('trainingSessions')
        .where('cycleId', isEqualTo: cycleId)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("삭제할 기록이 없어요 ($cycleLabel)")),
      );
      return;
    }

    final batch = firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    ref.read(selectedCycleIdProvider.notifier).state = null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("‘$cycleLabel’ 기록 ${query.docs.length}개가 삭제되었습니다."),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("삭제 중 오류가 발생했습니다: $e")),
    );
  }
}

class _TrendTab extends StatelessWidget {
  final List<TrainingSessionModel> sessions;
  const _TrendTab({required this.sessions});

  @override
  Widget build(BuildContext context) {
    // (네 기존 로직 그대로 유지)
    final hitRates = sessions
        .where((s) => s.inputModeString == 'hitCount' && s.hitRate != null)
        .map((s) => s.hitRate! * 100)
        .toList();

    final ppds = sessions
        .where((s) => s.inputModeString == 'scoreOnly' && s.ppd != null)
        .map((s) => s.ppd!)
        .toList();

    final mprs = sessions
        .where((s) => s.inputModeString == 'cricketMarks' && s.mpr != null)
        .map((s) => s.mpr!)
        .toList();

    double _avg(List<double> list) =>
        list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;
    double _max(List<double> list) =>
        list.isEmpty ? 0.0 : list.reduce((a, b) => a > b ? a : b);

    final avgHitRate = _avg(hitRates);
    final bestHitRate = _max(hitRates);

    final avgPpd = _avg(ppds);
    final bestPpd = _max(ppds);

    final avgMpr = _avg(mprs);
    final bestMpr = _max(mprs);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          TrainingHistoryChart(sessions: sessions),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _SummaryCard(
                  title: "평균 명중률",
                  value: hitRates.isEmpty ? "-" : "${avgHitRate.toStringAsFixed(1)}%",
                  color: Colors.amber.shade700,
                ),
                _SummaryCard(
                  title: "최고 명중률",
                  value: hitRates.isEmpty ? "-" : "${bestHitRate.toStringAsFixed(1)}%",
                  color: Colors.amber[800]!,
                ),
                _SummaryCard(
                  title: "평균 PPD",
                  value: ppds.isEmpty ? "-" : avgPpd.toStringAsFixed(2),
                  color: Colors.cyan,
                ),
                _SummaryCard(
                  title: "최고 PPD",
                  value: ppds.isEmpty ? "-" : bestPpd.toStringAsFixed(2),
                  color: Colors.cyan[700]!,
                ),
                _SummaryCard(
                  title: "평균 MPR",
                  value: mprs.isEmpty ? "-" : avgMpr.toStringAsFixed(2),
                  color: Colors.purple.shade400,
                ),
                _SummaryCard(
                  title: "최고 MPR",
                  value: mprs.isEmpty ? "-" : bestMpr.toStringAsFixed(2),
                  color: Colors.purple.shade700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  final List<TrainingSessionModel> sessions;
  const _ListTab({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      itemCount: sessions.length,
      itemBuilder: (_, i) {
        final s = sessions[i];
        final metric = _buildSessionMetric(s);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TrainingSessionDetailScreen(session: s),
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.cyan[700],
              child: Text(
                s.drillTitle.isNotEmpty ? s.drillTitle[0] : "?",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              s.drillTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${_simpleDate(s.startedAt)}  ·  ${_cycleLabel(s.cycleId)}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  metric.mainValue,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: metric.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.subText,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _simpleDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) {
      return "오늘 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    if (diff == 1) return "어제";
    if (diff < 7) return "$diff일 전";
    return "${dt.month}/${dt.day}";
  }

  String _cycleLabel(String? id) {
    if (id == null || id.isEmpty) return "초기 기록";
    if (id.startsWith("cycle_")) {
      final n = int.tryParse(id.substring(6)) ?? 0;
      return "사이클 $n";
    }
    return id;
  }
}

class _SessionMetric {
  final String mainValue;
  final String subText;
  final Color color;

  _SessionMetric({
    required this.mainValue,
    required this.subText,
    required this.color,
  });
}

_SessionMetric _buildSessionMetric(TrainingSessionModel s) {
  final mode = s.inputModeString;

  if (mode == 'hitCount') {
    final rate = (s.hitRate ?? 0.0) * 100.0;
    final mainValue = "${rate.toStringAsFixed(1)}%";
    final subText = "명중률 · ${s.successCount}/${s.totalAttempts} 다트";
    return _SessionMetric(mainValue: mainValue, subText: subText, color: Colors.amber[700]!);
  }

  if (mode == 'scoreOnly') {
    final ppd = s.ppd ?? 0.0;
    final mainValue = ppd > 0 ? ppd.toStringAsFixed(2) : "-";
    final totalScore = s.totalScoreExtra;
    final subText = totalScore != null ? "PPD · 총점 $totalScore" : "PPD";
    return _SessionMetric(mainValue: mainValue, subText: subText, color: Colors.cyan[700]!);
  }

  if (mode == 'cricketMarks') {
    final mpr = s.mpr ?? 0.0;
    final mainValue = mpr > 0 ? mpr.toStringAsFixed(2) : "-";
    final totalMarks = s.totalMarksExtra;
    final subText = totalMarks != null ? "MPR · 총 Marks $totalMarks" : "MPR";
    return _SessionMetric(mainValue: mainValue, subText: subText, color: Colors.purple[700]!);
  }

  return _SessionMetric(mainValue: "-", subText: "기록 없음", color: Colors.grey[600]!);
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12.5, color: Colors.grey[600])),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// Cycle info (그대로 유지)
// ===============================

class _CycleInfo {
  final String cycleId;
  final DaoTrainingTier? tier;
  final DateTime startAt;
  final int sessionCount;

  const _CycleInfo({
    required this.cycleId,
    required this.tier,
    required this.startAt,
    required this.sessionCount,
  });

  String get label => _tierDisplayLabel(tier);
}

String _tierDisplayLabel(DaoTrainingTier? tier) {
  if (tier == null) return '기타 사이클';

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

List<_CycleInfo> _buildCycleInfos(List<TrainingSessionModel> sessions) {
  final Map<String, _CycleInfo> map = {};

  for (final s in sessions) {
    final id = s.cycleId;
    if (id == null || id.isEmpty) continue;

    final existing = map[id];
    if (existing == null) {
      map[id] = _CycleInfo(
        cycleId: id,
        tier: s.tierAtThatTime,
        startAt: s.startedAt,
        sessionCount: 1,
      );
    } else {
      final earliest =
      s.startedAt.isBefore(existing.startAt) ? s.startedAt : existing.startAt;
      map[id] = _CycleInfo(
        cycleId: id,
        tier: existing.tier,
        startAt: earliest,
        sessionCount: existing.sessionCount + 1,
      );
    }
  }

  final list = map.values.toList();
  list.sort((a, b) => b.startAt.compareTo(a.startAt));
  return list;
}

String? _cycleDisplayLabelFromId(String? id) {
  if (id == null || id.isEmpty) return null;
  if (id.startsWith('cycle_')) {
    final n = int.tryParse(id.substring(6));
    if (n != null) return '사이클 $n';
  }
  return id;
}
