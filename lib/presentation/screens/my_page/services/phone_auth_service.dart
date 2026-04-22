import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  /// ✅ 전화번호 인증번호 발송
  static Future<void> verifyPhone({
    required String phone,
    required void Function(String) onCodeSent,
    required void Function(String) onError,
    required void Function() onTimeout,
  }) async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          String message = '인증에 실패했습니다.';
          if (e.code == 'invalid-phone-number') {
            message = '유효하지 않은 전화번호 형식입니다.';
          } else if (e.code == 'too-many-requests') {
            message = '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
          }
          onError(e.message ?? message);
        },
        codeSent: (String verificationId, int? resendToken) => onCodeSent(verificationId),
        codeAutoRetrievalTimeout: (String verificationId) => onTimeout(),
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError('인증 요청 중 알 수 없는 오류가 발생했습니다.');
    }
  }

  /// ✅ 인증번호 확인 및 계정 링크/업데이트
  static Future<bool> linkPhone({
    required String verificationId,
    required String smsCode,
    required User currentUser,
    required String newPhone,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // 최신 토큰 정보를 가져와 현재 상태 확인
      final idToken = await currentUser.getIdTokenResult(true);
      final currentPhoneClaim = idToken.claims?['phone_number'] as String?;

      // 이미 인증 서버에 등록된 번호와 바꾸려는 번호가 같다면 성공 처리
      if (currentPhoneClaim == newPhone) {
        return true;
      }

      // 🆕 핵심 수정: 이미 번호가 연결된 경우와 아닌 경우를 나누어 처리
      try {
        if (currentPhoneClaim != null) {
          // 1. 이미 번호가 있는 경우 -> updatePhoneNumber로 교체
          await currentUser.updatePhoneNumber(credential);
        } else {
          // 2. 번호가 처음인 경우 -> linkWithCredential로 연결
          await currentUser.linkWithCredential(credential);
        }

        // 성공 시 유저 정보 강제 리로드 (Auth 탭 반영 속도 향상)
        await currentUser.reload();
        return true;
      } on FirebaseAuthException catch (e) {
        // 이미 연결되었다는 에러가 뜨더라도 강제로 업데이트 시도 (이중 안전장치)
        if (e.code == 'provider-already-linked') {
          await currentUser.updatePhoneNumber(credential);
          await currentUser.reload();
          return true;
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      return false;
    } catch (e) {
      print('Auth Error: $e');
      return false;
    }
  }

  /// ✅ 발생 가능한 에러 상황 정리
  static void _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'credential-already-in-use':
        print('Error: 이 전화번호는 이미 다른 사용자가 사용 중입니다.');
        break;
      case 'invalid-verification-code':
        print('Error: 인증번호가 올바르지 않습니다.');
        break;
      case 'provider-already-linked':
        print('Error: 이미 휴대폰 인증 정보가 계정에 존재합니다.');
        break;
      case 'requires-recent-login':
        print('Error: 보안을 위해 다시 로그인한 후 번호를 변경해주세요.');
        break;
      default:
        print('Error: ${e.code} - ${e.message}');
    }
  }
}