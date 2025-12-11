// lib/core/utils/dao_training_rating_utils.dart

/// DAO 트레이닝 공통 7등급
///
/// Beginner → Learner → Competitor → Challenger → Elite → Pro → Master
enum DaoTrainingTier {
  beginner, // 비기너
  learner, // 러너
  competitor, // 컴페티터
  challenger, // 챌린저
  elite, // 엘리트
  pro, // 프로
  master, // 마스터
}

extension DaoTrainingTierX on DaoTrainingTier {
  String get labelKo => switch (this) {
    DaoTrainingTier.beginner => '비기너',
    DaoTrainingTier.learner => '러너',
    DaoTrainingTier.competitor => '컴페티터',
    DaoTrainingTier.challenger => '챌린저',
    DaoTrainingTier.elite => '엘리트',
    DaoTrainingTier.pro => '프로',
    DaoTrainingTier.master => '마스터',
  };

  String get labelEn => switch (this) {
    DaoTrainingTier.beginner => 'Beginner',
    DaoTrainingTier.learner => 'Learner',
    DaoTrainingTier.competitor => 'Competitor',
    DaoTrainingTier.challenger => 'Challenger',
    DaoTrainingTier.elite => 'Elite',
    DaoTrainingTier.pro => 'Pro',
    DaoTrainingTier.master => 'Master',
  };

/// 🔹 미니 뱃지/칩용 짧은 라벨 (필요하면 나중에 더 줄여도 됨)
String get shortLabelKo => switch (this) {
  DaoTrainingTier.beginner => '비기너',
  DaoTrainingTier.learner => '러너',
  DaoTrainingTier.competitor => '컴페티터',
  DaoTrainingTier.challenger => '챌린저',
  DaoTrainingTier.elite => '엘리트',
  DaoTrainingTier.pro => '프로',
  DaoTrainingTier.master => '마스터',
};
}

/// =======================================
/// DAO 트레이닝 프로필 모델
/// =======================================

class DaoTrainingProfile {
  final double? phoenixPpd; // PHOENIX PPD (1다트 평균, 0~60)
  final double? phoenixMpr;
  final double? phoenixClass; // double (소수점 지원)

  final double? livePpd; // DARTSLIVE PPD == 3다트 평균(PPR)
  final double? liveMpr;
  final double? liveRating; // double (소수점 지원)

  final int? boardTestDarts;
  final DaoTrainingTier tier;

  const DaoTrainingProfile({
    this.phoenixPpd,
    this.phoenixMpr,
    this.phoenixClass,
    this.livePpd,
    this.liveMpr,
    this.liveRating,
    this.boardTestDarts,
    required this.tier,
  });

  @override
  String toString() {
    return 'DaoTrainingProfile('
        'phoenixClass: $phoenixClass, '
        'liveRating: $liveRating, '
        'tier: ${tier.labelKo})';
  }
}

/// =======================================
/// 보간 공통 유틸
/// =======================================

double _lerpWithScale(
    double base,
    double value,
    double min,
    double max, {
      double scale = 0.99,
    }) {
  if (max == min) return base;
  final ratio = (value - min) / (max - min);
  return base + ratio * scale;
}

/// 소수 2자리로 잘라서 경계 이슈 방지 (29.993 → 29.99)
double _round2(double value) => double.parse(value.toStringAsFixed(2));

/// =======================================
/// PHOENIX CLASS 테이블 (기본 & 상향 보정)
/// =======================================

class PhoenixClassRange {
  final double phoenixClass;
  final double mprMin;
  final double mprMax;
  final double ppdMin;
  final double ppdMax;

  const PhoenixClassRange({
    required this.phoenixClass,
    required this.mprMin,
    required this.mprMax,
    required this.ppdMin,
    required this.ppdMax,
  });

  bool contains({double? mpr, double? ppd}) {
    final mprOk = mpr != null && mpr >= mprMin && mpr <= mprMax;
    final ppdOk = ppd != null && ppd >= ppdMin && ppd <= ppdMax;
    return mprOk || ppdOk;
  }
}

