// lib/presentation/providers/app_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/repositories/auth_repository_impl.dart';
import 'package:daoapp/data/repositories/auth_repository.dart';  // 경로 수정 (domain → data)

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final isAdminProvider = StreamProvider<bool>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('allowed_users')
      .doc(user.email)  // 이메일로 문서 ID
      .snapshots()
      .map((snapshot) => snapshot.exists && snapshot.data()?['isAdmin'] == true);
});