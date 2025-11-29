// lib/data/models/practice_session_summary.dart

class PracticeResult {
  final int scoreBefore;
  final List<String> darts;
  final bool isSuccess;
  final int dartsUsed;

  const PracticeResult({
    required this.scoreBefore,
    required this.darts,
    required this.isSuccess,
    required this.dartsUsed,
  });
}

class PracticeSessionSummary {
  final int elapsedSeconds;
  final List<PracticeResult> results;

  const PracticeSessionSummary({
    required this.elapsedSeconds,
    required this.results,
  });
}