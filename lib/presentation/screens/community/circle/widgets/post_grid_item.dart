// lib/presentation/screens/community/circle/widgets/post_grid_item.dart

import 'package:flutter/material.dart';

class PostGridItem extends StatelessWidget {
  final String photoUrl;
  final VoidCallback onTap;

  /// ✅ Hero 애니메이션 옵션
  final Object? heroTag;

  const PostGridItem({
    super.key,
    required this.photoUrl,
    required this.onTap,
    this.heroTag,
  });

  static const String _fallbackAsset = 'assets/images/circle_main.png';

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      photoUrl,
      fit: BoxFit.cover,
      gaplessPlayback: true, // ✅ 깜빡임 방지 핵심
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return _FadeIn(child: child);
        }
        return const _GridSkeleton();
      },
      errorBuilder: (context, error, stackTrace) {
        // ✅ 에러 시 기본 이미지로 통일
        return Image.asset(
          _fallbackAsset,
          fit: BoxFit.cover,
        );
      },
    );

    final imageOrHero = heroTag == null
        ? image
        : Hero(
      tag: heroTag!,
      flightShuttleBuilder: (
          flightContext,
          animation,
          flightDirection,
          fromHeroContext,
          toHeroContext,
          ) {
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: Curves.easeOut),
          ),
          // ✅ fromHeroContext 사용 (안정성 ↑)
          child: fromHeroContext.widget,
        );
      },
      child: image,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          child: SizedBox.expand(
            child: ClipRect(
              child: imageOrHero,
            ),
          ),
        ),
      ),
    );
  }
}

/// ===============================
/// 로드 완료 후 부드러운 페이드인
/// ===============================
class _FadeIn extends StatefulWidget {
  final Widget child;
  const _FadeIn({required this.child});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c.drive(
        CurveTween(curve: Curves.easeOut),
      ),
      child: widget.child,
    );
  }
}

/// ===============================
/// 스켈레톤 로딩
/// ===============================
class _GridSkeleton extends StatefulWidget {
  const _GridSkeleton();

  @override
  State<_GridSkeleton> createState() => _GridSkeletonState();
}

class _GridSkeletonState extends State<_GridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final base = 0.10;
        final amp = 0.08;
        final alpha =
            base + (amp * (0.5 + 0.5 * (1 - (2 * (t - 0.5)).abs())));

        return Container(
          // ✅ withValues(alpha: )는 버전 이슈 가능 → withOpacity로 안전 처리
          color: Colors.black12.withOpacity(alpha),
        );
      },
    );
  }
}
