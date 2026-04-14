// lib/presentation/screens/admin/admin_report_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class AdminReportListScreen extends ConsumerStatefulWidget {
  const AdminReportListScreen({super.key});

  @override
  ConsumerState<AdminReportListScreen> createState() =>
      _AdminReportListScreenState();
}

class _AdminReportListScreenState
    extends ConsumerState<AdminReportListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 처리 상태 업데이트
  Future<void> _markAsProcessed(String reportId) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({
      'processed': true,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ [New] 신고 내역 삭제
  Future<void> _deleteReport(String reportId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고 내역이 삭제되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  /// ✅ [New] 삭제 확인 다이얼로그
  Future<void> _confirmDelete(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('신고 삭제'),
        content: const Text('정말 이 신고 내역을 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteReport(reportId);
    }
  }

  void _showReportDetailDialog({
    required BuildContext context,
    required String reportId,
    required String reporterName,
    required String? reporterEmail,
    required String title,
    required String content,
    required DateTime? timestamp,
    required String? imageUrl,
    required bool processed,
  }) {
    final timeStr = timestamp != null
        ? AppDateUtils.formatRelativeTime(timestamp)
        : '방금 전';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title.isEmpty ? '신고 상세' : title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 신고자 정보
                Text(
                  '신고자: $reporterName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (reporterEmail != null && reporterEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reporterEmail,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // 내용
                const Text(
                  '신고 내용',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),

                // 이미지 미리보기
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '첨부 이미지',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Text("이미지를 불러올 수 없습니다."),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            // ✅ [New] 상세 팝업 내 삭제 버튼
            TextButton(
              onPressed: () async {
                // 다이얼로그 닫고 삭제 확인창 띄우기 (겹침 방지)
                Navigator.pop(ctx);
                await _confirmDelete(reportId);
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),

            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기', style: TextStyle(color: Colors.grey)),
            ),

            if (!processed)
              TextButton(
                onPressed: () async {
                  await _markAsProcessed(reportId);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('처리완료', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '신고 내역 관리', showBackButton: true),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '신고 내용 검색',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
              ),
            ),
          ),

          // 신고 리스트
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                // 검색 필터
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final content = (data['content'] as String?)?.toLowerCase() ?? '';
                    final reporter = (data['reporterName'] as String?)?.toLowerCase() ?? '';
                    final title = (data['title'] as String?)?.toLowerCase() ?? '';
                    return content.contains(_searchQuery) ||
                        reporter.contains(_searchQuery) ||
                        title.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text('신고 내역이 없습니다'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final reportId = doc.id;

                    final reporterName = (data['reporterName'] as String?) ?? '익명';
                    final reporterEmail = (data['reporterEmail'] as String?) ?? data['email'];
                    final title = (data['title'] as String?) ?? '(제목 없음)';
                    final content = (data['content'] as String?) ?? '';

                    final ts = (data['timestamp'] ?? data['createdAt']) as Timestamp?;
                    final timestamp = ts?.toDate();
                    final timeStr = timestamp != null
                        ? AppDateUtils.formatRelativeTime(timestamp)
                        : '방금 전';

                    final processed = (data['processed'] as bool?) ?? (data['isResolved'] == true);
                    final imageUrl = data['imageUrl'] as String?;
                    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

                    return ListTile(
                      onTap: () {
                        _showReportDetailDialog(
                          context: context,
                          reportId: reportId,
                          reporterName: reporterName,
                          reporterEmail: reporterEmail,
                          title: title,
                          content: content,
                          timestamp: timestamp,
                          imageUrl: imageUrl,
                          processed: processed,
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      leading: hasImage
                          ? const Icon(Icons.image, color: Colors.orange)
                          : const Icon(Icons.report_gmailerrorred, color: Colors.redAccent),
                      title: Row(
                        children: [
                          Text(reporterName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Spacer(),
                          if (processed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('처리완료', style: TextStyle(fontSize: 11, color: Colors.green)),
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      // ✅ [New] 리스트 아이템 오른쪽 버튼 그룹 (처리/삭제)
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!processed)
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
                              tooltip: '처리 완료',
                              onPressed: () => _markAsProcessed(reportId),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            tooltip: '삭제',
                            onPressed: () => _confirmDelete(reportId),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}