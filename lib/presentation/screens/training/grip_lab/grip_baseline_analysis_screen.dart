// lib/presentation/screens/training/grip_lab/grip_baseline_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_camera_screen.dart';
import 'package:daoapp/data/models/grip_baseline_model.dart';

// ✅ 분리한 위젯 사용
import 'package:daoapp/presentation/screens/training/grip_lab/widgets/grip_metric_card.dart';

class GripBaselineAnalysisScreen extends ConsumerWidget {
  const GripBaselineAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gripBaselineProvider);

    ref.listen<GripBaselineState>(gripBaselineProvider, (prev, next) {
      final msg = next.errorMessage;
      if (msg == null || msg.isEmpty) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

      ref.read(gripBaselineProvider.notifier).clearError();
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "기준 그립 분석",
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
          IconButton(
            tooltip: "새로고침",
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () => ref.read(gripBaselineProvider.notifier).fetchBaseline(),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (!state.hasBaseline)
              _EmptyBaselineView(
                onTake: state.isLoading
                    ? null
                    : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GripCameraScreen(),
                    ),
                  );
                  // 촬영/저장 후 돌아오면 새로 불러오기
                  await ref
                      .read(gripBaselineProvider.notifier)
                      .fetchBaseline();
                },
              )
            else
              _BaselineAnalysisBody(
                baseline: state.baseline!,
                onUpdate: state.isLoading
                    ? null
                    : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GripCameraScreen(),
                    ),
                  );
                  await ref
                      .read(gripBaselineProvider.notifier)
                      .fetchBaseline();
                },
                onDelete: state.isLoading
                    ? null
                    : () async {
                  final ok = await _confirmDelete(context);
                  if (!ok) return;

                  final success = await ref
                      .read(gripBaselineProvider.notifier)
                      .deleteBaseline();

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("기준 그립이 삭제되었습니다.")),
                    );
                  }
                },
              ),

            if (state.isLoading)
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

  static Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("기준 그립 삭제"),
        content: const Text(
          "저장된 기준 그립(이미지/데이터)을 삭제할까요?\n\n"
              "⚠️ 이 작업은 되돌릴 수 없습니다.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return result == true;
  }
}

class _EmptyBaselineView extends StatelessWidget {
  final VoidCallback? onTake;

  const _EmptyBaselineView({required this.onTake});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pan_tool_alt_rounded,
                    size: 64, color: Colors.grey[500]),
                const SizedBox(height: 14),
                const Text(
                  "저장된 기준 그립이 없어요",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "좋았던 날의 그립을 촬영해서\n‘기준 그립’으로 저장해보세요.",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTake,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan[600],
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "촬영하러 가기",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BaselineAnalysisBody extends StatelessWidget {
  final GripBaselineModel baseline;
  final VoidCallback? onUpdate;
  final VoidCallback? onDelete;

  const _BaselineAnalysisBody({
    required this.baseline,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final createdLabel = _formatDateTimeSafe(baseline.createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 이미지 "안 잘리게" 전체 보이도록 수정
          _BaselinePreviewCard(
            imageUrl: baseline.imageUrl,
            createdLabel: createdLabel,
            frameLabel: "${baseline.imageWidth}×${baseline.imageHeight}",
          ),
          const SizedBox(height: 14),

          const Text(
            "기준 데이터",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            "이 화면은 ‘기준 그립’의 분석 수치를 보여줘요.\n"
                "다음 단계에서 여기에 ‘현재 그립과의 차이(빨강/파랑)’도 추가할 거야.",
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.15,
            children: [
              GripMetricCard(
                title: "Pinch Gap",
                value: "${(baseline.pinchGap * 100).toStringAsFixed(1)}%",
                sub: "엄지-검지 간격",
                color: Colors.cyan,
              ),
              GripMetricCard(
                title: "Index Angle",
                value: "${baseline.indexAngle.toStringAsFixed(1)}°",
                sub: "검지 굽힘 각도",
                color: Colors.indigo,
              ),
              GripMetricCard(
                title: "Landmarks",
                value: "${baseline.landmarks.length}/21",
                sub: "손 포인트 수",
                color: Colors.orange,
              ),
              GripMetricCard(
                title: "Updated",
                value: createdLabel.split(" ").first,
                sub: "기준 저장일",
                color: Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Colors.red.withOpacity(0.55),
                      width: 1.6,
                    ),
                  ),
                  child: const Text(
                    "기준 삭제",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan[600],
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "기준 업데이트",
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

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Colors.amber[700], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "다음 단계: 카메라에서 ‘기준 그립 고스트’를 깔고,\n"
                        "현재 그립과 차이를 빨강/파랑으로 표시할 거야.",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey[700],
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTimeSafe(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return "${dt.year}-$mm-$dd $hh:$mi";
  }
}

class _BaselinePreviewCard extends StatelessWidget {
  final String imageUrl;
  final String createdLabel;
  final String frameLabel;

  const _BaselinePreviewCard({
    required this.imageUrl,
    required this.createdLabel,
    required this.frameLabel,
  });

  void _openFull(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(14),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 240,
                    child: Center(
                      child: Text(
                        "이미지를 불러올 수 없어요",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 240,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.cyan),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFull(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 여기서 BoxFit.cover -> BoxFit.contain 으로 변경 (안 잘리게)
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Container(
                  color: Colors.black, // contain일 때 남는 여백 배경
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text("이미지를 불러올 수 없어요"),
                      ),
                    ),
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.cyan),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "저장일: $createdLabel",
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.cyan.withOpacity(0.25)),
                      ),
                      child: Text(
                        "Frame $frameLabel",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.cyan[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
                child: Text(
                  "탭하면 전체보기(확대/이동) 할 수 있어요",
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
