import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

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
    final s = AppLocalizations.of(context)!;
    final tournamentId = _idCtrl.text.trim();

    if (tournamentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.debug_mail_msg_enter_id),
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
        SnackBar(
          content: Text(s.debug_mail_msg_success),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.debug_mail_msg_functions_error(e.code, e.message ?? '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.debug_mail_msg_error(e.toString())),
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
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.debug_title),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.debug_mail_section_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              s.debug_mail_guide,
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _idCtrl,
              decoration: InputDecoration(
                labelText: s.debug_mail_field_id,
                hintText: s.debug_mail_field_hint,
                border: const OutlineInputBorder(),
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
                label: Text(_isSending ? s.debug_mail_btn_sending : s.debug_mail_btn_send),
                onPressed: _isSending ? null : _sendTestMail,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 24),
            Text(
              s.debug_mail_tip_title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              s.debug_mail_tip_desc,
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}