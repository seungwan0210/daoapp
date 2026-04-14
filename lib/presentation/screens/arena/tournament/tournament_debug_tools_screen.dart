import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class TournamentDebugToolsScreen extends StatefulWidget {
  const TournamentDebugToolsScreen({super.key});

  @override
  State<TournamentDebugToolsScreen> createState() =>
      _TournamentDebugToolsScreenState();
}

class _TournamentDebugToolsScreenState extends State<TournamentDebugToolsScreen> {
  final _idCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendTestMail() async {
    final tournamentId = _idCtrl.text.trim();
    if (tournamentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('tournamentId를 입력해주세요'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final callable =
      FirebaseFunctions.instance.httpsCallable('testSendEntrySummary');

      await callable.call({'tournamentId': tournamentId});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 테스트 메일 발송 요청 완료! (받은편지함/스팸함 확인)'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Functions 오류: ${e.code}\n${e.message ?? ''}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 오류: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Debug Tools'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '테스트 메일 발송 (admin only)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '※ functions/index.js의 관리자 UID 조건을 통과해야 동작합니다.\n'
                  '※ tournamentId는 Firestore tournaments 문서 ID를 넣어주세요.',
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _idCtrl,
              decoration: const InputDecoration(
                labelText: 'tournamentId',
                hintText: '예: aBcD1234....',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSending
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.mark_email_read_outlined),
                label: Text(_isSending ? '발송 중...' : '테스트 메일 보내기'),
                onPressed: _isSending ? null : _sendTestMail,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 24),
            Text(
              '팁: tournamentId 찾는 법\n'
                  '• Firebase Console → Firestore → tournaments 컬렉션\n'
                  '• 문서 클릭하면 상단에 Document ID가 tournamentId 입니다.',
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
