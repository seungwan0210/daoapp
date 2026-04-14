// lib/presentation/screens/training/widgets/report/training_report_animator.dart

import 'package:flutter/material.dart';

/// 🔹 전/후 값 사이를 부드럽게 애니메이션해주는 공용 위젯.
///
/// - 예: 성장 게이지 0.45 → 0.73 으로 자연스럽게 올라가게 만들 때
/// - 예: "이번 세션 XP +24" 같은 숫자도 전 값 → 후 값으로 애니메이션 가능
///
/// 사용 예시:
///
/// TrainingReportAnimator(
///   from: beforeRatio,
///   to: afterRatio,
///   duration: const Duration(milliseconds: 800),
///   builder: (context, value) {
///     return LinearProgressIndicator(value: value);
///   },
/// )
class TrainingReportAnimator extends StatefulWidget {
  final double from;
  final double to;
  final Duration duration;
  final Curve curve;

  /// 애니메이션을 실제로 수행할지 여부
  /// - false 이면 그냥 to 값으로 고정 렌더링
  final bool animate;

  /// 애니메이션이 완료되었을 때 한 번 호출
  final VoidCallback? onCompleted;

  /// 현재 값(0.0 ~ 1.0)을 바탕으로 위젯을 빌드하는 빌더
  final Widget Function(BuildContext context, double value) builder;

  const TrainingReportAnimator({
    super.key,
    required this.from,
    required this.to,
    required this.builder,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.animate = true,
    this.onCompleted,
  });

  @override
  State<TrainingReportAnimator> createState() => _TrainingReportAnimatorState();
}

class _TrainingReportAnimatorState extends State<TrainingReportAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _setupAnimation();

    if (widget.animate) {
      _controller.forward();
    } else {
      // 애니메이션을 사용하지 않을 경우 즉시 완료 상태로 둠
      _controller.value = 1.0;
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onCompleted != null) {
        widget.onCompleted!();
      }
    });
  }

  void _setupAnimation() {
    final double from = widget.from.clamp(0.0, 1.0);
    final double to = widget.to.clamp(0.0, 1.0);

    _animation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant TrainingReportAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // from/to 값이 바뀌면 새 Tween으로 교체
    if (oldWidget.from != widget.from || oldWidget.to != widget.to) {
      _setupAnimation();

      if (widget.animate) {
        _controller
          ..reset()
          ..forward();
      } else {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 애니메이션을 안 쓸 때는 그냥 최종값으로 빌더 호출
    if (!widget.animate) {
      final v = widget.to.clamp(0.0, 1.0);
      return widget.builder(context, v);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return widget.builder(context, _animation.value.clamp(0.0, 1.0));
      },
    );
  }
}
