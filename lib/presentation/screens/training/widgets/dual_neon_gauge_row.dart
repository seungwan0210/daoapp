// lib/presentation/screens/training/widgets/dual_neon_gauge_row.dart

import 'package:flutter/material.dart';

class DualNeonGaugeRow extends StatelessWidget {
  final double? phoenixRating;
  final double? liveRating;
  final double gaugeSize; // 기본 목표 사이즈 (화면에 맞춰 줄어듦)
  final Duration duration;

  const DualNeonGaugeRow({
    Key? key,
    this.phoenixRating,
    this.liveRating,
    this.gaugeSize = 140,
    this.duration = const Duration(milliseconds: 2400),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasPhoenix = phoenixRating != null && phoenixRating! > 0;
    final hasLive = liveRating != null && liveRating! > 0;

    if (!hasPhoenix && !hasLive) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final gaugeCount = (hasPhoenix ? 1 : 0) + (hasLive ? 1 : 0);
        if (gaugeCount == 0) {
          return const SizedBox.shrink();
        }

        // 두 개 있을 때만 사이 간격 고정 16px
        const spacing = 16.0;
        final totalSpacing = gaugeCount == 2 ? spacing : 0.0;

        // 각 게이지에 쓸 수 있는 최대 너비
        final perGaugeMaxWidth = (maxWidth - totalSpacing) / gaugeCount;

        // 최소 80, 최대 perGaugeMaxWidth 안에서 clamp
        final effectiveSize = gaugeSize.clamp(80.0, perGaugeMaxWidth);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasPhoenix) ...[
              _NeonGauge(
                value: phoenixRating!,
                max: 30.0,
                label: "PHOENIX",
                gradient: const [Colors.cyan, Colors.greenAccent, Colors.yellow],
                duration: duration,
                size: effectiveSize,
              ),
              if (hasLive) const SizedBox(width: spacing),
            ],
            if (hasLive)
              _NeonGauge(
                value: liveRating!,
                max: 18.0,
                label: "LIVE",
                gradient: const [Colors.orangeAccent, Colors.deepOrange, Colors.redAccent],
                duration: duration,
                size: effectiveSize,
              ),
          ],
        );
      },
    );
  }
}

class _NeonGauge extends StatelessWidget {
  final double value;
  final double max;
  final String label;
  final List<Color> gradient;
  final Duration duration;
  final double size;

  const _NeonGauge({
    required this.value,
    required this.max,
    required this.label,
    required this.gradient,
    required this.duration,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        final progress = (animValue / max).clamp(0.0, 1.0);

        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _NeonArcPainter(progress: progress, colors: gradient),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _formatRating(animValue),
                      style: TextStyle(
                        fontSize: size * 0.22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        shadows: const [
                          Shadow(color: Colors.white, blurRadius: 10),
                          Shadow(color: Colors.cyanAccent, blurRadius: 20),
                        ],
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: size * 0.08,
                        color: Colors.black54,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatRating(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _NeonArcPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _NeonArcPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.88;

    // 배경 서클
    final bg = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = size.width * 0.12
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bg);

    // 네온 아크
    final arc = Paint()
      ..shader = LinearGradient(colors: colors).createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.75 * 3.14159,
      progress * 2.5 * 3.14159,
      false,
      arc,
    );

    // 외곽 글로우
    final glow = Paint()
      ..color = colors.first.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
      ..strokeWidth = size.width * 0.18
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.75 * 3.14159,
      progress * 2.5 * 3.14159,
      false,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
