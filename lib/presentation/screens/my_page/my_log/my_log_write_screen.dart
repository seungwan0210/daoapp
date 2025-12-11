// lib/presentation/screens/user/my_log/my_log_write_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/services/storage_service.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
// 🔹 여기 추가! (myLogRepositoryProvider 가져오기)
import 'package:daoapp/presentation/providers/my_log_provider.dart';

class MyLogWriteScreen extends ConsumerStatefulWidget {
  final MyLogModel? existingLog;
  final DateTime? initialDate; // 캘린더에서 선택된 날짜

  const MyLogWriteScreen({
    super.key,
    this.existingLog,
    this.initialDate,
  });

  @override
  ConsumerState<MyLogWriteScreen> createState() =>
      _MyLogWriteScreenState();
}

class _MyLogWriteScreenState extends ConsumerState<MyLogWriteScreen> {
  final _contentController = TextEditingController();
  final _picker = ImagePicker();

  File? _pickedImage;
  String? _existingPhotoUrl; // 기존 사진 유지용

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

  // 선택된 날짜(또는 기존 기록 날짜)를 공통으로 계산
  DateTime get _selectedDateForSave {
    if (_isEditMode) {
      return widget.existingLog!.date;
    }
    return widget.initialDate ?? DateTime.now();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  void _insertTemplate(String template) {
    final current = _contentController.text;
    final separator = current.trim().isEmpty ? '' : '\n\n';
    _contentController.text = '$current$separator$template';
    _contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _contentController.text.length),
    );
    setState(() {});
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      String? uploadedPhotoUrl;

      // 1) 새로 선택한 사진이 있으면 업로드
      if (_pickedImage != null) {
        uploadedPhotoUrl =
        await StorageService().uploadMyLogImage(_pickedImage!);
      }

      // 2) 최종 photoUrls 결정 로직
      final List<String> photoUrls = [];
      if (uploadedPhotoUrl != null) {
        photoUrls.add(uploadedPhotoUrl);
      } else if (_existingPhotoUrl != null) {
        photoUrls.add(_existingPhotoUrl!);
      }

      // 3) 레포지토리 가져오기
      final repo = ref.read(myLogRepositoryProvider);

      // 4) 저장할 날짜(새로 쓰기면 선택 날짜, 수정이면 기존 날짜 유지)
      final dateForSave = _selectedDateForSave;

      // 5) 마이로그 모델 생성
      final log = MyLogModel(
        id: widget.existingLog?.id,
        userId: userId,
        date: dateForSave,
        content: content,
        photoUrls: photoUrls,
        isSharedToCircle: _shareToCircle,
        createdAt: widget.existingLog?.createdAt ?? DateTime.now(),
      );

      // 6) 먼저 마이로그 저장 → logId 확보
      final logId = await repo.saveLog(log);

      // 7) 피드에 공유 옵션이 켜져 있으면 서클에도 등록
      if (_shareToCircle) {
        await repo.shareToCircle(log.copyWith(id: logId));
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _shareToCircle ? '저장 + 피드 공유 완료!' : '마이로그 저장 완료!',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateForDisplay = _selectedDateForSave;
    final dateStr =
    DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(dateForDisplay);

    return Scaffold(
      appBar: CommonAppBar(
        title: _isEditMode ? '마이로그 수정' : '마이로그 작성',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _contentController.text.trim().isNotEmpty &&
                  !_isUploading
                  ? _save
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUploading)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Text(
                    _isUploading ? '저장 중...' : '완료',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE2E8F0),
              Color(0xFFF8FAFC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 메인 카드
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 헤더 (아이콘 + 날짜)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0F172A),
                                  Color(0xFF1E293B),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              '🎯',
                              style: TextStyle(fontSize: 26),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isEditMode
                                      ? '이 날의 다트 이야기를 다시 정리해볼까요?'
                                      : '오늘의 다트 이야기를 남겨보세요.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 📸 사진 선택 영역
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: _pickedImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              _pickedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                              : (_existingPhotoUrl != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              _existingPhotoUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 56,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '사진 추가하기 (선택)',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          )),
                        ),
                      ),
                      if (_pickedImage != null || _existingPhotoUrl != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _pickedImage = null;
                                _existingPhotoUrl = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('사진 삭제'),
                          ),
                        ),

                      const SizedBox(height: 24),

                      const Text(
                        '오늘 연습을 기록해 보세요',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ✨ 작성 도와주는 템플릿 버튼들
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('잘 된 점 💪'),
                            onPressed: () {
                              _insertTemplate(
                                '💪 오늘 잘 된 점\n'
                                    '- 스코어 / 그룹핑이 좋았던 순간은?\n'
                                    '- 자신 있었던 셋업이나 루트는?',
                              );
                            },
                          ),
                          ActionChip(
                            label: const Text('아쉬웠던 점 🧐'),
                            onPressed: () {
                              _insertTemplate(
                                '🧐 아쉬웠던 점\n'
                                    '- 자주 놓친 구간은?\n'
                                    '- 멘탈이 흔들린 순간은?',
                              );
                            },
                          ),
                          ActionChip(
                            label: const Text('다음 연습 계획 ✏️'),
                            onPressed: () {
                              _insertTemplate(
                                '✏️ 다음 연습 계획\n'
                                    '- 집중해서 연습할 구간 (예: 더블, 19 트리플 등)\n'
                                    '- 최소 몇 레그 / 몇 분 이상 할지?',
                              );
                            },
                          ),
                          ActionChip(
                            label: const Text('오늘의 한 줄 📝'),
                            onPressed: () {
                              _insertTemplate(
                                '📝 오늘의 한 줄\n- ',
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText:
                          '예시)\n'
                              '- 180 두 번, 트리플 감각 좋았음\n'
                              '- 더블 16, 더블 8 성공률이 조금 아쉬웠다\n'
                              '- 내일은 61~80 체크아웃 루트 집중 연습하기',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 16.5,
                          height: 1.8,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 공유 스위치 카드
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SwitchListTile(
                  title: const Text(
                    '서클에 공유하기',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _isEditMode
                        ? '이미 공유된 기록은 다시 올리지 않아요'
                        : '체크하면 저장과 동시에 피드에 올라가요',
                  ),
                  value: _shareToCircle,
                  onChanged: (v) {
                    setState(() => _shareToCircle = v);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
