// lib/presentation/screens/admin/selection_players_admin_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  String _gender = 'male';    // male, female

  final _koreanNameCtrl = TextEditingController();
  final _englishNameCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '1');

  bool _isLoading = false;

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

  /// 시즌 + 성별 선택 시 기존 데이터 로드
  Future<void> _loadCurrentData() async {
    setState(() => _isLoading = true);
    try {
      // docId를 season_gender로 고정해서 쓰는 방식
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

                          TextFormField(
                            controller: _koreanNameCtrl,
                            decoration: const InputDecoration(
                              labelText: '이름 (한글)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                            v == null || v.trim().isEmpty ? '필수 입력' : null,
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
                              hintText: 'Firebase Storage에 업로드 후 URL 붙여넣기',
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
                              color: theme.colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '※ 시즌 + 성별 조합당 1명만 저장됩니다.\n'
                                  '   (예: season1 + male → 시즌1 남자 선발 1명)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
