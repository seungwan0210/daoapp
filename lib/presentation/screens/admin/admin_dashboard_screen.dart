// lib/presentation/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          _buildMenuTile(context, '공지 등록', Icons.campaign, RouteConstants.noticeForm),
          _buildMenuTile(context, '뉴스 등록', Icons.article, RouteConstants.newsForm),
          _buildMenuTile(context, '스폰서 배너 등록', Icons.image, RouteConstants.sponsorForm),
          _buildMenuTile(context, '포인트 수동 부여', Icons.add_circle, RouteConstants.pointAward),
          _buildMenuTile(context, '포인트 관리', Icons.list_alt, RouteConstants.pointAwardList),
          _buildMenuTile(context, '경기 등록', Icons.sports_esports, RouteConstants.eventCreate),
          _buildMenuTile(context, '경기 관리', Icons.list_alt, RouteConstants.eventList),
          _buildMenuTile(context, 'KDF 정회원 등록', Icons.card_membership, RouteConstants.memberRegister),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, IconData icon, String route) {
    return AppCard(
      onTap: () => Navigator.pushNamed(context, route), // pushNamed 적용
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
      ),
    );
  }
}