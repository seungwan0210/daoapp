import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_camera_screen.dart';
import 'package:daoapp/data/models/grip_baseline_model.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/widgets/grip_gauge_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class GripBaselineAnalysisScreen extends ConsumerWidget {
  const GripBaselineAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩
    final state = ref.watch(gripBaselineProvider);

    ref.listen<GripBaselineState>(gripBaselineProvider, (prev, next) {
      final msg = next.errorMessage;
      if (msg == null || msg.isEmpty) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      ref.read(gripBaselineProvider.notifier).clearError();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(s.grip_report_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              _HeroImageSection(baseline: state.baseline!),
              const SizedBox(height: 24),

              _SectionHeader(title: s.grip_report_main_ctrl, icon: Icons.precision_manufacturing),
              const SizedBox(height: 12),

              GripGaugeCard(
                title: s.grip_report_gap,
                valueText: "${(state.baseline!.pinchGap * 100).toStringAsFixed(1)}%",
                normalizedValue: (state.baseline!.pinchGap / 0.2).clamp(0.0, 1.0),
                labelLeft: s.grip_report_tight,
                labelRight: s.grip_report_wide,
                color: Colors.green[700]!,
              ),
              const SizedBox(height: 12),

              GripGaugeCard(
                title: s.grip_report_index,
                valueText: "${state.baseline!.indexAngle.toStringAsFixed(0)}°",
                normalizedValue: ((state.baseline!.indexAngle - 90) / 90).clamp(0.0, 1.0),
                labelLeft: s.grip_report_bent,
                labelRight: s.grip_report_straight,
                color: Colors.blue[700]!,
              ),
              const SizedBox(height: 24),

              _SectionHeader(title: s.grip_report_support, icon: Icons.front_hand),
              const SizedBox(height: 12),

              _buildSupportFingerCards(state.baseline!.landmarks, s),

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
                    Text(s.grip_report_ad_area, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await _confirmDelete(context, s);
                        if (ok) {
                          await ref.read(gripBaselineProvider.notifier).deleteBaseline();
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: Text(s.common_delete), // 🔹 공통 키 사용
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
                      label: Text(s.pose_result_btn_repick), // 🔹 포즈 분석 재사용
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

  Widget _buildSupportFingerCards(List<Offset> landmarks, AppLocalizations s) {
    if (landmarks.length < 21) return Text(s.grip_comp_no_result);

    final middleAngle = _calculateJointAngle(landmarks[9], landmarks[10], landmarks[11]);
    final ringAngle = _calculateJointAngle(landmarks[13], landmarks[14], landmarks[15]);
    final pinkyAngle = _calculateJointAngle(landmarks[17], landmarks[18], landmarks[19]);

    return Column(
      children: [
        GripGaugeCard(
          title: s.grip_report_middle,
          valueText: "${middleAngle.toStringAsFixed(0)}°",
          normalizedValue: ((middleAngle - 70) / 110).clamp(0.0, 1.0),
          labelLeft: s.grip_report_deep,
          labelRight: s.grip_report_shallow,
          color: Colors.orange[800]!,
        ),
        const SizedBox(height: 12),
        GripGaugeCard(
          title: s.grip_report_ring,
          valueText: "${ringAngle.toStringAsFixed(0)}°",
          normalizedValue: ((ringAngle - 60) / 120).clamp(0.0, 1.0),
          labelLeft: s.grip_report_rolled,
          labelRight: s.grip_report_relaxed,
          color: Colors.purple[700]!,
        ),
        const SizedBox(height: 12),
        GripGaugeCard(
          title: s.grip_report_pinky,
          valueText: "${pinkyAngle.toStringAsFixed(0)}°",
          normalizedValue: ((pinkyAngle - 60) / 120).clamp(0.0, 1.0),
          labelLeft: s.grip_report_inner,
          labelRight: s.grip_report_outer,
          color: Colors.red[700]!,
        ),
      ],
    );
  }

  double _calculateJointAngle(Offset a, Offset b, Offset c) {
    final double angle1 = math.atan2(a.dy - b.dy, a.dx - b.dx);
    final double angle2 = math.atan2(c.dy - b.dy, c.dx - b.dx);
    double angle = (angle1 - angle2) * 180 / math.pi;
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  Future<bool> _confirmDelete(BuildContext context, AppLocalizations s) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.grip_report_delete_confirm),
        content: Text(s.grip_report_delete_msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.common_delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }
}

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
    final s = AppLocalizations.of(context)!;
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
                    child: Row(
                      children: [
                        const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(s.grip_report_zoom, style: const TextStyle(color: Colors.white, fontSize: 11)),
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
    final s = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(s.grip_comp_no_result, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onTake,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            child: Text(s.pose_result_btn_repick, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}