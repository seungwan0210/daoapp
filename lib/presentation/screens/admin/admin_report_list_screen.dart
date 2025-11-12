import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class AdminReportListScreen extends ConsumerStatefulWidget {
  const AdminReportListScreen({super.key});

  @override
  ConsumerState<AdminReportListScreen> createState() => _AdminReportListScreenState();
}

class _AdminReportListScreenState extends ConsumerState<AdminReportListScreen> {
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

  Future<void> _markAsProcessed(String reportId) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({'processed': true, 'processedAt': FieldValue.serverTimestamp()});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(title: '신고 내역', showBackButton: true),
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
                    return content.contains(_searchQuery) || reporter.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text('신고 내역이 없습니다'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final reportId = doc.id;
                    final reporterId = data['reporterId'] as String?;
                    final reporterName = data['reporterName'] ?? '익명';
                    final content = data['content'] ?? '';
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                    final timeStr = timestamp != null ? AppDateUtils.formatRelativeTime(timestamp) : '방금 전';
                    final processed = data['processed'] == true;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
                        child: Text(content, style: const TextStyle(fontSize: 13)),
                      ),
                      trailing: !processed
                          ? TextButton(
                        onPressed: () => _markAsProcessed(reportId),
                        child: const Text('처리', style: TextStyle(color: Colors.blue)),
                      )
                          : null,
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