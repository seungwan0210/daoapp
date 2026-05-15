import 'package:flutter/material.dart';
import 'package:daoapp/data/models/practice_session_model.dart';
import 'package:daoapp/data/repositories/practice_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/l10n/app_localizations.dart';

class PracticeStopBottomSheet extends StatefulWidget {
  final PracticeSessionModel session;
  final Duration finalDuration;

  const PracticeStopBottomSheet({
    super.key,
    required this.session,
    required this.finalDuration,
  });

  @override
  State<PracticeStopBottomSheet> createState() => _PracticeStopBottomSheetState();
}

class _PracticeStopBottomSheetState extends State<PracticeStopBottomSheet> {
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _complete(bool saveLog) async {
    final s = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    // ✅ 종료 시점 유저 체크 (소프트 게이트)
    if (user == null) {
      _showPromptDialog(
          context,
          s.community_home_login_prompt,
          Icons.people_alt_outlined,
          RouteConstants.login
      );
      return;
    }

    try {
      await sl<PracticeRepository>().stopPractice(
        widget.session.uid,
        saveToMyLog: saveLog,
        feedback: _feedbackController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.practice_stop_error(e.toString()))),
        );
      }
    }
  }

  // ✅ 유도 팝업 다이얼로그 (바텀시트와 다이얼로그 동시 제어)
  void _showPromptDialog(BuildContext context, String title, IconData icon, String route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그 닫기
                  Navigator.pop(context); // 바텀시트 닫기
                  Navigator.pushNamed(context, route);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("이동하기"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.practice_stop_title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Text(s.practice_stop_sub, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 24),

                      _buildInfoBox(
                        s.practice_stop_total_time,
                        _formatDuration(widget.finalDuration),
                        const Color(0xFF1565C0),
                        icon: Icons.timer_outlined,
                      ),
                      const SizedBox(height: 16),

                      if (widget.session.targetGoal != null && widget.session.targetGoal!.isNotEmpty) ...[
                        _buildInfoBox(
                          s.practice_stop_my_goal,
                          widget.session.targetGoal!,
                          Colors.blue,
                          icon: Icons.track_changes_rounded,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          s.practice_stop_feedback_label,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _feedbackController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: s.practice_stop_feedback_hint,
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1)),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(s.practice_stop_cheer_msg, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        ),
                      ],

                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _complete(false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(s.practice_stop_btn_no_save, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _complete(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: Text(s.practice_stop_btn_save, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, Color color, {required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}