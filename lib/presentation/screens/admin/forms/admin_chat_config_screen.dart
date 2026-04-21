import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
// ✅ ChatUtils 임포트 추가
import 'package:daoapp/core/utils/chat_utils.dart';

class AdminChatConfigScreen extends StatefulWidget {
  const AdminChatConfigScreen({super.key});

  @override
  State<AdminChatConfigScreen> createState() => _AdminChatConfigScreenState();
}

class _AdminChatConfigScreenState extends State<AdminChatConfigScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  // ✅ 마감 임박 공지 전송 로딩 상태 추가
  bool _isNotifying = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentNotice();
  }

  Future<void> _loadCurrentNotice() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('chat_config').get();
    if (doc.exists) {
      setState(() {
        _controller.text = doc.get('tickerNotice') ?? '';
      });
    }
  }

  Future<void> _saveNotice() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('chat_config').set({
        'tickerNotice': _controller.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('전광판 공지가 수정되었습니다!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 [추가] 마감 임박 공지 발송 함수 연동
  Future<void> _sendClosingSoonNotice() async {
    setState(() => _isNotifying = true);
    try {
      final int count = await ChatUtils.sendClosingSoonTournaments();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? '총 $count개의 대회 마감 임박 공지를 발송했습니다! 🎯'
              : '현재 마감 1일 전인 대회가 없습니다. 😅'),
          backgroundColor: count > 0 ? Colors.teal : Colors.grey[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('발송 실패: $e')));
    } finally {
      if (mounted) setState(() => _isNotifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: '전광판 공지 관리', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('전광판 상단 공지 문구', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLength: 50,
              decoration: InputDecoration(
                hintText: '공지 내용을 입력하세요 (예: 오늘 대만 오픈 선발전 화이팅!)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveNotice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('수정하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),

            // 🔥 [추가] 마감 임박 대회 홍보 섹션
            const Text('대회 홍보 알림', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              '엔트리 마감이 1일 남은 대회를 찾아 채팅방에 공지를 뿌립니다.\n사람들이 가장 많이 접속하는 시간에 사용하면 효과가 좋습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: _isNotifying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal))
                    : const Icon(Icons.campaign, color: Colors.teal),
                label: const Text('마감 임박 공지 즉시 발송', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                onPressed: _isNotifying ? null : _sendClosingSoonNotice,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.teal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}