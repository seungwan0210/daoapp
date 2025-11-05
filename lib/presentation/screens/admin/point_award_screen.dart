// lib/presentation/screens/admin/point_award_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/data/repositories/point_record_repository.dart';
import 'package:daoapp/data/models/point_record_model.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class PointAwardScreen extends ConsumerStatefulWidget {
  const PointAwardScreen({super.key});

  @override
  ConsumerState<PointAwardScreen> createState() => _PointAwardScreenState();
}

class _PointAwardScreenState extends ConsumerState<PointAwardScreen> {
  String _year = '2026';
  String _phase = 'season1';
  String _koreanName = '';
  String _englishName = '';
  String _shopName = '';
  String _gender = 'male';
  DateTime _selectedDate = DateTime.now();

  List<DocumentSnapshot> _searchResults = [];
  DocumentSnapshot? _selectedUser;
  bool _isNewUser = false;

  final _koreanController = TextEditingController();
  final _englishController = TextEditingController();
  final _shopController = TextEditingController();
  final _pointsController = TextEditingController();

  @override
  void dispose() {
    _koreanController.dispose();
    _englishController.dispose();
    _shopController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트 수동 부여'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 시즌/구분
                DropdownButtonFormField<String>(
                  value: _year,
                  items: ['2026'].map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (v) => setState(() => _year = v!),
                  decoration: const InputDecoration(labelText: '시즌'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _phase,
                  items: const [
                    DropdownMenuItem(value: 'season1', child: Text('시즌 1')),
                    DropdownMenuItem(value: 'season2', child: Text('시즌 2')),
                    DropdownMenuItem(value: 'season3', child: Text('시즌 3')),
                  ],
                  onChanged: (v) => setState(() => _phase = v!),
                  decoration: const InputDecoration(labelText: '구분'),
                ),
                const SizedBox(height: 16),

                // 날짜 선택
                Card(
                  child: ListTile(
                    title: Text('날짜: ${AppDateUtils.formatKoreanDate(_selectedDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: AppDateUtils.firstDay,
                        lastDate: AppDateUtils.lastDay,
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 한글 이름 검색
                TextField(
                  controller: _koreanController,
                  decoration: InputDecoration(
                    labelText: '한글 이름 (필수)',
                    suffixIcon: _searchResults.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchResults = []),
                    )
                        : null,
                  ),
                  onChanged: _searchOrCreateUser,
                ),
                if (_searchResults.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) {
                        final data = _searchResults[i].data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['koreanName']),
                          subtitle: Text('${data['englishName']} • ${data['shopName']}'),
                          onTap: () {
                            setState(() {
                              _selectedUser = _searchResults[i];
                              _isNewUser = false;
                              _koreanController.text = data['koreanName'];
                              _englishController.text = data['englishName'];
                              _shopController.text = data['shopName'];
                              _gender = data['gender'];
                              _searchResults = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                if (_isNewUser && _koreanName.isNotEmpty)
                  Card(
                    color: Colors.green[50],
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('신규 등록 중', style: TextStyle(color: Colors.green)),
                    ),
                  ),

                const SizedBox(height: 16),

                // 나머지 입력
                TextField(
                  controller: _englishController,
                  decoration: const InputDecoration(labelText: '영문 이름 (신규 등록 시 필수)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _shopController,
                  decoration: const InputDecoration(labelText: '샵 이름 (신규 등록 시 필수)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _gender,
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('남자')),
                    DropdownMenuItem(value: 'female', child: Text('여자')),
                  ],
                  onChanged: (v) => setState(() => _gender = v!),
                  decoration: const InputDecoration(labelText: '성별'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '포인트 (0 이상)',
                    errorText: _pointsError(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // 부여 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canAward() ? _award : null,
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        return _canAward() ? null : Colors.grey;
                      }),
                    ),
                    child: const Text('포인트 부여', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _pointsError() {
    final text = _pointsController.text;
    if (text.isEmpty) return null;
    final points = int.tryParse(text);
    if (points == null || points <= 0) return '0 이상의 숫자를 입력하세요';
    return null;
  }

  bool _canAward() {
    final points = int.tryParse(_pointsController.text);
    final hasName = _koreanName.isNotEmpty;
    final hasPoints = points != null && points > 0;

    if (_isNewUser) {
      return hasName &&
          hasPoints &&
          _englishController.text.isNotEmpty &&
          _shopController.text.isNotEmpty;
    } else {
      return hasName && hasPoints;
    }
  }

  void _searchOrCreateUser(String query) async {
    _koreanName = query.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('koreanName', isGreaterThanOrEqualTo: query)
        .where('koreanName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(5)
        .get();

    setState(() {
      _searchResults = snapshot.docs;
      _isNewUser = _searchResults.isEmpty && query.isNotEmpty;
    });
  }

  // 신규 포인트 부여 전용
  Future<void> _award() async {
    final points = int.parse(_pointsController.text);
    String userId;

    // 1. 유저 처리 (기존 or 신규)
    if (_selectedUser != null) {
      userId = _selectedUser!.id;
    } else {
      final newUser = await FirebaseFirestore.instance.collection('users').add({
        'koreanName': _koreanName,
        'englishName': _englishController.text,
        'shopName': _shopController.text,
        'gender': _gender,
        'totalPoints': points,
      });
      userId = newUser.id;
    }

    // 2. PointRecord 생성 (id는 null → awardPoints에서 생성)
    final record = PointRecord(
      id: null, // 신규 → Firestore가 자동 생성
      userId: userId,
      seasonId: _year,
      phase: _phase,
      points: points,
      eventName: '관리자 수동 부여',
      shopName: _shopController.text.isEmpty ? '미기입' : _shopController.text,
      date: _selectedDate,
      awardedBy: 'admin',
      koreanName: _koreanName,
      englishName: _englishController.text,
    );

    try {
      final repo = ref.read(pointRecordRepositoryProvider);
      await repo.awardPoints(record); // 수정 로직 제거!

      ref.read(rankingProvider.notifier).loadRanking();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('포인트 부여 완료!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}