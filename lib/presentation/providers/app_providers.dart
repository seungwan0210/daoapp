// lib/presentation/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/data/repositories/auth_repository.dart';
import 'package:daoapp/di/service_locator.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return sl<AuthRepository>();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Custom Claims 기반 (즉시 반영 위해 FutureProvider)
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;

  final idTokenResult = await user.getIdTokenResult(true);
  final isAdmin = idTokenResult.claims?['admin'] == true || idTokenResult.claims?['super_admin'] == true;
  print('isAdminProvider: $isAdmin');
  return isAdmin;
});