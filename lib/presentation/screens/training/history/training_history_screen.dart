import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/training/training_history_provider.dart';
import 'package:daoapp/presentation/screens/training/history/training_session_detail_screen.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

import 'widgets/training_history_chart.dart';

class TrainingHistoryScreen extends ConsumerWidget {
  const TrainingHistoryScreen({super.key});

  bool _determineHasProfile(Map<String, dynamic> data) {
    final hasProfile = data['hasProfile'] as bool? ?? false;
    final isPhoneVerified = data['isPhoneVerified'] as bool? ?? false;
    final koreanName = data['koreanName']?.toString().trim();
    return hasProfile && isPhoneVerified && koreanName != null && koreanName.isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final s = AppLocalizations.of(context)!;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildDefaultAppBar(context),
        body: _buildLoginPrompt(context),
      );
    }

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

        if (!hasProfile) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: _buildDefaultAppBar(context),
            body: _buildProfilePrompt(context),
          );
        }

        return const _TrainingHistoryAuthedBody();
      },
    );
  }

  AppBar _buildDefaultAppBar(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AppBar(
      title: Text(s.history_title, style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0))),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(s.history_login_required, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(s.history_login_msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
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
                child: Text(s.login_title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePrompt(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(s.history_profile_required, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(s.history_profile_msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
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
                child: Text(s.profile_register_btn ?? "Register", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
    final s = AppLocalizations.of(context)!;
    final filteredAsync = ref.watch(filteredTrainingHistoryProvider);
    final allAsync = ref.watch(trainingRecentSessionsProvider);
    final selectedCycleId = ref.watch(selectedCycleIdProvider);

    final allSessions = allAsync.maybeWhen(data: (v) => v, orElse: () => <TrainingSessionModel>[]);
    final cycleInfos = _buildCycleInfos(context, allSessions);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(s.history_title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0))),
        actions: [
          if (selectedCycleId != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              tooltip: "Delete Cycle",
              onPressed: () => _onDeleteCyclePressed(context, ref, selectedCycleId),
            ),
        ],
      ),
      body: filteredAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyan)),
        error: (e, _) => Center(child: Text("${s.rank_load_failed}\n$e")),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Text(
                selectedCycleId == null ? s.history_no_record : s.history_no_cycle_record,
                style: TextStyle(color: Colors.grey[600]),
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
                          _cycleChip(ref, null, s.history_filter_all, selectedCycleId == null),
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

                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.cyan,
                    indicatorWeight: 3.5,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    tabs: [Tab(text: s.history_tab_trend), Tab(text: s.history_tab_list)],
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

class _ListTab extends ConsumerWidget {
  final List<TrainingSessionModel> sessions;
  const _ListTab({required this.sessions});

  Future<void> _deleteSession(BuildContext context, WidgetRef ref, TrainingSessionModel session) async {
    final s = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.history_delete_title),
        content: Text(s.history_delete_msg, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.common_delete, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('trainingSessions').doc(session.id).delete();
      ref.invalidate(trainingRecentSessionsProvider);
      ref.invalidate(filteredTrainingHistoryProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.rank_reset_done)));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sLocal = AppLocalizations.of(context)!;
    return Column(
      children: [
        // 💡 팁 박스 (Expanded 적용으로 오버플로우 해결)
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
            crossAxisAlignment: CrossAxisAlignment.center, // 세로 중앙 정렬
            children: [
              Icon(Icons.touch_app_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              // ✅ Expanded를 사용하여 텍스트가 가로 가용 공간을 넘지 않게 합니다.
              Expanded(
                child: Text(
                  sLocal.history_tip_delete,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  // 일본어의 경우 문장이 길어질 수 있으므로 줄바꿈을 허용하거나
                  // 필요에 따라 한 줄 제한(maxLines: 1)을 둘 수 있습니다.
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: sessions.length,
            itemBuilder: (_, i) {
              final s = sessions[i];
              final metric = _buildSessionMetric(context, s);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TrainingSessionDetailScreen(session: s))),
                  onLongPress: () => _deleteSession(context, ref, s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.cyan[700],
                          radius: 20,
                          child: Text(s.drillTitle.isNotEmpty ? s.drillTitle[0] : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.drillTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text("${_simpleDate(context, s.startedAt)}  ·  ${_cycleLabel(context, s.cycleId)}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(metric.mainValue, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: metric.color)),
                            Text(metric.subText, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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

  String _simpleDate(BuildContext context, DateTime dt) {
    final s = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return "${s.history_date_today} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    if (diff == 1) return s.history_date_yesterday;
    if (diff < 7) return s.history_date_days_ago(diff.toString());
    return "${dt.month}/${dt.day}";
  }

  String _cycleLabel(BuildContext context, String? id) {
    final s = AppLocalizations.of(context)!;
    if (id == null || id.isEmpty) return s.history_initial_record;
    if (id.startsWith("cycle_")) {
      final n = id.substring(6);
      return s.history_cycle_label(n);
    }
    return id;
  }
}

class _TrendTab extends StatelessWidget {
  final List<TrainingSessionModel> sessions;
  const _TrendTab({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final hitRates = sessions.where((s) => s.inputModeString == 'hitCount' && s.hitRate != null).map((s) => s.hitRate! * 100).toList();
    final ppds = sessions.where((s) => s.inputModeString == 'scoreOnly' && s.ppd != null).map((s) => s.ppd!).toList();
    final mprs = sessions.where((s) => s.inputModeString == 'cricketMarks' && s.mpr != null).map((s) => s.mpr!).toList();

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
                _SummaryCard(title: s.history_stat_avg_hit, value: hitRates.isEmpty ? "-" : "${_avg(hitRates).toStringAsFixed(1)}%", color: Colors.amber.shade700),
                _SummaryCard(title: s.history_stat_max_hit, value: hitRates.isEmpty ? "-" : "${_max(hitRates).toStringAsFixed(1)}%", color: Colors.amber[800]!),
                _SummaryCard(title: "Avg PPD", value: ppds.isEmpty ? "-" : _avg(ppds).toStringAsFixed(2), color: Colors.cyan),
                _SummaryCard(title: "Max PPD", value: ppds.isEmpty ? "-" : _max(ppds).toStringAsFixed(2), color: Colors.cyan[700]!),
                _SummaryCard(title: "Avg MPR", value: mprs.isEmpty ? "-" : _avg(mprs).toStringAsFixed(2), color: Colors.purple.shade400),
                _SummaryCard(title: "Max MPR", value: mprs.isEmpty ? "-" : _max(mprs).toStringAsFixed(2), color: Colors.purple.shade700),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])), const SizedBox(height: 2), Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))]),
    );
  }
}

class _SessionMetric {
  final String mainValue;
  final String subText;
  final Color color;
  _SessionMetric({required this.mainValue, required this.subText, required this.color});
}

_SessionMetric _buildSessionMetric(BuildContext context, TrainingSessionModel s) {
  final sLocal = AppLocalizations.of(context)!;
  final mode = s.inputModeString;
  if (mode == 'hitCount') {
    final rate = (s.hitRate ?? 0.0) * 100.0;
    return _SessionMetric(mainValue: "${rate.toStringAsFixed(1)}%", subText: sLocal.drill_stat_hit_rate, color: Colors.amber[700]!);
  }
  if (mode == 'scoreOnly') {
    return _SessionMetric(mainValue: "${s.ppd?.toStringAsFixed(2) ?? '-'}", subText: "PPD", color: Colors.cyan[700]!);
  }
  if (mode == 'cricketMarks') {
    return _SessionMetric(mainValue: "${s.mpr?.toStringAsFixed(2) ?? '-'}", subText: "MPR", color: Colors.purple[700]!);
  }
  return _SessionMetric(mainValue: "-", subText: "-", color: Colors.grey);
}

class _CycleInfo {
  final String cycleId;
  final DaoTrainingTier? tier;
  final DateTime startAt;
  final int sessionCount;
  final BuildContext context;
  const _CycleInfo({required this.cycleId, required this.tier, required this.startAt, required this.sessionCount, required this.context});
  String get label => _tierDisplayLabel(context, tier);
}

String _tierDisplayLabel(BuildContext context, DaoTrainingTier? tier) {
  final s = AppLocalizations.of(context)!;
  if (tier == null) return s.filter_all;
  switch (tier) {
    case DaoTrainingTier.beginner: return s.tier_beginner;
    case DaoTrainingTier.learner: return s.tier_learner;
    case DaoTrainingTier.competitor: return s.tier_competitor;
    case DaoTrainingTier.challenger: return s.tier_challenger;
    case DaoTrainingTier.elite: return s.tier_elite;
    case DaoTrainingTier.pro: return s.tier_pro;
    case DaoTrainingTier.master: return s.tier_master;
  }
}

List<_CycleInfo> _buildCycleInfos(BuildContext context, List<TrainingSessionModel> sessions) {
  final Map<String, _CycleInfo> map = {};
  for (final s in sessions) {
    final id = s.cycleId;
    if (id == null || id.isEmpty) continue;
    final existing = map[id];
    if (existing == null) {
      map[id] = _CycleInfo(cycleId: id, tier: s.tierAtThatTime, startAt: s.startedAt, sessionCount: 1, context: context);
    } else {
      map[id] = _CycleInfo(cycleId: id, tier: existing.tier, startAt: s.startedAt.isBefore(existing.startAt) ? s.startedAt : existing.startAt, sessionCount: existing.sessionCount + 1, context: context);
    }
  }
  return map.values.toList()..sort((a, b) => b.startAt.compareTo(a.startAt));
}

Future<void> _onDeleteCyclePressed(BuildContext context, WidgetRef ref, String cycleId) async {
  final s = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.history_cycle_delete_title),
      content: Text(s.history_cycle_delete_msg),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.common_delete, style: const TextStyle(color: Colors.red))),
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
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.rank_reset_done)));
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
  }
}