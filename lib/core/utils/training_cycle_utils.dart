// lib/core/utils/training_cycle_utils.dart

import 'package:daoapp/core/utils/dao_training_rating_utils.dart';

/// 🔹 새 사이클 ID 생성
/// 예: cycle_beginner_1733890000000
String buildCycleIdForTier(DaoTrainingTier tier) {
  final tierName = tier.name; // beginner, learner...
  final ts = DateTime.now().millisecondsSinceEpoch;
  return 'cycle_${tierName}_$ts';
}

/// 🔹 화면에 보여줄 "사이클 라벨"
/// 예:
///   - cycle_beginner_1733...  → "비기너 사이클"
///   - cycle_pro_1733...       → "프로 사이클"
///   - cycle_1                 → "사이클 1" (옛 데이터 호환)
String? cycleDisplayLabelFromId(String? id) {
  if (id == null || id.isEmpty) return null;
  if (!id.startsWith('cycle_')) return id;

  final rest = id.substring(6); // 'beginner_1733...' or '1'
  final parts = rest.split('_');

  // 🔸 옛 형식: cycle_1, cycle_2 ...
  if (parts.length == 1) {
    final n = int.tryParse(parts[0]);
    if (n != null) return '사이클 $n';
    return id; // 파싱 실패하면 그냥 원본
  }

  // 🔸 새 형식: cycle_{tierName}_{ts}
  final tierKey = parts[0]; // beginner, learner...
  final tierKo = _tierKoName(tierKey);
  return '$tierKo 사이클';
}

/// DaoTrainingTier 의 name → 한글 이름
String _tierKoName(String tierKey) {
  switch (tierKey) {
    case 'beginner':
      return '비기너';
    case 'learner':
      return '러너';
    case 'competitor':
      return '컴페티터';
    case 'challenger':
      return '챌린저';
    case 'elite':
      return '엘리트';
    case 'pro':
      return '프로';
    case 'master':
      return '마스터';
    default:
      return tierKey; // 혹시 모를 예외
  }
}
