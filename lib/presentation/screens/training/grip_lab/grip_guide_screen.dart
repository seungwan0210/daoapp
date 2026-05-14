import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:daoapp/presentation/screens/training/grip_lab/grip_camera_screen.dart';
import 'package:daoapp/presentation/providers/training/grip_lab_provider.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class GripGuideScreen extends ConsumerWidget {
  const GripGuideScreen({super.key});

  Future<void> _handleStart(BuildContext context, WidgetRef ref) async {
    final s = AppLocalizations.of(context)!;
    final status = await Permission.camera.request();

    if (status.isGranted) {
      ref.read(gripLabProvider.notifier).stopAnalysis();

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GripCameraScreen()),
        );
      }
    } else if (status.isPermanentlyDenied) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(s.grip_auth_camera_title),
            content: Text(s.grip_auth_camera_msg),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.common_cancel)), // 🔹 공통 키 cancel 사용
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(ctx);
                },
                child: Text(s.grip_auth_go_settings),
              ),
            ],
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.grip_auth_camera_denied)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(s.grip_guide_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    s.grip_guide_main,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.grip_guide_sub,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  _buildGuideSection(
                    title: s.grip_guide_good_title,
                    imagePath: "assets/images/grip_guide_good.png",
                    isGood: true,
                    points: [
                      s.grip_guide_good_1,
                      s.grip_guide_good_2,
                      s.grip_guide_good_3,
                      s.grip_guide_good_4,
                      s.grip_guide_good_5,
                    ],
                  ),

                  const SizedBox(height: 30),

                  _buildGuideSection(
                    title: s.grip_guide_bad_title,
                    imagePath: "assets/images/grip_guide_bad.png",
                    isGood: false,
                    points: [
                      s.grip_guide_bad_1,
                      s.grip_guide_bad_2,
                      s.grip_guide_bad_3,
                      s.grip_guide_bad_4,
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
                onPressed: () => _handleStart(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[700],
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(s.grip_guide_btn_start, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

        AspectRatio(
          aspectRatio: 3 / 2,
          child: Container(
            width: double.infinity,
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
              child: Icon(Icons.camera_alt_outlined, size: 40, color: Colors.black12),
            ),
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