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
import 'package:daoapp/core/utils/chat_utils.dart'; // ✅ 1. ChatUtils 임포트 추가

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

  Future<void> _saveDraftBeforePhoneAuth() async {
    final u = user;
    if (u == null) return;

    final raw = phoneCtrl.text.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    String? intl;
    if (digits.length == 11 && digits.startsWith('0')) {
      intl = '+82${digits.substring(1)}';
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set(
        {
          'koreanName': koreanNameCtrl.text.trim(),
          'englishName': englishNameCtrl.text.trim(),
          'shopName': shopNameCtrl.text.trim(),
          if (intl != null) 'phoneNumber': intl,
          'isPhoneVerified': isPhoneVerified,
          'updatedAt': FieldValue.serverTimestamp(),
          if (intl != null)
            'phoneAuthDraft': {
              'phoneNumber': intl,
              'requestedAt': FieldValue.serverTimestamp(),
            },
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<void> _loadExistingProfile() async {
    final u = user;
    if (u == null) return;

    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(u.uid).get();

      if (!doc.exists) {
        isFirstRegistration = true;
        _safeNotify();
        return;
      }

      final data = doc.data() ?? {};
      final hasProfileFlag = data['hasProfile'] == true;

      isFirstRegistration = !hasProfileFlag;

      final phoneRaw = data['phoneNumber']?.toString();

      String displayPhone = '';
      if (phoneRaw != null && phoneRaw.startsWith('+82')) {
        final digits = phoneRaw.substring(3);
        if (digits.length >= 9) {
          final d = digits;
          if (d.length == 10) {
            displayPhone =
            '0${d.substring(0, 2)}-${d.substring(2, 6)}-${d.substring(6)}';
          } else if (d.length == 9) {
            displayPhone =
            '0${d.substring(0, 2)}-${d.substring(2, 5)}-${d.substring(5)}';
          } else if (d.length == 11) {
            displayPhone =
            '0${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
          } else {
            displayPhone = phoneRaw;
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

      final draft = data['phoneAuthDraft'];
      if (draft is Map<String, dynamic>) {
        final draftPhone = draft['phoneNumber']?.toString();
        final draftVerificationId = draft['verificationId']?.toString();
        final requestedAt = draft['requestedAt'];

        bool isFresh = true;
        if (requestedAt is Timestamp) {
          final now = DateTime.now();
          isFresh = now.difference(requestedAt.toDate()).inMinutes < 10;
        }

        final alreadyVerified = isPhoneVerified == true;

        if (!alreadyVerified &&
            draftPhone != null &&
            draftVerificationId != null &&
            isFresh) {
          String restoreDisplay = phoneCtrl.text;
          if (draftPhone.startsWith('+82')) {
            final digits = draftPhone.substring(3);
            if (digits.length >= 9) {
              if (digits.length == 10) {
                restoreDisplay =
                '0${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
              } else if (digits.length == 9) {
                restoreDisplay =
                '0${digits.substring(0, 2)}-${digits.substring(2, 5)}-${digits.substring(5)}';
              } else if (digits.length == 11) {
                restoreDisplay =
                '0${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
              }
            }
          }

          phoneCtrl.text = restoreDisplay;
          if (!isFirstRegistration) {
            isEditingPhone = true;
          }

          verificationId = draftVerificationId;
          codeSent = true;
        }
      }

      _safeNotify();
    } catch (e) {
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

    await _saveDraftBeforePhoneAuth();

    final phone = '+82${digits.substring(1)}';

    isVerifying = true;
    verificationId = null;
    codeCtrl.clear();
    _safeNotify();

    await PhoneAuthService.verifyPhone(
      phone: phone,
      onCodeSent: (verificationId) async {
        if (!context.mounted) return;

        this.verificationId = verificationId;
        codeSent = true;
        isVerifying = false;
        _safeNotify();
        _showSnackBar('인증번호가 전송되었습니다');

        final u = user;
        if (u != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(u.uid)
                .set(
              {
                'phoneAuthDraft': {
                  'phoneNumber': phone,
                  'verificationId': verificationId,
                  'requestedAt': FieldValue.serverTimestamp(),
                },
              },
              SetOptions(merge: true),
            );
          } catch (_) {}
        }
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
    if (codeCtrl.text.length != 6 ||
        !RegExp(r'^\d{6}$').hasMatch(codeCtrl.text.trim())) {
      _showSnackBar('6자리 숫자 인증번호를 입력하세요');
      return;
    }

    if (verificationId == null) {
      _showSnackBar('인증번호를 다시 요청하세요');
      return;
    }

    isVerifying = true;
    _safeNotify();

    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      isVerifying = false;
      _safeNotify();
      _showSnackBar('로그인이 필요합니다', color: Colors.red);
      return;
    }

    final newPhoneIntl = _formatToInternational(phoneCtrl.text.trim());
    if (newPhoneIntl.isEmpty) {
      isVerifying = false;
      _safeNotify();
      _showSnackBar('010으로 시작하는 올바른 번호를 입력해주세요');
      return;
    }

    final success = await PhoneAuthService.linkPhone(
      verificationId: verificationId!,
      smsCode: codeCtrl.text.trim(),
      currentUser: current,
      newPhone: newPhoneIntl,
    );

    if (success) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(current.uid)
            .set(
          {
            'phoneNumber': newPhoneIntl,
            'isPhoneVerified': true,
            'updatedAt': FieldValue.serverTimestamp(),
            'phoneAuthDraft': FieldValue.delete(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        _showSnackBar(
          '인증은 완료되었지만 서버 저장 중 문제가 발생했습니다.\n프로필 저장을 한 번 더 시도해주세요.',
          color: Colors.orange,
        );
      }

      isPhoneVerified = true;
      isEditingPhone = false;
      codeSent = false;
      originalPhone = phoneCtrl.text.trim();
      verificationId = null;
      codeCtrl.clear();

      _showSnackBar(
        '휴대폰 번호가 성공적으로 인증되었습니다!',
        color: Colors.green,
      );
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
        content:
        const Text('정말로 이 사진을 삭제하시겠습니까?\n삭제 후 복구할 수 없습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final String? targetUrl = isProfile ? firestoreProfileUrl : firestoreBarrelUrl;

    if (isProfile) {
      profileImage = null;
      firestoreProfileUrl = null;
    } else {
      barrelImage = null;
      firestoreBarrelUrl = null;
    }

    if (targetUrl != null && targetUrl.isNotEmpty) {
      await ImageUploadService.deleteByUrl(targetUrl);
    }

    if (isProfile) {
      final onlineRef =
      FirebaseDatabase.instance.ref('online_users/${u.uid}');
      await onlineRef.update({'photoUrl': ''});
    }

    _showSnackBar('사진이 삭제되었습니다.', color: Colors.orange);
    _safeNotify();
  }

  Future<void> save(GlobalKey<FormState> formKey) async {
    final result = await saveAndReturnResult(formKey);
    if (!context.mounted) return;
    _showSnackBar(
      result.message,
      color: result.success ? Colors.green : Colors.red,
    );
  }

  Future<SaveResult> saveAndReturnResult(
      GlobalKey<FormState> formKey) async {
    if (_isSaving) {
      return const SaveResult(
          success: false, message: '저장 중입니다. 잠시만 기다려주세요.');
    }

    final u = user;
    if (u == null) {
      return const SaveResult(
          success: false, message: '로그인 후 이용해주세요.');
    }

    final formState = formKey.currentState;
    if (formState == null) {
      return const SaveResult(
          success: false, message: '폼 상태를 찾을 수 없습니다.');
    }

    if (!formState.validate()) {
      return const SaveResult(
          success: false, message: '입력값을 확인해주세요.');
    }

    final phoneInput = phoneCtrl.text.trim();
    final isFirstReg = isFirstRegistration;

    String normalize(String s) => s.replaceAll(RegExp(r'\D'), '');
    final normalizedInput = normalize(phoneInput);
    final normalizedOriginal =
    originalPhone != null ? normalize(originalPhone!) : '';
    final isPhoneChanged =
        !isFirstReg && (normalizedInput != normalizedOriginal);

    if ((isFirstReg || isPhoneChanged) && !isPhoneVerified) {
      return const SaveResult(
          success: false, message: '전화번호 인증을 완료해주세요!');
    }

    if (codeSent) {
      return const SaveResult(
          success: false, message: '인증번호 확인 후 저장해주세요.');
    }

    if (isEditingPhone && !isPhoneVerified) {
      return const SaveResult(
          success: false, message: '인증을 완료한 후 저장해주세요.');
    }

    _isSaving = true;
    _safeNotify();

    try {
      String? profileUrl;
      String? barrelUrl;

      final String? oldProfileUrl = firestoreProfileUrl;
      final String? oldBarrelUrl = firestoreBarrelUrl;

      if (profileImage != null) {
        if (oldProfileUrl != null) await ImageUploadService.deleteByUrl(oldProfileUrl);
        profileUrl =
        await ImageUploadService.upload(profileImage!, 'profiles/${u.uid}');
      }
      if (barrelImage != null) {
        if (oldBarrelUrl != null) await ImageUploadService.deleteByUrl(oldBarrelUrl);
        barrelUrl =
        await ImageUploadService.upload(barrelImage!, 'barrels/${u.uid}');
      }

      final normalizedInput2 = normalizedInput;
      final internationalPhone = normalizedInput2.isNotEmpty
          ? '+82${normalizedInput2.substring(1)}'
          : '';

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get();
      final isCurrentlyAdmin = (userDoc.data() ?? {})['admin'] == true;

      // ✅ [추가] 공지에 사용할 닉네임 미리 저장
      final String nickname = koreanNameCtrl.text.trim();
      final bool wasFirstReg = isFirstRegistration;

      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'koreanName': nickname,
        'englishName': englishNameCtrl.text.trim(),
        'shopName': shopNameCtrl.text.trim(),

        'phoneNumber': internationalPhone.isNotEmpty
            ? internationalPhone
            : FieldValue.delete(),
        'isPhoneVerified': isPhoneVerified,

        'barrelName': barrelNameCtrl.text.trim(),
        'shaft': shaftCtrl.text.trim(),
        'flight': flightCtrl.text.trim(),
        'tip': tipCtrl.text.trim(),

        'profileImageUrl': profileImage != null
            ? profileUrl
            : (firestoreProfileUrl != null &&
            firestoreProfileUrl!.isNotEmpty
            ? firestoreProfileUrl
            : FieldValue.delete()),
        'barrelImageUrl': barrelImage != null
            ? barrelUrl
            : (firestoreBarrelUrl != null &&
            firestoreBarrelUrl!.isNotEmpty
            ? firestoreBarrelUrl
            : FieldValue.delete()),

        'hasProfile': true,
        'updatedAt': FieldValue.serverTimestamp(),

        if (isCurrentlyAdmin) 'admin': true,
      }, SetOptions(merge: true));

      // profile_service.dart 내부

      if (wasFirstReg) {
        // ✅ 이제 유틸에서 함수 이름만 호출하면 끝!
        await ChatUtils.sendWelcomeNotice(nickname);
        isFirstRegistration = false;
      }

      final finalPhotoUrl =
      (profileImage != null) ? (profileUrl ?? '') : (firestoreProfileUrl ?? '');

      final onlineRef =
      FirebaseDatabase.instance.ref('online_users/${u.uid}');
      await onlineRef.update({
        'name': nickname,
        'photoUrl': finalPhotoUrl,
      });

      String? warning;
      try {
        final callable =
        FirebaseFunctions.instance.httpsCallable('setHasProfile');
        await callable.call();
        await FirebaseAuth.instance.currentUser?.reload();
        ref.invalidate(isAdminProvider);
      } catch (e) {
        warning = '권한 업데이트 실패: $e';
      }

      originalPhone = phoneInput;
      isEditingPhone = false;
      codeSent = false;

      ref.invalidate(userHasProfileProvider);

      if (warning != null) {
        return SaveResult(
            success: true,
            message: '프로필 저장 완료! (참고: $warning)');
      }
      return SaveResult.ok;
    } on FirebaseException catch (e) {
      final msg = (e.message ?? e.code).toString();
      return SaveResult(success: false, message: '저장 실패: $msg');
    } catch (e) {
      return SaveResult(
          success: false, message: '저장 중 오류: $e');
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
    if (isFirstRegistration && user?.photoURL != null) {
      return NetworkImage(user!.photoURL!);
    }
    return null;
  }

  DecorationImage? getBarrelDecorationImage() {
    if (barrelImage != null) {
      return DecorationImage(
          image: FileImage(barrelImage!), fit: BoxFit.cover);
    }
    if (firestoreBarrelUrl != null && firestoreBarrelUrl!.isNotEmpty) {
      return DecorationImage(
          image: NetworkImage(firestoreBarrelUrl!), fit: BoxFit.cover);
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