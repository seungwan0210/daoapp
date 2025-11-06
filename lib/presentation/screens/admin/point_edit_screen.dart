// lib/presentation/screens/admin/point_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/point_record_model.dart';
import 'package:daoapp/data/repositories/point_record_repository.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart'; // 추가!

class PointEditScreen extends ConsumerStatefulWidget {
  final PointRecord record;
  final int oldPoints;

  const PointEditScreen({
    super.key,
    required this.record,
    required this.oldPoints,
  });

  @override
  ConsumerState<PointEditScreen> createState() => _PointEditScreenState();
}

class _PointEditScreenState extends ConsumerState<PointEditScreen> {
  late TextEditingController _pointsController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _pointsController = TextEditingController(text: widget.record.points.toString());
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 통일된 AppBar
      appBar: CommonAppBar(
        title: '포인트 수정',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 사용자 정보 카드
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(Icons.person, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.record.koreanName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              widget.record.englishName,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.record.shopName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.record.date.year}-${widget.record.date.month.toString().padLeft(2, '0')}-${widget.record.date.day.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 현재 포인트
          AppCard(
            child: ListTile(
              leading: Icon(Icons.bar_chart, color: theme.colorScheme.primary),
              title: const Text('현재 포인트'),
              trailing: Text(
                '${widget.record.points}pt',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 새 포인트 입력
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '새 포인트',
                    prefixIcon: const Icon(Icons.add_circle_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '포인트를 입력하세요';
                    if (int.tryParse(value) == null || int.tryParse(value)! <= 0) {
                      return '1 이상의 숫자를 입력하세요';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 수정 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _update,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                '수정 완료',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    final newPoints = int.tryParse(_pointsController.text);
    if (newPoints == null || newPoints <= 0) return;

    final updatedRecord = widget.record.copyWith(points: newPoints);
    await ref.read(pointRecordRepositoryProvider).updatePointRecord(updatedRecord, widget.oldPoints);

    ref.read(rankingProvider.notifier).loadRanking();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('포인트가 수정되었습니다'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }
}