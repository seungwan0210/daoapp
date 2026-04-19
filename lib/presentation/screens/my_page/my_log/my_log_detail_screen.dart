import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/data/repositories/my_log_repository.dart';
import 'package:daoapp/presentation/providers/my_log_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_write_screen.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class MyLogDetailScreen extends ConsumerWidget {
  final String logId;

  const MyLogDetailScreen({super.key, required this.logId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(myLogRepositoryProvider);

    return StreamBuilder<MyLogModel?>(
      stream: repo.watchLog(logId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
          );
        }

        final log = snapshot.data;
        if (log == null) {
          return const Scaffold(
            appBar: CommonAppBar(title: '나의 다트 일기', showBackButton: true),
            body: Center(child: Text('기록을 찾을 수 없습니다.')),
          );
        }

        final dateStr = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(log.date);
        final timeStr = DateFormat('a h:mm', 'ko_KR').format(log.createdAt ?? log.date);
        final hasPhoto = log.photoUrls.isNotEmpty;
        final photoUrl = hasPhoto ? log.photoUrls.first : null;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: CommonAppBar(
            title: '나의 다트 일기',
            showBackButton: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MyLogWriteScreen(existingLog: log)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirm(context, repo, log.id!),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 사진 영역 (있는 경우만 표시)
                if (photoUrl != null)
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loading) {
                        if (loading == null) return child;
                        return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                      },
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. 날짜 및 공유 정보
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateStr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              Text('$timeStr 작성됨', style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                            ],
                          ),
                          if (log.isSharedToCircle)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.share_rounded, size: 14, color: Colors.cyan),
                                  SizedBox(width: 4),
                                  Text('서클 공유됨', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyan)),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 3. 본문 카드
                      AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('🎯', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 8),
                                Text('오늘의 다트 이야기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                              ],
                            ),
                            const Divider(height: 32, thickness: 0.5),

                            if (log.content != null && log.content!.trim().isNotEmpty)
                              SelectableText(
                                log.content!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.8,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.2,
                                ),
                              )
                            else
                              const Text(
                                '작성된 내용이 없습니다.',
                                style: TextStyle(fontSize: 15, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 하단 안내 문구
                      Center(
                        child: Text(
                          'DAO와 함께한 당신의 성장을 응원합니다.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirm(BuildContext context, MyLogRepository repo, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('이 날의 소중한 기록을 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제하기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await repo.deleteLog(id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('기록이 삭제되었습니다.')));
      }
    }
  }
}