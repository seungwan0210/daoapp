// lib/presentation/screens/training/drills/widgets/effects/confetti_effect.dart

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

class ConfettiEffect extends StatefulWidget {
  final bool trigger;
  final Duration duration;
  final Widget child;

  const ConfettiEffect({
    super.key,
    required this.trigger,
    this.duration = const Duration(seconds: 4),
    required this.child,
  });

  @override
  State<ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<ConfettiEffect> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: widget.duration);

    if (widget.trigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.play();
      });
    }
  }

  @override
  void didUpdateWidget(ConfettiEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 트리거가 false -> true로 변할 때 실행
    if (widget.trigger && !oldWidget.trigger) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // 1. 상단 중앙: 폭발형 별 모양 종이조각
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.cyan,
              Colors.pink,
              Colors.yellow,
              Colors.green,
              Colors.purple,
              Colors.orange,
            ],
            createParticlePath: _drawStar, // 🔹 별 모양 경로 함수 호출
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.2,
            maxBlastForce: 80,
            minBlastForce: 20,
          ),
        ),

        // 2. 좌측 중앙: 오른쪽으로 날아가는 효과
        Align(
          alignment: Alignment.centerLeft,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirection: 0, // 0도 (오른쪽)
            emissionFrequency: 0.08,
            numberOfParticles: 20,
            gravity: 0.15,
            colors: const [Colors.red, Colors.blue, Colors.green],
          ),
        ),

        // 3. 우측 중앙: 왼쪽으로 날아가는 효과
        Align(
          alignment: Alignment.centerRight,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirection: math.pi, // 180도 (왼쪽)
            emissionFrequency: 0.08,
            numberOfParticles: 20,
            gravity: 0.15,
            colors: const [Colors.orange, Colors.purple, Colors.cyan],
          ),
        ),
      ],
    );
  }

  /// ⭐️ 별 모양을 그리는 경로 생성 함수
  Path _drawStar(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const points = 5;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius / 2;

    path.moveTo(centerX + outerRadius, centerY);

    for (int i = 1; i <= points * 2; i++) {
      final radius = i % 2 == 0 ? innerRadius : outerRadius;
      final angle = i * math.pi / points;
      final x = centerX + radius * math.cos(angle - math.pi / 2);
      final y = centerY + radius * math.sin(angle - math.pi / 2);
      path.lineTo(x, y);
    }
    path.close();
    return path;
  }
}