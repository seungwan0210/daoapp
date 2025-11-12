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

/// 실시간 안 읽은 공지 수 (모든 화면에서 공유)
final unreadNoticesCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);

  final noticesRef = FirebaseFirestore.instance.collection('notices');
  final readRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('readNotices');

  return noticesRef
      .where('isActive', isEqualTo: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final noticeIds = snapshot.docs.map((d) => d.id).toList();
    if (noticeIds.isEmpty) return 0;

    final chunks = <List<String>>[];
    for (var i = 0; i < noticeIds.length; i += 10) {
      chunks.add(noticeIds.sublist(i, i + 10 > noticeIds.length ? noticeIds.length : i + 10));
    }

    int unreadCount = 0;
    for (final chunk in chunks) {
      final readSnapshot = await readRef.where(FieldPath.documentId, whereIn: chunk).get();
      final readIds = readSnapshot.docs.map((d) => d.id).toSet();
      unreadCount += chunk.where((id) => !readIds.contains(id)).length;
    }
    return unreadCount;
  });
});