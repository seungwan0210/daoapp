import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_setting_screen.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class PoseAnalysisGuideScreen extends ConsumerWidget {
  const PoseAnalysisGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(s.pose_guide_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.pose_guide_main,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.pose_guide_sub,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  // ✅ Good 가이드
                  _buildGuideSection(
                    title: s.pose_guide_good_title,
                    imagePath: "assets/images/guide_good.png",
                    isGood: true,
                    points: [
                      s.pose_guide_good_1,
                      s.pose_guide_good_2,
                      s.pose_guide_good_3,
                      s.pose_guide_good_4,
                      s.pose_guide_good_5,
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ❌ Bad 가이드
                  _buildGuideSection(
                    title: s.pose_guide_bad_title,
                    imagePath: "assets/images/guide_bad.png",
                    isGood: false,
                    points: [
                      s.pose_guide_bad_1,
                      s.pose_guide_bad_2,
                      s.pose_guide_bad_3,
                      s.pose_guide_bad_4,
                      s.pose_guide_bad_5,
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  ref.read(poseAnalysisProvider.notifier).reset();
                  final success = await ref.read(poseAnalysisProvider.notifier).pickVideo();
                  if (success && context.mounted) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const PoseAnalysisSettingScreen())
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[600],
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(s.pose_guide_btn_confirm, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection({
    required String title,
    required String imagePath,
    required bool isGood,
    required List<String> points,
  }) {
    final Color mainColor = isGood ? Colors.green[700]! : Colors.red[700]!;
    final Color bgColor = isGood ? Colors.green[50]! : Colors.red[50]!;
    final Color borderColor = isGood ? Colors.green[200]! : Colors.red[200]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isGood ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: mainColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mainColor)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {},
            ),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.black12),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: points.map((text) => _buildBulletPoint(text)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•", style: TextStyle(fontWeight: FontWeight.bold, height: 1.4)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}