/// 기본 Phoenix Class 표 (공식 기준)
const List<PhoenixClassRange> _phoenixTable = [
  PhoenixClassRange(
      phoenixClass: 30.0,
      mprMin: 6.00,
      mprMax: 9.00,
      ppdMin: 48.00,
      ppdMax: 60.00),
  PhoenixClassRange(
      phoenixClass: 29.0,
      mprMin: 5.74,
      mprMax: 5.99,
      ppdMin: 46.60,
      ppdMax: 47.99),
  PhoenixClassRange(
      phoenixClass: 28.0,
      mprMin: 5.48,
      mprMax: 5.73,
      ppdMin: 45.20,
      ppdMax: 46.59),
  PhoenixClassRange(
      phoenixClass: 27.0,
      mprMin: 5.22,
      mprMax: 5.47,
      ppdMin: 43.80,
      ppdMax: 45.19),
  PhoenixClassRange(
      phoenixClass: 26.0,
      mprMin: 4.96,
      mprMax: 5.21,
      ppdMin: 42.40,
      ppdMax: 43.79),
  PhoenixClassRange(
      phoenixClass: 25.0,
      mprMin: 4.70,
      mprMax: 4.95,
      ppdMin: 41.00,
      ppdMax: 42.39),
  PhoenixClassRange(
      phoenixClass: 24.0,
      mprMin: 4.49,
      mprMax: 4.69,
      ppdMin: 39.60,
      ppdMax: 40.99),
  PhoenixClassRange(
      phoenixClass: 23.0,
      mprMin: 4.28,
      mprMax: 4.48,
      ppdMin: 38.20,
      ppdMax: 39.59),
  PhoenixClassRange(
      phoenixClass: 22.0,
      mprMin: 4.07,
      mprMax: 4.27,
      ppdMin: 36.80,
      ppdMax: 38.19),
  PhoenixClassRange(
      phoenixClass: 21.0,
      mprMin: 3.86,
      mprMax: 4.06,
      ppdMin: 35.40,
      ppdMax: 36.79),
  PhoenixClassRange(
      phoenixClass: 20.0,
      mprMin: 3.71,
      mprMax: 3.85,
      ppdMin: 34.05,
      ppdMax: 35.39),
  PhoenixClassRange(
      phoenixClass: 19.0,
      mprMin: 3.56,
      mprMax: 3.70,
      ppdMin: 32.70,
      ppdMax: 34.04),
  PhoenixClassRange(
      phoenixClass: 18.0,
      mprMin: 3.41,
      mprMax: 3.55,
      ppdMin: 31.35,
      ppdMax: 32.69),
  PhoenixClassRange(
      phoenixClass: 17.0,
      mprMin: 3.26,
      mprMax: 3.40,
      ppdMin: 30.00,
      ppdMax: 31.34),
  PhoenixClassRange(
      phoenixClass: 16.0,
      mprMin: 3.11,
      mprMax: 3.25,
      ppdMin: 28.65,
      ppdMax: 29.99),
  PhoenixClassRange(
      phoenixClass: 15.0,
      mprMin: 2.96,
      mprMax: 3.10,
      ppdMin: 27.30,
      ppdMax: 28.64),
  PhoenixClassRange(
      phoenixClass: 14.0,
      mprMin: 2.81,
      mprMax: 2.95,
      ppdMin: 25.95,
      ppdMax: 27.29),
  PhoenixClassRange(
      phoenixClass: 13.0,
      mprMin: 2.66,
      mprMax: 2.80,
      ppdMin: 24.65,
      ppdMax: 25.94),
  PhoenixClassRange(
      phoenixClass: 12.0,
      mprMin: 2.51,
      mprMax: 2.65,
      ppdMin: 23.35,
      ppdMax: 24.64),
  PhoenixClassRange(
      phoenixClass: 11.0,
      mprMin: 2.36,
      mprMax: 2.50,
      ppdMin: 22.05,
      ppdMax: 23.34),
  PhoenixClassRange(
      phoenixClass: 10.0,
      mprMin: 2.21,
      mprMax: 2.35,
      ppdMin: 20.75,
      ppdMax: 22.04),
  PhoenixClassRange(
      phoenixClass: 9.0,
      mprMin: 2.06,
      mprMax: 2.20,
      ppdMin: 19.45,
      ppdMax: 20.74),
  PhoenixClassRange(
      phoenixClass: 8.0,
      mprMin: 1.91,
      mprMax: 2.05,
      ppdMin: 18.15,
      ppdMax: 19.44),
  PhoenixClassRange(
      phoenixClass: 7.0,
      mprMin: 1.76,
      mprMax: 1.90,
      ppdMin: 16.90,
      ppdMax: 18.14),
  PhoenixClassRange(
      phoenixClass: 6.0,
      mprMin: 1.61,
      mprMax: 1.75,
      ppdMin: 15.65,
      ppdMax: 16.89),
  PhoenixClassRange(
      phoenixClass: 5.0,
      mprMin: 1.46,
      mprMax: 1.60,
      ppdMin: 14.40,
      ppdMax: 15.64),
  PhoenixClassRange(
      phoenixClass: 4.0,
      mprMin: 1.31,
      mprMax: 1.45,
      ppdMin: 13.15,
      ppdMax: 14.39),
  PhoenixClassRange(
      phoenixClass: 3.0,
      mprMin: 1.20,
      mprMax: 1.30,
      ppdMin: 11.90,
      ppdMax: 13.14),
  PhoenixClassRange(
      phoenixClass: 2.0,
      mprMin: 1.10,
      mprMax: 1.19,
      ppdMin: 10.65,
      ppdMax: 11.89),
  PhoenixClassRange(
      phoenixClass: 1.0,
      mprMin: 0.00,
      mprMax: 1.09,
      ppdMin: 0.00,
      ppdMax: 10.64),
];

