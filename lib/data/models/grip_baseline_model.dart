import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 🔹 Grip Baseline Model
/// - 유저의 기준 그립(1인 1개)
/// - Firestore 저장용
/// - 이미지(Storage) + landmark + 분석 수치 포함
class GripBaselineModel {
  /// 기준 생성/업데이트 시각
  final DateTime createdAt;

  /// 기준 이미지 (Firebase Storage download URL)
  final String imageUrl;

  /// MediaPipe hand landmarks (0.0 ~ 1.0)
  /// length = 21
  final List<Offset> landmarks;

  /// 기준 핀치 간격 비율
  final double pinchGap;

  /// 기준 검지 굽힘 각도
  final double indexAngle;

  /// 기준 프레임 실제 크기 (회전 반영 후)
  final int imageWidth;
  final int imageHeight;

  const GripBaselineModel({
    required this.createdAt,
    required this.imageUrl,
    required this.landmarks,
    required this.pinchGap,
    required this.indexAngle,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// ✅ Firestore 저장용 Map
  Map<String, dynamic> toMap() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'landmarks': landmarks
          .map((p) => {
        'x': p.dx,
        'y': p.dy,
      })
          .toList(growable: false),
      'pinchGap': pinchGap,
      'indexAngle': indexAngle,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
    };
  }

  /// ✅ Firestore → Model
  /// 
  /// 🔥 [안전성 최적화] 빌드 모드 최적화 단계 및 직렬화 과정에서 map 자체나 수치들이 
  /// 누락·오염되어 넘어오더라도 절대 런타임 에러를 뿜지 않도록 방어막을 쳤습니다.
  factory GripBaselineModel.fromMap(Map<String, dynamic>? map) {
    // 💡 map 자체가 null로 넘어올 경우를 위한 최상위 가드 코드
    if (map == null) {
      return GripBaselineModel(
        createdAt: DateTime.now(),
        imageUrl: '',
        landmarks: const <Offset>[],
        pinchGap: 0.0,
        indexAngle: 0.0,
        imageWidth: 0,
        imageHeight: 0,
      );
    }

    final createdRaw = map['createdAt'];
    DateTime createdAt;

    if (createdRaw is Timestamp) {
      createdAt = createdRaw.toDate();
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    } else {
      createdAt = DateTime.now();
    }

    final rawLandmarks = map['landmarks'] as List<dynamic>? ?? const [];

    final landmarks = rawLandmarks
        .map((e) {
      if (e is Map) {
        final x = (e['x'] as num?)?.toDouble() ?? 0.0;
        final y = (e['y'] as num?)?.toDouble() ?? 0.0;
        return Offset(x, y);
      }
      return const Offset(0, 0);
    })
        .toList(growable: false);

    return GripBaselineModel(
      createdAt: createdAt,
      imageUrl: map['imageUrl'] as String? ?? '',
      landmarks: landmarks,
      // 💡 각 수치 캐스팅 뒤에 확실하게 default fallback 데이터(0.0 / 0)를 보장합니다.
      pinchGap: (map['pinchGap'] as num?)?.toDouble() ?? 0.0,
      indexAngle: (map['indexAngle'] as num?)?.toDouble() ?? 0.0,
      imageWidth: (map['imageWidth'] as num?)?.toInt() ?? 0,
      imageHeight: (map['imageHeight'] as num?)?.toInt() ?? 0,
    );
  }

  /// ✅ 안전성 체크 (분석 가능 여부)
  bool get isValid =>
      landmarks.length == 21 &&
          imageWidth > 0 &&
          imageHeight > 0 &&
          imageUrl.isNotEmpty;

  /// ✅ 복사 (부분 업데이트용)
  GripBaselineModel copyWith({
    DateTime? createdAt,
    String? imageUrl,
    List<Offset>? landmarks,
    double? pinchGap,
    double? indexAngle,
    int? imageWidth,
    int? imageHeight,
  }) {
    return GripBaselineModel(
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      landmarks: landmarks ?? this.landmarks,
      pinchGap: pinchGap ?? this.pinchGap,
      indexAngle: indexAngle ?? this.indexAngle,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }
}