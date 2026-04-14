import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tournament_model.dart'; // TimestampConverter 재사용

part 'tournament_entry_model.freezed.dart';
part 'tournament_entry_model.g.dart';

@freezed
class TournamentEntryModel with _$TournamentEntryModel {
  const factory TournamentEntryModel({
    /// Firestore document ID (doc.id)
    String? id,

    /// 참가자 유저 UID (entries/{userUid} = userUid 정책이면 사실상 key)
    required String userUid,

    /// 한글 이름
    required String nameKo,

    /// 영문 이름
    required String nameEn,

    /// 연락처
    required String phone,

    /// 이메일 (로그인 이메일, 없을 수도 있음)
    String? email,

    /// 레이팅 (선택)
    String? rating,

    /// 홈샵 (선택)
    String? homeShop,

    /// 신청 시간
    @TimestampConverter() required Timestamp createdAt,

    /// (권장) 수정 시간
    @TimestampConverter() Timestamp? updatedAt,

    /// (권장) 운영 상태값 (지금 당장은 없어도 됨)
    @Default('applied') String status, // applied / canceled / confirmed ...
  }) = _TournamentEntryModel;

  factory TournamentEntryModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentEntryModelFromJson(json);
}
