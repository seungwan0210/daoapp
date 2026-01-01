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

  /// ✅ 앱이 튕기더라도 다시 돌아왔을 때 폼이 유지되도록,
  ///    인증 요청 전에 현재 입력값을 Firestore에 초안으로 저장
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
          // isPhoneVerified는 지금 값 유지
          'isPhoneVerified': isPhoneVerified,
          'updatedAt': FieldValue.serverTimestamp(),
          // ✅ 진행 중인 전화 인증 초안 정보 (verificationId는 나중에 onCodeSent에서 채움)
          if (intl != null)
            'phoneAuthDraft': {
              'phoneNumber': intl,
              'requestedAt': FieldValue.serverTimestamp(),
            },
          // ❗ hasProfile 은 여기서 건들지 않는다 (최종 저장에서만 true)
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // 초안 저장 실패는 크게 떠들 필요 없이 무시 (로그만 남기고 싶으면 print 가능)
    }
  }

  Future<void> _loadExistingProfile() async {
    final u = user;
    if (u == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(u.uid).get();

      if (!doc.exists) {
        // 🔹 아직 아무 문서도 없는 완전 신규 유저
        isFirstRegistration = true;
        _safeNotify();
        return;
      }

      final data = doc.data() ?? {};
      final hasProfileFlag = data['hasProfile'] == true;

      // 🔹 프로필 전체는 아직 없어도(hasProfile=false),
      //    휴대폰 인증 정보는 미리 저장될 수 있으므로 무조건 다 읽어옴
      isFirstRegistration = !hasProfileFlag;

      final phoneRaw = data['phoneNumber']?.toString();

      String displayPhone = '';
      if (phoneRaw != null && phoneRaw.startsWith('+82')) {
        final digits = phoneRaw.substring(3);
        if (digits.length >= 9) {
          final d = digits;
          if (d.length == 10) {
            // 010-1234-5678
            displayPhone =
                '0${d.substring(0, 2)}-${d.substring(2, 6)}-${d.substring(6)}';
          } else if (d.length == 9) {
            displayPhone =
                '0${d.substring(0, 2)}-${d.substring(2, 5)}-${d.substring(5)}';
          } else if (d.length == 11) {
            displayPhone =
                '0${d.substring(0, 3)}-${d.substring(3, 7)}-${d.substring(7)}';
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

      // ✅ 진행 중인 전화 인증(phoneAuthDraft) 복원
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
          // 화면용 번호 010-xxxx-xxxx로 포맷
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
          // 기존 유저라면 "수정 중" 상태로 인식해서 입력칸이 보이도록
          if (!isFirstRegistration) {
            isEditingPhone = true;
          }

          verificationId = draftVerificationId;
          codeSent = true; // → 인증번호 입력 칸 다시 보이게
        }
      }

      _safeNotify();
    } catch (e) {
      _safeNotify();
    }
  }

  /// ✅ "인증번호 보내기" 버튼 눌렀을 때
  Future<void> sendVerificationCode() async {
    final input = phoneCtrl.text.trim();
    final digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 11 || !digits.startsWith('0')) {
      _showSnackBar('010으로 시작하는 11자리 번호를 입력하세요');
      return;
    }

    // 🔹 여기서 먼저 현재 입력값을 Firestore에 초안으로 저장
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

        // ✅ Firestore의 phoneAuthDraft에 verificationId까지 저장
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
          } catch (_) {
            // 저장 실패해도 인증 자체는 진행 가능하니 조용히 무시
          }
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

  /// ✅ 문자로 받은 인증번호 확인 + 서버에 인증 상태 저장
  Future<void> verifyCode() async {
    // 1) 입력값 검증
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

    // 2) Firebase Auth 계정에 전화번호 연결(실제 인증 시도)
    final success = await PhoneAuthService.linkPhone(
      verificationId: verificationId!,
      smsCode: codeCtrl.text.trim(),
      currentUser: current,
      newPhone: newPhoneIntl,
    );

    if (success) {
      // 3) Firestore(users/{uid})에도 인증 결과 저장
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(current.uid)
            .set(
          {
            'phoneNumber': newPhoneIntl,
            'isPhoneVerified': true,
            'updatedAt': FieldValue.serverTimestamp(),
            // ✅ 진행 중이던 인증 초안 제거
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

      // 4) 로컬 상태 정리
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
      final onlineRef =
          FirebaseDatabase.instance.ref('online_users/${u.uid}');
      await onlineRef.update({'photoUrl': ''});
    }

    _showSnackBar('사진이 삭제되었습니다.', color: Colors.orange);
    _safeNotify();
  }

  /// ✅ 기존 호환용
  Future<void> save(GlobalKey<FormState> formKey) async {
    final result = await saveAndReturnResult(formKey);
    if (!context.mounted) return;
    _showSnackBar(
      result.message,
      color: result.success ? Colors.green : Colors.red,
    );
  }

  /// ✅ UI(화면)에서 "됐는지/안됐는지" 확실히 알 수 있게 결과를 리턴
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

      if (profileImage != null) {
        profileUrl =
            await ImageUploadService.upload(profileImage!, 'profiles/${u.uid}');
      }
      if (barrelImage != null) {
        barrelUrl =
            await ImageUploadService.upload(barrelImage!, 'barrels/${u.uid}');
      }

      // 국제번호 저장 (+82)
      final normalizedInput2 = normalizedInput;
      final internationalPhone = normalizedInput2.isNotEmpty
          ? '+82${normalizedInput2.substring(1)}'
          : '';

      // admin 플래그 보존
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get();
      final isCurrentlyAdmin = (userDoc.data() ?? {})['admin'] == true;

      // Firestore set(merge)
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'koreanName': koreanNameCtrl.text.trim(),
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

        // ✅ 이미지: 새로 업로드된 게 있으면 그걸, 아니면 기존 url 유지(없으면 delete)
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

      // ✅ RTDB 온라인 사용자에도 반영
      final finalPhotoUrl =
          (profileImage != null) ? (profileUrl ?? '') : (firestoreProfileUrl ?? '');

      final onlineRef =
          FirebaseDatabase.instance.ref('online_users/${u.uid}');
      await onlineRef.update({
        'name': koreanNameCtrl.text.trim(),
        'photoUrl': finalPhotoUrl,
      });

      // ✅ 권한/프로필 플래그 업데이트 함수
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

      // 내부 상태 정리
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
