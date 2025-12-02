// lib/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Auth
import 'package:daoapp/data/repositories/auth_repository.dart';
import 'package:daoapp/data/repositories/auth_repository_impl.dart';

// Point & Ranking
import 'package:daoapp/data/repositories/point_record_repository.dart';
import 'package:daoapp/data/repositories/point_record_repository_impl.dart';

// Arena
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/data/repositories/arena_repository_impl.dart';

// Storage
import 'package:daoapp/services/storage_service.dart';

// ★★★★★ Training 추가 ★★★★★
import 'package:daoapp/data/repositories/training_repository.dart';
import 'package:daoapp/data/repositories/training_repository_impl.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // === Firebase 인스턴스 ===
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // === Auth ===
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    firebaseAuth: sl<FirebaseAuth>(),
    googleSignIn: sl<GoogleSignIn>(),
  ));

  // === Point & Ranking ===
  sl.registerLazySingleton<PointRecordRepository>(
          () => PointRecordRepositoryImpl());

  // === Arena ===
  sl.registerLazySingleton<ArenaRepository>(() => ArenaRepositoryImpl());

  // === Storage ===
  sl.registerLazySingleton<StorageService>(() => StorageService());

  // ★★★★★ Training Repository 등록 (핵심) ★★★★★
  sl.registerLazySingleton<TrainingRepository>(
          () => TrainingRepositoryImpl(firestore: sl<FirebaseFirestore>()));
}
