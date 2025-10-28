// lib/presentation/screens/admin/forms/sponsor_form_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SponsorFormScreen extends StatefulWidget {
  const SponsorFormScreen({super.key});

  @override
  State<SponsorFormScreen> createState() => _SponsorFormScreenState();
}

class _SponsorFormScreenState extends State<SponsorFormScreen> {
  File? _image;
  bool _isActive = true;
  final picker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스폰서 관리'),
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildInputForm(),
          const Divider(height: 1),
          Expanded(child: _buildSponsorList()),
        ],
      ),
    );
  }

  /* ────────────────────────── 입력 폼 ────────────────────────── */
  Widget _buildInputForm() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                child: Image.file(_image!, fit: BoxFit.contain), // 로고 잘 보이게
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('갤러리에서 선택'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('배너 활성화'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeColor: const Color(0xFF00D4FF),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('등록하기'),
            ),
          ],
        ),
      ),
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
      if (picked != null && mounted) {
        final file = File(picked.path);
        final sizeInMB = file.lengthSync() / (1024 * 1024);
        if (sizeInMB > 3) {
          _showSnackBar('이미지는 3MB 이하만 가능합니다.', Colors.red);
          return;
        }
        setState(() => _image = file);
      }
    } catch (e) {
      _showSnackBar('이미지 선택 실패: $e', Colors.red);
    }
  }

  /* ────────────────────────── 등록 ────────────────────────── */
  Future<void> _save() async {
    if (_image == null) {
      _showSnackBar('이미지를 선택하세요', Colors.red);
      return;
    }

    _showSnackBar('업로드 중...', Colors.blue);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('sponsors').child('$timestamp.jpg');
      await ref.putFile(_image!);
      final url = await ref.getDownloadURL();

      await _firestore.collection('sponsors').add({
        'imageUrl': url,
        'isActive': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      _showSnackBar('등록 완료!', Colors.green);
    } catch (e) {
      _showSnackBar('등록 실패: $e', Colors.red);
    }
  }

  void _clearForm() {
    setState(() {
      _image = null;
      _isActive = true;
    });
  }

  /* ────────────────────────── 스폰서 목록 ────────────────────────── */
  Widget _buildSponsorList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('sponsors')
          .orderBy('createdAt', descending: true)  // where 삭제 → 모두 보임
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

            return Card(
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
                    fit: BoxFit.contain, // 로고 잘 보이게
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
                      activeColor: const Color(0xFF00D4FF),
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
              ),
            );
          },
        );
      },
    );
  }

  /* ────────────────────────── 수정 다이얼로그 ────────────────────────── */
  void _editSponsor(String docId, Map<String, dynamic> data, String? currentImageUrl) {
    final isActive = data['isActive'] as bool? ?? true;

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
                      activeColor: const Color(0xFF00D4FF),
                    ),
                  ],
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
      if (mounted) _showSnackBar('삭제 완료!', Colors.green);
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
    super.dispose();
  }
}