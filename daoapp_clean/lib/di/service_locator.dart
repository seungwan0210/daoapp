// lib/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/repositories/auth_repository_impl.dart';
import 'package:daoapp/data/repositories/auth_repository.dart';
import 'package:daoapp/data/repositories/point_record_repository_impl.dart';
import 'package:daoapp/data/repositories/point_record_repository.dart';
// import 'package:daoapp/presentation/providers/ranking_provider.dart'; // 삭제!

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
  sl.registerLazySingleton<PointRecordRepository>(() => PointRecordRepositoryImpl()); // 파라미터 제거!

  // sl.registerFactory(() => RankingProvider(sl<PointRecordRepository>())); // 삭제!
}