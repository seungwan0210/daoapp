import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:intl/intl.dart';

class QuickNoticeManageScreen extends StatefulWidget {
  const QuickNoticeManageScreen({super.key});

  @override
  State<QuickNoticeManageScreen> createState() => _QuickNoticeManageScreenState();
}

class _QuickNoticeManageScreenState extends State<QuickNoticeManageScreen> {
  final _contentController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _selectedLogo = 'none';
  String _selectedHex = 'F1F5F9'; // 기본 파스텔 그레이
  bool _isLoading = false;

  // ✅ 로고 옵션
  final Map<String, String> _logoOptions = {
    'none': '로고 없음',
    'phoenix': '피닉스다트',
    'dartslive': '다트라이브',
    'pdc': 'PDC',
    'wdf': 'WDF',
    'league': 'DAO 리그',
  };

  final List<Map<String, dynamic>> _colorOptions = [
    {'label': '블루', 'color': const Color(0xFF3B82F6), 'hex': '3B82F6'}, // 선명한 블루
    {'label': '네온그린', 'color': const Color(0xFF22C55E), 'hex': '22C55E'}, // 네온 그린
    {'label': '레드', 'color': const Color(0xFFEF4444), 'hex': 'EF4444'}, // 강렬한 레드
    {'label': '옐로우', 'color': const Color(0xFFEAB308), 'hex': 'EAB308'}, // 골드 옐로우
    {'label': '퍼플', 'color': const Color(0xFFA855F7), 'hex': 'A855F7'}, // 퍼플
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // 날짜 선택 헬퍼
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // 1. 등록 함수
  Future<void> _saveNotice() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('quick_notices').add({
        'content': _contentController.text.trim(),
        'logoKey': _selectedLogo,
        'colorHex': _selectedHex,
        'startDate': Timestamp.fromDate(DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0)),
        'endDate': Timestamp.fromDate(DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59)),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _contentController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('퀵 노티스가 등록되었습니다.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. 삭제 함수
  Future<void> _deleteNotice(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("공지 삭제"),
        content: const Text("이 퀵 노티스를 영구 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('quick_notices').doc(docId).delete();
    }
  }

  // 3. 수정 팝업 함수
  void _showEditDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final editController = TextEditingController(text: data['content']);
    String editLogo = data['logoKey'] ?? 'none';
    String editHex = data['colorHex'] ?? 'F1F5F9';
    DateTime editStart = (data['startDate'] as Timestamp).toDate();
    DateTime editEnd = (data['endDate'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("퀵 노티스 수정", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: editController, decoration: const InputDecoration(labelText: "내용")),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: editLogo,
                  items: _logoOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (val) => setDialogState(() => editLogo = val!),
                  decoration: const InputDecoration(labelText: "로고 선택", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                const Text("배경색 수정", style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _colorOptions.map((item) {
                    final isSel = editHex == item['hex'];
                    return GestureDetector(
                      onTap: () => setDialogState(() => editHex = item['hex']),
                      child: Container(
                        width: 35, height: 35,
                        decoration: BoxDecoration(
                          color: item['color'], shape: BoxShape.circle,
                          border: Border.all(color: isSel ? Colors.blue : Colors.grey[300]!, width: isSel ? 2 : 1),
                        ),
                        child: isSel ? const Icon(Icons.check, size: 18, color: Colors.blue) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('quick_notices').doc(doc.id).update({
                  'content': editController.text.trim(),
                  'logoKey': editLogo,
                  'colorHex': editHex,
                  'startDate': Timestamp.fromDate(editStart),
                  'endDate': Timestamp.fromDate(editEnd),
                });
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text("저장하기"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: '퀵 노티스 관리', showBackButton: true),
      body: Column(
        children: [
          // --- 상단: 입력 섹션 ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: "홈 화면에 흐를 공지 내용을 입력하세요",
                    prefixIcon: Icon(Icons.campaign),
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("배경 색상 선택", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _colorOptions.map((item) {
                    final isSelected = _selectedHex == item['hex'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedHex = item['hex']),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: item['color'], shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? Colors.blue : Colors.grey[200]!, width: isSelected ? 2.5 : 1),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 20, color: Colors.blue) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLogo,
                        items: _logoOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                        onChanged: (val) => setState(() => _selectedLogo = val!),
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveNotice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("등록"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- 하단: 실시간 리스트 섹션 ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('quick_notices').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("등록된 퀵 노티스가 없습니다."));

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final color = Color(int.parse("0xFF${data['colorHex'] ?? 'F1F5F9'}"));

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                        child: _buildLogoIcon(data['logoKey']),
                      ),
                      title: Text(data['content'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        "${DateFormat('MM/dd').format((data['startDate'] as Timestamp).toDate())} ~ ${DateFormat('MM/dd').format((data['endDate'] as Timestamp).toDate())}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey), onPressed: () => _showEditDialog(docs[index])),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: () => _deleteNotice(docs[index].id)),
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

  // 리스트용 로고 아이콘 빌더
  Widget _buildLogoIcon(String? key) {
    if (key == null || key == 'none') return const Icon(Icons.campaign, size: 20, color: Colors.blueGrey);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset('assets/images/logos/$key.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.error, size: 10)),
    );
  }
}