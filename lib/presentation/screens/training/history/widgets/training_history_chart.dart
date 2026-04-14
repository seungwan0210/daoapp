// lib/presentation/screens/training/history/widgets/training_history_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:daoapp/data/models/training_session_model.dart';

class TrainingHistoryChart extends StatefulWidget {
  final List<TrainingSessionModel> sessions;

  const TrainingHistoryChart({
    super.key,
    required this.sessions,
  });

  @override
  State<TrainingHistoryChart> createState() => _TrainingHistoryChartState();
}

enum _MetricView { all, hitRate, ppd, mpr }

class _TrainingHistoryChartState extends State<TrainingHistoryChart> {
  // 🔹 어떤 지표를 볼지 (전체 / 명중률 / PPD / MPR)
  _MetricView _view = _MetricView.all;

  // 공통 색상 (그래프/범례/카드 전부 맞춰 쓰기)
  static const Color _hitRateColor = Color(0xFFFFA000); // 주황 - 명중률
  static const Color _ppdColor = Color(0xFF00ACC1); // 민트/청록 - PPD
  static const Color _mprColor = Color(0xFFAB47BC); // 보라 - MPR

  @override
  Widget build(BuildContext context) {
    final sessions = widget.sessions;

    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          '아직 기록이 없어요!\n연습을 시작해보세요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    // 🔹 1) 날짜(연/월/일) 단위로 묶어서 하루 평균 만들기
    final Map<DateTime, _DailyAggregate> dailyMap = {};

    for (final s in sessions) {
      final ended = s.endedAt.toLocal();
      final dayKey = DateTime(ended.year, ended.month, ended.day);

      final agg = dailyMap.putIfAbsent(dayKey, () => _DailyAggregate());
      final mode = s.inputModeString;

      if (mode == 'hitCount' && s.hitRate != null) {
        agg.hitRateSum += s.hitRate! * 100; // 0~1 → 0~100
        agg.hitRateCount++;
      }

      if (mode == 'scoreOnly' && s.ppd != null) {
        agg.ppdSum += s.ppd!;
        agg.ppdCount++;
      }

      if (mode == 'cricketMarks' && s.mpr != null) {
        agg.mprSum += s.mpr!;
        agg.mprCount++;
      }
    }

    if (dailyMap.isEmpty) {
      return const Center(
        child: Text(
          '표시할 수 있는 데이터가 없어요',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    // 🔹 2) 날짜 정렬 후, 최근 N일만 사용
    const int maxDays = 7;
    List<DateTime> days = dailyMap.keys.toList()..sort((a, b) => a.compareTo(b));

    if (days.length > maxDays) {
      days = days.sublist(days.length - maxDays);
    }

    // 🔹 3) 그래프용 포인트 & 라벨 생성
    final hitRateSpots = <FlSpot>[];
    final ppdSpots = <FlSpot>[];
    final mprSpots = <FlSpot>[];

    final xLabels = <String>[];
    final dayList = <DateTime>[];

    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final agg = dailyMap[day]!;

      if (agg.hitRateCount > 0) {
        final avg =
        (agg.hitRateSum / agg.hitRateCount).clamp(0.0, 100.0).toDouble();
        hitRateSpots.add(FlSpot(i.toDouble(), avg));
      }

      if (agg.ppdCount > 0) {
        final avgPpd = agg.ppdSum / agg.ppdCount;
        final scaled = (avgPpd * 2).clamp(0.0, 100.0).toDouble();
        ppdSpots.add(FlSpot(i.toDouble(), scaled));
      }

      if (agg.mprCount > 0) {
        final avgMpr = agg.mprSum / agg.mprCount;
        final scaled = (avgMpr * 10).clamp(0.0, 100.0).toDouble();
        mprSpots.add(FlSpot(i.toDouble(), scaled));
      }

      xLabels.add(_shortDateLabel(day));
      dayList.add(day);
    }

    // 🔹 4) 현재 뷰에 따라 실제로 그릴 라인 선택
    final List<LineChartBarData> lineBars = [];

    if (_view == _MetricView.all || _view == _MetricView.hitRate) {
      if (hitRateSpots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: hitRateSpots,
            isCurved: true,
            barWidth: 3.5,
            color: _hitRateColor,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _hitRateColor.withOpacity(0.25),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        );
      }
    }

    if (_view == _MetricView.all || _view == _MetricView.ppd) {
      if (ppdSpots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: ppdSpots,
            isCurved: true,
            barWidth: 3.0,
            color: _ppdColor,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _ppdColor.withOpacity(0.20),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        );
      }
    }

    if (_view == _MetricView.all || _view == _MetricView.mpr) {
      if (mprSpots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: mprSpots,
            isCurved: true,
            barWidth: 3.0,
            color: _mprColor,
            dotData: const FlDotData(show: true),
          ),
        );
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "성장 추이 (하루 평균, 최근 7일)",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "그래프는 최근 7일 동안의 하루 평균값을 보여줘요.",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (hitRateSpots.isNotEmpty)
                  _legendItem(_hitRateColor, "명중률 (%)"),
                if (ppdSpots.isNotEmpty)
                  _legendItem(_ppdColor, "PPD (스케일 x2)"),
                if (mprSpots.isNotEmpty)
                  _legendItem(_mprColor, "MPR (스케일 x10)"),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (days.isEmpty) ? 0 : (days.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: lineBars,
                  lineTouchData:
                  _touchData(hitRateSpots, ppdSpots, mprSpots, dayList),
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
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
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
                        color: _hitRateColor.withOpacity(0.5),
                        strokeWidth: 1.5,
                        dashArray: const [8, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _hitRateColor,
                          ),
                          labelResolver: (_) => "목표 명중률 70%",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Center(child: _buildToggle()),
          ],
        ),
      ),
    );
  }

  // ───── UI helpers ─────

  Widget _buildToggle() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        _toggleChip(_MetricView.all, "전체"),
        _toggleChip(_MetricView.hitRate, "명중률"),
        _toggleChip(_MetricView.ppd, "PPD"),
        _toggleChip(_MetricView.mpr, "MPR"),
      ],
    );
  }

  Widget _toggleChip(_MetricView value, String label) {
    final bool selected = _view == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.grey[700],
        ),
      ),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _view = value;
        });
      },
      selectedColor: Colors.black87,
      backgroundColor: Colors.grey[200],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 3, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 11),
        ),
      ],
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
        // 배경색 설정 (버전에 따라 tooltipBgColor 또는 getTooltipColor 사용)
        getTooltipColor: (_) => Colors.black87,

        // 🔥 [최종 해결] 에러를 일으키는 Radius 설정을 삭제했습니다.
        // 삭제하더라도 패키지 기본값으로 깔끔하게 출력됩니다.

        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tooltipMargin: 12,
        maxContentWidth: 160,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((touchedSpot) {
            final index = touchedSpot.x.toInt();
            if (index < 0 || index >= days.length) return null;

            final day = days[index];
            final date = _shortDateLabel(day);
            String tooltipText = date;

            if (touchedSpot.bar.spots == hitRateSpots) {
              final percent = touchedSpot.y;
              tooltipText += "\n명중률: ${percent.toStringAsFixed(1)}%";
            } else if (touchedSpot.bar.spots == ppdSpots) {
              final realPpd = touchedSpot.y / 2;
              tooltipText += "\nPPD: ${realPpd.toStringAsFixed(2)}";
            } else if (touchedSpot.bar.spots == mprSpots) {
              final realMpr = touchedSpot.y / 10;
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

class _DailyAggregate {
  double hitRateSum = 0;
  int hitRateCount = 0;

  double ppdSum = 0;
  int ppdCount = 0;

  double mprSum = 0;
  int mprCount = 0;
}