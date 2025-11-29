// lib/user/services/phone_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  static Future<void> verifyPhone({
    required String phone,
    required void Function(String) onCodeSent,
    required void Function(String) onError,
    required void Function() onTimeout,
  }) async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (_) {},
        verificationFailed: (e) => onError(e.message ?? '인증 실패'),
        codeSent: (verificationId, _) => onCodeSent(verificationId),
        codeAutoRetrievalTimeout: (_) => onTimeout(),
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError('요청 실패');
    }
  }

  static Future<bool> linkPhone({
    required String verificationId,
    required String smsCode,
    required User currentUser,
    required String newPhone,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
      final idToken = await currentUser.getIdTokenResult();
      final currentPhoneClaim = idToken.claims?['phone_number'] as String?;

      if (currentPhoneClaim == newPhone) {
        return true;
      } else {
        await currentUser.linkWithCredential(credential);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        print('이미 사용 중인 번호');
      } else if (e.code == 'invalid-verification-code') {
        print('인증번호 오류');
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}