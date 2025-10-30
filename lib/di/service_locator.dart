// lib/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:daoapp/data/repositories/auth_repository_impl.dart';
import 'package:daoapp/data/repositories/auth_repository.dart';
import 'package:daoapp/data/repositories/point_record_repository_impl.dart';
import 'package:daoapp/data/repositories/point_record_repository.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

  // Auth
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    firebaseAuth: sl<FirebaseAuth>(),
    googleSignIn: sl<GoogleSignIn>(),
  ));

  // Point & Ranking
  sl.registerLazySingleton<PointRecordRepository>(() => PointRecordRepositoryImpl());
  sl.registerFactory(() => RankingProvider(sl<PointRecordRepository>()));
}