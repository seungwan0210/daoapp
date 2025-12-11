// lib/presentation/screens/training/history/training_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/presentation/providers/training/training_history_provider.dart';
import 'package:daoapp/presentation/screens/training/history/training_session_detail_screen.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart'; // DaoTrainingTier 사용

// 우리가 만든 듀얼축 그래프
import 'widgets/training_history_chart.dart';

class TrainingHistoryScreen extends ConsumerWidget {
  const TrainingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredTrainingHistoryProvider);
    final allAsync = ref.watch(trainingRecentSessionsProvider);
    final selectedCycleId = ref.watch(selectedCycleIdProvider);

    // 전체 세션에서 사이클 목록 추출
    final allSessions =
    allAsync.maybeWhen(data: (v) => v, orElse: () => <TrainingSessionModel>[]);
    final cycleInfos = _buildCycleInfos(allSessions);

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
          // 🔥 선택된 사이클이 있을 때만 "사이클 삭제" 버튼 표시
          if (selectedCycleId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: "이 사이클 전체 삭제",
              onPressed: () => _onDeleteCyclePressed(
                context,
                ref,
                selectedCycleId,
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
                // 사이클 선택 칩 (가로 스크롤)
                if (cycleInfos.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _cycleChip(
                            ref,
                            null,
                            "전체",
                            selectedCycleId == null,
                          ),
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

                // 탭바
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

                // 탭 내용
                Expanded(
                  child: TabBarView(
                    children: [
                      // 추이 탭 – 그래프 + 요약
                      _TrendTab(sessions: sessions),

                      // 목록 탭 – 기존 리스트보다 훨씬 깔끔한 카드
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

  Widget _cycleChip(
      WidgetRef ref, String? cycleId, String label, bool selected) {
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

// MARK: - 사이클 삭제 로직 (A안: 실제 삭제)

Future<void> _onDeleteCyclePressed(
    BuildContext context,
    WidgetRef ref,
    String cycleId,
    ) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text("사이클 삭제"),
        content: Text(
          "사이클 '$cycleId'에 포함된 모든 연습 기록을\n정말 삭제할까요?\n\n"
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
            child: const Text(
              "삭제",
              style: TextStyle(color: Colors.red),
            ),
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

    // 🔥 경로는 네가 쓰는 실제 컬렉션 구조에 맞게 조정해도 됨.
    // 예시: users/{uid}/trainingSessions 컬렉션
    final query = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('trainingSessions')
        .where('cycleId', isEqualTo: cycleId)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("삭제할 기록이 없어요 (cycleId: $cycleId)")),
      );
      return;
    }

    final batch = firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // 선택 초기화
    ref.read(selectedCycleIdProvider.notifier).state = null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "사이클 '$cycleId'의 연습 기록 ${query.docs.length}개가 삭제되었습니다.",
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("삭제 중 오류가 발생했습니다: $e")),
    );
  }
}

// MARK: - 추이 탭

class _TrendTab extends StatelessWidget {
  final List<TrainingSessionModel> sessions;
  const _TrendTab({required this.sessions});

  @override
  Widget build(BuildContext context) {
    // 🔹 모드별로 나눠서 평균/최고 계산
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
          // 🔹 메인 그래프 (하루 평균, 최근 7일)
          TrainingHistoryChart(sessions: sessions),

          // 🔹 요약 카드들
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
                  value:
                  hitRates.isEmpty ? "-" : "${avgHitRate.toStringAsFixed(1)}%",
                  color: Colors.amber.shade700,
                ),
                _SummaryCard(
                  title: "최고 명중률",
                  value:
                  hitRates.isEmpty ? "-" : "${bestHitRate.toStringAsFixed(1)}%",
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

// MARK: - 목록 탭

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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
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

// MARK: - 목록용 Metric 계산 (hitRate / PPD / MPR 분기)

class _SessionMetric {
  final String mainValue; // 예: "72.5%", "27.31", "2.43"
  final String subText; // 예: "명중률 / 12/18 다트", "PPD / 총점 712", "MPR / 총 Marks 42"
  final Color color;

  _SessionMetric({
    required this.mainValue,
    required this.subText,
    required this.color,
  });
}

_SessionMetric _buildSessionMetric(TrainingSessionModel s) {
  final mode = s.inputModeString;

  // 🔹 hitCount: 명중률 → 명중률 색상은 연한 노랑/주황 계열
  if (mode == 'hitCount') {
    final rate = (s.hitRate ?? 0.0) * 100.0;
    final mainValue = "${rate.toStringAsFixed(1)}%";

    final success = s.successCount;
    final total = s.totalAttempts;
    final subText = "명중률 · $success/$total 다트";

    // 🔥 명중률 색 → 항상 주황/노랑 계열로 통일
    final color = Colors.amber[700]!;

    return _SessionMetric(
      mainValue: mainValue,
      subText: subText,
      color: color,
    );
  }

  // 🔹 scoreOnly: Count-Up → 카운트업은 청록 계열로 통일
  if (mode == 'scoreOnly') {
    final ppd = s.ppd ?? 0.0;
    final mainValue = ppd > 0 ? ppd.toStringAsFixed(2) : "-";
    final totalScore = s.totalScoreExtra;
    final subText =
    totalScore != null ? "PPD · 총점 $totalScore" : "PPD";

    // 🔥 Count-Up 색 → 항상 cyan 계열로 통일
    final color = Colors.cyan[700]!;

    return _SessionMetric(
      mainValue: mainValue,
      subText: subText,
      color: color,
    );
  }

  // 🔹 cricketMarks: MPR → 항상 보라색
  if (mode == 'cricketMarks') {
    final mpr = s.mpr ?? 0.0;
    final mainValue = mpr > 0 ? mpr.toStringAsFixed(2) : "-";
    final totalMarks = s.totalMarksExtra;
    final subText =
    totalMarks != null ? "MPR · 총 Marks $totalMarks" : "MPR";

    // 🔥 MPR 색 → 항상 퍼플
    final color = Colors.purple[700]!;

    return _SessionMetric(
      mainValue: mainValue,
      subText: subText,
      color: color,
    );
  }

  // 🔸 fallback
  final rate = (s.hitRate ?? 0.0) * 100.0;
  final mainValue = rate > 0 ? "${rate.toStringAsFixed(1)}%" : "-";

  return _SessionMetric(
    mainValue: mainValue,
    subText: "기록 없음",
    color: Colors.grey[600]!,
  );
}

// MARK: - 요약 카드

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
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
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
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 기존에 있던 사이클 정보 추출 함수들 (정렬만 잘 유지)

/// ✅ 사이클 = "해당 티어에서 시작한 연습 묶음"
class _CycleInfo {
  final String cycleId;
  final DaoTrainingTier? tier; // ← 이 사이클의 기준 티어
  final DateTime startAt;
  final int sessionCount;

  const _CycleInfo({
    required this.cycleId,
    required this.tier,
    required this.startAt,
    required this.sessionCount,
  });

  /// 칩/라벨에 표시할 문자열
  String get label => _tierDisplayLabel(tier);
}

/// ✅ 티어 → 한글 라벨 매핑
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

/// ✅ cycle_001, cycle_002 ... 묶음별로 "티어 사이클" 정보 만들기
List<_CycleInfo> _buildCycleInfos(List<TrainingSessionModel> sessions) {
  final Map<String, _CycleInfo> map = {};

  for (final s in sessions) {
    final id = s.cycleId;
    if (id == null || id.isEmpty) continue;

    final existing = map[id];
    if (existing == null) {
      // 🔹 이 cycleId 에서 처음 등장한 세션 → 이때의 티어를 대표 티어로 사용
      map[id] = _CycleInfo(
        cycleId: id,
        tier: s.tierAtThatTime, // ← TrainingSessionModel 안에 있는 필드 사용
        startAt: s.startedAt,
        sessionCount: 1,
      );
    } else {
      final earliest =
      s.startedAt.isBefore(existing.startAt) ? s.startedAt : existing.startAt;
      map[id] = _CycleInfo(
        cycleId: id,
        tier: existing.tier, // 이미 잡힌 티어 유지
        startAt: earliest,
        sessionCount: existing.sessionCount + 1,
      );
    }
  }

  final list = map.values.toList();

  // 🔹 "가장 최근에 시작된 사이클" 순으로 정렬 (최신 → 예전)
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
