// lib/presentation/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/screens/admin/forms/notice_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/news_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/sponsor_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/point_award_screen.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard('미검수 제출', '12건', Colors.orange),
          _buildStatCard('진행중 일정', '3건', Colors.blue),
          _buildStatCard('오늘 포인트 부여', '245pt', Colors.green),
          const SizedBox(height: 24),

          _buildMenuTile(context, '공지 등록', Icons.campaign, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NoticeFormScreen()),
            );
          }),
          _buildMenuTile(context, '뉴스 등록', Icons.article, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewsFormScreen()), // const OK
            );
          }),
          _buildMenuTile(context, '스폰서 배너 등록', Icons.image, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SponsorFormScreen()),
            );
          }),
          _buildMenuTile(context, '포인트 수동 부여', Icons.add_circle, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => provider.ChangeNotifierProvider<RankingProvider>(
                  create: (_) => sl<RankingProvider>(),
                  child: const PointAwardScreen(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(value[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00D4FF)),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}