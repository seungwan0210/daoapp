// lib/presentation/widgets/app_card.dart
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? margin;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.elevation,
    this.shape,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // 외부 여백
      child: Material(
        color: color ?? cardTheme.color ?? Colors.white,
        elevation: elevation ?? cardTheme.elevation ?? 1.5,
        shape: shape ?? cardTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(8), // 16→10 (내부 여백 최소!)
            child: child,
          ),
        ),
      ),
    );
  }
}