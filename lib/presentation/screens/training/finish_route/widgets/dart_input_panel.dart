import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class DartInputPanel extends StatelessWidget {
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onFail;
  final VoidCallback onFinishWith1;
  final VoidCallback onFinishWith2;
  final VoidCallback onFinishWith3;

  const DartInputPanel({
    super.key,
    required this.canUndo,
    required this.onUndo,
    required this.onFail,
    required this.onFinishWith1,
    required this.onFinishWith2,
    required this.onFinishWith3,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 성공 다트 개수 선택
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onFinishWith1,
                    child: const Text("1다트 성공"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onFinishWith2,
                    child: const Text("2다트 성공"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onFinishWith3,
                    child: const Text("3다트 성공"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: canUndo ? onUndo : null,
                    child: const Text("마지막 다트 되돌리기"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onFail,
                    child: const Text("이번 문제 실패"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
