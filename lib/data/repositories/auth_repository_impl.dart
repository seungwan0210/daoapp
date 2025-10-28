// lib/data/repositories/auth_repository_impl.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _auth = firebaseAuth,
        _googleSignIn = googleSignIn;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // 토큰 강제 새로고침!
    final idTokenResult = await user.getIdTokenResult(true);
    final isAdmin = idTokenResult.claims?['admin'] == true || idTokenResult.claims?['super_admin'] == true;

    print('isAdmin(): $isAdmin, claims: ${idTokenResult.claims}'); // 디버그

    return isAdmin;
  }
}