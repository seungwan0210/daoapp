// lib/presentation/screens/training/drills/drill_result_screen.dart

import 'package:flutter/material.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/data/models/training_drill_model.dart';
import 'package:daoapp/core/utils/dao_training_rating_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class DrillResultScreen extends StatelessWidget {
  final TrainingSessionModel session;
  final TrainingDrillDefinition drill;
  final DaoTrainingTier tier;

  const DrillResultScreen({
    super.key,
    required this.session,
    required this.drill,
    required this.tier,
  });

  int get _xpEarned {
    // 모델 필드 우선, 없으면 extra에서 백업
    if (session.xpEarned > 0) return session.xpEarned;
    final extraXp = session.extra?['xpEarned'];
    if (extraXp is num) return extraXp.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final mode = session.inputModeString;
    final started = session.startedAt;
    final ended = session.endedAt;
    final duration = ended.difference(started);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '연습 결과',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            // 1) 드릴 / 티어 정보
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drill.titleKo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    drill.titleEn,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ChipLabel(
                        label: '티어',
                        value: '${tier.labelKo} (${tier.labelEn})',
                      ),
                      const SizedBox(width: 8),
                      _ChipLabel(
                        label: '카테고리',
                        value: drill.category.name,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.drillTitle.isNotEmpty
                        ? session.drillTitle
                        : drill.shortDescriptionKo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2) XP 카드 (이번 세션에서 획득)
            _XpResultCard(xp: _xpEarned),

            const SizedBox(height: 16),

            // 3) 성과(명중률 / PPD / MPR 등) 요약
            _MainStatsCard(
              session: session,
              mode: mode,
            ),

            const SizedBox(height: 16),

            // 4) 세부 정보
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '세션 요약',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _RowItem(
                    label: '총 시도',
                    value:
                    '${session.totalAttempts}회 (라운드: ${session.totalRounds}R)',
                  ),
                  const SizedBox(height: 6),
                  if (session.hitRate != null) ...[
                    _RowItem(
                      label: '성공 / 실패',
                      value:
                      '${session.successCount} / ${session.failCount}',
                    ),
                    const SizedBox(height: 6),
                    _RowItem(
                      label: '명중률',
                      value:
                      '${(session.hitRate! * 100).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (session.ppd != null && session.threeDartAvg != null)
                    _RowItem(
                      label: 'PPD / 3다트 평균',
                      value:
                      '${session.ppd!.toStringAsFixed(2)} PPD / ${session.threeDartAvg!.toStringAsFixed(2)}',
                    ),
                  if (session.mpr != null) ...[
                    const SizedBox(height: 6),
                    _RowItem(
                      label: 'Cricket MPR',
                      value: session.mpr!.toStringAsFixed(2),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _RowItem(
                    label: '소요 시간',
                    value: minutes > 0
                        ? '${minutes}분 ${seconds}초'
                        : '${seconds}초',
                  ),
                  const SizedBox(height: 6),
                  _RowItem(
                    label: '시작 / 종료',
                    value:
                    '${_formatTime(started)} ~ ${_formatTime(ended)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5) 닫기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

/// 큰 XP 카드
class _XpResultCard extends StatelessWidget {
  final int xp;

  const _XpResultCard({
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasXp = xp > 0;
    final String mainText = hasXp ? '+$xp XP' : 'XP 0 (테스트 중)';
    final String subText = hasXp
        ? '이번 연습으로 획득한 경험치입니다.'
        : 'XP 계산 테스트용 기록입니다.';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 세션 XP',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                mainText,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: hasXp ? Colors.cyan.shade600 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              if (hasXp)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '성장 포인트',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 메인 성과 카드 (모드별로 가장 중요한 수치 1~2개만 강조)
class _MainStatsCard extends StatelessWidget {
  final TrainingSessionModel session;
  final String? mode;

  const _MainStatsCard({
    required this.session,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final inputMode = mode ?? session.inputModeString;

    String title = '주요 성과';
    Widget content;

    if (inputMode == 'hitCount') {
      final hitRate = session.hitRate != null
          ? (session.hitRate! * 100).toStringAsFixed(1)
          : '--';
      title = '명중률 드릴 결과';
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(
            label: '명중률',
            value: '$hitRate%',
          ),
          _BigStat(
            label: '성공 / 실패',
            value: '${session.successCount} / ${session.failCount}',
          ),
        ],
      );
    } else if (inputMode == 'scoreOnly') {
      final ppdText =
      session.ppd != null ? session.ppd!.toStringAsFixed(2) : '--';
      final threeDartText = session.threeDartAvg != null
          ? session.threeDartAvg!.toStringAsFixed(2)
          : '--';
      title = '점수형 드릴 결과';

      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(
            label: 'PPD',
            value: ppdText,
          ),
          _BigStat(
            label: '3다트 평균',
            value: threeDartText,
          ),
        ],
      );
    } else if (inputMode == 'cricketMarks') {
      final mprText =
      session.mpr != null ? session.mpr!.toStringAsFixed(2) : '--';
      title = '크리켓 드릴 결과';
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(
            label: 'Cricket MPR',
            value: mprText,
          ),
          _BigStat(
            label: '총 마크',
            value: '${session.totalMarksExtra ?? '-'}',
          ),
        ],
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BigStat(
            label: '시도 수',
            value: '${session.totalAttempts}',
          ),
          _BigStat(
            label: '라운드',
            value: '${session.totalRounds}R',
          ),
        ],
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}

/// 작은 라벨+값 칩
class _ChipLabel extends StatelessWidget {
  final String label;
  final String value;

  const _ChipLabel({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;

  const _BigStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;

  const _RowItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
