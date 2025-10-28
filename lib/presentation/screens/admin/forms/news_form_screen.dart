// lib/presentation/screens/admin/forms/news_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class NewsFormScreen extends StatefulWidget {
  const NewsFormScreen({super.key});

  @override
  State<NewsFormScreen> createState() => _NewsFormScreenState();
}

class _NewsFormScreenState extends State<NewsFormScreen> {
  File? _image;
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  String _actionType = 'none';
  final _actionUrlController = TextEditingController();
  final _actionRouteController = TextEditingController();

  bool _isLoading = false;
  final picker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // 이미지 선택 + 3MB 제한
  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;

    final file = File(picked.path);
    final sizeInMB = file.lengthSync() / (1024 * 1024);
    if (sizeInMB > 3) {
      _showSnackBar("이미지는 3MB 이하만 가능합니다.", Colors.red);
      return;
    }

    setState(() => _image = file);
  }

  // 날짜 선택기
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _dateController.text = picked.toString().substring(0, 10);
    }
  }

  Future<void> _saveNews() async {
    if (_image == null) {
      _showSnackBar("포스터 이미지를 선택하세요", Colors.red);
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar("제목을 입력하세요", Colors.red);
      return;
    }
    if (_actionType == 'link' && _actionUrlController.text.trim().isEmpty) {
      _showSnackBar("링크 URL을 입력하세요", Colors.red);
      return;
    }
    if (_actionType == 'internal' && _actionRouteController.text.trim().isEmpty) {
      _showSnackBar("라우트 경로를 입력하세요", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    _showSnackBar("업로드 중...", Colors.blue, showProgress: true);

    try {
      final ref = _storage.ref().child('news').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_image!);
      final imageUrl = await ref.getDownloadURL();

      await _firestore.collection('news').add({
        'title': _titleController.text.trim(),
        'date': _dateController.text.trim(),
        'imageUrl': imageUrl,
        'actionType': _actionType,
        'actionUrl': _actionType == 'link' ? _actionUrlController.text.trim() : null,
        'actionRoute': _actionType == 'internal' ? _actionRouteController.text.trim() : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _hideSnackBar();
      _showSnackBar("뉴스 등록 완료!", Colors.green);
      _clearForm();
    } catch (e) {
      _hideSnackBar();
      _showSnackBar("실패: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    setState(() {
      _image = null;
      _titleController.clear();
      _dateController.clear();
      _actionType = 'none';
      _actionUrlController.clear();
      _actionRouteController.clear();
    });
  }

  void _showSnackBar(String msg, Color color, {bool showProgress = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (showProgress) ...[
              const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              const SizedBox(width: 12),
            ],
            Text(msg),
          ],
        ),
        backgroundColor: color,
        duration: showProgress ? const Duration(minutes: 5) : const Duration(seconds: 2),
      ),
    );
  }

  void _hideSnackBar() {
    if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('뉴스 관리'),
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildInputForm(),
          const Divider(),
          Expanded(child: _buildNewsList()),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Padding(
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
                ? const Center(child: Text('포스터 이미지 (3MB 이하)', style: TextStyle(color: Colors.grey)))
                : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_image!, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text('이미지 선택'),
          ),
          const SizedBox(height: 16),

          // 제목 입력 - 길면 ... 처리
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: '제목'), // 수정: .const → const
            maxLines: 2,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),

          // 날짜 입력
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _selectDate,
            decoration: const InputDecoration(
              labelText: '날짜',
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 16),

          // 액션 섹션
          _buildActionSection(),
          const SizedBox(height: 20),

          // 등록 버튼
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _saveNews,
            child: const Text('뉴스 등록'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _actionType,
          decoration: const InputDecoration(labelText: '클릭 시 이동'),
          hint: const Text('선택하세요'),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('없음')),
            DropdownMenuItem(value: 'link', child: Text('외부 링크')),
            DropdownMenuItem(value: 'internal', child: Text('앱 내부 페이지')),
          ],
          onChanged: (v) => setState(() => _actionType = v!),
        ),
        if (_actionType == 'link') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _actionUrlController,
            decoration: const InputDecoration(labelText: '링크 URL'),
            maxLines: 1,
            keyboardType: TextInputType.url,
          ),
        ],
        if (_actionType == 'internal') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _actionRouteController,
            decoration: const InputDecoration(labelText: '라우트 경로 (예: /ranking)'),
            maxLines: 1,
          ),
        ],
      ],
    );
  }

  Widget _buildNewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('news').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('등록된 뉴스 없음'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final url = data['imageUrl'] as String?;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: url != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url, width: 60, height: 60, fit: BoxFit.cover),
                )
                    : const Icon(Icons.image),
                title: Text(
                  data['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  data['date'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editNews(docId, data)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteNews(docId, url)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editNews(String docId, Map<String, dynamic> data) {
    // 수정 로직 (생략 - 필요 시 추가)
  }

  Future<void> _deleteNews(String docId, String? imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('news').doc(docId).delete();
      if (imageUrl != null) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print(e);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _actionUrlController.dispose();
    _actionRouteController.dispose();
    super.dispose();
  }
}