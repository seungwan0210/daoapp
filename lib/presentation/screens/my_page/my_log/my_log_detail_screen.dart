import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/data/repositories/my_log_repository.dart';
import 'package:daoapp/presentation/providers/my_log_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_write_screen.dart';
import 'package:daoapp/presentation/screens/my_page/my_log/widgets/my_log_card.dart';

class MyLogDetailScreen extends ConsumerWidget {
  final String logId;

  const MyLogDetailScreen({super.key, required this.logId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(myLogRepositoryProvider);

    return StreamBuilder<MyLogModel?>(
      stream: repo.watchLog(logId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final log = snapshot.data;
        if (log == null) {
          return Scaffold(
            appBar: const CommonAppBar(title: '마이로그'),
            body: const Center(child: Text('기록을 찾을 수 없습니다.')),
          );
        }

        final dateStr =
        DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(log.date);

        return Scaffold(
          appBar: CommonAppBar(
            title: '나의 다트 일기',
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyLogWriteScreen(existingLog: log),
                    ),
                  );
                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('기록이 수정되었습니다.')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('삭제하시겠어요?'),
                      content:
                      const Text('이 날짜의 다트 기록이 완전히 삭제됩니다.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            '삭제',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await repo.deleteLog(log.id!);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('기록이 삭제되었습니다.')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  Theme.of(context).colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 + 작은 서브타이틀
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '오늘의 다트 기록',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 다이어리 카드
                  MyLogCard(log: log, showDate: false),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
