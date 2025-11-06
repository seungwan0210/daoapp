// lib/presentation/screens/admin/forms/news_form_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

// 탭 전환을 위한 MainScreen import
import 'package:daoapp/presentation/screens/main_screen.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart'; // 추가!

class NewsFormScreen extends StatefulWidget {
  const NewsFormScreen({super.key});

  @override
  State<NewsFormScreen> createState() => _NewsFormScreenState();
}

class _NewsFormScreenState extends State<NewsFormScreen> {
  File? _image;
  final _titleController = TextEditingController();
  DateTime? _selectedDate;
  String _actionType = 'none';
  final _actionUrlController = TextEditingController();
  final _actionRouteController = TextEditingController();

  bool _isLoading = false;
  final picker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: '뉴스 등록',
        showBackButton: true,
      ),
      body: Column(
        children: [
          _buildInputForm(theme),
          const Divider(height: 1),
          Expanded(child: _buildNewsList(theme)),
        ],
      ),
    );
  }

  /* ────────────────────────── 입력 폼 ────────────────────────── */
  Widget _buildInputForm(ThemeData theme) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 이미지 미리보기
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _image == null
                      ? const Center(
                    child: Text(
                      '포스터 이미지 (3MB 이하)',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('이미지 선택'),
                  style: theme.elevatedButtonTheme.style,
                ),
                const SizedBox(height: 16),

                // 제목
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // 날짜 선택
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '날짜',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? '날짜를 선택하세요'
                          : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 액션 섹션
                _buildActionSection(theme),
                const SizedBox(height: 20),

                // 등록 버튼
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveNews,
                    style: theme.elevatedButtonTheme.style,
                    child: const Text('뉴스 등록', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection(ThemeData theme) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _actionType,
          decoration: const InputDecoration(
            labelText: '클릭 시 이동',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('없음')),
            DropdownMenuItem(value: 'link', child: Text('외부 링크')),
            DropdownMenuItem(value: 'internal', child: Text('앱 내부 페이지')),
          ],
          onChanged: (v) => setState(() => _actionType = v!),
        ),
        const SizedBox(height: 8),
        if (_actionType == 'link')
          TextField(
            controller: _actionUrlController,
            decoration: const InputDecoration(
              labelText: '링크 URL',
              border: OutlineInputBorder(),
              hintText: 'https://example.com',
            ),
            keyboardType: TextInputType.url,
          ),
        if (_actionType == 'internal')
          TextField(
            controller: _actionRouteController,
            decoration: const InputDecoration(
              labelText: '라우트 경로',
              border: OutlineInputBorder(),
              hintText: '/ranking',
            ),
          ),
      ],
    );
  }

  /* ────────────────────────── 이미지 선택 ────────────────────────── */
  Future<void> _pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final sizeInMB = file.lengthSync() / (1024 * 1024);
    if (sizeInMB > 3) {
      _showSnackBar("이미지는 3MB 이하만 가능합니다.", Colors.red);
      return;
    }

    setState(() => _image = file);
  }

  /* ────────────────────────── 날짜 선택 ────────────────────────── */
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /* ────────────────────────── 저장 ────────────────────────── */
  Future<void> _saveNews() async {
    if (_image == null) return _showSnackBar("포스터 이미지를 선택하세요", Colors.red);
    if (_titleController.text.trim().isEmpty) return _showSnackBar("제목을 입력하세요", Colors.red);
    if (_selectedDate == null) return _showSnackBar("날짜를 선택하세요", Colors.red);
    if (_actionType == 'link' && _actionUrlController.text.trim().isEmpty) {
      return _showSnackBar("링크 URL을 입력하세요", Colors.red);
    }
    if (_actionType == 'internal' && _actionRouteController.text.trim().isEmpty) {
      return _showSnackBar("라우트 경로를 입력하세요", Colors.red);
    }

    setState(() => _isLoading = true);
    _showSnackBar("업로드 중...", Colors.blue);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('news').child('$timestamp.jpg');
      await ref.putFile(_image!);
      final imageUrl = await ref.getDownloadURL();

      await _firestore.collection('news').add({
        'title': _titleController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate!),
        'imageUrl': imageUrl,
        'actionType': _actionType,
        'actionUrl': _actionType == 'link' ? _actionUrlController.text.trim() : null,
        'actionRoute': _actionType == 'internal' ? _actionRouteController.text.trim() : null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      _showSnackBar("뉴스 등록 완료!", Colors.green);
    } catch (e) {
      _showSnackBar("실패: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    setState(() {
      _image = null;
      _titleController.clear();
      _selectedDate = null;
      _actionType = 'none';
      _actionUrlController.clear();
      _actionRouteController.clear();
    });
  }

  /* ────────────────────────── 뉴스 목록 ────────────────────────── */
  Widget _buildNewsList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('news')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('등록된 뉴스 없음'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;
            final imageUrl = data['imageUrl'] as String?;
            final isActive = data['isActive'] as bool? ?? true;

            return AppCard(
              color: isActive ? null : Colors.grey[100],
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: imageUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                )
                    : const Icon(Icons.image),
                title: Text(
                  data['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? null : Colors.grey[600],
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  data['date'] is Timestamp
                      ? (data['date'] as Timestamp).toDate().toString().substring(0, 10)
                      : '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: isActive,
                      onChanged: (value) async {
                        await _firestore.collection('news').doc(docId).update({
                          'isActive': value,
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editNews(docId, data, imageUrl),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteNews(docId, imageUrl),
                    ),
                  ],
                ),
                // 뉴스 클릭 → 탭 전환만!
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
  void _editNews(String docId, Map<String, dynamic> data, String? currentImageUrl) {
    _titleController.text = data['title'] ?? '';
    _selectedDate = data['date'] is Timestamp ? (data['date'] as Timestamp).toDate() : null;
    _actionType = data['actionType'] ?? 'none';
    _actionUrlController.text = data['actionUrl'] ?? '';
    _actionRouteController.text = data['actionRoute'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          File? tempImage;

          return AlertDialog(
            title: const Text("뉴스 수정"),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                          child: tempImage != null
                              ? Image.file(tempImage, fit: BoxFit.cover)
                              : currentImageUrl != null
                              ? Image.network(currentImageUrl, fit: BoxFit.cover)
                              : const Center(child: Text("이미지 없음")),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await picker.pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              final file = File(picked.path);
                              if (file.lengthSync() / (1024 * 1024) <= 3) {
                                setStateDialog(() => tempImage = file);
                              } else {
                                _showSnackBar("3MB 이하만 가능", Colors.red);
                              }
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text("이미지 변경"),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: "제목", border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setStateDialog(() => _selectedDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: "날짜", border: OutlineInputBorder()),
                            child: Text(_selectedDate?.toString().substring(0, 10) ?? '선택'),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                  if (_titleController.text.trim().isEmpty || _selectedDate == null) {
                    _showSnackBar("제목과 날짜를 입력하세요", Colors.red);
                    return;
                  }

                  String? newImageUrl = currentImageUrl;
                  if (tempImage != null) {
                    final ref = _storage.ref().child('news').child('$docId.jpg');
                    await ref.putFile(tempImage!);
                    newImageUrl = await ref.getDownloadURL();

                    if (currentImageUrl != null) {
                      try {
                        await _storage.refFromURL(currentImageUrl).delete();
                      } catch (_) {}
                    }
                  }

                  await _firestore.collection('news').doc(docId).update({
                    'title': _titleController.text.trim(),
                    'date': Timestamp.fromDate(_selectedDate!),
                    'imageUrl': newImageUrl,
                    'actionType': _actionType,
                    'actionUrl': _actionType == 'link' ? _actionUrlController.text.trim() : null,
                    'actionRoute': _actionType == 'internal' ? _actionRouteController.text.trim() : null,
                    'isActive': true,
                  });

                  if (mounted) {
                    Navigator.pop(ctx);
                    _showSnackBar("수정 완료", Colors.green);
                  }
                },
                child: const Text("저장"),
              ),
            ],
          );
        },
      ),
    );
  }

  /* ────────────────────────── 삭제 ────────────────────────── */
  Future<void> _deleteNews(String docId, String? imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        content: const Text('이미지도 함께 삭제됩니다.'),
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
        await _firestore.collection('news').doc(docId).delete();
        if (imageUrl != null) {
          await _storage.refFromURL(imageUrl).delete();
        }
        if (mounted) _showSnackBar("삭제 완료", Colors.red);
      } catch (e) {
        if (mounted) _showSnackBar("삭제 실패: $e", Colors.red);
      }
    }
  }

  /* ────────────────────────── 유틸 ────────────────────────── */
  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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