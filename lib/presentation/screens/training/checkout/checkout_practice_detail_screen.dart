// lib/presentation/screens/community/checkout/practice/checkout_practice_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/checkout_table.dart';

class CheckoutPracticeDetailScreen extends StatelessWidget {
  final String recordId;
  final Map<String, dynamic> data;

  const CheckoutPracticeDetailScreen({super.key, required this.recordId, required this.data});

  @override
  Widget build(BuildContext context) {
    final ts = (data['timestamp'] ?? data['createdAt']) as Timestamp?;
    final createdAt = ts?.toDate();

    final elapsed = (data['elapsedSeconds'] as num?)?.toDouble() ?? 0.0;
    final successRate = (data['successRate'] as num?)?.toDouble() ?? 0.0;
    final avgDarts = (data['avgDarts'] as num?)?.toDouble() ?? 0.0;
    final problemCount = (data['problemCount'] as num?)?.toInt() ?? (data['totalAttempts'] as num?)?.toInt() ?? 0;
    int successCount = (data['successCount'] as num?)?.toInt() ?? (successRate * problemCount).round();
    final optimizationRate = (data['optimizationRate'] as num?)?.toDouble() ?? 0.0;
    final routeMatchRate = (data['routeMatchRate'] as num?)?.toDouble() ?? 0.0;
    final score = (data['score'] as num?)?.toInt() ?? 0;

    final problemsRaw = data['problems'] as List<dynamic>? ?? const [];
    final problems = problemsRaw.cast<Map<String, dynamic>>();

    String dateText = createdAt != null
        ? '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';

    return Scaffold(
      appBar: const CommonAppBar(title: '연습 상세 기록'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (dateText.isNotEmpty) Text(dateText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildStatRow(label: '총 걸린 시간', value: '${elapsed.toStringAsFixed(1)} 초'),
                _buildStatRow(label: '성공률', value: '${(successRate * 100).toStringAsFixed(0)} %'),
                _buildStatRow(label: '평균 사용 다트 수', value: '${avgDarts.toStringAsFixed(1)} 개'),
                _buildStatRow(label: '성공 / 시도', value: '$successCount / $problemCount'),
                const Divider(height: 24),
                _buildStatRow(label: '최적 다트율', value: '${(optimizationRate * 100).toStringAsFixed(0)} %'),
                _buildStatRow(label: '정석 루트율', value: '${(routeMatchRate * 100).toStringAsFixed(0)} %'),
                _buildStatRow(label: '세션 점수', value: '$score 점 (0~10000)'),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          if (problems.isNotEmpty)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('문제별 상세 기록', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: problems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = problems[index];
                      final targetScore = (p['targetScore'] as num?)?.toInt() ?? 0;
                      final dartsUsed = (p['dartsUsed'] as num?)?.toInt() ?? 0;
                      final success = (p['success'] as bool?) ?? false;
                      final usedSegments = (p['usedSegments'] as List<dynamic>?)?.cast<String>() ?? [];

                      final routeData = checkoutTable[targetScore.toString()];
                      final primary = routeData?.primary ?? [];
                      final alts = routeData?.alts ?? [];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(success ? Icons.check_circle : Icons.cancel, color: success ? Colors.green : Colors.red),
                        title: Text('문제 ${index + 1}: $targetScore점', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const SizedBox(height: 4),
                          Text('사용 다트: $dartsUsed개', style: const TextStyle(fontSize: 12)),
                          if (usedSegments.isNotEmpty)
                            Text('실제 던진 루트: ${usedSegments.join(" → ")}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          const SizedBox(height: 8),
                          Text('최적 루트: ${primary.join(" → ")} (${primary.length}다트)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                          if (alts.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            const Text('대안 루트:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ...alts.map((alt) => Padding(padding: const EdgeInsets.only(left: 8, top: 2), child: Text("• ${alt.join(" → ")} (${alt.length}다트)", style: const TextStyle(fontSize: 12)))),
                          ],
                        ]),
                      );
                    },
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildStatRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]),
    );
  }
}