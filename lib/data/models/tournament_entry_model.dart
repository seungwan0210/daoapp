// lib/data/models/tournament_entry_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tournament_model.dart'; // TimestampConverter 재사용

part 'tournament_entry_model.freezed.dart';
part 'tournament_entry_model.g.dart';

@freezed
class TournamentEntryModel with _$TournamentEntryModel {
  const factory TournamentEntryModel({
    String? id,
    String? userUid,
    required String nameKo,
    required String nameEn,
    required String phone,
    String? email,
    String? rating,
    String? homeShop,
    @TimestampConverter() required Timestamp createdAt,
  }) = _TournamentEntryModel;

  factory TournamentEntryModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentEntryModelFromJson(json);
}