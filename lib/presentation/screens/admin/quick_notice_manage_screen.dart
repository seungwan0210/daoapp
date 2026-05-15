import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:intl/intl.dart';

class QuickNoticeManageScreen extends StatefulWidget {
  const QuickNoticeManageScreen({super.key});

  @override
  State<QuickNoticeManageScreen> createState() => _QuickNoticeManageScreenState();
}

class _QuickNoticeManageScreenState extends State<QuickNoticeManageScreen> {
  final _contentController = TextEditingController();
  final _actionUrlController = TextEditingController();

  DateTime _startDate = DateTime.now();
  // 💡 초기값을 7일 뒤로 설정하되, UI에서 수정 가능하게 변경
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _targetDate;    // ✅ 대회 당일 (D-Day 자동 계산용)
  DateTime? _entryDeadline; // ✅ 엔트리 마감일

  String _selectedLogo = 'none';
  String _selectedHex = '3B82F6';

  String _actionType = 'none';
  String _selectedRoute = RouteConstants.arenaHome;

  bool _isLoading = false;

  final Map<String, String> _logoOptions = {
    'none': '로고 없음',
    'phoenix': '피닉스다트',
    'dartslive': '다트라이브',
    'pdc': 'PDC',
    'wdf': 'WDF',
    'league': 'DAO 리그',
  };

  final List<Map<String, dynamic>> _colorOptions = [
    {'label': '블루', 'color': const Color(0xFF3B82F6), 'hex': '3B82F6'},
    {'label': '네온그린', 'color': const Color(0xFF22C55E), 'hex': '22C55E'},
    {'label': '레드', 'color': const Color(0xFFEF4444), 'hex': 'EF4444'},
    {'label': '옐로우', 'color': const Color(0xFFEAB308), 'hex': 'EAB308'},
    {'label': '퍼플', 'color': const Color(0xFFA855F7), 'hex': 'A855F7'},
  ];

  @override
  void dispose() {
    _contentController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveNotice() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요.')));
      return;
    }
    setState(() => _isLoading = true);

    String finalActionUrl = '';
    if (_actionType == 'link') {
      finalActionUrl = _actionUrlController.text.trim();
    } else if (_actionType == 'internal') {
      finalActionUrl = _selectedRoute;
    }

    try {
      await FirebaseFirestore.instance.collection('quick_notices').add({
        'content': _contentController.text.trim(),
        'actionType': _actionType,
        'actionUrl': finalActionUrl,
        'logoKey': _selectedLogo,
        'colorHex': _selectedHex,
        'startDate': Timestamp.fromDate(DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0)),
        // 💡 관리자가 설정한 _endDate가 그대로 반영됨
        'endDate': Timestamp.fromDate(DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59)),
        'targetDate': _targetDate != null ? Timestamp.fromDate(_targetDate!) : null,
        'entryDeadline': _entryDeadline != null ? Timestamp.fromDate(_entryDeadline!) : null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('퀵 노티스가 등록되었습니다.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _contentController.clear();
    _actionUrlController.clear();
    setState(() {
      _endDate = DateTime.now().add(const Duration(days: 7)); // 초기화 시 다시 7일 뒤로
      _targetDate = null;
      _entryDeadline = null;
      _actionType = 'none';
      _selectedLogo = 'none';
      _selectedHex = '3B82F6';
    });
  }

  Widget _buildActionSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이동 경로 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: [
            _buildRadioOption('none', '없음'),
            _buildRadioOption('link', '외부 링크'),
            _buildRadioOption('internal', '앱 내부'),
          ],
        ),
        if (_actionType == 'link')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextField(
              controller: _actionUrlController,
              decoration: InputDecoration(
                labelText: 'URL 입력 (https://...)',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        else if (_actionType == 'internal')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DropdownButtonFormField<String>(
              value: _selectedRoute,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.near_me),
              ),
              items: const [
                DropdownMenuItem(value: RouteConstants.arenaHome, child: Text('아레나(토너먼트) 홈')),
                DropdownMenuItem(value: RouteConstants.steelLeagueRanking, child: Text('스틸리그 랭킹')),
                DropdownMenuItem(value: RouteConstants.community, child: Text('커뮤니티 홈')),
              ],
              onChanged: (v) => setState(() => _selectedRoute = v!),
            ),
          ),
      ],
    );
  }

  Widget _buildRadioOption(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _actionType,
          onChanged: (v) => setState(() => _actionType = v!),
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Future<void> _selectDate({required DateTime initialDate, required Function(DateTime) onSelected}) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2025),
        lastDate: DateTime(2030),
        locale: const Locale('ko', 'KR')
    );
    if (picked != null) onSelected(picked);
  }

  Widget _buildDateChip(String label, DateTime? date, VoidCallback onTap, {bool isRequired = false}) {
    return ActionChip(
      avatar: Icon(Icons.calendar_today, size: 14, color: date != null ? Colors.white : Colors.grey),
      label: Text(
          date != null ? "$label: ${DateFormat('MM/dd').format(date)}" : "$label 설정",
          style: TextStyle(color: date != null ? Colors.white : Colors.black87, fontSize: 12)
      ),
      backgroundColor: date != null ? (isRequired ? Colors.orangeAccent : Colors.blue) : Colors.grey[100],
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: '퀵 노티스 관리', showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: "공지 내용 (예: Taiwan Open 개최)",
                      prefixIcon: Icon(Icons.campaign),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildActionSelector(theme),
                  const SizedBox(height: 24),

                  const Text("날짜 옵션 (종료일 필수 / 나머지는 선택)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  // 💡 종료일 설정을 위한 Chip 추가
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDateChip(
                          "공지 종료일",
                          _endDate,
                              () => _selectDate(initialDate: _endDate, onSelected: (d) => setState(() => _endDate = d)),
                          isRequired: true
                      ),
                      _buildDateChip(
                          "대회 당일",
                          _targetDate,
                              () => _selectDate(initialDate: DateTime.now(), onSelected: (d) => setState(() => _targetDate = d))
                      ),
                      _buildDateChip(
                          "엔트리 마감",
                          _entryDeadline,
                              () => _selectDate(initialDate: DateTime.now(), onSelected: (d) => setState(() => _entryDeadline = d))
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text("배경 색상 선택", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _colorOptions.map((item) {
                      final isSelected = _selectedHex == item['hex'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedHex = item['hex']),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                              color: item['color'],
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? Colors.black : Colors.transparent, width: 2)
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
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
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(100, 48)
                        ),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("등록"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text("최근 등록 리스트", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('quick_notices').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final docs = snapshot.data!.docs;
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final color = Color(int.parse("0xFF${data['colorHex'] ?? '3B82F6'}"));

                          // 💡 리스트에서 종료일도 확인할 수 있도록 수정
                          final endTs = data['endDate'] as Timestamp?;
                          final endStr = endTs != null ? DateFormat('MM/dd').format(endTs.toDate()) : '-';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: _buildLogoIcon(data['logoKey'])),
                            title: Text(data['content'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                              "종료: $endStr | 타겟: ${data['targetDate'] != null ? 'D-Day' : '없음'} | 경로: ${data['actionType']}",
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _deleteNotice(docs[index].id)
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoIcon(String? key) {
    if (key == null || key == 'none') return const Icon(Icons.campaign, size: 20);
    return Image.asset('assets/images/logos/$key.png', width: 24, errorBuilder: (_, __, ___) => const Icon(Icons.error));
  }

  Future<void> _deleteNotice(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("공지 삭제"),
        content: const Text("정말 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await FirebaseFirestore.instance.collection('quick_notices').doc(docId).delete();
  }
}