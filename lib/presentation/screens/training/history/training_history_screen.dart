// lib/presentation/screens/training/history/training_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/providers/training/training_history_provider.dart';
import 'package:daoapp/presentation/screens/training/history/training_session_detail_screen.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/data/models/training_session_model.dart';

// 🔹 우리가 만든 그래프 위젯
import 'widgets/training_history_chart.dart';

class TrainingHistoryScreen extends ConsumerWidget {
  const TrainingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredTrainingHistoryProvider);
    final allAsync = ref.watch(trainingRecentSessionsProvider);
    final selectedCycleId = ref.watch(selectedCycleIdProvider);

    // 🔹 전체 세션에서 사이클 목록 뽑기
    final allSessions = allAsync.maybeWhen(
      data: (value) => value,
      orElse: () => <TrainingSessionModel>[],
    );

    final cycleInfos = _buildCycleInfos(allSessions);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "트레이닝 히스토리",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 8),

          // 🔹 사이클 선택 영역
          if (cycleInfos.isNotEmpty)
            SizedBox(
              height: 60,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                children: [
                  // 전체 보기 Chip
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text("전체"),
                      selected: selectedCycleId == null,
                      onSelected: (_) {
                        ref.read(selectedCycleIdProvider.notifier).state = null;
                      },
                    ),
                  ),
                  // 사이클별 Chip
                  for (final info in cycleInfos)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(info.label),
                        selected: selectedCycleId == info.cycleId,
                        onSelected: (_) {
                          ref.read(selectedCycleIdProvider.notifier).state =
                              info.cycleId;
                        },
                      ),
                    ),
                ],
              ),
            ),

          // 🔹 Divider
          const Divider(height: 1),

          // 🔹 그래프 + 히스토리 리스트
          Expanded(
            child: filteredAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "아직 이 구간에 저장된 트레이닝 기록이 없습니다.\n연습을 시작해보세요!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 🔹 sessions가 있을 때: 위에는 그래프, 아래는 리스트
                return Column(
                  children: [
                    // ===== 그래프 영역 =====
                    SizedBox(
                      height: 220,
                      child: TrainingHistoryChart(
                        sessions: sessions,
                      ),
                    ),

                    const Divider(height: 1),

                    // ===== 리스트 영역 =====
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final s = sessions[index];

                          final double hitRate = s.hitRate ?? 0.0;
                          final String hitRateText =
                          (hitRate * 100).toStringAsFixed(1);

                          final int successCount = s.successCount;
                          final int totalAttempts = s.totalAttempts;

                          final Color rateColor = hitRate >= 0.7
                              ? (Colors.cyan[700]!)
                              : hitRate >= 0.5
                              ? (Colors.green[600]!)
                              : (Colors.orange[700]!);

                          final String tierLabel =
                          s.tierAtThatTime.name.toUpperCase();
                          final String? cycleLabel =
                          _cycleDisplayLabelFromId(s.cycleId);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TrainingSessionDetailScreen(
                                          session: s,
                                        ),
                                  ),
                                );
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.cyan[700],
                                  child: Text(
                                    s.drillTitle.isNotEmpty
                                        ? s.drillTitle[0]
                                        : "?",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  s.drillTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      "${_formatDateTime(s.startedAt)} ~ ${_formatDateTime(s.endedAt)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          "티어: $tierLabel",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "XP +${s.xpEarned}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.deepPurple[400],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (cycleLabel != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            "($cycleLabel)",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "$hitRateText%",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                        color: rateColor,
                                      ),
                                    ),
                                    Text(
                                      "$successCount/$totalAttempts 다트",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Colors.cyan,
                ),
              ),
              error: (e, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "기록을 불러오지 못했습니다",
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$e",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 히스토리 상단에서 사용할 사이클 요약 정보
class _CycleInfo {
  final String cycleId;
  final String label; // 예: "사이클 1"
  final DateTime startAt;
  final int sessionCount;

  _CycleInfo({
    required this.cycleId,
    required this.label,
    required this.startAt,
    required this.sessionCount,
  });
}

/// 세션 리스트에서 사이클 정보를 추출
List<_CycleInfo> _buildCycleInfos(List<TrainingSessionModel> sessions) {
  final Map<String, _CycleInfo> map = {};

  for (final s in sessions) {
    final id = s.cycleId;
    if (id == null || id.isEmpty) {
      // 🔹 cycleId 없는 옛 기록은 “초기 기록” 같은 이름으로 묶고 싶다면
      //   별도 그룹을 만들 수도 있음. (지금은 사이클 목록에 안 넣음)
      continue;
    }

    final existing = map[id];
    if (existing == null) {
      map[id] = _CycleInfo(
        cycleId: id,
        label: _cycleDisplayLabelFromId(id) ?? id,
        startAt: s.startedAt,
        sessionCount: 1,
      );
    } else {
      final earliest = s.startedAt.isBefore(existing.startAt)
          ? s.startedAt
          : existing.startAt;
      map[id] = _CycleInfo(
        cycleId: id,
        label: existing.label,
        startAt: earliest,
        sessionCount: existing.sessionCount + 1,
      );
    }
  }

  final list = map.values.toList();
  list.sort((a, b) => a.cycleId.compareTo(b.cycleId));
  return list;
}

/// cycleId → "사이클 1" 같은 표시용 텍스트로 변환
String? _cycleDisplayLabelFromId(String? id) {
  if (id == null || id.isEmpty) return null;
  if (id.startsWith('cycle_')) {
    final numStr = id.substring(6);
    final n = int.tryParse(numStr);
    if (n != null) {
      return '사이클 $n';
    }
  }
  return id;
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}
