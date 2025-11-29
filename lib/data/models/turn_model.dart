// lib/data/models/turn_model.dart

class Turn {
  final List<String> darts;
  final int scoreBefore;

  const Turn({
    required this.darts,
    required this.scoreBefore,
  });
}