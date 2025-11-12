import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed; // 추가: 커스텀 뒤로 가기 동작

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
        tooltip: '뒤로 가기',
      )
          : null,
      centerTitle: false,
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.95),
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      elevation: 0.5,
      actions: actions ?? [const SizedBox(width: 8)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}