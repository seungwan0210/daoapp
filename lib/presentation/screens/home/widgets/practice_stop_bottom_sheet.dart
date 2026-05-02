import 'package:flutter/material.dart';
import 'package:daoapp/data/models/practice_session_model.dart';
import 'package:daoapp/data/repositories/practice_repository.dart';
import 'package:daoapp/di/service_locator.dart';

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

  /// 연습 종료 실행
  Future<void> _complete(bool saveLog) async {
    try {
      // ✅ 리포지토리의 stopPractice에 피드백 텍스트를 전달합니다.
      await sl<PracticeRepository>().stopPractice(
        widget.session.uid,
        saveToMyLog: saveLog,
        feedback: _feedbackController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('종료 처리 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // 키보드 대응
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
                      const Text(
                        '연습 종료 리포트',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      const Text('오늘의 연습을 마무리하고 기록을 남겨보세요.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 24),

                      // 1. 총 연습 시간 표시 (시각적 피드백)
                      _buildInfoBox(
                        '총 연습 시간',
                        _formatDuration(widget.finalDuration),
                        const Color(0xFF1565C0), // Indigo
                        icon: Icons.timer_outlined,
                      ),
                      const SizedBox(height: 16),

                      // 2. 설정했던 목표 표시 (있을 경우만)
                      if (widget.session.targetGoal != null && widget.session.targetGoal!.isNotEmpty) ...[
                        _buildInfoBox(
                          '나의 목표',
                          widget.session.targetGoal!,
                          Colors.blue,
                          icon: Icons.track_changes_rounded,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '목표를 달성하셨나요? (결과/피드백)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _feedbackController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: '예: 100발 완료!, 컨디션 난조로 실패 등',
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
                        const Center(
                          child: Text('오늘도 정말 고생하셨습니다!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // 3. 하단 액션 버튼
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
                              child: const Text('저장없이 종료', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
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
                              child: const Text('마이로그 저장', style: TextStyle(fontWeight: FontWeight.bold)),
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