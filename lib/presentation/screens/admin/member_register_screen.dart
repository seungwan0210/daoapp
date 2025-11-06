// lib/presentation/screens/admin/member_register_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class MemberRegisterScreen extends StatefulWidget {
  const MemberRegisterScreen({super.key});

  @override
  State<MemberRegisterScreen> createState() => _MemberRegisterScreenState();
}

class _MemberRegisterScreenState extends State<MemberRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _koreanNameController = TextEditingController();
  final _englishNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();

  File? _image;
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedGender; // 성별 추가!

  final picker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _koreanNameController.dispose();
    _englishNameController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final sizeInMB = file.lengthSync() / (1024 * 1024);
    if (sizeInMB > 3) {
      _showSnackBar('이미지는 3MB 이하만 가능합니다.', Colors.red);
      return;
    }
    setState(() => _image = file);
  }

  Future<String?> _uploadImage(String docId) async {
    if (_image == null) return null;
    final ref = _storage.ref().child('official_members').child('$docId.jpg');
    await ref.putFile(_image!);
    return await ref.getDownloadURL();
  }

  Future<void> _registerMember() async {
    if (!_formKey.currentState!.validate() || _selectedGender == null) {
      _showSnackBar('모든 필드를 입력하세요', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final docRef = _firestore.collection('official_members').doc();
      final imageUrl = await _uploadImage(docRef.id);

      await docRef.set({
        'koreanName': _koreanNameController.text.trim(),
        'englishName': _englishNameController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _selectedGender,
        'profileImageUrl': imageUrl,
        'totalPoints': 0,
        'registeredAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar('KDF 정회원 등록 완료!', Colors.green);
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('등록 실패: $e', Colors.red);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _koreanNameController.clear();
    _englishNameController.clear();
    _emailController.clear();
    setState(() {
      _image = null;
      _selectedGender = null;
    });
  }

  Future<void> _editMember(String docId, Map<String, dynamic> data) async {
    final koreanNameCtrl = TextEditingController(text: data['koreanName']);
    final englishNameCtrl = TextEditingController(text: data['englishName']);
    final emailCtrl = TextEditingController(text: data['email']);
    String? selectedGender = data['gender'];
    File? tempImage;
    String? currentImageUrl = data['profileImageUrl'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('정회원 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    final file = File(picked.path);
                    if (file.lengthSync() / (1024 * 1024) <= 3) {
                      setState(() => tempImage = file);
                    } else {
                      _showSnackBar('3MB 이하만 가능', Colors.red);
                    }
                  }
                },
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: tempImage != null
                      ? ClipOval(child: Image.file(tempImage!, fit: BoxFit.cover))
                      : currentImageUrl != null
                      ? ClipOval(child: Image.network(currentImageUrl, fit: BoxFit.cover))
                      : const Icon(Icons.person, size: 60),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    final file = File(picked.path);
                    if (file.lengthSync() / (1024 * 1024) <= 3) {
                      setState(() => tempImage = file);
                    } else {
                      _showSnackBar('3MB 이하만 가능', Colors.red);
                    }
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text('사진 변경'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: koreanNameCtrl,
                decoration: const InputDecoration(labelText: '한국 이름', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: englishNameCtrl,
                decoration: const InputDecoration(labelText: '영어 이름', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: '이메일', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(
                  labelText: '성별',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('남자')),
                  DropdownMenuItem(value: 'female', child: Text('여자')),
                ],
                onChanged: (v) => selectedGender = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        String? newImageUrl = currentImageUrl;
        if (tempImage != null) {
          final ref = _storage.ref().child('official_members').child('$docId.jpg');
          await ref.putFile(tempImage!);
          newImageUrl = await ref.getDownloadURL();

          if (currentImageUrl != null) {
            try {
              await _storage.refFromURL(currentImageUrl).delete();
            } catch (_) {}
          }
        }

        await _firestore.collection('official_members').doc(docId).update({
          'koreanName': koreanNameCtrl.text.trim(),
          'englishName': englishNameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'gender': selectedGender,
          'profileImageUrl': newImageUrl,
        });

        if (mounted) {
          _showSnackBar('수정 완료!', Colors.green);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('수정 실패: $e', Colors.red);
        }
      }
    }
  }

  Future<void> _deleteMember(String docId, String? imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        content: const Text('사진도 함께 삭제됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('official_members').doc(docId).delete();
        if (imageUrl != null) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (_) {}
        }
        if (mounted) {
          _showSnackBar('삭제 완료!', Colors.red);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('삭제 실패: $e', Colors.red);
        }
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KDF 정회원 관리'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildRegisterForm(theme),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '이름 또는 이메일로 검색',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildMemberList(theme)),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(ThemeData theme) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: _image != null
                          ? ClipOval(child: Image.file(_image!, fit: BoxFit.cover))
                          : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _koreanNameController,
                    decoration: const InputDecoration(
                      labelText: '한국 이름 (필수)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.trim().isEmpty ? '한국 이름을 입력하세요' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _englishNameController,
                    decoration: const InputDecoration(
                      labelText: '영어 이름 (필수)',
                      prefixIcon: Icon(Icons.translate),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.trim().isEmpty ? '영어 이름을 입력하세요' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: '성별 (필수)',
                      prefixIcon: Icon(Icons.wc),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('남자')),
                      DropdownMenuItem(value: 'female', child: Text('여자')),
                    ],
                    onChanged: (v) => setState(() => _selectedGender = v),
                    validator: (v) => v == null ? '성별을 선택하세요' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _registerMember,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.how_to_reg),
                      label: Text(_isLoading ? '등록 중...' : '정회원 등록'),
                      style: theme.elevatedButtonTheme.style,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('official_members')
          .orderBy('registeredAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('등록된 정회원이 없습니다.'));
        }

        var docs = snapshot.data!.docs;
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final koreanName = (data['koreanName'] as String?)?.toLowerCase() ?? '';
            final englishName = (data['englishName'] as String?)?.toLowerCase() ?? '';
            final email = (data['email'] as String?)?.toLowerCase() ?? '';
            return koreanName.contains(_searchQuery) ||
                englishName.contains(_searchQuery) ||
                email.contains(_searchQuery);
          }).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;
            final imageUrl = data['profileImageUrl'] as String?;

            return AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl == null || imageUrl.isEmpty
                      ? Text(
                    data['koreanName']?[0] ?? '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        data['koreanName'] ?? '이름 없음',
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${data['gender'] == 'male' ? '남' : '여'})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: data['gender'] == 'male' ? Colors.blue[700] : Colors.pink[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '(${data['englishName']})',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      data['email'] ?? '이메일 없음',
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => _editMember(docId, data),
                      tooltip: '수정',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _deleteMember(docId, imageUrl),
                      tooltip: '삭제',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}