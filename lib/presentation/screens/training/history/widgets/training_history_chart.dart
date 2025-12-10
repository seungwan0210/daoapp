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
          '그래프로 보여줄 기록이 아직 없어요.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    // 🔹 날짜 기준 오름차순 정렬
    final sorted = [...sessions]..sort((a, b) => a.endedAt.compareTo(b.endedAt));

    // 🔹 그래프에 쓸 포인트 만들기
    final List<FlSpot> spots = [];
    final List<String> xLabels = [];

    int idx = 0;
    for (final s in sorted) {
      final metric = _primaryMetricValue(s);
      if (metric == null) continue;

      spots.add(FlSpot(idx.toDouble(), metric));
      xLabels.add(_shortDateLabel(s.endedAt));
      idx++;
    }

    if (spots.isEmpty) {
      return const Center(
        child: Text(
          '명중률 / PPD / MPR 데이터가 없어서\n그래프를 그릴 수 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    final String metricLabel = _primaryMetricLabel(sorted);
    final bool isPercent = metricLabel == '명중률';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 220, // 🔹 고정 높이
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "최근 기록 추이 ($metricLabel)",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (spots.length - 1).toDouble(),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        // 👉 여기서는 더 이상 배경색 옵션 사용 안 함
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((t) {
                            final int i = t.x.toInt();
                            final String dateLabel =
                            (i >= 0 && i < xLabels.length) ? xLabels[i] : '';
                            final double value = t.y;
                            final String valueText = isPercent
                                ? "${value.toStringAsFixed(1)}%"
                                : value.toStringAsFixed(2);

                            return LineTooltipItem(
                              "$dateLabel\n$valueText",
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: isPercent ? 10 : 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                      drawVerticalLine: false,
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final int i = value.toInt();
                            if (i < 0 || i >= xLabels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                xLabels[i],
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              isPercent
                                  ? value.toStringAsFixed(0)
                                  : value.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.cyan.withOpacity(0.35),
                              Colors.cyan.withOpacity(0.02),
                            ],
                          ),
                        ),
                        color: Colors.cyan,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 세션에서 사용할 대표 지표 값
  double? _primaryMetricValue(TrainingSessionModel s) {
    final mode = s.inputModeString;

    if (mode == 'hitCount') {
      if (s.hitRate == null) return null;
      return s.hitRate! * 100; // %
    } else if (mode == 'scoreOnly') {
      return s.ppd;
    } else if (mode == 'cricketMarks') {
      return s.mpr;
    } else {
      return null;
    }
  }

  /// 🔹 그래프 타이틀용 지표 이름
  String _primaryMetricLabel(List<TrainingSessionModel> list) {
    for (final s in list) {
      final mode = s.inputModeString;
      if (mode == 'hitCount' && s.hitRate != null) {
        return '명중률';
      } else if (mode == 'scoreOnly' && s.ppd != null) {
        return 'PPD';
      } else if (mode == 'cricketMarks' && s.mpr != null) {
        return 'MPR';
      }
    }
    return '지표';
  }

  String _shortDateLabel(DateTime dt) {
    final local = dt.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$m/$d';
  }
}
