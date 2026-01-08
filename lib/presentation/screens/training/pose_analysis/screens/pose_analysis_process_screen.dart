import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/presentation/providers/training/pose_analysis_provider.dart';
import 'package:daoapp/presentation/screens/training/pose_analysis/screens/pose_analysis_result_screen.dart';

class PoseAnalysisProcessScreen extends ConsumerStatefulWidget {
  const PoseAnalysisProcessScreen({super.key});

  @override
  ConsumerState<PoseAnalysisProcessScreen> createState() => _PoseAnalysisProcessScreenState();
}

class _PoseAnalysisProcessScreenState extends ConsumerState<PoseAnalysisProcessScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    // 시각적 재미를 위한 가짜 프로그레스 바 (실제 FFmpeg 퍼센트는 파싱이 어렵습니다)
    // 1초마다 조금씩 오르다가 분석 완료되면 100%
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = (timer.tick / 2).floor(); // 0.5초 단위라 2로 나눔
          // 20초 정도 걸린다고 가정하고 천천히 게이지 채움
          if (_progressValue < 0.9) {
            _progressValue += 0.02;
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    final success = await ref.read(poseAnalysisProvider.notifier).analyzeVideo();
    if (success && mounted) {
      setState(() => _progressValue = 1.0); // 100% 달성
      await Future.delayed(const Duration(milliseconds: 500)); // 100% 보여주고 이동

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PoseAnalysisResultScreen()));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("분석 실패. 다시 시도해주세요.")));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 퍼센트 텍스트
    final percent = (_progressValue * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로딩 아이콘
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100, height: 100,
                  child: CircularProgressIndicator(
                    value: _progressValue, // 게이지
                    strokeWidth: 8,
                    color: Colors.cyan,
                    backgroundColor: Colors.grey[100],
                  ),
                ),
                Text(
                  "$percent%",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan),
                ),
              ],
            ),
            const SizedBox(height: 40),

            const Text("AI가 자세를 분석 중입니다", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("소요 시간: ${_elapsedSeconds}초", style: TextStyle(color: Colors.grey[600], fontSize: 14)),

            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "잠시만 기다려주세요.\n영상이 길수록 시간이 조금 더 소요됩니다.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}