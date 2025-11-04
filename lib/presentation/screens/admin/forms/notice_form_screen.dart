// lib/presentation/screens/admin/forms/notice_form_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:url_launcher/url_launcher.dart';

// 탭 전환을 위한 MainScreen import (필수!)
import 'package:daoapp/presentation/screens/main_screen.dart'; // ← 여기에 MainScreen 있음

class NoticeFormScreen extends StatefulWidget {
  const NoticeFormScreen({super.key});

  @override
  State<NoticeFormScreen> createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends State<NoticeFormScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _actionUrlController = TextEditingController();
  final _actionRouteController = TextEditingController();

  String _actionType = 'none';
  bool _isLoading = false;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("공지사항 관리"),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildInputForm(theme),
          const Divider(height: 1),
          Expanded(child: _buildNoticeList(theme)),
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
                // 제목
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "제목",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // 내용
                SizedBox(
                  height: 120,
                  child: TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: "내용",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
                const SizedBox(height: 12),

                // 액션 섹션
                _buildActionSection(theme),
                const SizedBox(height: 16),

                // 등록 버튼
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addNotice,
                    style: theme.elevatedButtonTheme.style,
                    child: const Text("공지 등록", style: TextStyle(fontSize: 16)),
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
            labelText: '액션 타입',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('텍스트만')),
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
              hintText: 'https://example.com',
              border: OutlineInputBorder(),
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
            ),
          ),
      ],
    );
  }

  /* ────────────────────────── 등록 ────────────────────────── */
  Future<void> _addNotice() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return _showSnackBar("제목을 입력하세요", Colors.red);

    if (_actionType == 'link' && _actionUrlController.text.trim().isEmpty) {
      return _showSnackBar("링크 URL을 입력하세요", Colors.red);
    }
    if (_actionType == 'internal' && _actionRouteController.text.trim().isEmpty) {
      return _showSnackBar("라우트 경로를 입력하세요", Colors.red);
    }

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('notices').add({
        'title': title,
        'content': _contentController.text.trim(),
        'actionType': _actionType,
        'actionUrl': _actionType == 'link' ? _actionUrlController.text.trim() : null,
        'actionRoute': _actionType == 'internal' ? _actionRouteController.text.trim() : null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      _showSnackBar("공지가 등록되었습니다!", Colors.green);
    } catch (e) {
      _showSnackBar("등록 실패: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _contentController.clear();
    _actionUrlController.clear();
    _actionRouteController.clear();
    setState(() => _actionType = 'none');
  }

  /* ────────────────────────── 목록 ────────────────────────── */
  Widget _buildNoticeList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("등록된 공지가 없습니다."));
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
                  data['content'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 활성화 토글
                    Switch(
                      value: isActive,
                      onChanged: (value) async {
                        await _firestore.collection('notices').doc(docId).update({
                          'isActive': value,
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                    // 수정
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editNotice(docId, data),
                    ),
                    // 삭제
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteNotice(docId),
                    ),
                  ],
                ),
                // 내부 링크 클릭 → 푸쉬 + 탭 전환
                onTap: () {
                  final type = data['actionType'];
                  final url = data['actionUrl'] as String?;
                  final route = data['actionRoute'] as String?;

                  if (type == 'link' && url != null) {
                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  } else if (type == 'internal' && route != null) {
                    // 1. 탭 전환
                    _syncTabWithRoute(route);
                    // 2. 페이지 푸쉬
                    Navigator.pushNamed(context, route);
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
      case '/point-calendar':
        tabIndex = 2; // 예: 일정 탭이 2번
        break;
    // 다른 페이지 추가 가능
      default:
        return;
    }

    if (tabIndex != null) {
      MainScreen.changeTab(context, tabIndex);
    }
  }

  /* ────────────────────────── 수정 다이얼로그 ────────────────────────── */
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
                        labelText: "제목",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: "내용",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
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
              final title = _titleController.text.trim();
              if (title.isEmpty) {
                _showSnackBar("제목을 입력하세요", Colors.red);
                return;
              }

              try {
                await _firestore.collection('notices').doc(docId).update({
                  'title': title,
                  'content': _contentController.text.trim(),
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
  Future<void> _deleteNotice(String docId) async {
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
        await _firestore.collection('notices').doc(docId).delete();
        if (mounted) _showSnackBar("공지가 삭제되었습니다.", Colors.red);
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
    _contentController.dispose();
    _actionUrlController.dispose();
    _actionRouteController.dispose();
    super.dispose();
  }
}