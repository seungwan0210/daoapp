// lib/user/services/profile_service.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:daoapp/presentation/providers/app_providers.dart';
import 'image_upload_service.dart';
import 'phone_auth_service.dart';

/// ✅ 저장 결과를 UI로 알려주기 위한 모델
class SaveResult {
  final bool success;
  final String message;

  const SaveResult({required this.success, required this.message});

  static const ok = SaveResult(success: true, message: '프로필이 저장되었습니다.');
}

class ProfileService extends ChangeNotifier {
  final BuildContext context;
  final WidgetRef ref;

  User? get user => FirebaseAuth.instance.currentUser;

  final koreanNameCtrl = TextEditingController();
  final englishNameCtrl = TextEditingController();
  final shopNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final barrelNameCtrl = TextEditingController();
  final shaftCtrl = TextEditingController();
  final flightCtrl = TextEditingController();
  final tipCtrl = TextEditingController();

  bool isFirstRegistration = false;
  bool isPhoneVerified = false;
  String? originalPhone;
  bool isEditingPhone = false;
  bool codeSent = false;
  bool isVerifying = false;
  String? verificationId;

  File? profileImage;
  File? barrelImage;
  String? firestoreProfileUrl;
  String? firestoreBarrelUrl;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  ProfileService(this.context, this.ref) {
    _loadExistingProfile();
  }

