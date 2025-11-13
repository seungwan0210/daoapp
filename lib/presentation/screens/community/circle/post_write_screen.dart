// lib/presentation/screens/community/circle/post_write_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:daoapp/data/models/user_model.dart';

class PostWriteScreen extends ConsumerStatefulWidget {
  PostWriteScreen({super.key}); // const 제거!

  @override
  ConsumerState<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends ConsumerState<PostWriteScreen> {
  final _contentController = TextEditingController();
  File? _image;
  bool _isUploading = false;
  final _picker = ImagePicker();

  String? _postId;
  String? _existingPhotoUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['postId'] != null && _postId == null) {
      _postId = args['postId'] as String;
      _loadExistingPost(_postId!);
    }
  }

  Future<void> _loadExistingPost(String postId) async {
    final doc = await FirebaseFirestore.instance.collection('community').doc(postId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    _contentController.text = data['content'] ?? '';
    _existingPhotoUrl = data['photoUrl'] as String?;

    if (mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _upload() async {
    if (_contentController.text.trim().isEmpty && _image == null && _existingPhotoUrl == null) {
      _showSnackBar('내용 또는 사진을 추가해주세요');
      return;
    }

    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final appUser = AppUser.fromMap(user.uid, userDoc.data()!);

      String? photoUrl = _existingPhotoUrl;
      if (_image != null) {
        if (_existingPhotoUrl != null) {
          try {
            await FirebaseStorage.instance.refFromURL(_existingPhotoUrl!).delete();
          } catch (e) {
            debugPrint('기존 이미지 삭제 실패: $e');
          }
        }

        final ref = FirebaseStorage.instance
            .ref()
            .child('community_posts')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = await ref.putFile(_image!);
        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      final data = {
        'userId': user.uid,
        'displayName': appUser.koreanName ?? 'Unknown',
        'userPhotoUrl': appUser.profileImageUrl,
        'photoUrl': photoUrl,
        'content': _contentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_postId == null) {
        await FirebaseFirestore.instance.collection('community').add({
          ...data,
          'likes': 0,
          'comments': 0,
        });
      } else {
        await FirebaseFirestore.instance.collection('community').doc(_postId).update(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showSnackBar('업로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool get _canPost => _contentController.text.trim().isNotEmpty || _image != null || _existingPhotoUrl != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);  // 이 줄 추가! (오류 해결)
    final isEdit = _postId != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? "게시물 수정" : "게시물 작성", style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          AnimatedOpacity(
            opacity: _canPost ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: _canPost && !_isUploading ? _upload : null,
              child: _isUploading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : Text(
                isEdit ? "수정" : "게시",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(theme),
              const SizedBox(height: 24),
              TextField(
                controller: _contentController,
                maxLines: null,
                style: const TextStyle(fontSize: 16, height: 1.5),
                decoration: InputDecoration(
                  hintText: "무슨 생각을 하고 계신가요?",
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                  border: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    if (_image != null || _existingPhotoUrl != null) {
      return _buildImagePreview(theme);
    } else {
      return _buildImagePlaceholder(theme);
    }
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_a_photo_outlined,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "사진 추가하기",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Text("터치해서 사진을 선택하세요", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    final imageProvider = _image != null
        ? FileImage(_image!) as ImageProvider
        : NetworkImage(_existingPhotoUrl!);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image(
            image: imageProvider,
            height: 340,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 340,
              color: Colors.grey[200],
              child: const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
        // 삭제 버튼
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => setState(() {
              _image = null;
              _existingPhotoUrl = null;
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
        // 변경 버튼 (theme 사용!)
        Positioned(
          bottom: 12,
          right: 12,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    "변경",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}