/// Phoenix Class 상향 보정 테이블 (Live 입력 → Phoenix 변환용, 약 +6%)
const List<PhoenixClassRange> _phoenixTableAdjusted = [
  PhoenixClassRange(phoenixClass: 30.0, mprMin: 6.36, mprMax: 9.54, ppdMin: 50.88, ppdMax: 63.60),
  PhoenixClassRange(phoenixClass: 29.0, mprMin: 6.08, mprMax: 6.35, ppdMin: 49.40, ppdMax: 50.87),
  PhoenixClassRange(phoenixClass: 28.0, mprMin: 5.81, mprMax: 6.07, ppdMin: 47.91, ppdMax: 49.39),
  PhoenixClassRange(phoenixClass: 27.0, mprMin: 5.53, mprMax: 5.80, ppdMin: 46.43, ppdMax: 47.90),
  PhoenixClassRange(phoenixClass: 26.0, mprMin: 5.26, mprMax: 5.52, ppdMin: 44.94, ppdMax: 46.42),
  PhoenixClassRange(phoenixClass: 25.0, mprMin: 4.98, mprMax: 5.25, ppdMin: 43.46, ppdMax: 44.93),
  PhoenixClassRange(phoenixClass: 24.0, mprMin: 4.76, mprMax: 4.97, ppdMin: 42.18, ppdMax: 43.45),
  PhoenixClassRange(phoenixClass: 23.0, mprMin: 4.54, mprMax: 4.75, ppdMin: 40.49, ppdMax: 42.17),
  PhoenixClassRange(phoenixClass: 22.0, mprMin: 4.32, mprMax: 4.53, ppdMin: 38.81, ppdMax: 40.48),
  PhoenixClassRange(phoenixClass: 21.0, mprMin: 4.09, mprMax: 4.31, ppdMin: 37.52, ppdMax: 38.80),
  PhoenixClassRange(phoenixClass: 20.0, mprMin: 3.95, mprMax: 4.08, ppdMin: 36.09, ppdMax: 37.51),
  PhoenixClassRange(phoenixClass: 19.0, mprMin: 3.80, mprMax: 3.94, ppdMin: 34.51, ppdMax: 36.08),
  PhoenixClassRange(phoenixClass: 18.0, mprMin: 3.62, mprMax: 3.79, ppdMin: 33.23, ppdMax: 34.50),
  PhoenixClassRange(phoenixClass: 17.0, mprMin: 3.44, mprMax: 3.61, ppdMin: 31.95, ppdMax: 33.22),
  PhoenixClassRange(phoenixClass: 16.0, mprMin: 3.30, mprMax: 3.43, ppdMin: 30.37, ppdMax: 31.94),
  PhoenixClassRange(phoenixClass: 15.0, mprMin: 3.14, mprMax: 3.29, ppdMin: 29.00, ppdMax: 30.36),
  PhoenixClassRange(phoenixClass: 14.0, mprMin: 2.97, mprMax: 3.13, ppdMin: 27.51, ppdMax: 28.99),
  PhoenixClassRange(phoenixClass: 13.0, mprMin: 2.82, mprMax: 2.96, ppdMin: 26.13, ppdMax: 27.50),
  PhoenixClassRange(phoenixClass: 12.0, mprMin: 2.66, mprMax: 2.81, ppdMin: 24.75, ppdMax: 26.12),
  PhoenixClassRange(phoenixClass: 11.0, mprMin: 2.50, mprMax: 2.65, ppdMin: 23.37, ppdMax: 24.74),
  PhoenixClassRange(phoenixClass: 10.0, mprMin: 2.34, mprMax: 2.49, ppdMin: 21.99, ppdMax: 23.36),
  PhoenixClassRange(phoenixClass: 9.0,  mprMin: 2.20, mprMax: 2.33, ppdMin: 20.69, ppdMax: 21.98),
  PhoenixClassRange(phoenixClass: 8.0,  mprMin: 2.04, mprMax: 2.19, ppdMin: 19.24, ppdMax: 20.68),
  PhoenixClassRange(phoenixClass: 7.0,  mprMin: 1.87, mprMax: 2.03, ppdMin: 17.91, ppdMax: 19.23),
  PhoenixClassRange(phoenixClass: 6.0,  mprMin: 1.72, mprMax: 1.86, ppdMin: 16.60, ppdMax: 17.90),
  PhoenixClassRange(phoenixClass: 5.0,  mprMin: 1.55, mprMax: 1.71, ppdMin: 15.26, ppdMax: 16.59),
  PhoenixClassRange(phoenixClass: 4.0,  mprMin: 1.39, mprMax: 1.54, ppdMin: 13.93, ppdMax: 15.25),
  PhoenixClassRange(phoenixClass: 3.0,  mprMin: 1.26, mprMax: 1.38, ppdMin: 12.97, ppdMax: 13.92),
  PhoenixClassRange(phoenixClass: 2.0,  mprMin: 1.17, mprMax: 1.25, ppdMin: 11.29, ppdMax: 12.96),
  PhoenixClassRange(phoenixClass: 1.0,  mprMin: 0.00, mprMax: 1.16, ppdMin: 0.00,  ppdMax: 11.28),
];

