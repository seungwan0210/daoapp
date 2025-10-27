// lib/data/models/user_model.dart
/// Firestore에서 가져온 선수 정보
class UserModel {
  final String uid;
  final String 이름;
  final String? 사진;
  final int 총포인트;
  final int 시즌1;
  final int 시즌2;
  final int 시즌3;
  final String 역할; // "admin" or "user"

  UserModel({
  required this.uid,
  required this.이름,
  this.사진,
  this.총포인트 = 0,
  this.시즌1 = 0,
  this.시즌2 = 0,
  this.시즌3 = 0,
  this.역할 = 'user',
});

// Firestore → Dart
factory UserModel.fromMap(Map<String, dynamic> map, String id) {
return UserModel(
uid: id,
이름: map['이름'] ?? '',
사진: map['사진'],
총포인트: map['총포인트'] ?? 0,
시즌1: map['시즌1'] ?? 0,
시즌2: map['시즌2'] ?? 0,
시즌3: map['시즌3'] ?? 0,
역할: map['역할'] ?? 'user',
);
}

// Dart → Firestore
Map<String, dynamic> toMap() {
  return {
    '이름': 이름,
    '사진': 사진,
    '총포인트': 총포인트,
    '시즌1': 시즌1,
    '시즌2': 시즌2,
    '시즌3': 시즌3,
    '역할': 역할,
  };
}
}