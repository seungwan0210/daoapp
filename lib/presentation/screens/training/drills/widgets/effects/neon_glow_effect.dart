// lib/presentation/screens/training/drills/widgets/effects/neon_glow_effect.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

class NeonGlowEffect extends StatefulWidget {
  final bool trigger;           // true일 때 발동
  final Widget child;
  final Color glowColor;        // 기본: cyan
  final Duration duration;      // 발동 시간
  final double maxGlowSize;     // 최대 글로우 크기

  const NeonGlowEffect({
    super.key,
    required this.trigger,
    required this.child,
    this.glowColor = Colors.cyan,
    this.duration = const Duration(milliseconds: 1500),
    this.maxGlowSize = 30.0,
  });

  @override
  State<NeonGlowEffect> createState() => _NeonGlowEffectState();
}

class _NeonGlowEffectState extends State<NeonGlowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: widget.maxGlowSize).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.trigger) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(NeonGlowEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 트리거가 꺼졌다 켜질 때 애니메이션 리셋 및 재시작
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = _glowAnimation.value;
        final scale = _scaleAnimation.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. 네온 아우라 (5겹 중첩으로 깊이감 표현)
            ...List.generate(5, (index) {
              final opacity = (1.0 - index * 0.15).clamp(0.0, 1.0);
              final size = glow * (1 + index * 0.3);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.glowColor.withOpacity(opacity * 0.4),
                    boxShadow: [
                      BoxShadow(
                        color: widget.glowColor.withOpacity(opacity),
                        blurRadius: size * 0.8,
                        spreadRadius: size * 0.3,
                      ),
                    ],
                  ),
                ),
              );
            }),

            // 2. 메인 콘텐츠 위젯 (스케일 및 회전 연출)
            Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: _controller.value * 0.1, // 0.1 라디안 정도 살짝 회전
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}