// lib/presentation/screens/training/history/widgets/training_history_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:daoapp/data/models/training_session_model.dart';

class TrainingHistoryChart extends StatelessWidget {
  final List<TrainingSessionModel> sessions;

  const TrainingHistoryChart({
    super.key,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          '아직 기록이 없어요!\n연습을 시작해보세요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    // 🔹 1) 세션들을 "날짜(연/월/일)" 단위로 묶어서 하루 평균 만들기
    final Map<DateTime, _DailyAggregate> dailyMap = {};

    for (final s in sessions) {
      final ended = s.endedAt.toLocal();
      final dayKey = DateTime(ended.year, ended.month, ended.day); // 날짜만

      final agg = dailyMap.putIfAbsent(dayKey, () => _DailyAggregate());

      // inputMode 기준으로 나눠서 평균에 포함
      final mode = s.inputModeString;

      // 명중률: hitCount 모드만
      if (mode == 'hitCount' && s.hitRate != null) {
        agg.hitRateSum += s.hitRate! * 100; // 0~1 -> 0~100
        agg.hitRateCount++;
      }

      // PPD: scoreOnly 모드만
      if (mode == 'scoreOnly' && s.ppd != null) {
        agg.ppdSum += s.ppd!;
        agg.ppdCount++;
      }

      // MPR: cricketMarks 모드만
      if (mode == 'cricketMarks' && s.mpr != null) {
        agg.mprSum += s.mpr!;
        agg.mprCount++;
      }
    }

    // 🔹 2) 날짜 정렬 후, 최근 N일(예: 7일)만 사용
    const int maxDays = 7;
    List<DateTime> days = dailyMap.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    if (days.length > maxDays) {
      days = days.sublist(days.length - maxDays); // 최근 7일만
    }

    // 🔹 3) 그래프용 포인트 & 라벨 생성
    final hitRateSpots = <FlSpot>[];
    final ppdSpots = <FlSpot>[];
    final mprSpots = <FlSpot>[];
    final xLabels = <String>[];   // X축 라벨
    final dayList = <DateTime>[]; // 툴팁용 날짜

    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final agg = dailyMap[day]!;

      // 각 지표별 "하루 평균" 계산 (없으면 건너뜀)
      if (agg.hitRateCount > 0) {
        final avg = (agg.hitRateSum / agg.hitRateCount)
            .clamp(0.0, 100.0) as double;
        hitRateSpots.add(FlSpot(i.toDouble(), avg));
      }
      if (agg.ppdCount > 0) {
        final avgPpd = agg.ppdSum / agg.ppdCount; // 실제 PPD
        final scaled = (avgPpd * 2).clamp(0.0, 100.0) as double; // 0~100 스케일
        ppdSpots.add(FlSpot(i.toDouble(), scaled));
      }
      if (agg.mprCount > 0) {
        final avgMpr = agg.mprSum / agg.mprCount; // 실제 MPR
        final scaled = (avgMpr * 10).clamp(0.0, 100.0) as double; // 0~100 스케일
        mprSpots.add(FlSpot(i.toDouble(), scaled));
      }

      xLabels.add(_shortDateLabel(day));
      dayList.add(day);
    }

    if (hitRateSpots.isEmpty && ppdSpots.isEmpty && mprSpots.isEmpty) {
      return const Center(
        child: Text(
          '표시할 수 있는 데이터가 없어요',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "성장 추이 (하루 평균, 최근 7일)",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (hitRateSpots.isNotEmpty)
                  _legendItem(Colors.cyan, "명중률 (%)"),
                if (ppdSpots.isNotEmpty)
                  _legendItem(Colors.amber.shade600, "PPD"),
                if (mprSpots.isNotEmpty)
                  _legendItem(Colors.purple.shade400, "MPR"),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (days.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100, // 🔹 모든 지표를 0~100 스케일로
                  lineTouchData: _touchData(
                    hitRateSpots,
                    ppdSpots,
                    mprSpots,
                    dayList,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    // 오른쪽 축: % 표시
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            "${value.toInt()}%",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.cyan,
                            ),
                          );
                        },
                      ),
                    ),
                    // 왼쪽 축은 숨김 (혼동 줄이기)
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= xLabels.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              xLabels[i],
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 70,
                        color: Colors.cyan.withOpacity(0.4),
                        strokeWidth: 1.5,
                        dashArray: const [8, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.cyan,
                          ),
                          labelResolver: (_) => "목표 70%",
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    if (hitRateSpots.isNotEmpty)
                      LineChartBarData(
                        spots: hitRateSpots,
                        isCurved: true,
                        barWidth: 3.5,
                        color: Colors.cyan,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyan.withOpacity(0.25),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    if (ppdSpots.isNotEmpty)
                      LineChartBarData(
                        spots: ppdSpots,
                        isCurved: true,
                        barWidth: 3.0,
                        color: Colors.amber.shade600,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.withOpacity(0.20),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    if (mprSpots.isNotEmpty)
                      LineChartBarData(
                        spots: mprSpots,
                        isCurved: true,
                        barWidth: 3.0,
                        color: Colors.purple.shade400,
                        dotData: const FlDotData(show: true),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───── helpers ─────

  Widget _legendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 3, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  LineTouchData _touchData(
      List<FlSpot> hitRateSpots,
      List<FlSpot> ppdSpots,
      List<FlSpot> mprSpots,
      List<DateTime> days,
      ) {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => Colors.black87,
        tooltipRoundedRadius: 12,
        tooltipPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        tooltipMargin: 12,
        maxContentWidth: 140,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((touchedSpot) {
            final index = touchedSpot.x.toInt();
            if (index < 0 || index >= days.length) return null;

            final day = days[index];
            final date = _shortDateLabel(day);
            String tooltipText = date;

            if (touchedSpot.bar.spots == hitRateSpots) {
              final percent = touchedSpot.y; // 이미 % 값
              tooltipText += "\n명중률: ${percent.toStringAsFixed(1)}%";
            } else if (touchedSpot.bar.spots == ppdSpots) {
              final realPpd = touchedSpot.y / 2; // 다시 PPD로
              tooltipText += "\nPPD: ${realPpd.toStringAsFixed(2)}";
            } else if (touchedSpot.bar.spots == mprSpots) {
              final realMpr = touchedSpot.y / 10; // 다시 MPR로
              tooltipText += "\nMPR: ${realMpr.toStringAsFixed(2)}";
            }

            return LineTooltipItem(
              tooltipText,
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          }).whereType<LineTooltipItem>().toList();
        },
      ),
    );
  }

  String _shortDateLabel(DateTime dt) {
    final local = dt.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$m/$d';
  }
}

/// 하루 평균 계산용 내부 클래스
class _DailyAggregate {
  double hitRateSum = 0;
  int hitRateCount = 0;

  double ppdSum = 0;
  int ppdCount = 0;

  double mprSum = 0;
  int mprCount = 0;
}
