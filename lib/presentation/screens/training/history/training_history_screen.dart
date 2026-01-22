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

  // 프로필 정보가 유효한지 확인
  bool _determineHasProfile(Map<String, dynamic> data) {
    final hasProfile = data['hasProfile'] as bool? ?? false;
    final isPhoneVerified = data['isPhoneVerified'] as bool? ?? false;
    final koreanName = data['koreanName']?.toString().trim();
    return hasProfile && isPhoneVerified && koreanName != null && koreanName.isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    // 1. 비로그인 상태
    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildDefaultAppBar(),
        body: _buildLoginPrompt(context),
      );
    }

    // 2. 로그인 상태 -> 프로필 확인
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.grey,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final hasProfile = _determineHasProfile(data);

        // 3. 프로필 미등록 상태
        if (!hasProfile) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: _buildDefaultAppBar(),
            body: _buildProfilePrompt(context, data),
          );
        }

        // 4. 정상 진입
        return const _TrainingHistoryAuthedBody();
      },
    );
  }

  AppBar _buildDefaultAppBar() {
    return AppBar(
      title: const Text("트레이닝 히스토리", style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0))),
    );
  }

  // 🔒 로그인 유도 화면
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              "로그인이 필요해요",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "내 연습 기록을 저장하고 추이를 확인하려면\n로그인이 필요합니다.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, RouteConstants.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[600],
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("로그인 하러 가기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👤 프로필 등록 유도 화면
  Widget _buildProfilePrompt(BuildContext context, Map<String, dynamic> data) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              "프로필 등록이 필요해요",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "기록의 신뢰성을 위해 프로필 등록 유저만\n히스토리 기능을 사용할 수 있습니다.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, RouteConstants.profileRegister),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[600],
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("프로필 등록하러 가기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
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

    final allSessions = allAsync.maybeWhen(data: (v) => v, orElse: () => <TrainingSessionModel>[]);
    final cycleInfos = _buildCycleInfos(allSessions);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("트레이닝 히스토리", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0))),
        actions: [
          if (selectedCycleId != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              tooltip: "이 사이클 전체 삭제",
              onPressed: () => _onDeleteCyclePressed(context, ref, selectedCycleId),
            ),
        ],
      ),
      body: filteredAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
        error: (e, _) => Center(child: Text("불러오기 실패\n$e")),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Text(
                selectedCycleId == null ? "아직 연습 기록이 없어요." : "이 사이클엔 기록이 없어요.",
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // 1. 사이클 필터 칩
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
                          ...cycleInfos.map((info) => _cycleChip(
                            ref,
                            info.cycleId,
                            info.label,
                            selectedCycleId == info.cycleId,
                          )),
                        ],
                      ),
                    ),
                  ),

                // 2. 탭 바
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.cyan,
                    indicatorWeight: 3.5,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    tabs: const [Tab(text: "추이"), Tab(text: "목록")],
                  ),
                ),

                // 3. 탭 내용
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
        label: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.w600)),
        selected: selected,
        selectedColor: Colors.cyan.withOpacity(0.22),
        backgroundColor: Colors.grey[200],
        side: BorderSide(color: selected ? Colors.cyan : Colors.transparent, width: 2),
        onSelected: (_) => ref.read(selectedCycleIdProvider.notifier).state = cycleId,
      ),
    );
  }
}

// ==============================================================================
// 📋 [목록 탭] - 삭제 기능 및 팁 추가
// ==============================================================================
class _ListTab extends ConsumerWidget {
  final List<TrainingSessionModel> sessions;
  const _ListTab({required this.sessions});

