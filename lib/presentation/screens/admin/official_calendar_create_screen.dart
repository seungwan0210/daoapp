import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class OfficialCalendarCreateScreen extends StatefulWidget {
  const OfficialCalendarCreateScreen({super.key});

  @override
  State<OfficialCalendarCreateScreen> createState() => _OfficialCalendarCreateScreenState();
}

class _OfficialCalendarCreateScreenState extends State<OfficialCalendarCreateScreen> {
  // 폼 입력을 위한 컨트롤러
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();

  // 기본 상태 값
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _scheduleType = 'domestic'; // domestic(국내), overseas(해외), league(리그/모집)
  String _selectedLogo = 'none'; // ✅ 기본 로고 선택값
  bool _isLoading = false; // 저장 중 로딩 상태 표시용

  // ✅ 로고 선택 옵션 (통합 관리)
  final Map<String, String> _logoOptions = {
    'none': '로고 없음',
    'phoenix': '피닉스다트 (Phoenix)',
    'dartslive': '다트라이브 (Dartslive)',
    'pdc': 'PDC',
    'wdf': 'WDF',
    'league': '자체 리그 및 모집',
  };

  @override
  void dispose() {
    // 컨트롤러 해제 (메모리 누수 방지)
    _titleController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  // 날짜 선택기 실행 함수
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Firestore 저장 함수
  Future<void> _saveSchedule() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정 명칭을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('official_calendar').add({
        'title': _titleController.text.trim(),
        'venue': _venueController.text.trim(),
        'startDate': Timestamp.fromDate(
          DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0),
        ),
        'endDate': Timestamp.fromDate(
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
        ),
        'type': _scheduleType,
        'logoKey': _selectedLogo, // ✅ 선택된 로고 키 저장
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공식 일정이 성공적으로 등록되었습니다.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(title: '공식 일정 등록', showBackButton: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "대회 또는 리그 정보를 입력하세요.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // 일정 명칭 입력
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '일정 명칭',
              hintText: '예: 피닉스 원리그, PDC 재팬 투어 등',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 20),

          // 일정 구분 선택 (Bar 색상 결정)
          DropdownButtonFormField<String>(
            value: _scheduleType,
            decoration: const InputDecoration(
              labelText: '일정 분류 (달력 표시 색상)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: const [
              DropdownMenuItem(value: 'domestic', child: Text('국내 대회 (파란 바)')),
              DropdownMenuItem(value: 'overseas', child: Text('해외 대회 (빨간 바)')),
              DropdownMenuItem(value: 'league', child: Text('리그 및 모집 기간 (초록 바)')),
            ],
            onChanged: (val) => setState(() => _scheduleType = val!),
          ),
          const SizedBox(height: 20),

          // ✅ 주최사 로고 선택 (통합 드롭다운)
          DropdownButtonFormField<String>(
            value: _selectedLogo,
            decoration: const InputDecoration(
              labelText: '주최사 로고 선택',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.stars_rounded),
            ),
            items: _logoOptions.entries.map((e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value),
            )).toList(),
            onChanged: (val) => setState(() => _selectedLogo = val!),
          ),
          const SizedBox(height: 30),

          // 기간 설정 섹션
          const Text("일정 기간 설정", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context, true),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text("${_startDate.month}/${_startDate.day} 시작"),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("~", style: TextStyle(fontSize: 20, color: Colors.grey)),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context, false),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text("${_endDate.month}/${_endDate.day} 종료"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 장소 입력
          TextField(
            controller: _venueController,
            decoration: const InputDecoration(
              labelText: '장소 (선택)',
              hintText: '대회 장소 또는 플랫폼 명칭',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),

          const SizedBox(height: 50),

          // 저장 버튼
          ElevatedButton(
            onPressed: _saveSchedule,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text(
              '공식 일정 저장하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}