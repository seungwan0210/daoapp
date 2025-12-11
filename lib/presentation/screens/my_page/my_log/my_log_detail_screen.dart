import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/data/repositories/my_log_repository.dart';
import 'package:daoapp/presentation/providers/my_log_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_write_screen.dart';

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
        final timeStr = DateFormat('a h:mm', 'ko_KR')
            .format(log.createdAt ?? log.date); // 작성 시간 표시용
        final hasPhoto = log.photoUrls.isNotEmpty;
        final photoUrl = hasPhoto ? log.photoUrls.first : null;

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
          body: SafeArea(
            top: false,
            child: Container(
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== 상단 날짜 + 서브 텍스트 =====
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '이 날의 다트 이야기를 다시 읽어볼까요?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 서클 공유 배지
                    if (log.isSharedToCircle) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.cyan.withOpacity(0.08),
                          border: Border.all(
                            color: Colors.cyan.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.share_outlined,
                              size: 16,
                              color: Colors.cyan,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '서클에도 남겨둔 기록이에요',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.cyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else
                      const SizedBox(height: 8),

                    // ===== 메인 다이어리 카드 =====
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 사진 영역
                          if (photoUrl != null) ...[
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              child: Image.network(
                                photoUrl,
                                width: double.infinity,
                                height: 240,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: double.infinity,
                                    height: 240,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 240,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_outlined,
                                          size: 60,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '사진을 불러올 수 없어요',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 상단 작은 타이틀
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blueGrey[50],
                                      ),
                                      child: const Text('🎯', style: TextStyle(fontSize: 22)),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        '오늘의 다트 기록',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // 본문 내용 (읽기 전용, 넓은 줄 간격)
                                if (log.content != null &&
                                    log.content!.trim().isNotEmpty)
                                  SelectableText(
                                    log.content!,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      height: 1.9,
                                      letterSpacing: -0.1,
                                    ),
                                  )
                                else
                                  Text(
                                    '내용이 없는 기록입니다.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                    ),
                                  ),

                                const SizedBox(height: 20),

                                // 작성 시간
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$timeStr 작성',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
