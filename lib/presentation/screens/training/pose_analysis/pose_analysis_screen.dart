import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
// ✅ 가이드 화면 import 필수 (경로가 다르면 수정해주세요)
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_guide_screen.dart';

class PoseAnalysisScreen extends ConsumerWidget {
  const PoseAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white, // 깔끔한 흰색 배경
      appBar: AppBar(
        title: const Text("AI 자세 분석", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 타이틀 영역
              const Text(
                "내 스로우, 분석하기.",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
              ),
              const SizedBox(height: 8),
              Text(
                "영상을 업로드하면 뼈대와 궤적을 추적하여\n시각적으로 분석해 드립니다.",
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 30),

              // 2. 기능 설명 (AppCard 스타일)
              Expanded(
                child: ListView(
                  children: [
                    _buildInfoCard(
                      Icons.accessibility_new_rounded,
                      "스켈레톤(뼈대) 분석",
                      "어깨, 팔꿈치, 손목의 움직임을 뼈대로 시각화합니다.",
                      Colors.cyan,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      Icons.timeline,
                      "손목 궤적 트래킹",
                      "릴리즈 순간의 손목 이동 경로를 선으로 그려줍니다.",
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      Icons.slow_motion_video,
                      "프레임 단위 정밀 진단",
                      "30FPS 고화질 분석으로 미세한 흔들림까지 확인하세요.",
                      Colors.indigo,
                    ),
                  ],
                ),
              ),

              // 3. 하단 시작 버튼
              ElevatedButton(
                onPressed: () {
                  // 🔥 [수정됨] 갤러리를 바로 열지 않고, 가이드 화면으로 이동합니다.
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PoseAnalysisGuideScreen())
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[600], // Cyan 테마
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("영상 선택하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String desc, Color color) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}