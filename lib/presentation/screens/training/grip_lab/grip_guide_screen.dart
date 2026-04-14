import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ 권한 처리를 위해 추가

import 'package:daoapp/presentation/screens/training/grip_lab/grip_camera_screen.dart';
import 'package:daoapp/presentation/providers/training/grip_lab_provider.dart';

class GripGuideScreen extends ConsumerWidget {
  const GripGuideScreen({super.key});

  // ✅ 권한 체크 및 화면 이동 로직 분리
  Future<void> _handleStart(BuildContext context, WidgetRef ref) async {
    // 1. 카메라 권한 요청 (가장 중요한 단계)
    final status = await Permission.camera.request();

    if (status.isGranted) {
      // 2. 권한 허용 시, 기존 분석기 중지 후 카메라 화면으로 이동
      ref.read(gripLabProvider.notifier).stopAnalysis();
      
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GripCameraScreen()),
        );
      }
    } else if (status.isPermanentlyDenied) {
      // 3. 사용자가 설정을 완전히 막아둔 경우 (설정 앱으로 유도)
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("카메라 권한 필요"),
            content: const Text("설정에서 카메라 권한을 허용해야 그립 분석 기능을 사용할 수 있습니다."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(ctx);
                },
                child: const Text("설정으로 이동"),
              ),
            ],
          ),
        );
      }
    } else {
      // 거부했을 때 단순 안내
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("촬영을 위해 카메라 권한 허용이 필요합니다.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("그립 촬영 가이드", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  const Text(
                    "정확한 그립 분석을 위해\n다음 사항을 확인해 주세요.",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "손가락 마디와 손톱 위치가 명확할수록 분석이 정교해집니다.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  // ✅ 좋은 예시 섹션
                  _buildGuideSection(
                    title: "Good: 권장하는 촬영 방법",
                    imagePath: "assets/images/grip_guide_good.png",
                    isGood: true,
                    points: [
                      "다트를 잡은 손을 '정확한 측면(90도)'에서 촬영해 주세요.",
                      "엄지와 검지가 겹친 부위를 + 포인트에 맞춰주세요.",
                      "배경이 복잡하지 않은 깔끔한 곳이 좋습니다.",
                      "손목까지 화면 안에 들어오도록 거리를 조절해 주세요.",
                      "조명이 밝은 곳에서 촬영해야 손가락 마디가 잘 보입니다.",
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ❌ 나쁜 예시 섹션
                  _buildGuideSection(
                    title: "Bad: 피해야 할 촬영 방법",
                    imagePath: "assets/images/grip_guide_bad.png",
                    isGood: false,
                    points: [
                      "정면에서 찍으면 손가락 깊이(Depth) 분석이 불가능합니다.",
                      "손가락이 다트 배럴에 완전히 가려지면 안 됩니다.",
                      "너무 어둡거나 역광인 곳은 피해주세요.",
                      "카메라가 너무 멀어서 손이 작게 나오면 인식이 어렵습니다.",
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 하단 버튼 영역
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: ElevatedButton(
                // ✅ 수정된 핸들러 연결
                onPressed: () => _handleStart(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[700],
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("확인했습니다 (촬영 시작)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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