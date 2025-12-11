// lib/presentation/screens/community/checkout/practice/widgets/dartboard_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DartboardWidget extends StatefulWidget {
  final double size;
  final void Function(String segment) onSegmentTap;

  const DartboardWidget({
    super.key,
    required this.size,
    required this.onSegmentTap,
  });

  @override
  State<DartboardWidget> createState() => _DartboardWidgetState();
}

class _DartboardWidgetState extends State<DartboardWidget>
    with SingleTickerProviderStateMixin {
  String? _highlight;
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _trigger(String segment) {
    HapticFeedback.lightImpact();
    setState(() => _highlight = segment);
    _anim.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _highlight = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // 1. 다트보드 이미지
          Positioned.fill(
            child: ClipOval(
              child: Image.asset(
                'assets/images/dartboard.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),

          // 2. 터치 + 애니메이션 반짝 (디버그 라인 없이!)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox;
                final pos = box.globalToLocal(details.globalPosition);
                final segment = _detectSegment(pos, widget.size);
                if (segment != null) {
                  widget.onSegmentTap(segment);
                  _trigger(segment);
                }
              },
              child: AnimatedBuilder(
                animation: _fade,
                builder: (context, child) {
                  if (_highlight == null) return const SizedBox();
                  return CustomPaint(
                    painter: _AnimPainter(
                      highlight: _highlight!,
                      opacity: _fade.value,
                      size: widget.size,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 애니메이션 반짝 라인 (트리플/더블/Bull/SB)
class _AnimPainter extends CustomPainter {
  final String highlight;
  final double opacity;
  final double size;

  _AnimPainter({required this.highlight, required this.opacity, required this.size});

  @override
  void paint(Canvas canvas, Size _) {
    final center = Offset(size / 2, size / 2);
    final r = size / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = Colors.white.withOpacity(0);

    final type = highlight[0];
    double inner = 0, outer = 0;

    if (type == 'T') {
      paint.color = Colors.red.withOpacity(opacity);
      inner = r * 0.38;
      outer = r * 0.50;
    } else if (type == 'D') {
      paint.color = Colors.cyan.withOpacity(opacity);
      inner = r * 0.69;
      outer = r * 0.80;
    } else if (highlight == "Bull") {
      paint.color = Colors.yellow.withOpacity(opacity);
      canvas.drawCircle(center, r * 0.06, paint);
      return;
    } else if (highlight == "SB") {
      paint.color = Colors.green.withOpacity(opacity);
      inner = r * 0.06;
      outer = r * 0.16;
    } else {
      return;
    }

    canvas.drawCircle(center, inner, paint);
    canvas.drawCircle(center, outer, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

/// 터치 판정 (당신 이미지 기준 최적화)
String? _detectSegment(Offset pos, double size) {
  final center = Offset(size / 2, size / 2);
  final dx = pos.dx - center.dx;
  final dy = pos.dy - center.dy;
  final dist = math.sqrt(dx * dx + dy * dy);
  final radius = size / 2;

  if (dist > radius) return null;

  final double rbull      = radius * 0.06;
  final double rsbull     = radius * 0.16;
  final double rTripleIn  = radius * 0.38;
  final double rTripleOut = radius * 0.50;
  final double rDoubleIn  = radius * 0.69;
  final double rDoubleOut = radius * 0.80;

  String ring;

  if (dist <= rbull) return "Bull";
  if (dist <= rsbull) return "SB";
  if (dist < rTripleIn) ring = "S";
  else if (dist <= rTripleOut) ring = "T";
  else if (dist < rDoubleIn) ring = "S";
  else if (dist <= rDoubleOut) ring = "D";
  else return null;

  double angle = math.atan2(dy, dx);
  if (angle < 0) angle += 2 * math.pi;
  double degrees = angle * 180 / math.pi;
  double shifted = (degrees + 90) % 360;

  const sectors = [20,1,18,4,13,6,10,15,2,17,3,19,7,16,8,11,14,9,12,5];
  final sectorIndex = ((shifted + 9) ~/ 18) % 20;
  final number = sectors[sectorIndex];

  return "$ring$number";
}