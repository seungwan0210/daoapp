// lib/presentation/screens/training/grip_lab/grip_compare_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:daoapp/presentation/providers/training/grip_baseline_provider.dart';
import 'package:daoapp/presentation/providers/training/grip_lab_provider.dart';

import 'package:daoapp/presentation/screens/training/grip_lab/grip_camera_screen.dart';
import 'package:daoapp/presentation/screens/training/grip_lab/widgets/grip_diff_legend.dart';

class GripCompareScreen extends ConsumerWidget {
  const GripCompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baselineState = ref.watch(gripBaselineProvider);

    ref.listen<GripBaselineState>(gripBaselineProvider, (prev, next) {
      final msg = next.errorMessage;
      if (msg == null || msg.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      ref.read(gripBaselineProvider.notifier).clearError();
    });

    if (!baselineState.hasBaseline || baselineState.baseline == null) {
      return _NoBaselineView(
        onTake: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GripCameraScreen()),
          );
          await ref.read(gripBaselineProvider.notifier).fetchBaseline();
        },
      );
    }

    return _CompareBody(baseline: baselineState.baseline!);
  }
}

class _NoBaselineView extends StatelessWidget {
  final VoidCallback onTake;

  const _NoBaselineView({required this.onTake});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "그립 비교/교정",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
              color: const Color(0xFFF7F9FC),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pan_tool_alt_rounded,
                    size: 56, color: Colors.grey[600]),
                const SizedBox(height: 12),
                const Text(
                  "기준 그립이 없어요",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "비교/교정을 하려면 먼저\n‘기준 그립’을 촬영해서 저장해야 해요.",
                  style: TextStyle(color: Colors.grey[700], height: 1.35),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTake,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan[600],
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "촬영하러 가기",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ 여기가 핵심: "고스트 잠금(LOCK)" 상태를 들고 있어야 하므로 Stateful
class _CompareBody extends ConsumerStatefulWidget {
  final dynamic baseline; // GripBaselineModel

  const _CompareBody({required this.baseline});

  @override
  ConsumerState<_CompareBody> createState() => _CompareBodyState();
}

class _CompareBodyState extends ConsumerState<_CompareBody> {
  bool _isLocked = false;

  /// ✅ 잠금 시점에 고정된 baseline(0~1 좌표계)
  List<Offset> _lockedBaseline01 = const <Offset>[];

  /// (옵션) diff 민감도: 필요하면 UI로 조절 가능
  double _diffThreshold = 0.022;

  void _unlock() {
    setState(() {
      _isLocked = false;
      _lockedBaseline01 = const <Offset>[];
    });
  }

  void _lockBaseline(List<Offset> alignedOnce) {
    setState(() {
      _isLocked = true;
      _lockedBaseline01 = alignedOnce;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grip = ref.watch(gripLabProvider);

    final bool hasLive = grip.isHandDetected &&
        grip.landmarks.length >= 21 &&
        grip.imageWidth > 0 &&
        grip.imageHeight > 0;

    // ✅ baseline.landmarks 방어적으로 Offset 변환
    final List<dynamic> rawBase = (widget.baseline.landmarks as List);
    final List<Offset> basePts = rawBase.map((e) {
      if (e is Offset) return e;
      if (e is Map) {
        final dx = (e['dx'] as num?)?.toDouble() ?? 0.0;
        final dy = (e['dy'] as num?)?.toDouble() ?? 0.0;
        return Offset(dx, dy);
      }
      return Offset.zero;
    }).toList(growable: false);

    final List<Offset> curPts = grip.landmarks;

    // ✅ (A) 자동정렬 모드: 매 프레임 base -> cur 정렬
    final List<Offset> baseAutoAligned =
    (hasLive && basePts.length >= 21) ? _alignBaselineToCurrent(basePts, curPts) : const <Offset>[];

    // ✅ (B) 잠금 모드:
    // - 이미 잠금된 baseline이 있으면 그걸 그대로 사용(고스트가 안 움직임)
    // - 아직 잠금 안됐으면 빈 리스트
    final List<Offset> baseForCompare01 = _isLocked ? _lockedBaseline01 : baseAutoAligned;

    // ✅ diff 계산: "기준선(baseForCompare01)" vs current
    final List<bool> isDiff = (hasLive && baseForCompare01.length >= 21)
        ? List<bool>.generate(21, (i) {
      final d = (curPts[i] - baseForCompare01[i]).distance;
      return d > _diffThreshold;
    })
        : List<bool>.filled(21, false);

    final diffCount = isDiff.where((e) => e).length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "그립 비교/교정",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "기준 다시 불러오기",
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(gripBaselineProvider.notifier).fetchBaseline();
              // ✅ baseline 바뀌었을 수 있으니 잠금은 해제하는게 안전
              if (mounted) _unlock();
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) 카메라
          const AndroidView(viewType: 'dao_grip_camera_view'),

          // 2) 오버레이
          IgnorePointer(
            child: CustomPaint(
              painter: (hasLive && baseForCompare01.length >= 21)
                  ? GripCompareOverlayPainter(
                baseline: baseForCompare01,
                current: curPts,
                isDiff: isDiff,
                imageWidth: grip.imageWidth,
                imageHeight: grip.imageHeight,
                fillCenter: true,
                lockedMode: _isLocked,
              )
                  : null,
              child: const SizedBox.expand(),
            ),
          ),

          // 3) 레전드
          const Positioned(
            top: 14,
            right: 14,
            child: GripDiffLegend(),
          ),

          // 4) 안내
          if (!hasLive)
            const Center(
              child: Text(
                "손을 카메라에 비춰주세요",
                style: TextStyle(color: Colors.white54),
              ),
            ),

          // 5) 상단 왼쪽: LOCK / UNLOCK 버튼
          Positioned(
            top: 14,
            left: 14,
            child: _LockChip(
              enabled: hasLive && baseAutoAligned.length >= 21,
              locked: _isLocked,
              onLock: () {
                if (!hasLive || baseAutoAligned.length < 21) return;
                // ✅ 잠금은 "지금 프레임의 정렬 결과"를 1번만 저장
                _lockBaseline(baseAutoAligned);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("고스트 기준선이 고정되었습니다 ✅")),
                );
              },
              onUnlock: () {
                _unlock();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("고스트 고정 해제")),
                );
              },
            ),
          ),

          // 6) 하단 정보 카드
          Positioned(
            left: 14,
            right: 14,
            bottom: 18,
            child: _BottomInfoCard(
              hasLive: hasLive,
              locked: _isLocked,
              pinchGap: grip.pinchGap,
              indexAngle: grip.indexAngle,
              diffCount: diffCount,
              diffThreshold: _diffThreshold,
              onThresholdChanged: (v) {
                setState(() => _diffThreshold = v);
              },
              onUpdateBaseline: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GripCameraScreen()),
                );
                await ref.read(gripBaselineProvider.notifier).fetchBaseline();
                if (mounted) _unlock(); // ✅ 기준 업데이트하면 잠금 해제
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// -------------------------------
/// LOCK UI
/// -------------------------------
class _LockChip extends StatelessWidget {
  final bool enabled;
  final bool locked;
  final VoidCallback onLock;
  final VoidCallback onUnlock;

