// lib/presentation/providers/my_log_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/data/repositories/my_log_repository.dart';

/// 📌 MyLog Repository Provider
final myLogRepositoryProvider = Provider<MyLogRepository>((ref) {
  return MyLogRepository();
});

/// 📌 Firebase Auth 상태 감지 Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 📌 마이로그 스트림 Provider
///
/// - 로그인 안 된 상태: 빈 리스트 스트림 반환
/// - 로딩 중: 빈 리스트 스트림
/// - 에러: 일단 빈 리스트 스트림
/// - 로그인 된 상태: 해당 유저 uid 기준으로 MyLogRepository.getMyLogs 구독
final myLogProvider = StreamProvider<List<MyLogModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    // ✅ 로그인/로그아웃 상태까지 포함해서 User?를 안전하게 받음
    data: (user) {
      if (user == null) {
        // 로그아웃 상태 → 빈 리스트
        return Stream.value(<MyLogModel>[]);
      }

      // 로그인 상태 → 해당 유저의 마이로그 스트림
      return ref.read(myLogRepositoryProvider).getMyLogs(user.uid);
    },
    // 로딩 중일 때도 일단 빈 리스트
    loading: () => Stream.value(<MyLogModel>[]),
    // 에러일 때도 앱이 안 터지도록 빈 리스트 반환
    error: (_, __) => Stream.value(<MyLogModel>[]),
  );
});
