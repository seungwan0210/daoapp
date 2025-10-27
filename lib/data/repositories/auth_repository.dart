// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<User?> signInWithGoogle();
  Future<void> signOut();
  Future<bool> isAdmin();
}