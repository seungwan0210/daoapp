import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔥 추가

class MoreMenuButton extends ConsumerWidget {
  const MoreMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);
    final unreadCountAsync = ref.watch(unreadNoticesCountProvider);
    final s = AppLocalizations.of(context)!; // 🔥 110n 객체 가져오기

    return isAdminAsync.when(
      data: (isAdmin) {
        final count = unreadCountAsync.when(
          data: (count) => count,
          loading: () => 0,
          error: (_, __) => 0,
        );

        return _buildMenuButton(isAdmin, context, count, s);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMenuButton(bool isAdmin, BuildContext context, int count, AppLocalizations s) {
    return Stack(
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings),
          tooltip: s.menu_tooltip_settings, // 🔥 다국어 적용
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'notice',
              child: Row(
                children: [
                  const Icon(Icons.notifications, size: 20),
                  const SizedBox(width: 12),
                  Text(s.menu_notice), // 🔥 다국어 적용
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
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  const Icon(Icons.bug_report, size: 20),
                  const SizedBox(width: 12),
                  Text(s.menu_report), // 🔥 다국어 적용
                ],
              ),
            ),
            PopupMenuItem(
              value: isAdmin ? 'admin_block' : 'block_manage',
              child: Row(
                children: [
                  Icon(isAdmin ? Icons.admin_panel_settings : Icons.person_off, size: 20),
                  const SizedBox(width: 12),
                  // ✅ 관리자 여부에 따라 다국어 라벨 분기
                  Text(isAdmin ? s.menu_admin_block_manage : s.menu_block_manage),
                ],
              ),
            ),
            if (isAdmin)
              PopupMenuItem(
                value: 'admin',
                child: Row(
                  children: [
                    const Icon(Icons.dashboard_customize, size: 20),
                    const SizedBox(width: 12),
                    Text(s.menu_admin_mode), // 🔥 다국어 적용
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            if (value == 'notice') {
              Navigator.pushNamed(context, RouteConstants.noticeList);
            } else if (value == 'report') {
              Navigator.pushNamed(context, RouteConstants.report);
            } else if (value == 'block_manage') {
              Navigator.pushNamed(context, RouteConstants.blockList);
            } else if (value == 'admin_block') {
              Navigator.pushNamed(context, RouteConstants.adminBlockManage);
            } else if (value == 'admin') {
              Navigator.pushNamed(context, RouteConstants.adminDashboard);
            }
          },
        ),
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