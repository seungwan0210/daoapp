// lib/presentation/providers/my_log_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/data/repositories/my_log_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Repository Provider
final myLogRepositoryProvider = Provider((ref) => MyLogRepository());

// Auth 상태 감지 Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 마이로그 Provider
final myLogProvider = StreamProvider<List<MyLogModel>>((ref) {
  final authState = ref.watch(authStateProvider).value;

  // 로그인 안 되어 있으면 빈 리스트
  if (authState == null) return Stream.value([]);

  // 로그인되어있으면 해당 유저의 마이로그 구독
  return ref.read(myLogRepositoryProvider).getMyLogs(authState.uid);
});
