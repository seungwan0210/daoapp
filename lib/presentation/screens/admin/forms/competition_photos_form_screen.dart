// lib/presentation/screens/admin/forms/competition_photos_form_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';

class CompetitionPhotosFormScreen extends StatefulWidget {
  const CompetitionPhotosFormScreen({super.key});

  @override
  State<CompetitionPhotosFormScreen> createState() => _CompetitionPhotosFormScreenState();
}

class _CompetitionPhotosFormScreenState extends State<CompetitionPhotosFormScreen> {
  final _titleController = TextEditingController();
  final _actionUrlController = TextEditingController();
  final _actionRouteController = TextEditingController();
  File? _selectedImage;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  String _actionType = 'none';
  bool _isLoading = false;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("대회 사진 관리"),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildInputForm(theme),
          const Divider(height: 1),
          Expanded(child: _buildPhotoList(theme)),
        ],
      ),
    );
  }

  /* ────────────────────────── 입력 폼 ────────────────────────── */
  Widget _buildInputForm(ThemeData theme) {
    return Expanded(
      flex: 2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 제목
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "사진 제목",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // 이미지 선택 (갤러리에서 가져오기)
                Row(
                  children: [
                    Expanded(
                      child: _selectedImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, height: 120, fit: BoxFit.cover),
                      )
                          : Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: const Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text("사진 선택"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 액션 섹션
                _buildActionSection(theme),
                const SizedBox(height: 20),

                // 등록 버튼
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addPhoto,
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      textStyle: MaterialStateProperty.all(
                        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    child: const Text("사진 등록"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageUrl = null; // 새로 선택하면 URL 초기화
      });
    }
  }

  Widget _buildActionSection(ThemeData theme) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _actionType,
          decoration: const InputDecoration(
            labelText: '액션 타입',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('이미지만')),
            DropdownMenuItem(value: 'link', child: Text('외부 링크')),
            DropdownMenuItem(value: 'internal', child: Text('앱 내부 페이지')),
          ],
          onChanged: (v) => setState(() => _actionType = v!),
        ),
        const SizedBox(height: 12),
        if (_actionType == 'link')
          TextField(
            controller: _actionUrlController,
            decoration: const InputDecoration(
              labelText: '링크 URL',
              hintText: 'https://example.com',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            ),
            keyboardType: TextInputType.url,
          ),
        if (_actionType == 'internal')
          TextField(
            controller: _actionRouteController,
            decoration: const InputDecoration(
              labelText: '라우트 경로',
              hintText: '/ranking',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            ),
          ),
      ],
    );
  }

  /* ────────────────────────── 등록 (이미지 업로드 포함) ────────────────────────── */
  Future<void> _addPhoto() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedImage == null) {
      return _showSnackBar("제목과 사진을 선택하세요", Colors.red);
    }

    if (_actionType == 'link' && _actionUrlController.text.trim().isEmpty) {
      return _showSnackBar("링크 URL을 입력하세요", Colors.red);
    }
    if (_actionType == 'internal' && _actionRouteController.text.trim().isEmpty) {
      return _showSnackBar("라우트 경로를 입력하세요", Colors.red);
    }

    setState(() => _isLoading = true);
    try {
      // 이미지 업로드
      final ref = _storage.ref().child('competition_photos/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = await ref.putFile(_selectedImage!);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Firestore 저장
      await _firestore.collection('competition_photos').add({
        'title': title,
        'imageUrl': imageUrl,
        'actionType': _actionType,
        'actionUrl': _actionType == 'link' ? _actionUrlController.text.trim() : null,
        'actionRoute': _actionType == 'internal' ? _actionRouteController.text.trim() : null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      _showSnackBar("대회 사진이 등록되었습니다!", Colors.green);
    } catch (e) {
      _showSnackBar("등록 실패: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _actionUrlController.clear();
    _actionRouteController.clear();
    setState(() {
      _selectedImage = null;
      _actionType = 'none';
    });
  }

  /* ────────────────────────── 목록 ────────────────────────── */
  Widget _buildPhotoList(ThemeData theme) {
    return Expanded(
      flex: 1,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('competition_photos')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("등록된 대회 사진이 없습니다."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final isActive = data['isActive'] as bool? ?? true;

              return AppCard(
                color: isActive ? null : Colors.grey[100],
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['imageUrl'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  title: Text(
                    data['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? null : Colors.grey[600],
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        onChanged: (value) async {
                          await _firestore.collection('competition_photos').doc(docId).update({
                            'isActive': value,
                          });
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editPhoto(docId, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePhoto(docId),
                      ),
                    ],
                  ),
                  onTap: () {
                    final type = data['actionType'];
                    final url = data['actionUrl'] as String?;
                    final route = data['actionRoute'] as String?;

                    if (type == 'link' && url != null) {
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    } else if (type == 'internal' && route != null) {
                      _syncTabWithRoute(route);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  /* ────────────────────────── 탭 동기화 ────────────────────────── */
  void _syncTabWithRoute(String route) {
    int? tabIndex;
    switch (route) {
      case '/ranking':
        tabIndex = 1;
        break;
      case '/calendar':
        tabIndex = 2;
        break;
      case '/community':
        tabIndex = 3;
        break;
      case '/my-page':
        tabIndex = 4;
        break;
      default:
        return;
    }

    if (tabIndex != null) {
      MainScreen.changeTab(context, tabIndex);
    }
  }

  /* ────────────────────────── 수정 다이얼로그 ────────────────────────── */
  void _editPhoto(String docId, Map<String, dynamic> data) {
    _titleController.text = data['title'] ?? '';
    _imageUrl = data['imageUrl'] ?? '';
    _actionType = data['actionType'] ?? 'none';
    _actionUrlController.text = data['actionUrl'] ?? '';
    _actionRouteController.text = data['actionRoute'] ?? '';

    setState(() {
      _selectedImage = null; // 수정 시 기존 이미지는 URL로 표시
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("대회 사진 수정"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "사진 제목",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _selectedImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_selectedImage!, height: 100, fit: BoxFit.cover),
                          )
                              : _imageUrl != null && _imageUrl!.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_imageUrl!, height: 100, fit: BoxFit.cover),
                          )
                              : Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: const Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text("재선택"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildActionSection(Theme.of(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          ElevatedButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              if (title.isEmpty) {
                _showSnackBar("제목을 입력하세요", Colors.red);
                return;
              }

              try {
                String? finalImageUrl = _imageUrl;
                if (_selectedImage != null) {
                  final ref = _storage.ref().child('competition_photos/${DateTime.now().millisecondsSinceEpoch}');
                  final uploadTask = await ref.putFile(_selectedImage!);
                  finalImageUrl = await uploadTask.ref.getDownloadURL();
                }

                await _firestore.collection('competition_photos').doc(docId).update({
                  'title': title,
                  'imageUrl': finalImageUrl,
                  'actionType': _actionType,
                  'actionUrl': _actionType == 'link' ? _actionUrlController.text.trim() : null,
                  'actionRoute': _actionType == 'internal' ? _actionRouteController.text.trim() : null,
                  'isActive': true,
                });
                if (mounted) _showSnackBar("수정되었습니다.", Colors.green);
                Navigator.pop(ctx);
              } catch (e) {
                _showSnackBar("수정 실패: $e", Colors.red);
              }
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  /* ────────────────────────── 삭제 ────────────────────────── */
  Future<void> _deletePhoto(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("삭제하시겠습니까?"),
        content: const Text("이 작업은 되돌릴 수 없습니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('competition_photos').doc(docId).delete();
        if (mounted) _showSnackBar("대회 사진이 삭제되었습니다.", Colors.red);
      } catch (e) {
        _showSnackBar("삭제 실패: $e", Colors.red);
      }
    }
  }

  /* ────────────────────────── 유틸 ────────────────────────── */
  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _actionUrlController.dispose();
    _actionRouteController.dispose();
    super.dispose();
  }
}