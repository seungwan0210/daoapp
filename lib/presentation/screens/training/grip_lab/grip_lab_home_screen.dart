// lib/presentation/screens/training/grip_lab/grip_lab_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_camera_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_baseline_analysis_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_compare_screen.dart';

class GripLabHomeScreen extends ConsumerWidget {
  const GripLabHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baselineState = ref.watch(gripBaselineProvider);

    final hasBaseline = baselineState.hasBaseline;
    final isLoading = baselineState.isLoading;

    ref.listen<GripBaselineState>(gripBaselineProvider, (prev, next) {
      final msg = next.errorMessage;
      if (msg == null || msg.isEmpty) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

      // 한번 띄우고 초기화
      ref.read(gripBaselineProvider.notifier).clearError();
    });

    Future<void> _pushCamera() async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GripCameraScreen()),
      );
      await ref.read(gripBaselineProvider.notifier).fetchBaseline();
    }

    Future<void> _pushBaselineAnalysis() async {
      final now = ref.read(gripBaselineProvider);
      if (!now.hasBaseline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("기준 그립이 없어요. 먼저 촬영해서 저장해 주세요.")),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GripBaselineAnalysisScreen()),
      );

      // ✅ 돌아오면 최신 기준 다시 불러오기(삭제/업데이트 반영)
      await ref.read(gripBaselineProvider.notifier).fetchBaseline();
    }

    Future<void> _pushCompare() async {
      // CompareScreen은 내부에서 "기준 없으면 안내 + 촬영 연결"을 처리함
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GripCompareScreen()),
      );

      // ✅ 비교 화면에서 기준 업데이트/촬영 했을 수 있으니 갱신
      await ref.read(gripBaselineProvider.notifier).fetchBaseline();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "그립 연구소",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) 상단 타이틀
                  const Text(
                    "내 그립, 기록하고\n기준과 비교하기.",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "정답은 없지만, 나에게 잘 맞는 ‘기준 그립’은 만들 수 있어요.\n"
                        "좋았던 날의 그립을 저장하고, 다음 날 다시 맞춰보세요.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 2) 안내 카드들 + 기준 상태
                  Expanded(
                    child: ListView(
                      children: [
                        _InfoCard(
                          icon: Icons.camera_alt_rounded,
                          title: "촬영 & 저장",
                          desc:
                          "손을 카메라에 비추면 랜드마크(손뼈대)를 추적해요.\n"
                              "기준으로 저장하면 1인당 1개만 유지됩니다.",
                          tint: Colors.cyan,
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(
                          icon: Icons.compare_arrows_rounded,
                          title: "비교/교정",
                          desc:
                          "기준 그립(고스트) 위에 현재 그립을 겹치고,\n"
                              "달라진 곳을 빨강/파랑으로 확인하며 교정 연습을 해요.",
                          tint: Colors.indigo,
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(
                          icon: Icons.insights_rounded,
                          title: "숫자로 확인",
                          desc:
                          "엄지-검지 핀치 간격, 검지 굽힘 각도 등\n"
                              "측정 가능한 항목은 수치로 보여줘요.",
                          tint: Colors.orange,
                        ),
                        const SizedBox(height: 18),

                        // 3) 기준 상태 표시
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: hasBaseline
                                  ? Colors.cyan.withOpacity(0.35)
                                  : Colors.grey.withOpacity(0.2),
                              width: 1.4,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: hasBaseline
                                    ? Colors.cyan.withOpacity(0.14)
                                    : Colors.grey.withOpacity(0.12),
                                child: Icon(
                                  hasBaseline
                                      ? Icons.verified_rounded
                                      : Icons.info_outline_rounded,
                                  color: hasBaseline ? Colors.cyan : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasBaseline
                                          ? "기준 그립이 저장되어 있어요 ✅"
                                          : "아직 기준 그립이 없어요",
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.grey[850],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hasBaseline
                                          ? "아래에서 ‘비교/교정’으로 바로 교정 연습을 하거나,\n"
                                          "‘촬영하기’로 기준을 업데이트할 수 있어요."
                                          : "먼저 ‘촬영하기’로 기준을 저장해보세요.\n"
                                          "저장 후 ‘비교/교정’에서 바로 맞춰볼 수 있어요.",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        height: 1.35,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // ✅ 기준 분석(수치 보기)은 작은 텍스트 버튼으로 분리
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: isLoading ? null : _pushBaselineAnalysis,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          foregroundColor: Colors.cyan[800],
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        icon: const Icon(Icons.analytics_rounded, size: 18),
                                        label: const Text(
                                          "기준 분석(수치 보기)",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4) 하단 버튼 2개 (비교/교정 + 촬영하기)
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : _pushCompare,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Colors.indigo.withOpacity(0.55),
                              width: 1.6,
                            ),
                          ),
                          child: Text(
                            "비교/교정",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _pushCamera,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyan[600],
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "촬영하기",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 로딩 오버레이
            if (isLoading)
              Container(
                color: Colors.white.withOpacity(0.65),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.cyan),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color tint;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withOpacity(0.22), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tint.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tint, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
