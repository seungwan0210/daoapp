// lib/presentation/screens/admin/forms/sponsor_form_screen.dart

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

class SponsorFormScreen extends StatefulWidget {
  const SponsorFormScreen({super.key});

  @override
  State<SponsorFormScreen> createState() => _SponsorFormScreenState();
}

class _SponsorFormScreenState extends State<SponsorFormScreen> {
  File? _image;
  bool _isActive = true;
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
        title: '스폰서 관리',
        showBackButton: true,
      ),
      body: Column(
        children: [
          _buildInputForm(theme),
          const Divider(height: 1),
          Expanded(child: _buildSponsorList(theme)),
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
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _image == null
                      ? const Center(
                    child: Text(
                      '이미지를 선택하세요',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('갤러리에서 선택'),
                  style: theme.elevatedButtonTheme.style,
                ),
                const SizedBox(height: 16),

                // 활성화 스위치
                SwitchListTile(
                  title: const Text('배너 활성화'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),

                // 액션 섹션 (내부/외부 URL)
                _buildActionSection(theme),
                const SizedBox(height: 16),

                // 등록 버튼
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: theme.elevatedButtonTheme.style,
                    child: const Text('등록하기', style: TextStyle(fontSize: 16)),
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

  /* ────────────────────────── 이미지 선택 ────────────────────────── */
  Future<void> _pickImage() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final file = File(picked.path);
      final sizeInMB = file.lengthSync() / (1024 * 1024);
      if (sizeInMB > 3) {
        _showSnackBar('이미지는 3MB 이하만 가능합니다.', Colors.red);
        return;
      }
      setState(() => _image = file);
    } catch (e) {
      _showSnackBar('이미지 선택 실패: $e', Colors.red);
    }
  }

  /* ────────────────────────── 등록 ────────────────────────── */
  Future<void> _save() async {
    if (_image == null) return _showSnackBar('이미지를 선택하세요', Colors.red);
    if (_actionType == 'link' && _actionUrlController.text.trim().isEmpty) {
      return _showSnackBar('링크 URL을 입력하세요', Colors.red);
    }
    if (_actionType == 'internal' && _actionRouteController.text.trim().isEmpty) {
      return _showSnackBar('라우트 경로를 입력하세요', Colors.red);
    }

    setState(() => _isLoading = true);
    _showSnackBar('업로드 중...', Colors.blue);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('sponsors').child('$timestamp.jpg');
      await ref.putFile(_image!);
      final url = await ref.getDownloadURL();

      await _firestore.collection('sponsors').add({
        'imageUrl': url,
        'isActive': _isActive,
        'actionType': _actionType,
        'actionUrl': _actionType == 'link' ? _actionUrlController.text.trim() : null,
        'actionRoute': _actionType == 'internal' ? _actionRouteController.text.trim() : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      _showSnackBar('등록 완료!', Colors.green);
    } catch (e) {
      _showSnackBar('등록 실패: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    setState(() {
      _image = null;
      _isActive = true;
      _actionType = 'none';
      _actionUrlController.clear();
      _actionRouteController.clear();
    });
  }

  /* ────────────────────────── 스폰서 목록 ────────────────────────── */
  Widget _buildSponsorList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('sponsors')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('등록된 스폰서가 없습니다.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;
            final url = data['imageUrl'] as String?;
            final isActive = data['isActive'] as bool? ?? true;

            return AppCard(
              color: isActive ? null : Colors.grey[100],
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: url != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                )
                    : const Icon(Icons.broken_image),
                title: Text(
                  isActive ? '활성화' : '비활성',
                  style: TextStyle(color: isActive ? Colors.green : Colors.red),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: isActive,
                      onChanged: (value) async {
                        await _firestore.collection('sponsors').doc(docId).update({
                          'isActive': value,
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editSponsor(docId, data, url),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSponsor(docId, url),
                    ),
                  ],
                ),
                // 스폰서 클릭 → 탭 전환만!
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
  void _editSponsor(String docId, Map<String, dynamic> data, String? currentImageUrl) {
    final isActive = data['isActive'] as bool? ?? true;
    _actionType = data['actionType'] ?? 'none';
    _actionUrlController.text = data['actionUrl'] ?? '';
    _actionRouteController.text = data['actionRoute'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool tempActive = isActive;
          File? tempImage;

          return AlertDialog(
            title: const Text('스폰서 수정'),
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
                          height: 150,
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                          child: tempImage != null
                              ? Image.file(tempImage, fit: BoxFit.contain)
                              : currentImageUrl != null
                              ? Image.network(currentImageUrl, fit: BoxFit.contain)
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
                                _showSnackBar('3MB 이하만 가능', Colors.red);
                              }
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text("이미지 변경"),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('배너 활성화'),
                          value: tempActive,
                          onChanged: (v) => setStateDialog(() => tempActive = v),
                          activeColor: Theme.of(context).colorScheme.primary,
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
              ElevatedButton(
                onPressed: () async {
                  String? newImageUrl = currentImageUrl;
                  if (tempImage != null) {
                    final ref = _storage.ref().child('sponsors').child('$docId.jpg');
                    await ref.putFile(tempImage!);
                    newImageUrl = await ref.getDownloadURL();

                    if (currentImageUrl != null) {
                      try {
                        await _storage.refFromURL(currentImageUrl).delete();
                      } catch (_) {}
                    }
                  }

                  await _firestore.collection('sponsors').doc(docId).update({
                    'imageUrl': newImageUrl,
                    'isActive': tempActive,
                    'actionType': _actionType,
                    'actionUrl': _actionType == 'link' ? _actionUrlController.text.trim() : null,
                    'actionRoute': _actionType == 'internal' ? _actionRouteController.text.trim() : null,
                  });

                  if (mounted) {
                    Navigator.pop(ctx);
                    _showSnackBar('수정 완료!', Colors.green);
                  }
                },
                child: const Text('저장'),
              ),
            ],
          );
        },
      ),
    );
  }

  /* ────────────────────────── 삭제 ────────────────────────── */
  Future<void> _deleteSponsor(String docId, String? imageUrl) async {
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

    if (confirm != true) return;

    try {
      await _firestore.collection('sponsors').doc(docId).delete();
      if (imageUrl != null) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (_) {}
      }
      if (mounted) _showSnackBar('삭제 완료!', Colors.red);
    } catch (e) {
      if (mounted) _showSnackBar('삭제 실패: $e', Colors.red);
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
    _actionUrlController.dispose();
    _actionRouteController.dispose();
    super.dispose();
  }
}