double? _phoenixClassFromMprWithTable(double mpr, List<PhoenixClassRange> table) {
  for (final row in table) {
    if (mpr >= row.mprMin && mpr <= row.mprMax) {
      return _lerpWithScale(
        row.phoenixClass,
        mpr,
        row.mprMin,
        row.mprMax,
      );
    }
  }
  return null;
}

double? _phoenixClassFromPpdWithTable(double ppd, List<PhoenixClassRange> table) {
  for (final row in table) {
    if (ppd >= row.ppdMin && ppd <= row.ppdMax) {
      return _lerpWithScale(
        row.phoenixClass,
        ppd,
        row.ppdMin,
        row.ppdMax,
      );
    }
  }
  return null;
}

/// 기본 Phoenix 테이블 전용 (기존 동작 유지)
double? _phoenixClassFromMpr(double mpr) =>
    _phoenixClassFromMprWithTable(mpr, _phoenixTable);

double? _phoenixClassFromPpd(double ppd) =>
    _phoenixClassFromPpdWithTable(ppd, _phoenixTable);

double? _getPhoenixClassPreciseFromTable({
  double? mpr,
  double? ppd,
  required List<PhoenixClassRange> table,
  double mprWeight = 0.5, // 기본값은 기존 비율
}) {
  if (mpr == null && ppd == null) return null;

  final double ppdWeight = 1.0 - mprWeight;

  final fromMpr =
  mpr != null ? _phoenixClassFromMprWithTable(mpr, table) : null;
  final fromPpd =
  ppd != null ? _phoenixClassFromPpdWithTable(ppd, table) : null;

  if (fromMpr != null && fromPpd != null) {
    final value = fromMpr * mprWeight + fromPpd * ppdWeight;
    return double.parse(value.toStringAsFixed(2));
  } else if (fromMpr != null) {
    return double.parse(fromMpr.toStringAsFixed(2));
  } else if (fromPpd != null) {
    return double.parse(fromPpd.toStringAsFixed(2));
  }

  return 1.0;
}

/// 정확한 소수점 2자리 Phoenix Class 계산 (기본 테이블)
double? getPhoenixClassPrecise({double? mpr, double? ppd}) {
  return _getPhoenixClassPreciseFromTable(
    mpr: mpr,
    ppd: ppd,
    table: _phoenixTable,
    mprWeight: 0.5, // 기본 공식 비율 유지
  );
}

/// 상향 보정 테이블로 계산 (Live 입력 → Phoenix 역변환용)
/// 변환 보정은 PPD:MPR = 5:5
double? getPhoenixClassPreciseAdjusted({double? mpr, double? ppd}) {
  return _getPhoenixClassPreciseFromTable(
    mpr: mpr,
    ppd: ppd,
    table: _phoenixTableAdjusted,
    mprWeight: 0.5,
  );
}

/// =======================================
/// DARTSLIVE 레이팅 (기본 & 하향 보정)
///
/// ⚠️ 이 테이블의 ppdMin/Max 는
///  - DARTSLIVE 화면에 나오는 "PPD = 3다트 평균(PPR)" 값 기준.
///  - 즉, 함수 인자 ppd는 LIVE 앱에 찍힌 숫자를 그대로 넣으면 됨.
/// =======================================

class LiveRatingRange {
  final double rating;
  final double mprMin;
  final double mprMax;
  final double ppdMin;
  final double ppdMax;

  const LiveRatingRange({
    required this.rating,
    required this.mprMin,
    required this.mprMax,
    required this.ppdMin,
    required this.ppdMax,
  });

