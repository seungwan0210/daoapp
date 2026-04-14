// lib/presentation/screens/admin/selection_players_admin_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:daoapp/presentation/widgets/common_appbar.dart';

class SelectionPlayersAdminScreen extends StatefulWidget {
  const SelectionPlayersAdminScreen({super.key});

  @override
  State<SelectionPlayersAdminScreen> createState() =>
      _SelectionPlayersAdminScreenState();
}

class _SelectionPlayersAdminScreenState
    extends State<SelectionPlayersAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  String _season = 'season1'; // season1, season2, season3, total
  String _gender = 'male'; // male, female

  final _koreanNameCtrl = TextEditingController();
  final _englishNameCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '1');

  bool _isLoading = false; // 폼 전체 로딩(불러오기/저장/삭제) 상태
  bool _isUploadingImage = false; // 이미지 업로드 중 상태
  File? _localImageFile; // 갤러리에서 고른 로컬 이미지(미리보기용)

  @override
  void dispose() {
    _koreanNameCtrl.dispose();
    _englishNameCtrl.dispose();
    _shopNameCtrl.dispose();
    _photoUrlCtrl.dispose();
    _bioCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  String _seasonLabel(String season) {
    switch (season) {
      case 'season1':
        return '시즌 1';
      case 'season2':
        return '시즌 2';
      case 'season3':
        return '시즌 3';
      case 'total':
        return '통합';
      default:
        return season;
    }
  }

  /// 시즌 + 성별 선택 시 기존 데이터 로드
  Future<void> _loadCurrentData() async {
    setState(() {
      _isLoading = true;
      _localImageFile = null; // 새 조합 로드 시 로컬 미리보기 초기화
    });
    try {
      final docId = '${_season}_$_gender';
      final doc = await FirebaseFirestore.instance
          .collection('steel_league_selection')
          .doc(docId)
          .get();

      if (!doc.exists) {
        _koreanNameCtrl.clear();
        _englishNameCtrl.clear();
        _shopNameCtrl.clear();
        _photoUrlCtrl.clear();
        _bioCtrl.clear();
        _orderCtrl.text = '1';
      } else {
        final data = doc.data() as Map<String, dynamic>;
        _koreanNameCtrl.text = (data['koreanName'] ?? '') as String;
        _englishNameCtrl.text = (data['englishName'] ?? '') as String;
        _shopNameCtrl.text = (data['shopName'] ?? '') as String;
        _photoUrlCtrl.text = (data['photoUrl'] ?? '') as String;
        _bioCtrl.text = (data['bio'] ?? '') as String;
        _orderCtrl.text = (data['order'] ?? 1).toString();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('데이터 불러오기 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 갤러리에서 사진 선택 + Firebase Storage 업로드
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();

    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        _localImageFile = file;
        _isUploadingImage = true;
      });

      final fileName =
          '${_season}_${_gender}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 📁 Storage 경로: selection_players/파일명.jpg
      final ref = FirebaseStorage.instance
          .ref()
          .child('selection_players')
          .child(fileName);

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      if (!mounted) return;
      setState(() {
        _photoUrlCtrl.text = downloadUrl; // Firestore에는 다운로드 URL 저장
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사진이 업로드되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사진 업로드 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final order = int.tryParse(_orderCtrl.text.trim()) ?? 1;
      final docId = '${_season}_$_gender';

      await FirebaseFirestore.instance
          .collection('steel_league_selection')
          .doc(docId)
          .set({
        'koreanName': _koreanNameCtrl.text.trim(),
        'englishName': _englishNameCtrl.text.trim(),
        'gender': _gender,
        'season': _season,
        'shopName': _shopNameCtrl.text.trim(),
        'photoUrl': _photoUrlCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'order': order,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('선발 선수 정보가 저장되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 현재 시즌+성별 문서 삭제
  Future<void> _delete() async {
    final docId = '${_season}_$_gender';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('$_season / $_gender 선발 선수를 삭제할까요?\n'
            '삭제 후에는 앱에서 "선발 예정"으로 표시됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('steel_league_selection')
          .doc(docId)
          .delete();

      // 폼 초기화
      _koreanNameCtrl.clear();
      _englishNameCtrl.clear();
      _shopNameCtrl.clear();
      _photoUrlCtrl.clear();
      _bioCtrl.clear();
      _orderCtrl.text = '1';
      _localImageFile = null;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('선발 선수 정보가 삭제되었습니다'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // 기본값(season1, male) 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CommonAppBar(
        title: '선발 선수 관리',
        showBackButton: true,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              // 시즌 + 성별 선택
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _season,
                      decoration: const InputDecoration(
                        labelText: '시즌',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'season1', child: Text('시즌 1')),
                        DropdownMenuItem(value: 'season2', child: Text('시즌 2')),
                        DropdownMenuItem(value: 'season3', child: Text('시즌 3')),
                        DropdownMenuItem(value: 'total', child: Text('통합')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _season = v);
                        _loadCurrentData();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        labelText: '성별',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('남자')),
                        DropdownMenuItem(value: 'female', child: Text('여자')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _gender = v);
                        _loadCurrentData();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: AbsorbPointer(
                      absorbing: _isLoading,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isLoading)
                            const LinearProgressIndicator(minHeight: 2),
                          const SizedBox(height: 12),

                          // 🔹 사진 미리보기 + 업로드 버튼
                          Row(
                            children: [
                              _buildPhotoPreview(theme),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: _isUploadingImage
                                          ? null
                                          : _pickAndUploadImage,
                                      icon: _isUploadingImage
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                          : const Icon(Icons.photo_library),
                                      label: Text(
                                        _isUploadingImage
                                            ? '업로드 중...'
                                            : '갤러리에서 사진 선택',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '사진은 Storage의 selection_players 폴더에 저장되고,\n'
                                          'Firestore에는 다운로드 URL이 저장됩니다.',
                                      style:
                                      theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _koreanNameCtrl,
                            decoration: const InputDecoration(
                              labelText: '이름 (한글)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? '필수 입력'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _englishNameCtrl,
                            decoration: const InputDecoration(
                              labelText: '이름 (영문 / 선택)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _shopNameCtrl,
                            decoration: const InputDecoration(
                              labelText: '소속 샵 (선택)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _photoUrlCtrl,
                            decoration: const InputDecoration(
                              labelText: '프로필 사진 URL (선택)',
                              hintText: '자동 입력되거나 직접 붙여넣기',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _bioCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: '한 줄 소개 / 간단 설명 (선택)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _orderCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '정렬 순서 (기본 1)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '※ 시즌 + 성별 조합당 1명씩 저장됩니다.\n'
                                  '   예) season1 남자 1명, 여자 1명 → 시즌 1 대표 2명\n'
                                  '   시즌1~3 + 통합까지 총 8명의 선발 선수가 표시됩니다.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 🔹 현재 저장된 선발 선수 요약 리스트
                          Text(
                            '현재 저장된 선발 선수',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('steel_league_selection')
                                .orderBy('season')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: LinearProgressIndicator(minHeight: 2),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Text(
                                  '아직 저장된 선발 선수가 없습니다.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                );
                              }

                              final docs = snapshot.data!.docs;

                              return Column(
                                children: docs.map((doc) {
                                  final data = doc.data();
                                  final season =
                                  (data['season'] ?? '') as String;
                                  final gender =
                                  (data['gender'] ?? '') as String;
                                  final koreanName =
                                  (data['koreanName'] ?? '') as String;

                                  final genderLabel = gender == 'male'
                                      ? '남자'
                                      : '여자';

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 14,
                                      child: Text(
                                        gender == 'male' ? 'M' : 'F',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                    title: Text(
                                      '${_seasonLabel(season)} · $genderLabel',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      koreanName.isEmpty
                                          ? '(이름 없음)'
                                          : koreanName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: const Icon(
                                      Icons.edit,
                                      size: 18,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _season = season;
                                        _gender = gender;
                                      });
                                      _loadCurrentData();
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('삭제하기'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        '저장하기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(ThemeData theme) {
    final radius = 32.0;

    // 1) 갤러리에서 고른 로컬 파일이 있으면 그걸 먼저 보여줌
    if (_localImageFile != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
        backgroundImage: FileImage(_localImageFile!),
      );
    }

    // 2) 서버 URL이 있으면 NetworkImage로 프리뷰
    if (_photoUrlCtrl.text.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
        backgroundImage: NetworkImage(_photoUrlCtrl.text.trim()),
        onBackgroundImageError: (_, __) {},
      );
    }

    // 3) 아무것도 없으면 플레이스홀더
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      child: Icon(
        Icons.person_outline,
        size: 32,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
