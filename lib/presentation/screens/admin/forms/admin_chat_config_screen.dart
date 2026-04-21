import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class AdminChatConfigScreen extends StatefulWidget {
  const AdminChatConfigScreen({super.key});

  @override
  State<AdminChatConfigScreen> createState() => _AdminChatConfigScreenState();
}

class _AdminChatConfigScreenState extends State<AdminChatConfigScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentNotice();
  }

  // 현재 설정된 공지 불러오기
  Future<void> _loadCurrentNotice() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('chat_config').get();
    if (doc.exists) {
      setState(() {
        _controller.text = doc.get('tickerNotice') ?? '';
      });
    }
  }

  // 🔥 공지 저장 (이때 DB 컬렉션과 문서가 자동 생성됨)
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('수정하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}