  bool contains({double? mpr, double? ppd}) {
    final mprOk = mpr != null && mpr >= mprMin && mpr <= mprMax;
    final ppdOk = ppd != null && ppd >= ppdMin && ppd <= ppdMax;
    return mprOk || ppdOk;
  }
}

/// 기본 Live Rating 표 (공식 기준)
const List<LiveRatingRange> _liveTable = [
  LiveRatingRange(
      rating: 18.0,
      mprMin: 4.75,
      mprMax: 9.50,
      ppdMin: 130.00,
      ppdMax: 180.00),
  LiveRatingRange(
      rating: 17.0,
      mprMin: 4.50,
      mprMax: 4.74,
      ppdMin: 123.00,
      ppdMax: 129.99),
  LiveRatingRange(
      rating: 16.0,
      mprMin: 4.25,
      mprMax: 4.49,
      ppdMin: 116.00,
      ppdMax: 122.99),
  LiveRatingRange(
      rating: 15.0,
      mprMin: 4.00,
      mprMax: 4.24,
      ppdMin: 109.00,
      ppdMax: 115.99),
  LiveRatingRange(
      rating: 14.0,
      mprMin: 3.75,
      mprMax: 3.99,
      ppdMin: 102.00,
      ppdMax: 108.99),
  LiveRatingRange(
      rating: 13.0,
      mprMin: 3.50,
      mprMax: 3.74,
      ppdMin: 95.00,
      ppdMax: 101.99),
  LiveRatingRange(
      rating: 12.0,
      mprMin: 3.30,
      mprMax: 3.49,
      ppdMin: 90.00,
      ppdMax: 94.99),
  LiveRatingRange(
      rating: 11.0,
      mprMin: 3.10,
      mprMax: 3.29,
      ppdMin: 85.00,
      ppdMax: 89.99),
  LiveRatingRange(
      rating: 10.0,
      mprMin: 2.90,
      mprMax: 3.09,
      ppdMin: 80.00,
      ppdMax: 84.99),
  LiveRatingRange(
      rating: 9.0,
      mprMin: 2.70,
      mprMax: 2.89,
      ppdMin: 75.00,
      ppdMax: 79.99),
  LiveRatingRange(
      rating: 8.0,
      mprMin: 2.50,
      mprMax: 2.69,
      ppdMin: 70.00,
      ppdMax: 74.99),
  LiveRatingRange(
      rating: 7.0,
      mprMin: 2.30,
      mprMax: 2.49,
      ppdMin: 65.00,
      ppdMax: 69.99),
  LiveRatingRange(
      rating: 6.0,
      mprMin: 2.10,
      mprMax: 2.29,
      ppdMin: 60.00,
      ppdMax: 64.99),
  LiveRatingRange(
      rating: 5.0,
      mprMin: 1.90,
      mprMax: 2.09,
      ppdMin: 55.00,
      ppdMax: 59.99),
  LiveRatingRange(
      rating: 4.0,
      mprMin: 1.70,
      mprMax: 1.89,
      ppdMin: 50.00,
      ppdMax: 54.99),
  LiveRatingRange(
      rating: 3.0,
      mprMin: 1.50,
      mprMax: 1.69,
      ppdMin: 45.00,
      ppdMax: 49.99),
  LiveRatingRange(
      rating: 2.0,
      mprMin: 1.30,
      mprMax: 1.49,
      ppdMin: 40.00,
      ppdMax: 44.99),
  LiveRatingRange(
      rating: 1.0,
      mprMin: 0.00,
      mprMax: 1.29,
      ppdMin: 0.00,
      ppdMax: 39.99),
];

