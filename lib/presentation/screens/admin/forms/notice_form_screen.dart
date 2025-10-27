// lib/presentation/screens/admin/forms/notice_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeFormScreen extends StatefulWidget {
  const NoticeFormScreen({super.key});

  @override
  State<NoticeFormScreen> createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends State<NoticeFormScreen> {
  final _textController = TextEditingController();
  bool _isActive = true;

  Future<void> _save() async {
    // 1. 입력값 검증
    if (_textController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('공지 내용을 입력하세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. 저장 시작
    try {
      await FirebaseFirestore.instance.collection('banners_notices').add({
        'text': _textController.text.trim(),
        'active': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. 성공 메시지 + 화면 닫기
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('공지가 성공적으로 등록되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      // 4. 에러 처리
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지 등록'),
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 공지 내용 입력
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: '공지 내용',
                border: OutlineInputBorder(),
                hintText: '예: Season 3 시작!',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 활성화 스위치
            SwitchListTile(
              title: const Text('공지 활성화'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeColor: const Color(0xFF00D4FF),
            ),
            const SizedBox(height: 24),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '공지 등록하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}