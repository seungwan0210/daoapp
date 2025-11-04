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

  String? _verificationId;
  bool _codeSent = false;
  bool _isPhoneVerified = false;
  String? _originalPhone;
  bool _isFirstRegistration = false;

  File? _profileImage;
  File? _barrelImage;
  final ImagePicker _picker = ImagePicker();

  String? _firestoreProfileUrl;
  String? _firestoreBarrelUrl;

  String? _selectedBarrel;
  String? _selectedShaft;
  String? _selectedFlight;
  String? _selectedTip;

  final List<String> _barrels = ['Monster', 'Target', 'L-Style', 'Harrows'];
  final List<String> _shafts = ['Nylon', 'Carbon', 'Titanium'];
  final List<String> _flights = ['Standard', 'Slim', 'Kite'];
  final List<String> _tips = ['Soft', 'Hard'];

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
    final phoneRaw = data['phoneNumber']?.toString().replaceAll(RegExp(r'\+82'), '0') ?? '';

    setState(() {
      _koreanNameController.text = data['koreanName'] ?? '';
      _englishNameController.text = data['englishName'] ?? '';
      _shopNameController.text = data['shopName'] ?? '';
      _phoneController.text = phoneRaw;
      _originalPhone = phoneRaw;
      _isPhoneVerified = data['isPhoneVerified'] == true;

      _selectedBarrel = data['barrelName'];
      _selectedShaft = data['shaft'];
      _selectedFlight = data['flight'];
      _selectedTip = data['tip'];

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
    super.dispose();
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
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

  Future<void> _sendCode() async {
    final phoneInput = _phoneController.text.trim();
    if (phoneInput.isEmpty) {
      _showSnackBar('전화번호를 입력하세요.');
      return;
    }

    final needsVerification = _isFirstRegistration || (phoneInput != _originalPhone);
    if (!needsVerification) return;

    final phone = '+82$phoneInput';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (_) {
          // 자동 로그인 방지
          debugPrint('자동 로그인 무시');
        },
        verificationFailed: (e) {
          String msg;
          switch (e.code) {
            case 'invalid-phone-number':
              msg = '유효하지 않은 전화번호입니다.';
              break;
            case 'too-many-requests':
              msg = '너무 많은 요청. 잠시 후 다시 시도하세요.';
              break;
            default:
              msg = e.message ?? '인증 실패';
          }
          _showSnackBar(msg);
        },
        codeSent: (verificationId, _) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
          });
          _showSnackBar('인증번호 전송됨');
        },
        codeAutoRetrievalTimeout: (_) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _showSnackBar('인증 요청 실패');
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null || _codeController.text.trim().isEmpty) {
      _showSnackBar('인증번호를 입력하세요.');
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      await _linkAndSave(credential);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'invalid-verification-code':
          msg = '잘못된 인증번호입니다.';
          break;
        case 'session-expired':
          msg = '인증 시간이 만료되었습니다.';
          break;
        default:
          msg = e.message ?? '인증 실패';
      }
      _showSnackBar(msg);
    }
  }

  Future<void> _linkAndSave(PhoneAuthCredential? credential) async {
    if (user == null) return;

    try {
      final phoneInput = _phoneController.text.trim();
      final needsVerification = _isFirstRegistration || (phoneInput != _originalPhone);

      if (needsVerification && credential == null) {
        _showSnackBar('전화번호 인증이 필요합니다.');
        return;
      }

      if (credential != null && needsVerification) {
        try {
          await user!.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code != 'credential-already-in-use') rethrow;
          debugPrint('이미 연결된 번호');
        }
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

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'koreanName': _koreanNameController.text.trim(),
        'englishName': _englishNameController.text.trim(),
        'shopName': _shopNameController.text.trim(),
        'phoneNumber': phoneInput.isNotEmpty ? '+82$phoneInput' : FieldValue.delete(),
        'isPhoneVerified': true,
        'barrelName': _selectedBarrel,
        'shaft': _selectedShaft,
        'flight': _selectedFlight,
        'tip': _selectedTip,
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
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.code == 'credential-already-in-use' ? '이미 사용 중인 전화번호입니다.' : (e.message ?? '저장 실패'));
    } catch (e) {
      _showSnackBar('오류가 발생했습니다.');
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
          child: !hasImage
              ? const Icon(Icons.account_circle, size: 50, color: Colors.grey)
              : null,
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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            image: hasImage ? _getBarrelDecorationImage() : null,
          ),
          child: !hasImage
              ? const Icon(Icons.sports_esports, size: 40, color: Colors.grey)
              : null,
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
      appBar: AppBar(
        title: Text(_isFirstRegistration ? '프로필 등록 (필수)' : '프로필 수정'),
        centerTitle: true,
      ),
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
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: _isFirstRegistration ? '전화번호 (필수)' : '전화번호 변경 (선택)',
                        prefixText: '+82 ',
                        prefixIcon: const Icon(Icons.phone),
                        suffixIcon: _codeSent ? null : (_phoneController.text.trim() == _originalPhone && !_isFirstRegistration ? const Icon(Icons.check, color: Colors.green) : IconButton(icon: const Icon(Icons.send), onPressed: _sendCode)),
                      ),
                      validator: (v) => _isFirstRegistration && v!.trim().isEmpty ? '최초 등록 시 전화번호는 필수입니다' : null,
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '인증번호 6자리',
                          prefixIcon: const Icon(Icons.sms),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.check), onPressed: _verifyCode),
                              TextButton(onPressed: _sendCode, child: const Text('재전송', style: TextStyle(fontSize: 12))),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ExpansionTile(
                      leading: const Icon(Icons.sports_esports),
                      title: const Text('배럴 세팅 (선택)'),
                      children: [
                        DropdownButtonFormField<String>(value: _selectedBarrel, hint: const Text('배럴 이름'), items: _barrels.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(), onChanged: (v) => setState(() => _selectedBarrel = v)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(value: _selectedShaft, hint: const Text('샤프트'), items: _shafts.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _selectedShaft = v)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(value: _selectedFlight, hint: const Text('플라이트'), items: _flights.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(), onChanged: (v) => setState(() => _selectedFlight = v)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(value: _selectedTip, hint: const Text('팁'), items: _tips.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _selectedTip = v)),
                        const SizedBox(height: 16),
                        Center(child: _buildBarrelImageStack()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          final phoneInput = _phoneController.text.trim();
                          final needsVerification = _isFirstRegistration || (phoneInput != _originalPhone);
                          if (needsVerification && !_codeSent) {
                            _showSnackBar('전화번호 인증이 필요합니다.');
                            return;
                          }
                          await _linkAndSave(null);
                        },
                        child: const Text('완료'),
                      ),
                    ),
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