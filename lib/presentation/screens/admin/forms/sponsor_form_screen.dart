// lib/presentation/screens/admin/forms/sponsor_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  // 이미지 선택
  Future<void> _pickImage() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _image = File(picked.path));
      }
    } catch (e) {
      _showSnackBar('이미지 선택 실패: $e', Colors.red);
    }
  }

  // 등록
  Future<void> _save() async {
    if (_image == null) {
      _showSnackBar('이미지를 선택하세요', Colors.red);
      return;
    }

    _showSnackBar('업로드 중...', Colors.blue, showProgress: true);

    try {
      // 고정 경로 + 고유 파일명
      final ref = _storage.ref().child('sponsors').child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // 업로드 완료까지 await
      await ref.putFile(_image!);

      // ref로 직접 URL 가져오기
      final url = await ref.getDownloadURL();

      // Firestore 저장
      await _firestore.collection('banners_sponsors').add({
        'imageUrl': url,
        'active': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _hideSnackBar();
      _showSnackBar('등록 완료!', Colors.green);
      _clearForm();
    } catch (e) {
      _hideSnackBar();
      _showSnackBar('등록 실패: $e', Colors.red);
    }
  }

  void _clearForm() {
    setState(() {
      _image = null;
      _isActive = true;
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
        title: const Text('스폰서 관리'),
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 입력 폼
          _buildInputForm(),
          const Divider(),
          // 스폰서 목록
          Expanded(child: _buildSponsorList()),
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
          Container(
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _image == null
                ? const Center(child: Text('이미지를 선택하세요', style: TextStyle(color: Colors.grey)))
                : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_image!, fit: BoxFit.cover)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.white),
            child: const Text('등록하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('banners_sponsors').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('등록된 스폰서가 없습니다.'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final url = data['imageUrl'] as String?;
            final active = data['active'] as bool? ?? true;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: url != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                )
                    : const Icon(Icons.broken_image),
                title: Text(active ? '활성화' : '비활성', style: TextStyle(color: active ? Colors.green : Colors.red)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editSponsor(docId, data)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSponsor(docId, url)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editSponsor(String docId, Map<String, dynamic> data) {
    final url = data['imageUrl'] as String?;
    final active = data['active'] as bool? ?? true;

    setState(() => _isActive = active);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('스폰서 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (url != null) ...[
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, height: 100, fit: BoxFit.cover)),
              const SizedBox(height: 12),
            ],
            SwitchListTile(
              title: const Text('배너 활성화'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('banners_sponsors').doc(docId).update({'active': _isActive});
              Navigator.pop(ctx);
              _showSnackBar('수정 완료!', Colors.green);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 안전한 삭제 (오류 무시)
  Future<void> _deleteSponsor(String docId, String? imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Firestore 삭제
      await _firestore.collection('banners_sponsors').doc(docId).delete();

      // 2. Storage 삭제 (실패해도 무시)
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('Storage 이미지 삭제 실패 (무시): $e');
        }
      }

      _showSnackBar('삭제 완료!', Colors.green);
    } catch (e) {
      _showSnackBar('삭제 실패: $e', Colors.red);
    }
  }
}