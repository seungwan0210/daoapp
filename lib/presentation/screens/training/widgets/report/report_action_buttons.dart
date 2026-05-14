// lib/presentation/screens/training/widgets/report/report_action_buttons.dart
import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class ReportActionButtons extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback? onGoHistory;
  final VoidCallback? onGoNextDrill;
  final VoidCallback? onGoRatingCheck;

  const ReportActionButtons({
    super.key,
    required this.onClose,
    this.onGoHistory,
    this.onGoNextDrill,
    this.onGoRatingCheck,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 추가
    final hasHistory = onGoHistory != null;
    final hasNextDrill = onGoNextDrill != null;
    final hasRatingCheck = onGoRatingCheck != null;

    return Column(
      children: [
        Row(
          children: [
            // 닫기
            Expanded(
              child: OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[800],
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  s.btn_close, // 🔹 수정
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // 히스토리
            if (hasHistory) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGoHistory,
                  icon: const Icon(Icons.timeline, size: 18),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyan[700],
                    side: const BorderSide(color: Colors.cyan),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  label: Text(
                    s.btn_go_history, // 🔹 수정
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasNextDrill || hasRatingCheck) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (hasNextDrill) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onGoNextDrill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      s.btn_continue_drill, // 🔹 수정
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              if (hasNextDrill && hasRatingCheck) const SizedBox(width: 8),
              if (hasRatingCheck) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onGoRatingCheck,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.assessment_rounded),
                    label: Text(
                      s.btn_rating_check, // 🔹 수정
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}