/// Live Rating 하향 보정 (Phoenix 입력 → Live 변환용, 약 -7%)
const List<LiveRatingRange> _liveTableAdjusted = [
  LiveRatingRange(rating: 18.0, mprMin: 4.42, mprMax: 8.84, ppdMin: 120.90, ppdMax: 167.40),
  LiveRatingRange(rating: 17.0, mprMin: 4.19, mprMax: 4.41, ppdMin: 114.39, ppdMax: 120.89),
  LiveRatingRange(rating: 16.0, mprMin: 3.95, mprMax: 4.18, ppdMin: 107.88, ppdMax: 114.38),
  LiveRatingRange(rating: 15.0, mprMin: 3.72, mprMax: 3.94, ppdMin: 101.37, ppdMax: 107.87),
  LiveRatingRange(rating: 14.0, mprMin: 3.49, mprMax: 3.71, ppdMin: 94.86, ppdMax: 101.36),
  LiveRatingRange(rating: 13.0, mprMin: 3.26, mprMax: 3.48, ppdMin: 88.35, ppdMax: 94.85),
  LiveRatingRange(rating: 12.0, mprMin: 3.07, mprMax: 3.25, ppdMin: 83.70, ppdMax: 88.34),
  LiveRatingRange(rating: 11.0, mprMin: 2.88, mprMax: 3.06, ppdMin: 79.05, ppdMax: 83.69),
  LiveRatingRange(rating: 10.0, mprMin: 2.70, mprMax: 2.87, ppdMin: 74.40, ppdMax: 79.04),
  LiveRatingRange(rating: 9.0,  mprMin: 2.51, mprMax: 2.69, ppdMin: 69.75, ppdMax: 74.39),
  LiveRatingRange(rating: 8.0,  mprMin: 2.33, mprMax: 2.50, ppdMin: 65.10, ppdMax: 69.74),
  LiveRatingRange(rating: 7.0,  mprMin: 2.14, mprMax: 2.32, ppdMin: 60.45, ppdMax: 65.09),
  LiveRatingRange(rating: 6.0,  mprMin: 1.95, mprMax: 2.13, ppdMin: 55.80, ppdMax: 60.44),
  LiveRatingRange(rating: 5.0,  mprMin: 1.77, mprMax: 1.94, ppdMin: 51.15, ppdMax: 55.79),
  LiveRatingRange(rating: 4.0,  mprMin: 1.58, mprMax: 1.76, ppdMin: 46.50, ppdMax: 51.14),
  LiveRatingRange(rating: 3.0,  mprMin: 1.40, mprMax: 1.57, ppdMin: 41.85, ppdMax: 46.49),
  LiveRatingRange(rating: 2.0,  mprMin: 1.21, mprMax: 1.39, ppdMin: 37.20, ppdMax: 41.84),
  LiveRatingRange(rating: 1.0,  mprMin: 0.00, mprMax: 1.20, ppdMin: 0.00,  ppdMax: 37.19),
];

double? _liveRatingFromMprWithTable(
    double mpr,
    List<LiveRatingRange> table,
    ) {
  for (final row in table) {
    if (mpr >= row.mprMin && mpr <= row.mprMax) {
      return _lerpWithScale(
        row.rating,
        mpr,
        row.mprMin,
        row.mprMax,
      );
    }
  }
  return null;
}

double? _liveRatingFromPpdWithTable(
    double ppd,
    List<LiveRatingRange> table,
    ) {
  for (final row in table) {
    if (ppd >= row.ppdMin && ppd <= row.ppdMax) {
      return _lerpWithScale(
        row.rating,
        ppd,
        row.ppdMin,
        row.ppdMax,
      );
    }
  }
  return null;
}

/// 기본 Live 테이블 전용 (기존 동작 유지)
double? _liveRatingFromMpr(double mpr) =>
    _liveRatingFromMprWithTable(mpr, _liveTable);

double? _liveRatingFromPpd(double ppd) =>
    _liveRatingFromPpdWithTable(ppd, _liveTable);

double? _getLiveRatingPreciseFromTable({
  double? mpr,
  double? ppd,
  required List<LiveRatingRange> table,
  double mprWeight = 0.5, // 기본값은 기존 비율
}) {
  if (mpr == null && ppd == null) return null;

  final double ppdWeight = 1.0 - mprWeight;

  final fromMpr =
  mpr != null ? _liveRatingFromMprWithTable(mpr, table) : null;
  final fromPpd =
  ppd != null ? _liveRatingFromPpdWithTable(ppd, table) : null;

  if (fromMpr != null && fromPpd != null) {
    final value = fromMpr * mprWeight + fromPpd * ppdWeight;
    return double.parse(value.toStringAsFixed(2));
  } else if (fromMpr != null) {
    return double.parse(fromMpr.toStringAsFixed(2));
  } else if (fromPpd != null) {
    return double.parse(fromPpd.toStringAsFixed(2));
  }

  return 1.0;
}

/// DARTSLIVE 레이팅 근사 (소수점 2자리, 기본 테이블)
double? getLiveRatingPrecise({double? mpr, double? ppd}) {
  return _getLiveRatingPreciseFromTable(
    mpr: mpr,
    ppd: ppd,
    table: _liveTable,
    mprWeight: 0.5, // 기본 공식 비율 유지
  );
}

/// 하향 보정 테이블로 계산 (Phoenix 입력 → Live 변환용)
/// 변환 보정은 PPD:MPR = 5:5
double? getLiveRatingPreciseAdjusted({double? mpr, double? ppd}) {
  return _getLiveRatingPreciseFromTable(
    mpr: mpr,
    ppd: ppd,
    table: _liveTableAdjusted,
    mprWeight: 0.5,
  );
}

