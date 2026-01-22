import 'dart:math' as math; // 각도 계산용
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_camera_screen.dart';
import 'package:daoapp/data/models/grip_baseline_model.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/widgets/grip_gauge_card.dart';

class GripBaselineAnalysisScreen extends ConsumerWidget {
  const GripBaselineAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gripBaselineProvider);

    ref.listen<GripBaselineState>(gripBaselineProvider, (prev, next) {
      final msg = next.errorMessage;
      if (msg == null || msg.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      ref.read(gripBaselineProvider.notifier).clearError();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("그립 분석 리포트", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(gripBaselineProvider.notifier).fetchBaseline(),
          ),
        ],
      ),
      body: SafeArea(
        child: !state.hasBaseline
            ? _EmptyBaselineView(onTake: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const GripCameraScreen()));
          await ref.read(gripBaselineProvider.notifier).fetchBaseline();
        })
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 히어로 이미지 (탭하여 확대 가능)
              _HeroImageSection(baseline: state.baseline!),
              const SizedBox(height: 24),

              // 2. 메인 분석 (엄지/검지) - 녹색 & 파랑
              const _SectionHeader(title: "메인 컨트롤 (Main Control)", icon: Icons.precision_manufacturing),
              const SizedBox(height: 12),

              GripGaugeCard(
                title: "엄지-검지 간격 (Gap)",
                valueText: "${(state.baseline!.pinchGap * 100).toStringAsFixed(1)}%",
                normalizedValue: (state.baseline!.pinchGap / 0.2).clamp(0.0, 1.0),
                labelLeft: "타이트함",
                labelRight: "와이드함",
                color: Colors.green[700]!, // 🟢 녹색
              ),
              const SizedBox(height: 12),

              GripGaugeCard(
                title: "검지 굽힘 (Index Angle)",
                valueText: "${state.baseline!.indexAngle.toStringAsFixed(0)}°",
                normalizedValue: ((state.baseline!.indexAngle - 90) / 90).clamp(0.0, 1.0),
                labelLeft: "많이 굽힘",
                labelRight: "펴짐",
                color: Colors.blue[700]!, // 🔵 파랑
              ),
              const SizedBox(height: 24),

              // 3. 보조 손가락 분석 (중지/약지/소지) - 주황 & 보라 & 빨강
              const _SectionHeader(title: "보조 지지대 (Support Fingers)", icon: Icons.front_hand),
              const SizedBox(height: 12),

              _buildSupportFingerCards(state.baseline!.landmarks),

              const SizedBox(height: 24),

              // 4. 광고 배너 영역
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.ad_units, color: Colors.grey[400]),
                    const SizedBox(height: 4),
                    Text("AdMob 배너 광고 영역", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. 하단 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await _confirmDelete(context);
                        if (ok) {
                          await ref.read(gripBaselineProvider.notifier).deleteBaseline();
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text("삭제"),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Colors.redAccent),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const GripCameraScreen()));
                        ref.read(gripBaselineProvider.notifier).fetchBaseline();
                      },
                      icon: const Icon(Icons.camera_alt_outlined, size: 20, color: Colors.white),
                      label: const Text("다시 촬영"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 📐 3개의 보조 손가락 카드 생성 로직
  Widget _buildSupportFingerCards(List<Offset> landmarks) {
    if (landmarks.length < 21) return const Text("데이터 부족으로 분석 불가");

    // 각도 계산 (PIP 관절 기준: MCP -> PIP -> DIP)
    // 중지: 9-10-11, 약지: 13-14-15, 소지: 17-18-19
    final middleAngle = _calculateJointAngle(landmarks[9], landmarks[10], landmarks[11]);
    final ringAngle = _calculateJointAngle(landmarks[13], landmarks[14], landmarks[15]);
    final pinkyAngle = _calculateJointAngle(landmarks[17], landmarks[18], landmarks[19]);

    return Column(
      children: [
        GripGaugeCard(
          title: "중지 받침 각도 (Middle)",
          valueText: "${middleAngle.toStringAsFixed(0)}°",
          normalizedValue: ((middleAngle - 70) / 110).clamp(0.0, 1.0),
          labelLeft: "깊게 잡음",
          labelRight: "얕게 잡음",
          color: Colors.orange[800]!, // 🟠 주황 (진하게)
        ),
        const SizedBox(height: 12),
        GripGaugeCard(
          title: "약지 굽힘 (Ring)",
          valueText: "${ringAngle.toStringAsFixed(0)}°",
          normalizedValue: ((ringAngle - 60) / 120).clamp(0.0, 1.0),
          labelLeft: "말아 쥠",
          labelRight: "편안함",
          color: Colors.purple[700]!, // 🟣 보라
        ),
        const SizedBox(height: 12),
        GripGaugeCard(
          title: "소지 밸런스 (Pinky)",
          valueText: "${pinkyAngle.toStringAsFixed(0)}°",
          normalizedValue: ((pinkyAngle - 60) / 120).clamp(0.0, 1.0),
          labelLeft: "안쪽 지지",
          labelRight: "바깥 지지",
          color: Colors.red[700]!, // 🔴 빨강
        ),
      ],
    );
  }

  // 🧮 3점 사잇각 계산 함수 (로컬 헬퍼)
  double _calculateJointAngle(Offset a, Offset b, Offset c) {
    final double angle1 = math.atan2(a.dy - b.dy, a.dx - b.dx);
    final double angle2 = math.atan2(c.dy - b.dy, c.dx - b.dx);
    double angle = (angle1 - angle2) * 180 / math.pi;
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("기준 삭제"),
        content: const Text("정말 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ??
        false;
  }
}

// 🖼️ 히어로 이미지 (확대 기능 복구됨)
class _HeroImageSection extends StatelessWidget {
  final GripBaselineModel baseline;
  const _HeroImageSection({required this.baseline});

  void _openFull(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Image.network(baseline.imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40, right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      baseline.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text("탭하여 확대", style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(_formatDate(baseline.createdAt), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(8)),
                    child: Text("${baseline.imageWidth} x ${baseline.imageHeight}px", style: TextStyle(color: Colors.blueGrey[600], fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _formatDate(DateTime dt) => "${dt.year}.${dt.month}.${dt.day}";
}

// 🏷️ 섹션 헤더 (아이콘 + 텍스트)
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }
}

class _EmptyBaselineView extends StatelessWidget {
  final VoidCallback? onTake;
  const _EmptyBaselineView({required this.onTake});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("데이터를 불러올 수 없습니다.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onTake,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: const Text("새로 촬영하기", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}