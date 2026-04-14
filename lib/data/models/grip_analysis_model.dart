import 'package:cloud_firestore/cloud_firestore.dart';

/// [GripAnalysisModel]
/// 다트 그립의 '디지털 지문' 데이터 모델.
/// 이미지뿐만 아니라, 공학적으로 계산된 각도와 비율을 저장하여
/// "내 그립이 기준보다 얼마나 달라졌는지" 수치로 비교할 수 있게 합니다.
class GripAnalysisModel {
  final String id;            // 고유 ID (UUID)
  final String userId;        // 사용자 ID
  final DateTime createdAt;   // 생성 일시
  final String? imageUrl;     // 저장된 그립 이미지 경로 (Local or Storage URL)

  // ==========================================================
  // 1. 핵심 분석 데이터 (The Fingerprint)
  // ==========================================================

  /// [엄지-검지 핀치 비율] (Pinch Gap Ratio)
  /// 손 크기 대비 엄지와 검지가 얼마나 떨어져 있는지 (0.0 ~ 1.0)
  /// 예: 0.15 (적당함), 0.3 (많이 벌어짐)
  final double thumbIndexGapRatio;

  /// [검지 굽힘 각도] (Index Flexion)
  /// 180도에 가까우면 펴짐(Pencil), 90도에 가까우면 굽힘(Claw/Hook)
  final double indexFlexionAngle;

  /// [엄지 굽힘 각도] (Thumb Flexion)
  /// 엄지 관절이 꺾인 정도
  final double thumbFlexionAngle;

  /// [검지-중지 벌림 각도] (Spread Angle)
  /// 그립의 안정성을 체크하는 지표. (보통 붙이거나 일정하게 벌림)
  final double indexMiddleSpreadAngle;

  // ==========================================================
  // 2. 선택적 데이터 (고급 분석용)
  // ==========================================================

  /// [중지 지지대 높이] (Middle Finger Height Ratio)
  /// 엄지 높이(0)를 기준으로 중지가 얼마나 내려가 있는지 (+: 아래, -: 위)
  final double? middleFingerHeightRatio;

  /// [메모]
  /// 유저가 남긴 코멘트 (예: "오늘 컨디션 좋음")
  final String? note;

  const GripAnalysisModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.imageUrl,
    required this.thumbIndexGapRatio,
    required this.indexFlexionAngle,
    required this.thumbFlexionAngle,
    required this.indexMiddleSpreadAngle,
    this.middleFingerHeightRatio,
    this.note,
  });

  // ------------------------------------------------------------------------
  // [Factory] JSON(Firestore/Hive) -> 객체 변환
  // ------------------------------------------------------------------------
  factory GripAnalysisModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return GripAnalysisModel(
      id: docId ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      thumbIndexGapRatio: (map['thumbIndexGapRatio'] ?? 0.0).toDouble(),
      indexFlexionAngle: (map['indexFlexionAngle'] ?? 0.0).toDouble(),
      thumbFlexionAngle: (map['thumbFlexionAngle'] ?? 0.0).toDouble(),
      indexMiddleSpreadAngle: (map['indexMiddleSpreadAngle'] ?? 0.0).toDouble(),
      middleFingerHeightRatio: map['middleFingerHeightRatio']?.toDouble(),
      note: map['note'],
    );
  }

  // ------------------------------------------------------------------------
  // [Method] 객체 -> JSON 변환
  // ------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'thumbIndexGapRatio': thumbIndexGapRatio,
      'indexFlexionAngle': indexFlexionAngle,
      'thumbFlexionAngle': thumbFlexionAngle,
      'indexMiddleSpreadAngle': indexMiddleSpreadAngle,
      'middleFingerHeightRatio': middleFingerHeightRatio,
      'note': note,
    };
  }

  // ------------------------------------------------------------------------
  // [Logic] 비교 기능: 나와 다른 모델(기준)과의 차이 계산
  // ------------------------------------------------------------------------

  /// 현재 모델(this)과 기준 모델(baseline)을 비교하여 차이값을 반환합니다.
  /// 반환값: GripDifference (별도 클래스나 Map으로 반환)
  Map<String, double> compareWith(GripAnalysisModel baseline) {
    return {
      // 양수면 현재가 더 큼(벌어짐), 음수면 현재가 더 작음(좁아짐)
      'gapDiff': thumbIndexGapRatio - baseline.thumbIndexGapRatio,

      // 양수면 현재가 더 펴짐, 음수면 더 굽어짐
      'indexAngleDiff': indexFlexionAngle - baseline.indexFlexionAngle,

      'thumbAngleDiff': thumbFlexionAngle - baseline.thumbFlexionAngle,
      'spreadDiff': indexMiddleSpreadAngle - baseline.indexMiddleSpreadAngle,
    };
  }

  /// 차이값이 허용 오차(tolerance) 이내인지 확인 (Stability 체크)
  bool isStable(GripAnalysisModel baseline, {double toleranceRatio = 0.05, double toleranceAngle = 10.0}) {
    final diffs = compareWith(baseline);

    final bool isGapStable = diffs['gapDiff']!.abs() < toleranceRatio;
    final bool isIndexStable = diffs['indexAngleDiff']!.abs() < toleranceAngle;

    // 엄지와 검지가 가장 중요하므로 이 두 가지만 맞아도 Stable하다고 판단 (엄격도 조절 가능)
    return isGapStable && isIndexStable;
  }

  // ------------------------------------------------------------------------
  // [Utility] 복사본 생성 (Update용)
  // ------------------------------------------------------------------------
  GripAnalysisModel copyWith({
    String? imageUrl,
    String? note,
  }) {
    return GripAnalysisModel(
      id: this.id,
      userId: this.userId,
      createdAt: this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbIndexGapRatio: this.thumbIndexGapRatio,
      indexFlexionAngle: this.indexFlexionAngle,
      thumbFlexionAngle: this.thumbFlexionAngle,
      indexMiddleSpreadAngle: this.indexMiddleSpreadAngle,
      middleFingerHeightRatio: this.middleFingerHeightRatio,
      note: note ?? this.note,
    );
  }
}