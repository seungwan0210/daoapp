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
  const PostWriteScreen({super.key});

  @override
  ConsumerState<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends ConsumerState<PostWriteScreen> {
  final _contentController = TextEditingController();
  File? _image;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _upload() async {
    if (_contentController.text.trim().isEmpty && _image == null) return;

    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final appUser = AppUser.fromMap(user.uid, userDoc.data()!);

      String? photoUrl;
      if (_image != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('community_posts')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_image!);
        photoUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('community').add({
        'userId': user.uid,
        'displayName': appUser.koreanName ?? 'Unknown',
        'userPhotoUrl': appUser.profileImageUrl,
        'photoUrl': photoUrl,
        'content': _contentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          tooltip: '취소',
        ),
        title: const Text("게시물 작성", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _upload,
            child: _isUploading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(
              "게시",
              style: TextStyle(
                color: _canPost ? theme.colorScheme.primary : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 1. 사진 추가 (먼저!) ===
            Center(
              child: _image == null
                  ? _buildImagePlaceholder(theme)
                  : _buildImagePreview(),
            ),

            const SizedBox(height: 24),

            // === 2. 글쓰기 ===
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "무슨 생각을 하고 계신가요?",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canPost => _contentController.text.trim().isNotEmpty || _image != null;

  // 사진 추가 플레이스홀더
  Widget _buildImagePlaceholder(ThemeData theme) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text(
              "사진 추가",
              style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // 선택된 이미지 미리보기
  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _image!,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => setState(() => _image = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}