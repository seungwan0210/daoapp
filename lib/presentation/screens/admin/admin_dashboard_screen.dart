// lib/presentation/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/screens/admin/forms/notice_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/news_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/forms/sponsor_form_screen.dart';
import 'package:daoapp/presentation/screens/admin/point_award_screen.dart';
import 'package:daoapp/presentation/screens/admin/event_create_screen.dart';
import 'package:daoapp/presentation/screens/admin/event_list_screen.dart'; // ← 추가!
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuTile(context, '공지 등록', Icons.campaign, const NoticeFormScreen()),
          _buildMenuTile(context, '뉴스 등록', Icons.article, const NewsFormScreen()),
          _buildMenuTile(context, '스폰서 배너 등록', Icons.image, const SponsorFormScreen()),
          _buildMenuTile(context, '포인트 수동 부여', Icons.add_circle, const PointAwardScreen()),
          _buildMenuTile(context, '경기 등록', Icons.sports_esports, const EventCreateScreen()),
          _buildMenuTile(context, '경기 관리', Icons.list_alt, const EventListScreen()), // ← 사용!
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, IconData icon, Widget screen) {
    return AppCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}