/// =======================================
/// 보드 레벨 테스트 & 티어 계산 (7단계)
///
/// 대략 20~70발 구간을 7등급으로 쪼갠 느낌으로 구성.
/// - 적게 던질수록 상위 티어.
/// =======================================

DaoTrainingTier tierFromBoardTest(int dartsUsed) {
  if (dartsUsed <= 24) return DaoTrainingTier.master;
  if (dartsUsed <= 28) return DaoTrainingTier.pro;
  if (dartsUsed <= 33) return DaoTrainingTier.elite;
  if (dartsUsed <= 42) return DaoTrainingTier.challenger;
  if (dartsUsed <= 55) return DaoTrainingTier.competitor;
  if (dartsUsed <= 70) return DaoTrainingTier.learner;
  return DaoTrainingTier.beginner; // 71발 이상
}

/// Phoenix Class → 7티어 매핑
///
/// 비기너  : 1 ~ 6
/// Learner : 7 ~ 9
/// Competitor : 10 ~ 11
/// Challenger : 12 ~ 14
/// Elite : 15 ~ 17
/// Pro : 18 ~ 23
/// Master : 24 ~ 30
DaoTrainingTier? tierFromPhoenixClass(double? phoenixClass) {
  if (phoenixClass == null) return null;

  if (phoenixClass >= 24.0) return DaoTrainingTier.master;
  if (phoenixClass >= 18.0) return DaoTrainingTier.pro;
  if (phoenixClass >= 15.0) return DaoTrainingTier.elite;
  if (phoenixClass >= 12.0) return DaoTrainingTier.challenger;
  if (phoenixClass >= 10.0) return DaoTrainingTier.competitor;
  if (phoenixClass >= 7.0) return DaoTrainingTier.learner;
  return DaoTrainingTier.beginner;
}

/// DARTSLIVE Rating → 7티어 매핑
///
/// 비기너  : 1 ~ 3
/// Learner : 4 ~ 5
/// Competitor : 6 ~ 7
/// Challenger : 8 ~ 9
/// Elite : 10 ~ 12
/// Pro : 13 ~ 15
/// Master : 16 ~ 18
DaoTrainingTier? tierFromLiveRating(double? rating) {
  if (rating == null) return null;

  if (rating >= 16.0) return DaoTrainingTier.master;
  if (rating >= 13.0) return DaoTrainingTier.pro;
  if (rating >= 10.0) return DaoTrainingTier.elite;
  if (rating >= 8.0) return DaoTrainingTier.challenger;
  if (rating >= 6.0) return DaoTrainingTier.competitor;
  if (rating >= 4.0) return DaoTrainingTier.learner;
  return DaoTrainingTier.beginner; // 1~3 또는 그 이하
}

/// 입력 소스 판별용 (내부 전용)
enum _RatingSource {
  phoenixOnly, // 피닉스 입력만 있는 경우
  liveOnly, // 라이브 입력만 있는 경우
  bothOrMixed, // 둘 다 있거나, 둘 다 없는 경우
}

/// =======================================
/// 최종 통합 계산 함수
///
/// 🔥 규칙 요약
/// - 피닉스 입력만 있을 때:
///    - Phoenix Class : 기본 Phoenix 표
///    - Live Rating   : 하향 보정 Live 표 (_liveTableAdjusted, PPD:MPR=5:5)
/// - 라이브 입력만 있을 때:
///    - Live Rating   : 기본 Live 표
///    - Phoenix Class : 상향 보정 Phoenix 표 (_phoenixTableAdjusted, PPD:MPR=5:5)
/// - 둘 다 입력되면:
///    - 둘 다 "기본 표"만 사용 (보정 없이 표준값만 표시)
///
/// 내부 계산 방식(MPR/PPD 가중 평균, 티어 계산)은 위 규칙에 맞게 조정.
/// =======================================

