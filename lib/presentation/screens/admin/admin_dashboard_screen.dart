// lib/presentation/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart'; // 추가!

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'ADMIN',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: '공지·뉴스·스폰서·사진',
            items: [
              _buildItem(
                context,
                icon: Icons.campaign,
                title: '공지 등록',
                subtitle: '공지 작성·수정·삭제·링크',
                route: RouteConstants.noticeForm,
              ),
              _buildItem(
                context,  // ← rivew → context 수정!
                icon: Icons.article,
                title: '뉴스 등록',
                subtitle: '뉴스 작성·수정·삭제·링크',
                route: RouteConstants.newsForm,
              ),
              _buildItem(
                context,
                icon: Icons.image,
                title: '스폰서 배너 등록',
                subtitle: '스폰서 등록·수정·삭제·링크',
                route: RouteConstants.sponsorForm,
              ),
              _buildItem(
                context,
                icon: Icons.photo_library,
                title: '대회 사진 등록',
                subtitle: '대회 사진 등록·수정·삭제·링크',
                route: RouteConstants.competitionPhotosForm,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            context,
            title: '포인트 관리',
            items: [
              _buildItem(
                context,
                icon: Icons.add_circle,
                title: '포인트 수동 부여',
                subtitle: '스틸리그 포인트 부여·등록',
                route: RouteConstants.pointAward,
              ),
              _buildItem(
                context,
                icon: Icons.list_alt,
                title: '포인트 내역 관리',
                subtitle: '포인트 내역 수정·삭제',
                route: RouteConstants.pointAwardList,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            context,
            title: '스틸리그 경기',
            items: [
              _buildItem(
                context,
                icon: Icons.sports_esports,
                title: '경기 등록',
                subtitle: '스틸리그 경기 일정 등록·예정·종료',
                route: RouteConstants.eventCreate,
              ),
              _buildItem(
                context,
                icon: Icons.list_alt,
                title: '경기 관리',
                subtitle: '스틸리그 경기 삭제·재등록',
                route: RouteConstants.eventList,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            context,
            title: 'KDF 정회원',
            items: [
              _buildItem(
                context,
                icon: Icons.card_membership,
                title: '정회원 등록',
                subtitle: 'KDF 정회원 등록·사진 등록',
                route: RouteConstants.memberRegister,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 섹션 빌더
  Widget _buildSection(BuildContext context, {required String title, required List<Widget> items}) {
    final theme = Theme.of(context);

    return AppCard(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          // 항목 리스트
          Column(
            children: List.generate(items.length, (i) {
              return Column(
                children: [
                  items[i],
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 68, endIndent: 16),
                ],
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // 항목 빌더
  Widget _buildItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required String route,
      }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}