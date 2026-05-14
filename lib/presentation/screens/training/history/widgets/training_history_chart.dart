import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:daoapp/data/models/training_session_model.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

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
  _MetricView _view = _MetricView.all;

  static const Color _hitRateColor = Color(0xFFFFA000);
  static const Color _ppdColor = Color(0xFF00ACC1);
  static const Color _mprColor = Color(0xFFAB47BC);

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스
    final sessions = widget.sessions;

    if (sessions.isEmpty) {
      return Center(
        child: Text(
          s.history_no_record, // 🔹 기존 히스토리 키 재사용
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    final Map<DateTime, _DailyAggregate> dailyMap = {};

    for (final s in sessions) {
      final ended = s.endedAt.toLocal();
      final dayKey = DateTime(ended.year, ended.month, ended.day);

      final agg = dailyMap.putIfAbsent(dayKey, () => _DailyAggregate());
      final mode = s.inputModeString;

      if (mode == 'hitCount' && s.hitRate != null) {
        agg.hitRateSum += s.hitRate! * 100;
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
      return Center(
        child: Text(
          s.chart_no_data, // 🔹 다국어화
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    const int maxDays = 7;
    List<DateTime> days = dailyMap.keys.toList()..sort((a, b) => a.compareTo(b));
    if (days.length > maxDays) {
      days = days.sublist(days.length - maxDays);
    }

    final hitRateSpots = <FlSpot>[];
    final ppdSpots = <FlSpot>[];
    final mprSpots = <FlSpot>[];
    final xLabels = <String>[];
    final dayList = <DateTime>[];

    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final agg = dailyMap[day]!;

      if (agg.hitRateCount > 0) {
        final avg = (agg.hitRateSum / agg.hitRateCount).clamp(0.0, 100.0).toDouble();
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

    final List<LineChartBarData> lineBars = [];
    if (_view == _MetricView.all || _view == _MetricView.hitRate) {
      if (hitRateSpots.isNotEmpty) {
        lineBars.add(_buildBarData(hitRateSpots, _hitRateColor, hasArea: true));
      }
    }
    if (_view == _MetricView.all || _view == _MetricView.ppd) {
      if (ppdSpots.isNotEmpty) {
        lineBars.add(_buildBarData(ppdSpots, _ppdColor, hasArea: true, opacity: 0.20));
      }
    }
    if (_view == _MetricView.all || _view == _MetricView.mpr) {
      if (mprSpots.isNotEmpty) {
        lineBars.add(_buildBarData(mprSpots, _mprColor));
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
            Text(s.chart_title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), // 🔹 다국어화
            const SizedBox(height: 4),
            Text(s.chart_sub, style: const TextStyle(fontSize: 11, color: Colors.grey)), // 🔹 다국어화
            const SizedBox(height: 8),

            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (hitRateSpots.isNotEmpty) _legendItem(_hitRateColor, "${s.drill_stat_hit_rate} (%)"),
                if (ppdSpots.isNotEmpty) _legendItem(_ppdColor, s.chart_legend_ppd),
                if (mprSpots.isNotEmpty) _legendItem(_mprColor, s.chart_legend_mpr),
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
                  lineTouchData: _touchData(context, hitRateSpots, ppdSpots, mprSpots, dayList), // 🔹 context 전달
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 20,
                        getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= xLabels.length) return const SizedBox();
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(xLabels[i], style: TextStyle(fontSize: 10, color: Colors.grey[600])));
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
                          style: const TextStyle(fontSize: 10, color: _hitRateColor),
                          labelResolver: (_) => s.chart_goal_hit("70"), // 🔹 다국어화
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: _buildToggle(context)),
          ],
        ),
      ),
    );
  }

  // ───── UI helpers ─────

  LineChartBarData _buildBarData(List<FlSpot> spots, Color color, {bool hasArea = false, double opacity = 0.25}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      barWidth: 3.5,
      color: color,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: hasArea,
        gradient: LinearGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildToggle(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        _toggleChip(_MetricView.all, s.chart_toggle_all),
        _toggleChip(_MetricView.hitRate, s.drill_stat_hit_rate),
        _toggleChip(_MetricView.ppd, "PPD"),
        _toggleChip(_MetricView.mpr, "MPR"),
      ],
    );
  }

  Widget _toggleChip(_MetricView value, String label) {
    final bool selected = _view == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey[700])),
      selected: selected,
      onSelected: (_) => setState(() => _view = value),
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
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  LineTouchData _touchData(
      BuildContext context,
      List<FlSpot> hitRateSpots,
      List<FlSpot> ppdSpots,
      List<FlSpot> mprSpots,
      List<DateTime> days,
      ) {
    final s = AppLocalizations.of(context)!;
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => Colors.black87,
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
              tooltipText += "\n${s.chart_tooltip_hit}: ${touchedSpot.y.toStringAsFixed(1)}%";
            } else if (touchedSpot.bar.spots == ppdSpots) {
              tooltipText += "\nPPD: ${(touchedSpot.y / 2).toStringAsFixed(2)}";
            } else if (touchedSpot.bar.spots == mprSpots) {
              tooltipText += "\nMPR: ${(touchedSpot.y / 10).toStringAsFixed(2)}";
            }

            return LineTooltipItem(
              tooltipText,
              const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            );
          }).whereType<LineTooltipItem>().toList();
        },
      ),
    );
  }

  String _shortDateLabel(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
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