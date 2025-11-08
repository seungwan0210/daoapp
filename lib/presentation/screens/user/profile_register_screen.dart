// lib/presentation/screens/user/profile_register_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class ProfileRegisterScreen extends ConsumerStatefulWidget {
  const ProfileRegisterScreen({super.key});

  @override
  ConsumerState<ProfileRegisterScreen> createState() => _ProfileRegisterScreenState();
}

class _ProfileRegisterScreenState extends ConsumerState<ProfileRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _koreanNameController = TextEditingController();
  final _englishNameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  final _barrelNameController = TextEditingController();
  final _shaftController = TextEditingController();
  final _flightController = TextEditingController();
  final _tipController = TextEditingController();

  String? _originalPhone;
  bool _isFirstRegistration = false;
  bool _isPhoneVerified = false;

  bool _isEditingPhone = false;
  bool _codeSent = false;
  bool _isVerifying = false;
  String? _verificationId;

  File? _profileImage;
  File? _barrelImage;
  final ImagePicker _picker = ImagePicker();

  String? _firestoreProfileUrl;
  String? _firestoreBarrelUrl;

  late final User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final exists = doc.exists && (doc.data()?['hasProfile'] == true);

    if (!exists) {
      setState(() => _isFirstRegistration = true);
      return;
    }

    final data = doc.data()!;
    final phoneRaw = data['phoneNumber']?.toString();

    String displayPhone = '';
    if (phoneRaw != null && phoneRaw.startsWith('+82')) {
      final digits = phoneRaw.substring(3);
      if (digits.length == 10) displayPhone = '0$digits';
    }

    setState(() {
      _koreanNameController.text = data['koreanName'] ?? '';
      _englishNameController.text = data['englishName'] ?? '';
      _shopNameController.text = data['shopName'] ?? '';
      _phoneController.text = displayPhone;
      _originalPhone = displayPhone;
      _isPhoneVerified = data['isPhoneVerified'] == true;

      _barrelNameController.text = data['barrelName'] ?? '';
      _shaftController.text = data['shaft'] ?? '';
      _flightController.text = data['flight'] ?? '';
      _tipController.text = data['tip'] ?? '';

      _firestoreProfileUrl = data['profileImageUrl'];
      _firestoreBarrelUrl = data['barrelImageUrl'];
    });
  }

  @override
  void dispose() {
    _koreanNameController.dispose();
    _englishNameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _barrelNameController.dispose();
    _shaftController.dispose();
    _flightController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    final input = _phoneController.text.trim();
    final digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 11 || !digits.startsWith('0')) {
      _showSnackBar('010으로 시작하는 11자리 번호를 입력하세요');
      return;
    }

    final phone = '+82${digits.substring(1)}';

    setState(() {
      _isVerifying = true;
      _verificationId = null;
      _codeController.clear();
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          _showSnackBar(e.message ?? '인증 실패');
          setState(() => _isVerifying = false);
        },
        codeSent: (verificationId, _) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isVerifying = false;
          });
          _showSnackBar('인증번호가 전송되었습니다');
        },
        codeAutoRetrievalTimeout: (_) {
          setState(() {
            _verificationId = null;
            _codeSent = false;
            _isVerifying = false;
          });
          _showSnackBar('인증번호가 만료되었습니다. 다시 요청하세요', color: Colors.orange);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _showSnackBar('요청 실패');
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6 || !_codeController.text.trim().contains(RegExp(r'^\d{6}$'))) {
      _showSnackBar('6자리 숫자 인증번호를 입력하세요');
      return;
    }

    if (_verificationId == null) {
      _showSnackBar('인증번호를 다시 요청하세요');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Google 계정에 Phone 번호 연동
        await currentUser.linkWithCredential(credential);
        _showSnackBar('휴대폰 번호가 연동되었습니다!', color: Colors.green);
      } else {
        // 비정상: currentUser 없음 → 새로 로그인
        await FirebaseAuth.instance.signInWithCredential(credential);
        _showSnackBar('로그인되었습니다', color: Colors.green);
      }

      setState(() {
        _isPhoneVerified = true;
        _isEditingPhone = false;
        _codeSent = false;
        _originalPhone = _phoneController.text;
      });
      _codeController.clear();

    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'credential-already-in-use') {
        msg = '이 번호는 이미 다른 계정에 연동되어 있습니다';
      } else if (e.code == 'invalid-verification-code') {
        msg = '인증번호가 틀렸습니다';
      } else {
        msg = '인증 실패: ${e.message}';
      }
      _showSnackBar(msg);
    } catch (e) {
      _showSnackBar('인증 실패');
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(image.path);
        } else {
          _barrelImage = File(image.path);
        }
      });
    }
  }

  Future<void> _deleteImage(bool isProfile) async {
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

    if (confirmed != true) return;

    setState(() {
      if (isProfile) {
        _profileImage = null;
        _firestoreProfileUrl = null;
      } else {
        _barrelImage = null;
        _firestoreBarrelUrl = null;
      }
    });

    try {
      final ref = FirebaseStorage.instance.ref().child(isProfile ? 'profiles/${user!.uid}' : 'barrels/${user!.uid}');
      await ref.delete();
    } catch (e) {
      debugPrint('Storage 삭제 실패: $e');
    }

    _showSnackBar('사진이 삭제되었습니다.', color: Colors.orange);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneInput = _phoneController.text.trim();
    final needsVerification = _isFirstRegistration || (phoneInput != _originalPhone);

    if (needsVerification && !_isPhoneVerified) {
      _showSnackBar('전화번호 인증을 완료해주세요!', color: Colors.red);
      return;
    }

    if (_codeSent || _isEditingPhone) {
      _showSnackBar('인증을 완료한 후 저장해주세요', color: Colors.red);
      return;
    }

    String? profileUrl;
    String? barrelUrl;

    if (_profileImage != null) {
      final ref = FirebaseStorage.instance.ref().child('profiles/${user!.uid}');
      await ref.putFile(_profileImage!);
      profileUrl = await ref.getDownloadURL();
    }

    if (_barrelImage != null) {
      final ref = FirebaseStorage.instance.ref().child('barrels/${user!.uid}');
      await ref.putFile(_barrelImage!);
      barrelUrl = await ref.getDownloadURL();
    }

    final cleanNumber = phoneInput.replaceAll(RegExp(r'\D'), '').substring(1);

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'koreanName': _koreanNameController.text.trim(),
      'englishName': _englishNameController.text.trim(),
      'shopName': _shopNameController.text.trim(),
      'phoneNumber': phoneInput.isNotEmpty ? '+82$cleanNumber' : FieldValue.delete(),
      'isPhoneVerified': _isPhoneVerified,
      'barrelName': _barrelNameController.text.trim(),
      'shaft': _shaftController.text.trim(),
      'flight': _flightController.text.trim(),
      'tip': _tipController.text.trim(),
      'profileImageUrl': _profileImage != null ? profileUrl : (_firestoreProfileUrl == null ? null : _firestoreProfileUrl),
      'barrelImageUrl': _barrelImage != null ? barrelUrl : (_firestoreBarrelUrl == null ? null : _firestoreBarrelUrl),
      'hasProfile': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.pop(context);
      ref.invalidate(userHasProfileProvider);
      _showSnackBar('프로필이 저장되었습니다.', color: Colors.green);
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  ImageProvider? _getProfileImageProvider() {
    if (_profileImage != null) return FileImage(_profileImage!);
    if (_firestoreProfileUrl != null && _firestoreProfileUrl!.isNotEmpty) return NetworkImage(_firestoreProfileUrl!);
    if (_isFirstRegistration && user?.photoURL != null) return NetworkImage(user!.photoURL!);
    return null;
  }

  DecorationImage? _getBarrelDecorationImage() {
    if (_barrelImage != null) return DecorationImage(image: FileImage(_barrelImage!), fit: BoxFit.cover);
    if (_firestoreBarrelUrl != null && _firestoreBarrelUrl!.isNotEmpty) return DecorationImage(image: NetworkImage(_firestoreBarrelUrl!), fit: BoxFit.cover);
    return null;
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed, {double size = 32}) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: onPressed,
        child: Icon(icon, size: size * 0.5, color: Colors.white),
      ),
    );
  }

  Widget _buildDeleteButton(VoidCallback onPressed) {
    return SizedBox(
      width: 28,
      height: 28,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.red,
        onPressed: onPressed,
        child: const Icon(Icons.close, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileImageStack() {
    final hasImage = _profileImage != null || _firestoreProfileUrl != null || (_isFirstRegistration && user?.photoURL != null);
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          backgroundImage: hasImage ? _getProfileImageProvider() : null,
          child: !hasImage ? const Icon(Icons.account_circle, size: 50, color: Colors.grey) : null,
        ),
        Positioned(bottom: 0, right: 0, child: _buildIconButton(Icons.camera_alt, () => _pickImage(true))),
        if (_profileImage != null || _firestoreProfileUrl != null)
          Positioned(top: 0, right: 0, child: _buildDeleteButton(() => _deleteImage(true))),
      ],
    );
  }

  Widget _buildBarrelImageStack() {
    final hasImage = _barrelImage != null || _firestoreBarrelUrl != null;
    return Stack(
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8), image: hasImage ? _getBarrelDecorationImage() : null),
          child: !hasImage ? const Icon(Icons.sports_esports, size: 40, color: Colors.grey) : null,
        ),
        Positioned(bottom: 0, right: 0, child: _buildIconButton(Icons.camera_alt, () => _pickImage(false), size: 28)),
        if (_barrelImage != null || _firestoreBarrelUrl != null)
          Positioned(top: 0, right: 0, child: _buildDeleteButton(() => _deleteImage(false))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '프로필 등록/수정', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(child: _buildProfileImageStack()),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    TextFormField(controller: _koreanNameController, decoration: const InputDecoration(labelText: '한국 이름', prefixIcon: Icon(Icons.person)), validator: (v) => v!.trim().isEmpty ? '한국 이름을 입력하세요' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _englishNameController, decoration: const InputDecoration(labelText: '영어 이름', prefixIcon: Icon(Icons.translate)), validator: (v) => v!.trim().isEmpty ? '영어 이름을 입력하세요' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _shopNameController, decoration: const InputDecoration(labelText: '샵 이름', prefixIcon: Icon(Icons.store)), validator: (v) => v!.trim().isEmpty ? '샵 이름을 입력하세요' : null),
                    const SizedBox(height: 12),

                    // 전화번호 인증 UI (신규 유저 인증 버튼 포함)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_isEditingPhone && _isPhoneVerified && !_isFirstRegistration)
                                  Text('+82 ${_phoneController.text}', style: const TextStyle(fontSize: 16)),

                                if (_isFirstRegistration || _isEditingPhone || !_isPhoneVerified)
                                  TextFormField(
                                    controller: _phoneController,
                                    enabled: _isFirstRegistration || _isEditingPhone || !_isPhoneVerified,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(hintText: '01012345678', border: const UnderlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8)),
                                    validator: (v) {
                                      if (_isFirstRegistration && (v?.trim().isEmpty ?? true)) return '전화번호는 필수입니다';
                                      return null;
                                    },
                                  ),

                                if (_codeSent && (_isEditingPhone || _isFirstRegistration))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _codeController,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(hintText: '인증번호 6자리', border: UnderlineInputBorder(), isDense: true),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _isVerifying
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                            : IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _verifyCode),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isPhoneVerified && !_isEditingPhone && !_isFirstRegistration)
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),

                              if (_isPhoneVerified && !_isEditingPhone && !_isFirstRegistration)
                                TextButton(
                                  onPressed: () => setState(() => _isEditingPhone = true),
                                  child: const Text('변경', style: TextStyle(fontSize: 12)),
                                ),

                              if ((_isFirstRegistration || _isEditingPhone) && !_codeSent && !_isPhoneVerified)
                                IconButton(
                                  icon: const Icon(Icons.send, color: Colors.blue),
                                  onPressed: _isVerifying ? null : _sendVerificationCode,
                                ),

                              if (_isEditingPhone && !_isFirstRegistration)
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _isEditingPhone = false;
                                      _codeSent = false;
                                      _codeController.clear();
                                      _phoneController.text = _originalPhone ?? '';
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    ExpansionTile(
                      leading: const Icon(Icons.sports_esports),
                      title: const Text('배럴 세팅 (선택)'),
                      children: [
                        TextFormField(controller: _barrelNameController, decoration: const InputDecoration(labelText: '배럴 이름', prefixIcon: Icon(Icons.sports_esports), border: OutlineInputBorder())),
                        const SizedBox(height: 12),
                        TextFormField(controller: _shaftController, decoration: const InputDecoration(labelText: '샤프트', prefixIcon: Icon(Icons.straighten), border: OutlineInputBorder())),
                        const SizedBox(height: 12),
                        TextFormField(controller: _flightController, decoration: const InputDecoration(labelText: '플라이트', prefixIcon: Icon(Icons.flight), border: OutlineInputBorder())),
                        const SizedBox(height: 12),
                        TextFormField(controller: _tipController, decoration: const InputDecoration(labelText: '팁', prefixIcon: Icon(Icons.push_pin), border: OutlineInputBorder())),
                        const SizedBox(height: 16),
                        Center(child: _buildBarrelImageStack()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('완료'))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}