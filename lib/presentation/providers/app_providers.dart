// lib/presentation/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 추가!
import 'package:daoapp/data/repositories/auth_repository.dart';
import 'package:daoapp/di/service_locator.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return sl<AuthRepository>();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// lib/presentation/providers/app_providers.dart
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;

  // 토큰 강제 갱신 (Custom Claims 반영!)
  final idTokenResult = await user.getIdTokenResult(true);
  return idTokenResult.claims?['admin'] == true;
});