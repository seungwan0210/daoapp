import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/services/storage_service.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/providers/my_log_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class MyLogWriteScreen extends ConsumerStatefulWidget {
  final MyLogModel? existingLog;
  final DateTime? initialDate;

  const MyLogWriteScreen({
    super.key,
    this.existingLog,
    this.initialDate,
  });

  @override
  ConsumerState<MyLogWriteScreen> createState() => _MyLogWriteScreenState();
}

class _MyLogWriteScreenState extends ConsumerState<MyLogWriteScreen> {
  final _contentController = TextEditingController();
  final _picker = ImagePicker();

  File? _pickedImage;
  String? _existingPhotoUrl;

  bool _shareToCircle = false;
  bool _isUploading = false;

  bool get _isEditMode => widget.existingLog != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _contentController.text = log.content ?? '';
      _shareToCircle = log.isSharedToCircle;
      if (log.photoUrls.isNotEmpty) {
        _existingPhotoUrl = log.photoUrls.first;
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  DateTime get _selectedDateForSave {
    if (_isEditMode) return widget.existingLog!.date;
    return widget.initialDate ?? DateTime.now();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  // ✅ 토글형 템플릿 삽입 로직: 있으면 지우고, 없으면 넣는다!
  void _toggleTemplate(String template) {
    String current = _contentController.text;

    if (current.contains(template)) {
      // 이미 있으면 삭제 (줄바꿈 포함해서 깔끔하게)
      setState(() {
        _contentController.text = current.replaceAll(template, "").replaceAll("\n\n\n", "\n\n").trim();
      });
    } else {
      // 없으면 추가
      final separator = current.trim().isEmpty ? '' : '\n\n';
      setState(() {
        _contentController.text = '$current$separator$template';
      });
    }

    // 커서를 맨 끝으로 이동
    _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _contentController.text.length)
    );
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('기록할 내용을 입력해주세요.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      String? uploadedPhotoUrl;

      if (_pickedImage != null) {
        uploadedPhotoUrl = await StorageService().uploadMyLogImage(_pickedImage!);
      }

      final List<String> photoUrls = [];
      if (uploadedPhotoUrl != null) photoUrls.add(uploadedPhotoUrl);
      else if (_existingPhotoUrl != null) photoUrls.add(_existingPhotoUrl!);

      final repo = ref.read(myLogRepositoryProvider);
      final log = MyLogModel(
        id: widget.existingLog?.id,
        userId: userId,
        date: _selectedDateForSave,
        content: content,
        photoUrls: photoUrls,
        isSharedToCircle: _shareToCircle,
        createdAt: widget.existingLog?.createdAt ?? DateTime.now(),
      );

      final logId = await repo.saveLog(log);
      if (_shareToCircle) await repo.shareToCircle(log.copyWith(id: logId));

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // 헬퍼 위젯: 섹션 타이틀
  Widget _sectionTitle(String text, IconData icon) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.cyan[800]),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
    ],
  );

  // 헬퍼 위젯: 템플릿 칩 (선택 상태에 따라 색상 변경)
  Widget _templateChip(String label, String template, MaterialColor color) {
    final bool isSelected = _contentController.text.contains(template);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(
            color: isSelected ? Colors.white : color.shade800,
            fontSize: 12,
            fontWeight: FontWeight.bold
        )),
        selected: isSelected,
        selectedColor: color.shade700,
        backgroundColor: color.withOpacity(0.05),
        checkmarkColor: Colors.white,
        shape: StadiumBorder(side: BorderSide(color: color.withOpacity(0.2))),
        onSelected: (_) => _toggleTemplate(template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_selectedDateForSave);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CommonAppBar(
        title: _isEditMode ? '일기 수정' : '일기 작성',
        showBackButton: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                // ✅ 중요: 키보드가 올라올 때 스크롤이 자연스럽게 올라가도록 설정
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 헤더 카드
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0F172A)),
                          child: const Text('🎯', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            Text(_isEditMode ? '기억을 다듬고 있어요' : '오늘의 성장을 기록하세요',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. 사진 업로드 영역
                    _buildImagePicker(),
                    const SizedBox(height: 32),

                    // 3. 토글형 작성 가이드
                    _sectionTitle('작성 가이드 (탭해서 추가/삭제)', Icons.auto_awesome_outlined),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _templateChip('💪 잘 된 점', '💪 오늘 잘 된 점\n- ', Colors.blue),
                          _templateChip('🧐 아쉬운 점', '🧐 아쉬웠던 점\n- ', Colors.orange),
                          _templateChip('✏️ 다음 계획', '✏️ 다음 연습 계획\n- ', Colors.green),
                          _templateChip('📝 한 줄 평', '📝 오늘의 한 줄\n- ', Colors.purple),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. 본문 입력창 (스크롤 중복 방지)
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _contentController,
                        maxLines: null, // ✅ 텍스트 길이에 따라 자동으로 늘어남 (중복 스크롤 방지)
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(fontSize: 15, height: 1.6),
                        decoration: InputDecoration(
                          hintText: '오늘 다트 어땠나요?\n기억에 남는 샷이나 보완할 점을 적어보세요.',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 5. 공유 설정
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: SwitchListTile(
                        title: const Text('서클(커뮤니티)에 공유', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(_isEditMode ? '이미 공유된 기록입니다.' : '저장과 동시에 피드에 게시합니다.', style: const TextStyle(fontSize: 11)),
                        value: _shareToCircle,
                        activeColor: Colors.cyan[700],
                        onChanged: (v) => setState(() => _shareToCircle = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. 하단 고정 버튼 (배경색 추가하여 명확히 구분)
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  // 사진 업로드 위젯 빌더
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!, width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: _pickedImage != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_pickedImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity))
                  : (_existingPhotoUrl != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(_existingPhotoUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity))
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('사진 추가 (선택)', style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              )),
            ),
            if (_pickedImage != null || _existingPhotoUrl != null)
              Positioned(
                top: 10, right: 10,
                child: GestureDetector(
                  onTap: () => setState(() { _pickedImage = null; _existingPhotoUrl = null; }),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 하단 버튼 빌더
  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: ElevatedButton(
        onPressed: (_contentController.text.isNotEmpty && !_isUploading) ? _save : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isUploading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))
            : const Text('기록 저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}