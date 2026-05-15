import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:daoapp/presentation/providers/app_providers.dart';
import 'image_upload_service.dart';
import 'package:daoapp/l10n/app_localizations.dart';

/// ✅ 저장 결과를 UI로 알려주기 위한 모델
class SaveResult {
  final bool success;
  final String message;

  const SaveResult({required this.success, required this.message});

  static const ok = SaveResult(success: true, message: 'Success');
}

class ProfileService extends ChangeNotifier {
  final BuildContext context;
  final WidgetRef ref;

  User? get user => FirebaseAuth.instance.currentUser;

  final koreanNameCtrl = TextEditingController();
  final englishNameCtrl = TextEditingController();
  final shopNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final barrelNameCtrl = TextEditingController();
  final shaftCtrl = TextEditingController();
  final flightCtrl = TextEditingController();
  final tipCtrl = TextEditingController();

  // --- 상태 관리 변수 ---
  bool isFirstRegistration = false;
  bool isPhoneVerified = true;

  File? profileImage;
  File? barrelImage;
  String? firestoreProfileUrl;
  String? firestoreBarrelUrl;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  ProfileService(this.context, this.ref) {
    _loadExistingProfile();
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

      koreanNameCtrl.text = (data['koreanName'] ?? '').toString();
      englishNameCtrl.text = (data['englishName'] ?? '').toString();
      shopNameCtrl.text = (data['shopName'] ?? '').toString();
      phoneCtrl.text = (data['phoneNumber'] ?? '').toString();
      barrelNameCtrl.text = (data['barrelName'] ?? '').toString();
      shaftCtrl.text = (data['shaft'] ?? '').toString();
      flightCtrl.text = (data['flight'] ?? '').toString();
      tipCtrl.text = (data['tip'] ?? '').toString();
      firestoreProfileUrl = data['profileImageUrl']?.toString();
      firestoreBarrelUrl = data['barrelImageUrl']?.toString();

      _safeNotify();
    } catch (e) {
      _safeNotify();
    }
  }

  // 🖼️ 이미지 처리 로직
  Future<void> pickImage(bool isProfile) async {
    final s = AppLocalizations.of(context)!;
    final u = user;
    if (u == null) return;

    final image = await ImageUploadService.pickImage();
    if (image == null || !context.mounted) return;

    _isSaving = true;
    _safeNotify();

    try {
      final file = File(image.path);
      final String folder = isProfile ? 'profiles' : 'barrels';
      final String fileName = isProfile ? 'profile_img.jpg' : 'barrel_img.jpg';
      final String storagePath = '$folder/${u.uid}/$fileName';

      final String? uploadedUrl = await ImageUploadService.upload(file, storagePath);

      if (uploadedUrl == null) throw Exception('Upload failed');

      final String? oldUrl = isProfile ? firestoreProfileUrl : firestoreBarrelUrl;
      if (oldUrl != null && oldUrl != uploadedUrl) {
        try {
          await ImageUploadService.deleteByUrl(oldUrl);
        } catch (e) {
          debugPrint('Old file delete skip: $e');
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(u.uid).update({
        isProfile ? 'profileImageUrl' : 'barrelImageUrl': uploadedUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (isProfile) {
        firestoreProfileUrl = uploadedUrl;
      } else {
        firestoreBarrelUrl = uploadedUrl;
      }

      _showSnackBar(isProfile ? s.profile_image_save : s.barrel_image_save, color: Colors.green);
    } catch (e) {
      _showSnackBar(s.profile_image_fail(e.toString()), color: Colors.red);
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  Future<void> deleteImage(bool isProfile) async {
    final s = AppLocalizations.of(context)!;
    final u = user;
    if (u == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.profile_image_delete_title),
        content: Text(s.profile_image_delete_body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.common_delete, style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _isSaving = true;
    _safeNotify();

    try {
      final String? targetUrl = isProfile ? firestoreProfileUrl : firestoreBarrelUrl;
      if (targetUrl != null) {
        await ImageUploadService.deleteByUrl(targetUrl);
        await FirebaseFirestore.instance.collection('users').doc(u.uid).update({
          isProfile ? 'profileImageUrl' : 'barrelImageUrl': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (isProfile) {
        firestoreProfileUrl = null;
      } else {
        firestoreBarrelUrl = null;
      }

      _showSnackBar(s.profile_image_deleted, color: Colors.orange);
    } catch (e) {
      _showSnackBar(s.profile_image_fail(e.toString()), color: Colors.red);
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  // 💾 최종 저장 및 닉네임 중복 체크
  Future<SaveResult> saveAndReturnResult(GlobalKey<FormState> formKey) async {
    final s = AppLocalizations.of(context)!;

    if (_isSaving) return SaveResult(success: false, message: s.common_msg_processing);
    final u = user;
    if (u == null) return const SaveResult(success: false, message: 'Auth Error');
    if (!formKey.currentState!.validate()) return SaveResult(success: false, message: s.profile_reg_input_check);

    _isSaving = true;
    _safeNotify();

    try {
      final newName = koreanNameCtrl.text.trim();

      // 🆕 [중복 체크] Firestore 쿼리 실행
      // koreanName 필드가 입력한 이름과 같은 문서를 검색
      final nicknameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('koreanName', isEqualTo: newName)
          .get();

      // 💡 결과가 존재하는데, 그 문서의 ID(u.uid)가 현재 로그인한 유저의 ID와 다르다면 다른 사람이 쓰는 중임
      if (nicknameQuery.docs.isNotEmpty && nicknameQuery.docs.first.id != u.uid) {
        return SaveResult(success: false, message: s.profile_reg_fail_duplicate_name);
      }

      // 데이터 저장 (merge: true를 사용하여 기존 프로필 이미지/배지 등의 데이터 보존)
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'koreanName': newName,
        'englishName': englishNameCtrl.text.trim(),
        'shopName': shopNameCtrl.text.trim(),
        'phoneNumber': phoneCtrl.text.trim(),
        'isPhoneVerified': true,
        'barrelName': barrelNameCtrl.text.trim(),
        'shaft': shaftCtrl.text.trim(),
        'flight': flightCtrl.text.trim(),
        'tip': tipCtrl.text.trim(),
        'profileImageUrl': firestoreProfileUrl ?? FieldValue.delete(),
        'barrelImageUrl': firestoreBarrelUrl ?? FieldValue.delete(),
        'hasProfile': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Firebase Auth Custom Claim 또는 Profile 관련 후처리를 위한 Function 호출
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('setHasProfile');
        await callable.call();
        await u.reload();
        ref.invalidate(isAdminProvider);
      } catch (_) {
        // Functions 에러는 저장 성공 여부에 치명적이지 않으므로 skip
      }

      ref.invalidate(userHasProfileProvider);
      return SaveResult(success: true, message: s.profile_reg_success);
    } catch (e) {
      return SaveResult(success: false, message: e.toString());
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating)
    );
  }

  void _safeNotify() { if (context.mounted) notifyListeners(); }

  ImageProvider? getProfileImageProvider() {
    if (firestoreProfileUrl != null && firestoreProfileUrl!.isNotEmpty) return NetworkImage(firestoreProfileUrl!);
    if (isFirstRegistration && user?.photoURL != null) return NetworkImage(user!.photoURL!);
    return null;
  }

  DecorationImage? getBarrelDecorationImage() {
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
    barrelNameCtrl.dispose();
    shaftCtrl.dispose();
    flightCtrl.dispose();
    tipCtrl.dispose();
    super.dispose();
  }
}