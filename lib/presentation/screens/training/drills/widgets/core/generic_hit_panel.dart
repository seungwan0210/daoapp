// lib/presentation/screens/training/drills/widgets/core/generic_hit_panel.dart

import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 임포트 경로 수정

class GenericHitPanel extends StatelessWidget {
  final String? targetLabel;
  final String? subTarget;
  final int currentRound;
  final int totalRounds;
  final int thrownDarts;
  final int totalDarts;
  final VoidCallback? onHitSuccess;
  final VoidCallback? onHitFail;
  final VoidCallback? onFinishPressed;

  final VoidCallback? onUndo;
  final bool canUndo;

  final bool isBusy;

  const GenericHitPanel({
    super.key,
    this.targetLabel,
    this.subTarget,
    required this.currentRound,
    required this.totalRounds,
    required this.thrownDarts,
    required this.totalDarts,
    this.onHitSuccess,
    this.onHitFail,
    this.onFinishPressed,
    this.onUndo,
    this.canUndo = false,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    // 🔹 S 대신 AppLocalizations 사용
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 진행 정보
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ROUND $currentRound / $totalRounds",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "$thrownDarts / $totalDarts ${s.drill_stat_darts}",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. 현재 타겟 표시
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  targetLabel ?? s.drill_panel_target,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
              if (subTarget != null) ...[
                const SizedBox(height: 6),
                Text(
                  subTarget!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.cyan.shade200,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                s.drill_guide_hit_miss,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. 성공 / 실패 버튼
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (isBusy || onHitSuccess == null) ? null : onHitSuccess,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  s.drill_btn_success,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (isBusy || onHitFail == null) ? null : onHitFail,
                icon: const Icon(Icons.close),
                label: Text(
                  s.drill_btn_fail,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 3.5 Undo 버튼
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: (isBusy || !canUndo || onUndo == null) ? null : onUndo,
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: Text(
              s.calc_undo, // 🔹 범용적인 되돌리기 키 사용
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
          ),
        ),

        const SizedBox(height: 4),

        // 4. 종료 버튼
        TextButton(
          onPressed: (isBusy || onFinishPressed == null) ? null : onFinishPressed,
          child: Text(
            s.drill_btn_finish_save,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.cyan,
            ),
          ),
        ),
      ],
    );
  }
}