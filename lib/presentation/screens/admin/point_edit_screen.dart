// lib/presentation/screens/admin/point_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/data/models/point_record_model.dart';
import 'package:daoapp/data/repositories/point_record_repository.dart';
import 'package:daoapp/presentation/providers/ranking_provider.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('포인트 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('이름: ${widget.record.koreanName}'),
            Text('현재 포인트: ${widget.record.points}pt'),
            const SizedBox(height: 16),
            TextField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '새 포인트'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _update,
              child: const Text('수정 완료'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _update() async {
    final newPoints = int.tryParse(_pointsController.text);
    if (newPoints == null || newPoints <= 0) return;

    final updatedRecord = widget.record.copyWith(points: newPoints);
    await ref.read(pointRecordRepositoryProvider).updatePointRecord(updatedRecord, widget.oldPoints);

    ref.read(rankingProvider.notifier).loadRanking();
    if (mounted) Navigator.pop(context);
  }
}