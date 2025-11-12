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
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _upload() async {
    if (_contentController.text.trim().isEmpty && _image == null && _existingPhotoUrl == null) {
      _showSnackBar('내용 또는 사진을 입력하세요');
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
        await ref.putFile(_image!);
        photoUrl = await ref.getDownloadURL();
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
      if (mounted) {
        _showSnackBar('업로드 실패: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = _postId != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? "게시물 수정" : "게시물 작성"),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _upload,
            child: _isUploading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isEdit ? "수정" : "게시", style: TextStyle(color: _canPost ? theme.colorScheme.primary : Colors.grey)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: _image == null && _existingPhotoUrl == null
                  ? _buildImagePlaceholder(theme)
                  : _buildImagePreview(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "무슨 생각을 하고 계신가요?",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canPost => _contentController.text.trim().isNotEmpty || _image != null || _existingPhotoUrl != null;

  Widget _buildImagePlaceholder(ThemeData theme) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text("사진 추가", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final imageProvider = _image != null
        ? FileImage(_image!) as ImageProvider
        : NetworkImage(_existingPhotoUrl!);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image(image: imageProvider, height: 300, width: double.infinity, fit: BoxFit.cover),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => setState(() {
              _image = null;
              _existingPhotoUrl = null;
            }),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}