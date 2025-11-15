// lib/presentation/screens/community/checkout/practice/checkout_result_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/providers/checkout_practice_provider.dart';
import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class CheckoutResultScreen extends StatelessWidget {
  const CheckoutResultScreen({super.key});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as PracticeSessionSummary?;
    if (args == null) {
      return _buildErrorScreen(context, "결과 데이터를 불러올 수 없습니다.");
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildErrorScreen(context, "로그인이 필요합니다.");
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, RouteConstants.checkoutHome, (route) => false);
        return false;
      },
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildErrorScreen(context, "프로필 정보를 불러올 수 없습니다.");
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final koreanName = userData['koreanName']?.toString().trim() ?? '이름 없음';
          final photoUrl = userData['profileImageUrl'] as String?;
          final barrelImageUrl = userData['barrelImageUrl'] as String?;

          final total = args.results.length;
          final successCount = args.results.where((r) => r.success).length;
          final successRate = total > 0 ? (successCount / total) * 100 : 0.0;

          final successResults = args.results.where((r) => r.success).toList();
          final avgDarts = successResults.isEmpty
              ? 0.0
              : successResults.map((r) => r.dartsUsed).reduce((a, b) => a + b) / successResults.length;

          return Scaffold(
            appBar: const CommonAppBar(title: "연습 결과"),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 프로필 헤더
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
                            child: photoUrl?.isNotEmpty != true ? const Icon(Icons.person, size: 36) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(koreanName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                if (barrelImageUrl?.isNotEmpty == true)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(barrelImageUrl!, width: 50, height: 50, fit: BoxFit.cover),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 주요 통계
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatRow("총 소요 시간", _formatTime(args.elapsedSeconds), Icons.timer),
                          const Divider(height: 24),
                          _buildStatRow("성공률", "${successRate.toStringAsFixed(0)}%", Icons.check_circle_outline),
                          const Divider(height: 24),
                          _buildStatRow("평균 다트", "${avgDarts.toStringAsFixed(1)} 다트", Icons.sports_score),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 문제별 결과 + 피드백
                  Text(
                    "문제별 결과",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: args.results.length,
                    itemBuilder: (context, index) {
                      final r = args.results[index];
                      final isSuccess = r.success;
                      final targetScore = r.problem.targetScore;
                      final optimalRoute = checkoutTable[targetScore.toString()]?.primary ?? [];
                      final usedDarts = r.dartsUsed;
                      final optimalDarts = checkoutTable[targetScore.toString()]?.primary.length ?? 3;

                      return AppCard(
                        child: ExpansionTile(
                          leading: Icon(
                            isSuccess ? Icons.check_circle : Icons.cancel,
                            color: isSuccess ? Colors.green : Colors.red,
                          ),
                          title: Text("문제 ${index + 1}: ${targetScore}점"),
                          subtitle: Text(isSuccess ? "$usedDarts 다트 성공" : "실패"),
                          trailing: isSuccess
                              ? Text("$usedDarts다트", style: const TextStyle(fontWeight: FontWeight.bold))
                              : null,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "최적 루트",
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    optimalRoute.isEmpty ? "없음" : optimalRoute.join(" → "),
                                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                                  ),
                                  const SizedBox(height: 8),
                                  if (isSuccess)
                                    Text(
                                      usedDarts == optimalDarts
                                          ? "최적 루트로 성공!"
                                          : "성공했지만 최적 루트는 $optimalDarts다트입니다.",
                                      style: TextStyle(
                                        color: usedDarts == optimalDarts ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  else
                                    const Text(
                                      "다음엔 최적 루트를 도전해보세요!",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorScreen(BuildContext context, String message) {
    return Scaffold(
      appBar: const CommonAppBar(title: "연습 결과"),
      body: Center(child: Text(message)),
    );
  }
}