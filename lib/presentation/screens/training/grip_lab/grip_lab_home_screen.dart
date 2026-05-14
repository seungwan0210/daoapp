import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_camera_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_baseline_analysis_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_compare_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/grip_guide_screen.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class GripLabHomeScreen extends ConsumerStatefulWidget {
  const GripLabHomeScreen({super.key});

  @override
  ConsumerState<GripLabHomeScreen> createState() => _GripLabHomeScreenState();
}

class _GripLabHomeScreenState extends ConsumerState<GripLabHomeScreen> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<GripBaselineState>(gripBaselineProvider, (prev, next) {
      final msg = next.errorMessage;
      if (msg == null || msg.isEmpty) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      ref.read(gripBaselineProvider.notifier).clearError();
    });

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(context),
            body: _buildLoginPrompt(context),
          );
        }

        return _buildMainContent(context);
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AppBar(
      title: Text(s.grip_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black,
      bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0))
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              s.history_login_required,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              s.pose_login_msg, // 🔹 자세 분석과 동일한 유도 메시지 재사용 권장
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, RouteConstants.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[600],
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(s.login_title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final baselineState = ref.watch(gripBaselineProvider);
    final hasBaseline = baselineState.hasBaseline;
    final isLoading = baselineState.isLoading;
    final bool canClick = !isLoading && !_isNavigating;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.grip_main_title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.25)),
                  const SizedBox(height: 8),
                  Text(s.grip_main_sub, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                  const SizedBox(height: 22),

                  Expanded(
                    child: ListView(
                      children: [
                        _InfoCard(icon: Icons.camera_alt_rounded, title: s.grip_info1_title, desc: s.grip_info1_desc, tint: Colors.cyan),
                        const SizedBox(height: 12),
                        _InfoCard(icon: Icons.compare_arrows_rounded, title: s.grip_info2_title, desc: s.grip_info2_desc, tint: Colors.indigo),
                        const SizedBox(height: 12),
                        _InfoCard(icon: Icons.insights_rounded, title: s.grip_info3_title, desc: s.grip_info3_desc, tint: Colors.orange),
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
                                Text(hasBaseline ? s.grip_status_has : s.grip_status_no, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[850])),
                              ]),
                              const SizedBox(height: 8),
                              Text(hasBaseline ? s.grip_msg_has : s.grip_msg_no, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),

                              if (hasBaseline) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: canClick ? () => _safeNavigate(const GripBaselineAnalysisScreen()) : null,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red[800],
                                      side: BorderSide(color: Colors.cyan[200]!),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.analytics_outlined, size: 18),
                                    label: Text(s.grip_btn_view_data, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                          onPressed: canClick ? () => _safeNavigate(const GripCompareScreen()) : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.indigo.withOpacity(0.6), width: 2),
                            foregroundColor: Colors.indigo[800],
                          ),
                          child: _isNavigating
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo))
                              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.compare_arrows_rounded, size: 22), const SizedBox(height: 4), Text(s.grip_btn_compare, style: const TextStyle(fontWeight: FontWeight.bold))]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: canClick ? () => _safeNavigate(const GripGuideScreen()) : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: Colors.cyan.withOpacity(0.6), width: 2),
                            foregroundColor: Colors.cyan[700],
                          ),
                          child: _isNavigating
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan))
                              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.camera_alt_rounded, size: 22), const SizedBox(height: 4), Text(s.grip_btn_new_shoot, style: const TextStyle(fontWeight: FontWeight.bold))]),
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

  Future<void> _safeNavigate(Widget page) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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