DaoTrainingProfile calculateDaoTrainingProfile({
  double? phoenixPpd, // PHOENIX PPD (1다트 평균)
  double? phoenixMpr,
  double? phoenixClass,
  double? livePpd, // DARTSLIVE PPD == 3다트 평균(PPR)
  double? liveMpr,
  double? liveRating,
  int? boardTestDarts,
}) {
  // 1) 입력 소스 판별
  final bool hasPhoenixInput =
      phoenixPpd != null || phoenixMpr != null || phoenixClass != null;
  final bool hasLiveInput =
      livePpd != null || liveMpr != null || liveRating != null;

  final _RatingSource source;
  if (hasPhoenixInput && !hasLiveInput) {
    source = _RatingSource.phoenixOnly;
  } else if (hasLiveInput && !hasPhoenixInput) {
    source = _RatingSource.liveOnly;
  } else {
    source = _RatingSource.bothOrMixed;
  }

  // 2) PPD 상호 보정 (스케일 맞춰서 변환)
  // - LIVE PPD(3다트 평균) → PHOENIX PPD(1다트 평균) : /3
  // - PHOENIX PPD → LIVE PPD(3다트 평균) : *3
  double? effectivePhoenixPpd =
      phoenixPpd ?? (livePpd != null ? livePpd / 3.0 : null);
  double? effectiveLivePpd =
      livePpd ?? (phoenixPpd != null ? phoenixPpd * 3.0 : null);

  // 변환된 값은 소수 2자리로 잘라서 테이블 경계 문제 방지
  if (effectivePhoenixPpd != null) {
    effectivePhoenixPpd = _round2(effectivePhoenixPpd);
  }
  if (effectiveLivePpd != null) {
    effectiveLivePpd = _round2(effectiveLivePpd);
  }

  // 3) 정확한 클래스/레이팅 계산
  //    - 입력으로 phoenixClass / liveRating이 직접 들어오면 우선 사용
  double? computedPhoenixClass = phoenixClass;
  double? computedLiveRating = liveRating;

  // Phoenix Class 계산
  if (computedPhoenixClass == null &&
      (effectivePhoenixPpd != null || phoenixMpr != null || liveMpr != null)) {
    switch (source) {
      case _RatingSource.liveOnly:
      // 라이브 입력만 있는 경우 → 피닉스는 상향 보정 기준으로 보수적으로 계산
      // PPD는 /3 해서 Phoenix 스케일, MPR은 liveMpr 사용
        computedPhoenixClass = getPhoenixClassPreciseAdjusted(
          mpr: liveMpr,
          ppd: effectivePhoenixPpd,
        );
        break;
      case _RatingSource.phoenixOnly:
      // 피닉스 직접 입력 → 기본 표 + 피닉스 MPR 사용
        computedPhoenixClass = getPhoenixClassPrecise(
          mpr: phoenixMpr,
          ppd: effectivePhoenixPpd,
        );
        break;
      case _RatingSource.bothOrMixed:
      // 둘 다 있는 경우 → 기본 표 사용, MPR은 phoenixMpr 우선, 없으면 liveMpr 사용
        computedPhoenixClass = getPhoenixClassPrecise(
          mpr: phoenixMpr ?? liveMpr,
          ppd: effectivePhoenixPpd,
        );
        break;
    }
  }

  // Live Rating 계산
  if (computedLiveRating == null &&
      (effectiveLivePpd != null || liveMpr != null || phoenixMpr != null)) {
    switch (source) {
      case _RatingSource.phoenixOnly:
      // 피닉스 입력만 있는 경우 → 라이브는 하향 보정 기준으로 후하게 계산
      // PPD는 *3 해서 Live 스케일, MPR은 phoenixMpr 사용
        computedLiveRating = getLiveRatingPreciseAdjusted(
          mpr: phoenixMpr,
          ppd: effectiveLivePpd,
        );
        break;
      case _RatingSource.liveOnly:
      // 라이브 직접 입력 → 기본 표 + 라이브 MPR 사용
        computedLiveRating = getLiveRatingPrecise(
          mpr: liveMpr,
          ppd: effectiveLivePpd,
        );
        break;
      case _RatingSource.bothOrMixed:
      // 둘 다 있는 경우 → 기본 표 사용, MPR은 liveMpr 우선, 없으면 phoenixMpr 사용
        computedLiveRating = getLiveRatingPrecise(
          mpr: liveMpr ?? phoenixMpr,
          ppd: effectiveLivePpd,
        );
        break;
    }
  }

  // 4) 티어 후보 모으기
  final candidates = <DaoTrainingTier>[];

  if (computedPhoenixClass != null) {
    final t = tierFromPhoenixClass(computedPhoenixClass);
    if (t != null) candidates.add(t);
  }

  if (computedLiveRating != null) {
    final t = tierFromLiveRating(computedLiveRating);
    if (t != null) candidates.add(t);
  }

  if (boardTestDarts != null) {
    candidates.add(tierFromBoardTest(boardTestDarts));
  }

  // 가장 높은 티어(인덱스 큰 것) 선택
  final tier = candidates.isEmpty
      ? DaoTrainingTier.beginner
      : candidates.reduce((a, b) => a.index > b.index ? a : b);

  return DaoTrainingProfile(
    phoenixPpd: effectivePhoenixPpd,
    phoenixMpr: phoenixMpr,
    phoenixClass: computedPhoenixClass,
    livePpd: effectiveLivePpd,
    liveMpr: liveMpr,
    liveRating: computedLiveRating,
    boardTestDarts: boardTestDarts,
    tier: tier,
  );
}
