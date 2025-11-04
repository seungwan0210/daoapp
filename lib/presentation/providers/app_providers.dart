// lib/presentation/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/repositories/auth_repository.dart';
import 'package:daoapp/di/service_locator.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return sl<AuthRepository>();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// 관리자 권한 (한 번만 체크)
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;

  try {
    final result = await user.getIdTokenResult(true);
    return result.claims?['admin'] == true || result.claims?['super_admin'] == true;
  } catch (e) {
    return false;
  }
});

/// 프로필 등록 여부 (한 번만 체크)
final userHasProfileProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  return doc.exists;
});