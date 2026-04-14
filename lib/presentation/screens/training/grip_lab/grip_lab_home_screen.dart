import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_camera_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_baseline_analysis_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_compare_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_guide_screen.dart';

class GripLabHomeScreen extends ConsumerStatefulWidget {
  const GripLabHomeScreen({super.key});

  @override
  ConsumerState<GripLabHomeScreen> createState() => _GripLabHomeScreenState();
}

class _GripLabHomeScreenState extends ConsumerState<GripLabHomeScreen> {
  // 🔒 네비게이션 잠금 장치
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    // ✅ [수정됨] ref.listen을 build 메서드 최상단으로 이동
    // 로그인이 안 되어 있어도 리스너를 등록해두는 것은 문제되지 않습니다.
    ref.listen<GripBaselineState>(gripBaselineProvider, (prev, next) {
      final msg = next.errorMessage;
      if (msg == null || msg.isEmpty) return;

      // 화면이 살아있을 때만 스낵바 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      ref.read(gripBaselineProvider.notifier).clearError();
    });

    // 🔥 로그인 상태 실시간 감지
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // 2. 비로그인 상태 -> 로그인 유도 화면
        if (user == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(),
            body: _buildLoginPrompt(context),
          );
        }

        // 3. 로그인 상태 -> 메인 콘텐츠 표시
        return _buildMainContent(context);
      },
    );
  }

  // --- [UI 구성 요소] ---

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text("그립 연구소", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black,
      bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0))),
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
              "나만의 그립 기준을 저장하고 분석하려면\n로그인이 필요합니다.",
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
    // ✅ [수정됨] 여기서 ref.listen 제거됨 (위로 이동)

    final baselineState = ref.watch(gripBaselineProvider);
    final hasBaseline = baselineState.hasBaseline;
    final isLoading = baselineState.isLoading;

    // 🔒 버튼 활성화 조건: 로딩 중이 아니고, 화면 이동 중도 아닐 때만
    final bool canClick = !isLoading && !_isNavigating;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("내 그립, 기록하고\n비교하기.", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.25)),
                  const SizedBox(height: 8),
                  Text("정답은 없지만, 나에게 잘 맞는 ‘기준’은 있습니다.\n가장 좋았던 그립을 저장하고, 매일 그 감각을 맞춰보세요.", style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                  const SizedBox(height: 22),

                  Expanded(
                    child: ListView(
                      children: [
                        _InfoCard(icon: Icons.camera_alt_rounded, title: "촬영 & 저장", desc: "손을 비추면 뼈대를 추적합니다.\n가장 마음에 드는 그립을 '기준'으로 저장하세요.", tint: Colors.cyan),
                        const SizedBox(height: 12),
                        _InfoCard(icon: Icons.compare_arrows_rounded, title: "비교/교정", desc: "기준과 달라진 손가락을 찾아내어 조언해줍니다.", tint: Colors.indigo),
                        const SizedBox(height: 12),
                        _InfoCard(icon: Icons.insights_rounded, title: "수치 분석", desc: "엄지-검지 사이 거리, 손가락 굽힘 각도 등\n미세한 차이를 수치로 확인할 수 있어요.", tint: Colors.orange),
                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: hasBaseline ? Colors.cyan.withOpacity(0.5) : Colors.grey.withOpacity(0.3), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(hasBaseline ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: hasBaseline ? Colors.cyan[700] : Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Text(hasBaseline ? "기준 그립이 저장되어 있습니다." : "아직 기준 그립이 없습니다.", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[850])),
                              ]),
                              const SizedBox(height: 8),
                              Text(hasBaseline ? "저장된 기준 데이터를 확인하거나, 아래 버튼을 눌러 비교 훈련을 시작하세요." : "먼저 [촬영하기] 버튼을 눌러 기준 그립을 만들어주세요.", style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),

                              if (hasBaseline) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    // ✅ canClick 적용
                                    onPressed: canClick ? () => _safeNavigate(const GripBaselineAnalysisScreen()) : null,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red[800],
                                      side: BorderSide(color: Colors.cyan[200]!),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.analytics_outlined, size: 18),
                                    label: const Text("저장된 기준 데이터(수치) 보기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          // ✅ canClick 적용
                          onPressed: canClick ? () => _safeNavigate(const GripCompareScreen()) : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.indigo.withOpacity(0.6), width: 2),
                            foregroundColor: Colors.indigo[800],
                          ),
                          child: _isNavigating // 이동 중이면 로딩 표시
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo))
                              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.compare_arrows_rounded, size: 22), SizedBox(height: 4), Text("비교/교정 하기", style: TextStyle(fontWeight: FontWeight.bold))]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          // ✅ [변경] GripGuideScreen으로 이동 (가이드 먼저)
                          onPressed: canClick ? () => _safeNavigate(const GripGuideScreen()) : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.cyan.withOpacity(0.6), width: 2),
                            foregroundColor: Colors.cyan[700],
                          ),
                          child: _isNavigating // 이동 중이면 로딩 표시
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan))
                              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_rounded, size: 22), SizedBox(height: 4), Text("새로 촬영하기", style: TextStyle(fontWeight: FontWeight.bold))]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isLoading) Container(color: Colors.white.withOpacity(0.65), child: const Center(child: CircularProgressIndicator(color: Colors.cyan))),
          ],
        ),
      ),
    );
  }

  // --- [안전한 이동 함수] ---
  Future<void> _safeNavigate(Widget page) async {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _isNavigating = false);
      ref.read(gripBaselineProvider.notifier).fetchBaseline();
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final String title; final String desc; final Color tint;
  const _InfoCard({required this.icon, required this.title, required this.desc, required this.tint});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: tint.withOpacity(0.22), width: 1.4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: tint.withOpacity(0.10), shape: BoxShape.circle), child: Icon(icon, color: tint, size: 24)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 4), Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4))]))]),
    );
  }
}