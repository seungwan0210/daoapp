// lib/presentation/screens/training/drills/widgets/effects/fireworks_effect.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';

class FireworksEffect extends StatefulWidget {
  final bool trigger;
  final Duration duration;
  final Widget child;

  const FireworksEffect({
    super.key,
    required this.trigger,
    this.duration = const Duration(seconds: 6),
    required this.child,
  });

  @override
  State<FireworksEffect> createState() => _FireworksEffectState();
}

class _FireworksEffectState extends State<FireworksEffect>
    with TickerProviderStateMixin {
  late ConfettiController _topController;
  late ConfettiController _leftController;
  late ConfettiController _rightController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _topController = ConfettiController(duration: widget.duration);
    _leftController = ConfettiController(duration: widget.duration);
    _rightController = ConfettiController(duration: widget.duration);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    if (widget.trigger) {
      _launchFireworks();
    }
  }

  @override
  void didUpdateWidget(FireworksEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _launchFireworks();
    }
  }

  void _launchFireworks() {
    _topController.play();
    _leftController.play();
    _rightController.play();
  }

  @override
  void dispose() {
    _topController.dispose();
    _leftController.dispose();
    _rightController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // 중앙에서 터지는 메인 불꽃놀이
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _topController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.red,
              Colors.yellow,
              Colors.white,
              Colors.blue,
              Colors.purple,
              Colors.orange,
              Colors.cyan,
            ],
            emissionFrequency: 0.02,
            numberOfParticles: 80,
            gravity: 0.15,
            maxBlastForce: 120,
            minBlastForce: 40,
            particleDrag: 0.05,
            createParticlePath: _drawFirework,
          ),
        ),

        // 좌우에서 추가 불꽃
        Align(
          alignment: Alignment.centerLeft,
          child: ConfettiWidget(
            confettiController: _leftController,
            blastDirection: -math.pi / 4,
            emissionFrequency: 0.05,
            numberOfParticles: 40,
            gravity: 0.2,
            colors: const [Colors.red, Colors.orange, Colors.yellow],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: ConfettiWidget(
            confettiController: _rightController,
            blastDirection: math.pi / 4,
            emissionFrequency: 0.05,
            numberOfParticles: 40,
            gravity: 0.2,
            colors: const [Colors.blue, Colors.cyan, Colors.purple],
          ),
        ),

        // 화면 전체에 빛나는 펄스 효과
        if (widget.trigger)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                color: Colors.white.withOpacity(
                  0.15 * _pulseController.value,
                ),
              );
            },
          ),
      ],
    );
  }

  Path _drawFirework(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    path.addOval(Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: radius,
    ));

    // 불꽃처럼 퍼지는 선들 추가
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * math.pi / 180;
      final x2 = centerX + radius * 1.5 * math.cos(angle);
      final y2 = centerY + radius * 1.5 * math.sin(angle);
      path.moveTo(centerX, centerY);
      path.lineTo(x2, y2);
    }

    return path;
  }
}