// lib/presentation/screens/training/checkout/checkout_result_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/data/models/practice_session_summary.dart';

class CheckoutResultScreen extends StatelessWidget {
  const CheckoutResultScreen({super.key});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  double _calculateOptimizationRate(List<PracticeResult> results) {
    final success = results.where((r) => r.isSuccess).toList();
    if (success.isEmpty) return 0.0;
    final optimal = success.where((r) => r.dartsUsed == _getOptimalDarts(r.scoreBefore)).length;
    return (optimal / success.length) * 100;
  }

  double _calculateRouteAccuracyRate(List<PracticeResult> results) {
    final success = results.where((r) => r.isSuccess).toList();
    if (success.isEmpty) return 0.0;

    int matched = 0;
    for (final r in success) {
      final data = checkoutTable[r.scoreBefore.toString()];
      if (data == null) continue;
      if (listEquals(data.primary, r.darts)) matched++;
    }
    return (matched / success.length) * 100;
  }

  int _getOptimalDarts(int score) {
    return checkoutTable[score.toString()]?.primary.length ?? 3;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as PracticeSessionSummary?;
    if (args == null) {
      return _errorScreen(context, "결과 데이터를 불러올 수 없습니다.");
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _errorScreen(context, "로그인이 필요합니다.");
    }

    final total = args.results.length;
    final successCount = args.results.where((r) => r.isSuccess).length;
    final successRate = total > 0 ? (successCount / total) * 100 : 0.0;
    final avgDarts = successCount > 0
        ? args.results.where((r) => r.isSuccess).map((r) => r.dartsUsed).reduce((a, b) => a + b) / successCount
        : 0.0;

    final optimizationRate = _calculateOptimizationRate(args.results);
    final routeAccuracyRate = _calculateRouteAccuracyRate(args.results);

    return Scaffold(
      // leading 제거! CommonAppBar가 자동으로 뒤로가기 넣어줌
      appBar: const CommonAppBar(title: "연습 결과"),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = userData['koreanName']?.toString().trim() ?? '이름 없음';
          final photoUrl = userData['profileImageUrl'] as String?;
          final barrelUrl = userData['barrelImageUrl'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 프로필 헤더
                AppCard(
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 32,
                      backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
                      child: photoUrl?.isNotEmpty != true ? const Icon(Icons.person, size: 36) : null,
                    ),
                    title: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    subtitle: barrelUrl?.isNotEmpty == true
                        ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(barrelUrl!, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                    )
                        : null,
                  ),
                ),

                const SizedBox(height: 20),

                // 주요 통계
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _statRow("총 소요 시간", _formatTime(args.elapsedSeconds), Icons.timer),
                        _statRow("성공률", "${successRate.toStringAsFixed(0)}%", Icons.check_circle),
                        _statRow("최적 다트율", "${optimizationRate.toStringAsFixed(0)}%", Icons.star),
                        _statRow("정석 루트율", "${routeAccuracyRate.toStringAsFixed(0)}%", Icons.navigation),
                        _statRow("평균 다트", "${avgDarts.toStringAsFixed(1)} 다트", Icons.sports_score),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 문제별 결과
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("문제별 결과", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),

                ...args.results.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final r = entry.value;
                  final optimalRoute = checkoutTable[r.scoreBefore.toString()]?.primary ?? [];
                  final optimalDarts = optimalRoute.length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: ExpansionTile(
                        leading: Icon(r.isSuccess ? Icons.check_circle : Icons.cancel, color: r.isSuccess ? Colors.green : Colors.red),
                        title: Text("문제 $index: ${r.scoreBefore}점"),
                        subtitle: Text(r.isSuccess ? "${r.dartsUsed}다트 성공" : "실패 (BUST)"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow("최적 루트", optimalRoute.join(" → "), Colors.blue),
                                _infoRow("최적 다트 수", "$optimalDarts 다트", Colors.green),
                                if (r.isSuccess) ...[
                                  _infoRow("사용한 루트", r.darts.join(" → "), Colors.purple),
                                  _infoRow("사용 다트 수", "${r.dartsUsed} 다트", r.dartsUsed == optimalDarts ? Colors.green : Colors.orange),
                                  Text(
                                    r.dartsUsed == optimalDarts ? "최적 다트 수로 성공!" : "성공했지만 최적은 $optimalDarts다트였습니다.",
                                    style: TextStyle(color: r.dartsUsed == optimalDarts ? Colors.green[700] : Colors.orange[700], fontWeight: FontWeight.bold),
                                  ),
                                ] else
                                  const Text("다음엔 더블 아웃으로 끝내보세요!", style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 28),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _errorScreen(BuildContext context, String message) {
    return Scaffold(
      appBar: const CommonAppBar(title: "연습 결과"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName(RouteConstants.checkoutPracticeHome)),
              child: const Text("홈으로 돌아가기"),
            ),
          ],
        ),
      ),
    );
  }
}