  // 🗑️ 개별 삭제 로직
  Future<void> _deleteSession(BuildContext context, WidgetRef ref, TrainingSessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("기록 삭제"),
        content: const Text(
          "이 연습 기록을 정말 삭제하시겠습니까?\n서버에서도 영구적으로 삭제됩니다.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("삭제", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trainingSessions')
          .doc(session.id)
          .delete();

      // 목록 새로고침
      ref.invalidate(trainingRecentSessionsProvider);
      ref.invalidate(filteredTrainingHistoryProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("기록이 삭제되었습니다.")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("삭제 실패: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 💡 팁 박스
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                "Tip. 목록을 길게 누르면 기록을 삭제할 수 있어요.",
                style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        // 리스트
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: sessions.length,
            itemBuilder: (_, i) {
              final s = sessions[i];
              final metric = _buildSessionMetric(s);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  // 👆 클릭: 상세 이동
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TrainingSessionDetailScreen(session: s)),
                  ),
                  // 👇 꾹 누르기: 삭제
                  onLongPress: () => _deleteSession(context, ref, s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.cyan[700],
                          radius: 20,
                          child: Text(
                            s.drillTitle.isNotEmpty ? s.drillTitle[0] : "?",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.drillTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${_simpleDate(s.startedAt)}  ·  ${_cycleLabel(s.cycleId)}",
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              metric.mainValue,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: metric.color),
                            ),
                            Text(
                              metric.subText,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
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
  }

  String _simpleDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return "오늘 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
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

// ==============================================================================
// 📈 [추이 탭]
// ==============================================================================
class _TrendTab extends StatelessWidget {
  final List<TrainingSessionModel> sessions;
  const _TrendTab({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final hitRates = sessions
        .where((s) => s.inputModeString == 'hitCount' && s.hitRate != null)
        .map((s) => s.hitRate! * 100).toList();
    final ppds = sessions
        .where((s) => s.inputModeString == 'scoreOnly' && s.ppd != null)
        .map((s) => s.ppd!).toList();
    final mprs = sessions
        .where((s) => s.inputModeString == 'cricketMarks' && s.mpr != null)
        .map((s) => s.mpr!).toList();

    double _avg(List<double> list) => list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;
    double _max(List<double> list) => list.isEmpty ? 0.0 : list.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      child: Column(
        children: [
          TrainingHistoryChart(sessions: sessions),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _SummaryCard(title: "평균 명중률", value: hitRates.isEmpty ? "-" : "${_avg(hitRates).toStringAsFixed(1)}%", color: Colors.amber.shade700),
                _SummaryCard(title: "최고 명중률", value: hitRates.isEmpty ? "-" : "${_max(hitRates).toStringAsFixed(1)}%", color: Colors.amber[800]!),
                _SummaryCard(title: "평균 PPD", value: ppds.isEmpty ? "-" : _avg(ppds).toStringAsFixed(2), color: Colors.cyan),
                _SummaryCard(title: "최고 PPD", value: ppds.isEmpty ? "-" : _max(ppds).toStringAsFixed(2), color: Colors.cyan[700]!),
                _SummaryCard(title: "평균 MPR", value: mprs.isEmpty ? "-" : _avg(mprs).toStringAsFixed(2), color: Colors.purple.shade400),
                _SummaryCard(title: "최고 MPR", value: mprs.isEmpty ? "-" : _max(mprs).toStringAsFixed(2), color: Colors.purple.shade700),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _SessionMetric {
  final String mainValue;
  final String subText;
  final Color color;
  _SessionMetric({required this.mainValue, required this.subText, required this.color});
}

_SessionMetric _buildSessionMetric(TrainingSessionModel s) {
  final mode = s.inputModeString;
  if (mode == 'hitCount') {
    final rate = (s.hitRate ?? 0.0) * 100.0;
    return _SessionMetric(mainValue: "${rate.toStringAsFixed(1)}%", subText: "명중률", color: Colors.amber[700]!);
  }
  if (mode == 'scoreOnly') {
    return _SessionMetric(mainValue: "${s.ppd?.toStringAsFixed(2) ?? '-'}", subText: "PPD", color: Colors.cyan[700]!);
  }
  if (mode == 'cricketMarks') {
    return _SessionMetric(mainValue: "${s.mpr?.toStringAsFixed(2) ?? '-'}", subText: "MPR", color: Colors.purple[700]!);
  }
  return _SessionMetric(mainValue: "-", subText: "-", color: Colors.grey);
}

// ♻️ 사이클 관련 헬퍼
class _CycleInfo {
  final String cycleId;
  final DaoTrainingTier? tier;
  final DateTime startAt;
  final int sessionCount;
  const _CycleInfo({required this.cycleId, required this.tier, required this.startAt, required this.sessionCount});
  String get label => _tierDisplayLabel(tier);
}

String _tierDisplayLabel(DaoTrainingTier? tier) {
  if (tier == null) return '기타';
  switch (tier) {
    case DaoTrainingTier.beginner: return '비기너';
    case DaoTrainingTier.learner: return '러너';
    case DaoTrainingTier.competitor: return '컴페티터';
    case DaoTrainingTier.challenger: return '첼린저';
    case DaoTrainingTier.elite: return '엘리트';
    case DaoTrainingTier.pro: return '프로';
    case DaoTrainingTier.master: return '마스터';
  }
}

List<_CycleInfo> _buildCycleInfos(List<TrainingSessionModel> sessions) {
  final Map<String, _CycleInfo> map = {};
  for (final s in sessions) {
    final id = s.cycleId;
    if (id == null || id.isEmpty) continue;
    final existing = map[id];
    if (existing == null) {
      map[id] = _CycleInfo(cycleId: id, tier: s.tierAtThatTime, startAt: s.startedAt, sessionCount: 1);
    } else {
      map[id] = _CycleInfo(cycleId: id, tier: existing.tier, startAt: s.startedAt.isBefore(existing.startAt) ? s.startedAt : existing.startAt, sessionCount: existing.sessionCount + 1);
    }
  }
  final list = map.values.toList()..sort((a, b) => b.startAt.compareTo(a.startAt));
  return list;
}

// 사이클 전체 삭제 함수
Future<void> _onDeleteCyclePressed(BuildContext context, WidgetRef ref, String cycleId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("사이클 삭제"),
      content: const Text("이 사이클의 모든 기록을 삭제할까요?\n복구할 수 없습니다."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
      ],
    ),
  );
  if (confirmed != true) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final fs = FirebaseFirestore.instance;
    final q = await fs.collection('users').doc(user.uid).collection('trainingSessions').where('cycleId', isEqualTo: cycleId).get();
    final batch = fs.batch();
    for (var doc in q.docs) batch.delete(doc.reference);
    await batch.commit();

    ref.read(selectedCycleIdProvider.notifier).state = null;
    ref.invalidate(trainingRecentSessionsProvider);
    ref.invalidate(filteredTrainingHistoryProvider);

    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사이클이 삭제되었습니다.")));
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류: $e")));
  }
}