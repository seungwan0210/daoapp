import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/checkout_table.dart';
import 'package:daoapp/core/constants/route_constants.dart';

// ✅ 실제 사용 중인 provider 경로/타입으로 맞춤
import 'package:daoapp/presentation/providers/training/finish_route/finish_route_practice_provider.dart';

class FinishRouteResultScreen extends StatelessWidget {
  const FinishRouteResultScreen({super.key});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // ✅ 최적 다트율 (성공 중 optimal darts와 일치)
  double _calculateOptimizationRate(List<PracticeResult> results) {
    final success = results.where((r) => r.success).toList();
    if (success.isEmpty) return 0.0;

    int optimalCount = 0;
    for (final r in success) {
      final key = r.originalScore.toString();
      final optimal = checkoutTable[key]?.primary.length ?? 3;
      if (r.dartsUsed == optimal) optimalCount++;
    }
    return (optimalCount / success.length) * 100;
  }

  // ✅ 정석 루트율 (성공 중 primary/alt 중 하나와 정확히 일치)
  double _calculateRouteMatchRate(List<PracticeResult> results) {
    final success = results.where((r) => r.success).toList();
    if (success.isEmpty) return 0.0;

    int matched = 0;
    for (final r in success) {
      final data = checkoutTable[r.originalScore.toString()];
      if (data == null) continue;

      final candidates = <List<String>>[data.primary, ...data.alts];
      for (final route in candidates) {
        if (route.length == r.usedSegments.length &&
            listEquals(route, r.usedSegments)) {
          matched++;
          break;
        }
      }
    }
    return (matched / success.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)?.settings.arguments as FinishRoutePracticeSessionSummary?;

    if (args == null) {
      return _buildErrorScreen(context, "결과 데이터를 불러올 수 없습니다.");
    }

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("피니시 루트 결과"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).popUntil(
            ModalRoute.withName(RouteConstants.finishRouteHome),
          ),
        ),
      ),
      body: user == null
          ? _buildGuestResult(context, args)
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() ?? {};
          final koreanName =
          (userData['koreanName'] ?? '이름 없음').toString().trim();
          final photoUrl = userData['profileImageUrl'] as String?;
          final barrelImageUrl = userData['barrelImageUrl'] as String?;

          return _buildResultBody(
            context: context,
            args: args,
            koreanName: koreanName,
            photoUrl: photoUrl,
            barrelImageUrl: barrelImageUrl,
          );
        },
      ),
    );
  }

  /// ✅ 로그인 안한 유저도 결과는 보여주기
  Widget _buildGuestResult(
      BuildContext context,
      FinishRoutePracticeSessionSummary args,
      ) {
    return _buildResultBody(
      context: context,
      args: args,
      koreanName: '게스트',
      photoUrl: null,
      barrelImageUrl: null,
    );
  }

  Widget _buildResultBody({
    required BuildContext context,
    required FinishRoutePracticeSessionSummary args,
    required String koreanName,
    required String? photoUrl,
    required String? barrelImageUrl,
  }) {
    final total = args.results.length;
    final successCount = args.results.where((r) => r.success).length;
    final successRate = total > 0 ? (successCount / total) * 100 : 0.0;

    final successResults = args.results.where((r) => r.success).toList();
    final avgDarts = successResults.isEmpty
        ? 0.0
        : successResults.map((r) => r.dartsUsed).reduce((a, b) => a + b) /
        successResults.length;

    final optimizationRate = _calculateOptimizationRate(args.results);
    final routeMatchRate = _calculateRouteMatchRate(args.results);

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
                    (photoUrl?.isNotEmpty == true) ? NetworkImage(photoUrl!) : null,
                    child: (photoUrl?.isNotEmpty == true)
                        ? null
                        : const Icon(Icons.person, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          koreanName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (barrelImageUrl?.isNotEmpty == true)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              barrelImageUrl!,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                width: 52,
                                height: 52,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
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
                  _buildStatRow("총 소요 시간", _formatTime(args.elapsedSeconds), Icons.timer),
                  const Divider(height: 24),
                  _buildStatRow("성공률", "${successRate.toStringAsFixed(0)}%", Icons.check_circle_outline),
                  const Divider(height: 24),
                  _buildStatRow("최적 다트율", "${optimizationRate.toStringAsFixed(0)}%", Icons.track_changes),
                  const Divider(height: 24),
                  _buildStatRow("정석 루트율", "${routeMatchRate.toStringAsFixed(0)}%", Icons.navigation),
                  const Divider(height: 24),
                  _buildStatRow("평균 다트", "${avgDarts.toStringAsFixed(1)} 다트", Icons.sports_score),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "문제별 결과",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

              final routeData = checkoutTable[targetScore.toString()];
              final primary = routeData?.primary ?? const <String>[];
              final alts = routeData?.alts ?? const <List<String>>[];

              final usedDarts = r.dartsUsed;
              final optimalDarts = primary.isNotEmpty ? primary.length : 3;

              // ✅ 루트 매칭 여부
              final matched = (() {
                final candidates = <List<String>>[primary, ...alts];
                for (final route in candidates) {
                  if (route.length == r.usedSegments.length &&
                      listEquals(route, r.usedSegments)) {
                    return true;
                  }
                }
                return false;
              })();

              return AppCard(
                child: ExpansionTile(
                  leading: Icon(
                    isSuccess ? Icons.check_circle : Icons.cancel,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                  title: Text("문제 ${index + 1}: $targetScore점"),
                  subtitle: Text(isSuccess ? "$usedDarts 다트 성공" : "실패"),
                  trailing: isSuccess
                      ? Text(
                    "$usedDarts다트",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                      : null,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("최적 루트", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            primary.isEmpty ? "없음" : primary.join(" → "),
                            style: const TextStyle(fontSize: 16, color: Colors.blue),
                          ),
                          if (alts.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text("대안 루트", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ...alts.map(
                                  (alt) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text("• ${alt.join(" → ")}", style: const TextStyle(fontSize: 13)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (r.usedSegments.isNotEmpty) ...[
                            const Text("내가 던진 루트", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              r.usedSegments.join(" → "),
                              style: TextStyle(
                                fontSize: 14,
                                color: matched ? Colors.green[700] : Colors.blueGrey,
                                fontWeight: matched ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (isSuccess)
                            Text(
                              usedDarts == optimalDarts
                                  ? "최적 다트 수로 성공!"
                                  : "성공했지만 최적 다트 수는 ${optimalDarts}다트입니다.",
                              style: TextStyle(
                                color: usedDarts == optimalDarts ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            const Text(
                              "다음엔 최적 다트 수/루트를 도전해보세요!",
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

          const SizedBox(height: 20),

          // ✅ 홈으로
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).popUntil(
              ModalRoute.withName(RouteConstants.finishRouteHome),
            ),
            icon: const Icon(Icons.home),
            label: const Text("피니시 루트 홈으로"),
          ),
        ],
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
      appBar: AppBar(
        title: const Text("피니시 루트 결과"),
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
