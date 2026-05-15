// lib/presentation/screens/admin/forms/notice_form_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/screens/my_page/services/image_upload_service.dart'; // 이미지 서비스 임포트
import 'package:firebase_auth/firebase_auth.dart';

class NoticeFormScreen extends StatefulWidget {
  const NoticeFormScreen({super.key});

  @override
  State<NoticeFormScreen> createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends State<NoticeFormScreen> with SingleTickerProviderStateMixin {
  // 5개 국어용 컨트롤러 맵
  final Map<String, TextEditingController> _titleControllers = {
    'ko': TextEditingController(),
    'en': TextEditingController(),
    'ja': TextEditingController(),
    'zh_Hant': TextEditingController(),
    'zh_Hans': TextEditingController(),
  };

  final Map<String, TextEditingController> _contentControllers = {
    'ko': TextEditingController(),
    'en': TextEditingController(),
    'ja': TextEditingController(),
    'zh_Hant': TextEditingController(),
    'zh_Hans': TextEditingController(),
  };

  // 이미지 관련 상태
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  late TabController _tabController;

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _titleControllers.values) {
      c.dispose();
    }
    for (var c in _contentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /* ────────────────────────── 이미지 선택 ────────────────────────── */
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 7) {
      _showSnackBar("이미지는 최대 7장까지 가능합니다.", Colors.orange);
      return;
    }
    final picked = await ImageUploadService.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        final availableSlots = 7 - _selectedImages.length;
        _selectedImages.addAll(picked.take(availableSlots).map((x) => File(x.path)));
      });
    }
  }

  /* ────────────────────────── 등록 로직 ────────────────────────── */
  Future<void> _addNotice() async {
    // 한국어 제목은 필수 체크
    if (_titleControllers['ko']!.text.trim().isEmpty) {
      return _showSnackBar("한국어 제목은 필수입니다.", Colors.red);
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final List<String> uploadedUrls = [];

      // 1. 이미지 업로드 (있을 경우)
      for (var file in _selectedImages) {
        final url = await ImageUploadService.upload(file, 'notices/${user?.uid}');
        if (url != null) uploadedUrls.add(url);
      }

      // 2. 다국어 맵 구성
      final Map<String, Map<String, String>> langsData = {};
      _titleControllers.forEach((key, controller) {
        langsData[key] = {
          'title': controller.text.trim(),
          'content': _contentControllers[key]!.text.trim(),
        };
      });

      // 3. Firestore 저장
      await _firestore.collection('notices').add({
        'langs': langsData,
        'imageUrls': uploadedUrls,
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
    for (var c in _titleControllers.values) {
      c.clear();
    }
    for (var c in _contentControllers.values) {
      c.clear();
    }
    setState(() => _selectedImages.clear());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(title: '공지사항 마스터 관리', showBackButton: true),
      body: Column(
        children: [
          // 언어 선택 탭바
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "한국어(KO)"),
              Tab(text: "English(EN)"),
              Tab(text: "日本語(JA)"),
              Tab(text: "繁體(Hant)"),
              Tab(text: "简体(Hans)"),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 입력 폼 영역 (탭에 따라 내용 변경)
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _tabController,
                      children: _titleControllers.keys.map((langCode) {
                        return _buildLanguageInput(langCode);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 이미지 섹션
                  _buildImagePickerSection(),
                  const SizedBox(height: 24),

                  // 등록 버튼
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _addNotice,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("공지사항 발행 (5개국어 동시)", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  _buildRecentListHeader(),
                  // 하단 리스트 (간략히)
                  _buildNoticeListPreview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageInput(String langCode) {
    return Column(
      children: [
        TextField(
          controller: _titleControllers[langCode],
          decoration: InputDecoration(
            labelText: "제목 ($langCode)",
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: _contentControllers[langCode],
            decoration: InputDecoration(
              labelText: "내용 ($langCode)",
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("공지 이미지 (최대 7장)", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("${_selectedImages.length} / 7", style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 추가 버튼
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Icon(Icons.add_a_photo, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              // 선택된 이미지들
              ..._selectedImages.map((file) => Stack(
                children: [
                  Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImages.remove(file)),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentListHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text("최근 발행 리스트", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildNoticeListPreview() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('notices').orderBy('createdAt', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final langs = data['langs'] as Map<String, dynamic>? ?? {};
            final koTitle = langs['ko']?['title'] ?? 'No Title';

            return AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(koTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text("이미지 ${ (data['imageUrls'] as List?)?.length ?? 0 }장"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteNotice(doc.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteNotice(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("공지 삭제"),
        content: const Text("정말 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await _firestore.collection('notices').doc(docId).delete();
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}