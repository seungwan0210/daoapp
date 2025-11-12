import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';

class MoreMenuButton extends ConsumerWidget {
  const MoreMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);
    final unreadCountAsync = ref.watch(unreadNoticesCountProvider);

    return isAdminAsync.when(
      data: (isAdmin) {
        final count = unreadCountAsync.when(
          data: (count) => count,
          loading: () => 0,
          error: (_, __) => 0,
        );

        return _buildMenuButton(isAdmin, context, count);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMenuButton(bool isAdmin, BuildContext context, int count) {
    return Stack(
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings),
          tooltip: '설정',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'notice',
              child: Row(
                children: [
                  const Icon(Icons.notifications, size: 20),
                  const SizedBox(width: 12),
                  const Text('공지사항'),
                  if (count > 0) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.bug_report, size: 20),
                  SizedBox(width: 12),
                  Text('버그 신고'),
                ],
              ),
            ),
            if (isAdmin)
              const PopupMenuItem(
                value: 'admin',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 20),
                    SizedBox(width: 12),
                    Text('관리자 모드'),
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            if (value == 'notice') {
              Navigator.pushNamed(context, RouteConstants.noticeList);
            } else if (value == 'report') {
              Navigator.pushNamed(context, RouteConstants.report);
            } else if (value == 'admin') {
              Navigator.pushNamed(context, RouteConstants.adminDashboard);
            }
          },
        ),
        // 설정 아이콘 위 배지
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}