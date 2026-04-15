import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/user_model.dart';
import 'package:daoapp/presentation/screens/my_page/services/image_upload_service.dart';

class PostWriteScreen extends ConsumerStatefulWidget {
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
  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];

  bool _isUploading = false;
  int _uploadCurrentIndex = 0; // ✅ 진행률 표시용
  String? _postId;
  bool _initializedFromRoute = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
    if (widget.initialImageFile != null) {
      _newImages.add(widget.initialImageFile!);
    }
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromRoute) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['postId'] != null) {
        _postId = args['postId'] as String;
        _loadExistingPost(_postId!);
      }
      _initializedFromRoute = true;
    }
  }

  Future<void> _loadExistingPost(String postId) async {
    final doc = await FirebaseFirestore.instance.collection('community').doc(postId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    _contentController.text = (data['content'] ?? '').toString();

    final dynamic images = data['imageUrls'];
    if (images is List) {
      _existingImageUrls = List<String>.from(images);
    } else if (data['photoUrl'] != null) {
      _existingImageUrls = [data['photoUrl']];
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickImages() async {
    final int currentTotal = _newImages.length + _existingImageUrls.length;
    if (currentTotal >= 7) {
      _showSnackBar('사진은 최대 7장까지 등록 가능합니다.');
      return;
    }

    final picked = await ImageUploadService.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        final int availableSlots = 7 - currentTotal;
        _newImages.addAll(
          picked.take(availableSlots).map((x) => File(x.path)).toList(),
        );
      });
    }
  }

  bool get _canPost =>
      _contentController.text.trim().isNotEmpty ||
          _newImages.isNotEmpty ||
          _existingImageUrls.isNotEmpty;

  // ✅ 안정성을 위해 순차 업로드 방식으로 변경
  Future<void> _upload() async {
    if (!_canPost) return;

    setState(() {
      _isUploading = true;
      _uploadCurrentIndex = 0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final appUser = AppUser.fromMap(user.uid, userDoc.data()!);

      // 1. 순차적으로 하나씩 업로드 (중복 및 꼬임 방지)
      final List<String> uploadedUrls = [];
      for (int i = 0; i < _newImages.length; i++) {
        setState(() => _uploadCurrentIndex = i + 1);
        final url = await ImageUploadService.upload(_newImages[i], 'community_posts/${user.uid}');
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      // 2. 리스트 합치기
      final List<String> finalImageUrls = [..._existingImageUrls, ...uploadedUrls];

      final postRef = FirebaseFirestore.instance.collection('community');
      final Map<String, dynamic> postData = {
        'userId': user.uid,
        'userName': appUser.koreanName ?? 'Unknown',
        'userPhotoUrl': appUser.profileImageUrl,
        'imageUrls': finalImageUrls,
        'photoUrl': finalImageUrls.isNotEmpty ? finalImageUrls.first : null,
        'content': _contentController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_postId == null) {
        await postRef.add({
          ...postData,
          'likes': 0,
          'comments': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await postRef.doc(_postId).update(postData);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = _postId != null;

    // ✅ 업로드 중에는 뒤로가기를 막고 로딩 화면을 띄움
    return PopScope(
      canPop: !_isUploading,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _isUploading ? null : () => Navigator.pop(context),
              ),
              title: Text(isEdit ? "게시물 수정" : "서클에 공유하기",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                TextButton(
                  onPressed: _canPost && !_isUploading ? _upload : null,
                  child: Text(isEdit ? "수정" : "게시",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      enabled: !_isUploading,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      decoration: const InputDecoration(
                        hintText: "무슨 생각을 하고 계신가요?",
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ✅ 전체 로딩 오버레이
          if (_isUploading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          "게시글을 올리는 중입니다...",
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "사진 업로드 중 ($_uploadCurrentIndex / ${_newImages.length})",
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    final bool hasImages = _newImages.isNotEmpty || _existingImageUrls.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("사진 (${_newImages.length + _existingImageUrls.length}/7)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (_newImages.length + _existingImageUrls.length < 7 && !_isUploading)
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text("추가"),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!hasImages)
          _buildImagePlaceholder(theme)
        else
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._existingImageUrls.map((url) => _buildImageItem(url: url, isNetwork: true)),
                ..._newImages.map((file) => _buildImageItem(file: file, isNetwork: false)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImages,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text("사진 추가 (최대 7장)", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem({String? url, File? file, required bool isNetwork}) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isNetwork
                ? Image.network(url!, width: 110, height: 110, fit: BoxFit.cover)
                : Image.file(file!, width: 110, height: 110, fit: BoxFit.cover),
          ),
          if (!_isUploading)
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isNetwork) {
                      _existingImageUrls.remove(url);
                      ImageUploadService.deleteByUrl(url!);
                    } else {
                      _newImages.remove(file);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}