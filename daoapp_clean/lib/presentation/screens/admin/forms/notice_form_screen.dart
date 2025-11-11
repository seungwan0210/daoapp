// lib/presentation/screens/admin/forms/notice_form_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart'; // 추가!

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
      appBar: CommonAppBar(
        title: '공지 등록',
        showBackButton: true,
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

  /* ────────────────────────── 입력 폼 (크게 확장) ────────────────────────── */
  Widget _buildInputForm(ThemeData theme) {
    return Expanded(
      flex: 2, // 리스트보다 더 넓게
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
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // 내용 (크게!)
                SizedBox(
                  height: 200, // 120 → 200
                  child: TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: "내용",
                      hintText: "자세한 내용을 입력하세요...",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    style: theme.textTheme.bodyMedium,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    expands: true,
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
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addNotice,
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      textStyle: MaterialStateProperty.all(
                        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    child: const Text("공지 등록"),
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
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('텍스트만')),
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

  /* ────────────────────────── 목록 (내용 잘 보이게) ────────────────────────── */
  Widget _buildNoticeList(ThemeData theme) {
    return Expanded(
      flex: 1,
      child: StreamBuilder<QuerySnapshot>(
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['content'] != null && data['content'].toString().isNotEmpty)
                        Text(
                          data['content'].toString(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                        ),
                      const SizedBox(height: 4),
                      if (data['actionUrl'] != null)
                        Text(
                          data['actionUrl'].toString(),
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        onChanged: (value) async {
                          await _firestore.collection('notices').doc(docId).update({
                            'isActive': value,
                          });
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editNotice(docId, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNotice(docId),
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
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: "내용",
                          hintText: "자세한 내용을 입력하세요...",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        expands: true,
                      ),
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