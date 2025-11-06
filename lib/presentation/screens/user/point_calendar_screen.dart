// lib/presentation/screens/user/point_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/data/repositories/point_record_repository.dart';
import 'package:daoapp/data/models/point_record_model.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class PointCalendarScreen extends StatefulWidget {
  const PointCalendarScreen({super.key});

  @override
  State<PointCalendarScreen> createState() => _PointCalendarScreenState();
}

class _PointCalendarScreenState extends State<PointCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<PointRecord>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllPointEvents();
  }

  Future<void> _loadAllPointEvents() async {
    final repo = sl<PointRecordRepository>();

    repo.getAllPointRecords().listen((records) {
      final Map<DateTime, List<PointRecord>> events = {};
      for (var record in records) {
        final date = DateTime(record.date.year, record.date.month, record.date.day);
        events.putIfAbsent(date, () => []).add(record);
      }
      setState(() => _events = events);
    });
  }

  List<PointRecord> _getEventsForDay(DateTime day) {
    final events = _events[DateTime(day.year, day.month, day.day)] ?? [];

    // 포인트 내림차순 정렬
    events.sort((a, b) => b.points.compareTo(a.points));

    int currentRank = 1;
    int? previousPoints;

    for (int i = 0; i < events.length; i++) {
      if (i == 0) {
        currentRank = 1;
      } else if (events[i].points == previousPoints!) {
        // 같은 포인트 → 같은 순위
      } else {
        currentRank = i + 1;
      }
      events[i] = events[i].copyWith(rank: currentRank);
      previousPoints = events[i].points;
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: '포인트 달력',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // 달력 (400px 고정 + overflow 방지)
          AppCard(
            margin: const EdgeInsets.all(16),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 400,
                child: TableCalendar(
                  firstDay: AppDateUtils.firstDay,
                  lastDay: AppDateUtils.lastDay,
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                  eventLoader: _getEventsForDay,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                    todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    selectedDecoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
                    selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      if (isSameDay(day, _selectedDay)) return null;
                      return Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                          child: Center(child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
                          child: Center(child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // 선택된 날짜 포인트 내역
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('날짜를 선택하세요'))
                : _getEventsForDay(_selectedDay!).isEmpty
                ? const Center(child: Text('해당 날짜에 포인트 내역 없음'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _getEventsForDay(_selectedDay!).length,
              itemBuilder: (_, i) {
                final record = _getEventsForDay(_selectedDay!)[i];
                final rank = record.rank ?? i + 1;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      child: Row(
                        children: [
                          // 순위
                          SizedBox(
                            width: 36,
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: rank == 1
                                    ? Colors.amber
                                    : rank == 2
                                    ? Colors.grey
                                    : rank == 3
                                    ? Colors.brown.shade600
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 이름
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.koreanName,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  record.englishName,
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // 샵
                          Expanded(
                            flex: 2,
                            child: Text(
                              record.shopName,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // 포인트
                          Expanded(
                            flex: 1,
                            child: Text(
                              '+${record.points}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}