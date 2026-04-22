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

  // --- 상태 관리 변수 ---
  bool isFirstRegistration = false;
  bool isPhoneVerified = false;
  String? originalPhone; // 내부 비교용 (실제 인증 성공한 국제 규격 번호)
  bool isEditingPhone = false;
  bool codeSent = false;
  bool isVerifying = false;
  String? verificationId;

  // 🆕 국가 코드 관리 (기본값 한국)
  String selectedCountryCode = '+82';

  File? profileImage;
  File? barrelImage;
  String? firestoreProfileUrl;
  String? firestoreBarrelUrl;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  ProfileService(this.context, this.ref) {
    _loadExistingProfile();
    // 🆕 [빈틈 봉쇄 1] 번호가 실시간으로 바뀌면 인증 상태 해제
    phoneCtrl.addListener(_onPhoneChanged);
  }

  // 🆕 실시간 번호 변경 감지 리스너
  void _onPhoneChanged() {
    final currentFull = _formatToInternational(phoneCtrl.text.trim(), selectedCountryCode);
    // 현재 입력창 번호가 '인증 성공한 번호'와 다르면 즉시 인증 취소
    if (isPhoneVerified && currentFull != originalPhone) {
      isPhoneVerified = false;
      _safeNotify();
    }
  }

  // 🆕 국가 코드 변경 메서드
  void setCountryCode(String code) {
    if (selectedCountryCode == code) return;
    selectedCountryCode = code;
    _onPhoneChanged();
    _safeNotify();
  }

  // 🆕 번호 오입력 시 탈출구 (상태 초기화)
  void resetVerification() {
    codeSent = false;
    verificationId = null;
    codeCtrl.clear();
    isVerifying = false;
    _safeNotify();
  }

  // 🆕 [정교화] 국제 규격 변환 로직 (중복 방지 및 글로벌 대응)
  String _formatToInternational(String input, String countryCode) {
    String digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';

    // 한국(+82)이고 010 등으로 시작하면 앞의 0을 제거
    if (countryCode == '+82' && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // 국가 코드가 숫자에 중복 포함된 경우 처리 (예: 8210...)
    final pureCC = countryCode.replaceAll('+', '');
    if (digits.startsWith(pureCC)) {
      digits = digits.substring(pureCC.length);
    }

    return '$countryCode$digits';
  }

  /// ✅ 인증 요청 전 초안 저장
  Future<void> _saveDraftBeforePhoneAuth() async {
    final u = user;
    if (u == null) return;
    final intl = _formatToInternational(phoneCtrl.text.trim(), selectedCountryCode);
    try {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set(
        {
          'koreanName': koreanNameCtrl.text.trim(),
          'englishName': englishNameCtrl.text.trim(),
          'shopName': shopNameCtrl.text.trim(),
          if (intl.isNotEmpty) 'phoneNumber': intl,
          'isPhoneVerified': isPhoneVerified,
          'updatedAt': FieldValue.serverTimestamp(),
          if (intl.isNotEmpty)
            'phoneAuthDraft': {
              'phoneNumber': intl,
              'selectedCountryCode': selectedCountryCode,
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      if (!doc.exists) {
        isFirstRegistration = true;
        _safeNotify();
        return;
      }
      final data = doc.data() ?? {};
      isFirstRegistration = data['hasProfile'] != true;
      final phoneRaw = data['phoneNumber']?.toString() ?? '';

      if (phoneRaw.startsWith('+')) {
        originalPhone = phoneRaw;
        if (phoneRaw.startsWith('+82')) {
          selectedCountryCode = '+82';
          final digits = phoneRaw.substring(3);
          if (digits.length == 10) {
            phoneCtrl.text = '0${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
          } else if (digits.length == 11) {
            phoneCtrl.text = '0${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
          } else {
            phoneCtrl.text = '0$digits';
          }
        } else {
          if (phoneRaw.startsWith('+81')) selectedCountryCode = '+81';
          else if (phoneRaw.startsWith('+1')) selectedCountryCode = '+1';
          phoneCtrl.text = phoneRaw.replaceFirst(selectedCountryCode, '');
        }
      }

      koreanNameCtrl.text = (data['koreanName'] ?? '').toString();
      englishNameCtrl.text = (data['englishName'] ?? '').toString();
      shopNameCtrl.text = (data['shopName'] ?? '').toString();
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
        final draftCountry = draft['selectedCountryCode']?.toString() ?? '+82';
        final draftVerificationId = draft['verificationId']?.toString();
        final requestedAt = draft['requestedAt'];
        if (isPhoneVerified != true && draftPhone != null && draftVerificationId != null) {
          if (DateTime.now().difference((requestedAt as Timestamp).toDate()).inMinutes < 10) {
            selectedCountryCode = draftCountry;
            phoneCtrl.text = draftPhone.replaceFirst(draftCountry, draftCountry == '+82' ? '0' : '');
            if (!isFirstRegistration) isEditingPhone = true;
            verificationId = draftVerificationId;
            codeSent = true;
          }
        }
      }
      _safeNotify();
    } catch (e) { _safeNotify(); }
  }

  Future<void> sendVerificationCode() async {
    final digits = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) { _showSnackBar('전화번호를 입력하세요'); return; }
    await _saveDraftBeforePhoneAuth();
    final phone = _formatToInternational(phoneCtrl.text.trim(), selectedCountryCode);
    isVerifying = true; verificationId = null; codeCtrl.clear(); _safeNotify();

    await PhoneAuthService.verifyPhone(
      phone: phone,
      onCodeSent: (vId) async {
        if (!context.mounted) return;
        verificationId = vId; codeSent = true; isVerifying = false; _safeNotify();
        _showSnackBar('인증번호가 전송되었습니다');
        final u = user;
        if (u != null) {
          try {
            await FirebaseFirestore.instance.collection('users').doc(u.uid).set(
              {'phoneAuthDraft': {'phoneNumber': phone, 'selectedCountryCode': selectedCountryCode, 'verificationId': vId, 'requestedAt': FieldValue.serverTimestamp()}},
              SetOptions(merge: true),
            );
          } catch (_) {}
        }
      },
      onError: (msg) { if (context.mounted) { _showSnackBar(msg); isVerifying = false; _safeNotify(); } },
      onTimeout: () { if (context.mounted) { resetVerification(); _showSnackBar('인증번호 만료', color: Colors.orange); } },
    );
  }

  Future<void> verifyCode() async {
    final code = codeCtrl.text.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) { _showSnackBar('6자리 입력'); return; }
    if (verificationId == null) { _showSnackBar('재요청 필요'); return; }

    isVerifying = true; _safeNotify();
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) { isVerifying = false; _safeNotify(); return; }

    final newPhoneIntl = _formatToInternational(phoneCtrl.text.trim(), selectedCountryCode);

    // 🆕 PhoneAuthService 내부에서 updatePhoneNumber/linkWithCredential 분기 처리됨
    final success = await PhoneAuthService.linkPhone(
      verificationId: verificationId!,
      smsCode: code,
      currentUser: current,
      newPhone: newPhoneIntl,
    );

    if (success) {
      // ✅ [빈틈 봉쇄] 서버(Auth) 성공 시에만 originalPhone을 교체하여 저장 권한 부여
      originalPhone = newPhoneIntl;
      isPhoneVerified = true;
      isEditingPhone = false;
      codeSent = false;
      verificationId = null;
      codeCtrl.clear();

      try {
        // Firestore 즉시 업데이트로 Auth와 동기화
        await FirebaseFirestore.instance.collection('users').doc(current.uid).set(
          {'phoneNumber': newPhoneIntl, 'isPhoneVerified': true, 'updatedAt': FieldValue.serverTimestamp(), 'phoneAuthDraft': FieldValue.delete()},
          SetOptions(merge: true),
        );
        _showSnackBar('인증 및 번호 변경 완료!', color: Colors.green);
      } catch (_) {}
    } else {
      isPhoneVerified = false;
      _showSnackBar('인증 실패: 잘못된 코드거나 이미 사용 중인 번호입니다.', color: Colors.red);
    }
    isVerifying = false; _safeNotify();
  }

  // --- 이미지 및 저장 로직 ---
  Future<void> pickImage(bool isProfile) async {
    final image = await ImageUploadService.pickImage();
    if (image != null && context.mounted) {
      if (isProfile) profileImage = File(image.path);
      else barrelImage = File(image.path);
      _safeNotify();
    }
  }

  Future<void> deleteImage(bool isProfile) async {
    final u = user; if (u == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'), content: const Text('삭제하시겠습니까?'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red)))],
      ),
    );
    if (confirmed == true && context.mounted) {
      final String? targetUrl = isProfile ? firestoreProfileUrl : firestoreBarrelUrl;
      if (isProfile) { profileImage = null; firestoreProfileUrl = null; }
      else { barrelImage = null; firestoreBarrelUrl = null; }
      if (targetUrl != null) await ImageUploadService.deleteByUrl(targetUrl);
      _safeNotify();
    }
  }

  Future<SaveResult> saveAndReturnResult(GlobalKey<FormState> formKey) async {
    if (_isSaving) return const SaveResult(success: false, message: '저장 중...');
    final u = user; if (u == null) return const SaveResult(success: false, message: '로그인 필요');
    if (!formKey.currentState!.validate()) return const SaveResult(success: false, message: '입력 확인');

    final currentFullPhone = _formatToInternational(phoneCtrl.text.trim(), selectedCountryCode);

    // 🆕 [빈틈 봉쇄 최종] 입력창 번호가 실제 인증된 번호와 다르면 저장 원천 차단
    if (currentFullPhone != originalPhone || !isPhoneVerified) {
      return const SaveResult(success: false, message: '번호 인증이 완료되지 않았습니다.');
    }

    _isSaving = true; _safeNotify();
    try {
      String? profileUrl; String? barrelUrl;
      if (profileImage != null) {
        if (firestoreProfileUrl != null) await ImageUploadService.deleteByUrl(firestoreProfileUrl!);
        profileUrl = await ImageUploadService.upload(profileImage!, 'profiles/${u.uid}');
      }
      if (barrelImage != null) {
        if (firestoreBarrelUrl != null) await ImageUploadService.deleteByUrl(firestoreBarrelUrl!);
        barrelUrl = await ImageUploadService.upload(barrelImage!, 'barrels/${u.uid}');
      }

      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'koreanName': koreanNameCtrl.text.trim(),
        'englishName': englishNameCtrl.text.trim(),
        'shopName': shopNameCtrl.text.trim(),
        'phoneNumber': currentFullPhone,
        'isPhoneVerified': true,
        'barrelName': barrelNameCtrl.text.trim(),
        'shaft': shaftCtrl.text.trim(),
        'flight': flightCtrl.text.trim(),
        'tip': tipCtrl.text.trim(),
        'profileImageUrl': profileUrl ?? firestoreProfileUrl ?? FieldValue.delete(),
        'barrelImageUrl': barrelUrl ?? firestoreBarrelUrl ?? FieldValue.delete(),
        'hasProfile': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      isEditingPhone = false;
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('setHasProfile');
        await callable.call(); await u.reload(); ref.invalidate(isAdminProvider);
      } catch (_) {}
      ref.invalidate(userHasProfileProvider);
      return SaveResult.ok;
    } catch (e) { return SaveResult(success: false, message: '오류: $e'); }
    finally { _isSaving = false; _safeNotify(); }
  }

  void _showSnackBar(String message, {Color? color}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }
  void _safeNotify() { if (context.mounted) notifyListeners(); }

  ImageProvider? getProfileImageProvider() {
    if (profileImage != null) return FileImage(profileImage!);
    if (firestoreProfileUrl?.isNotEmpty == true) return NetworkImage(firestoreProfileUrl!);
    if (isFirstRegistration && user?.photoURL != null) return NetworkImage(user!.photoURL!);
    return null;
  }
  DecorationImage? getBarrelDecorationImage() {
    if (barrelImage != null) return DecorationImage(image: FileImage(barrelImage!), fit: BoxFit.cover);
    if (firestoreBarrelUrl?.isNotEmpty == true) return DecorationImage(image: NetworkImage(firestoreBarrelUrl!), fit: BoxFit.cover);
    return null;
  }
  @override
  void dispose() {
    phoneCtrl.removeListener(_onPhoneChanged);
    koreanNameCtrl.dispose(); englishNameCtrl.dispose(); shopNameCtrl.dispose();
    phoneCtrl.dispose(); codeCtrl.dispose(); barrelNameCtrl.dispose();
    shaftCtrl.dispose(); flightCtrl.dispose(); tipCtrl.dispose();
    super.dispose();
  }
}