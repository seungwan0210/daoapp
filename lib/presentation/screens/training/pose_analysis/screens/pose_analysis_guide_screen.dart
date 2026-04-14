import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_setting_screen.dart';

class PoseAnalysisGuideScreen extends ConsumerWidget {
  const PoseAnalysisGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("촬영 가이드", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    "정확한 분석을 위해\n다음 사항을 확인해 주세요.",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "AI가 뼈대를 잘 인식할수록 분석 결과가 정확해집니다.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  // ✅ 좋은 예시 섹션
                  _buildGuideSection(
                    title: "Good: 권장하는 촬영 방법",
                    imagePath: "assets/images/guide_good.png",
                    isGood: true,
                    points: [
                      "영상 길이는 20초~25초 사이가 분석 및 저장에 가장 적합합니다.",
                      "분석할 사용자의 측면 모습(90도)에서 촬영해 주세요.",
                      "머리부터 상체, 골반, 무릎까지 나오도록 찍는 것이 좋습니다.",
                      "긴팔보다는 반팔을 입어야 관절 위치가 정확히 인식됩니다.",
                      "강한 역광이나 배경의 방해 요소가 없는 밝은 곳이 좋습니다.",
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ❌ 나쁜 예시 섹션
                  _buildGuideSection(
                    title: "Bad: 피해야 할 촬영 방법",
                    imagePath: "assets/images/guide_bad.png",
                    isGood: false,
                    points: [
                      "영상이 너무 길면 분석 시간이 오래 걸리거나 앱이 종료될 수 있습니다.",
                      "상반신만 찍으면 중요 포인트와 궤적 추적이 안 될 수 있습니다.",
                      "정면이나 45도 각도는 현재 정확한 분석이 어렵습니다.",
                      "신체를 가리는 헐렁한 옷이나 장신구는 피해 주세요.",
                      "강한 조명이나 촬영 중 배경에 다른 움직임이 있으면 분석이 부정확할 수 있습니다.",
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
                onPressed: () async {
                  // 1. 기존 데이터 초기화 (혹시 남아있을 데이터 삭제)
                  ref.read(poseAnalysisProvider.notifier).reset();

                  // 2. 갤러리 열기
                  final success = await ref.read(poseAnalysisProvider.notifier).pickVideo();

                  // 3. 영상 선택 성공 시 설정 화면으로 이동 (뒤로가기 시 다시 가이드 안 나오게 Replacement)
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
                child: const Text("확인했습니다 (영상 선택)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        // 타이틀 (아이콘 + 텍스트)
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

        // 이미지 영역
        Container(
          width: double.infinity,
          height: 220, // 이미지 높이 적절히 조절
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {}, // 이미지 로드 실패 시 에러 방지
            ),
          ),
          // 이미지가 없을 때(로딩 실패 등) 보여줄 placeholder
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.black12),
          ),
        ),
        const SizedBox(height: 16),

        // 설명 텍스트 영역 (박스 형태)
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

  // 글머리 기호 텍스트 위젯
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