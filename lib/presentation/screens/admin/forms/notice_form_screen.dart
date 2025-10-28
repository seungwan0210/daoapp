// lib/presentation/screens/admin/forms/notice_form_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NoticeFormScreen extends StatefulWidget {
  const NoticeFormScreen({super.key});

  @override
  _NoticeFormScreenState createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends State<NoticeFormScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _actionUrlController = TextEditingController();
  final _actionRouteController = TextEditingController();

  String _actionType = 'none'; // none, link, internal
  bool _isLoading = false;

  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("공지사항 관리")),
      body: Column(
        children: [
          _buildInputForm(),
          const Divider(),
          Expanded(child: _buildNoticeList()),
        ],
      ),
    );
  }

  // 입력 폼
  Widget _buildInputForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 제목
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "제목"),
            maxLines: 2,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),

          // 내용 - Expanded로 감싸서 스크롤 가능
          Expanded(
            child: TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: "내용"),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          const SizedBox(height: 12),

          // 액션 섹션
          _buildActionSection(),
          const SizedBox(height: 16),

          // 등록 버튼
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _addNotice,
            child: const Text("공지 등록"),
          ),
        ],
      ),
    );
  }

  // 액션 타입 선택
  Widget _buildActionSection() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _actionType,
          decoration: const InputDecoration(labelText: '액션 타입'),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('텍스트만')),
            DropdownMenuItem(value: 'link', child: Text('외부 링크')),
            DropdownMenuItem(value: 'internal', child: Text('앱 내부 페이지')),
          ],
          onChanged: (v) => setState(() => _actionType = v!),
        ),
        if (_actionType == 'link') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _actionUrlController,
            decoration: const InputDecoration(labelText: '링크 URL', hintText: 'https://example.com'),
            keyboardType: TextInputType.url,
          ),
        ],
        if (_actionType == 'internal') ...[
          const SizedBox(height: 8),
          TextField(
            controller: _actionRouteController,
            decoration: const InputDecoration(labelText: '라우트 경로', hintText: '/event, /ranking 등'),
          ),
        ],
      ],
    );
  }

  // 공지 등록
  Future<void> _addNotice() async {
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
    try {
      await _firestore.collection('notices').add({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'actionType': _actionType,
        'actionUrl': _actionType == 'link' ? _actionUrlController.text.trim() : null,
        'actionRoute': _actionType == 'internal' ? _actionRouteController.text.trim() : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      _showSnackBar("공지가 등록되었습니다!", Colors.green);
    } catch (e) {
      _showSnackBar("등록 실패: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _contentController.clear();
    _actionUrlController.clear();
    _actionRouteController.clear();
    setState(() => _actionType = 'none');
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // 공지 목록
  Widget _buildNoticeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('notices').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("등록된 공지가 없습니다."));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final type = data['actionType'] ?? 'none';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                title: Text(
                  data['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  data['content'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (type != 'none') const Icon(Icons.touch_app, size: 16, color: Colors.blue),
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editNotice(docId, data)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteNotice(docId)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 수정
  void _editNotice(String docId, Map<String, dynamic> data) {
    _titleController.text = data['title'] ?? '';
    _contentController.text = data['content'] ?? '';
    _actionType = data['actionType'] ?? 'none';
    _actionUrlController.text = data['actionUrl'] ?? '';
    _actionRouteController.text = data['actionRoute'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("공지 수정"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "제목"),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: "내용"),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionSection(),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('notices').doc(docId).update({
                'title': _titleController.text.trim(),
                'content': _contentController.text.trim(),
                'actionType': _actionType,
                'actionUrl': _actionType == 'link' ? _actionUrlController.text.trim() : null,
                'actionRoute': _actionType == 'internal' ? _actionRouteController.text.trim() : null,
              });
              Navigator.pop(ctx);
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  // 삭제
  Future<void> _deleteNotice(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('notices').doc(docId).delete();
      if (mounted) _showSnackBar("공지가 삭제되었습니다.", Colors.red);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _actionUrlController.dispose();
    _actionRouteController.dispose();
    super.dispose();
  }
}