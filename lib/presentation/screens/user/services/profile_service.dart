// lib/user/services/profile_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'image_upload_service.dart';
import 'phone_auth_service.dart';

class ProfileService extends ChangeNotifier {
  final BuildContext context;
  final WidgetRef ref;
  final User? user = FirebaseAuth.instance.currentUser;

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

  ProfileService(this.context, this.ref) {
    _loadExistingProfile();
  }

  String _formatToInternational(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 || !digits.startsWith('0')) return '';
    return '+82${digits.substring(1)}';
  }

  Future<void> _loadExistingProfile() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final exists = doc.exists && (doc.data()?['hasProfile'] == true);

    if (!exists) {
      isFirstRegistration = true;
      _safeNotify();
      return;
    }

    final data = doc.data()!;
    final phoneRaw = data['phoneNumber']?.toString();
    String displayPhone = '';
    if (phoneRaw != null && phoneRaw.startsWith('+82')) {
      final digits = phoneRaw.substring(3);
      if (digits.length == 10) {
        displayPhone = '0${digits.substring(0,3)}-${digits.substring(3,7)}-${digits.substring(7)}';
      } else if (digits.length == 11) {
        displayPhone = '0${digits.substring(0,3)}-${digits.substring(3,7)}-${digits.substring(7)}';
      }
    }

    koreanNameCtrl.text = data['koreanName'] ?? '';
    englishNameCtrl.text = data['englishName'] ?? '';
    shopNameCtrl.text = data['shopName'] ?? '';
    phoneCtrl.text = displayPhone;
    originalPhone = displayPhone;
    isPhoneVerified = data['isPhoneVerified'] == true;

    barrelNameCtrl.text = data['barrelName'] ?? '';
    shaftCtrl.text = data['shaft'] ?? '';
    flightCtrl.text = data['flight'] ?? '';
    tipCtrl.text = data['tip'] ?? '';

    firestoreProfileUrl = data['profileImageUrl'];
    firestoreBarrelUrl = data['barrelImageUrl'];

    _safeNotify();
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

    final success = await PhoneAuthService.linkPhone(
      verificationId: verificationId!,
      smsCode: codeCtrl.text.trim(),
      currentUser: FirebaseAuth.instance.currentUser!,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('정말로 이 사진을 삭제하시겠습니까?\n삭제 후 복구할 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
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

    final path = isProfile ? 'profiles/${user!.uid}' : 'barrels/${user!.uid}';
    await ImageUploadService.delete(path);

    if (isProfile) {
      final onlineRef = FirebaseDatabase.instance.ref('online_users/${user!.uid}');
      await onlineRef.update({'photoUrl': ''});
    }

    _showSnackBar('사진이 삭제되었습니다.', color: Colors.orange);
    _safeNotify();
  }

  Future<void> save(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    final phoneInput = phoneCtrl.text.trim();
    final isFirstReg = isFirstRegistration;

    String normalize(String s) => s.replaceAll(RegExp(r'\D'), '');
    final normalizedInput = normalize(phoneInput);
    final normalizedOriginal = originalPhone != null ? normalize(originalPhone!) : '';
    final isPhoneChanged = !isFirstReg && (normalizedInput != normalizedOriginal);

    if ((isFirstReg || isPhoneChanged) && !isPhoneVerified) {
      _showSnackBar('전화번호 인증을 완료해주세요!', color: Colors.red);
      return;
    }

    if (codeSent) {
      _showSnackBar('인증번호 확인 후 저장해주세요', color: Colors.red);
      return;
    }

    if (isEditingPhone && !isPhoneVerified) {
      _showSnackBar('인증을 완료한 후 저장해주세요', color: Colors.red);
      return;
    }

    String? profileUrl;
    String? barrelUrl;

    if (profileImage != null) {
      profileUrl = await ImageUploadService.upload(profileImage!, 'profiles/${user!.uid}');
    }

    if (barrelImage != null) {
      barrelUrl = await ImageUploadService.upload(barrelImage!, 'barrels/${user!.uid}');
    }

    final internationalPhone = normalizedInput.isNotEmpty ? '+82${normalizedInput.substring(1)}' : '';

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final isCurrentlyAdmin = (userDoc.data() ?? {})['admin'] == true;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'koreanName': koreanNameCtrl.text.trim(),
      'englishName': englishNameCtrl.text.trim(),
      'shopName': shopNameCtrl.text.trim(),
      'phoneNumber': internationalPhone.isNotEmpty ? internationalPhone : FieldValue.delete(),
      'isPhoneVerified': isPhoneVerified,
      'barrelName': barrelNameCtrl.text.trim(),
      'shaft': shaftCtrl.text.trim(),
      'flight': flightCtrl.text.trim(),
      'tip': tipCtrl.text.trim(),
      'profileImageUrl': profileImage != null ? profileUrl : (firestoreProfileUrl ?? FieldValue.delete()),
      'barrelImageUrl': barrelImage != null ? barrelUrl : (firestoreBarrelUrl ?? FieldValue.delete()),
      'hasProfile': true,
      'updatedAt': FieldValue.serverTimestamp(),
      if (isCurrentlyAdmin) 'admin': true,
    }, SetOptions(merge: true));

    final onlineRef = FirebaseDatabase.instance.ref('online_users/${user!.uid}');
    await onlineRef.update({
      'name': koreanNameCtrl.text.trim(),
      'photoUrl': profileUrl ?? '',
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('setHasProfile');
      await callable.call();
      await FirebaseAuth.instance.currentUser?.reload();
      ref.invalidate(isAdminProvider);
    } catch (e) {
      if (context.mounted) _showSnackBar('권한 업데이트 실패: $e', color: Colors.red);
    }

    originalPhone = phoneInput;
    isEditingPhone = false;
    codeSent = false;

    if (context.mounted) {
      Navigator.pop(context);
      ref.invalidate(userHasProfileProvider);
      _showSnackBar('프로필이 저장되었습니다.', color: Colors.green);
    }

    // 모든 작업 끝 → 수동 dispose
    dispose();  // 여기서만 호출!
  }

  void _showSnackBar(String message, {Color? color}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _safeNotify() {
    if (context.mounted) notifyListeners();
  }

  ImageProvider? getProfileImageProvider() {
    if (profileImage != null) return FileImage(profileImage!);
    if (firestoreProfileUrl != null && firestoreProfileUrl!.isNotEmpty) return NetworkImage(firestoreProfileUrl!);
    if (isFirstRegistration && user?.photoURL != null) return NetworkImage(user!.photoURL!);
    return null;
  }

  DecorationImage? getBarrelDecorationImage() {
    if (barrelImage != null) return DecorationImage(image: FileImage(barrelImage!), fit: BoxFit.cover);
    if (firestoreBarrelUrl != null && firestoreBarrelUrl!.isNotEmpty) return DecorationImage(image: NetworkImage(firestoreBarrelUrl!), fit: BoxFit.cover);
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