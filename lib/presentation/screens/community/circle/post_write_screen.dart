import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/user_model.dart';
import 'package:daoapp/presentation/screens/my_page/services/image_upload_service.dart';
import 'package:daoapp/l10n/app_localizations.dart';

class PostWriteScreen extends ConsumerStatefulWidget {
  final String? initialContent;
  final File? initialImageFile;

  const PostWriteScreen({
    super.key,
    this.initialContent,
    this.initialImageFile,
  });

  // 💡 도배 방지용 시간 기록
  static DateTime? _lastPostTime;

  @override
  ConsumerState<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends ConsumerState<PostWriteScreen> {
  final _contentController = TextEditingController();
  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];

  bool _isUploading = false;
  int _uploadCurrentIndex = 0;
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
    if (images is List) _existingImageUrls = List<String>.from(images);
    if (mounted) setState(() {});
  }

  Future<void> _pickImages() async {
    final s = AppLocalizations.of(context)!;
    final int currentTotal = _newImages.length + _existingImageUrls.length;
    if (currentTotal >= 7) {
      _showSnackBar(s.post_write_photo_limit);
      return;
    }
    final picked = await ImageUploadService.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        final int availableSlots = 7 - currentTotal;
        _newImages.addAll(picked.take(availableSlots).map((x) => File(x.path)).toList());
      });
    }
  }

  bool get _canPost => _contentController.text.trim().isNotEmpty || _newImages.isNotEmpty || _existingImageUrls.isNotEmpty;

  Future<void> _upload() async {
    if (!_canPost) return;
    final s = AppLocalizations.of(context)!;

    if (_postId == null && PostWriteScreen._lastPostTime != null) {
      if (DateTime.now().difference(PostWriteScreen._lastPostTime!).inSeconds < 60) {
        _showSnackBar(s.post_write_delay_msg);
        return;
      }
    }

    setState(() { _isUploading = true; _uploadCurrentIndex = 0; });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final appUser = AppUser.fromMap(user.uid, userDoc.data()!);

      final List<String> uploadedUrls = [];
      for (int i = 0; i < _newImages.length; i++) {
        setState(() => _uploadCurrentIndex = i + 1);
        final url = await ImageUploadService.upload(_newImages[i], 'community_posts/${user.uid}');
        if (url != null) uploadedUrls.add(url);
      }

      final List<String> finalImageUrls = [..._existingImageUrls, ...uploadedUrls];
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
        await FirebaseFirestore.instance.collection('community').add({
          ...postData,
          'likes': 0, 'comments': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(),
        });
        PostWriteScreen._lastPostTime = DateTime.now();
      } else {
        await FirebaseFirestore.instance.collection('community').doc(_postId).update(postData);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showSnackBar(s.post_write_error_upload(e.toString()));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final isEdit = _postId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(isEdit ? s.post_write_edit_title : s.post_write_title, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _canPost && !_isUploading ? _upload : null,
            child: Text(isEdit ? s.post_write_btn_edit : s.post_write_btn_post, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: _isUploading
          ? _buildLoadingOverlay(s)
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // 1. 시원하게 뚫린 텍스트 입력창 (minLines 설정으로 최소 높이 확보)
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 8,
                    autofocus: true,
                    style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: s.post_write_hint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 2. 기존 방식의 사진 섹션 (가로 리스트 + 추가 버튼)
                  _buildImageSection(s),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(AppLocalizations s) {
    final count = _newImages.length + _existingImageUrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(s.post_write_photo_count(count.toString()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            if (count < 7)
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(s.post_write_photo_add),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (count == 0)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: Colors.grey[300], size: 40),
                  const SizedBox(height: 8),
                  Text(s.post_write_photo_placeholder, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._existingImageUrls.map((url) => _buildThumbnail(url: url, isNetwork: true)),
                ..._newImages.map((file) => _buildThumbnail(file: file, isNetwork: false)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnail({String? url, File? file, required bool isNetwork}) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isNetwork
                ? Image.network(url!, width: 110, height: 110, fit: BoxFit.cover)
                : Image.file(file!, width: 110, height: 110, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => setState(() => isNetwork ? _existingImageUrls.remove(url) : _newImages.remove(file)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(AppLocalizations s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(s.post_write_uploading, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(s.post_write_upload_progress(_uploadCurrentIndex.toString(), _newImages.length.toString())),
        ],
      ),
    );
  }
}