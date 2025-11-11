// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';

/// 인증 관련 비즈니스 로직 추상화
abstract class AuthRepository {
  /// 현재 로그인된 사용자 (null 가능)
  User? get currentUser;

  /// 로그인 상태 실시간 스트림
  Stream<User?> get authStateChanges;

  /// Google 로그인 + users 문서 자동 생성
  Future<User?> signInWithGoogle();

  /// 로그아웃
  Future<void> signOut();

// isAdmin() 제거됨
// → app_providers.dart의 isAdminProvider가 실시간 처리
}