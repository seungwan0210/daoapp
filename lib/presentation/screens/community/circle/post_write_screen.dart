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
  // 마이로그에서 넘어올 때 사용할 초기값
  final String? initialContent;
  final File? initialImageFile;

  const PostWriteScreen({
    super.key,
    this.initialContent,
    this.initialImageFile,
  });

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

  bool _initializedFromRoute = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
    if (widget.initialImageFile != null) {
      _image = widget.initialImageFile;
    }

    _contentController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initializedFromRoute) {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null && args['postId'] != null && _postId == null) {
        _postId = args['postId'] as String;
        _loadExistingPost(_postId!);
      }

      _initializedFromRoute = true;
    }
  }

  Future<void> _loadExistingPost(String postId) async {
    final doc =
    await FirebaseFirestore.instance.collection('community').doc(postId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    _contentController.text = (data['content'] ?? '').toString();

    // ✅ photoUrl / imageUrls 둘 다 호환
    final direct = (data['photoUrl'] as String?)?.trim();
    if (direct != null && direct.isNotEmpty) {
      _existingPhotoUrl = direct;
    } else {
      final dynamic images = data['imageUrls'];
      if (images is List && images.isNotEmpty) {
        final first = images.first;
        if (first is String && first.trim().isNotEmpty) {
          _existingPhotoUrl = first.trim();
        }
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    final picked =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  bool get _canPost =>
      _contentController.text.trim().isNotEmpty ||
          _image != null ||
          _existingPhotoUrl != null;

  Future<void> _upload() async {
    if (!_canPost) {
      _showSnackBar('내용 또는 사진을 추가해주세요');
      return;
    }

    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception('유저 정보를 불러올 수 없습니다.');
      }

      final appUser = AppUser.fromMap(user.uid, userDoc.data()!);

      // ✅ 업로드 후 최종 photoUrl
      String? photoUrl = _existingPhotoUrl;

      // 새 이미지 선택되어 있으면 업로드
      if (_image != null) {
        // 기존 이미지 삭제(선택)
        if (_existingPhotoUrl != null) {
          try {
            await FirebaseStorage.instance.refFromURL(_existingPhotoUrl!).delete();
          } catch (e) {
            debugPrint('기존 이미지 삭제 실패(무시 가능): $e');
          }
        }

        final ref = FirebaseStorage.instance
            .ref()
            .child('community_posts')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = await ref.putFile(_image!);
        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      final postRef = FirebaseFirestore.instance.collection('community');

      if (_postId == null) {
        // ✅ 새 글
        await postRef.add({
          'userId': user.uid,
          'userName': (appUser.koreanName?.trim().isNotEmpty == true)
              ? appUser.koreanName!.trim()
              : 'Unknown',
          'userPhotoUrl': appUser.profileImageUrl,
          'photoUrl': photoUrl,
          // ✅ PostCard/Preview 호환용 (있으면 imageUrls 우선)
          'imageUrls': photoUrl != null ? [photoUrl] : [],
          'content': _contentController.text.trim(),
          'likes': 0,
          'comments': 0,

          // ✅ 생성/수정 분리
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),

          // ✅ 기존 코드 호환 위해 timestamp 유지(정렬용)
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // ✅ 수정 (createdAt/timestamp는 건드리지 않음)
        final updateData = <String, dynamic>{
          'userPhotoUrl': appUser.profileImageUrl,
          'photoUrl': photoUrl,
          'imageUrls': photoUrl != null ? [photoUrl] : [],
          'content': _contentController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await postRef.doc(_postId).update(updateData);
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
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        title: Text(
          isEdit ? "게시물 수정" : "서클에 공유하기",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                isEdit ? "수정" : "게시",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
                  hintText: widget.initialContent != null
                      ? "마이로그를 다듬어서 공유해 보세요"
                      : "무슨 생각을 하고 계신가요?",
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "터치해서 사진을 선택하세요",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library,
                      size: 16, color: theme.colorScheme.primary),
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
