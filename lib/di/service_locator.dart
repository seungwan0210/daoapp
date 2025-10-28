// lib/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:daoapp/data/repositories/auth_repository_impl.dart';
import 'package:daoapp/data/repositories/auth_repository.dart';

final sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    firebaseAuth: sl<FirebaseAuth>(),
    googleSignIn: sl<GoogleSignIn>(),
  ));
}