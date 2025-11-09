// lib/presentation/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/repositories/auth_repository.dart';
import 'package:daoapp/di/service_locator.dart';

// === Auth ===
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return sl<AuthRepository>();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// === 클레임 실시간 감시 ===
final userClaimsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final token = await user.getIdTokenResult(true);
  return token.claims;
});

// === 관리자 여부 (실시간) ===
final isAdminProvider = Provider<bool>((ref) {
  final claims = ref.watch(userClaimsProvider).value;
  return claims?['admin'] == true;
});

// === 프로필 등록 여부 ===
final userHasProfileProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists && (doc.data()?['hasProfile'] == true));
});

// === 전화번호 인증 여부 ===
final userPhoneVerifiedProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.data()?['isPhoneVerified'] == true);
});

// === 완전 인증 여부 ===
final isFullyAuthenticatedProvider = Provider<bool>((ref) {
  final hasProfile = ref.watch(userHasProfileProvider).value ?? false;
  final phoneVerified = ref.watch(userPhoneVerifiedProvider).value ?? false;
  return hasProfile && phoneVerified;
});