  const _LockChip({
    required this.enabled,
    required this.locked,
    required this.onLock,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: locked
              ? const Color(0xFF3F8CFF).withOpacity(0.55)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            locked ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: locked ? const Color(0xFF3F8CFF) : Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            locked ? "고스트 고정됨" : "고스트 고정",
            style: TextStyle(
              color: locked ? const Color(0xFFBFD7FF) : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 30,
            child: OutlinedButton(
              onPressed: !enabled
                  ? null
                  : (locked ? onUnlock : onLock),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: BorderSide(color: Colors.white.withOpacity(0.28)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                locked ? "해제" : "고정",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// -------------------------------
/// 오버레이 Painter
/// -------------------------------
class GripCompareOverlayPainter extends CustomPainter {
  final List<Offset> baseline; // 0~1
  final List<Offset> current; // 0~1
  final List<bool> isDiff;

  final int imageWidth;
  final int imageHeight;
  final bool fillCenter;

  /// ✅ 잠금 모드면 "기준선" 느낌이 더 강하게 보여야 해서 약간 강조
  final bool lockedMode;

  GripCompareOverlayPainter({
    required this.baseline,
    required this.current,
    required this.isDiff,
    required this.imageWidth,
    required this.imageHeight,
    this.fillCenter = true,
    this.lockedMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (baseline.length < 21 || current.length < 21) return;
    if (imageWidth <= 0 || imageHeight <= 0) return;

    final base = _mapToView(size, baseline);
    final cur = _mapToView(size, current);

    final paintBaseLine = Paint()
      ..color = lockedMode
          ? Colors.white.withOpacity(0.70)
          : Colors.white.withOpacity(0.55)
      ..strokeWidth = lockedMode ? 2.8 : 2.2
      ..style = PaintingStyle.stroke;

    final paintBasePoint = Paint()
      ..color = lockedMode
          ? Colors.white.withOpacity(0.88)
          : Colors.white.withOpacity(0.75)
      ..strokeWidth = lockedMode ? 6.0 : 5.0
      ..strokeCap = StrokeCap.round;

    final paintCurLine = Paint()
      ..color = const Color(0xFF3F8CFF)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final paintCurPoint = Paint()
      ..color = const Color(0xFF3F8CFF)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final paintDiffPoint = Paint()
      ..color = const Color(0xFFFF3B30)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    final paintDiffLine = Paint()
      ..color = const Color(0xFFFF3B30).withOpacity(0.85)
      ..strokeWidth = 3.4
      ..style = PaintingStyle.stroke;

    // 기준
    canvas.drawPoints(ui.PointMode.points, base, paintBasePoint);
    _drawHand(canvas, base, paintBaseLine);

    // 현재
    canvas.drawPoints(ui.PointMode.points, cur, paintCurPoint);
    _drawHand(canvas, cur, paintCurLine);

    // 차이 포인트
    for (int i = 0; i < math.min(21, isDiff.length); i++) {
      if (!isDiff[i]) continue;
      canvas.drawPoints(ui.PointMode.points, [cur[i]], paintDiffPoint);
    }

    // 차이 세그먼트
    _drawHandDiff(canvas, cur, isDiff, paintDiffLine);
  }

  List<Offset> _mapToView(Size viewSize, List<Offset> points01) {
    final vw = viewSize.width;
    final vh = viewSize.height;

    final iw = imageWidth.toDouble();
    final ih = imageHeight.toDouble();

    final scaleX = vw / iw;
    final scaleY = vh / ih;

    final scale = fillCenter
        ? (scaleX > scaleY ? scaleX : scaleY)
        : (scaleX < scaleY ? scaleX : scaleY);

    final scaledW = iw * scale;
    final scaledH = ih * scale;

    final dx = (scaledW - vw) / 2.0;
    final dy = (scaledH - vh) / 2.0;

    return points01.map((p) {
      final x = (p.dx * iw * scale) - dx;
      final y = (p.dy * ih * scale) - dy;
      return Offset(x, y);
    }).toList(growable: false);
  }

  void _drawHand(Canvas canvas, List<Offset> pts, Paint paint) {
    _drawFinger(canvas, pts, const [0, 1, 2, 3, 4], paint);
    _drawFinger(canvas, pts, const [0, 5, 6, 7, 8], paint);
    _drawFinger(canvas, pts, const [0, 9, 10, 11, 12], paint);
    _drawFinger(canvas, pts, const [0, 13, 14, 15, 16], paint);
    _drawFinger(canvas, pts, const [0, 17, 18, 19, 20], paint);

    canvas.drawLine(pts[5], pts[9], paint);
    canvas.drawLine(pts[9], pts[13], paint);
    canvas.drawLine(pts[13], pts[17], paint);
    canvas.drawLine(pts[5], pts[17], paint);
  }

  void _drawHandDiff(
      Canvas canvas,
      List<Offset> pts,
      List<bool> diff,
      Paint paint,
      ) {
    void lineIfDiff(int a, int b) {
      final bool on =
          (a < diff.length && diff[a]) || (b < diff.length && diff[b]);
      if (on) canvas.drawLine(pts[a], pts[b], paint);
    }

    const fingers = [
      [0, 1, 2, 3, 4],
      [0, 5, 6, 7, 8],
      [0, 9, 10, 11, 12],
      [0, 13, 14, 15, 16],
      [0, 17, 18, 19, 20],
    ];

    for (final f in fingers) {
      for (int i = 0; i < f.length - 1; i++) {
        lineIfDiff(f[i], f[i + 1]);
      }
    }

    lineIfDiff(5, 9);
    lineIfDiff(9, 13);
    lineIfDiff(13, 17);
    lineIfDiff(5, 17);
  }

  void _drawFinger(Canvas canvas, List<Offset> points, List<int> indices, Paint paint) {
    for (int i = 0; i < indices.length - 1; i++) {
      canvas.drawLine(points[indices[i]], points[indices[i + 1]], paint);
    }
  }

  @override
  bool shouldRepaint(covariant GripCompareOverlayPainter old) => true;
}

/// -------------------------------
/// baseline -> current 정렬 (한 번 계산용)
/// - palmCenter(0,5,9,13,17 평균)
/// - scale: (5-17) 손바닥 폭
/// - rotate: (0->9) 손바닥 방향
/// -------------------------------
List<Offset> _alignBaselineToCurrent(List<Offset> base, List<Offset> cur) {
  if (base.length < 21 || cur.length < 21) return base;

  Offset palmCenter(List<Offset> pts) {
    final p0 = pts[0];
    final p5 = pts[5];
    final p9 = pts[9];
    final p13 = pts[13];
    final p17 = pts[17];
    return Offset(
      (p0.dx + p5.dx + p9.dx + p13.dx + p17.dx) / 5.0,
      (p0.dy + p5.dy + p9.dy + p13.dy + p17.dy) / 5.0,
    );
  }

  double palmWidth(List<Offset> pts) => (pts[5] - pts[17]).distance;

  double palmAngle(List<Offset> pts) {
    final v = pts[9] - pts[0];
    return math.atan2(v.dy, v.dx);
  }

  final bCenter = palmCenter(base);
  final cCenter = palmCenter(cur);

  final lenB = palmWidth(base);
  final lenC = palmWidth(cur);

  if (lenB < 1e-6 || lenC < 1e-6) return base;

  final scale = lenC / lenB;

  final rot = palmAngle(cur) - palmAngle(base);
  final cosR = math.cos(rot);
  final sinR = math.sin(rot);

  Offset transform(Offset p) {
    final x = (p.dx - bCenter.dx) * scale;
    final y = (p.dy - bCenter.dy) * scale;

    final xr = x * cosR - y * sinR;
    final yr = x * sinR + y * cosR;

    return Offset(xr + cCenter.dx, yr + cCenter.dy);
  }

  return base.map(transform).toList(growable: false);
}

/// -------------------------------
/// 하단 정보 카드 (threshold도 조절 가능하게)
/// -------------------------------
class _BottomInfoCard extends StatelessWidget {
  final bool hasLive;
  final bool locked;
  final double pinchGap;
  final double indexAngle;
  final int diffCount;

  final double diffThreshold;
  final ValueChanged<double> onThresholdChanged;

  final VoidCallback onUpdateBaseline;

  const _BottomInfoCard({
    required this.hasLive,
    required this.locked,
    required this.pinchGap,
    required this.indexAngle,
    required this.diffCount,
    required this.diffThreshold,
    required this.onThresholdChanged,
    required this.onUpdateBaseline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLive
                          ? "Pinch ${(pinchGap * 100).toStringAsFixed(1)}%  ·  Index ${indexAngle.toStringAsFixed(1)}°"
                          : "손 인식 대기 중…",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasLive
                          ? "차이 포인트: $diffCount / 21   ·   ${locked ? "기준선 고정 ✅" : "자동정렬 모드"}"
                          : "카메라에 손을 안정적으로 보여주세요",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: onUpdateBaseline,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "기준 업데이트",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                "민감도",
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Slider(
                  value: diffThreshold,
                  min: 0.012,
                  max: 0.040,
                  onChanged: hasLive ? onThresholdChanged : null,
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  "${(diffThreshold * 100).toStringAsFixed(1)}%",
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
