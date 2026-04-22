// lib/data/models/tournament_entry_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tournament_model.dart'; // TimestampConverter 재사용을 위해 필요

part 'tournament_entry_model.freezed.dart';
part 'tournament_entry_model.g.dart';

@freezed
class TeamMember with _$TeamMember {
  // ✅ 자식 모델도 JSON 변환 시 Map으로 정확히 변환되도록 설정 (스토리지/DB 저장 시 필수)
  @JsonSerializable(explicitToJson: true)
  const factory TeamMember({
    required String name,
    required String rating,

    // ✅ 각 팀원별 추가 질문에 대한 답변 (예: {"상의 사이즈": "L"})
    @Default({}) Map<String, String> customAnswers,
  }) = _TeamMember;

  factory TeamMember.fromJson(Map<String, dynamic> json) => _$TeamMemberFromJson(json);
}

@freezed
class TournamentEntryModel with _$TournamentEntryModel {
  // ✅ 부모 모델에서 명시적 JSON 변환 활성화
  @JsonSerializable(explicitToJson: true)
  const factory TournamentEntryModel({
    String? id,
    required String userUid, // 신청자(팀장) 고유 UID

    // --- 대표자(팀장) 정보 ---
    required String nameKo,
    required String nameEn,
    required String phone,
    String? email,
    String? rating,
    String? homeShop,

    // --- [추가] 수동 등록 관리용 필드 ---
    @Default(false) bool isManual,     // ✅ true면 주최자가 오프라인으로 받은 정보
    String? registeredBy,             // ✅ 등록한 주최자의 UID (추적용)

    // --- 팀전 전용 정보 ---
    String? teamName,
    @Default([]) List<TeamMember> members, // 팀원 목록
    String? totalRating,

    // ✅ 팀장(본인)의 추가 질문에 대한 답변
    @Default({}) Map<String, String> customAnswers,

    @TimestampConverter() required Timestamp createdAt,
    @TimestampConverter() Timestamp? updatedAt,
    @Default('applied') String status, // applied, confirmed 등
  }) = _TournamentEntryModel;

  factory TournamentEntryModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentEntryModelFromJson(json);
}