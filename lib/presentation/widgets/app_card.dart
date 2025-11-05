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
      margin: margin ?? cardTheme.margin ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: color ?? cardTheme.color ?? Colors.white,
        elevation: elevation ?? cardTheme.elevation ?? 4,
        shadowColor: cardTheme.shadowColor ?? Colors.black.withOpacity(0.08),
        shape: shape ?? cardTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}