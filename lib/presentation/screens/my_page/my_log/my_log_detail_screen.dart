import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:daoapp/data/models/my_log_model.dart';
import 'package:daoapp/data/repositories/my_log_repository.dart';
import 'package:daoapp/presentation/providers/my_log_provider.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/screens/my_page/my_log/my_log_write_screen.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class MyLogDetailScreen extends ConsumerWidget {
  final String logId;

  const MyLogDetailScreen({super.key, required this.logId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스
    final repo = ref.read(myLogRepositoryProvider);
    final locale = Localizations.localeOf(context).toString(); // 🔹 현재 로케일

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
          return Scaffold(
            appBar: CommonAppBar(title: s.mylog_title, showBackButton: true),
            body: Center(child: Text(s.mylog_detail_error_not_found)), // 🔹 다국어 적용
          );
        }

        // 🔹 로케일에 맞춘 날짜 및 시간 포맷
        final dateStr = DateFormat.yMMMEd(locale).format(log.date);
        final timeStr = DateFormat.jm(locale).format(log.createdAt ?? log.date);

        final hasPhoto = log.photoUrls.isNotEmpty;
        final photoUrl = hasPhoto ? log.photoUrls.first : null;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: CommonAppBar(
            title: s.mylog_title, // 🔹 다국어 적용
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
                onPressed: () => _showDeleteConfirm(context, repo, log.id!, s), // 🔹 s 전달
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateStr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              Text(s.mylog_detail_written_at(timeStr), style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)), // 🔹 파라미터 적용
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
                              child: Row(
                                children: [
                                  const Icon(Icons.share_rounded, size: 14, color: Colors.cyan),
                                  const SizedBox(width: 4),
                                  Text(s.mylog_detail_shared_circle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyan)), // 🔹 다국어 적용
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('🎯', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(s.mylog_detail_content_title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF334155))), // 🔹 다국어 적용
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
                              Text(
                                s.mylog_detail_no_content, // 🔹 다국어 적용
                                style: const TextStyle(fontSize: 15, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      Center(
                        child: Text(
                          s.mylog_detail_footer, // 🔹 다국어 적용
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

  void _showDeleteConfirm(BuildContext context, MyLogRepository repo, String id, AppLocalizations s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.mylog_detail_delete_title, style: const TextStyle(fontWeight: FontWeight.bold)), // 🔹 다국어 적용
        content: Text(s.mylog_detail_delete_body), // 🔹 다국어 적용
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.mylog_detail_delete_btn, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), // 🔹 다국어 적용
          ),
        ],
      ),
    );

    if (confirm == true) {
      await repo.deleteLog(id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.mylog_detail_delete_success))); // 🔹 다국어 적용
      }
    }
  }
}