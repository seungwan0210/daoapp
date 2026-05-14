import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_guide_screen.dart';
import 'package:daoapp/l10n/app_localizations.dart';

class PoseAnalysisScreen extends ConsumerWidget {
  const PoseAnalysisScreen({super.key});

  @override
  // 🔹 WidgetRef ref 파라미터를 추가하여 오버라이드 오류를 해결합니다.
  Widget build(BuildContext context, WidgetRef ref) {
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

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context),
          body: _buildMainContent(context),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AppBar(
      title: Text(s.pose_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black,
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
              s.pose_login_msg,
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.pose_main_title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 8),
            Text(
              s.pose_main_sub,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: ListView(
                children: [
                  _buildInfoCard(
                    Icons.accessibility_new_rounded,
                    s.pose_feature1_title,
                    s.pose_feature1_desc,
                    Colors.cyan,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    Icons.timeline,
                    s.pose_feature2_title,
                    s.pose_feature2_desc,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    Icons.slow_motion_video,
                    s.pose_feature3_title,
                    s.pose_feature3_desc,
                    Colors.indigo,
                  ),
                ],
              ),
            ),

            ElevatedButton(
              onPressed: () {
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
              child: Text(s.pose_btn_select_video, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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