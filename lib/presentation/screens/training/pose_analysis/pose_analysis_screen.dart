import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart'; // 로그인 라우트용
// ✅ 가이드 화면 import
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_guide_screen.dart';

class PoseAnalysisScreen extends ConsumerWidget {
  const PoseAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔥 로그인 상태 실시간 감지
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // 1. 비로그인 상태 -> 로그인 유도 화면
        if (user == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(),
            body: _buildLoginPrompt(context),
          );
        }

        // 2. 로그인 상태 -> 정상 기능 화면 (프로필 체크 없이 바로 보여줌)
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(),
          body: _buildMainContent(context),
        );
      },
    );
  }

  // 상단 앱바 (공통 사용)
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text("AI 자세 분석", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black,
    );
  }

  // 🔒 로그인 유도 화면
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              "로그인이 필요해요",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "자세 분석 기능을 사용하고 기록을 저장하려면\n로그인이 필요합니다.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 로그인 화면으로 이동
                  Navigator.pushNamed(context, RouteConstants.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[600],
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("로그인 하러 가기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📸 메인 기능 화면 (로그인 된 경우)
  Widget _buildMainContent(BuildContext context) {
    return SafeArea(
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
                // 🚀 가이드 화면으로 이동
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PoseAnalysisGuideScreen())
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan[600],
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("영상 선택하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
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