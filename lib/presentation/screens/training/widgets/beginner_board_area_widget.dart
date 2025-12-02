// lib/presentation/widgets/training/beginner_board_area_widget.dart

import 'package:flutter/material.dart';

/// 비기너 4구역 연습용 구역 정의
enum BeginnerBoardArea {
  topRight,
  bottomRight,
  bottomLeft,
  topLeft,
}

extension BeginnerBoardAreaX on BeginnerBoardArea {
  String get labelKo => switch (this) {
    BeginnerBoardArea.topRight => '오른쪽 위',
    BeginnerBoardArea.bottomRight => '오른쪽 아래',
    BeginnerBoardArea.bottomLeft => '왼쪽 아래',
    BeginnerBoardArea.topLeft => '왼쪽 위',
  };

  String get labelShort => switch (this) {
    BeginnerBoardArea.topRight => 'TR',
    BeginnerBoardArea.bottomRight => 'BR',
    BeginnerBoardArea.bottomLeft => 'BL',
    BeginnerBoardArea.topLeft => 'TL',
  };
}

/// 비기너 4구역 연습용 보드 위젯
///
/// - dartboard.png 이미지를 가운데에 표시
/// - [activeArea] 에 해당하는 구역만 살짝 네온 색으로 오버레이
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
    return Column(
      children: [
        Text(
          '현재 연습 구역: ${activeArea.labelKo}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
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