  String _formatToInternational(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 || !digits.startsWith('0')) return '';
    return '+82${digits.substring(1)}';
  }

  Future<void> _loadExistingProfile() async {
    final u = user;
    if (u == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      final exists = doc.exists && (doc.data()?['hasProfile'] == true);

      if (!exists) {
        isFirstRegistration = true;
        _safeNotify();
        return;
      }

      final data = doc.data() ?? {};
      final phoneRaw = data['phoneNumber']?.toString();

      String displayPhone = '';
      if (phoneRaw != null && phoneRaw.startsWith('+82')) {
        final digits = phoneRaw.substring(3);
        // 보통 +82 10xxxxxxxx 또는 10xxxxxxxxx 형태가 들어오므로 아래처럼 표시
        if (digits.length >= 9) {
          final d = digits;
          // 10 + 8~9 자리 → 010-xxxx-xxxx 형태로 맞추기
          // digits가 10자리면 3-4-3이 아니라 3-4-4가 더 자연스러워서 아래 처리
          if (d.length == 10) {
            displayPhone = '0${d.substring(0, 2)}-${d.substring(2, 6)}-${d.substring(6)}'; // 010-1234-5678
          } else if (d.length == 9) {
            displayPhone = '0${d.substring(0, 2)}-${d.substring(2, 5)}-${d.substring(5)}';
          } else if (d.length == 11) {
            displayPhone = '0${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
          } else {
            displayPhone = phoneRaw; // fallback
          }
        }
      }

      koreanNameCtrl.text = (data['koreanName'] ?? '').toString();
      englishNameCtrl.text = (data['englishName'] ?? '').toString();
      shopNameCtrl.text = (data['shopName'] ?? '').toString();
      phoneCtrl.text = displayPhone;
      originalPhone = displayPhone;

      isPhoneVerified = data['isPhoneVerified'] == true;

      barrelNameCtrl.text = (data['barrelName'] ?? '').toString();
      shaftCtrl.text = (data['shaft'] ?? '').toString();
      flightCtrl.text = (data['flight'] ?? '').toString();
      tipCtrl.text = (data['tip'] ?? '').toString();

      firestoreProfileUrl = data['profileImageUrl']?.toString();
      firestoreBarrelUrl = data['barrelImageUrl']?.toString();

      _safeNotify();
    } catch (e) {
      // 로드 실패는 조용히(필요하면 로그/스낵바 가능)
      _safeNotify();
    }
  }

  Future<void> sendVerificationCode() async {
    final input = phoneCtrl.text.trim();
    final digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 11 || !digits.startsWith('0')) {
      _showSnackBar('010으로 시작하는 11자리 번호를 입력하세요');
      return;
    }

    final phone = '+82${digits.substring(1)}';

    isVerifying = true;
    verificationId = null;
    codeCtrl.clear();
    _safeNotify();

    await PhoneAuthService.verifyPhone(
      phone: phone,
      onCodeSent: (verificationId) {
        if (!context.mounted) return;
        this.verificationId = verificationId;
        codeSent = true;
        isVerifying = false;
        _safeNotify();
        _showSnackBar('인증번호가 전송되었습니다');
      },
      onError: (msg) {
        if (!context.mounted) return;
        _showSnackBar(msg);
        isVerifying = false;
        _safeNotify();
      },
      onTimeout: () {
        if (!context.mounted) return;
        verificationId = null;
        codeSent = false;
        isVerifying = false;
        _safeNotify();
        _showSnackBar('인증번호가 만료되었습니다. 다시 요청하세요', color: Colors.orange);
      },
    );
  }

  Future<void> verifyCode() async {
    if (codeCtrl.text.length != 6 || !RegExp(r'^\d{6}$').hasMatch(codeCtrl.text.trim())) {
      _showSnackBar('6자리 숫자 인증번호를 입력하세요');
      return;
    }

    if (verificationId == null) {
      _showSnackBar('인증번호를 다시 요청하세요');
      return;
    }

    isVerifying = true;
    _safeNotify();

    final newPhone = _formatToInternational(phoneCtrl.text.trim());

    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      isVerifying = false;
      _safeNotify();
      _showSnackBar('로그인이 필요합니다', color: Colors.red);
      return;
    }

    final success = await PhoneAuthService.linkPhone(
      verificationId: verificationId!,
      smsCode: codeCtrl.text.trim(),
      currentUser: current,
      newPhone: newPhone,
    );

    if (success) {
      isPhoneVerified = true;
      isEditingPhone = false;
      codeSent = false;
      originalPhone = phoneCtrl.text.trim();
      codeCtrl.clear();
      _showSnackBar('휴대폰 번호가 성공적으로 인증되었습니다!', color: Colors.green);
    } else {
      _showSnackBar('인증 실패');
    }

    isVerifying = false;
    _safeNotify();
  }

  Future<void> pickImage(bool isProfile) async {
    final image = await ImageUploadService.pickImage();
    if (image != null && context.mounted) {
      if (isProfile) {
        profileImage = File(image.path);
      } else {
        barrelImage = File(image.path);
      }
      _safeNotify();
    }
  }

  Future<void> deleteImage(bool isProfile) async {
    final u = user;
    if (u == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('정말로 이 사진을 삭제하시겠습니까?\n삭제 후 복구할 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (isProfile) {
      profileImage = null;
      firestoreProfileUrl = null;
    } else {
      barrelImage = null;
      firestoreBarrelUrl = null;
    }

    final path = isProfile ? 'profiles/${u.uid}' : 'barrels/${u.uid}';
    await ImageUploadService.delete(path);

    if (isProfile) {
      final onlineRef = FirebaseDatabase.instance.ref('online_users/${u.uid}');
      await onlineRef.update({'photoUrl': ''});
    }

    _showSnackBar('사진이 삭제되었습니다.', color: Colors.orange);
    _safeNotify();
  }

  /// ✅ 기존 호환용: 내부적으로 결과를 만들고, 필요하면 여기서 스낵바만 띄우는 용도로 사용 가능
  Future<void> save(GlobalKey<FormState> formKey) async {
    final result = await saveAndReturnResult(formKey);
    // 기존 코드 흐름을 유지하고 싶으면 여기서만 스낵바 처리:
    if (!context.mounted) return;
    _showSnackBar(
      result.message,
      color: result.success ? Colors.green : Colors.red,
    );
  }

  /// ✅ UI(화면)에서 "됐는지/안됐는지" 확실히 알 수 있게 결과를 리턴
  Future<SaveResult> saveAndReturnResult(GlobalKey<FormState> formKey) async {
    if (_isSaving) {
      return const SaveResult(success: false, message: '저장 중입니다. 잠시만 기다려주세요.');
    }

    final u = user;
    if (u == null) {
      return const SaveResult(success: false, message: '로그인 후 이용해주세요.');
    }

    final formState = formKey.currentState;
    if (formState == null) {
      return const SaveResult(success: false, message: '폼 상태를 찾을 수 없습니다.');
    }

    if (!formState.validate()) {
      return const SaveResult(success: false, message: '입력값을 확인해주세요.');
    }

    final phoneInput = phoneCtrl.text.trim();
    final isFirstReg = isFirstRegistration;

    String normalize(String s) => s.replaceAll(RegExp(r'\D'), '');
    final normalizedInput = normalize(phoneInput);
    final normalizedOriginal = originalPhone != null ? normalize(originalPhone!) : '';
    final isPhoneChanged = !isFirstReg && (normalizedInput != normalizedOriginal);

    if ((isFirstReg || isPhoneChanged) && !isPhoneVerified) {
      return const SaveResult(success: false, message: '전화번호 인증을 완료해주세요!');
    }

    if (codeSent) {
      return const SaveResult(success: false, message: '인증번호 확인 후 저장해주세요.');
    }

    if (isEditingPhone && !isPhoneVerified) {
      return const SaveResult(success: false, message: '인증을 완료한 후 저장해주세요.');
    }

    _isSaving = true;
    _safeNotify();

    try {
      String? profileUrl;
      String? barrelUrl;

      if (profileImage != null) {
        profileUrl = await ImageUploadService.upload(profileImage!, 'profiles/${u.uid}');
      }
      if (barrelImage != null) {
        barrelUrl = await ImageUploadService.upload(barrelImage!, 'barrels/${u.uid}');
      }

      // 국제번호 저장 (+82)
      final internationalPhone = normalizedInput.isNotEmpty
          ? '+82${normalizedInput.substring(1)}'
          : '';

      // admin 플래그 보존
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      final isCurrentlyAdmin = (userDoc.data() ?? {})['admin'] == true;

      // Firestore set(merge)
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'koreanName': koreanNameCtrl.text.trim(),
        'englishName': englishNameCtrl.text.trim(),
        'shopName': shopNameCtrl.text.trim(),

        'phoneNumber': internationalPhone.isNotEmpty ? internationalPhone : FieldValue.delete(),
        'isPhoneVerified': isPhoneVerified,

        'barrelName': barrelNameCtrl.text.trim(),
        'shaft': shaftCtrl.text.trim(),
        'flight': flightCtrl.text.trim(),
        'tip': tipCtrl.text.trim(),

        // ✅ 이미지: 새로 업로드된 게 있으면 그걸, 아니면 기존 url 유지(없으면 delete)
        'profileImageUrl': profileImage != null
            ? profileUrl
            : (firestoreProfileUrl != null && firestoreProfileUrl!.isNotEmpty
            ? firestoreProfileUrl
            : FieldValue.delete()),
        'barrelImageUrl': barrelImage != null
            ? barrelUrl
            : (firestoreBarrelUrl != null && firestoreBarrelUrl!.isNotEmpty
            ? firestoreBarrelUrl
            : FieldValue.delete()),

        'hasProfile': true,
        'updatedAt': FieldValue.serverTimestamp(),

        if (isCurrentlyAdmin) 'admin': true,
      }, SetOptions(merge: true));

      // ✅ RTDB 온라인 사용자에도 반영 (photoUrl은 "최종 프로필 url"로)
      final finalPhotoUrl = (profileImage != null)
          ? (profileUrl ?? '')
          : (firestoreProfileUrl ?? '');

      final onlineRef = FirebaseDatabase.instance.ref('online_users/${u.uid}');
      await onlineRef.update({
        'name': koreanNameCtrl.text.trim(),
        'photoUrl': finalPhotoUrl,
      });

      // ✅ 권한/프로필 플래그 업데이트 함수 (실패해도 저장 자체는 성공으로 처리 가능)
      String? warning;
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('setHasProfile');
        await callable.call();
        await FirebaseAuth.instance.currentUser?.reload();
        ref.invalidate(isAdminProvider);
      } catch (e) {
        warning = '권한 업데이트 실패: $e';
      }

      // 내부 상태 정리
      originalPhone = phoneInput;
      isEditingPhone = false;
      codeSent = false;

      // provider invalidate (UI에서 pop은 여기서 하지 말고 화면에서 처리!)
      ref.invalidate(userHasProfileProvider);

      // 저장 성공 메시지(경고 포함)
      if (warning != null) {
        return SaveResult(success: true, message: '프로필 저장 완료! (참고: $warning)');
      }
      return SaveResult.ok;
    } on FirebaseException catch (e) {
      // FirebaseException은 메시지를 조금 더 사람이 이해하기 좋게
      final msg = (e.message ?? e.code).toString();
      return SaveResult(success: false, message: '저장 실패: $msg');
    } catch (e) {
      return SaveResult(success: false, message: '저장 중 오류: $e');
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _safeNotify() {
    if (context.mounted) notifyListeners();
  }

  ImageProvider? getProfileImageProvider() {
    if (profileImage != null) return FileImage(profileImage!);
    if (firestoreProfileUrl != null && firestoreProfileUrl!.isNotEmpty) {
      return NetworkImage(firestoreProfileUrl!);
    }
    if (isFirstRegistration && user?.photoURL != null) return NetworkImage(user!.photoURL!);
    return null;
  }

  DecorationImage? getBarrelDecorationImage() {
    if (barrelImage != null) {
      return DecorationImage(image: FileImage(barrelImage!), fit: BoxFit.cover);
    }
    if (firestoreBarrelUrl != null && firestoreBarrelUrl!.isNotEmpty) {
      return DecorationImage(image: NetworkImage(firestoreBarrelUrl!), fit: BoxFit.cover);
    }
    return null;
  }

  @override
  void dispose() {
    koreanNameCtrl.dispose();
    englishNameCtrl.dispose();
    shopNameCtrl.dispose();
    phoneCtrl.dispose();
    codeCtrl.dispose();
    barrelNameCtrl.dispose();
    shaftCtrl.dispose();
    flightCtrl.dispose();
    tipCtrl.dispose();
    super.dispose();
  }
}
