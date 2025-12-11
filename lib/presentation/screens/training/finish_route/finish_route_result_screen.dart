// lib/presentation/screens/training/finish_route/finish_route_result_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/providers/checkout_practice_provider.dart';
import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class FinishRouteResultScreen extends StatelessWidget {
  const FinishRouteResultScreen({super.key});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // 최적 다트율 (성공한 문제 중, 최적 다트 수로 끝낸 비율) → % 단위
  double _calculateOptimizationRate(List<PracticeResult> results) {
    final successResults = results.where((r) => r.success).toList();
    if (successResults.isEmpty) return 0.0;

    int optimalCount = 0;
    for (final r in successResults) {
      final scoreKey = r.originalScore.toString();
      final optimalDarts = checkoutTable[scoreKey]?.primary.length ?? 3;
      if (r.dartsUsed == optimalDarts) {
        optimalCount++;
      }
    }
    return (optimalCount / successResults.length) * 100;
  }

  // 정석 루트율 (성공한 문제 중, primary 루트와 정확히 일치한 비율) → % 단위
  double _calculateRouteAccuracyRate(List<PracticeResult> results) {
    final successResults = results.where((r) => r.success).toList();
    if (successResults.isEmpty) return 0.0;

    int matchedCount = 0;
    for (final r in successResults) {
      final routeData = checkoutTable[r.originalScore.toString()];
      if (routeData == null) continue;
      if (listEquals(routeData.primary, r.usedSegments)) {
        matchedCount++;
      }
    }
    return (matchedCount / successResults.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)?.settings.arguments as PracticeSessionSummary?;
    if (args == null) {
      return _buildErrorScreen(context, "결과 데이터를 불러올 수 없습니다.");
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildErrorScreen(context, "로그인이 필요합니다.");
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("피니쉬 루트 연습 결과"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).popUntil(
            ModalRoute.withName(RouteConstants.finishRouteHome),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildErrorScreen(context, "프로필 정보를 불러올 수 없습니다.");
          }

          final userData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final koreanName =
              userData['koreanName']?.toString().trim() ?? '이름 없음';
          final photoUrl = userData['profileImageUrl'] as String?;
          final barrelImageUrl = userData['barrelImageUrl'] as String?;

          final total = args.results.length;
          final successCount =
              args.results.where((r) => r.success).length;
          final successRate =
          total > 0 ? (successCount / total) * 100 : 0.0;

          final successResults =
          args.results.where((r) => r.success).toList();
          final avgDarts = successResults.isEmpty
              ? 0.0
              : successResults
              .map((r) => r.dartsUsed)
              .reduce((a, b) => a + b) /
              successResults.length;

          final optimizationRate =
          _calculateOptimizationRate(args.results);
          final routeAccuracyRate =
          _calculateRouteAccuracyRate(args.results);

          return SingleChildScrollView(
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
                          backgroundImage:
                          photoUrl?.isNotEmpty == true
                              ? NetworkImage(photoUrl!)
                              : null,
                          child: photoUrl?.isNotEmpty == true
                              ? null
                              : const Icon(Icons.person, size: 36),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                koreanName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (barrelImageUrl?.isNotEmpty == true)
                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(8),
                                  child: Image.network(
                                    barrelImageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
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
                        _buildStatRow(
                          "총 소요 시간",
                          _formatTime(args.elapsedSeconds),
                          Icons.timer,
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          "성공률",
                          "${successRate.toStringAsFixed(0)}%",
                          Icons.check_circle_outline,
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          "최적 다트율",
                          "${optimizationRate.toStringAsFixed(0)}%",
                          Icons.track_changes,
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          "정석 루트율",
                          "${routeAccuracyRate.toStringAsFixed(0)}%",
                          Icons.navigation,
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          "평균 다트",
                          "${avgDarts.toStringAsFixed(1)} 다트",
                          Icons.sports_score,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "문제별 결과",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                ListView.builder(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  itemCount: args.results.length,
                  itemBuilder: (context, index) {
                    final r = args.results[index];
                    final isSuccess = r.success;
                    final targetScore = r.problem.targetScore;

                    final routeData =
                    checkoutTable[targetScore.toString()];
                    final optimalRoute =
                        routeData?.primary ?? const <String>[];
                    final optimalDarts =
                        routeData?.primary.length ?? 3;

                    final usedDarts = r.dartsUsed;

                    return AppCard(
                      child: ExpansionTile(
                        leading: Icon(
                          isSuccess
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: isSuccess
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(
                          "문제 ${index + 1}: ${targetScore}점",
                        ),
                        subtitle: Text(
                          isSuccess
                              ? "$usedDarts 다트 성공"
                              : "실패",
                        ),
                        trailing: isSuccess
                            ? Text(
                          "$usedDarts다트",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            : null,
                        children: [
                          Padding(
                            padding:
                            const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "최적 루트",
                                  style: TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  optimalRoute.isEmpty
                                      ? "없음"
                                      : optimalRoute
                                      .join(" → "),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (isSuccess)
                                  Text(
                                    usedDarts == optimalDarts
                                        ? "최적 다트 수로 성공!"
                                        : "성공했지만 최적 다트 수는 $optimalDarts다트입니다.",
                                    style: TextStyle(
                                      color: usedDarts ==
                                          optimalDarts
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight:
                                      FontWeight.w500,
                                    ),
                                  )
                                else
                                  const Text(
                                    "다음엔 최적 다트 수/루트를 도전해보세요!",
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
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
          );
        },
      ),
    );
  }

  Widget _buildStatRow(
      String label,
      String value,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorScreen(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("피니쉬 루트 연습 결과"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).popUntil(
            ModalRoute.withName(RouteConstants.finishRouteHome),
          ),
        ),
      ),
      body: Center(child: Text(message)),
    );
  }
}
