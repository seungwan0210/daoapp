// lib/presentation/widgets/training/beginner_board_area_widget.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 추가

/// 비기너 4구역 연습용 구역 정의
enum BeginnerBoardArea {
  topRight,
  bottomRight,
  bottomLeft,
  topLeft,
}

extension BeginnerBoardAreaX on BeginnerBoardArea {
  // 🔹 다국어 라벨 반환 헬퍼 (context 필요)
  String getLabel(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return switch (this) {
      BeginnerBoardArea.topRight => s.area_top_right,
      BeginnerBoardArea.bottomRight => s.area_bottom_right,
      BeginnerBoardArea.bottomLeft => s.area_bottom_left,
      BeginnerBoardArea.topLeft => s.area_top_left,
    };
  }

  String get labelShort => switch (this) {
    BeginnerBoardArea.topRight => 'TR',
    BeginnerBoardArea.bottomRight => 'BR',
    BeginnerBoardArea.bottomLeft => 'BL',
    BeginnerBoardArea.topLeft => 'TL',
  };
}

/// 비기너 4구역 연습용 보드 위젯
class BeginnerBoardAreaWidget extends StatelessWidget {
  final BeginnerBoardArea activeArea;
  final double size; // 정사각형 한 변 길이

  const BeginnerBoardAreaWidget({
    super.key,
    required this.activeArea,
    this.size = 260,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스

    return Column(
      children: [
        Text(
          '${s.drill_active_area}: ${activeArea.getLabel(context)}', // 🔹 다국어 적용
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                // 보드 이미지
                Positioned.fill(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/dartboard.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // 4분할 오버레이
                ..._buildQuadrantOverlays(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildQuadrantOverlays() {
    // 공통 오버레이 스타일
    Color activeColor = Colors.cyanAccent.withOpacity(0.28);
    Color borderColor = Colors.cyanAccent.withOpacity(0.85);

    Widget quadrant({
      required Alignment alignment,
      required BeginnerBoardArea area,
    }) {
      final bool isActive = area == activeArea;
      return Align(
        alignment: alignment,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          heightFactor: 0.5,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                border: isActive
                    ? Border.all(
                  color: borderColor,
                  width: 2,
                )
                    : null,
              ),
              child: Center(
                child: Text(
                  area.labelShort,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? Colors.black87
                        : Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return [
      quadrant(
        alignment: Alignment.topRight,
        area: BeginnerBoardArea.topRight,
      ),
      quadrant(
        alignment: Alignment.bottomRight,
        area: BeginnerBoardArea.bottomRight,
      ),
      quadrant(
        alignment: Alignment.bottomLeft,
        area: BeginnerBoardArea.bottomLeft,
      ),
      quadrant(
        alignment: Alignment.topLeft,
        area: BeginnerBoardArea.topLeft,
      ),
    ];
  }
}