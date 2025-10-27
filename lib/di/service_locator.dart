// lib/di/service_locator.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:daoapp/data/repositories/auth_repository.dart';
import 'package:daoapp/data/repositories/auth_repository_impl.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // Firebase 인스턴스들은 싱글톤이므로 get_it에 등록할 필요 없음
  // sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);   // 제거
  // sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());         // 제거

  // Firestore, Storage는 필요 시 등록 (선택)
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // Repository만 등록 → 내부에서 FirebaseAuth.instance 직접 사용
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
}