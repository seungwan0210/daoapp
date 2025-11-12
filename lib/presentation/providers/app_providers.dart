import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/repositories/auth_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:rxdart/rxdart.dart'; // 추가!

// === Auth ===
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return sl<AuthRepository>();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// === 관리자 여부 ===
final isAdminProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists && (doc.data()?['admin'] == true));
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

// === 실시간 안 읽은 공지 수 ===
final unreadNoticesCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);

  final noticesStream = FirebaseFirestore.instance
      .collection('notices')
      .where('isActive', isEqualTo: true)
      .snapshots();

  final readNoticesStream = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('readNotices')
      .snapshots();

  return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, int>(
    noticesStream,
    readNoticesStream,
        (notices, readNotices) {
      final readIds = readNotices.docs.map((e) => e.id).toSet();
      return notices.docs.where((doc) => !readIds.contains(doc.id)).length;
    },
  );
});