// 이 파일은 그대로 유지!

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/training_progress_model.dart';
import 'package:daoapp/data/repositories/training_progress_repository.dart';
import 'package:daoapp/di/service_locator.dart';

final trainingProgressProvider =
StreamProvider.autoDispose<TrainingProgressModel>((ref) {
  final firebaseAuth = sl<FirebaseAuth>();
  final repo = sl<TrainingProgressRepository>();

  final User? user = firebaseAuth.currentUser;

  if (user == null) {
    return const Stream<TrainingProgressModel>.empty();
  }

  return repo.watchProgress(user.uid);
});
